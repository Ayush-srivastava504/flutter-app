import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// P1 (`docs/FEATURE_PLAN_25.md` §1): `image_picker`/`file_picker` leave
/// freshly picked media sitting in the OS-clearable cache dir (see
/// `docs/FACTS.md` F-50). Android can wipe that directory under storage
/// pressure, which is the most likely cause of a project suddenly
/// failing export with "source missing" days after it was created. This
/// service copies a picked file into the app's **documents** directory
/// (not cleared by the OS) so the DB's `sourceUri` points somewhere
/// durable instead.
///
/// `documentsDir`/`cacheDirs` are injectable so tests can point this at
/// a temp directory instead of needing `path_provider`'s platform
/// channel (same pattern as `AppPrefs(directory: ...)`).
class MediaStorageService {
  final Future<Directory> Function() _documentsDir;

  /// Every directory whose contents should be treated as "clearable
  /// cache" for [isInCache]. Two calls rather than one: `path_provider`
  /// 2.x exposes both `getTemporaryDirectory()` (Android `cacheDir`)
  /// and, on newer versions, `getApplicationCacheDirectory()` (also
  /// `cacheDir` on Android today, but a distinct — and still
  /// OS-clearable — directory on iOS). Checking both means this stays
  /// correct even if `image_picker`/`file_picker` pick a different one
  /// of the two than `ThumbnailService` does (`thumbnail_service.dart`
  /// uses `getApplicationCacheDirectory()`). ⚠️ Not verified against a
  /// real device — see `docs/FACTS.md` F-50/F-90.
  final List<Future<Directory> Function()> _cacheDirs;

  static const _uuid = Uuid();

  MediaStorageService({
    Future<Directory> Function()? documentsDir,
    List<Future<Directory> Function()>? cacheDirs,
  })  : _documentsDir = documentsDir ?? getApplicationDocumentsDirectory,
        _cacheDirs = cacheDirs ??
            [getTemporaryDirectory, getApplicationCacheDirectory];

  /// Copies the file at [sourcePath] into `<documents>/imported_media/`
  /// under a fresh filename (original extension kept) and returns the
  /// new path. On any failure (source gone, disk full, permission
  /// denied) returns [sourcePath] unchanged rather than throwing — a
  /// failed copy should never block an otherwise-successful import; the
  /// clip just keeps pointing at the cache path, same as before P1.
  Future<String> persistToDocuments(String sourcePath) async {
    try {
      final dir = await _documentsDir();
      final destDir = Directory(p.join(dir.path, 'imported_media'));
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }
      final ext = p.extension(sourcePath);
      final destPath = p.join(destDir.path, '${_uuid.v4()}$ext');
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (_) {
      return sourcePath;
    }
  }

  /// True if [path] sits inside one of [_cacheDirs] — i.e. it's a
  /// pre-P1 import (or an install upgrading from before P1) that the
  /// one-time repair pass (`MediaRepairService`) should try to move.
  Future<bool> isInCache(String path) async {
    for (final dirFn in _cacheDirs) {
      try {
        final dir = await dirFn();
        if (p.equals(dir.path, path) || p.isWithin(dir.path, path)) {
          return true;
        }
      } catch (_) {
        // A cache dir call failing (e.g. unsupported on this platform)
        // shouldn't stop checking the others.
      }
    }
    return false;
  }
}
