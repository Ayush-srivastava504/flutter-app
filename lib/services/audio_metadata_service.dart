import 'package:ffmpeg_kit_flutter_new_full/ffprobe_kit.dart';

/// Reads an audio file's duration via FFprobeKit.
///
/// Same rationale as [MediaMetadataService] (see that file): this is
/// read-only container probing, not compositing, so it doesn't touch the
/// Phase 8 FFmpeg export pipeline — it just needs to know how long a
/// picked music file is so [AudioImportService] can hand the timeline a
/// track with a real `durationMs` instead of a guess.
class AudioMetadataService {
  /// Returns the file's duration, or null if it couldn't be read
  /// (corrupt file, unsupported container, etc). Callers should fall
  /// back to `Duration.zero` and let the user trim manually rather than
  /// blocking the import on this.
  Future<Duration?> readDuration(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      final durationSeconds = info?.getDuration();
      if (durationSeconds == null) return null;

      final seconds = double.tryParse(durationSeconds);
      if (seconds == null || seconds <= 0) return null;

      return Duration(milliseconds: (seconds * 1000).round());
    } catch (_) {
      return null;
    }
  }
}
