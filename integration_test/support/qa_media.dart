// On-device QA helpers: make test media with the app's own FFmpegKit build,
// and inspect exported files with FFprobe/FFmpeg on the phone.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:path/path.dart' as p;

void qaLog(String s) {
  // ignore: avoid_print
  print('QA> $s');
}

Future<(bool, String)> ffmpeg(List<String> args) async {
  final s = await FFmpegKit.executeWithArguments(['-hide_banner', '-y', ...args]);
  final rc = await s.getReturnCode();
  final log = await s.getAllLogsAsString() ?? '';
  return (ReturnCode.isSuccess(rc), log);
}

/// Synthetic clips covering the media edge cases (rotation, 60 fps, VFR,
/// no audio, shorter than a beat, 4K, long, HEVC). Returns name → path for
/// the ones this phone's FFmpeg could make, and logs the ones it couldn't.
Future<Map<String, String>> makeSyntheticMedia(Directory dir) async {
  await dir.create(recursive: true);
  final out = <String, String>{};
  Future<void> make(String name, List<String> args) async {
    final path = p.join(dir.path, name);
    if (await File(path).exists() && await File(path).length() > 0) {
      out[name] = path;
      return;
    }
    final (ok, log) = await ffmpeg([...args, path]);
    if (ok && await File(path).exists()) {
      out[name] = path;
    } else {
      qaLog('could not make $name: ${log.split('\n').where((l) => l.trim().isNotEmpty).toList().reversed.take(4).join(' | ')}');
      if (await File(path).exists()) await File(path).delete();
    }
  }

  List<String> src(String size, num fps, num secs, {bool audio = true}) => [
        '-f', 'lavfi', '-i', 'testsrc2=s=$size:r=$fps:d=$secs',
        if (audio) ...['-f', 'lavfi', '-i', 'sine=frequency=440:duration=$secs'],
      ];
  const mp4v = ['-c:v', 'mpeg4', '-q:v', '4', '-pix_fmt', 'yuv420p'];
  const aac = ['-c:a', 'aac', '-b:a', '128k'];

  await make('syn_land_1080p30.mp4', [...src('1920x1080', 30, 6), ...mp4v, ...aac, '-shortest']);
  await make('syn_port_1080p30.mp4', [...src('1080x1920', 30, 6), ...mp4v, ...aac, '-shortest']);
  await make('syn_60fps.mp4', [...src('1280x720', 60, 5), ...mp4v, ...aac, '-shortest']);
  await make('syn_noaudio.mp4', [...src('1280x720', 30, 5, audio: false), ...mp4v]);
  await make('syn_short_0.4s.mp4', [...src('1280x720', 30, 0.4), ...mp4v, ...aac, '-shortest']);
  // Variable frame rate: frame gaps alternate 16 ms / 50 ms (≈30 fps average).
  await make('syn_vfr.mp4', [
    ...src('1280x720', 30, 5),
    '-vf', "settb=1/1000,setpts='floor(N/2)*66+mod(N,2)*16'",
    '-fps_mode', 'passthrough', '-enc_time_base:v', '1:1000', '-video_track_timescale', '1000',
    ...mp4v, ...aac, '-shortest',
  ]);
  await make('syn_4k.mp4', [...src('3840x2160', 30, 3), ...mp4v, ...aac, '-shortest']);
  await make('syn_long_120s.mp4', [...src('640x360', 30, 120), ...mp4v, ...aac, '-shortest']);
  await make('syn_hevc.mp4', [...src('1920x1080', 30, 4), '-c:v', 'hevc_mediacodec', '-b:v', '6000000', ...aac, '-shortest']);
  // Landscape pixels with a 90° display rotation, like a phone held upright.
  if (out.containsKey('syn_land_1080p30.mp4')) {
    await make('syn_rot90.mp4', [
      '-display_rotation:v:0', '90', '-i', out['syn_land_1080p30.mp4']!, '-c', 'copy',
    ]);
  }
  // Photos.
  await make('syn_photo_12mp.jpg', ['-f', 'lavfi', '-i', 'testsrc2=s=4032x3024', '-frames:v', '1', '-q:v', '3']);
  await make('syn_photo_port.png', ['-f', 'lavfi', '-i', 'testsrc2=s=1080x1920', '-frames:v', '1']);
  await make('syn_photo.webp', ['-f', 'lavfi', '-i', 'testsrc2=s=1200x1200', '-frames:v', '1']);
  // Not a video at all.
  final bad = File(p.join(dir.path, 'syn_corrupt.mp4'));
  if (!await bad.exists()) {
    final r = Random(7);
    await bad.writeAsBytes(List.generate(200000, (_) => r.nextInt(256)));
  }
  out['syn_corrupt.mp4'] = bad.path;
  return out;
}

class Probe {
  final int width;
  final int height;
  final double fps;
  final double durationS;
  final double videoDurationS;
  final double? audioDurationS;
  final int frames;
  final String videoCodec;
  final String? audioCodec;
  final int rotation;
  Probe({
    required this.width,
    required this.height,
    required this.fps,
    required this.durationS,
    required this.videoDurationS,
    required this.audioDurationS,
    required this.frames,
    required this.videoCodec,
    required this.audioCodec,
    required this.rotation,
  });

  bool get hasAudio => audioCodec != null;
  @override
  String toString() => '${width}x$height ${fps.toStringAsFixed(2)}fps ${durationS.toStringAsFixed(2)}s '
      'frames=$frames v=$videoCodec a=${audioCodec ?? '-'}'
      '${audioDurationS == null ? '' : ' aDur=${audioDurationS!.toStringAsFixed(2)}'}'
      '${rotation == 0 ? '' : ' rot=$rotation'}';
}

double _rate(String? r) {
  if (r == null || !r.contains('/')) return double.tryParse(r ?? '') ?? 0;
  final [a, b] = r.split('/').map(double.parse).toList();
  return b == 0 ? 0 : a / b;
}

Future<Probe> probe(String path, {bool countFrames = true}) async {
  final s = await FFprobeKit.executeWithArguments([
    '-v', 'error', '-print_format', 'json', '-show_format', '-show_streams',
    if (countFrames) '-count_frames', path,
  ]);
  final raw = await s.getOutput() ?? '';
  final json = jsonDecode(raw.substring(raw.indexOf('{'))) as Map<String, dynamic>;
  final streams = (json['streams'] as List).cast<Map<String, dynamic>>();
  final v = streams.firstWhere((x) => x['codec_type'] == 'video');
  final a = streams.where((x) => x['codec_type'] == 'audio').firstOrNull;
  var rot = 0;
  for (final sd in (v['side_data_list'] as List? ?? const [])) {
    final r = (sd as Map)['rotation'];
    if (r != null) rot = (r as num).toInt();
  }
  rot = rot == 0 ? int.tryParse('${(v['tags'] as Map?)?['rotate'] ?? 0}') ?? 0 : rot;
  return Probe(
    width: v['width'] as int,
    height: v['height'] as int,
    fps: _rate(v['avg_frame_rate'] as String?),
    durationS: double.tryParse('${(json['format'] as Map)['duration']}') ?? 0,
    videoDurationS: double.tryParse('${v['duration']}') ?? 0,
    audioDurationS: a == null ? null : double.tryParse('${a['duration']}'),
    frames: int.tryParse('${v['nb_read_frames'] ?? v['nb_frames'] ?? 0}') ?? 0,
    videoCodec: '${v['codec_name']}',
    audioCodec: a == null ? null : '${a['codec_name']}',
    rotation: rot,
  );
}

class DecodeScan {
  /// Black stretches longer than the threshold, as (start, end) seconds.
  final List<(double, double)> black;
  final List<String> errors;
  DecodeScan(this.black, this.errors);
}

/// Decodes the whole file once: finds black stretches and decode errors.
Future<DecodeScan> scanDecode(String path) async {
  final (_, log) = await ffmpeg([
    '-v', 'info', '-i', path, '-vf', 'blackdetect=d=0.25:pic_th=0.98:pix_th=0.08', '-an', '-f', 'null', '-',
  ]);
  final black = <(double, double)>[];
  final re = RegExp(r'black_start:([\d.]+) black_end:([\d.]+)');
  for (final m in re.allMatches(log)) {
    black.add((double.parse(m.group(1)!), double.parse(m.group(2)!)));
  }
  final errors = log
      .split('\n')
      .where((l) => RegExp(r'error|corrupt|invalid|concealing', caseSensitive: false).hasMatch(l))
      .where((l) => !l.contains('blackdetect'))
      .toList();
  return DecodeScan(black, errors);
}

/// One row of 4 frames (at 12/37/62/87 % of the video) as a PNG.
Future<bool> contactSheet(String video, double durationS, String png) async {
  final step = durationS / 4;
  final (ok, _) = await ffmpeg([
    '-i', video,
    '-vf', "fps=1/${step.toStringAsFixed(3)}:start_time=${(step / 2).toStringAsFixed(3)},scale=-2:320,tile=4x1",
    '-frames:v', '1', png,
  ]);
  return ok;
}
