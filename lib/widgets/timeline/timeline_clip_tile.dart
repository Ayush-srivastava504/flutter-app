import 'dart:io';

import 'package:flutter/material.dart';

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

  const TimelineClipTile({
    super.key,
    required this.clip,
    required this.isSelected,
    required this.pixelsPerSecond,
    required this.onTap,
  });

  static const double _minWidth = 36;
  static const double _height = 64;

  @override
  Widget build(BuildContext context) {
    final width = (clip.trimmedDurationMs / 1000 * pixelsPerSecond)
        .clamp(_minWidth, 4000.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: _height,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.antiAlias,
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
            if (clip.transitionOut != 'cut')
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Clip clip;
  const _Thumbnail({required this.clip});

  @override
  Widget build(BuildContext context) {
    final uri = clip.thumbnailUri;
    if (uri == null) {
      return Container(
        color: Colors.grey[800],
        alignment: Alignment.center,
        child: const Icon(Icons.movie, color: Colors.white38, size: 18),
      );
    }
    return Image.file(
      File(uri),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[800],
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.white38, size: 18),
      ),
    );
  }
}
