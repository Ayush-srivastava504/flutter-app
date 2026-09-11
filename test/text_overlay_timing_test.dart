import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/data/project_database.dart';
import 'package:video_editor_app/models/text_overlay_x.dart';

TextOverlay _overlay({required int startMs, required int endMs}) =>
    TextOverlay(
      id: 't',
      projectId: 'p',
      content: 'hi',
      fontFamily: 'Default',
      colorValue: 0xFFFFFFFF,
      fontSize: 24,
      positionX: 0.5,
      positionY: 0.5,
      startMs: startMs,
      endMs: endMs,
      alignment: 1,
    );

void main() {
  group('TextOverlayTiming.activeAt', () {
    test('is active from its start up to (not including) its end', () {
      final overlay = _overlay(startMs: 1000, endMs: 2000);
      expect(overlay.activeAt(999), isFalse);
      expect(overlay.activeAt(1000), isTrue);
      expect(overlay.activeAt(1500), isTrue);
      expect(overlay.activeAt(2000), isFalse);
    });

    test('a zero-length window is never active anywhere', () {
      final overlay = _overlay(startMs: 1000, endMs: 1000);
      expect(overlay.activeAt(1000), isFalse);
    });

    test(
      'back-to-back overlays never both render at the shared boundary '
      '(half-open interval, same convention as TimelinePosition.contains)',
      () {
        final first = _overlay(startMs: 0, endMs: 1000);
        final second = _overlay(startMs: 1000, endMs: 2000);
        expect(first.activeAt(1000) && second.activeAt(1000), isFalse);
        // ...but the boundary instant itself is still covered by one of
        // them, not a gap.
        expect(first.activeAt(1000) || second.activeAt(1000), isTrue);
      },
    );

    test('overlapping ranges are both active in their shared window', () {
      final a = _overlay(startMs: 0, endMs: 2000);
      final b = _overlay(startMs: 1000, endMs: 3000);
      expect(a.activeAt(1500) && b.activeAt(1500), isTrue);
    });
  });
}
