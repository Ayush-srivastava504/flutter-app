import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/data/project_database.dart';

/// Regression tests for `ProjectDatabase.splitClip` (FACTS.md B-01, B-02):
///  * the second half used to come back at volume 1.0 and lose its look
///    (`filterPreset`) because those columns weren't copied;
///  * the first half used to keep its own outgoing transition *and* hand a
///    copy to the second half, producing a fade/dissolve into its own other
///    piece at export time.
void main() {
  late ProjectDatabase db;

  setUp(() => db = ProjectDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seed(String projectId) async {
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
      trimEndMs: 10000,
      durationMs: 10000,
      transitionOut: const Value('dissolve'),
      volume: const Value(0.4),
      filterPreset: const Value('vintage'),
      brightness: const Value(0.2),
      muted: const Value(true),
    ));
    await db.insertClip(ClipsCompanion.insert(
      id: '$projectId-clip2',
      projectId: projectId,
      sourceUri: '/media/b.mp4',
      orderIndex: 1,
      trimEndMs: 3000,
      durationMs: 3000,
    ));
  }

  group('splitClip', () {
    test('second half keeps the original volume and filter preset (B-01)', () async {
      await seed('p1');
      await db.splitClip('p1-clip1', 4000, 'p1-clip1-b');

      final second = (await db.getClip('p1-clip1-b'))!;
      expect(second.volume, 0.4);
      expect(second.filterPreset, 'vintage');
      expect(second.brightness, 0.2);
      expect(second.muted, isTrue);
    });

    test('first half becomes a plain cut; second half keeps the outgoing transition (B-02)', () async {
      await seed('p1');
      await db.splitClip('p1-clip1', 4000, 'p1-clip1-b');

      final first = (await db.getClip('p1-clip1'))!;
      final second = (await db.getClip('p1-clip1-b'))!;
      expect(first.transitionOut, 'cut');
      expect(second.transitionOut, 'dissolve');
    });

    test('trims and order index are still split correctly', () async {
      await seed('p1');
      await db.splitClip('p1-clip1', 4000, 'p1-clip1-b');

      final first = (await db.getClip('p1-clip1'))!;
      final second = (await db.getClip('p1-clip1-b'))!;
      final third = (await db.getClip('p1-clip2'))!;

      expect(first.trimStartMs, 0);
      expect(first.trimEndMs, 4000);
      expect(second.trimStartMs, 4000);
      expect(second.trimEndMs, 10000);
      expect(second.orderIndex, 1);
      expect(third.orderIndex, 2); // shifted to make room
    });

    test('is a no-op when the split point is outside the trim window', () async {
      await seed('p1');
      await db.splitClip('p1-clip1', 0, 'p1-clip1-b'); // == trimStartMs
      await db.splitClip('p1-clip1', 10000, 'p1-clip1-c'); // == trimEndMs

      expect(await db.getClip('p1-clip1-b'), isNull);
      expect(await db.getClip('p1-clip1-c'), isNull);
      expect((await db.watchClips('p1').first).length, 2);
    });
  });
}
