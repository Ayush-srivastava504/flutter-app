import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/project_database.dart';
import '../../models/clip_x.dart';
import '../../providers/audio_providers.dart';
import '../../providers/text_overlay_providers.dart';
import '../../providers/timeline_providers.dart';

/// Moves the playhead to [ms], selects the clip under it, and closes the
/// audio/text panels so the clip panel shows. This is the one code path for
/// every way of moving the playhead (scrub bar and the buttons below), so they
/// can never disagree about what a seek does.
void seekTimeline(WidgetRef ref, List<TimelinePosition> layout, int ms) {
  ref.read(playheadMsProvider.notifier).state = ms;
  final pos = positionAt(layout, ms);
  if (pos != null) {
    ref.read(selectedClipIdProvider.notifier).state = pos.clip.id;
    ref.read(audioPanelOpenProvider.notifier).state = false;
    ref.read(textPanelOpenProvider.notifier).state = false;
  }
}

/// F4: previous clip / back 1 frame / timecode / forward 1 frame / next clip,
/// plus the "snap to clip edges" toggle for the scrub bar.
///
/// Performance: only the small timecode `Consumer` watches the playhead; the
/// buttons read it at tap time, so this widget does not rebuild per tick.
class PlayheadControls extends ConsumerWidget {
  final List<Clip> clips;

  const PlayheadControls({super.key, required this.clips});

  void _seek(WidgetRef ref, int Function(List<int> boundaries, int playheadMs, int totalMs) target) {
    final layout = layoutTimeline(clips);
    if (layout.isEmpty) return;
    final playheadMs = ref.read(playheadMsProvider);
    seekTimeline(ref, layout, target(clipBoundariesMs(layout), playheadMs, layout.last.endMs));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalMs = clips.fold<int>(0, (sum, c) => sum + c.trimmedDurationMs);
    final hasClips = totalMs > 0;
    final snap = ref.watch(snapScrubProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: 40,
      color: Colors.grey[850],
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white70),
            tooltip: 'Previous clip',
            visualDensity: VisualDensity.compact,
            onPressed: hasClips ? () => _seek(ref, (b, ms, _) => previousBoundaryMs(b, ms)) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white70),
            tooltip: 'Back 1 frame',
            visualDensity: VisualDensity.compact,
            onPressed: hasClips ? () => _seek(ref, (_, ms, total) => stepFrameMs(ms, -1, total)) : null,
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final playheadMs = ref.watch(playheadMsProvider);
                return Text(
                  '${formatTimecode(playheadMs)} / ${formatTimecode(totalMs)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white70),
            tooltip: 'Forward 1 frame',
            visualDensity: VisualDensity.compact,
            onPressed: hasClips ? () => _seek(ref, (_, ms, total) => stepFrameMs(ms, 1, total)) : null,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white70),
            tooltip: 'Next clip',
            visualDensity: VisualDensity.compact,
            onPressed: hasClips ? () => _seek(ref, (b, ms, _) => nextBoundaryMs(b, ms)) : null,
          ),
          IconButton(
            icon: Icon(Icons.straighten, color: snap ? primary : Colors.white38),
            tooltip: snap ? 'Snap to clip edges: on' : 'Snap to clip edges: off',
            visualDensity: VisualDensity.compact,
            onPressed: () => ref.read(snapScrubProvider.notifier).state = !snap,
          ),
        ],
      ),
    );
  }
}
