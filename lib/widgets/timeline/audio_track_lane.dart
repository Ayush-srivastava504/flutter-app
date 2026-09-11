import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/project_database.dart';
import '../../providers/audio_providers.dart';
import '../../providers/text_overlay_providers.dart';
import '../../providers/timeline_providers.dart';

/// Thin lane beneath the clip strip showing where the project's
/// background-music track sits against the (trimmed) video timeline —
/// this is the "aligned against the video timeline" view from the
/// Phase 5 spec; the actual drag-to-align interaction lives in
/// [AudioTrackPanel] once this lane is tapped.
///
/// Empty state doubles as the entry point for importing a track at all.
class AudioTrackLane extends ConsumerWidget {
  final AudioTrack? track;
  final int totalMs;
  final VoidCallback onImport;

  const AudioTrackLane({
    super.key,
    required this.track,
    required this.totalMs,
    required this.onImport,
  });

  static const double _height = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = this.track;

    if (track == null) {
      return SizedBox(
        height: _height,
        child: InkWell(
          onTap: onImport,
          child: Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(Icons.music_note, size: 14, color: Colors.white38),
                SizedBox(width: 6),
                Text(
                  'Add background music',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isOpen = ref.watch(audioPanelOpenProvider);
    final trackDurationMs = track.trimEndMs - track.trimStartMs;
    // The music can run longer than the video (nothing stops that at
    // this stage), so size the lane against whichever is longer rather
    // than clipping the bar at the lane's edge.
    final laneSpanMs = totalMs > 0
        ? math.max(totalMs, track.offsetMs + trackDurationMs)
        : trackDurationMs;

    return SizedBox(
      height: _height,
      child: InkWell(
        onTap: () {
          ref.read(selectedClipIdProvider.notifier).state = null;
          ref.read(audioPanelOpenProvider.notifier).state = true;
          ref.read(textPanelOpenProvider.notifier).state = false;
        },
        child: Container(
          color: Colors.grey[850],
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              if (laneSpanMs <= 0) return const SizedBox.shrink();

              final left = track.offsetMs / laneSpanMs * width;
              final barWidth =
                  (trackDurationMs / laneSpanMs * width).clamp(4.0, width);

              return Stack(
                children: [
                  Positioned(
                    left: left.clamp(0.0, width),
                    width: barWidth,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isOpen
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.6),
                        borderRadius: BorderRadius.circular(3),
                        border: track.volume == 0
                            ? Border.all(color: Colors.white38)
                            : null,
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        track.volume == 0
                            ? Icons.volume_off
                            : Icons.music_note,
                        size: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
