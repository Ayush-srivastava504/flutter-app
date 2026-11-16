import 'dart:async';

// All FFmpegKit usage is confined to this file. The original `ffmpeg_kit_flutter`
// was retired in 2025 and its binaries pulled, so this targets the maintained
// community fork `ffmpeg_kit_flutter_new_full` (non-GPL "full" build: includes
// libfreetype for drawtext, no libx264 — hence the hardware-encoder path).
// If the fork's file layout differs from the original's, fix the imports here only.
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';

import '../ai/media_analysis.dart' show MediaAnalyzer;

class EngineResult {
  final bool success;
  final bool cancelled;

  /// Tail of FFmpeg's log, used to classify failures (disk full, bad codec…).
  final String log;
  const EngineResult({required this.success, required this.cancelled, required this.log});
}

/// Seam between the export service and FFmpeg, so the service's retry /
/// failure-mapping logic can be tested with a fake.
abstract class ExportEngine {
  Future<bool> hasAudioStream(String path);

  /// Runs [args]; [onTimeMs] receives how much output has been rendered.
  Future<EngineResult> run(List<String> args, {required void Function(int timeMs) onTimeMs});

  Future<void> cancel();
}

class FfmpegKitEngine implements ExportEngine, MediaAnalyzer {
  static const int _maxLogChars = 20000;

  /// Analysis results *are* the log, so it is kept whole up to this cap
  /// (~hours of silencedetect output) instead of being trimmed to a tail.
  static const int _maxAnalysisLogChars = 2000000;
  int? _sessionId;

  @override
  Future<String> analyze(List<String> args) {
    final done = Completer<String>();
    final log = StringBuffer();
    unawaited(() async {
      try {
        await FFmpegKit.executeWithArgumentsAsync(
          args,
          (finished) async {
            if (!done.isCompleted) done.complete(log.toString());
          },
          (l) {
            if (log.length < _maxAnalysisLogChars) log.writeln(l.getMessage());
          },
        );
      } catch (e) {
        if (!done.isCompleted) done.completeError(StateError('FFmpegKit failed to start: $e'));
      }
    }());
    return done.future;
  }

  @override
  Future<bool> hasAudioStream(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final streams = session.getMediaInformation()?.getStreams() ?? const [];
      return streams.any((s) => s.getType() == 'audio');
    } catch (_) {
      return false; // can't probe → treat as silent rather than failing the export
    }
  }

  @override
  Future<EngineResult> run(List<String> args, {required void Function(int timeMs) onTimeMs}) {
    final done = Completer<EngineResult>();
    final log = StringBuffer();

    // If the native FFmpegKit layer can't start (missing native library, wrong
    // ABI, stripped by R8…) the call below throws. Without the catch the
    // returned future would never complete and the export would sit at 0% forever.
    unawaited(() async {
      try {
        final started = await FFmpegKit.executeWithArgumentsAsync(
          args,
          (finished) async {
            final rc = await finished.getReturnCode();
            var text = log.toString();
            if (text.length > _maxLogChars) text = text.substring(text.length - _maxLogChars);
            if (!done.isCompleted) {
              done.complete(EngineResult(
                success: ReturnCode.isSuccess(rc),
                cancelled: ReturnCode.isCancel(rc),
                log: text,
              ));
            }
          },
          (l) {
            log.writeln(l.getMessage());
            if (log.length > _maxLogChars * 2) {
              final tail = log.toString().substring(log.length - _maxLogChars);
              log
                ..clear()
                ..write(tail);
            }
          },
          (stats) {
            final Object? t = stats.getTime();
            if (t is num && t >= 0) onTimeMs(t.toInt());
          },
        );
        _sessionId = started.getSessionId();
      } catch (e) {
        if (!done.isCompleted) {
          done.complete(EngineResult(success: false, cancelled: false, log: 'FFmpegKit failed to start: $e'));
        }
      }
    }());

    return done.future;
  }

  @override
  Future<void> cancel() async {
    final id = _sessionId;
    if (id != null) {
      await FFmpegKit.cancel(id);
    } else {
      await FFmpegKit.cancel();
    }
  }
}
