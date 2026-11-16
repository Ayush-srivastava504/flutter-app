import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/export/export_command_builder.dart';
import 'package:video_editor_app/export/export_models.dart';
import 'package:video_editor_app/models/color_filter_x.dart' show buildColorMatrix;

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

/// Reads a colorchannelmixer filter the way FFmpeg does: named options by
/// name, positional ones in FFmpeg's own option order (which has an alpha
/// slot after each channel). Unset coefficients keep FFmpeg's defaults.
Map<String, double> parseColorChannelMixer(String filter) {
  const order = ['rr', 'rg', 'rb', 'ra', 'gr', 'gg', 'gb', 'ga', 'br', 'bg', 'bb', 'ba'];
  final out = <String, double>{'rr': 1, 'gg': 1, 'bb': 1};
  final args = filter.substring('colorchannelmixer='.length).split(':');
  for (var i = 0; i < args.length; i++) {
    final kv = args[i].split('=');
    if (kv.length == 2) {
      out[kv[0]] = double.parse(kv[1]);
    } else {
      out[order[i]] = double.parse(kv[0]);
    }
  }
  return out;
}

void main() {
  test('colorchannelmixer: every coefficient lands in the slot it was meant for', () {
    // The bug seen on the phone: 9 positional values shifted into alpha
    // slots. Parse the generated filter exactly as FFmpeg would.
    final m = <double>[
      0.11, 0.12, 0.13, 0, 0, //
      0.21, 0.22, 0.23, 0, 0, //
      0.31, 0.32, 0.33, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
    final p = parseColorChannelMixer(ffmpegColorChannelMixerFilter(m));
    expect(p, {
      'rr': 0.11, 'rg': 0.12, 'rb': 0.13,
      'gr': 0.21, 'gg': 0.22, 'gb': 0.23,
      'br': 0.31, 'bg': 0.32, 'bb': 0.33,
    });
  });

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

  test('colour sliders add filters only when non-neutral, and never `eq` (missing on the phone)', () {
    final neutral = graph(build([clip('a.mp4', 0, 1000)]));
    expect(neutral, isNot(contains('colorchannelmixer')));
    expect(neutral, isNot(contains('lutrgb')));
    final f = graph(build([clip('a.mp4', 0, 1000, b: 0.1, c: 0.2, s: -0.3)]));
    expect(f, contains('colorchannelmixer='));
    expect(f, contains('lutrgb='));
    expect(f, isNot(contains('eq=')));
  });

  test('the export colour filters compute the same pixel as the preview matrix', () {
    // Parse the two filters back into numbers and apply them to a pixel,
    // then compare with the 4x5 matrix the preview hands to ColorFilter.
    for (final (b, c, s) in [(0.1, 0.2, -0.3), (-0.25, 0.05, 0.4), (0.0, -0.5, 0.0), (0.3, 0.0, 0.0)]) {
      final filters = colorAdjustFilters(brightness: b, contrast: c, saturation: s);
      var mix = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0];
      var offs = [0.0, 0.0, 0.0];
      for (final f in filters) {
        if (f.startsWith('colorchannelmixer=')) {
          final named = parseColorChannelMixer(f);
          mix = [for (final k in ['rr', 'rg', 'rb', 'gr', 'gg', 'gb', 'br', 'bg', 'bb']) named[k] ?? 0];
        } else if (f.startsWith('lutrgb=')) {
          offs = RegExp(r'val\+(-?[\d.]+)\*').allMatches(f).map((m) => double.parse(m[1]!)).toList();
        }
      }
      final m = buildColorMatrix(brightness: b, contrast: c, saturation: s);
      const px = [180.0, 90.0, 40.0];
      for (var ch = 0; ch < 3; ch++) {
        final viaExport = mix[ch * 3] * px[0] + mix[ch * 3 + 1] * px[1] + mix[ch * 3 + 2] * px[2] + offs[ch];
        final viaPreview = m[ch * 5] * px[0] + m[ch * 5 + 1] * px[1] + m[ch * 5 + 2] * px[2] + m[ch * 5 + 4];
        expect(viaExport, closeTo(viaPreview, 0.05), reason: '($b,$c,$s) channel $ch');
      }
    }
  });

  test('no export graph uses a filter the phone FFmpegKit build lacks', () {
    // `eq` and `boxblur` are GPL; the non-GPL build omits them (found on a
    // real phone 2026-11-11: "No such filter: 'eq'"). Exercise every
    // feature at once and make sure neither sneaks back in.
    final cmd = buildExportCommand(
      clips: [
        const ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 3000, hasAudio: true,
            brightness: 0.2, contrast: 0.1, saturation: -0.2, look: 'vignette', fitMode: 'blur', speed: 4,
            transitionOut: 'circleopen', turns: 1, flipH: true),
        const ExportClip(path: 'p.jpg', isPhoto: true, trimStartMs: 0, trimEndMs: 3000, fitMode: 'fill',
            look: 'sepia', transitionOut: 'fade'),
        const ExportClip(path: 'b.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 3000, hasAudio: true, speed: 0.25),
      ],
      overlays: const [],
      music: const ExportMusic(path: 'm.mp3', trimStartMs: 0, trimEndMs: 5000, fadeInMs: 500, fadeOutMs: 500),
      aspectRatio: 9 / 16,
      quality: ExportQuality.p1080,
      fps: 30,
      encoder: VideoEncoder.software,
      outputPath: '/o.mp4',
      fontPaths: const {'Default': '/f.ttf'},
      textFilePaths: const {},
      duckMusic: true,
    );
    final names = RegExp(r'(?:^|[,;\]])([a-z0-9_]+)(?==|,|\[|;|$)')
        .allMatches(graph(cmd))
        .map((m) => m[1]!)
        .toSet();
    expect(names.intersection({'eq', 'boxblur', 'smartblur', 'hqdn3d', 'delogo', 'perspective', 'mpdecimate'}), isEmpty);
    expect(names, containsAll(['gblur', 'colorchannelmixer', 'lutrgb', 'sidechaincompress', 'xfade']));
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
