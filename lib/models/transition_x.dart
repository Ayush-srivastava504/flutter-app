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

  const TransitionPreview(this.currentOpacity, this.nextOpacity);

  /// Fully on the current clip, no overlay — the boundary is either a
  /// cut or the playhead isn't within the transition window yet.
  static const none = TransitionPreview(1, 0);

  @override
  bool operator ==(Object other) =>
      other is TransitionPreview &&
      other.currentOpacity == currentOpacity &&
      other.nextOpacity == nextOpacity;

  @override
  int get hashCode => Object.hash(currentOpacity, nextOpacity);
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
  if (transitionOut == 'cut') return TransitionPreview.none;

  final msUntilBoundary = boundaryMs - playheadMs;
  if (msUntilBoundary <= 0 || msUntilBoundary > transitionWindowMs) {
    return TransitionPreview.none;
  }

  // 0.0 at the window's start, 1.0 right at the boundary.
  final progress = 1 - (msUntilBoundary / transitionWindowMs);

  if (transitionOut == 'dissolve') {
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
