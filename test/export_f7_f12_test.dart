import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/export/export_command_builder.dart';
import 'package:video_editor_app/export/export_models.dart';

/// Tests for the Tier-2 batch: F7 (looks), F8 (text styling v2), F9
/// (music fades), F10 (rotate/flip), F11 (speed). F12 (subtitle import)
/// is tested separately in `test/srt_parser_test.dart` — it never
/// touches the export graph.
ExportCommand build(
  List<ExportClip> clips, {
  List<ExportOverlay> overlays = const [],
  ExportMusic? music,
  Map<String, String> textFilePaths = const {},
}) =>
    buildExportCommand(
      clips: clips,
      overlays: overlays,
      music: music,
      aspectRatio: 9 / 16,
      quality: ExportQuality.p720,
      fps: defaultExportFps,
      encoder: VideoEncoder.software,
      outputPath: '/out/o.mp4',
      fontPaths: const {'Default': '/f/Sans.ttf'},
      textFilePaths: textFilePaths,
    );

String graph(ExportCommand c) => c.args[c.args.indexOf('-filter_complex') + 1];

void main() {
  group('F10 rotateFlipFilters (pure)', () {
    test('turns=0, no flip -> nothing', () {
      expect(rotateFlipFilters(flipH: false, flipV: false, turns: 0), isEmpty);
    });
    test('turns=1 -> a single 90deg clockwise transpose', () {
      expect(rotateFlipFilters(flipH: false, flipV: false, turns: 1), ['transpose=1']);
    });
    test('turns=3 -> a single 90deg counter-clockwise transpose', () {
      expect(rotateFlipFilters(flipH: false, flipV: false, turns: 3), ['transpose=2']);
    });
    test('turns=2 (180deg) folds into a flip pair, not a transpose', () {
      final f = rotateFlipFilters(flipH: false, flipV: false, turns: 2);
      expect(f, containsAll(['hflip', 'vflip']));
      expect(f, isNot(contains(startsWith('transpose'))));
    });
    test('turns=2 XORs with an explicit flip, cancelling it out on that axis', () {
      // User already asked for hflip; a 180 turn also implies hflip, so
      // the two should cancel, leaving only vflip.
      expect(rotateFlipFilters(flipH: true, flipV: false, turns: 2), ['vflip']);
    });
    test('turns is taken mod 4, so 5 behaves like 1', () {
      expect(rotateFlipFilters(flipH: false, flipV: false, turns: 5), ['transpose=1']);
    });
    test('a plain flip with no turns just emits hflip/vflip, flip before any transpose', () {
      expect(rotateFlipFilters(flipH: true, flipV: true, turns: 1),
          ['hflip', 'vflip', 'transpose=1']);
    });
  });

  group('F7 look filters (pure)', () {
    test('none/null -> no filters at all', () {
      expect(lookFilters('none'), isEmpty);
      expect(lookFilters(null), isEmpty);
    });
    test('a tinted look -> exactly one colorchannelmixer, no vignette', () {
      final f = lookFilters('sepia');
      expect(f.length, 1);
      expect(f.single, startsWith('colorchannelmixer='));
    });
    test('sepia colorchannelmixer uses the standard sepia coefficients', () {
      final f = lookFilters('sepia').single;
      expect(f, 'colorchannelmixer=rr=0.3930:rg=0.7690:rb=0.1890:gr=0.3490:gg=0.6860:gb=0.1680:br=0.2720:bg=0.5340:bb=0.1310');
    });
    test('vignette -> the vignette filter, no colorchannelmixer', () {
      expect(lookFilters('vignette'), ['vignette=angle=0.740']);
    });
  });

  group('ffmpegColor', () {
    test('opaque white', () => expect(ffmpegColor(0xFFFFFFFF), '0xFFFFFF@1.00'));
    test('opaque black', () => expect(ffmpegColor(0xFF000000), '0x000000@1.00'));
    test('60%-alpha black box default', () => expect(ffmpegColor(0x99000000), '0x000000@0.60'));
  });

  group('F11 speed, end to end through buildExportCommand', () {
    test('default speed (1.0) keeps the plain setpts reset and no atempo', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 3000, hasAudio: true),
      ]);
      expect(graph(cmd), contains('setpts=PTS-STARTPTS'));
      expect(graph(cmd), isNot(contains('atempo')));
      expect(cmd.totalDurationMs, 3000);
    });

    test('2x speed scales setpts, adds atempo=2.000, and halves the duration', () {
      final cmd = build([
        ExportClip(
            path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 4000, hasAudio: true, speed: 2.0),
      ]);
      expect(graph(cmd), contains('setpts=(PTS-STARTPTS)/2.000'));
      expect(graph(cmd), contains('atempo=2.000'));
      expect(cmd.totalDurationMs, 2000);
    });

    test('0.5x speed scales setpts, adds atempo=0.500, and doubles the duration', () {
      final cmd = build([
        ExportClip(
            path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 2000, hasAudio: true, speed: 0.5),
      ]);
      expect(graph(cmd), contains('setpts=(PTS-STARTPTS)/0.500'));
      expect(graph(cmd), contains('atempo=0.500'));
      expect(cmd.totalDurationMs, 4000);
    });

    test('a silent clip at 2x speed still pads to the correct (halved) duration', () {
      final cmd = build([
        ExportClip(
            path: 'a.mp4',
            isPhoto: false,
            trimStartMs: 0,
            trimEndMs: 4000,
            hasAudio: false,
            speed: 2.0),
      ]);
      // 4000ms raw / 2.0 speed = 2000ms effective = "2.000" seconds.
      expect(graph(cmd), contains('atrim=0:2.000'));
    });
  });

  group('F10 rotate/flip, end to end', () {
    test('a clip with turns=1 gets transpose=1 in its own chain', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 1000, turns: 1),
      ]);
      expect(graph(cmd), contains('transpose=1'));
    });

    test('flip/rotate filters land before scale (reoriented before resizing)', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 1000, flipH: true),
      ]);
      final g = graph(cmd);
      expect(g.indexOf('hflip'), lessThan(g.indexOf('scale=')));
    });
  });

  group('F7 look, end to end', () {
    test('a clip with a look gets its colorchannelmixer in the graph', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 1000, look: 'cool'),
      ]);
      expect(graph(cmd), contains('colorchannelmixer='));
    });

    test('vignette look adds the vignette filter after format in the per-clip chain', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 1000, look: 'vignette'),
      ]);
      expect(graph(cmd), contains('vignette'));
    });

    test('no look -> no colorchannelmixer, no vignette filter', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 1000),
      ]);
      final g = graph(cmd);
      expect(g, isNot(contains('colorchannelmixer')));
      expect(g, isNot(contains('vignette')));
    });
  });

  group('F8 text styling v2, end to end', () {
    ExportOverlay overlay({bool bold = false, bool box = false, double outline = 0}) => ExportOverlay(
          id: 'o1',
          content: 'Hi',
          startMs: 0,
          endMs: 900,
          bold: bold,
          boxEnabled: box,
          outlineWidth: outline,
        );

    test('plain overlay (no bold/box/outline) has no borderw or box', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 1000),
      ], overlays: [
        overlay()
      ], textFilePaths: {
        'o1': '/t/o1.txt'
      });
      final g = graph(cmd);
      expect(g, isNot(contains('borderw')));
      expect(g, isNot(contains('box=1')));
    });

    test('bold with no explicit outline adds a thin same-color border', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 1000),
      ], overlays: [
        overlay(bold: true)
      ], textFilePaths: {
        'o1': '/t/o1.txt'
      });
      expect(graph(cmd), contains('borderw='));
    });

    test('an explicit outline width wins over bold\'s synthetic border', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 1000),
      ], overlays: [
        overlay(bold: true, outline: 2)
      ], textFilePaths: {
        'o1': '/t/o1.txt'
      });
      final g = graph(cmd);
      expect('borderw='.allMatches(g).length, 1); // never both at once
    });

    test('boxEnabled adds box=1 with a boxcolor', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 1000),
      ], overlays: [
        overlay(box: true)
      ], textFilePaths: {
        'o1': '/t/o1.txt'
      });
      expect(graph(cmd), contains('box=1:boxcolor='));
    });
  });

  group('F9 music fades, end to end', () {
    test('no fade set -> no afade filter at all', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 3000),
      ], music: const ExportMusic(path: 'm.mp3', trimStartMs: 0, trimEndMs: 3000));
      expect(graph(cmd), isNot(contains('afade')));
    });

    test('fadeInMs adds a fade-in starting at the music\'s own t=0', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 3000),
      ],
          music: const ExportMusic(
              path: 'm.mp3', trimStartMs: 0, trimEndMs: 3000, fadeInMs: 500));
      expect(graph(cmd), contains('afade=t=in:st=0:d=0.500'));
    });

    test('fadeOutMs starts at (trimmed length - fadeOut)', () {
      final cmd = build([
        ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 3000),
      ],
          music: const ExportMusic(
              path: 'm.mp3', trimStartMs: 1000, trimEndMs: 5000, fadeOutMs: 1000));
      // trimmed length = 5000-1000 = 4000ms; fade-out starts at 3000ms = "3.000"
      expect(graph(cmd), contains('afade=t=out:st=3.000:d=1.000'));
    });
  });
}
