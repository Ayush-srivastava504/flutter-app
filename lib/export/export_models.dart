/// Plain value types for the export pipeline. No Flutter or drift imports so
/// the command builder (and its tests) run on the plain Dart VM.
library export_models;

/// Output quality presets. [shortSide] is the shorter edge of the rendered
/// frame; the longer edge follows the project's aspect ratio.
enum ExportQuality {
  p720('720p', 720, 5000000),
  p1080('1080p', 1080, 10000000);

  final String label;
  final int shortSide;
  final int videoBitrate;
  const ExportQuality(this.label, this.shortSide, this.videoBitrate);
}

/// One timeline clip, flattened to exactly what rendering needs.
class ExportClip {
  final String path;
  final bool isPhoto;
  final int trimStartMs;
  final int trimEndMs;
  final String transitionOut; // cut | fade | dissolve
  final double brightness;
  final double contrast;
  final double saturation;
  final bool muted;
  final double volume;
  final bool hasAudio;

  const ExportClip({
    required this.path,
    required this.isPhoto,
    required this.trimStartMs,
    required this.trimEndMs,
    this.transitionOut = 'cut',
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.muted = false,
    this.volume = 1.0,
    this.hasAudio = false,
  });

  int get durationMs => trimEndMs - trimStartMs;
}

class ExportOverlay {
  final String id;
  final String content;
  final String fontFamily; // key of textFontPresets
  final int colorValue; // 0xAARRGGBB
  final double fontSize; // logical px in the editor preview
  final double positionX; // 0..1 of the frame, text centre
  final double positionY;
  final int startMs;
  final int endMs;

  const ExportOverlay({
    required this.id,
    required this.content,
    this.fontFamily = 'Default',
    this.colorValue = 0xFFFFFFFF,
    this.fontSize = 24,
    this.positionX = 0.5,
    this.positionY = 0.5,
    required this.startMs,
    required this.endMs,
  });
}

class ExportMusic {
  final String path;
  final int trimStartMs;
  final int trimEndMs;
  final int offsetMs; // where on the (original) timeline the track starts
  final double volume;

  const ExportMusic({
    required this.path,
    required this.trimStartMs,
    required this.trimEndMs,
    this.offsetMs = 0,
    this.volume = 1.0,
  });
}

/// Which H.264 path to render with. Hardware encoders are fast and
/// memory-light; [software] (MPEG-4) is the last-resort fallback because the
/// non-GPL FFmpeg builds ship no libx264.
enum VideoEncoder { androidHardware, iosHardware, software }

/// Why an export failed, in terms the UI can explain to a person.
enum ExportFailureKind {
  nothingToExport,
  sourceMissing,
  insufficientStorage,
  interrupted,
  unsupportedCodec,
  unknown,
}

class ExportFailure implements Exception {
  final ExportFailureKind kind;
  final String message;
  final String? detail;
  const ExportFailure(this.kind, this.message, {this.detail});

  @override
  String toString() => 'ExportFailure($kind): $message';
}

/// A fully-resolved FFmpeg invocation.
class ExportCommand {
  final List<String> args;
  final int totalDurationMs;
  final int width;
  final int height;
  const ExportCommand(this.args, this.totalDurationMs, this.width, this.height);
}
