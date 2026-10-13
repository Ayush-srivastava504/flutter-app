import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:video_editor_app/data/project_database.dart';
import 'package:video_editor_app/services/sample_project_service.dart';

/// Tests for P2's fixture builder (`docs/FEATURE_PLAN_25.md` §1).
/// Needs `TestWidgetsFlutterBinding` (not just `flutter_test`'s
/// `test`/`expect`, unlike every other file in this folder) because
/// `SampleProjectService` reads `assets/dev/*` via `rootBundle`, which
/// only resolves once the test binding is initialized — `flutter test`
/// serves the real pubspec assets to it, same as a widget test loading
/// an `Image.asset`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late Directory documentsDir;
  late ProjectDatabase db;
  late SampleProjectService service;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('sample_project_test');
    documentsDir = Directory(p.join(tempRoot.path, 'documents'))..createSync();
    db = ProjectDatabase.forTesting(NativeDatabase.memory());
    service = SampleProjectService(db, documentsDir: () async => documentsDir);
  });

  tearDown(() async {
    await db.close();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('creates a project with 2 video clips, 1 photo clip, and a music track', () async {
    final id = await service.create();

    final project = await db.getProject(id);
    expect(project, isNotNull);
    expect(project!.name, 'Sample Project');

    final clips = await db.watchClips(id).first;
    expect(clips, hasLength(3));
    expect(clips.map((c) => c.orderIndex), [0, 1, 2]);
    for (final c in clips) {
      expect(await File(c.sourceUri).exists(), isTrue,
          reason: '${c.sourceUri} should have been copied into documents');
      expect(p.isWithin(documentsDir.path, c.sourceUri), isTrue);
    }
    // The photo clip (3rd appended) gets the standard 3 s photo duration.
    expect(clips.last.durationMs, 3000);

    final audio = await db.getAudioTrack(id);
    expect(audio, isNotNull);
    expect(await File(audio!.sourceUri).exists(), isTrue);
  });

  test('creating it twice gives each project its own name', () async {
    final id1 = await service.create();
    final id2 = await service.create();

    expect(id1, isNot(id2));
    final name1 = (await db.getProject(id1))!.name;
    final name2 = (await db.getProject(id2))!.name;
    expect({name1, name2}, {'Sample Project', 'Sample Project (2)'});
  });

  test('the underlying media files are only copied once and then reused', () async {
    await service.create();
    final firstCopyTime = await File(
      p.join(documentsDir.path, 'dev_samples', 'dev_sample_clip_1.mp4'),
    ).lastModified();

    await Future<void>.delayed(const Duration(milliseconds: 5));
    await service.create();
    final secondCopyTime = await File(
      p.join(documentsDir.path, 'dev_samples', 'dev_sample_clip_1.mp4'),
    ).lastModified();

    expect(secondCopyTime, firstCopyTime); // not rewritten the second time
  });
}
