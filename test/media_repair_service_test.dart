import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:video_editor_app/data/project_database.dart';
import 'package:video_editor_app/services/media_repair_service.dart';
import 'package:video_editor_app/services/media_storage_service.dart';

/// Tests for P1's second half — the one-time repair pass
/// (`docs/FEATURE_PLAN_25.md` §1) that moves existing clips/audio
/// tracks off the cache dir, for projects created before P1 shipped.
void main() {
  late Directory tempRoot;
  late Directory documentsDir;
  late Directory cacheDir;
  late ProjectDatabase db;
  late MediaRepairService repair;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('media_repair_test');
    documentsDir = Directory(p.join(tempRoot.path, 'documents'))..createSync();
    cacheDir = Directory(p.join(tempRoot.path, 'cache'))..createSync();
    db = ProjectDatabase.forTesting(NativeDatabase.memory());
    final storage = MediaStorageService(
      documentsDir: () async => documentsDir,
      cacheDirs: [() async => cacheDir],
    );
    repair = MediaRepairService(db, storage: storage);

    await db.insertProject(ProjectsCompanion.insert(
      id: 'p1',
      name: 'Old project',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ));
  });

  tearDown(() async {
    await db.close();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('moves a clip whose sourceUri is still in the cache dir and still exists', () async {
    final cachedFile = File(p.join(cacheDir.path, 'clip.mp4'))
      ..writeAsBytesSync([1, 2, 3]);
    await db.insertClip(ClipsCompanion.insert(
      id: 'c1',
      projectId: 'p1',
      sourceUri: cachedFile.path,
      orderIndex: 0,
      trimEndMs: 1000,
      durationMs: 1000,
    ));

    final result = await repair.repairCachedMedia();

    expect(result.repaired, 1);
    expect(result.alreadyMissing, 0);

    final clip = (await db.getClip('c1'))!;
    expect(clip.sourceUri, isNot(cachedFile.path));
    expect(p.isWithin(documentsDir.path, clip.sourceUri), isTrue);
    expect(await File(clip.sourceUri).exists(), isTrue);
  });

  test('counts a cached clip whose file is already gone as alreadyMissing, and leaves it untouched', () async {
    final goneePath = p.join(cacheDir.path, 'never_existed.mp4');
    await db.insertClip(ClipsCompanion.insert(
      id: 'c1',
      projectId: 'p1',
      sourceUri: goneePath,
      orderIndex: 0,
      trimEndMs: 1000,
      durationMs: 1000,
    ));

    final result = await repair.repairCachedMedia();

    expect(result.repaired, 0);
    expect(result.alreadyMissing, 1);
    expect((await db.getClip('c1'))!.sourceUri, goneePath);
  });

  test('leaves a clip already in documents (P1-imported) alone', () async {
    final documentsFile = File(p.join(documentsDir.path, 'imported_media', 'clip.mp4'))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1]);
    await db.insertClip(ClipsCompanion.insert(
      id: 'c1',
      projectId: 'p1',
      sourceUri: documentsFile.path,
      orderIndex: 0,
      trimEndMs: 1000,
      durationMs: 1000,
    ));

    final result = await repair.repairCachedMedia();

    expect(result.repaired, 0);
    expect(result.alreadyMissing, 0);
    expect((await db.getClip('c1'))!.sourceUri, documentsFile.path);
  });

  test('moves an audio track the same way', () async {
    final cachedFile = File(p.join(cacheDir.path, 'music.mp3'))
      ..writeAsBytesSync([4, 5, 6]);
    await db.setAudioTrack(
      id: 'a1',
      projectId: 'p1',
      sourceUri: cachedFile.path,
      durationMs: 8000,
    );

    final result = await repair.repairCachedMedia();

    expect(result.repaired, 1);
    final track = (await db.getAudioTrack('p1'))!;
    expect(p.isWithin(documentsDir.path, track.sourceUri), isTrue);
  });

  test('sweeps clips and audio across every project in one pass', () async {
    await db.insertProject(ProjectsCompanion.insert(
      id: 'p2',
      name: 'Another old project',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ));
    final clip1 = File(p.join(cacheDir.path, 'a.mp4'))..writeAsBytesSync([1]);
    final clip2 = File(p.join(cacheDir.path, 'b.mp4'))..writeAsBytesSync([2]);
    await db.insertClip(ClipsCompanion.insert(
      id: 'c1',
      projectId: 'p1',
      sourceUri: clip1.path,
      orderIndex: 0,
      trimEndMs: 1000,
      durationMs: 1000,
    ));
    await db.insertClip(ClipsCompanion.insert(
      id: 'c2',
      projectId: 'p2',
      sourceUri: clip2.path,
      orderIndex: 0,
      trimEndMs: 1000,
      durationMs: 1000,
    ));

    final result = await repair.repairCachedMedia();

    expect(result.repaired, 2);
  });

  test('running it twice in a row only repairs once (idempotent)', () async {
    final cachedFile = File(p.join(cacheDir.path, 'clip.mp4'))
      ..writeAsBytesSync([1, 2, 3]);
    await db.insertClip(ClipsCompanion.insert(
      id: 'c1',
      projectId: 'p1',
      sourceUri: cachedFile.path,
      orderIndex: 0,
      trimEndMs: 1000,
      durationMs: 1000,
    ));

    final first = await repair.repairCachedMedia();
    final second = await repair.repairCachedMedia();

    expect(first.repaired, 1);
    expect(second.repaired, 0);
    expect(second.alreadyMissing, 0);
  });
}
