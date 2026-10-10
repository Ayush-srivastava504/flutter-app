import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/export/export_command_builder.dart';
import 'package:video_editor_app/export/export_models.dart';

ExportClip clip(String path, int start, int end,
        {String t = 'cut', bool photo = false, bool audio = true, double b = 0, double c = 0, double s = 0, bool muted = false}) =>
    ExportClip(
      path: path, isPhoto: photo, trimStartMs: start, trimEndMs: end, transitionOut: t,
      hasAudio: audio, brightness: b, contrast: c, saturation: s, muted: muted,
    );

ExportCommand build(List<ExportClip> clips,
        {List<ExportOverlay> overlays = const [], ExportMusic? music, double aspect = 9 / 16, ExportQuality q = ExportQuality.p720}) =>
    buildExportCommand(
      clips: clips, overlays: overlays, music: music, aspectRatio: aspect, quality: q,
      encoder: VideoEncoder.software, outputPath: '/out/o.mp4',
      fontPaths: const {'Default': '/f/Sans.ttf'},
      textFilePaths: {for (final o in overlays) o.id: '/t/${o.id}.txt'},
    );

String graph(ExportCommand c) => c.args[c.args.indexOf('-filter_complex') + 1];

void main() {
  test('dimensions follow aspect ratio and are even', () {
    expect(exportDimensions(9 / 16, 720), (720, 1280));
    expect(exportDimensions(9 / 16, 1080), (1080, 1920));
    expect(exportDimensions(16 / 9, 720), (1280, 720));
    expect(exportDimensions(1, 1080), (1080, 1080));
  });

  test('cut transitions concatenate and keep total length', () {
    final cmd = build([clip('a.mp4', 1000, 4000), clip('b.mp4', 0, 2000)]);
    expect(cmd.totalDurationMs, 5000);
    expect(graph(cmd), contains('concat=n=2:v=1:a=0'));
    expect(graph(cmd), isNot(contains('xfade')));
  });

  test('dissolve overlaps (xfade + acrossfade) and shortens the output', () {
    final cmd = build([clip('a.mp4', 0, 3000, t: 'dissolve'), clip('b.mp4', 0, 3000)]);
    expect(cmd.totalDurationMs, 5400);
    expect(graph(cmd), contains('xfade=transition=fade:duration=0.600:offset=2.400'));
    expect(graph(cmd), contains('acrossfade=d=0.600'));
  });

  test('dissolve shrinks to half of a very short clip, or becomes a cut', () {
    expect(exportDurationMs([clip('a', 0, 400, t: 'dissolve'), clip('b', 0, 3000)]), 400 + 3000 - 200);
    expect(exportDurationMs([clip('a', 0, 150, t: 'dissolve'), clip('b', 0, 3000)]), 3150);
  });

  test('fade dips through black without changing length', () {
    final cmd = build([clip('a.mp4', 0, 3000, t: 'fade'), clip('b.mp4', 0, 3000)]);
    expect(cmd.totalDurationMs, 6000);
    expect(graph(cmd), contains('fade=t=out:st=2.700:d=0.300'));
    expect(graph(cmd), contains('fade=t=in:st=0:d=0.300'));
  });

  test('filters map to eq only when non-neutral', () {
    final neutral = graph(build([clip('a.mp4', 0, 1000)]));
    expect(neutral, isNot(contains('eq=')));
    final f = graph(build([clip('a.mp4', 0, 1000, b: 0.1, c: 0.2, s: -0.3)]));
    expect(f, contains('eq=brightness=0.100:contrast=1.200:saturation=0.700'));
  });

  test('photos loop for their duration and have no trim; clips without audio get silence', () {
    final cmd = build([clip('p.jpg', 0, 3000, photo: true), clip('v.mp4', 0, 2000, audio: false)]);
    expect(cmd.args.join(' '), contains('-loop 1 -framerate 30 -t 3.000 -i p.jpg'));
    expect(graph(cmd), isNot(contains('[0:v]trim')));
    expect(graph(cmd), contains('anullsrc'));
    expect(graph(cmd), isNot(contains('[1:a]')));
  });

  test('muted clips are silenced, not removed', () {
    expect(graph(build([clip('a.mp4', 0, 1000, muted: true)])), contains('volume=0.000'));
  });

  test('text after a dissolve is shifted earlier by the overlap', () {
    final o = ExportOverlay(id: 'x', content: 'Hi', startMs: 4000, endMs: 5000);
    final cmd = build([clip('a.mp4', 0, 3000, t: 'dissolve'), clip('b.mp4', 0, 3000)], overlays: [o]);
    expect(graph(cmd), contains("enable='between(t,3.400,4.400)'"));
  });

  test('text before the dissolve is not shifted; font size scales with width', () {
    final o = ExportOverlay(id: 'x', content: 'Hi', fontSize: 24, startMs: 500, endMs: 1500);
    final g = graph(build([clip('a.mp4', 0, 3000, t: 'dissolve'), clip('b.mp4', 0, 3000)], overlays: [o]));
    expect(g, contains("enable='between(t,0.500,1.500)'"));
    expect(g, contains('fontsize=48')); // 24 * 720 / 360
    expect(g, contains('x=0.5000*w-text_w/2'));
  });

  test('blank overlays and overlays without a text file are skipped', () {
    final blank = ExportOverlay(id: 'b', content: '   ', startMs: 0, endMs: 1000);
    expect(graph(build([clip('a.mp4', 0, 3000)], overlays: [blank])), isNot(contains('drawtext')));
  });

  test('colour is split into rgb + alpha', () {
    final o = ExportOverlay(id: 'x', content: 'Hi', colorValue: 0x80FF8000, startMs: 0, endMs: 1000);
    expect(graph(build([clip('a.mp4', 0, 3000)], overlays: [o])), contains('fontcolor=0xFF8000@0.50'));
  });

  test('music is mixed, delayed by the (remapped) offset', () {
    const m = ExportMusic(path: 'm.mp3', trimStartMs: 0, trimEndMs: 9000, offsetMs: 4000, volume: 0.5);
    final cmd = build([clip('a.mp4', 0, 3000, t: 'dissolve'), clip('b.mp4', 0, 3000)], music: m);
    expect(graph(cmd), contains('[2:a]atrim'));
    expect(graph(cmd), contains('adelay=3400:all=1'));
    expect(graph(cmd), contains('amix=inputs=2:duration=first'));
    expect(cmd.args, contains('-i'));
  });

  test('paths with special characters are escaped inside filters', () {
    expect(escapeFilterPath(r"C:\a b\it's:x"), r"C\:\\a b\\it\'s\:x");
  });

  test('encoder args per encoder and the output ends the argument list', () {
    expect(encoderArgs(VideoEncoder.androidHardware, 5000000).take(2), ['-c:v', 'h264_mediacodec']);
    expect(encoderArgs(VideoEncoder.iosHardware, 5000000).take(2), ['-c:v', 'h264_videotoolbox']);
    final cmd = build([clip('a.mp4', 0, 1000)]);
    expect(cmd.args.last, '/out/o.mp4');
    expect(cmd.args, containsAllInOrder(['-c:a', 'aac']));
  });

  test('refuses an empty timeline', () {
    expect(() => build([]), throwsArgumentError);
  });
}
