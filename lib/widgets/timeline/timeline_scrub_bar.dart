import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/clip_x.dart';

/// A thin full-width scrub bar beneath the clip strip. Dragging or
/// tapping anywhere on it maps linearly to a position in [0, totalMs]
/// and reports it via [onScrub] — this is what actually drives the live
/// preview, independent of the clip strip's own zoom level (which would
/// otherwise make a global scrub gesture awkward once zoomed in).
class TimelineScrubBar extends StatelessWidget {
  final List<TimelinePosition> layout;
  final int totalMs;
  final int playheadMs;
  final ValueChanged<int> onScrub;

  const TimelineScrubBar({
    super.key,
    required this.layout,
    required this.totalMs,
    required this.playheadMs,
    required this.onScrub,
  });

  @override
  Widget build(BuildContext context) {
    if (totalMs <= 0) return const SizedBox(height: 28);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        void handleDrag(Offset localPosition) {
          final fraction = (localPosition.dx / width).clamp(0.0, 1.0);
          onScrub((fraction * totalMs).round());
        }

        return GestureDetector(
          onHorizontalDragUpdate: (d) => handleDrag(d.localPosition),
          onTapDown: (d) => handleDrag(d.localPosition),
          child: Container(
            height: 28,
            color: Colors.grey[850],
            child: Stack(
              clipBehavior: ui.Clip.none,
              children: [
                for (final pos in layout)
                  Positioned(
                    left: pos.startMs / totalMs * width,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 1, color: Colors.white24),
                  ),
                Positioned(
                  left: (playheadMs / totalMs * width).clamp(0.0, width) - 1,
                  top: -4,
                  bottom: -4,
                  child: Container(
                    width: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
