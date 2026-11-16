import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/models/text_overlay_x.dart';

void main() {
  group('letterboxedFrame', () {
    test('falls back to the full canvas when the aspect ratio is unknown', () {
      final frame = letterboxedFrame(const Size(300, 500), null);
      expect(frame.offset, Offset.zero);
      expect(frame.size, const Size(300, 500));
    });

    test('falls back to the full canvas for a degenerate aspect ratio', () {
      final frame = letterboxedFrame(const Size(300, 500), 0);
      expect(frame.offset, Offset.zero);
      expect(frame.size, const Size(300, 500));
    });

    test(
      'letterboxes top/bottom when the frame is relatively wider than '
      'the container (e.g. a 16:9 clip in a 9:16 preview)',
      () {
        final frame = letterboxedFrame(const Size(360, 640), 16 / 9);
        expect(frame.size.width, 360);
        expect(frame.offset.dx, 0);
        expect(frame.offset.dy, greaterThan(0));
        // Centered: the two letterbox bars are equal, so the frame
        // should exactly fill the remaining vertical space.
        expect(
          frame.offset.dy * 2 + frame.size.height,
          closeTo(640, 0.01),
        );
      },
    );

    test(
      'letterboxes left/right when the frame is relatively taller than '
      'the container (e.g. a 9:16 clip in a square preview)',
      () {
        final frame = letterboxedFrame(const Size(360, 360), 9 / 16);
        expect(frame.size.height, 360);
        expect(frame.offset.dy, 0);
        expect(frame.offset.dx, greaterThan(0));
        expect(frame.offset.dx * 2 + frame.size.width, closeTo(360, 0.01));
      },
    );

    test('fills the canvas exactly when the aspect ratios match', () {
      final frame = letterboxedFrame(const Size(360, 640), 360 / 640);
      expect(frame.offset, Offset.zero);
      expect(frame.size.width, closeTo(360, 0.01));
      expect(frame.size.height, closeTo(640, 0.01));
    });
  });

  group('dragFractionDelta', () {
    test('converts a pixel delta into a fraction of the frame', () {
      const frame = Size(200, 100);
      final moved =
          dragFractionDelta(const Offset(0.5, 0.5), const Offset(20, 10), frame);
      expect(moved.dx, closeTo(0.6, 1e-9));
      expect(moved.dy, closeTo(0.6, 1e-9));
    });

    test('clamps at the frame edges rather than overshooting', () {
      const frame = Size(200, 100);
      final moved = dragFractionDelta(
          const Offset(0.95, 0.95), const Offset(50, 50), frame);
      expect(moved.dx, 1.0);
      expect(moved.dy, 1.0);

      final movedNegative = dragFractionDelta(
          const Offset(0.05, 0.05), const Offset(-50, -50), frame);
      expect(movedNegative.dx, 0.0);
      expect(movedNegative.dy, 0.0);
    });

    test('is a no-op against a zero-size frame instead of dividing by zero', () {
      final moved =
          dragFractionDelta(const Offset(0.5, 0.5), const Offset(20, 10), Size.zero);
      expect(moved, const Offset(0.5, 0.5));
    });
  });
}
