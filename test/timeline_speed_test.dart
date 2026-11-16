import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/export/export_command_builder.dart';
import 'package:video_editor_app/export/export_inputs.dart';
import 'package:video_editor_app/models/clip_x.dart';

import 'support/fixtures.dart';

/// The editor timeline and the export must agree on how long a clip is.
/// Before this was fixed `trimmedDurationMs` ignored speed, so a 2x clip
/// took twice as much room in the editor as in the exported video and every
/// later clip, text and music cue was misplaced.
void main() {
  group('ClipTiming with speed', () {
    test('timeline duration is the source span divided by speed', () {
      expect(clipRow(trimStartMs: 1000, trimEndMs: 5000).trimmedDurationMs, 4000);
      expect(clipRow(trimStartMs: 1000, trimEndMs: 5000, speed: 2).trimmedDurationMs, 2000);
      expect(clipRow(trimStartMs: 1000, trimEndMs: 5000, speed: 0.5).trimmedDurationMs, 8000);
      expect(clipRow(trimEndMs: 4000, speed: 4).trimmedDurationMs, 1000);
    });

    test('photos ignore speed, and a corrupt speed is treated as 1.0', () {
      expect(clipRow(sourceUri: '/p.jpg', trimEndMs: 3000, speed: 2).trimmedDurationMs, 3000);
      expect(clipRow(trimEndMs: 3000, speed: 0).trimmedDurationMs, 3000);
      expect(clipRow(trimEndMs: 3000, speed: -1).effectiveSpeed, 1.0);
    });

    test('timeline <-> source offset conversion round-trips', () {
      final c = clipRow(trimEndMs: 8000, speed: 2);
      expect(c.timelineToSourceOffsetMs(1000), 2000);
      expect(c.sourceToTimelineOffsetMs(2000), 1000);
      final slow = clipRow(trimEndMs: 8000, speed: 0.5);
      expect(slow.timelineToSourceOffsetMs(1000), 500);
      expect(slow.sourceToTimelineOffsetMs(500), 1000);
    });

    test('layoutTimeline places later clips after the sped-up length', () {
      final layout = layoutTimeline([
        clipRow(id: 'a', trimEndMs: 4000, speed: 2), // 2 s
        clipRow(id: 'b', trimEndMs: 3000), // 3 s
        clipRow(id: 'c', trimEndMs: 1000, speed: 0.5), // 2 s
      ]);
      expect([for (final p in layout) (p.startMs, p.endMs)], [(0, 2000), (2000, 5000), (5000, 7000)]);
    });
  });

  test('editor timeline length equals the export duration for the same rows', () {
    final rows = [
      clipRow(id: 'a', trimStartMs: 500, trimEndMs: 4500, speed: 2),
      clipRow(id: 'b', sourceUri: '/p.png', trimEndMs: 3000, speed: 3), // photo: speed ignored
      clipRow(id: 'c', trimEndMs: 5000, speed: 0.25),
      clipRow(id: 'd', trimEndMs: 3333, speed: 1.5),
    ];
    final editorTotal = layoutTimeline(rows).last.endMs;
    final exportTotal = exportDurationMs(exportClipsFrom(rows, const {}));
    expect(editorTotal, exportTotal);

    // Clip by clip too, not just the sum.
    final exported = exportClipsFrom(rows, const {});
    for (var i = 0; i < rows.length; i++) {
      expect(rows[i].trimmedDurationMs, exported[i].durationMs, reason: 'clip ${rows[i].id}');
    }
  });
}
