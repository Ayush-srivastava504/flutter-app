import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

import '../../data/project_database.dart';
import '../../models/clip_x.dart';

/// One clip's thumbnail chip on the timeline strip. Width is
/// proportional to the clip's *trimmed* duration at the current zoom
/// level, so trimming a clip visibly shortens its tile without a
/// separate redraw pass — the strip just rebuilds from the DB stream.
class TimelineClipTile extends StatelessWidget {
  final Clip clip;
  final bool isSelected;
  final double pixelsPerSecond;
  final VoidCallback onTap;

  /// False for every clip except the last on the timeline — the
  /// trailing transition badge (Phase 7) only makes sense on a clip
  /// that has a *next* clip for [Clip.transitionOut] to describe the
  /// join into.
  final bool isLast;

  /// Opens the transition picker for the boundary after this clip.
  /// Null (and the badge hidden) when [isLast].
  final VoidCallback? onTransitionTap;

  const TimelineClipTile({
    super.key,
    required this.clip,
    required this.isSelected,
    required this.pixelsPerSecond,
    required this.onTap,
    this.isLast = false,
    this.onTransitionTap,
  });

  static const double _minWidth = 36;
  static const double _height = 64;

  @override
  Widget build(BuildContext context) {
    final width = (clip.trimmedDurationMs / 1000 * pixelsPerSecond).clamp(_minWidth, 4000.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: _height,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: ui.Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Thumbnail(clip: clip),
            if (clip.muted)
              const Positioned(
                right: 2,
                top: 2,
                child: Icon(Icons.volume_off, size: 14, color: Colors.white70),
              ),
            if (!isLast)
              Positioned(
                right: 2,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _TransitionBadge(
                    transitionOut: clip.transitionOut,
                    onTap: onTransitionTap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tappable icon at a clip's trailing edge showing (and letting the
/// user change) [Clip.transitionOut] — the UI control the Phase 7 spec
/// calls for "at the clip boundary". A plain `GestureDetector` nested
/// inside the tile's own drag-and-tap handling is enough for it to win
/// taps within its small hit area without interfering with either
/// long-press-drag-to-reorder or the tile's own select-on-tap.
class _TransitionBadge extends StatelessWidget {
  final String transitionOut;
  final VoidCallback? onTap;

  const _TransitionBadge({required this.transitionOut, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCut = transitionIcon(transitionOut) == Icons.content_cut;
    return Tooltip(
      message: 'Transition',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // A little padding makes the 20 px badge easier to hit with a thumb.
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isCut ? Colors.black45 : Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              transitionIcon(transitionOut),
              size: 12,
              color: isCut ? Colors.white38 : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon for a `Clips.transitionOut` value (`transitionOptions` in
/// `models/transition_x.dart`). Lives here, not in the model, because the
/// model file is pure Dart with no Flutter import.
IconData transitionIcon(String transitionOut) => switch (transitionOut) {
      'fade' => Icons.gradient,
      'dissolve' => Icons.blur_on,
      'flash' => Icons.flash_on,
      'dipblack' => Icons.brightness_3_outlined,
      'mono' => Icons.filter_b_and_w,
      'whip' => Icons.fast_forward_rounded,
      'whipup' => Icons.keyboard_double_arrow_up,
      'slideleft' => Icons.swipe_left_alt,
      'slideup' => Icons.swipe_up_alt,
      'zoomin' => Icons.zoom_in,
      'cover' => Icons.input,
      'reveal' => Icons.output,
      'squeeze' => Icons.compress,
      'warp' => Icons.waves,
      'wipeleft' => Icons.vertical_split,
      'diagonal' => Icons.call_made,
      'circleopen' => Icons.radio_button_unchecked,
      'iris' => Icons.camera_outlined,
      'box' => Icons.crop_square,
      'doors' => Icons.door_sliding_outlined,
      'slices' => Icons.view_stream_outlined,
      'wind' => Icons.air,
      'blur' => Icons.blur_linear,
      'glitch' => Icons.grid_view,
      'spin' => Icons.cyclone,
      _ => Icons.content_cut,
    };

class _Thumbnail extends StatelessWidget {
  final Clip clip;
  const _Thumbnail({required this.clip});

  @override
  Widget build(BuildContext context) {
    // Photos have no generated thumbnail — the photo itself is the picture
    // (same rule as the filter/effects/background panels).
    final uri = clip.thumbnailUri ?? (clip.isPhoto ? clip.sourceUri : null);
    if (uri == null) {
      return Container(
        color: AppColors.surfaceTop,
        alignment: Alignment.center,
        child: const Icon(Icons.movie, color: Colors.white38, size: 18),
      );
    }
    return Image.file(
      File(uri),
      fit: BoxFit.cover,
      cacheWidth: 240, // decode a small bitmap, not the full-size source (memory)
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceTop,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.white38, size: 18),
      ),
    );
  }
}
