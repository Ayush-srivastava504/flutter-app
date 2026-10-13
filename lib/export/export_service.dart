import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/project_database.dart';
import 'export_command_builder.dart';
import 'export_engine.dart';
import 'export_inputs.dart';
import 'export_models.dart';

/// Rough output size, for the quality picker ("~48 MB").
int estimatedExportBytes(ExportQuality quality, int durationMs, {int fps = defaultExportFps}) =>
    ((exportVideoBitrate(quality, fps) + 192000) * durationMs / 1000 / 8).round();

/// Maps FFmpeg's log tail to a failure kind. Pure, so it's unit-tested.
ExportFailureKind classifyFfmpegLog(String log) {
  final l = log.toLowerCase();
  if (l.contains('no space left') || l.contains('enospc') || l.contains('disk full')) {
    return ExportFailureKind.insufficientStorage;
  }
  if (l.contains('no such file or directory') && !l.contains('fontfile')) {
    return ExportFailureKind.sourceMissing;
  }
  if (l.contains('unknown encoder') ||
      l.contains('encoder not found') ||
      l.contains('error while opening encoder') ||
      l.contains('could not open codec') ||
      l.contains('invalid data found when processing input') ||
      l.contains('moov atom not found') ||
      l.contains('could not find codec parameters') ||
      (l.contains('decoder') && l.contains('not found'))) {
    return ExportFailureKind.unsupportedCodec;
  }
  return ExportFailureKind.unknown;
}

String failureMessage(ExportFailureKind kind) {
  switch (kind) {
    case ExportFailureKind.nothingToExport:
      return 'Add at least one clip before exporting.';
    case ExportFailureKind.sourceMissing:
      return 'One of the clips or the music track is no longer on this device. '
          'Re-import it, or remove it from the timeline.';
    case ExportFailureKind.insufficientStorage:
      return 'Not enough free storage to finish the export. '
          'Free up some space (or pick 720p) and try again.';
    case ExportFailureKind.interrupted:
      return 'The export was interrupted before it finished.';
    case ExportFailureKind.unsupportedCodec:
      return 'A clip uses a video or photo format this device can\'t process '
          '(for example some HEIC photos). Try replacing it with a JPG/PNG or an MP4.';
    case ExportFailureKind.unknown:
      return 'The export failed unexpectedly. Please try again.';
  }
}

class ExportService {
  final ProjectDatabase db;
  final ExportEngine engine;
  final Future<Directory> Function() _tempDir;
  final List<VideoEncoder> _encoders;

  ExportService({
    required this.db,
    ExportEngine? engine,
    Future<Directory> Function()? tempDir,
    List<VideoEncoder>? encoders,
  })  : engine = engine ?? FfmpegKitEngine(),
        _tempDir = tempDir ?? getTemporaryDirectory,
        _encoders = encoders ??
            [
              if (Platform.isAndroid) VideoEncoder.androidHardware,
              if (Platform.isIOS) VideoEncoder.iosHardware,
              VideoEncoder.software, // always last: slower, but works everywhere
            ];

  static const _fontAssets = {
    'Default': 'DejaVuSans.ttf',
    'Serif': 'DejaVuSerif.ttf',
    'Monospace': 'DejaVuSansMono.ttf',
    'Cursive': 'DejaVuSerif-Italic.ttf',
  };

  Future<void> cancel() => engine.cancel();

  /// Renders [projectId] to an MP4 and returns it. Throws [ExportFailure].
  /// [onProgress] gets 0.0–1.0.
  Future<File> export({
    required String projectId,
    required ExportQuality quality,
    int fps = defaultExportFps,
    required void Function(double progress) onProgress,
  }) async {
    final project = await db.getProject(projectId);
    final clipRows = await db.watchClips(projectId).first;
    if (project == null || clipRows.isEmpty) {
      throw ExportFailure(ExportFailureKind.nothingToExport, failureMessage(ExportFailureKind.nothingToExport));
    }
    final overlayRows = await db.watchTextOverlays(projectId).first;
    final audioRow = await db.getAudioTrack(projectId);

    // Fail early, and clearly, if a source vanished (user deleted it, SD card…).
    final sources = [...clipRows.map((c) => c.sourceUri), if (audioRow != null) audioRow.sourceUri];
    for (final path in sources) {
      if (!await File(path).exists()) {
        throw ExportFailure(ExportFailureKind.sourceMissing, failureMessage(ExportFailureKind.sourceMissing),
            detail: path);
      }
    }

    final hasAudio = <String, bool>{};
    for (final c in clipRows.where((c) => !isPhotoPath(c.sourceUri))) {
      hasAudio[c.sourceUri] ??= await engine.hasAudioStream(c.sourceUri);
    }

    final root = await _tempDir();
    await _pruneOldExports(root);
    final work = Directory(p.join(root.path, 'export_${DateTime.now().millisecondsSinceEpoch}'));
    await work.create(recursive: true);

    try {
      final fonts = await _materialiseFonts(root);
      final textFiles = <String, String>{};
      for (final o in overlayRows) {
        final f = File(p.join(work.path, 'text_${o.id}.txt'));
        await f.writeAsString(o.content);
        textFiles[o.id] = f.path;
      }

      final clips = exportClipsFrom(clipRows, hasAudio);
      final overlays = exportOverlaysFrom(overlayRows);
      final music = exportMusicFrom(audioRow);
      final output = p.join(work.path, 'ClipForge_${DateTime.now().millisecondsSinceEpoch}.mp4');

      ExportFailure? last;
      for (var i = 0; i < _encoders.length; i++) {
        final cmd = buildExportCommand(
          clips: clips,
          overlays: overlays,
          music: music,
          aspectRatio: project.aspectRatio,
          quality: quality,
          fps: fps,
          encoder: _encoders[i],
          outputPath: output,
          fontPaths: fonts,
          textFilePaths: textFiles,
        );
        onProgress(0);
        final result = await engine.run(cmd.args, onTimeMs: (t) {
          if (cmd.totalDurationMs > 0) onProgress((t / cmd.totalDurationMs).clamp(0.0, 0.99).toDouble());
        });

        if (result.success && await File(output).exists() && await File(output).length() > 0) {
          onProgress(1);
          return File(output);
        }
        if (result.cancelled) {
          throw ExportFailure(ExportFailureKind.interrupted, failureMessage(ExportFailureKind.interrupted));
        }
        final kind = classifyFfmpegLog(result.log);
        final report = 'encoder: ${_encoders[i].name}\n'
            'quality: ${quality.label} @ $fps fps\n'
            'classified as: ${kind.name}\n'
            'command: ffmpeg ${cmd.args.join(' ')}\n'
            '--- ffmpeg log tail ---\n${result.log}';
        debugPrint('[export] FAILED\n$report');
        last = ExportFailure(kind, failureMessage(kind), detail: report);
        // Disk full / missing source won't be fixed by another encoder; anything else gets
        // one more try on the next (more compatible) encoder.
        if (kind == ExportFailureKind.insufficientStorage || kind == ExportFailureKind.sourceMissing) break;
        if (await File(output).exists()) await File(output).delete();
      }
      throw last ?? ExportFailure(ExportFailureKind.unknown, failureMessage(ExportFailureKind.unknown));
    } on FileSystemException catch (e) {
      final full = e.osError?.errorCode == 28; // ENOSPC
      final kind = full ? ExportFailureKind.insufficientStorage : ExportFailureKind.unknown;
      throw ExportFailure(kind, failureMessage(kind), detail: e.toString());
    } finally {
      // Text scratch files are always disposable; the finished MP4 is kept until the
      // caller has saved/shared it and is swept by _pruneOldExports on a later run.
      for (final f in work.listSync().whereType<File>().where((f) => f.path.endsWith('.txt'))) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
  }

  Future<Map<String, String>> _materialiseFonts(Directory root) async {
    final dir = Directory(p.join(root.path, 'clipforge_fonts'));
    await dir.create(recursive: true);
    final map = <String, String>{};
    for (final entry in _fontAssets.entries) {
      final file = File(p.join(dir.path, entry.value));
      if (!await file.exists() || await file.length() == 0) {
        final data = await rootBundle.load('assets/fonts/${entry.value}');
        await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      }
      map[entry.key] = file.path;
    }
    return map;
  }

  /// Deletes export folders older than a day — covers interrupted runs and
  /// finished files that were never cleaned up.
  Future<void> _pruneOldExports(Directory root) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    try {
      await for (final e in root.list()) {
        if (e is Directory && p.basename(e.path).startsWith('export_')) {
          if ((await e.stat()).modified.isBefore(cutoff)) await e.delete(recursive: true);
        }
      }
    } catch (_) {}
  }
}
