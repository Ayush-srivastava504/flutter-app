import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database_provider.dart';
import '../../data/project_database.dart';
import '../../providers/audio_providers.dart';

/// Shown when the project's background-music track is selected (tapped
/// on [AudioTrackLane]): trim handles over the *source file's* full
/// duration (same non-destructive pattern as `TrimPanel`), a drag
/// handle to slide the whole clip's `offsetMs` against the video
/// timeline, a volume slider, and remove.
///
/// `VideoPreviewPlayer` reads these same stored values (trim/offset/
/// volume) to actually mix the music into playback (Phase 5, second
/// half) — this panel only edits them; it doesn't touch playback itself.
class AudioTrackPanel extends ConsumerStatefulWidget {
  final AudioTrack track;
  final int totalTimelineMs;

  const AudioTrackPanel({
    super.key,
    required this.track,
    required this.totalTimelineMs,
  });

  @override
  ConsumerState<AudioTrackPanel> createState() => _AudioTrackPanelState();
}

class _AudioTrackPanelState extends ConsumerState<AudioTrackPanel> {
  late int _trimStart;
  late int _trimEnd;
  late int _offset;
  late double _volume;

  static const int _minTrimmedMs = 200;

  @override
  void initState() {
    super.initState();
    _loadFrom(widget.track);
  }

  @override
  void didUpdateWidget(covariant AudioTrackPanel old) {
    super.didUpdateWidget(old);
    if (old.track.id != widget.track.id) _loadFrom(widget.track);
  }

  void _loadFrom(AudioTrack t) {
    _trimStart = t.trimStartMs;
    _trimEnd = t.trimEndMs;
    _offset = t.offsetMs;
    _volume = t.volume;
  }

  void _commit() {
    ref.read(projectDatabaseProvider).updateAudioTrack(
          widget.track.copyWith(
            trimStartMs: _trimStart,
            trimEndMs: _trimEnd,
            offsetMs: _offset,
            volume: _volume,
          ),
        );
  }

  Future<void> _remove() async {
    await ref.read(projectDatabaseProvider).deleteAudioTrack(widget.track.id);
    ref.read(audioPanelOpenProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final fullDurationMs =
        widget.track.durationMs > 0 ? widget.track.durationMs : _trimEnd;
    final trimmedMs = _trimEnd - _trimStart;
    // The music can run past the end of the video — give the alignment
    // strip enough room to show that instead of clamping it out of view.
    final alignSpanMs = widget.totalTimelineMs > 0
        ? (widget.totalTimelineMs > _offset + trimmedMs
            ? widget.totalTimelineMs
            : _offset + trimmedMs)
        : trimmedMs;

    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '${(trimmedMs / 1000).toStringAsFixed(1)}s music',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Remove music',
                onPressed: _remove,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                tooltip: 'Close',
                onPressed: () =>
                    ref.read(audioPanelOpenProvider.notifier).state = false,
              ),
            ],
          ),
          const _SectionLabel('Trim'),
          if (fullDurationMs > 0)
            SizedBox(
              height: 36,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  double msToX(int ms) => (ms / fullDurationMs) * width;
                  int xToMs(double x) => ((x / width) * fullDurationMs)
                      .round()
                      .clamp(0, fullDurationMs);

                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        height: 12,
                        color: Colors.white12,
                      ),
                      Positioned(
                        left: msToX(_trimStart),
                        width: msToX(_trimEnd) - msToX(_trimStart),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          height: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.7),
                        ),
                      ),
                      _Handle(
                        x: msToX(_trimStart),
                        onDrag: (dx) => setState(() {
                          final next = xToMs(msToX(_trimStart) + dx);
                          _trimStart = next.clamp(0, _trimEnd - _minTrimmedMs);
                        }),
                        onDragEnd: _commit,
                      ),
                      _Handle(
                        x: msToX(_trimEnd),
                        onDrag: (dx) => setState(() {
                          final next = xToMs(msToX(_trimEnd) + dx);
                          _trimEnd = next.clamp(
                              _trimStart + _minTrimmedMs, fullDurationMs);
                        }),
                        onDragEnd: _commit,
                      ),
                    ],
                  );
                },
              ),
            ),
          const _SectionLabel('Align with video'),
          SizedBox(
            height: 32,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                if (alignSpanMs <= 0) return const SizedBox.shrink();
                double msToX(int ms) => (ms / alignSpanMs) * width;
                int xToMs(double x) => ((x / width) * alignSpanMs).round();

                final barLeft = msToX(_offset);
                final barWidth = msToX(_offset + trimmedMs) - barLeft;
                final maxOffset =
                    (alignSpanMs - trimmedMs).clamp(0, alignSpanMs);

                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      height: 12,
                      color: Colors.white12,
                    ),
                    if (widget.totalTimelineMs > 0)
                      Positioned(
                        left: msToX(widget.totalTimelineMs),
                        top: 0,
                        bottom: 0,
                        child: Container(width: 1, color: Colors.white38),
                      ),
                    Positioned(
                      left: barLeft,
                      width: barWidth.clamp(4.0, width),
                      child: GestureDetector(
                        onHorizontalDragUpdate: (d) => setState(() {
                          final next = xToMs(barLeft + d.delta.dx);
                          _offset = next.clamp(0, maxOffset);
                        }),
                        onHorizontalDragEnd: (_) => _commit(),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const _SectionLabel('Music volume'),
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.white54, size: 18),
              Expanded(
                child: Slider(
                  value: _volume.clamp(0.0, 1.0),
                  onChanged: (v) => setState(() => _volume = v),
                  onChangeEnd: (_) => _commit(),
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white54, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
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
