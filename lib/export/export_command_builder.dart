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
///    doing it twice would turn clips sideways.
library export_command_builder;

import 'export_models.dart';

const int exportFps = 30;
const int maxDissolveMs = 600;
const int fadeDipMs = 300;
const int audioRate = 44100;

/// Width, in editor logical pixels, of the preview frame the overlay font
/// sizes were authored against. Export scales text by outputWidth / this.
const double previewReferenceWidth = 360;

class _Boundary {
  final String kind; // cut | fade | dissolve
  final int ms;
  const _Boundary(this.kind, this.ms);
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

/// Output frame size for [aspect] (width / height) at [shortSide].
(int, int) exportDimensions(double aspect, int shortSide) {
  if (aspect <= 1) return (_even(shortSide), _even(shortSide / aspect));
  return (_even(shortSide * aspect), _even(shortSide));
}

_Boundary _boundaryAfter(List<ExportClip> clips, int i) {
  if (i >= clips.length - 1) return const _Boundary('cut', 0);
  final a = clips[i].durationMs;
  final b = clips[i + 1].durationMs;
  switch (clips[i].transitionOut) {
    case 'dissolve':
      final t = [maxDissolveMs, a ~/ 2, b ~/ 2].reduce((x, y) => x < y ? x : y);
      return t >= 100 ? _Boundary('dissolve', t) : const _Boundary('cut', 0);
    case 'fade':
      final t = [fadeDipMs, a ~/ 2, b ~/ 2].reduce((x, y) => x < y ? x : y);
      return t >= 50 ? _Boundary('fade', t) : const _Boundary('cut', 0);
    default:
      return const _Boundary('cut', 0);
  }
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

/// Encoder arguments for [encoder] at [bitrate] bits/s.
List<String> encoderArgs(VideoEncoder encoder, int bitrate) {
  switch (encoder) {
    case VideoEncoder.androidHardware:
      return ['-c:v', 'h264_mediacodec', '-b:v', '$bitrate'];
    case VideoEncoder.iosHardware:
      return ['-c:v', 'h264_videotoolbox', '-b:v', '$bitrate'];
    case VideoEncoder.software:
      return ['-c:v', 'mpeg4', '-b:v', '$bitrate'];
  }
}

/// Builds the full FFmpeg argument list.
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
  required VideoEncoder encoder,
  required String outputPath,
  required Map<String, String> fontPaths,
  required Map<String, String> textFilePaths,
}) {
  if (clips.isEmpty) {
    throw ArgumentError('buildExportCommand needs at least one clip');
  }
  final (w, h) = exportDimensions(aspectRatio, quality.shortSide);
  final n = clips.length;
  final durs = [for (final c in clips) c.durationMs];
  final bounds = [for (var i = 0; i < n; i++) _boundaryAfter(clips, i)];

  final inputs = <String>[];
  for (var i = 0; i < n; i++) {
    final c = clips[i];
    if (c.isPhoto) {
      inputs.addAll(['-loop', '1', '-framerate', '$exportFps', '-t', _sec(durs[i]), '-i', c.path]);
    } else {
      inputs.addAll(['-i', c.path]);
    }
  }
  if (music != null) inputs.addAll(['-i', music.path]);

  final f = <String>[];

  // ---- per-clip normalised video + audio ----
  for (var i = 0; i < n; i++) {
    final c = clips[i];
    final d = durs[i];
    final inB = i > 0 ? bounds[i - 1] : const _Boundary('cut', 0);
    final outB = bounds[i];

    final v = <String>[];
    if (!c.isPhoto) {
      v.add('trim=start=${_sec(c.trimStartMs)}:end=${_sec(c.trimEndMs)},setpts=PTS-STARTPTS');
    }
    v.addAll([
      'fps=$exportFps',
      'scale=$w:$h:force_original_aspect_ratio=decrease',
      'pad=$w:$h:(ow-iw)/2:(oh-ih)/2:color=black',
      'setsar=1',
    ]);
    if (c.brightness != 0 || c.contrast != 0 || c.saturation != 0) {
      v.add('eq=brightness=${c.brightness.toStringAsFixed(3)}'
          ':contrast=${(1 + c.contrast).toStringAsFixed(3)}'
          ':saturation=${(1 + c.saturation).toStringAsFixed(3)}');
    }
    v.add('format=yuv420p');
    if (inB.kind == 'fade') v.add('fade=t=in:st=0:d=${_sec(inB.ms)}');
    if (outB.kind == 'fade') v.add('fade=t=out:st=${_sec(d - outB.ms)}:d=${_sec(outB.ms)}');
    v.add('settb=AVTB');
    f.add('[$i:v]${v.join(',')}[v$i]');

    final List<String> a;
    String src = '';
    if (c.hasAudio && !c.isPhoto) {
      final vol = c.muted ? 0.0 : c.volume;
      a = [
        'atrim=start=${_sec(c.trimStartMs)}:end=${_sec(c.trimEndMs)}',
        'asetpts=PTS-STARTPTS',
        'aresample=$audioRate',
        'aformat=sample_fmts=fltp:channel_layouts=stereo',
        'volume=${vol.toStringAsFixed(3)}',
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
      f.add('[$cv][v$i]xfade=transition=fade:duration=${_sec(b.ms)}:offset=${_sec(total - b.ms)},'
          'settb=AVTB,setpts=PTS-STARTPTS[x$i]');
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
    final alpha = ((o.colorValue >> 24) & 0xFF) / 255;
    final rgb = (o.colorValue & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0');
    final fontSize = (o.fontSize * w / previewReferenceWidth).round().clamp(8, 400);
    final font = fontPaths[o.fontFamily] ?? fontPaths['Default']!;
    final out = 't$k';
    f.add("[$cv]drawtext=fontfile='${escapeFilterPath(font)}':textfile='${escapeFilterPath(textFile)}':"
        'expansion=none:fontsize=$fontSize:fontcolor=0x$rgb@${alpha.toStringAsFixed(2)}:'
        'shadowcolor=black@0.6:shadowx=2:shadowy=2:'
        'x=${o.positionX.toStringAsFixed(4)}*w-text_w/2:y=${o.positionY.toStringAsFixed(4)}*h-text_h/2:'
        "enable='between(t,${_sec(s)},${_sec(e)})'[$out]");
    cv = out;
    k++;
  }

  // ---- background music ----
  var ao = ca;
  if (music != null) {
    f.add('[$n:a]atrim=start=${_sec(music.trimStartMs)}:end=${_sec(music.trimEndMs)},'
        'asetpts=PTS-STARTPTS,aresample=$audioRate,aformat=sample_fmts=fltp:channel_layouts=stereo,'
        'volume=${music.volume.toStringAsFixed(3)},adelay=${timeline.remap(music.offsetMs)}:all=1[mus]');
    f.add('[$ca][mus]amix=inputs=2:duration=first:dropout_transition=0:normalize=0,alimiter=limit=0.97[aout]');
    ao = 'aout';
  }

  final args = <String>[
    '-y',
    ...inputs,
    '-filter_complex', f.join(';'),
    '-map', '[$cv]',
    '-map', '[$ao]',
    ...encoderArgs(encoder, quality.videoBitrate),
    '-pix_fmt', 'yuv420p',
    '-r', '$exportFps',
    '-c:a', 'aac',
    '-b:a', '192k',
    '-ar', '$audioRate',
    '-movflags', '+faststart',
    outputPath,
  ];
  return ExportCommand(args, total, w, h);
}
