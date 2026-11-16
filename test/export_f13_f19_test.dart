import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/export/export_command_builder.dart';
import 'package:video_editor_app/export/export_models.dart';

/// Export graph for F11 (wider speed range), F13 (more transitions),
/// F15 (fit/fill/blur) and F19 (music ducking).
ExportCommand build(List<ExportClip> clips, {ExportMusic? music, bool duck = false}) => buildExportCommand(
      clips: clips,
      overlays: const [],
      music: music,
      aspectRatio: 9 / 16,
      quality: ExportQuality.p720,
      fps: defaultExportFps,
      encoder: VideoEncoder.software,
      outputPath: '/out/o.mp4',
      fontPaths: const {'Default': '/f/Sans.ttf'},
      textFilePaths: const {},
      duckMusic: duck,
    );

String graph(ExportCommand c) => c.args[c.args.indexOf('-filter_complex') + 1];

ExportClip video(String path, {String transition = 'cut', String fit = 'fit', double speed = 1.0}) => ExportClip(
      path: path,
      isPhoto: false,
      trimStartMs: 0,
      trimEndMs: 4000,
      hasAudio: true,
      transitionOut: transition,
      fitMode: fit,
      speed: speed,
    );

void main() {
  group('F11 atempoChain', () {
    test('1.0 needs nothing; 0.5–2.0 is one filter', () {
      expect(atempoChain(1.0), isEmpty);
      expect(atempoChain(1.5), ['atempo=1.500']);
      expect(atempoChain(0.5), ['atempo=0.500']);
    });
    test('outside 0.5–2.0 chains filters whose product is the speed', () {
      expect(atempoChain(4.0), ['atempo=2.000', 'atempo=2.000']);
      expect(atempoChain(3.0), ['atempo=2.000', 'atempo=1.500']);
      expect(atempoChain(0.25), ['atempo=0.500', 'atempo=0.500']);
    });
    test('every filter in a chain is inside atempo\'s own range', () {
      for (final s in [0.25, 0.3, 0.75, 2.5, 3.0, 4.0]) {
        var product = 1.0;
        for (final f in atempoChain(s)) {
          final v = double.parse(f.split('=').last);
          expect(v, inInclusiveRange(0.5, 2.0), reason: '$s -> $f');
          product *= v;
        }
        expect(product, closeTo(s, 0.002), reason: '$s');
      }
    });
    test('a 4x clip gets the chain in its audio', () {
      expect(graph(build([video('/a.mp4', speed: 4)])), contains('atempo=2.000,atempo=2.000'));
    });
  });

  group('F13 transitions', () {
    test('each overlap transition maps to its xfade name and shortens like a dissolve', () {
      for (final (id, xfade) in [
        ('dissolve', 'fade'),
        ('slideleft', 'slideleft'),
        ('wipeleft', 'wipeleft'),
        ('circleopen', 'circleopen'),
        ('zoomin', 'zoomin'),
      ]) {
        final cmd = build([video('/a.mp4', transition: id), video('/b.mp4')]);
        expect(graph(cmd), contains('xfade=transition=$xfade:'), reason: id);
        expect(cmd.totalDurationMs, 8000 - maxDissolveMs, reason: id);
      }
    });
    test('an unknown transition name exports as a cut, never fails', () {
      final cmd = build([video('/a.mp4', transition: 'spin3d'), video('/b.mp4')]);
      expect(graph(cmd), isNot(contains('xfade')));
      expect(cmd.totalDurationMs, 8000);
    });
  });

  group('F15 fit modes', () {
    test('fit letterboxes (the old behaviour)', () {
      final g = graph(build([video('/a.mp4')]));
      expect(g, contains('force_original_aspect_ratio=decrease:flags=lanczos,pad='));
    });
    test('fill scales up and crops, no padding', () {
      final g = graph(build([video('/a.mp4', fit: 'fill')]));
      expect(g, contains('force_original_aspect_ratio=increase:flags=lanczos,crop='));
      expect(g, isNot(contains('pad=')));
    });
    test('blur splits into a blurred cover and a fitted foreground, then overlays', () {
      final g = graph(build([video('/a.mp4', fit: 'blur')]));
      expect(g, contains('split[bg0][fg0]'));
      expect(g, contains('[bg0]scale='));
      expect(g, contains('gblur=sigma=6,scale=720:1280[bb0]'), reason: 'blur a quarter-size copy, scale back up');
      expect(g, isNot(contains('boxblur')), reason: 'GPL, missing on the phone');
      expect(g, contains('[bb0][ff0]overlay=(W-w)/2:(H-h)/2'));
      expect(g, contains('[v0]'), reason: 'chain still ends at the clip label');
    });
    test('an unknown fit mode behaves as fit', () {
      expect(graph(build([video('/a.mp4', fit: 'stretch')])), contains('pad='));
    });
  });

  group('F19 ducking', () {
    const music = ExportMusic(path: '/m.mp3', trimStartMs: 0, trimEndMs: 8000);
    test('off: plain amix of clip audio and music', () {
      final g = graph(build([video('/a.mp4')], music: music));
      expect(g, isNot(contains('sidechaincompress')));
      expect(g, contains('[mus]amix=inputs=2'));
    });
    test('on: clip audio drives a compressor on the music before the mix', () {
      final g = graph(build([video('/a.mp4')], music: music, duck: true));
      expect(g, contains('asplit=2[dsc][dmix]'));
      expect(g, contains('[mus][dsc]sidechaincompress=threshold=0.05:ratio=8[duck]'));
      expect(g, contains('[dmix][duck]amix=inputs=2'));
    });
    test('on but no music: nothing changes', () {
      expect(graph(build([video('/a.mp4')], duck: true)), isNot(contains('sidechaincompress')));
    });
  });
}
