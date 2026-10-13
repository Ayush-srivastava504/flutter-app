import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/data/project_database.dart';
import 'package:video_editor_app/models/clip_x.dart';

/// Tests for F4 (playhead tools): the pure helpers next to `layoutTimeline`.
void main() {
  // Boundaries of a 3 s + 2 s + 1 s timeline.
  const b = [0, 3000, 5000, 6000];

  group('clipBoundariesMs', () {
    late ProjectDatabase db;
    setUp(() => db = ProjectDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> addClip(String id, int order, int start, int end) => db.insertClip(ClipsCompanion.insert(
          id: id,
          projectId: 'p1',
          sourceUri: '/media/$id.mp4',
          orderIndex: order,
          trimStartMs: Value(start),
          trimEndMs: end,
          durationMs: 10000,
        ));

    test('empty timeline has no boundaries', () {
      expect(clipBoundariesMs(layoutTimeline(const [])), isEmpty);
    });

    test('lists every clip start and the end, using trimmed lengths', () async {
      await db.insertProject(ProjectsCompanion.insert(
        id: 'p1',
        name: 'P',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ));
      await addClip('a', 0, 0, 3000); // 3 s
      await addClip('b', 1, 1000, 3000); // 2 s (trimmed)
      await addClip('c', 2, 0, 1000); // 1 s

      final clips = await db.watchClips('p1').first;
      expect(clipBoundariesMs(layoutTimeline(clips)), b);
    });
  });

  group('previousBoundaryMs', () {
    test('from inside a clip goes to that clip\'s start', () {
      expect(previousBoundaryMs(b, 4000), 3000);
      expect(previousBoundaryMs(b, 3001), 3000);
    });
    test('from exactly a clip start goes to the previous clip\'s start', () {
      expect(previousBoundaryMs(b, 3000), 0);
      expect(previousBoundaryMs(b, 5000), 3000);
    });
    test('first clip: stays at 0', () {
      expect(previousBoundaryMs(b, 0), 0);
      expect(previousBoundaryMs(b, 1500), 0);
    });
    test('from the end of the timeline goes to the last clip\'s start', () {
      expect(previousBoundaryMs(b, 6000), 5000);
    });
    test('empty timeline -> 0', () {
      expect(previousBoundaryMs(const [], 1234), 0);
    });
  });

  group('nextBoundaryMs', () {
    test('goes to the next clip start', () {
      expect(nextBoundaryMs(b, 0), 3000);
      expect(nextBoundaryMs(b, 2999), 3000);
      expect(nextBoundaryMs(b, 3000), 5000);
    });
    test('last clip: goes to the end of the timeline, then stays', () {
      expect(nextBoundaryMs(b, 5500), 6000);
      expect(nextBoundaryMs(b, 6000), 6000);
      expect(nextBoundaryMs(b, 9999), 6000);
    });
    test('empty timeline -> 0', () {
      expect(nextBoundaryMs(const [], 1234), 0);
    });
  });

  group('stepFrameMs', () {
    test('one frame at 30 fps is ~33 ms', () {
      expect(stepFrameMs(0, 1, 10000), 33);
      expect(stepFrameMs(33, 1, 10000), 67);
    });
    test('30 forward steps land exactly on 1 s (no rounding drift)', () {
      var ms = 0;
      for (var i = 0; i < 30; i++) {
        ms = stepFrameMs(ms, 1, 10000);
      }
      expect(ms, 1000);
    });
    test('forward then back returns to the same frame', () {
      for (final start in [0, 33, 67, 1000, 4567, 9967]) {
        final there = stepFrameMs(start, 1, 10000);
        expect(there, greaterThan(start));
        expect(stepFrameMs(there, -1, 10000), stepFrameMs(start, 0, 10000), reason: 'start=$start');
      }
    });
    test('always moves when not at an edge', () {
      for (var ms = 100; ms < 9900; ms += 7) {
        expect(stepFrameMs(ms, 1, 10000), greaterThan(ms), reason: 'ms=$ms');
        expect(stepFrameMs(ms, -1, 10000), lessThan(ms), reason: 'ms=$ms');
      }
    });
    test('clamps to 0 and to the end', () {
      expect(stepFrameMs(0, -1, 10000), 0);
      expect(stepFrameMs(10, -1, 10000), 0);
      expect(stepFrameMs(10000, 1, 10000), 10000);
      expect(stepFrameMs(9990, 1, 10000), 10000);
    });
    test('empty timeline -> 0', () {
      expect(stepFrameMs(500, 1, 0), 0);
    });
    test('other frame rates', () {
      expect(stepFrameMs(0, 1, 10000, fps: 60), 17);
      expect(stepFrameMs(0, 1, 10000, fps: 24), 42);
    });
  });

  group('snapToBoundaryMs', () {
    const edges = [0, 3000, 5000];
    test('snaps when within the threshold', () {
      expect(snapToBoundaryMs(edges, 2950, 100), 3000);
      expect(snapToBoundaryMs(edges, 3080, 100), 3000);
      expect(snapToBoundaryMs(edges, 40, 100), 0);
    });
    test('leaves the value alone when nothing is close', () {
      expect(snapToBoundaryMs(edges, 2800, 100), 2800);
      expect(snapToBoundaryMs(edges, 4000, 100), 4000);
    });
    test('picks the nearest of several candidates', () {
      expect(snapToBoundaryMs(edges, 3900, 1500), 3000);
      expect(snapToBoundaryMs(edges, 4200, 1500), 5000);
    });
    test('threshold 0 only matches exactly', () {
      expect(snapToBoundaryMs(edges, 3000, 0), 3000);
      expect(snapToBoundaryMs(edges, 3001, 0), 3001);
    });
    test('no boundaries -> unchanged', () {
      expect(snapToBoundaryMs(const [], 1234, 500), 1234);
    });
  });

  group('formatTimecode', () {
    test('m:ss:ff at 30 fps', () {
      expect(formatTimecode(0), '0:00:00');
      expect(formatTimecode(33), '0:00:01');
      expect(formatTimecode(3400), '0:03:12');
      expect(formatTimecode(61000), '1:01:00');
    });
    test('rounds up into the next second instead of showing frame 30', () {
      expect(formatTimecode(999), '0:01:00');
    });
    test('negative input is treated as 0', () {
      expect(formatTimecode(-50), '0:00:00');
    });
  });
}
