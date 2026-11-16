/// Plain value types for the export pipeline. No Flutter or drift imports so
/// the command builder (and its tests) run on the plain Dart VM.
library export_models;

import '../models/chroma_key.dart';

/// Output quality presets. [shortSide] is the shorter edge of the rendered
/// frame; the longer edge follows the project's aspect ratio.
///
/// [videoBitrate] is the bits/s used at [defaultExportFps]; use
/// [exportVideoBitrate] to get the value for a chosen frame rate.
///
/// Bitrates raised 2026-11-11: phones record 1080p at ~17-20 Mbit/s, and a
/// hardware H.264 encoder needs at least that much to keep the detail; the
/// old 10 Mbit/s visibly softened phone footage.
enum ExportQuality {
  p480('480p', 480, 4000000),
  p720('720p', 720, 8000000),
  p1080('1080p', 1080, 16000000),
  p2160('4K', 2160, 45000000);

  final String label;
  final int shortSide;
  final int videoBitrate;
  const ExportQuality(this.label, this.shortSide, this.videoBitrate);

  /// Parses a stored [name] (as saved in app prefs); null if unknown, so a
  /// stale or corrupt preference falls back to the default instead of crashing.
  static ExportQuality? tryParse(String? name) {
    for (final q in values) {
      if (q.name == name) return q;
    }
    return null;
  }
}

/// Frame rate used when the user has not picked one (and by old exports).
const int defaultExportFps = 30;

/// Frame rates offered in the export picker.
const List<int> exportFpsOptions = [24, 30, 60];

/// [fps] if it is one of [exportFpsOptions], otherwise [defaultExportFps].
/// Used when reading a saved preference.
int sanitizeExportFps(int? fps) =>
    fps != null && exportFpsOptions.contains(fps) ? fps : defaultExportFps;

/// Video bitrate (bits/s) for [quality] at [fps]. 60 fps carries twice the
/// frames per second, so it gets 1.5x the base bitrate; 24 and 30 fps use the
/// base value. Shared by the encoder arguments and the size estimate.
int exportVideoBitrate(ExportQuality quality, int fps) =>
    fps >= 60 ? quality.videoBitrate * 3 ~/ 2 : quality.videoBitrate;

/// One timeline clip, flattened to exactly what rendering needs.
class ExportClip {
  final String path;
  final bool isPhoto;
  final int trimStartMs;
  final int trimEndMs;
  final String transitionOut; // any id in `transitionOptions` (transition_x.dart)
  final double brightness;
  final double contrast;
  final double saturation;
  final bool muted;
  final double volume;
  final bool hasAudio;

  /// F7: which named look (`models/look_x.dart`) is layered on top of
  /// brightness/contrast/saturation, or null for none.
  final String? look;

  /// How strongly [look] is applied, 0..1 (`Clips.lookStrength`).
  final double lookStrength;

  /// F10: quarter-turns clockwise (0–3) plus horizontal/vertical flip,
  /// applied on top of whatever the source file's own container
  /// rotation already auto-applies (see `export_command_builder.dart`'s
  /// class doc comment on why that auto-rotation is never duplicated
  /// by hand) — a separate, deliberate edit.
  final int turns;
  final bool flipH;
  final bool flipV;

  /// F11: constant playback speed (0.5–2.0, 1.0 = unchanged). Always
  /// 1.0 for photos — `export_inputs.dart`'s `exportClipsFrom` enforces
  /// that at the mapping layer, same place it already forces `isPhoto`.
  final double speed;

  /// F15: 'fit' | 'fill' | 'blur' (see `models/fit_mode_x.dart`).
  final String fitMode;

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
    this.look,
    this.lookStrength = 1.0,
    this.turns = 0,
    this.flipH = false,
    this.flipV = false,
    this.speed = 1.0,
    this.fitMode = 'fit',
    this.effect,
    this.effectStrength = 1.0,
    this.enhanceSpeech = false,
    this.chromaKey,
  });

  /// v12: background removal, or null.
  final ChromaKeySpec? chromaKey;

  /// v11: effect id (`models/effect_x.dart`) or null, and its strength.
  final String? effect;
  final double effectStrength;

  /// v11: clean up this clip's voice ([speechEnhanceFilters]).
  final bool enhanceSpeech;

  /// Effective (post-speed) playback duration — what this clip actually
  /// occupies on the rendered timeline, not the raw trimmed source span.
  /// Every timeline-length calculation in `export_command_builder.dart`
  /// (boundaries, total duration, the `durs[]` array) reads this getter,
  /// so changing [speed] propagates correctly everywhere from this one
  /// place. `trimStartMs`/`trimEndMs` themselves stay raw source
  /// offsets — they still tell FFmpeg's `trim=` filter which *source*
  /// range to read; only how fast that range *plays back* changes.
  int get durationMs {
    final rawMs = trimEndMs - trimStartMs;
    if (speed == 1.0) return rawMs;
    final s = speed <= 0 ? 1.0 : speed;
    return (rawMs / s).round();
  }
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

  /// F8 (text styling v2): bold weight, an optional background box, and
  /// an optional outline/stroke, independent of [colorValue] (the fill).
  final bool bold;
  final bool boxEnabled;
  final int boxColorValue; // 0xAARRGGBB
  final double outlineWidth; // logical px, same space as fontSize; 0 = none
  final int outlineColorValue; // 0xAARRGGBB

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
    this.bold = false,
    this.boxEnabled = false,
    this.boxColorValue = 0x99000000,
    this.outlineWidth = 0,
    this.outlineColorValue = 0xFF000000,
  });
}

/// v11: a voice-over placed at [startMs] on the editor timeline.
class ExportVoiceOver {
  final String path;
  final int startMs;
  final double volume;
  final bool enhance;
  const ExportVoiceOver({required this.path, required this.startMs, this.volume = 1.0, this.enhance = true});
}

class ExportMusic {
  final String path;
  final int trimStartMs;
  final int trimEndMs;
  final int offsetMs; // where on the (original) timeline the track starts
  final double volume;

  /// F9: fade in/out at the music's own trimmed start/end, in ms. 0 =
  /// no fade.
  final int fadeInMs;
  final int fadeOutMs;

  const ExportMusic({
    required this.path,
    required this.trimStartMs,
    required this.trimEndMs,
    this.offsetMs = 0,
    this.volume = 1.0,
    this.fadeInMs = 0,
    this.fadeOutMs = 0,
  });
}

/// Which H.264 path to render with. Hardware encoders are fast and
/// memory-light; [software] (MPEG-4) is the last-resort fallback because the
/// non-GPL FFmpeg builds ship no libx264.
/// Encoders, tried in order until one works (see `ExportService`).
///
/// `androidHardwareHigh` is the phone's H.264 encoder asked for High
/// profile and VBR rate control; some encoders reject that, so plain
/// `androidHardware` (device defaults) comes next. `software` (mpeg4) is the
/// last resort: it always works but looks worse at the same size.
enum VideoEncoder { androidHardwareHigh, androidHardware, iosHardware, software }

/// How the export screen names an encoder after a successful export.
String videoEncoderLabel(VideoEncoder e) => const {
      VideoEncoder.androidHardwareHigh: 'Hardware H.264, High profile',
      VideoEncoder.androidHardware: 'Hardware H.264',
      VideoEncoder.iosHardware: 'Hardware H.264',
      VideoEncoder.software: 'Compatibility encoder (lower quality)',
    }[e]!;

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
