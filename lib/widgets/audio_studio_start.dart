import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/app_theme.dart';
import '../audio/audio_studio_service.dart';
import '../audio/composer.dart';
import '../data/database_provider.dart';
import '../data/project_database.dart';
import '../router/app_router.dart';
import '../services/audio_import_service.dart';
import '../services/voice_recorder.dart';

/// Home → Audio Studio: edit a file, record something, or compose a beat.
Future<void> showAudioStudioStart(BuildContext context, WidgetRef ref) async {
  final choice = await showModalBottomSheet<int>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text('Audio Studio', style: Theme.of(ctx).textTheme.titleLarge),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text('Trim, clean up, add reverb, echo and voice effects — or make your own beat.',
              style: TextStyle(color: AppColors.textDim)),
        ),
        ListTile(
          leading: const Icon(Icons.audio_file_outlined, color: AppColors.ember),
          title: const Text('Edit an audio file'),
          subtitle: const Text('Songs, voice notes, podcasts — MP3, M4A, WAV…'),
          onTap: () => Navigator.pop(ctx, 0),
        ),
        ListTile(
          leading: const Icon(Icons.mic_none_rounded, color: AppColors.ember),
          title: const Text('Record'),
          subtitle: const Text('Use the microphone, then add effects'),
          onTap: () => Navigator.pop(ctx, 1),
        ),
        ListTile(
          leading: const Icon(Icons.piano_outlined, color: AppColors.ember),
          title: const Text('Compose a beat'),
          subtitle: const Text('Drums, chords, bass and melody — made on your phone'),
          onTap: () => Navigator.pop(ctx, 2),
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (choice == null || !context.mounted) return;
  final db = ref.read(projectDatabaseProvider);

  Future<void> create(String name, {String? source, int ms = 0, String? compose, required String route}) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await db.insertAudioProject(AudioProjectsCompanion.insert(
      id: id,
      name: name,
      sourceUri: Value(source),
      durationMs: Value(ms),
      composeJson: Value(compose),
      createdAt: now,
      updatedAt: now,
    ));
    if (context.mounted) await Navigator.pushNamed(context, route, arguments: id);
  }

  try {
    switch (choice) {
      case 0:
        final asset = await AudioImportService().pickFromDevice();
        if (asset == null) return;
        await create(
          asset.displayName.isEmpty ? 'Audio' : asset.displayName.replaceAll(RegExp(r'\.[^.]+$'), ''),
          source: asset.uri,
          ms: asset.duration.inMilliseconds,
          route: AppRouter.audio,
        );
      case 1:
        if (!context.mounted) return;
        final rec = await showDialog<(String, int)>(context: context, builder: (_) => const _RecordDialog());
        if (rec == null) return;
        final kept = await AudioStudioService().keepCopy(rec.$1);
        final now = DateTime.now();
        await create('Recording ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            source: kept, ms: rec.$2, route: AppRouter.audio);
      case 2:
        await create('New beat', compose: stylePreset('lofi').toJson(), route: AppRouter.compose);
    }
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't start: $e")));
  }
}

class _RecordDialog extends StatefulWidget {
  const _RecordDialog();

  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  final _rec = VoiceRecorder();
  final _watch = Stopwatch();
  Timer? _tick;
  bool _recording = false;
  double _level = 0;
  String? _error;

  @override
  void dispose() {
    _tick?.cancel();
    if (_recording) _rec.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (!await _rec.ensurePermission()) {
      setState(() => _error = 'ClipForge needs the microphone. Allow it in Settings → Apps → ClipForge.');
      return;
    }
    await _rec.start();
    _watch
      ..reset()
      ..start();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      final l = await _rec.level();
      if (mounted) setState(() => _level = l);
    });
    setState(() => _recording = true);
  }

  Future<void> _stop() async {
    _tick?.cancel();
    _watch.stop();
    final ms = await _rec.stop();
    final path = _rec.path;
    if (!mounted) return;
    if (ms < 300 || path == null || !File(path).existsSync()) {
      setState(() {
        _recording = false;
        _error = 'That was too short. Try again.';
      });
      return;
    }
    Navigator.pop(context, (path, ms));
  }

  @override
  Widget build(BuildContext context) {
    final s = _watch.elapsedMilliseconds ~/ 1000;
    return AlertDialog(
      title: const Text('Record'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: _recording ? _level : 0, minHeight: 6),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: AppColors.warn, fontSize: 12.5)),
        ],
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _recording ? _stop : _start,
          icon: Icon(_recording ? Icons.stop_rounded : Icons.fiber_manual_record, size: 18),
          label: Text(_recording ? 'Stop' : 'Start'),
        ),
      ],
    );
  }
}
