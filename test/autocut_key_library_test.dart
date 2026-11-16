import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/export/export_command_builder.dart';
import 'package:video_editor_app/export/export_models.dart';
import 'package:video_editor_app/models/audio_library.dart';
import 'package:video_editor_app/models/auto_cut.dart';
import 'package:video_editor_app/models/chroma_key.dart';
import 'package:video_editor_app/models/transition_x.dart';

/// v12: AutoCut (tempo + beat planning), background removal (colour key),
/// the bigger transition set, and the built-in audio library.

/// A click track: short decaying bursts on every beat (+ weaker off-beats).
List<double> clicks(double bpm, int offsetMs, {int seconds = 20, int sr = 11025, int seed = 1}) {
  final g = math.Random(seed);
  final out = List<double>.generate(seconds * sr, (_) => (g.nextDouble() - 0.5) * 0.02);
  final beat = 60 / bpm;
  for (var k = 0;; k++) {
    final t = offsetMs / 1000 + k * beat / 2;
    if (t >= seconds - 0.1) break;
    final strong = k.isEven;
    final start = (t * sr).round();
    for (var i = 0; i < sr * 0.05 && start + i < out.length; i++) {
      out[start + i] += (strong ? 0.9 : 0.25) * math.exp(-i / (sr * 0.008)) * math.sin(i * 0.9);
    }
  }
  return out;
}

ExportCommand build(List<ExportClip> clips) => buildExportCommand(
      clips: clips,
      overlays: const [],
      aspectRatio: 16 / 9,
      quality: ExportQuality.p720,
      encoder: VideoEncoder.software,
      outputPath: '/out/o.mp4',
      fontPaths: const {'Default': '/f/Sans.ttf'},
      textFilePaths: const {},
      voiceOvers: const [ExportVoiceOver(path: '/v.m4a', startMs: 0)],
    );

String graph(ExportCommand c) => c.args[c.args.indexOf('-filter_complex') + 1];

void main() {
  group('tempo', () {
    for (final (bpm, offset) in [(100.0, 300), (128.0, 120), (78.0, 0), (90.0, 450), (120.0, 0)]) {
      test('finds $bpm bpm with the first beat at $offset ms', () {
        final t = estimateTempo(clicks(bpm, offset), 11025)!;
        expect(t.bpm, closeTo(bpm, 1.5));
        // Phase is only defined modulo one beat.
        final beat = 60000 / bpm;
        final d = ((t.firstBeatMs - offset) % beat + beat) % beat;
        expect(math.min(d, beat - d), lessThan(35), reason: '$t');
      });
    }

    test('silence and very short audio give no tempo', () {
      expect(estimateTempo(List.filled(11025 * 10, 0.0), 11025), isNull);
      expect(estimateTempo(List.filled(1000, 0.0), 11025), isNull);
    });

    test('library tracks are recognised from their copied file name', () {
      final t = libraryTempoFor('/data/app/files/bundled_audio/lofi_rainy_window.m4a')!;
      expect(t.bpm, 78);
      expect(libraryTempoFor('/x/my_song.mp3'), isNull);
      expect(libraryTempoFor('/x/sfx_whoosh.m4a'), isNull, reason: 'effects have no tempo');
    });

    test('music trim moves forward to the next beat', () {
      const t = Tempo(120, 100); // beats at 100, 600, 1100…
      expect(beatAlignedTrimStart(t, 0), 100);
      expect(beatAlignedTrimStart(t, 600), 600);
      expect(beatAlignedTrimStart(t, 601), 1100);
    });
  });

  group('planBeatCuts', () {
    const sources = [
      BeatSource('a', 0, 10000),
      BeatSource('b', 2000, 6000),
      BeatSource('p', 0, 3000, isPhoto: true),
    ];

    test('every cut lands on the beat grid, however many there are', () {
      final plan = planBeatCuts(sources, beatMs: 60000 / 128, beatsPerCut: 1, targetMs: 9000);
      var t = 0;
      for (var i = 0; i < plan.length; i++) {
        t += plan[i].lengthMs;
        expect(t, ((i + 1) * 60000 / 128).round(), reason: 'cut $i');
      }
    });

    test('clips take turns, stay inside their material, and photos appear once', () {
      final plan = planBeatCuts(sources, beatMs: 500, beatsPerCut: 2, targetMs: 60000);
      expect(plan.take(3).map((s) => s.clipId), ['a', 'b', 'p']);
      expect(plan.where((s) => s.clipId == 'p').length, 1);
      for (final s in plan.where((s) => s.clipId != 'p')) {
        final src = sources.firstWhere((x) => x.clipId == s.clipId);
        expect(s.srcStartMs, greaterThanOrEqualTo(src.srcStartMs));
        expect(s.srcEndMs, lessThanOrEqualTo(src.srcEndMs));
        expect(s.srcEndMs - s.srcStartMs, s.lengthMs);
      }
      // a: 10 s / 1 s = 10 pieces, b: 4 pieces, p: 1 → 15 in all.
      expect(plan.length, 15);
      // a's pieces are spread over the whole clip, not just its start.
      final aStarts = plan.where((s) => s.clipId == 'a').map((s) => s.srcStartMs).toList();
      expect(aStarts.first, 0);
      expect(aStarts.last, 9000);
    });

    test('a fast clip uses more source per slot', () {
      final plan = planBeatCuts(const [BeatSource('f', 0, 8000, speed: 2)], beatMs: 500, beatsPerCut: 2, targetMs: 3000);
      expect(plan.length, 3);
      expect(plan.first.srcEndMs - plan.first.srcStartMs, 2000);
      expect(plan.first.lengthMs, 1000);
    });

    test('stops at the music length', () {
      final plan = planBeatCuts(const [BeatSource('a', 0, 60000)], beatMs: 500, beatsPerCut: 4, targetMs: 7000);
      expect(plan.length, 3);
    });
  });

  group('background removal', () {
    test('JSON round-trips; bad JSON means no key', () {
      const s = ChromaKeySpec(color: 0x0047BB, similarity: 0.2, blend: 0.1, despill: false, bg: 'image', bgImage: '/b.jpg');
      expect(ChromaKeySpec.tryParse(s.toJson()), s);
      expect(ChromaKeySpec.tryParse('not json'), isNull);
      expect(ChromaKeySpec.tryParse(null), isNull);
    });

    test('green screen is removed, skin and clothes are kept', () {
      const s = ChromaKeySpec();
      expect(keyAlpha(0x00B140, s), 0);
      expect(keyAlpha(0x10A848, s), 0, reason: 'a slightly different green on the same screen');
      expect(keyAlpha(0xE0AC90, s), 1, reason: 'skin');
      expect(keyAlpha(0x203050, s), 1, reason: 'dark blue shirt');
      expect(keyAlpha(0xF0F0F0, s), 1, reason: 'white');
      expect(keyAlpha(0x101010, s), 1, reason: 'black');
      expect(keyAlpha(0x007A2C, s), 0, reason: 'the screen in shadow');
    });

    test('despill flavour follows the key colour', () {
      expect(despillTypeFor(ChromaKeySpec.greenScreen), 'green');
      expect(despillTypeFor(ChromaKeySpec.blueScreen), 'blue');
      expect(despillTypeFor(0xFF0000), isNull);
      expect(chromaKeyFilters(const ChromaKeySpec(color: 0xFF0000)).any((f) => f.startsWith('despill')), isFalse);
    });

    test('export keys the framed clip and lays it over a colour background', () {
      final g = graph(build([
        const ExportClip(
            path: '/a.mp4',
            isPhoto: false,
            trimStartMs: 0,
            trimEndMs: 3000,
            chromaKey: ChromaKeySpec(bgColor: 0xFF7A45),
            look: 'mono'),
      ]));
      expect(g, contains('format=yuva420p,chromakey=color=0x00B140:similarity=0.080:blend=0.060,'
          'format=rgba,despill=type=green:mix=0.5:expand=0:red=0:green=-1:blue=0[ky0]'));
      expect(g, contains('color=c=0xFF7A45:s=1280x720:r=30:d=3.000,setsar=1[kb0]'));
      expect(g, contains('[kb0][ky0]overlay=0:0:shortest=1:format=auto,setsar=1,fps=30'));
      // The look is applied after compositing (to the whole picture).
      expect(g.indexOf('[kb0][ky0]overlay'), lessThan(g.indexOf('colorchannelmixer')));
    });

    test('a photo background becomes a looped input after the voice-overs', () {
      final c = build([
        const ExportClip(path: '/a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 2000),
        const ExportClip(
            path: '/b.mp4',
            isPhoto: false,
            trimStartMs: 0,
            trimEndMs: 4000,
            chromaKey: ChromaKeySpec(bg: 'image', bgImage: '/bg.jpg')),
      ]);
      final i = c.args.indexOf('/bg.jpg');
      expect(c.args.sublist(i - 7, i + 1), ['-loop', '1', '-framerate', '30', '-t', '4.000', '-i', '/bg.jpg']);
      // Inputs: 0 a.mp4, 1 b.mp4, 2 voice-over, 3 background.
      expect(graph(c), contains('[3:v]scale=1280:720:force_original_aspect_ratio=increase'));
    });
  });

  group('transitions', () {
    test('26 options with unique ids, every group used, only cut/fade without xfade', () {
      expect(transitionOptions.length, 26);
      expect(transitionOptions.map((o) => o.id).toSet().length, transitionOptions.length);
      for (final g in transitionGroups) {
        expect(transitionOptions.any((o) => o.group == g), isTrue, reason: g);
      }
      expect(transitionOptions.where((o) => o.xfade == null).map((o) => o.id), ['cut', 'fade']);
      expect(transitionOptions.where((o) => o.trendy).length, greaterThanOrEqualTo(5));
    });

    test('ids stored by older versions keep their meaning', () {
      for (final (id, x) in [('dissolve', 'fade'), ('slideleft', 'slideleft'), ('wipeleft', 'wipeleft'),
        ('circleopen', 'circleopen'), ('zoomin', 'zoomin')]) {
        expect(xfadeNameFor(id), x);
      }
    });

    test('flash goes up to white at the midpoint, then down onto the next clip', () {
      expect(transitionPreviewAt(transitionOut: 'flash', playheadMs: 700, boundaryMs: 1000).white, closeTo(1, 0.01));
      final early = transitionPreviewAt(transitionOut: 'flash', playheadMs: 550, boundaryMs: 1000);
      expect(early.currentOpacity, 1);
      expect(early.white, closeTo(0.5, 0.01));
      expect(transitionPreviewAt(transitionOut: 'flash', playheadMs: 999, boundaryMs: 1000).nextOpacity, 1);
    });
  });

  group('audio library', () {
    test('28 sounds: 12 tracks (3 lofi) and 16 effects, all files present', () {
      final music = audioLibrary.where((s) => !s.isSfx).toList();
      final sfx = audioLibrary.where((s) => s.isSfx).toList();
      expect(music.length, 12);
      expect(sfx.length, 16);
      expect(music.where((s) => s.category == 'Lofi').length, 3);
      expect(audioLibrary.map((s) => s.id).toSet().length, audioLibrary.length);
      for (final s in audioLibrary) {
        expect(File(s.assetPath).existsSync(), isTrue, reason: s.assetPath);
        expect(s.durationMs, greaterThan(0));
        if (!s.isSfx) {
          expect(s.bpm, inInclusiveRange(55, 130), reason: s.id);
          expect(s.durationMs, greaterThan(40000), reason: '${s.id} is long enough for a short video');
        }
        expect(s.id.startsWith('sfx_'), s.isSfx, reason: 'lanes tell effects apart by the sfx_ prefix');
      }
    });
  });
}
