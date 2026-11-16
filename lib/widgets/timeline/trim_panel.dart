import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/database_provider.dart';
import '../../data/project_database.dart';
import '../../models/clip_x.dart';
import '../../models/fit_mode_x.dart';
import '../../providers/timeline_providers.dart';

/// Shown whenever a clip is selected: draggable trim handles over that
/// clip's full source duration, plus split-at-playhead, duplicate and delete.
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

  /// F3: a photo's on-screen time while its slider is being dragged.
  late int _photoMs;

  static const int _minTrimmedMs = 200;
  static const int _minPhotoMs = 1000;
  static const int _maxPhotoMs = 15000;

  @override
  void initState() {
    super.initState();
    _trimStart = widget.clip.trimStartMs;
    _trimEnd = widget.clip.trimEndMs;
    _volume = widget.clip.volume;
    _photoMs = widget.clip.sourceSpanMs;
  }

  @override
  void didUpdateWidget(covariant TrimPanel old) {
    super.didUpdateWidget(old);
    // Re-read when another clip is selected, and also when this clip's row
    // changed underneath us (undo/redo, an assistant edit, a split) — the
    // local copies only exist so a drag doesn't write to SQLite per frame.
    if (old.clip.id != widget.clip.id ||
        old.clip.trimStartMs != widget.clip.trimStartMs ||
        old.clip.trimEndMs != widget.clip.trimEndMs) {
      _trimStart = widget.clip.trimStartMs;
      _trimEnd = widget.clip.trimEndMs;
      _photoMs = widget.clip.sourceSpanMs;
    }
    if (old.clip.id != widget.clip.id || old.clip.volume != widget.clip.volume) {
      _volume = widget.clip.volume;
    }
  }

  /// F3: photos have no source length, so duration and trim end move
  /// together (see `ProjectDatabase.setPhotoDuration`).
  void _commitPhotoDuration() {
    ref.read(projectDatabaseProvider).setPhotoDuration(widget.clip.id, _photoMs);
  }

  Future<void> _setFitMode(String mode) async {
    await ref
        .read(projectDatabaseProvider)
        .updateClip(widget.clip.copyWith(fitMode: mode));
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
    // Timeline-space offset into this clip (what `trimmedDurationMs` is
    // also measured in since F11 — see its doc comment in `clip_x.dart`).
    final splitAtTimelineMs = playheadMs - pos.startMs;

    if (splitAtTimelineMs <= 0 ||
        splitAtTimelineMs >= widget.clip.trimmedDurationMs) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Move the playhead inside this clip to split it.'),
      ));
      return;
    }

    // F11: `ProjectDatabase.splitClip` expects a *source*-time offset (it
    // adds this directly to `trimStartMs`, unaware of speed), so convert
    // back from timeline-time — at speed != 1.0 they differ.
    final splitAtSourceMs =
        widget.clip.timelineToSourceOffsetMs(splitAtTimelineMs);

    await ref
        .read(projectDatabaseProvider)
        .splitClip(widget.clip.id, splitAtSourceMs, const Uuid().v4());
  }

  /// F2: inserts a copy of this clip right after it (see
  /// `ProjectDatabase.duplicateClip`). Selection stays on the original.
  Future<void> _duplicate() async {
    await ref.read(projectDatabaseProvider).duplicateClip(widget.clip.id);
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

  /// F10: adds one quarter-turn clockwise (wrapping 3 -> 0). Mirrors
  /// `rotateFlipFilters`'s own `turns % 4` handling in
  /// `export_command_builder.dart`, so this never needs to normalize
  /// before storing.
  Future<void> _rotate() async {
    await ref.read(projectDatabaseProvider).updateClip(
          widget.clip.copyWith(turns: (widget.clip.turns + 1) % 4),
        );
  }

  Future<void> _toggleFlipH() async {
    await ref.read(projectDatabaseProvider).updateClip(
          widget.clip.copyWith(flipH: !widget.clip.flipH),
        );
  }

  Future<void> _toggleFlipV() async {
    await ref.read(projectDatabaseProvider).updateClip(
          widget.clip.copyWith(flipV: !widget.clip.flipV),
        );
  }

  /// F11: a fixed set of stops rather than a continuous slider — a
  /// speed slider invites fiddly dragging for a feature whose whole
  /// value is "faster" or "slower", not a precise ratio. Spans
  /// `minClipSpeed`..`maxClipSpeed`.
  static const List<double> _speedStops = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0];

  Future<void> _setSpeed(double speed) async {
    await ref
        .read(projectDatabaseProvider)
        .updateClip(widget.clip.copyWith(speed: speed));
  }

  @override
  Widget build(BuildContext context) {
    final fullDuration = widget.clip.durationMs;
    final isPhoto = widget.clip.isPhoto;
    // What the clip occupies on the timeline right now (speed-aware), using
    // the in-progress drag values so the label follows the handle.
    final shownMs = isPhoto
        ? _photoMs
        : widget.clip.sourceToTimelineOffsetMs(_trimEnd - _trimStart);

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Expanded + ellipsis: the four buttons keep their room on a
              // narrow phone; the label shrinks instead of overflowing.
              Expanded(
                child: Text(
                  '${(shownMs / 1000).toStringAsFixed(1)}s ${isPhoto ? 'photo' : 'clip'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
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
                icon: const Icon(Icons.content_copy, color: Colors.white70),
                tooltip: 'Duplicate clip',
                onPressed: _duplicate,
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
              IconButton(
                icon: const Icon(Icons.rotate_90_degrees_cw_outlined,
                    color: Colors.white70),
                tooltip: 'Rotate 90°',
                onPressed: _rotate,
              ),
              IconButton(
                icon: Icon(Icons.flip,
                    color: widget.clip.flipH
                        ? Colors.orangeAccent
                        : Colors.white70),
                tooltip: 'Flip horizontal',
                onPressed: _toggleFlipH,
              ),
              Transform.rotate(
                angle: 1.5708, // 90deg, so the same glyph reads as a vertical flip
                child: IconButton(
                  icon: Icon(Icons.flip,
                      color: widget.clip.flipV
                          ? Colors.orangeAccent
                          : Colors.white70),
                  tooltip: 'Flip vertical',
                  onPressed: _toggleFlipV,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // F15: how the clip fills the project's frame.
                      for (final mode in fitModes)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ChoiceChip(
                            label: Text(mode.label),
                            labelStyle: const TextStyle(fontSize: 11),
                            selected:
                                normalizeFitMode(widget.clip.fitMode) == mode.id,
                            onSelected: (_) => _setFitMode(mode.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!isPhoto)
            Row(
              children: [
                const Text('Speed',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final s in _speedStops)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ChoiceChip(
                              label: Text('${s}x'),
                              labelStyle: const TextStyle(fontSize: 11),
                              selected: widget.clip.speed == s,
                              onSelected: (_) => _setSpeed(s),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          if (isPhoto)
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white54, size: 18),
                Expanded(
                  child: Slider(
                    min: _minPhotoMs.toDouble(),
                    max: _maxPhotoMs.toDouble(),
                    divisions: (_maxPhotoMs - _minPhotoMs) ~/ 500,
                    value: _photoMs
                        .clamp(_minPhotoMs, _maxPhotoMs)
                        .toDouble(),
                    onChanged: (v) => setState(() => _photoMs = v.round()),
                    onChangeEnd: (_) => _commitPhotoDuration(),
                  ),
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
          if (!isPhoto && fullDuration > 0)
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
