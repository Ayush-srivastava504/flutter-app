import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/data/project_database.dart';

/// Tests for F1 (rename / delete / duplicate a project): `renameProject`,
/// `deleteProjectCascade`, `duplicateProject` in `project_database.dart`.
/// Uses an in-memory database (same approach as
/// `project_database_migration_test.dart`, minus the on-disk file since
/// these tests don't need to reopen the database mid-test).
void main() {
  late ProjectDatabase db;

  setUp(() => db = ProjectDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seedProject(String projectId) async {
    await db.insertProject(ProjectsCompanion.insert(
      id: projectId,
      name: 'Original',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ));
    await db.insertClip(ClipsCompanion.insert(
      id: '$projectId-clip1',
      projectId: projectId,
      sourceUri: '/media/a.mp4',
      orderIndex: 0,
      trimEndMs: 5000,
      durationMs: 5000,
    ));
    await db.insertClip(ClipsCompanion.insert(
      id: '$projectId-clip2',
      projectId: projectId,
      sourceUri: '/media/b.mp4',
      orderIndex: 1,
      trimEndMs: 3000,
      durationMs: 3000,
    ));
    await db.setAudioTrack(
      id: '$projectId-audio1',
      projectId: projectId,
      sourceUri: '/media/music.mp3',
      durationMs: 8000,
    );
    await db.insertTextOverlay(TextOverlaysCompanion.insert(
      id: '$projectId-text1',
      projectId: projectId,
      content: 'hello',
      endMs: 2000,
    ));
  }

  group('renameProject', () {
    test('updates the name and leaves other projects untouched', () async {
      await seedProject('p1');
      await seedProject('p2');

      await db.renameProject('p1', 'My Trip');

      expect((await db.getProject('p1'))!.name, 'My Trip');
      expect((await db.getProject('p2'))!.name, 'Original');
    });

    test('is a no-op for an id that does not exist', () async {
      await db.renameProject('missing', 'New name');
      expect(await db.getProject('missing'), isNull);
    });
  });

  group('deleteProjectCascade', () {
    test('removes the project and every clip/audio/text row it owns', () async {
      await seedProject('p1');
      await seedProject('p2'); // control group: must survive untouched

      await db.deleteProjectCascade('p1');

      expect(await db.getProject('p1'), isNull);
      expect(await db.watchClips('p1').first, isEmpty);
      expect(await db.getAudioTrack('p1'), isNull);
      expect(await db.watchTextOverlays('p1').first, isEmpty);

      // p2's rows are untouched by p1's cascade.
      expect(await db.getProject('p2'), isNotNull);
      expect(await db.watchClips('p2').first, hasLength(2));
      expect(await db.getAudioTrack('p2'), isNotNull);
      expect(await db.watchTextOverlays('p2').first, hasLength(1));
    });
  });

  group('duplicateProject', () {
    test('copies the project row and every child row with fresh ids', () async {
      await seedProject('p1');

      final newId = await db.duplicateProject('p1', newProjectId: 'p1-copy');

      expect(newId, 'p1-copy');
      final copy = await db.getProject('p1-copy');
      expect(copy, isNotNull);
      expect(copy!.name, 'Original (copy)');
      expect(copy.aspectRatio, (await db.getProject('p1'))!.aspectRatio);

      final copiedClips = await db.watchClips('p1-copy').first;
      expect(copiedClips, hasLength(2));
      // Fresh ids: no overlap with the original clip ids.
      expect(copiedClips.map((c) => c.id), isNot(contains('p1-clip1')));
      expect(copiedClips.map((c) => c.id), isNot(contains('p1-clip2')));
      // Source media is referenced, not copied.
      expect(copiedClips.map((c) => c.sourceUri), containsAll(['/media/a.mp4', '/media/b.mp4']));
      // orderIndex is preserved so the duplicate's timeline looks identical.
      expect(copiedClips.firstWhere((c) => c.sourceUri == '/media/a.mp4').orderIndex, 0);
      expect(copiedClips.firstWhere((c) => c.sourceUri == '/media/b.mp4').orderIndex, 1);

      final copiedAudio = await db.getAudioTrack('p1-copy');
      expect(copiedAudio, isNotNull);
      expect(copiedAudio!.id, isNot('p1-audio1'));
      expect(copiedAudio.sourceUri, '/media/music.mp3');

      final copiedText = await db.watchTextOverlays('p1-copy').first;
      expect(copiedText, hasLength(1));
      expect(copiedText.single.content, 'hello');
      expect(copiedText.single.id, isNot('p1-text1'));

      // The original project is completely untouched.
      expect(await db.watchClips('p1').first, hasLength(2));
      expect((await db.getProject('p1'))!.name, 'Original');
    });

    test('the duplicate edits independently of the original', () async {
      await seedProject('p1');
      final newId = (await db.duplicateProject('p1'))!;

      final copiedClip = (await db.watchClips(newId).first).first;
      await db.updateClip(copiedClip.copyWith(brightness: 0.5));

      final originalClip = (await db.watchClips('p1').first)
          .firstWhere((c) => c.sourceUri == copiedClip.sourceUri);
      expect(originalClip.brightness, 0.0);
    });

    test('returns null for an id that does not exist', () async {
      expect(await db.duplicateProject('missing'), isNull);
    });

    test('generates an id when newProjectId is omitted', () async {
      await seedProject('p1');
      final newId = await db.duplicateProject('p1');
      expect(newId, isNotNull);
      expect(newId, isNot('p1'));
      expect(await db.getProject(newId!), isNotNull);
    });
  });
}
