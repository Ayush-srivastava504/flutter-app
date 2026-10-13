import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:video_editor_app/services/media_storage_service.dart';

/// Tests for P1's `MediaStorageService` (`docs/FEATURE_PLAN_25.md` §1):
/// copying a picked file out of the OS-clearable cache dir into
/// documents, and detecting whether a path is still in the cache.
/// `documentsDir`/`cacheDirs` are injected so this never touches
/// `path_provider`'s platform channel.
void main() {
  late Directory tempRoot;
  late Directory documentsDir;
  late Directory cacheDir;
  late MediaStorageService storage;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('media_storage_test');
    documentsDir = Directory(p.join(tempRoot.path, 'documents'))..createSync();
    cacheDir = Directory(p.join(tempRoot.path, 'cache'))..createSync();
    storage = MediaStorageService(
      documentsDir: () async => documentsDir,
      cacheDirs: [() async => cacheDir],
    );
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  group('persistToDocuments', () {
    test('copies the file into <documents>/imported_media with a fresh name', () async {
      final source = File(p.join(cacheDir.path, 'picked.mp4'))
        ..writeAsBytesSync([1, 2, 3]);

      final newPath = await storage.persistToDocuments(source.path);

      expect(newPath, isNot(source.path));
      expect(p.dirname(newPath), p.join(documentsDir.path, 'imported_media'));
      expect(p.extension(newPath), '.mp4');
      expect(await File(newPath).readAsBytes(), [1, 2, 3]);
      // Non-destructive: the original cache file is left in place (the
      // caller/repair pass decides whether to delete it; this service
      // never does).
      expect(await source.exists(), isTrue);
    });

    test('two calls for the same source produce two distinct files', () async {
      final source = File(p.join(cacheDir.path, 'a.jpg'))..writeAsBytesSync([9]);
      final first = await storage.persistToDocuments(source.path);
      final second = await storage.persistToDocuments(source.path);
      expect(first, isNot(second));
      expect(await File(first).exists(), isTrue);
      expect(await File(second).exists(), isTrue);
    });

    test('falls back to the original path if the source does not exist', () async {
      final missing = p.join(cacheDir.path, 'does_not_exist.mp4');
      final result = await storage.persistToDocuments(missing);
      expect(result, missing);
    });
  });

  group('isInCache', () {
    test('true for a path directly inside a cache dir', () async {
      final path = p.join(cacheDir.path, 'clip.mp4');
      expect(await storage.isInCache(path), isTrue);
    });

    test('true for a path in a subdirectory of a cache dir', () async {
      final path = p.join(cacheDir.path, 'nested', 'clip.mp4');
      expect(await storage.isInCache(path), isTrue);
    });

    test('false for a path under documents', () async {
      final path = p.join(documentsDir.path, 'imported_media', 'clip.mp4');
      expect(await storage.isInCache(path), isFalse);
    });

    test('false for an unrelated path', () async {
      expect(await storage.isInCache('/some/other/place/clip.mp4'), isFalse);
    });
  });
}
