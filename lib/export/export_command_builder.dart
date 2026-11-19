/// Pure FFmpeg command construction for Phase 8 export. Port of the
/// prototype in `tools/graph_prototype.py`, which is exercised against a real
/// FFmpeg by `tools/verify_export_graph.py` — keep the two in step.
///
/// Timeline semantics (they match what the editor preview shows):
///  * clips play end to end using their trim window and order;
///  * `fade` = dip through black: fade out the last 300ms of the clip, fade in
///    the first 300ms of the next. Timeline length is unchanged;
///  * `dissolve` = real overlapping cross-dissolve (up to 600ms). This
///    shortens the output, so text and music times that sit after a dissolve
///    are shifted earlier by the overlap ([_Timeline.remap]) to stay glued to
///    the same picture;
///  * per-clip brightness/contrast/saturation map onto FFmpeg `eq`
///    (contrast = 1 + c, saturation = 1 + s, identical to the preview matrix);
///  * rotation metadata is NOT applied by hand — FFmpeg auto-rotates, and
///    doing it twice would turn clips sideways. `ExportClip.turns`/`flipH`/
///    `flipV` (F10) are a separate, deliberate user edit layered on top of
///    that, via explicit `transpose`/`hflip`/`vflip` filters;
///  * `ExportClip.speed` (F11) scales a clip's own `setpts` (video) and
///    adds one `atempo` (audio) — see `ExportClip.durationMs`, which is
///    already the post-speed effective duration, so every timeline-length
///    calculation below (boundaries, `durs[]`, total) is speed-aware with
///    no further changes needed in this file;
///  * `ExportClip.look` (F7) maps to an FFmpeg `colorchannelmixer` (for
///    the tinted looks) and/or `vignette` filter, inserted after `eq`;
///  * `ExportMusic.fadeInMs`/`fadeOutMs` (F9) map to `afade` on the music
///    chain;
///  * `ExportOverlay.bold`/`boxEnabled`/`outlineWidth` (F8) map to
///    `drawtext`'s `borderw`/`box`/`boxcolor` options.
library export_command_builder;

import 'dart:math' as math;

import '../models/color_filter_x.dart' show buildColorMatrix, isNeutralFilter;
import '../models/fit_mode_x.dart';
import '../models/chroma_key.dart';
import '../models/effect_x.dart';
import '../models/look_x.dart' show ScaledLook, scaledLook;
import '../models/transition_x.dart' show xfadeNameFor;
import 'export_models.dart';

const int maxDissolveMs = 600;
const int fadeDipMs = 300;
const int audioRate = 44100;

/// Width, in editor logical pixels, of the preview frame the overlay font
/// sizes were authored against. Export scales text by outputWidth / this.
const double previewReferenceWidth = 360;

class _Boundary {
  /// cut | fade | dissolve. Every overlapping transition (cross-dissolve,
  /// slide, wipe, circle, zoom — F13) is kind `dissolve`; they differ only
  /// in [xfade], the FFmpeg `xfade` transition name.
  final String kind;
  final int ms;
  final String xfade;
  const _Boundary(this.kind, this.ms, [this.xfade = 'fade']);
}

/// F11: the `atempo` filter(s) for [speed]. One `atempo` only accepts
/// 0.5–2.0, so speeds outside that are split into a chain whose product is
/// [speed] (e.g. 4x -> `atempo=2.000,atempo=2.000`). Empty at 1.0.
List<String> atempoChain(double speed) {
  if (speed <= 0 || speed == 1.0) return const [];
  final out = <String>[];
  var rest = speed;
  while (rest > 2.0) {
    out.add('atempo=2.000');
    rest /= 2.0;
  }
  while (rest < 0.5) {
    out.add('atempo=0.500');
    rest /= 0.5;
  }
  if ((rest - 1.0).abs() > 0.0005) out.add('atempo=${rest.toStringAsFixed(3)}');
  return out;
}

class _Timeline {
  /// (original boundary time, overlap) for every dissolve.
  final List<(int, int)> overlaps;
  final int totalMs;
  const _Timeline(this.overlaps, this.totalMs);

  int remap(int t) {
    var shift = 0;
    for (final (boundary, overlap) in overlaps) {
      if (boundary <= t) shift += overlap;
    }
    return (t - shift).clamp(0, totalMs).toInt();
  }
}

int _even(num n) {
  final r = n.round();
  return r.isEven ? r : r + 1;
}

String _sec(num ms) => (ms / 1000).toStringAsFixed(3);

/// Escapes a path for use inside a single-quoted filter option value.
String escapeFilterPath(String path) => path
    .replaceAll(r'\', r'\\')
    .replaceAll(':', r'\:')
    .replaceAll("'", r"\'");

/// F10: the `transpose`/`hflip`/`vflip` filters for [flipH]/[flipV]/
/// [turns] (quarter-turns clockwise, 0–3), in the order they should run
/// — flip first, then rotate, matching `_RotateFlip`'s doc comment in
/// `video_preview_player.dart` so preview and export agree. A 180°
/// turn has no single `transpose` value, so it's folded into the flip
/// pair instead (XOR'd with any flip the user also asked for) rather
/// than emitted as a separate step.
List<String> rotateFlipFilters({
  required bool flipH,
  required bool flipV,
  required int turns,
}) {
  var h = flipH;
  var v = flipV;
  String? transpose;
  switch (turns % 4) {
    case 1:
      transpose = 'transpose=1'; // 90° clockwise
      break;
    case 2:
      h = !h;
      v = !v;
      break;
    case 3:
      transpose = 'transpose=2'; // 90° counter-clockwise == 270° clockwise
      break;
  }
  return [
    if (h) 'hflip',
    if (v) 'vflip',
    if (transpose != null) transpose,
  ];
}

/// F7: converts a look's flat 4x5 RGB-mix matrix (`models/look_x.dart`)
/// into FFmpeg `colorchannelmixer` arguments. The 9 RGB coefficients are
/// scale-invariant (same ratios whether channels run 0..1 or 0..255),
/// and every look matrix is bias-free by design (see that module's doc
/// comment on why), so this is exactly those 9 numbers — no further
/// conversion needed, and no risk of this filter drifting from what the
/// preview actually shows.
///
/// The coefficients are passed by **name**. Positional values are a trap:
/// colorchannelmixer's option order is rr,rg,rb,*ra*,gr,… (an alpha slot
/// per channel), so 9 positional numbers land in the wrong slots — that
/// turned every look and colour slider into a strong blue/purple cast in
/// exported videos until 2026-11-11 (seen on a real phone).
String ffmpegColorChannelMixerFilter(List<double> matrix) {
  String v(int i) => matrix[i].toStringAsFixed(4);
  return 'colorchannelmixer='
      'rr=${v(0)}:rg=${v(1)}:rb=${v(2)}:'
      'gr=${v(5)}:gg=${v(6)}:gb=${v(7)}:'
      'br=${v(10)}:bg=${v(11)}:bb=${v(12)}';
}

/// A 4x5 colour matrix (`ColorFilter.matrix` layout, offsets 0..255) as
/// FFmpeg filters that exist in the phone's FFmpegKit build:
/// `colorchannelmixer` for the 3x3 part and `lutrgb` for the offsets
/// (scaled by `maxval/255`, so >8-bit sources are right too). Either is
/// left out when it would be a no-op.
List<String> matrixFilters(List<double> m) {
  final out = <String>[];
  const identity3 = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0];
  final mix = [m[0], m[1], m[2], m[5], m[6], m[7], m[10], m[11], m[12]];
  var isIdentity = true;
  for (var i = 0; i < 9; i++) {
    if ((mix[i] - identity3[i]).abs() > 1e-6) isIdentity = false;
  }
  if (!isIdentity) out.add(ffmpegColorChannelMixerFilter(m));
  final offsets = [m[4], m[9], m[14]];
  if (offsets.any((o) => o.abs() > 1e-6)) {
    String ch(double o) => "'clip(val+${o.toStringAsFixed(3)}*maxval/255,minval,maxval)'";
    out.add('lutrgb=r=${ch(offsets[0])}:g=${ch(offsets[1])}:b=${ch(offsets[2])}');
  }
  return out;
}

/// Brightness/contrast/saturation as FFmpeg filters.
///
/// `eq` would be the obvious choice, but it is GPL and the non-GPL
/// `ffmpeg_kit_flutter_new_full` build leaves it out ("No such filter:
/// 'eq'" on a real phone, 2026-11-11). Instead this exports the *same*
/// matrix the preview uses (`buildColorMatrix`) via [matrixFilters].
/// Empty when all three are 0.
List<String> colorAdjustFilters({
  required double brightness,
  required double contrast,
  required double saturation,
}) {
  if (isNeutralFilter(brightness: brightness, contrast: contrast, saturation: saturation)) {
    return const [];
  }
  return matrixFilters(buildColorMatrix(brightness: brightness, contrast: contrast, saturation: saturation));
}

/// Not an FFmpeg filter: a step in [lookFilters]'s output meaning "draw ink
/// outlines here at opacity <value>". It needs a branched graph (split →
/// edge-detect one copy → multiply it back over the other), which
/// `buildExportCommand` builds when it meets this step.
const String edgeStepPrefix = 'edges:';

/// The edge-detect branch for [edgeStepPrefix]: thin Canny lines on the
/// luma plane, inverted so lines are dark on white, ready to multiply.
const String edgeBranchFilters = 'edgedetect=low=0.08:high=0.2:planes=1,negate=components=y';

/// The FFmpeg steps for [look] at [strength] (0..1) on a frame
/// [outputWidth] pixels wide. Pixel sizes in `LookSpec` are defined at
/// 1080 px wide and scaled from there.
///
/// Every filter here was checked to exist in the phone's FFmpegKit build
/// (2026-11-11): colorchannelmixer, lutrgb, colorbalance, negate, pixelize, edgedetect,
/// blend, unsharp, rgbashift, noise, vignette. ⚠️ Their *look* has not
/// been compared with the preview on a phone.
List<String> lookFilters(String? look, {double strength = 1.0, int outputWidth = 1080}) =>
    scaledLookFilters(scaledLook(look, strength), outputWidth: outputWidth);

/// [lookFilters] for an already-scaled spec — also used for stylise
/// effects (`models/effect_x.dart`), which are look specs drawn as a
/// second pass.
List<String> scaledLookFilters(ScaledLook l, {int outputWidth = 1080}) {
  if (l.isNone) return const [];
  double px(double v) => v * outputWidth / 1080;
  String n(double v) => v.toStringAsFixed(3);
  final out = <String>[];

  final m = l.matrix;
  if (m != null) out.addAll(matrixFilters(m));
  final sh = l.shadows, hi = l.highlights;
  if (sh != null || hi != null) {
    final parts = <String>[
      if (sh != null) ...['rs=${n(sh[0])}', 'gs=${n(sh[1])}', 'bs=${n(sh[2])}'],
      if (hi != null) ...['rh=${n(hi[0])}', 'gh=${n(hi[1])}', 'bh=${n(hi[2])}'],
    ];
    out.add('colorbalance=${parts.join(':')}');
  }
  if (l.negate > 0) {
    // negate has no strength, so blend toward the inverse with lutrgb.
    final e = "'val+${n(l.negate)}*(maxval+minval-2*val)'";
    out.add(l.negate >= 0.999 ? 'negate' : 'lutrgb=r=$e:g=$e:b=$e');
  }
  if (l.pixelate > 0) {
    final p = math.max(2, px(l.pixelate).round());
    out.add('pixelize=width=$p:height=$p');
  }
  if (l.posterize >= 2) {
    final q = '(maxval/${l.posterize - 1})';
    final e = "'val+${n(l.posterizeMix)}*(round(val/$q)*$q-val)'";
    out.add('lutrgb=r=$e:g=$e:b=$e');
  }
  if (l.edges > 0) out.add('$edgeStepPrefix${n(l.edges)}');
  if (l.sharpen > 0) out.add('unsharp=5:5:${(l.sharpen * 1.5).toStringAsFixed(2)}');
  if (l.chroma > 0) {
    final d = math.max(1, px(l.chroma).round());
    out.add('rgbashift=rh=-$d:bh=$d');
  }
  if (l.grain > 0) out.addAll(['format=yuv420p', 'noise=c0s=${(l.grain * 30).round()}:c0f=t+u']);
  if (l.vignette > 0) out.add('vignette=angle=${n(math.min(1.5, 0.2 + l.vignette * 1.2))}');
  return out;
}

/// Converts a 0xAARRGGBB value (as `TextOverlays.colorValue`/
/// `boxColorValue`/`outlineColorValue` store) into FFmpeg's
/// `0xRRGGBB@alpha` color syntax — the same conversion
/// `buildExportCommand` already did inline for the text fill color
/// before F8, now shared with the box/outline colors it adds.
String ffmpegColor(int argb) {
  final alpha = ((argb >> 24) & 0xFF) / 255;
  final rgb = (argb & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0');
  return '0x$rgb@${alpha.toStringAsFixed(2)}';
}

/// Output frame size for [aspect] (width / height) at [shortSide].
(int, int) exportDimensions(double aspect, int shortSide) {
  if (aspect <= 1) return (_even(shortSide), _even(shortSide / aspect));
  return (_even(shortSide * aspect), _even(shortSide));
}

_Boundary _boundaryAfter(List<ExportClip> clips, int i) {
  if (i >= clips.length - 1) return const _Boundary('cut', 0);
  final a = clips[i].durationMs;
  final b = clips[i + 1].durationMs;
  final transition = clips[i].transitionOut;
  final xfade = xfadeNameFor(transition);
  if (xfade != null) {
    final t = [maxDissolveMs, a ~/ 2, b ~/ 2].reduce((x, y) => x < y ? x : y);
    return t >= 100 ? _Boundary('dissolve', t, xfade) : const _Boundary('cut', 0);
  }
  if (transition == 'fade') {
    final t = [fadeDipMs, a ~/ 2, b ~/ 2].reduce((x, y) => x < y ? x : y);
    return t >= 50 ? _Boundary('fade', t) : const _Boundary('cut', 0);
  }
  return const _Boundary('cut', 0);
}

/// Total rendered length for [clips] — used for progress and size estimates
/// without building the whole graph.
int exportDurationMs(List<ExportClip> clips) {
  if (clips.isEmpty) return 0;
  var total = clips.first.durationMs;
  for (var i = 1; i < clips.length; i++) {
    final b = _boundaryAfter(clips, i - 1);
    total += clips[i].durationMs - (b.kind == 'dissolve' ? b.ms : 0);
  }
  return total;
}

/// Encoder arguments for [encoder] at [bitrate] bits/s and [fps].
///
/// Every encoder gets an explicit keyframe interval of 2 s (`-g`): left to
/// defaults, FFmpeg's 12-frame GOP spends bits on frequent keyframes.
List<String> encoderArgs(VideoEncoder encoder, int bitrate, {int fps = defaultExportFps}) {
  final gop = ['-g', '${fps * 2}'];
  switch (encoder) {
    case VideoEncoder.androidHardwareHigh:
      return [
        '-c:v', 'h264_mediacodec', '-b:v', '$bitrate',
        '-profile:v', 'high', '-bitrate_mode', 'vbr', ...gop,
      ];
    case VideoEncoder.androidHardware:
      return ['-c:v', 'h264_mediacodec', '-b:v', '$bitrate', ...gop];
    case VideoEncoder.iosHardware:
      return ['-c:v', 'h264_videotoolbox', '-b:v', '$bitrate', '-profile:v', 'high', ...gop];
    case VideoEncoder.software:
      // mpeg4 looks blocky on defaults: allow it to spend more bits on
      // detailed frames (qmax 6) and use the better macroblock decision.
      return [
        '-c:v', 'mpeg4', '-b:v', '$bitrate', '-maxrate', '${bitrate * 2}', '-bufsize', '${bitrate * 2}',
        '-qmin', '2', '-qmax', '6', '-mbd', 'rd', ...gop,
      ];
  }
}

/// Lanczos keeps more detail than FFmpeg's default bicubic when resizing.
const String scaleFlags = 'flags=lanczos';

/// Optional per-clip clean-up ("Enhance" in the export screen): a light
/// temporal denoise, then contrast-adaptive sharpening. Both filters were
/// found in the phone's FFmpegKit build (2026-11-11).
/// v11 "Enhance speech": rumble cut, hiss cut, FFT denoise, a little less
/// mud, a little more presence, gentle compression. Named options only
/// (FACTS B-06); all six filters are in the phone build (MASTER_PLAN §8)
/// and this exact chain ran through FFmpeg 7.1 on desktop (2026-11-11).
/// ⚠️ Not yet heard on the phone. Signal processing, not a neural model.
const List<String> speechEnhanceFilters = [
  'highpass=f=80',
  'lowpass=f=12000',
  'afftdn=nr=12:nf=-40',
  'equalizer=f=250:t=q:w=1:g=-2',
  'equalizer=f=3500:t=q:w=1.2:g=3',
  'acompressor=threshold=0.1:ratio=3:attack=15:release=200:makeup=1.6',
];

const List<String> enhanceFilters = ['atadenoise=0a=0.02:0b=0.04:1a=0.02:1b=0.04:2a=0.02:2b=0.04', 'cas=strength=0.45'];

/// Builds the full FFmpeg argument list.
///
/// [fps] is the output frame rate (see [exportFpsOptions]); it drives the
/// per-clip `fps=` filter, the photo `-framerate`, and the output `-r`.
///
/// [fontPaths] maps `TextOverlays.fontFamily` preset names to a font file (it
/// must contain 'Default'); [textFilePaths] maps overlay id to a UTF-8 text
/// file holding that overlay's content — a file avoids every drawtext
/// escaping hazard (`:`, `'`, `%`, newlines).
ExportCommand buildExportCommand({
  required List<ExportClip> clips,
  required List<ExportOverlay> overlays,
  ExportMusic? music,
  required double aspectRatio,
  required ExportQuality quality,
  int fps = defaultExportFps,
  required VideoEncoder encoder,
  required String outputPath,
  required Map<String, String> fontPaths,
  required Map<String, String> textFilePaths,
  bool duckMusic = false,
  bool enhance = false,
  List<ExportVoiceOver> voiceOvers = const [],
}) {
  if (clips.isEmpty) {
    throw ArgumentError('buildExportCommand needs at least one clip');
  }
  if (fps < 1 || fps > 120) {
    throw ArgumentError.value(fps, 'fps', 'must be between 1 and 120');
  }
  final (w, h) = exportDimensions(aspectRatio, quality.shortSide);
  final n = clips.length;
  final durs = [for (final c in clips) c.durationMs];
  final bounds = [for (var i = 0; i < n; i++) _boundaryAfter(clips, i)];

  final inputs = <String>[];
  for (var i = 0; i < n; i++) {
    final c = clips[i];
    if (c.isPhoto) {
      inputs.addAll(['-loop', '1', '-framerate', '$fps', '-t', _sec(durs[i]), '-i', c.path]);
    } else {
      inputs.addAll(['-i', c.path]);
    }
  }
  if (music != null) inputs.addAll(['-i', music.path]);
  // Voice-overs come after the music input: index n (+1 with music) + j.
  final voBase = n + (music == null ? 0 : 1);
  for (final vo in voiceOvers) {
    inputs.addAll(['-i', vo.path]);
  }
  // v12: photo backgrounds for keyed clips, one looped still per clip.
  final keyBgInput = <int, int>{};
  var nextInput = voBase + voiceOvers.length;
  for (var i = 0; i < n; i++) {
    final k = clips[i].chromaKey;
    if (k != null && k.usesImage) {
      inputs.addAll(['-loop', '1', '-framerate', '$fps', '-t', _sec(durs[i]), '-i', k.bgImage!]);
      keyBgInput[i] = nextInput++;
    }
  }

  final f = <String>[];

  // ---- per-clip normalised video + audio ----
  for (var i = 0; i < n; i++) {
    final c = clips[i];
    final d = durs[i];
    final inB = i > 0 ? bounds[i - 1] : const _Boundary('cut', 0);
    final outB = bounds[i];

    final v = <String>[];
    if (!c.isPhoto) {
      // F11: a non-1.0 speed scales the trimmed segment's own PTS right
      // after resetting it to zero — same `trim` step, just a scaled
      // `setpts` instead of a plain reset. `ExportClip.durationMs` (used
      // for `d`/`durs[]`/boundaries below) already reflects this scaling.
      final ptsExpr = c.speed == 1.0
          ? 'setpts=PTS-STARTPTS'
          : 'setpts=(PTS-STARTPTS)/${c.speed.toStringAsFixed(3)}';
      v.add('trim=start=${_sec(c.trimStartMs)}:end=${_sec(c.trimEndMs)},$ptsExpr');
    }
    // F10: flip/rotate before scale/pad, so the aspect-ratio-aware scale
    // below sees the frame in its final (already-reoriented) shape.
    v.addAll(rotateFlipFilters(flipH: c.flipH, flipV: c.flipV, turns: c.turns));
    v.add('fps=$fps');
    if (!c.isPhoto) {
      // Exactly `d` long. `trim` keeps the last frame's original duration,
      // so on variable-frame-rate phone video (low light: 82 frames in
      // 4.35 s) a long final frame made `fps` run past the trim point and
      // pushed every later cut off — and a stream that ends early is padded
      // with its last frame (Galaxy A36 camera files, 2026-11-18).
      v.addAll(['tpad=stop_mode=clone:stop_duration=${_sec(d)}', 'trim=end=${_sec(d)}']);
    }
    // F15: how the clip fills the output frame. `blur` needs two branches
    // (blurred cover + fitted foreground), so it closes the current chain
    // into labelled pads and the rest of this clip's filters continue from
    // the `overlay` that joins them.
    var vHead = '[$i:v]';
    switch (normalizeFitMode(c.fitMode)) {
      case fitModeFill:
        v.addAll(['scale=$w:$h:force_original_aspect_ratio=increase:$scaleFlags', 'crop=$w:$h', 'setsar=1']);
        break;
      case fitModeBlur:
        v.add('split[bg$i][fg$i]');
        f.add('$vHead${v.join(',')}');
        // Background blur: `boxblur` is GPL and missing from the phone's
        // FFmpegKit build, so blur a quarter-size copy with `gblur` and
        // scale it back up — also much cheaper than blurring at full size.
        final (bw, bh) = (_even(w / 4), _even(h / 4));
        f.add('[bg$i]scale=$bw:$bh:force_original_aspect_ratio=increase,crop=$bw:$bh,'
            'gblur=sigma=6,scale=$w:$h[bb$i]');
        f.add('[fg$i]scale=$w:$h:force_original_aspect_ratio=decrease:$scaleFlags[ff$i]');
        vHead = '[bb$i][ff$i]';
        v
          ..clear()
          ..addAll(['overlay=(W-w)/2:(H-h)/2', 'setsar=1']);
        break;
      default:
        v.addAll([
          'scale=$w:$h:force_original_aspect_ratio=decrease:$scaleFlags',
          'pad=$w:$h:(ow-iw)/2:(oh-ih)/2:color=black',
          'setsar=1',
        ]);
    }
    // v12 background removal: key the framed clip, then lay it over the new
    // background. Before colour/look, so the grade covers the whole picture
    // (same order as the preview's `ChromaKeyed` inside `LookFiltered`).
    final key = c.chromaKey;
    if (key != null) {
      v.addAll(chromaKeyFilters(key));
      f.add('$vHead${v.join(',')}[ky$i]');
      final bgIdx = keyBgInput[i];
      if (bgIdx != null) {
        f.add('[$bgIdx:v]scale=$w:$h:force_original_aspect_ratio=increase:$scaleFlags,crop=$w:$h,setsar=1,fps=$fps[kb$i]');
      } else {
        f.add('color=c=${ffmpegHexColor(key.bgColor)}:s=${w}x$h:r=$fps:d=${_sec(d)},setsar=1[kb$i]');
      }
      vHead = '[kb$i][ky$i]';
      v
        ..clear()
        // `fps`: keep a declared constant frame rate, which xfade requires.
        ..addAll(['overlay=0:0:shortest=1:format=auto', 'setsar=1', 'fps=$fps']);
    }
    v.addAll(colorAdjustFilters(
      brightness: c.brightness,
      contrast: c.contrast,
      saturation: c.saturation,
    ));
    // F7: the look layers on top of brightness/contrast/saturation,
    // same order the preview composes them in (see `_FilterPreview`'s
    // doc comment in `video_preview_player.dart`).
    final effect = effectById(c.effect);
    final style = effectStyle(c.effect, c.effectStrength);
    final steps = [
      ...lookFilters(c.look, strength: c.lookStrength, outputWidth: w),
      // v11 stylise effect: a second look-style pass after the look.
      if (style != null) ...scaledLookFilters(style, outputWidth: w),
    ];
    for (final step in steps) {
      if (!step.startsWith(edgeStepPrefix)) {
        v.add(step);
        continue;
      }
      // Ink outlines: split, trace edges on one copy, multiply it back over
      // the other (luma only; chroma comes from the original).
      v.addAll(['format=yuv420p', 'split[ea$i][eb$i]']);
      f.add('$vHead${v.join(',')}');
      f.add('[eb$i]$edgeBranchFilters[ec$i]');
      vHead = '[ea$i][ec$i]';
      v
        ..clear()
        ..add('blend=c0_mode=multiply:c0_opacity=${step.substring(edgeStepPrefix.length)}'
            ':c1_mode=normal:c2_mode=normal');
    }
    // Glow (bloom): highlights of one copy are blurred and screen-blended
    // over the other, in RGB so the screen maths matches the preview.
    final glow = glowAt(c.effect, c.effectStrength);
    if (glow != null) {
      v.addAll(['format=gbrp', 'split[ga$i][gb$i]']);
      f.add('$vHead${v.join(',')}');
      f.add('[gb$i]${glowBranchFilters(glow, w)}[gc$i]');
      vHead = '[ga$i][gc$i]';
      v
        ..clear()
        ..add('blend=all_mode=screen:all_opacity=${glow.opacity.toStringAsFixed(3)}');
    }
    // v11 motion effect (zoom / pan / pulse / shake / flash) on the finished
    // frame, same formula as the preview (`motionAt`).
    final motion = effect?.motion;
    if (motion != null) {
      v.addAll(motionFilters(motion, d / 1000, c.effectStrength, w, h, scaleFlags: scaleFlags));
    }
    if (enhance) v.addAll(enhanceFilters);
    v.add('format=yuv420p');
    if (inB.kind == 'fade') v.add('fade=t=in:st=0:d=${_sec(inB.ms)}');
    if (outB.kind == 'fade') v.add('fade=t=out:st=${_sec(d - outB.ms)}:d=${_sec(outB.ms)}');
    v.add('settb=AVTB');
    f.add('$vHead${v.join(',')}[v$i]');

    final List<String> a;
    String src = '';
    if (c.hasAudio && !c.isPhoto) {
      final vol = c.muted ? 0.0 : c.volume;
      a = [
        'atrim=start=${_sec(c.trimStartMs)}:end=${_sec(c.trimEndMs)}',
        'asetpts=PTS-STARTPTS',
        ...atempoChain(c.speed),
        'aresample=$audioRate',
        'aformat=sample_fmts=fltp:channel_layouts=stereo',
        'volume=${vol.toStringAsFixed(3)}',
        if (c.enhanceSpeech) ...speechEnhanceFilters,
        // Exactly as long as this clip's video: phone recordings often
        // have an audio track a little shorter than the picture, and the
        // shortfall used to add up across clips, so sound drifted ahead
        // and ended early (Galaxy A36 camera files, 2026-11-18).
        'apad',
        'atrim=0:${_sec(d)}',
        'asetpts=PTS-STARTPTS',
      ];
      src = '[$i:a]';
    } else {
      a = [
        'anullsrc=r=$audioRate:cl=stereo',
        'aformat=sample_fmts=fltp:channel_layouts=stereo',
        'atrim=0:${_sec(d)}',
        'asetpts=PTS-STARTPTS',
      ];
    }
    if (inB.kind == 'fade') a.add('afade=t=in:st=0:d=${_sec(inB.ms)}');
    if (outB.kind == 'fade') a.add('afade=t=out:st=${_sec(d - outB.ms)}:d=${_sec(outB.ms)}');
    f.add('$src${a.join(',')}[a$i]');
  }

  // ---- join clips pairwise ----
  var cv = 'v0';
  var ca = 'a0';
  var total = durs[0];
  var origEnd = durs[0];
  final overlaps = <(int, int)>[];
  for (var i = 1; i < n; i++) {
    final b = bounds[i - 1];
    if (b.kind == 'dissolve') {
      f.add('[$cv][v$i]xfade=transition=${b.xfade}:duration=${_sec(b.ms)}:offset=${_sec(total - b.ms)},'
          // `fps`: FFmpeg 7's setpts leaves the frame rate unset, and the
          // *next* xfade then refuses this stream (two overlapping
          // transitions in a row failed to export — found 2026-11-11).
          'setpts=PTS-STARTPTS,fps=$fps,settb=AVTB[x$i]');
      f.add('[$ca][a$i]acrossfade=d=${_sec(b.ms)}:c1=tri:c2=tri[ax$i]');
      total += durs[i] - b.ms;
      overlaps.add((origEnd, b.ms));
    } else {
      f.add('[$cv][v$i]concat=n=2:v=1:a=0,settb=AVTB[x$i]');
      f.add('[$ca][a$i]concat=n=2:v=0:a=1[ax$i]');
      total += durs[i];
    }
    origEnd += durs[i];
    cv = 'x$i';
    ca = 'ax$i';
  }
  final timeline = _Timeline(overlaps, total);

  // ---- text overlays ----
  var k = 0;
  for (final o in overlays) {
    final s = timeline.remap(o.startMs);
    final e = timeline.remap(o.endMs);
    final textFile = textFilePaths[o.id];
    if (e <= s || o.content.trim().isEmpty || textFile == null) continue;
    final fontSize = (o.fontSize * w / previewReferenceWidth).round().clamp(8, 400);
    final font = fontPaths[o.fontFamily] ?? fontPaths['Default']!;
    final out = 't$k';

    // F8: an explicit outline takes precedence over bold's own border —
    // drawtext accepts only one `borderw`, and a real outline already
    // reads bolder on its own anyway.
    var styleArgs = '';
    if (o.outlineWidth > 0) {
      final borderw =
          (o.outlineWidth * w / previewReferenceWidth).round().clamp(1, 40);
      styleArgs += 'borderw=$borderw:bordercolor=${ffmpegColor(o.outlineColorValue)}:';
    } else if (o.bold) {
      // No bold-weight font file is bundled per family (see
      // `fontPaths`), so approximate bold with a thin same-color
      // stroke — a standard drawtext trick when only one weight exists.
      final borderw = (fontSize * 0.04).round().clamp(1, 6);
      styleArgs += 'borderw=$borderw:bordercolor=${ffmpegColor(o.colorValue)}:';
    }
    if (o.boxEnabled) {
      final boxborderw = (6 * w / previewReferenceWidth).round().clamp(2, 60);
      styleArgs += 'box=1:boxcolor=${ffmpegColor(o.boxColorValue)}:boxborderw=$boxborderw:';
    }

    f.add("[$cv]drawtext=fontfile='${escapeFilterPath(font)}':textfile='${escapeFilterPath(textFile)}':"
        'expansion=none:fontsize=$fontSize:fontcolor=${ffmpegColor(o.colorValue)}:'
        '$styleArgs'
        'shadowcolor=black@0.6:shadowx=2:shadowy=2:'
        'x=${o.positionX.toStringAsFixed(4)}*w-text_w/2:y=${o.positionY.toStringAsFixed(4)}*h-text_h/2:'
        "enable='between(t,${_sec(s)},${_sec(e)})'[$out]");
    cv = out;
    k++;
  }

  // ---- voice-overs: mixed into the clip bus, so ducking reacts to them ----
  if (voiceOvers.isNotEmpty) {
    final labels = <String>[];
    for (var j = 0; j < voiceOvers.length; j++) {
      final vo = voiceOvers[j];
      f.add('[${voBase + j}:a]aresample=$audioRate,aformat=sample_fmts=fltp:channel_layouts=stereo,'
          '${vo.enhance ? '${speechEnhanceFilters.join(',')},' : ''}'
          'volume=${vo.volume.toStringAsFixed(3)},'
          'adelay=${timeline.remap(vo.startMs)}:all=1[vo$j]');
      labels.add('[vo$j]');
    }
    f.add('[$ca]${labels.join()}amix=inputs=${voiceOvers.length + 1}:duration=first:dropout_transition=0:normalize=0[avo]');
    ca = 'avo';
  }

  // ---- background music ----
  var ao = ca;
  if (music != null) {
    // F9: fades are measured from the music's own trimmed window (0 to
    // its trimmed length), so they're computed here — after `asetpts`
    // resets that window's own PTS to zero, before `adelay` shifts the
    // whole thing out to its timeline offset.
    final musicDurMs = music.trimEndMs - music.trimStartMs;
    final fades = <String>[
      if (music.fadeInMs > 0) 'afade=t=in:st=0:d=${_sec(music.fadeInMs)}',
      if (music.fadeOutMs > 0)
        'afade=t=out:st=${_sec((musicDurMs - music.fadeOutMs).clamp(0, musicDurMs))}:'
            'd=${_sec(music.fadeOutMs)}',
    ];
    f.add('[$n:a]atrim=start=${_sec(music.trimStartMs)}:end=${_sec(music.trimEndMs)},'
        'asetpts=PTS-STARTPTS,aresample=$audioRate,aformat=sample_fmts=fltp:channel_layouts=stereo,'
        'volume=${music.volume.toStringAsFixed(3)}'
        '${fades.isEmpty ? '' : ',${fades.join(',')}'},'
        'adelay=${timeline.remap(music.offsetMs)}:all=1[mus]');
    var clipBus = ca;
    var musicBus = 'mus';
    if (duckMusic) {
      // F19: the clip audio is split — one copy goes to the mix, the other
      // drives a compressor on the music, so music dips while clips talk.
      f.add('[$ca]asplit=2[dsc][dmix]');
      f.add('[mus][dsc]sidechaincompress=threshold=0.05:ratio=8[duck]');
      clipBus = 'dmix';
      musicBus = 'duck';
    }
    f.add('[$clipBus][$musicBus]amix=inputs=2:duration=first:dropout_transition=0:normalize=0,alimiter=limit=0.97[aout]');
    ao = 'aout';
  }

  final args = <String>[
    '-y',
    ...inputs,
    '-filter_complex', f.join(';'),
    '-map', '[$cv]',
    '-map', '[$ao]',
    ...encoderArgs(encoder, exportVideoBitrate(quality, fps), fps: fps),
    '-pix_fmt', 'yuv420p',
    '-r', '$fps',
    '-c:a', 'aac',
    '-b:a', '192k',
    '-ar', '$audioRate',
    '-movflags', '+faststart',
    outputPath,
  ];
  return ExportCommand(args, total, w, h);
}
