import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/models/transition_x.dart';

void main() {
  group('transitionPreviewAt', () {
    test('is always "none" for a cut, regardless of playhead position', () {
      final atBoundary = transitionPreviewAt(
        transitionOut: 'cut',
        playheadMs: 4900,
        boundaryMs: 5000,
      );
      expect(atBoundary, TransitionPreview.none);

      final wellBefore = transitionPreviewAt(
        transitionOut: 'cut',
        playheadMs: 1000,
        boundaryMs: 5000,
      );
      expect(wellBefore, TransitionPreview.none);
    });

    test('is "none" outside the transition window, before it starts', () {
      final preview = transitionPreviewAt(
        transitionOut: 'dissolve',
        playheadMs: 5000 - transitionWindowMs - 1,
        boundaryMs: 5000,
      );
      expect(preview, TransitionPreview.none);
    });

    test('is "none" once the playhead reaches or passes the boundary', () {
      final atBoundary = transitionPreviewAt(
        transitionOut: 'dissolve',
        playheadMs: 5000,
        boundaryMs: 5000,
      );
      expect(atBoundary, TransitionPreview.none);

      final past = transitionPreviewAt(
        transitionOut: 'dissolve',
        playheadMs: 5100,
        boundaryMs: 5000,
      );
      expect(past, TransitionPreview.none);
    });

    test('dissolve is a straight linear crossfade across the window', () {
      final start = transitionPreviewAt(
        transitionOut: 'dissolve',
        playheadMs: 5000 - transitionWindowMs,
        boundaryMs: 5000,
      );
      expect(start.currentOpacity, closeTo(1.0, 0.001));
      expect(start.nextOpacity, closeTo(0.0, 0.001));

      final halfway = transitionPreviewAt(
        transitionOut: 'dissolve',
        playheadMs: 5000 - (transitionWindowMs ~/ 2),
        boundaryMs: 5000,
      );
      expect(halfway.currentOpacity, closeTo(0.5, 0.02));
      expect(halfway.nextOpacity, closeTo(0.5, 0.02));

      final justBeforeEnd = transitionPreviewAt(
        transitionOut: 'dissolve',
        playheadMs: 4999,
        boundaryMs: 5000,
      );
      expect(justBeforeEnd.currentOpacity, closeTo(0.0, 0.01));
      expect(justBeforeEnd.nextOpacity, closeTo(1.0, 0.01));

      // The two opacities always sum to 1 for a dissolve — nothing
      // should be double-counted or left transparent.
      for (final preview in [start, halfway, justBeforeEnd]) {
        expect(preview.currentOpacity + preview.nextOpacity, closeTo(1.0, 0.001));
      }
    });

    test('fade goes to black at the window midpoint, unlike dissolve', () {
      final midpoint = transitionPreviewAt(
        transitionOut: 'fade',
        playheadMs: 5000 - (transitionWindowMs ~/ 2),
        boundaryMs: 5000,
      );
      // Both layers transparent — the black backdrop shows through.
      expect(midpoint.currentOpacity, closeTo(0.0, 0.02));
      expect(midpoint.nextOpacity, closeTo(0.0, 0.02));
    });

    test('fade fades the current clip out over the first half only', () {
      final quarterIn = transitionPreviewAt(
        transitionOut: 'fade',
        playheadMs: 5000 - (transitionWindowMs * 3 ~/ 4),
        boundaryMs: 5000,
      );
      expect(quarterIn.nextOpacity, 0);
      expect(quarterIn.currentOpacity, greaterThan(0));
      expect(quarterIn.currentOpacity, lessThan(1));
    });

    test('fade fades the next clip in over the second half only', () {
      final threeQuartersIn = transitionPreviewAt(
        transitionOut: 'fade',
        playheadMs: 5000 - (transitionWindowMs ~/ 4),
        boundaryMs: 5000,
      );
      expect(threeQuartersIn.currentOpacity, 0);
      expect(threeQuartersIn.nextOpacity, greaterThan(0));
      expect(threeQuartersIn.nextOpacity, lessThan(1));
    });

    test('fade ends fully on the next clip\'s thumbnail at the boundary',
        () {
      final justBeforeEnd = transitionPreviewAt(
        transitionOut: 'fade',
        playheadMs: 4999,
        boundaryMs: 5000,
      );
      expect(justBeforeEnd.nextOpacity, closeTo(1.0, 0.01));
    });
  });
}
