import 'package:flutter/material.dart';

import '../data/project_database.dart';

extension TextOverlayTiming on TextOverlay {
  /// Whether this overlay should be visible at [playheadMs] — same
  /// half-open-interval convention as `TimelinePosition.contains` in
  /// clip_x.dart, so an overlay ending exactly where the next one starts
  /// doesn't render both at once by accident.
  bool activeAt(int playheadMs) => playheadMs >= startMs && playheadMs < endMs;
}

/// Small preset list rather than a font picker — keeps Phase 6 from
/// pulling in bundled font assets or a `google_fonts` dependency. These
/// are generic family names Android's Skia font matcher resolves
/// directly; iOS falls back to the system font if a given name isn't
/// installed, which degrades gracefully rather than crashing. Swapping
/// in real bundled fonts later only means changing this list and adding
/// the assets — nothing else downstream cares how a preset maps to a
/// family string.
const Map<String, String?> textFontPresets = {
  'Default': null,
  'Serif': 'serif',
  'Monospace': 'monospace',
  'Cursive': 'cursive',
};

/// Swatches for the color picker — deliberately a fixed small palette
/// (not a full color wheel) so this stays a quick tap-to-pick rather
/// than its own sub-feature.
const List<Color> textColorPresets = [
  Colors.white,
  Colors.black,
  Color(0xFFFFEB3B), // yellow
  Color(0xFFFF5252), // red
  Color(0xFF448AFF), // blue
  Color(0xFF69F0AE), // green
  Color(0xFFFF80AB), // pink
  Color(0xFFFFA726), // orange
];

/// Maps `TextOverlays.alignment`'s stored int to a `TextAlign`. Kept as
/// free functions rather than a real enum so the drift column (a plain
/// int) doesn't need a `TypeConverter` for just three values.
TextAlign textAlignForIndex(int index) {
  switch (index) {
    case 0:
      return TextAlign.left;
    case 2:
      return TextAlign.right;
    case 1:
    default:
      return TextAlign.center;
  }
}

const List<IconData> textAlignmentIcons = [
  Icons.format_align_left,
  Icons.format_align_center,
  Icons.format_align_right,
];

/// Where the actual video/photo frame sits inside a larger preview
/// canvas, once letterboxing (from an aspect-ratio mismatch) is
/// accounted for.
class LetterboxedFrame {
  final Offset offset;
  final Size size;
  const LetterboxedFrame(this.offset, this.size);
}

/// Computes [LetterboxedFrame] for a [canvas] of the preview's full
/// size and the frame's own [aspectRatio] (width / height) — the frame
/// is centered and scaled to fit inside the canvas via "contain"
/// semantics (same as the `BoxFit.contain` the preview itself renders
/// with), so this stays correct whether the letterboxing runs top/
/// bottom or left/right.
///
/// `TextOverlays.positionX`/`positionY` are fractions of *this* rect,
/// not the raw canvas — falls back to treating the whole canvas as the
/// frame when [aspectRatio] isn't known yet (or is degenerate), which
/// matches the pre-Phase-6-letterboxing-fix behavior and is only
/// visibly wrong when the frame doesn't roughly match the canvas's own
/// aspect ratio. See PHASE_6_PROGRESS.md's letterboxing note.
LetterboxedFrame letterboxedFrame(Size canvas, double? aspectRatio) {
  if (aspectRatio == null ||
      aspectRatio <= 0 ||
      canvas.width <= 0 ||
      canvas.height <= 0) {
    return LetterboxedFrame(Offset.zero, canvas);
  }

  final containerAspect = canvas.width / canvas.height;
  if (aspectRatio > containerAspect) {
    // Frame is relatively wider than the container: fills the width,
    // letterboxed top/bottom.
    final frameWidth = canvas.width;
    final frameHeight = frameWidth / aspectRatio;
    return LetterboxedFrame(
      Offset(0, (canvas.height - frameHeight) / 2),
      Size(frameWidth, frameHeight),
    );
  }

  // Frame is relatively taller (or equal): fills the height,
  // letterboxed left/right.
  final frameHeight = canvas.height;
  final frameWidth = frameHeight * aspectRatio;
  return LetterboxedFrame(
    Offset((canvas.width - frameWidth) / 2, 0),
    Size(frameWidth, frameHeight),
  );
}

/// Applies a drag [delta] (in canvas pixels) to a [current] fractional
/// position, expressed as a fraction of [frameSize] — the same
/// "position, not raw pixels" convention `TextOverlays.positionX`/
/// `positionY` use, so it stays correct regardless of device/canvas
/// size. Clamps to `[0.0, 1.0]` on each axis so a drag can't push an
/// overlay's anchor point outside the frame. A zero-size [frameSize]
/// (canvas hasn't laid out yet) is a no-op rather than a divide-by-zero.
Offset dragFractionDelta(Offset current, Offset delta, Size frameSize) {
  if (frameSize.width <= 0 || frameSize.height <= 0) return current;
  return Offset(
    (current.dx + delta.dx / frameSize.width).clamp(0.0, 1.0),
    (current.dy + delta.dy / frameSize.height).clamp(0.0, 1.0),
  );
}
