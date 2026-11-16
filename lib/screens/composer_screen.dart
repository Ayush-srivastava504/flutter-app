import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../app/app_theme.dart';
import '../audio/audio_studio_service.dart';
import '../audio/composer.dart';
import '../data/database_provider.dart';
import '../data/project_database.dart';
import '../router/app_router.dart';
import '../widgets/common/state_views.dart';

/// Audio Studio → Compose: style, tempo, key, chords, instrument and a
/// 16-step drum grid. Play renders the beat on the phone (pure-Dart synth,
/// background isolate); "Add effects" opens it in the audio editor.
class ComposerScreen extends ConsumerStatefulWidget {
  final String audioId;
  const ComposerScreen({super.key, required this.audioId});

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  final _service = AudioStudioService();
  final _player = AudioPlayer();
  late final ProjectDatabase _db;
  StreamSubscription<PlayerState>? _sub;

  AudioProject? _project;
  Composition _c = stylePreset('lofi');
  String? _renderedJson; // composition the current WAV was rendered from
  bool _rendering = false;
  bool _playing = false;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _db = ref.read(projectDatabaseProvider);
    _load();
    _sub = _player.playerStateStream.listen((s) {
      final playing = s.playing && s.processingState != ProcessingState.completed;
      if (mounted && playing != _playing) setState(() => _playing = playing);
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _persist();
    _sub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final row = await _db.getAudioProject(widget.audioId);
    if (!mounted || row == null) return;
    setState(() {
      _project = row;
      _c = Composition.fromJson(row.composeJson);
    });
  }

  void _set(Composition c) {
    setState(() => _c = c);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _persist);
    // A playing loop is now out of date: stop so the next Play re-renders.
    if (_playing) _player.pause();
  }

  void _persist() {
    final p = _project;
    if (p == null) return;
    _db.updateAudioProject(p.id, AudioProjectsCompanion(composeJson: Value(_c.toJson())));
  }

  /// Renders (if anything changed) and stores the WAV as the project's audio.
  Future<String?> _ensureRendered() async {
    final p = _project;
    if (p == null) return null;
    final json = _c.toJson();
    if (_renderedJson == json && p.sourceUri != null) return p.sourceUri;
    setState(() => _rendering = true);
    try {
      final (path, ms) = await _service.renderCompositionToFile(_c, p.id);
      await _db.updateAudioProject(
          p.id, AudioProjectsCompanion(sourceUri: Value(path), durationMs: Value(ms), composeJson: Value(json)));
      _project = p.copyWith(sourceUri: Value(path), durationMs: ms);
      _renderedJson = json;
      return path;
    } finally {
      if (mounted) setState(() => _rendering = false);
    }
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    try {
      final path = await _ensureRendered();
      if (path == null) return;
      await _player.setFilePath(path);
      await _player.seek(Duration.zero);
      unawaited(_player.play());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't render the beat: $e")));
    }
  }

  Future<void> _toEditor() async {
    await _player.pause();
    final path = await _ensureRendered();
    if (path == null || !mounted) return;
    // Editing a rendered beat starts from a clean edit.
    Navigator.pushReplacementNamed(context, AppRouter.audio, arguments: widget.audioId);
  }

  Future<void> _pickChord(int bar) async {
    final d = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Chord for bar ${bar + 1}', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Every chord here fits the key of ${noteNames[_c.keyRoot]} ${_c.minor ? 'minor' : 'major'}.',
                style: const TextStyle(color: AppColors.textDim, fontSize: 12.5)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var deg = 0; deg < 7; deg++)
                ChoiceChip(
                  label: Text('${degreeLabel(_c, deg)} · ${chordName(_c, deg)}'),
                  selected: _c.chords[bar] == deg,
                  onSelected: (_) => Navigator.pop(ctx, deg),
                ),
            ]),
          ]),
        ),
      ),
    );
    if (d == null) return;
    final chords = [..._c.chords];
    chords[bar] = d;
    _set(_c.copyWith(chords: chords, style: 'custom'));
  }

  void _toggleStep(int row, int step) {
    final grid = [for (final r in _c.grid) [...r]];
    grid[row][step] = !grid[row][step];
    _set(_c.copyWith(drums: grid, style: 'custom'));
  }

  @override
  Widget build(BuildContext context) {
    final p = _project;
    return Scaffold(
      appBar: AppBar(
        title: Text(p?.name ?? 'Compose', overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 12)),
              onPressed: p == null || _rendering ? null : _toEditor,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Add effects'),
            ),
          ),
        ],
      ),
      body: p == null
          ? const LoadingStateView(message: 'Opening…')
          : SafeArea(
              top: false,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
                _transport(),
                const SizedBox(height: 14),
                const _Label('Style'),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final (id, label) in composeStyles)
                    ChoiceChip(
                      label: Text(label),
                      selected: _c.style == id,
                      onSelected: (_) => _set(stylePreset(id).copyWith(repeats: _c.repeats)),
                    ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  const SizedBox(width: 70, child: Text('Tempo')),
                  Expanded(
                    child: Slider(
                      value: _c.bpm.toDouble(),
                      min: 60,
                      max: 160,
                      divisions: 100,
                      onChanged: (v) => _set(_c.copyWith(bpm: v.round())),
                    ),
                  ),
                  SizedBox(width: 64, child: Text('${_c.bpm} bpm', textAlign: TextAlign.right)),
                ]),
                Row(children: [
                  const SizedBox(width: 70, child: Text('Key')),
                  DropdownButton<int>(
                    value: _c.keyRoot,
                    underline: const SizedBox.shrink(),
                    items: [for (var i = 0; i < 12; i++) DropdownMenuItem(value: i, child: Text(noteNames[i]))],
                    onChanged: (v) => _set(_c.copyWith(keyRoot: v)),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    segments: const [
                      ButtonSegment(value: false, label: Text('Major')),
                      ButtonSegment(value: true, label: Text('Minor')),
                    ],
                    selected: {_c.minor},
                    onSelectionChanged: (s) => _set(_c.copyWith(minor: s.first)),
                  ),
                ]),
                const SizedBox(height: 14),
                const _Label('Chords · tap a bar to change it'),
                Row(children: [
                  for (var bar = 0; bar < 4; bar++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: bar == 3 ? 0 : 6),
                        child: Material(
                          color: AppColors.surfaceHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            side: const BorderSide(color: AppColors.line),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            onTap: () => _pickChord(bar),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(children: [
                                Text(chordName(_c, _c.chords[bar]),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                Text(degreeLabel(_c, _c.chords[bar]),
                                    style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 14),
                const _Label('Sound'),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final i in ComposeInstrument.values)
                    ChoiceChip(
                      label: Text(i.label),
                      selected: _c.instrument == i,
                      onSelected: (_) => _set(_c.copyWith(instrument: i)),
                    ),
                ]),
                Row(children: [
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bass'),
                      value: _c.bass,
                      onChanged: (v) => _set(_c.copyWith(bass: v)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Melody'),
                      value: _c.melody,
                      onChanged: (v) => _set(_c.copyWith(melody: v)),
                    ),
                  ),
                ]),
                Row(children: [
                  const SizedBox(width: 70, child: Text('Swing')),
                  Expanded(
                    child: Slider(
                      value: _c.swing,
                      max: 0.5,
                      onChanged: (v) => _set(_c.copyWith(swing: v)),
                    ),
                  ),
                  SizedBox(width: 64, child: Text('${(_c.swing * 200).round()}%', textAlign: TextAlign.right)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  const Expanded(child: _Label('Drums · one bar, 16 steps')),
                  TextButton(
                    onPressed: () => _set(_c.copyWith(
                        drums: [for (var _ in drumRows) List<bool>.filled(16, false)], style: 'custom')),
                    child: const Text('Clear'),
                  ),
                ]),
                _DrumGrid(composition: _c, player: _player, playing: _playing, onToggle: _toggleStep),
                const SizedBox(height: 14),
                Row(children: [
                  const SizedBox(width: 70, child: Text('Length')),
                  IconButton(
                    onPressed: _c.repeats > 1 ? () => _set(_c.copyWith(repeats: _c.repeats - 1)) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${_c.repeats * 4} bars · ${_c.lengthSec.round()} s'),
                  IconButton(
                    onPressed: _c.repeats < 8 ? () => _set(_c.copyWith(repeats: _c.repeats + 1)) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ]),
              ]),
            ),
    );
  }

  Widget _transport() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(children: [
          SizedBox(
            width: 56,
            height: 56,
            child: _rendering
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 3))
                : IconButton.filled(
                    iconSize: 30,
                    onPressed: _togglePlay,
                    icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${noteNames[_c.keyRoot]} ${_c.minor ? 'minor' : 'major'} · ${_c.bpm} bpm',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                _rendering
                    ? 'Playing it on the phone’s synth…'
                    : 'Every sound is synthesised on your phone — 100% yours, no copyright.',
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ]),
          ),
        ]),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDim, fontSize: 12.5)),
      );
}

/// 5 × 16 step grid; while playing, the current step's column lights up.
class _DrumGrid extends StatelessWidget {
  final Composition composition;
  final AudioPlayer player;
  final bool playing;
  final void Function(int row, int step) onToggle;
  const _DrumGrid({required this.composition, required this.player, required this.playing, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final grid = composition.grid;
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) {
        final ms = snap.data?.inMilliseconds ?? 0;
        final barMs = composition.barSec * 1000;
        final current = playing ? ((ms % barMs) / barMs * 16).floor() : -1;
        return Column(children: [
          for (var r = 0; r < drumRows.length; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                SizedBox(
                  width: 62,
                  child: Text(drumLabels[r], style: const TextStyle(fontSize: 11.5, color: AppColors.textDim)),
                ),
                for (var s = 0; s < 16; s++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onToggle(r, s),
                      child: Container(
                        height: 26,
                        margin: EdgeInsets.only(right: s % 4 == 3 ? 4 : 1.5),
                        decoration: BoxDecoration(
                          color: grid[r][s]
                              ? AppColors.ember.withValues(alpha: s == current ? 1 : 0.85)
                              : (s == current
                                  ? AppColors.surfaceTop
                                  : (s ~/ 4).isEven
                                      ? AppColors.surfaceHigh
                                      : AppColors.surface),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: s == current ? AppColors.text : AppColors.line, width: 0.8),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
        ]);
      },
    );
  }
}
