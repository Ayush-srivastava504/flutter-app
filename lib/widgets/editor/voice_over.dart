import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../app/app_theme.dart';
import '../../data/database_provider.dart';
import '../../data/project_database.dart';
import '../../models/clip_x.dart' show formatTimecode;
import '../../providers/timeline_providers.dart';
import '../../providers/voice_providers.dart';
import '../../services/voice_recorder.dart';

/// Opens the recorder as a *non-modal* sheet, so the preview above stays
/// usable — press play on the preview, then record over it.
void showVoiceRecorder(ScaffoldState scaffold, String projectId) {
  scaffold.showBottomSheet(
    (ctx) => _RecorderSheet(projectId: projectId),
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
  );
}

class _RecorderSheet extends ConsumerStatefulWidget {
  final String projectId;
  const _RecorderSheet({required this.projectId});

  @override
  ConsumerState<_RecorderSheet> createState() => _RecorderSheetState();
}

enum _RecState { idle, recording, saving }

class _RecorderSheetState extends ConsumerState<_RecorderSheet> {
  final _recorder = VoiceRecorder();
  _RecState _state = _RecState.idle;
  Timer? _ticker;
  final _started = Stopwatch();
  final List<double> _levels = [];
  int _startMs = 0;
  String? _error;

  @override
  void dispose() {
    _ticker?.cancel();
    if (_state == _RecState.recording) _recorder.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    if (!await _recorder.ensurePermission()) {
      setState(() => _error = 'ClipForge needs the microphone to record. Allow it in Settings → Apps → ClipForge.');
      return;
    }
    try {
      _startMs = ref.read(playheadMsProvider);
      await _recorder.start();
    } catch (e) {
      setState(() => _error = 'Couldn\'t start recording: $e');
      return;
    }
    _levels.clear();
    _started
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      final l = await _recorder.level();
      if (!mounted) return;
      setState(() {
        _levels.add(l);
        if (_levels.length > 60) _levels.removeAt(0);
      });
    });
    setState(() => _state = _RecState.recording);
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    _started.stop();
    setState(() => _state = _RecState.saving);
    final ms = await _recorder.stop();
    final path = _recorder.path;
    if (ms < 300 || path == null || !File(path).existsSync()) {
      setState(() {
        _state = _RecState.idle;
        _error = 'That was too short to keep. Hold on a little longer.';
      });
      return;
    }
    final id = const Uuid().v4();
    await ref.read(projectDatabaseProvider).insertVoiceOver(VoiceOversCompanion.insert(
          id: id,
          projectId: widget.projectId,
          sourceUri: path,
          startMs: _startMs,
          durationMs: ms,
        ));
    if (!mounted) return;
    ref.read(selectedVoiceOverIdProvider.notifier).state = id;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final recording = _state == _RecState.recording;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Icon(Icons.mic_none_rounded, color: AppColors.ember),
            const SizedBox(width: 8),
            Text('Voice-over', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (!recording)
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textDim),
                onPressed: _state == _RecState.saving ? null : () => Navigator.of(context).pop(),
              ),
          ]),
          Text(
            recording
                ? 'Recording from ${formatTimecode(_startMs)} on the timeline'
                : 'Starts at the playhead (${formatTimecode(ref.watch(playheadMsProvider))}). '
                    'Tip: press play on the preview first, then record over it.',
            style: const TextStyle(color: AppColors.textDim, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          SizedBox(height: 44, child: _LevelBars(levels: _levels, active: recording)),
          const SizedBox(height: 8),
          Text(
            _fmt(_started.elapsedMilliseconds),
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!, style: const TextStyle(color: AppColors.warn, fontSize: 12.5), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: switch (_state) {
              _RecState.idle => _start,
              _RecState.recording => _stop,
              _RecState.saving => null,
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.text, width: 3),
              ),
              alignment: Alignment.center,
              child: _state == _RecState.saving
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: recording ? 26 : 54,
                      height: recording ? 26 : 54,
                      decoration: BoxDecoration(
                        color: AppColors.youtube,
                        borderRadius: BorderRadius.circular(recording ? 6 : 27),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(recording ? 'Tap to stop' : 'Tap to record',
              style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
        ]),
      ),
    );
  }

  static String _fmt(int ms) {
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}.${((ms % 1000) ~/ 100)}';
  }
}

class _LevelBars extends StatelessWidget {
  final List<double> levels;
  final bool active;
  const _LevelBars({required this.levels, required this.active});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BarsPainter(levels, active), size: Size.infinite);
  }
}

class _BarsPainter extends CustomPainter {
  final List<double> levels;
  final bool active;
  _BarsPainter(this.levels, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 60;
    final w = size.width / n;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.55;
    for (var i = 0; i < n; i++) {
      final idx = levels.length - n + i;
      final l = idx >= 0 ? levels[idx] : 0.0;
      final h = (size.height * (0.08 + 0.92 * l)).clamp(2.0, size.height);
      paint.color = active ? AppColors.ember.withValues(alpha: 0.35 + 0.65 * l) : AppColors.surfaceTop;
      final x = i * w + w / 2;
      canvas.drawLine(Offset(x, (size.height - h) / 2), Offset(x, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => true;
}

/// Library sound effects are copied in as `bundled_audio/sfx_*.m4a`.
bool isSoundEffectPath(String path) => p.basename(path).startsWith('sfx_');

/// Thin timeline lane showing where each voice-over sits. Tap one to edit.
class VoiceOverLane extends ConsumerWidget {
  final List<VoiceOver> voiceOvers;
  final int totalMs;
  const VoiceOverLane({super.key, required this.voiceOvers, required this.totalMs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (voiceOvers.isEmpty || totalMs <= 0) return const SizedBox.shrink();
    final selected = ref.watch(selectedVoiceOverIdProvider);
    return Container(
      height: 26,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(children: [
        const SizedBox(width: 22, child: Icon(Icons.graphic_eq, size: 15, color: AppColors.textDim)),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            return Stack(children: [
              for (final v in voiceOvers)
                Positioned(
                  left: (v.startMs / totalMs * c.maxWidth).clamp(0.0, c.maxWidth - 6),
                  width: (v.durationMs / totalMs * c.maxWidth).clamp(6.0, c.maxWidth),
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedClipIdProvider.notifier).state = null;
                      ref.read(selectedVoiceOverIdProvider.notifier).state = v.id;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isSoundEffectPath(v.sourceUri) ? AppColors.pro : AppColors.ember)
                            .withValues(alpha: v.id == selected ? 0.75 : 0.35),
                        borderRadius: BorderRadius.circular(4),
                        border: v.id == selected ? Border.all(color: AppColors.text, width: 1.2) : null,
                      ),
                    ),
                  ),
                ),
            ]);
          }),
        ),
      ]),
    );
  }
}

/// Edit panel for the selected voice-over.
class VoiceOverPanel extends ConsumerStatefulWidget {
  final VoiceOver voiceOver;
  const VoiceOverPanel({super.key, required this.voiceOver});

  @override
  ConsumerState<VoiceOverPanel> createState() => _VoiceOverPanelState();
}

class _VoiceOverPanelState extends ConsumerState<VoiceOverPanel> {
  final _player = AudioPlayer();
  late double _volume = widget.voiceOver.volume;
  bool _playing = false;
  StreamSubscription<PlayerState>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _player.playerStateStream.listen((s) {
      final playing = s.playing && s.processingState != ProcessingState.completed;
      if (mounted && playing != _playing) setState(() => _playing = playing);
    });
  }

  @override
  void didUpdateWidget(covariant VoiceOverPanel old) {
    super.didUpdateWidget(old);
    if (old.voiceOver.id != widget.voiceOver.id) {
      _volume = widget.voiceOver.volume;
      _player.stop();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    await _player.setFilePath(widget.voiceOver.sourceUri);
    await _player.setVolume(_volume);
    await _player.seek(Duration.zero);
    unawaited(_player.play());
  }

  void _save(VoiceOver v) => ref.read(projectDatabaseProvider).updateVoiceOver(v);

  @override
  Widget build(BuildContext context) {
    final v = widget.voiceOver;
    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Icon(Icons.mic_none_rounded, size: 18, color: AppColors.ember),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${isSoundEffectPath(v.sourceUri) ? 'Sound effect' : 'Voice-over'} · ${formatTimecode(v.startMs)} · '
                '${(v.durationMs / 1000).toStringAsFixed(1)} s',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close, size: 20, color: AppColors.textDim),
              onPressed: () => ref.read(selectedVoiceOverIdProvider.notifier).state = null,
            ),
          ]),
          Row(children: [
            IconButton.filledTonal(
              onPressed: _toggle,
              icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.volume_up_outlined, size: 18, color: AppColors.textDim),
            Expanded(
              child: Slider(
                value: _volume.clamp(0.0, 1.0),
                onChanged: (x) {
                  setState(() => _volume = x);
                  _player.setVolume(x);
                },
                onChangeEnd: (x) => _save(v.copyWith(volume: x)),
              ),
            ),
            SizedBox(
              width: 40,
              child:
                  Text('${(_volume * 100).round()}%', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
            ),
          ]),
          SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(right: 8),
            secondary: const Icon(Icons.record_voice_over_outlined, color: AppColors.pro),
            title: const Text('Enhance speech'),
            subtitle: const Text('Less noise, clearer voice — applied in the export',
                style: TextStyle(color: AppColors.textFaint, fontSize: 11.5)),
            value: v.enhance,
            onChanged: (on) => _save(v.copyWith(enhance: on)),
          ),
          Row(children: [
            TextButton.icon(
              onPressed: () => _save(v.copyWith(startMs: ref.read(playheadMsProvider))),
              icon: const Icon(Icons.vertical_align_center, size: 18),
              label: const Text('Move to playhead'),
            ),
            const Spacer(),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () {
                ref.read(selectedVoiceOverIdProvider.notifier).state = null;
                ref.read(projectDatabaseProvider).deleteVoiceOver(v.id);
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
            ),
          ]),
        ]),
      ),
    );
  }
}
