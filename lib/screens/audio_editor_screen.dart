import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../app/app_theme.dart';
import '../audio/audio_edit.dart';
import '../audio/audio_studio_service.dart';
import '../data/database_provider.dart';
import '../data/project_database.dart';
import '../models/edit_mode.dart';
import '../router/app_router.dart';
import '../widgets/common/state_views.dart';

/// Audio Studio editor: waveform + trim, and five tool tabs (Edit, Clean,
/// Tone, Space, Voice FX). Playback renders the real FFmpeg chain
/// (`audio_edit.dart`), so what you hear is exactly what gets saved; the
/// "Original" switch plays the untouched source for A/B.
class AudioEditorScreen extends ConsumerStatefulWidget {
  final String audioId;
  const AudioEditorScreen({super.key, required this.audioId});

  @override
  ConsumerState<AudioEditorScreen> createState() => _AudioEditorScreenState();
}

enum _Tab { edit, clean, tone, space, voice }

class _AudioEditorScreenState extends ConsumerState<AudioEditorScreen> {
  final _service = AudioStudioService();
  final _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;

  AudioProject? _project;
  AudioEdit _edit = const AudioEdit();
  final List<AudioEdit> _undo = [];
  final List<AudioEdit> _redo = [];
  List<double> _peaks = const [];
  String? _error;

  _Tab _tab = _Tab.edit;
  bool _original = false;
  bool _playing = false;
  double? _rendering; // progress while a preview renders
  AudioEdit? _previewEdit; // the edit the cached preview was rendered with
  String? _previewPath;
  Timer? _saveTimer;

  int get _sourceMs => _project?.durationMs ?? 0;

  /// Captured once: saving also happens in dispose, where `ref` is off limits.
  late final ProjectDatabase _db;

  @override
  void initState() {
    super.initState();
    _db = ref.read(projectDatabaseProvider);
    _load();
    _stateSub = _player.playerStateStream.listen((s) {
      final playing = s.playing && s.processingState != ProcessingState.completed;
      if (mounted && playing != _playing) setState(() => _playing = playing);
      if (s.processingState == ProcessingState.completed) _player.pause();
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _persist();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = _db;
    final row = await db.getAudioProject(widget.audioId);
    if (!mounted) return;
    if (row == null || row.sourceUri == null) {
      setState(() => _error = 'This audio could not be found.');
      return;
    }
    var duration = row.durationMs;
    if (duration <= 0) {
      duration = await _service.durationMs(row.sourceUri!);
      await db.updateAudioProject(row.id, AudioProjectsCompanion(durationMs: Value(duration)));
    }
    setState(() {
      _project = row.copyWith(durationMs: duration);
      _edit = AudioEdit.fromJson(row.editJson);
    });
    final peaks = await _service.waveform(row.sourceUri!);
    if (mounted) setState(() => _peaks = peaks);
  }

  // --- edit state -------------------------------------------------------------

  /// Live change while a slider moves (no undo step yet).
  void _preview(AudioEdit e) => setState(() => _edit = e);

  /// A finished change: one undo step, saved shortly after.
  void _commit(AudioEdit e, {AudioEdit? before}) {
    final prev = before ?? _edit;
    if (prev == e && before == null) return;
    setState(() {
      _undo.add(prev);
      if (_undo.length > 60) _undo.removeAt(0);
      _redo.clear();
      _edit = e;
    });
    _scheduleSave();
  }

  AudioEdit? _dragStart;
  void _dragBegin() => _dragStart ??= _edit;
  void _dragEnd(AudioEdit e) {
    final start = _dragStart ?? _edit;
    _dragStart = null;
    if (start != e) _commit(e, before: start);
  }

  void _doUndo() {
    if (_undo.isEmpty) return;
    setState(() {
      _redo.add(_edit);
      _edit = _undo.removeLast();
    });
    _scheduleSave();
  }

  void _doRedo() {
    if (_redo.isEmpty) return;
    setState(() {
      _undo.add(_edit);
      _edit = _redo.removeLast();
    });
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _persist);
  }

  void _persist() {
    final p0 = _project;
    if (p0 == null) return;
    _db.updateAudioProject(p0.id, AudioProjectsCompanion(editJson: Value(_edit.toJson())));
  }

  // --- playback ---------------------------------------------------------------

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    final project = _project;
    if (project == null) return;
    try {
      if (_original) {
        await _player.setFilePath(project.sourceUri!);
        await _player.seek(Duration(milliseconds: _edit.trimStartMs));
      } else {
        if (_previewEdit != _edit || _previewPath == null) {
          setState(() => _rendering = 0);
          final f = await _service.render(
            src: project.sourceUri!,
            sourceMs: _sourceMs,
            edit: _edit,
            onProgress: (v) {
              if (mounted) setState(() => _rendering = v);
            },
          );
          final old = _previewPath;
          _previewPath = f.path;
          _previewEdit = _edit;
          if (old != null) unawaited(File(old).delete().catchError((_) => File(old)));
        }
        await _player.setFilePath(_previewPath!);
        await _player.seek(Duration.zero);
      }
      if (mounted) setState(() => _rendering = null);
      unawaited(_player.play());
    } catch (e) {
      if (mounted) {
        setState(() => _rendering = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  // --- save -------------------------------------------------------------------

  Future<void> _showSaveSheet() async {
    final project = _project;
    if (project == null) return;
    await _player.pause();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SaveSheet(project: project, edit: _edit, service: _service),
    );
  }

  // --- layout -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final project = _project;
    return Scaffold(
      appBar: AppBar(
        title: Text(project?.name ?? 'Audio', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(tooltip: 'Undo', onPressed: _undo.isEmpty ? null : _doUndo, icon: const Icon(Icons.undo)),
          IconButton(tooltip: 'Redo', onPressed: _redo.isEmpty ? null : _doRedo, icon: const Icon(Icons.redo)),
          Padding(
            padding: const EdgeInsets.only(right: 10, left: 4),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),
              onPressed: project == null ? null : _showSaveSheet,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: _error != null
          ? ErrorStateView(message: _error!)
          : project == null
              ? const LoadingStateView(message: 'Opening audio…')
              : SafeArea(
                  top: false,
                  // Short screens (landscape): everything scrolls as one page,
                  // so the fixed waveform + controls can never overflow.
                  child: LayoutBuilder(builder: (context, box) {
                    final top = [
                      _waveCard(),
                      _transport(),
                      if (project.composeJson != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () =>
                                  Navigator.pushReplacementNamed(context, AppRouter.compose, arguments: project.id),
                              icon: const Icon(Icons.piano_outlined, size: 18),
                              label: const Text('Edit the beat'),
                            ),
                          ),
                        ),
                      _tabs(),
                    ];
                    if (box.maxHeight < 560) {
                      return ListView(children: [
                        ...top,
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          child: Column(children: _panel()),
                        ),
                      ]);
                    }
                    return Column(children: [
                      ...top,
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: _panel(),
                        ),
                      ),
                    ]);
                  }),
                ),
    );
  }

  Widget _waveCard() {
    final total = _sourceMs;
    final start = _edit.trimStartMs;
    final end = _edit.trimEndMs ?? total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.line),
        ),
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          double x(int ms) => total <= 0 ? 0 : ms / total * w;
          int ms(double dx) => total <= 0 ? 0 : (dx / w * total).round().clamp(0, total);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _dragBegin(),
            onHorizontalDragUpdate: (d) {
              final at = ms(d.localPosition.dx);
              // Move whichever handle is closer.
              if ((d.localPosition.dx - x(start)).abs() < (d.localPosition.dx - x(end)).abs()) {
                _preview(_edit.copyWith(trimStartMs: at.clamp(0, end - 200)));
              } else {
                _preview(_edit.copyWith(trimEndMs: at.clamp(start + 200, total)));
              }
            },
            onHorizontalDragEnd: (_) => _dragEnd(_edit),
            child: Stack(children: [
              Positioned.fill(
                child: CustomPaint(painter: _WavePainter(_peaks, start / (total == 0 ? 1 : total), end / (total == 0 ? 1 : total))),
              ),
              _Handle(left: x(start) - 10),
              _Handle(left: x(end) - 10),
              StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, snap) {
                  if (!_playing) return const SizedBox.shrink();
                  final pos = snap.data?.inMilliseconds ?? 0;
                  final src = _original ? pos : start + (pos * _edit.speed).round();
                  return Positioned(
                    left: x(src.clamp(0, total)),
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: AppColors.text),
                  );
                },
              ),
              Positioned(
                left: 8,
                bottom: 6,
                child: Text(_fmt(start), style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
              ),
              Positioned(
                right: 8,
                bottom: 6,
                child: Text(_fmt(end), style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
              ),
              if (_peaks.isEmpty)
                const Center(child: Text('Reading waveform…', style: TextStyle(color: AppColors.textFaint))),
            ]),
          );
        }),
      ),
    );
  }

  Widget _transport() {
    final outMs = _edit.outputMs(_sourceMs);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(children: [
        SizedBox(
          width: 56,
          height: 56,
          child: _rendering != null
              ? Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(value: _rendering! > 0 ? _rendering : null, strokeWidth: 3),
                  const Icon(Icons.graphic_eq, size: 20),
                ])
              : IconButton.filled(
                  iconSize: 30,
                  onPressed: _togglePlay,
                  icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Result ${_fmt(outMs)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              _rendering != null
                  ? 'Rendering your effects…'
                  : _original
                      ? 'Playing the original'
                      : 'Playing with every effect, exactly as it will save',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ]),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Switch(
            value: _original,
            onChanged: (v) {
              _player.pause();
              setState(() => _original = v);
            },
          ),
          const Text('Original', style: TextStyle(fontSize: 11, color: AppColors.textDim)),
        ]),
      ]),
    );
  }

  Widget _tabs() {
    const labels = {
      _Tab.edit: ('Edit', Icons.content_cut),
      _Tab.clean: ('Clean', Icons.cleaning_services_outlined),
      _Tab.tone: ('Tone', Icons.equalizer),
      _Tab.space: ('Space', Icons.spatial_audio_off_outlined),
      _Tab.voice: ('Voice FX', Icons.record_voice_over_outlined),
    };
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        children: [
          for (final t in _Tab.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                avatar: Icon(labels[t]!.$2, size: 16),
                label: Text(labels[t]!.$1),
                selected: _tab == t,
                onSelected: (_) => setState(() => _tab = t),
              ),
            ),
        ],
      ),
    );
  }

  _Knob _knob(String label, double value, double min, double max, String Function(double) show,
          AudioEdit Function(double) apply) =>
      _Knob(
        label: label,
        value: value,
        min: min,
        max: max,
        display: show(value),
        onStart: _dragBegin,
        onChanged: (v) => _preview(apply(v)),
        onEnd: (v) => _dragEnd(apply(v)),
        onReset: () => _commit(apply(_neutral(label, min, max))),
      );

  double _neutral(String label, double min, double max) => switch (label) {
        'Speed' => 1,
        'Mix' => 0.3,
        'Tone' => 0.5,
        'Feedback' => 0.35,
        _ => min < 0 ? 0 : min,
      };

  List<Widget> _panel() {
    final e = _edit;
    String db(double v) => '${v > 0 ? '+' : ''}${v.toStringAsFixed(1)} dB';
    String pct(double v) => '${(v * 100).round()}%';
    String hzOff(double v) => v <= 0 ? 'Off' : '${v.round()} Hz';
    switch (_tab) {
      case _Tab.edit:
        final outMs = e.outputMs(_sourceMs).toDouble();
        return [
          _knob('Volume', e.gainDb, -24, 12, db, (v) => e.copyWith(gainDb: v)),
          _knob('Fade in', e.fadeInMs.toDouble(), 0, (outMs / 2).clamp(0, 10000), (v) => '${(v / 1000).toStringAsFixed(1)} s',
              (v) => e.copyWith(fadeInMs: v.round())),
          _knob('Fade out', e.fadeOutMs.toDouble(), 0, (outMs / 2).clamp(0, 10000), (v) => '${(v / 1000).toStringAsFixed(1)} s',
              (v) => e.copyWith(fadeOutMs: v.round())),
          _knob('Speed', e.speed, 0.5, 2, (v) => '${v.toStringAsFixed(2)}×', (v) => e.copyWith(speed: v)),
          _knob('Pitch', e.pitch, -12, 12, (v) => '${v > 0 ? '+' : ''}${v.round()} st', (v) => e.copyWith(pitch: v.roundToDouble())),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reverse'),
            subtitle: const Text('Play it backwards', style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
            value: e.reverse,
            onChanged: (v) => _commit(e.copyWith(reverse: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Loudness for streaming'),
            subtitle: const Text('Matches YouTube / Spotify level (-14 LUFS)',
                style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
            value: e.normalize,
            onChanged: (v) => _commit(e.copyWith(normalize: v)),
          ),
          TextButton.icon(
            onPressed: e.trimStartMs == 0 && e.trimEndMs == null
                ? null
                : () => _commit(e.copyWith(trimStartMs: 0, clearTrimEnd: true)),
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Reset trim (drag the edges of the waveform to trim)'),
          ),
        ];
      case _Tab.clean:
        return [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enhance speech'),
            subtitle: const Text('Clearer, fuller, more even voice', style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
            value: e.enhanceSpeech,
            onChanged: (v) => _commit(e.copyWith(enhanceSpeech: v)),
          ),
          _knob('Noise removal', e.denoise, 0, 1, pct, (v) => e.copyWith(denoise: v)),
          _knob('Low cut', e.lowCutHz, 0, 400, hzOff, (v) => e.copyWith(lowCutHz: v < 15 ? 0 : v)),
          _knob('High cut', e.highCutHz <= 0 ? 20000 : e.highCutHz, 1000, 20000,
              (v) => v >= 19500 ? 'Off' : '${(v / 1000).toStringAsFixed(1)} kHz',
              (v) => e.copyWith(highCutHz: v >= 19500 ? 0 : v)),
          const _Hint('Low cut removes rumble and wind; high cut softens hiss and harsh highs.'),
        ];
      case _Tab.tone:
        return [
          _knob('Bass', e.bassDb, -12, 12, db, (v) => e.copyWith(bassDb: v)),
          _knob('Mids', e.midDb, -12, 12, db, (v) => e.copyWith(midDb: v)),
          _knob('Treble', e.trebleDb, -12, 12, db, (v) => e.copyWith(trebleDb: v)),
          _knob('Compressor', e.compress, 0, 1, pct, (v) => e.copyWith(compress: v)),
          _knob('Stereo width', e.width, 0, 1, pct, (v) => e.copyWith(width: v)),
          const _Hint('The compressor makes quiet and loud parts closer together — great for voice and drums.'),
        ];
      case _Tab.space:
        return [
          const _Section('Reverb'),
          _knob('Room size', e.reverbSize, 0, 1, (v) => v < 0.01 ? 'Off' : _room(v), (v) => e.copyWith(reverbSize: v)),
          _knob('Mix', e.reverbMix, 0, 1, pct, (v) => e.copyWith(reverbMix: v)),
          _knob('Tone', e.reverbTone, 0, 1, (v) => v < 0.35 ? 'Dark' : v > 0.65 ? 'Bright' : 'Natural',
              (v) => e.copyWith(reverbTone: v)),
          const _Section('Echo'),
          _knob('Delay', e.echoMs.toDouble(), 0, 1000, (v) => v < 20 ? 'Off' : '${v.round()} ms',
              (v) => e.copyWith(echoMs: v < 20 ? 0 : v.round())),
          _knob('Feedback', e.echoFeedback, 0, 0.9, pct, (v) => e.copyWith(echoFeedback: v)),
          const _Section('Chorus'),
          _knob('Chorus', e.chorus, 0, 1, (v) => v < 0.01 ? 'Off' : pct(v), (v) => e.copyWith(chorus: v)),
          const _Hint('Real convolution reverb: from a small room to a cathedral. Press play to hear it.'),
        ];
      case _Tab.voice:
        return [
          const _Hint('One tap gives your audio a character. Fine-tune it afterwards in the other tabs.'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final pr in voicePresets)
              SizedBox(
                width: 104,
                child: Material(
                  color: e.preset == pr.id ? AppColors.ember.withValues(alpha: 0.16) : AppColors.surfaceHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    side: BorderSide(color: e.preset == pr.id ? AppColors.ember : AppColors.line),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    onTap: () => _commit(applyVoicePreset(e, pr.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(pr.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w700, color: e.preset == pr.id ? AppColors.ember : AppColors.text)),
                        const SizedBox(height: 2),
                        Text(pr.hint,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.textDim, height: 1.2)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ];
    }
  }

  static String _room(double v) => v < 0.2
      ? 'Small room'
      : v < 0.45
          ? 'Studio'
          : v < 0.7
              ? 'Hall'
              : v < 0.9
                  ? 'Church'
                  : 'Cathedral';

  static String _fmt(int ms) {
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}.${(ms % 1000) ~/ 100}';
  }
}

class _Handle extends StatelessWidget {
  final double left;
  const _Handle({required this.left});

  @override
  Widget build(BuildContext context) => Positioned(
        left: left,
        top: 0,
        bottom: 0,
        width: 20,
        child: Center(
          child: Container(
            width: 6,
            height: 54,
            decoration: BoxDecoration(color: AppColors.ember, borderRadius: BorderRadius.circular(3)),
          ),
        ),
      );
}

class _WavePainter extends CustomPainter {
  final List<double> peaks;
  final double start; // 0..1
  final double end;
  _WavePainter(this.peaks, this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;
    final mid = size.height / 2;
    final barW = size.width / peaks.length;
    final inside = Paint()..color = AppColors.ember;
    final outside = Paint()..color = AppColors.surfaceTop;
    for (var i = 0; i < peaks.length; i++) {
      final f = i / peaks.length;
      final h = (peaks[i] * (size.height - 24)).clamp(1.5, size.height - 24);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(i * barW + barW / 2, mid), width: barW * 0.7, height: h),
        f >= start && f <= end ? inside : outside,
      );
    }
    final shade = Paint()..color = AppColors.ink.withValues(alpha: 0.45);
    canvas.drawRect(Rect.fromLTRB(0, 0, start * size.width, size.height), shade);
    canvas.drawRect(Rect.fromLTRB(end * size.width, 0, size.width, size.height), shade);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.peaks != peaks || old.start != start || old.end != end;
}

class _Knob extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final VoidCallback onStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onEnd;
  final VoidCallback onReset;

  const _Knob({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onStart,
    required this.onChanged,
    required this.onEnd,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final safeMax = max <= min ? min + 1 : max;
    return Row(children: [
      SizedBox(width: 104, child: Text(label, style: const TextStyle(fontSize: 13))),
      Expanded(
        child: Slider(
          value: value.clamp(min, safeMax),
          min: min,
          max: safeMax,
          onChangeStart: (_) => onStart(),
          onChanged: onChanged,
          onChangeEnd: onEnd,
        ),
      ),
      GestureDetector(
        onDoubleTap: onReset,
        child: SizedBox(
          width: 74,
          child: Text(display,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
        ),
      ),
    ]);
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ember)),
      );
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text, style: const TextStyle(color: AppColors.textFaint, fontSize: 12, height: 1.35)),
      );
}

/// Save: pick a format, then save to the phone's Music folder, share, or use
/// it as the music of a video project.
class _SaveSheet extends ConsumerStatefulWidget {
  final AudioProject project;
  final AudioEdit edit;
  final AudioStudioService service;
  const _SaveSheet({required this.project, required this.edit, required this.service});

  @override
  ConsumerState<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends ConsumerState<_SaveSheet> {
  AudioFormat _format = AudioFormat.m4a;
  double? _progress;
  String? _status;

  Future<File> _render(AudioFormat format) async {
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'audio_studio', 'exports'));
    await dir.create(recursive: true);
    final out = p.join(dir.path, '${widget.project.id}_${DateTime.now().millisecondsSinceEpoch}.${format.ext}');
    setState(() => _progress = 0);
    try {
      return await widget.service.render(
        src: widget.project.sourceUri!,
        sourceMs: widget.project.durationMs,
        edit: widget.edit,
        format: format,
        outPath: out,
        onProgress: (v) {
          if (mounted) setState(() => _progress = v);
        },
      );
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  Future<void> _run(Future<void> Function() job) async {
    try {
      await job();
    } catch (e) {
      if (mounted) setState(() => _status = 'Something went wrong: $e');
    }
  }

  Future<void> _saveToPhone() => _run(() async {
        final f = await _render(_format);
        final where = await widget.service.saveToMusic(f, widget.project.name, _format);
        if (mounted) setState(() => _status = 'Saved to $where');
      });

  Future<void> _share() => _run(() async {
        final f = await _render(_format);
        await widget.service.share(f);
      });

  Future<void> _useInVideo() => _run(() async {
        final db = ref.read(projectDatabaseProvider);
        final projects = [...await db.allProjects()]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        if (!mounted) return;
        final target = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Use as the music of…'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, ''),
                child: const Row(children: [Icon(Icons.add, size: 18), SizedBox(width: 10), Text('A new video')]),
              ),
              for (final pr in projects.take(12))
                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, pr.id), child: Text(pr.name)),
            ],
          ),
        );
        if (target == null) return;
        final f = await _render(AudioFormat.m4a);
        final ms = await widget.service.durationMs(f.path);
        var projectId = target;
        if (projectId.isEmpty) {
          projectId = const Uuid().v4();
          final now = DateTime.now();
          await db.insertProject(ProjectsCompanion.insert(
            id: projectId,
            name: widget.project.name,
            mode: Value(EditMode.normal.name),
            createdAt: now,
            updatedAt: now,
          ));
        }
        await db.setAudioTrack(id: const Uuid().v4(), projectId: projectId, sourceUri: f.path, durationMs: ms);
        if (!mounted) return;
        Navigator.pop(context);
        await Navigator.pushNamed(context, AppRouter.editor, arguments: projectId);
      });

  @override
  Widget build(BuildContext context) {
    final busy = _progress != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Save your audio', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<AudioFormat>(
            showSelectedIcon: false,
            segments: [for (final f in AudioFormat.values) ButtonSegment(value: f, label: Text(f.ext.toUpperCase()))],
            selected: {_format},
            onSelectionChanged: busy ? null : (s) => setState(() => _format = s.first),
          ),
          const SizedBox(height: 4),
          Text(_format.label, style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
          const SizedBox(height: 12),
          if (busy) ...[
            LinearProgressIndicator(value: _progress! > 0 ? _progress : null),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: busy ? null : _saveToPhone,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Save to phone (Music/ClipForge)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : _share,
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Share'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : _useInVideo,
            icon: const Icon(Icons.movie_creation_outlined, size: 18),
            label: const Text('Use as music in a video'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 10),
            Text(_status!, style: const TextStyle(color: AppColors.ok)),
          ],
        ]),
      ),
    );
  }
}
