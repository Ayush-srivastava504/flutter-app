import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/data/project_database.dart';

/// Tests for F2 (duplicate clip): `ProjectDatabase.duplicateClip`.
void main() {
  late ProjectDatabase db;

  setUp(() => db = ProjectDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Three clips: A (0), B (1, fully customised), C (2).
  Future<void> seed() async {
    await db.insertProject(ProjectsCompanion.insert(
      id: 'p1',
      name: 'Project',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ));
    await db.insertClip(ClipsCompanion.insert(
      id: 'a',
      projectId: 'p1',
      sourceUri: '/media/a.mp4',
      orderIndex: 0,
      trimEndMs: 5000,
      durationMs: 5000,
    ));
    await db.insertClip(ClipsCompanion.insert(
      id: 'b',
      projectId: 'p1',
      sourceUri: '/media/b.mp4',
      orderIndex: 1,
      trimStartMs: const Value(1000),
      trimEndMs: 7000,
      durationMs: 10000,
      rotationDegrees: const Value(90),
      thumbnailUri: const Value('/thumbs/b.jpg'),
      transitionOut: const Value('dissolve'),
      brightness: const Value(0.2),
      contrast: const Value(0.1),
      saturation: const Value(-0.3),
      filterPreset: const Value('vintage'),
      muted: const Value(true),
      volume: const Value(0.4),
    ));
    await db.insertClip(ClipsCompanion.insert(
      id: 'c',
      projectId: 'p1',
      sourceUri: '/media/c.mp4',
      orderIndex: 2,
      trimEndMs: 3000,
      durationMs: 3000,
    ));
  }

  Future<List<Clip>> clips() => db.watchClips('p1').first;

  group('duplicateClip', () {
    test('copy lands right after the original and order stays contiguous', () async {
      await seed();
      final newId = await db.duplicateClip('b', newClipId: 'b2');
      expect(newId, 'b2');

      final all = await clips();
      expect(all.map((c) => c.id).toList(), ['a', 'b', 'b2', 'c']);
      expect(all.map((c) => c.orderIndex).toList(), [0, 1, 2, 3]);
    });

    test('duplicating the last clip appends the copy', () async {
      await seed();
      await db.duplicateClip('c', newClipId: 'c2');

      final all = await clips();
      expect(all.map((c) => c.id).toList(), ['a', 'b', 'c', 'c2']);
      expect(all.map((c) => c.orderIndex).toList(), [0, 1, 2, 3]);
    });

    test('duplicating the first clip shifts everything else down', () async {
      await seed();
      await db.duplicateClip('a', newClipId: 'a2');

      final all = await clips();
      expect(all.map((c) => c.id).toList(), ['a', 'a2', 'b', 'c']);
      expect(all.map((c) => c.orderIndex).toList(), [0, 1, 2, 3]);
    });

    test('copy carries every editable property of the original', () async {
      await seed();
      await db.duplicateClip('b', newClipId: 'b2');

      final copy = (await db.getClip('b2'))!;
      expect(copy.projectId, 'p1');
      expect(copy.sourceUri, '/media/b.mp4');
      expect(copy.trimStartMs, 1000);
      expect(copy.trimEndMs, 7000);
      expect(copy.durationMs, 10000);
      expect(copy.rotationDegrees, 90);
      expect(copy.thumbnailUri, '/thumbs/b.jpg');
      expect(copy.brightness, 0.2);
      expect(copy.contrast, 0.1);
      expect(copy.saturation, -0.3);
      expect(copy.filterPreset, 'vintage');
      expect(copy.muted, isTrue);
      expect(copy.volume, 0.4);
    });

    test('original becomes a plain cut; copy inherits the outgoing transition', () async {
      await seed();
      await db.duplicateClip('b', newClipId: 'b2');

      expect((await db.getClip('b'))!.transitionOut, 'cut');
      expect((await db.getClip('b2'))!.transitionOut, 'dissolve');
    });

    test('generates a fresh id when none is given', () async {
      await seed();
      final newId = await db.duplicateClip('b');

      expect(newId, isNotNull);
      expect(newId, isNot('b'));
      expect(await db.getClip(newId!), isNotNull);
      expect((await clips()).length, 4);
    });

    test('copy is independent: editing it does not touch the original', () async {
      await seed();
      await db.duplicateClip('b', newClipId: 'b2');

      final copy = (await db.getClip('b2'))!;
      await db.updateClip(copy.copyWith(trimEndMs: 2000, volume: 1.0));

      final original = (await db.getClip('b'))!;
      expect(original.trimEndMs, 7000);
      expect(original.volume, 0.4);
    });

    test('unknown clip id returns null and changes nothing', () async {
      await seed();
      expect(await db.duplicateClip('missing'), isNull);

      final all = await clips();
      expect(all.map((c) => c.id).toList(), ['a', 'b', 'c']);
      expect(all.map((c) => c.orderIndex).toList(), [0, 1, 2]);
      expect(all[1].transitionOut, 'dissolve'); // untouched
    });

    test('undo: restoring the earlier snapshot removes the copy', () async {
      await seed();
      final before = await db.snapshotProject('p1');
      await db.duplicateClip('b', newClipId: 'b2');
      expect((await db.snapshotProject('p1')) == before, isFalse);

      await db.restoreProject('p1', before);

      final all = await clips();
      expect(all.map((c) => c.id).toList(), ['a', 'b', 'c']);
      expect(all[1].transitionOut, 'dissolve'); // original transition restored
    });
  });
}
