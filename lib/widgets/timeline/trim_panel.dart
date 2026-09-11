import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/database_provider.dart';
import '../../data/project_database.dart';
import '../../models/clip_x.dart';
import '../../providers/timeline_providers.dart';

/// Shown whenever a clip is selected: draggable trim handles over that
/// clip's full source duration, plus split-at-playhead and delete.
/// Non-destructive per the Phase 4 spec — every drag here only rewrites
/// trimStartMs/trimEndMs on the Clips row, never touches the source file;
/// compositing happens later, at export (Phase 8).
class TrimPanel extends ConsumerStatefulWidget {
  final Clip clip;
  final List<Clip> allClips;

  const TrimPanel({super.key, required this.clip, required this.allClips});

  @override
  ConsumerState<TrimPanel> createState() => _TrimPanelState();
}

class _TrimPanelState extends ConsumerState<TrimPanel> {
  late int _trimStart;
  late int _trimEnd;
  late double _volume;

  static const int _minTrimmedMs = 200;

  @override
  void initState() {
    super.initState();
    _trimStart = widget.clip.trimStartMs;
    _trimEnd = widget.clip.trimEndMs;
    _volume = widget.clip.volume;
  }

  @override
  void didUpdateWidget(covariant TrimPanel old) {
    super.didUpdateWidget(old);
    if (old.clip.id != widget.clip.id) {
      _trimStart = widget.clip.trimStartMs;
      _trimEnd = widget.clip.trimEndMs;
      _volume = widget.clip.volume;
    }
  }

  void _commitTrim() {
    ref.read(projectDatabaseProvider).updateClip(
          widget.clip.copyWith(trimStartMs: _trimStart, trimEndMs: _trimEnd),
        );
  }

  Future<void> _split() async {
    final playheadMs = ref.read(playheadMsProvider);
    final layout = layoutTimeline(widget.allClips);
    final pos = layout.firstWhere(
      (p) => p.clip.id == widget.clip.id,
      orElse: () => layout.first,
    );
    final splitAtTrimmedMs = playheadMs - pos.startMs;

    if (splitAtTrimmedMs <= 0 ||
        splitAtTrimmedMs >= widget.clip.trimmedDurationMs) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Move the playhead inside this clip to split it.'),
      ));
      return;
    }

    await ref
        .read(projectDatabaseProvider)
        .splitClip(widget.clip.id, splitAtTrimmedMs, const Uuid().v4());
  }

  Future<void> _delete() async {
    await ref
        .read(projectDatabaseProvider)
        .deleteClipAndReindex(widget.clip.projectId, widget.clip.id);
    ref.read(selectedClipIdProvider.notifier).state = null;
  }

  /// Toggles this clip's original audio on/off. `VideoPreviewPlayer`
  /// applies this to the preview's own audio volume (Phase 5, second
  /// half); the timeline tile also reflects it with a mute glyph
  /// (Phase 4).
  Future<void> _toggleMute() async {
    await ref.read(projectDatabaseProvider).updateClip(
          widget.clip.copyWith(muted: !widget.clip.muted),
        );
  }

  /// The continuous counterpart to [_toggleMute]: how loud this clip's
  /// original audio plays when it *isn't* muted. Applied to the preview
  /// via `VideoPreviewPlayer.setVolume` (Phase 5, second half) and, at
  /// export, alongside the music mix.
  void _commitVolume() {
    ref
        .read(projectDatabaseProvider)
        .updateClip(widget.clip.copyWith(volume: _volume));
  }

  @override
  Widget build(BuildContext context) {
    final fullDuration = widget.clip.durationMs;

    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '${((_trimEnd - _trimStart) / 1000).toStringAsFixed(1)}s clip',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  widget.clip.muted ? Icons.volume_off : Icons.volume_up,
                  color: widget.clip.muted
                      ? Colors.orangeAccent
                      : Colors.white70,
                ),
                tooltip: widget.clip.muted
                    ? 'Unmute original audio'
                    : 'Mute original audio',
                onPressed: _toggleMute,
              ),
              IconButton(
                icon: const Icon(Icons.content_cut, color: Colors.white70),
                tooltip: 'Split at playhead',
                onPressed: _split,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Delete clip',
                onPressed: _delete,
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.volume_down,
                color: widget.clip.muted ? Colors.white24 : Colors.white54,
                size: 18,
              ),
              Expanded(
                child: Slider(
                  value: _volume.clamp(0.0, 1.0),
                  // Dimmed but still adjustable while muted — mute is a
                  // separate hard override (Clips.muted), so the level
                  // set here is exactly what comes back the moment the
                  // user unmutes, rather than being reset to full.
                  onChanged: widget.clip.muted
                      ? null
                      : (v) => setState(() => _volume = v),
                  onChangeEnd: (_) => _commitVolume(),
                ),
              ),
              Icon(
                Icons.volume_up,
                color: widget.clip.muted ? Colors.white24 : Colors.white54,
                size: 18,
              ),
            ],
          ),
          if (fullDuration > 0)
            SizedBox(
              height: 40,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  double msToX(int ms) => (ms / fullDuration) * width;
                  int xToMs(double x) =>
                      ((x / width) * fullDuration).round().clamp(0, fullDuration);

                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 14),
                        height: 12,
                        color: Colors.white12,
                      ),
                      Positioned(
                        left: msToX(_trimStart),
                        width: msToX(_trimEnd) - msToX(_trimStart),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 14),
                          height: 12,
                          color:
                              Theme.of(context).colorScheme.primary.withOpacity(0.6),
                        ),
                      ),
                      _Handle(
                        x: msToX(_trimStart),
                        onDrag: (dx) => setState(() {
                          final next = xToMs(msToX(_trimStart) + dx);
                          _trimStart = next.clamp(0, _trimEnd - _minTrimmedMs);
                        }),
                        onDragEnd: _commitTrim,
                      ),
                      _Handle(
                        x: msToX(_trimEnd),
                        onDrag: (dx) => setState(() {
                          final next = xToMs(msToX(_trimEnd) + dx);
                          _trimEnd =
                              next.clamp(_trimStart + _minTrimmedMs, fullDuration);
                        }),
                        onDragEnd: _commitTrim,
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  final double x;
  final ValueChanged<double> onDrag;
  final VoidCallback onDragEnd;

  const _Handle({
    required this.x,
    required this.onDrag,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - 8,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
        onHorizontalDragEnd: (_) => onDragEnd(),
        child: Container(
          width: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.drag_indicator, size: 12, color: Colors.black54),
        ),
      ),
    );
  }
}
