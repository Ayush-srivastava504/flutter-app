import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../ai/media_analysis.dart';
import '../export/export_engine.dart';
import '../services/audio_metadata_service.dart';
import 'audio_edit.dart';
import 'composer.dart';
import 'reverb_ir.dart';
import 'wav.dart';

/// Everything the Audio Studio does outside the widgets: FFmpeg renders
/// (through the same `FfmpegKitEngine` the video export uses), waveform
/// extraction, reverb impulses, composition rendering, and delivery
/// (save to Music, share).
class AudioStudioService {
  final FfmpegKitEngine engine;
  AudioStudioService({FfmpegKitEngine? engine}) : engine = engine ?? FfmpegKitEngine();

  static const _media = MethodChannel('clipforge/media');

  Future<Directory> _dir(String name) async {
    final d = Directory(p.join((await getApplicationDocumentsDirectory()).path, name));
    await d.create(recursive: true);
    return d;
  }

  Future<Directory> _tmp() async {
    final d = Directory(p.join((await getTemporaryDirectory()).path, 'audio_studio'));
    await d.create(recursive: true);
    return d;
  }

  /// Length of an audio file (0 when it can't be read).
  Future<int> durationMs(String path) async =>
      (await AudioMetadataService().readDuration(path))?.inMilliseconds ?? 0;

  /// Peak envelope of [path] for the waveform (mono 8 kHz decode).
  Future<List<double>> waveform(String path, {int buckets = 600}) async {
    final raw = File(p.join((await _tmp()).path, 'wave_${const Uuid().v4()}.pcm'));
    try {
      await (engine as MediaAnalyzer).analyze(['-y', '-i', path, '-ac', '1', '-ar', '8000', '-f', 's16le', raw.path]);
      if (!await raw.exists()) return const [];
      return peaksFromPcm16(await raw.readAsBytes(), buckets);
    } finally {
      if (await raw.exists()) await raw.delete();
    }
  }

  /// The impulse response file for [e]'s reverb, cached by its (rounded)
  /// settings so moving other sliders doesn't regenerate it.
  Future<String> impulseFor(AudioEdit e) async {
    final size = (e.reverbSize * 20).round() / 20, tone = (e.reverbTone * 10).round() / 10;
    final f = File(p.join((await _tmp()).path, 'ir_${(size * 100).round()}_${(tone * 100).round()}.wav'));
    if (!await f.exists()) {
      final bytes = await Isolate.run(() => reverbImpulseWav(size, tone));
      await f.writeAsBytes(bytes, flush: true);
    }
    return f.path;
  }

  /// Renders [src] with [edit]. [onProgress] gets 0..1.
  Future<File> render({
    required String src,
    required int sourceMs,
    required AudioEdit edit,
    AudioFormat format = AudioFormat.m4a,
    String? outPath,
    void Function(double)? onProgress,
  }) async {
    final out = outPath ?? p.join((await _tmp()).path, 'preview_${const Uuid().v4()}.${format.ext}');
    final ir = edit.hasReverb ? await impulseFor(edit) : null;
    final args = buildAudioRenderArgs(src: src, sourceMs: sourceMs, edit: edit, out: out, format: format, irPath: ir);
    final total = edit.outputMs(sourceMs);
    final result = await engine.run(args, onTimeMs: (t) {
      if (total > 0) onProgress?.call((t / total).clamp(0.0, 1.0));
    });
    final file = File(out);
    if (!result.success || !await file.exists() || await file.length() == 0) {
      final tail = result.log.length > 400 ? result.log.substring(result.log.length - 400) : result.log;
      throw StateError('Rendering failed. $tail');
    }
    return file;
  }

  /// Renders a composition to `<documents>/audio_studio/<id>.wav` (in a
  /// background isolate). Returns (path, duration ms).
  Future<(String, int)> renderCompositionToFile(Composition c, String id) async {
    final json = c.toJson();
    final bytes = await Isolate.run(() {
      final samples = renderComposition(Composition.fromJson(json));
      return encodeWav16(samples);
    });
    final f = File(p.join((await _dir('audio_studio')).path, '$id.wav'));
    await f.writeAsBytes(bytes, flush: true);
    final ms = ((bytes.length - 44) / 4 / composeRate * 1000).round();
    return (f.path, ms);
  }

  /// Copies an imported/recorded file into app storage, so the original can
  /// move or vanish without breaking the project.
  Future<String> keepCopy(String path) async {
    final dest = p.join((await _dir('audio_studio')).path, '${const Uuid().v4()}${p.extension(path)}');
    await File(path).copy(dest);
    return dest;
  }

  /// Puts [file] in the phone's Music/ClipForge folder. Returns where.
  Future<String> saveToMusic(File file, String name, AudioFormat format) async {
    final mime = switch (format) {
      AudioFormat.m4a => 'audio/mp4',
      AudioFormat.mp3 => 'audio/mpeg',
      AudioFormat.wav => 'audio/wav',
    };
    final safe = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return await _media.invokeMethod<String>('saveAudio', {
          'path': file.path,
          'name': '$safe.${format.ext}',
          'mime': mime,
        }) ??
        'Music/ClipForge';
  }

  Future<void> share(File file) => Share.shareXFiles([XFile(file.path)], text: 'Made with ClipForge');
}
