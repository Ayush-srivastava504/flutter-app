/// Transition-preview math for Phase 7 (second half).
///
/// This is deliberately *not* frame-accurate video compositing — it
/// computes how much of the next clip's cached thumbnail to blend over
/// the current clip's live preview as the playhead approaches a
/// boundary, so picking "Fade" or "Cross-dissolve" in the timeline's
/// transition picker actually shows something at the boundary instead
/// of only being stored on the model. True frame-level crossfade
/// between two *playing* videos needs the continuous cross-clip
/// playback this codebase has flagged as a standing gap since Phase 4
/// (see PHASE_7_PROGRESS.md) — this preview works within the single-
/// clip-at-a-time model that already exists, both while scrubbing and
/// while playing (`VideoPreviewPlayer.onPositionTick` feeds the same
/// `playheadMs` this reads).
library transition_x;

/// One choice in the transition picker. [xfade] is the FFmpeg `xfade`
/// transition name for overlapping transitions, or null for the two that
/// don't overlap (`cut`, and `fade` = dip through black).
class TransitionOption {
  final String id;
  final String label;
  final String? xfade;

  /// Picker section: Basic, Motion, Shapes or Stylised.
  final String group;

  /// Shown with a "HOT" tag in the picker.
  final bool trendy;
  const TransitionOption(this.id, this.label, [this.xfade, this.group = 'Basic', this.trendy = false]);
}

/// Every value `Clips.transitionOut` may hold (F13 added the last four).
/// The xfade names are the ones listed in `docs/FFMPEG_COOKBOOK.md`.
const List<TransitionOption> transitionOptions = [
  // Basic
  TransitionOption('cut', 'Cut'),
  TransitionOption('fade', 'Fade'),
  TransitionOption('dissolve', 'Cross-dissolve', 'fade'),
  TransitionOption('flash', 'Flash', 'fadewhite', 'Basic', true),
  TransitionOption('dipblack', 'Dip to black', 'fadeblack'),
  TransitionOption('mono', 'Mono fade', 'fadegrays'),
  // Motion
  TransitionOption('whip', 'Whip pan', 'smoothleft', 'Motion', true),
  TransitionOption('whipup', 'Whip up', 'smoothup', 'Motion', true),
  TransitionOption('slideleft', 'Slide', 'slideleft', 'Motion'),
  TransitionOption('slideup', 'Slide up', 'slideup', 'Motion'),
  TransitionOption('zoomin', 'Zoom', 'zoomin', 'Motion', true),
  TransitionOption('cover', 'Push in', 'coverleft', 'Motion'),
  TransitionOption('reveal', 'Reveal', 'revealleft', 'Motion'),
  TransitionOption('squeeze', 'Squeeze', 'squeezeh', 'Motion'),
  TransitionOption('warp', 'Warp', 'distance', 'Motion'),
  // Shapes
  TransitionOption('wipeleft', 'Wipe', 'wipeleft', 'Shapes'),
  TransitionOption('diagonal', 'Diagonal', 'diagtl', 'Shapes'),
  TransitionOption('circleopen', 'Circle', 'circleopen', 'Shapes'),
  TransitionOption('iris', 'Iris close', 'circleclose', 'Shapes'),
  TransitionOption('box', 'Box', 'rectcrop', 'Shapes'),
  TransitionOption('doors', 'Doors', 'vertopen', 'Shapes'),
  TransitionOption('slices', 'Slices', 'hlslice', 'Shapes'),
  TransitionOption('wind', 'Wind', 'hlwind', 'Shapes'),
  // Stylised
  TransitionOption('blur', 'Blur', 'hblur', 'Stylised', true),
  TransitionOption('glitch', 'Pixel glitch', 'pixelize', 'Stylised', true),
  TransitionOption('spin', 'Spin', 'radial', 'Stylised', true),
];

/// Picker sections, in order.
const List<String> transitionGroups = ['Basic', 'Motion', 'Shapes', 'Stylised'];

/// The `xfade` name for [transitionOut], or null when it is not an
/// overlapping transition. Unknown values return null, i.e. behave as a cut,
/// so a bad row can never fail an export.
String? xfadeNameFor(String transitionOut) {
  for (final o in transitionOptions) {
    if (o.id == transitionOut) return o.xfade;
  }
  return null;
}

/// True for transitions where the two clips overlap (and so shorten the
/// rendered timeline).
bool isOverlapTransition(String transitionOut) => xfadeNameFor(transitionOut) != null;

/// How long, in ms, before a boundary the transition preview starts
/// blending in. Not user-configurable yet — see PHASE_7_PROGRESS.md's
/// note on transition duration.
const int transitionWindowMs = 600;

/// How to blend the current clip's live preview with the next clip's
/// thumbnail at a given playhead position.
class TransitionPreview {
  /// Opacity (0.0–1.0) for the *current* clip's live preview.
  final double currentOpacity;

  /// Opacity (0.0–1.0) for the *next* clip's thumbnail, overlaid on
  /// top of the current preview.
  final double nextOpacity;

  /// White over everything (0..1) — the Flash transition's preview.
  final double white;

  const TransitionPreview(this.currentOpacity, this.nextOpacity, [this.white = 0]);

  /// Fully on the current clip, no overlay — the boundary is either a
  /// cut or the playhead isn't within the transition window yet.
  static const none = TransitionPreview(1, 0);

  @override
  bool operator ==(Object other) =>
      other is TransitionPreview &&
      other.currentOpacity == currentOpacity &&
      other.nextOpacity == nextOpacity &&
      other.white == white;

  @override
  int get hashCode => Object.hash(currentOpacity, nextOpacity, white);
}

/// Computes [TransitionPreview] for [playheadMs] against a clip whose
/// trimmed end sits at [boundaryMs] on the timeline and whose
/// `Clip.transitionOut` is [transitionOut] ('cut' | 'fade' |
/// 'dissolve').
///
/// - `'cut'`: always [TransitionPreview.none].
/// - `'dissolve'`: a straight linear crossfade over the last
///   [transitionWindowMs] before the boundary.
/// - `'fade'`: fades the current clip to black over the window's first
///   half, then fades the next clip's thumbnail in from black over the
///   second half — the classic "fade through black" look, distinct
///   from a straight dissolve even though both only need the two
///   opacities this returns (a solid black backdrop behind both layers
///   makes the "through black" part visible; see how `EditorScreen`
///   composes this).
TransitionPreview transitionPreviewAt({
  required String transitionOut,
  required int playheadMs,
  required int boundaryMs,
}) {
  final overlap = isOverlapTransition(transitionOut);
  // Unknown names behave as a cut, same as the export.
  if (!overlap && transitionOut != 'fade') return TransitionPreview.none;

  final msUntilBoundary = boundaryMs - playheadMs;
  if (msUntilBoundary <= 0 || msUntilBoundary > transitionWindowMs) {
    return TransitionPreview.none;
  }

  // 0.0 at the window's start, 1.0 right at the boundary.
  final progress = 1 - (msUntilBoundary / transitionWindowMs);

  // Flash: up to white over the first half, down from white onto the
  // next clip over the second (FFmpeg `fadewhite`).
  if (transitionOut == 'flash') {
    return progress < 0.5
        ? TransitionPreview(1, 0, progress * 2)
        : TransitionPreview(0, 1, (1 - progress) * 2);
  }

  // Slide/wipe/circle/zoom/whip… are previewed as a plain crossfade (dip
  // to black uses the black backdrop below); only the export renders their
  // real shape.
  if (overlap && transitionOut != 'dipblack' && transitionOut != 'mono') {
    return TransitionPreview(1 - progress, progress);
  }

  // 'fade' — fade-through-black.
  if (progress < 0.5) {
    final t = progress / 0.5; // 0..1 across the first half
    return TransitionPreview(1 - t, 0);
  }
  final t = (progress - 0.5) / 0.5; // 0..1 across the second half
  return TransitionPreview(0, t);
}
