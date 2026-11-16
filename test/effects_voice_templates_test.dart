import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/export/export_command_builder.dart';
import 'package:video_editor_app/export/export_models.dart';
import 'package:video_editor_app/models/edit_mode.dart';
import 'package:video_editor_app/models/effect_x.dart';
import 'package:video_editor_app/models/look_x.dart';
import 'package:video_editor_app/models/audio_library.dart';
import 'package:video_editor_app/models/bundled_track.dart';
import 'package:video_editor_app/models/transition_x.dart';
import 'package:video_editor_app/models/video_template.dart';

/// v11: effects (motion + stylise), Enhance speech, voice-over mixing, templates.
ExportCommand build(List<ExportClip> clips, {List<ExportVoiceOver> voice = const [], ExportMusic? music, bool duck = false}) =>
    buildExportCommand(
      clips: clips,
      overlays: const [],
      music: music,
      aspectRatio: 16 / 9,
      quality: ExportQuality.p720,
      encoder: VideoEncoder.software,
      outputPath: '/out/o.mp4',
      fontPaths: const {'Default': '/f/Sans.ttf'},
      textFilePaths: const {},
      voiceOvers: voice,
      duckMusic: duck,
    );

String graph(ExportCommand c) => c.args[c.args.indexOf('-filter_complex') + 1];

ExportClip video({String? effect, double k = 1.0, bool speech = false, int ms = 4000}) => ExportClip(
      path: '/a.mp4',
      isPhoto: false,
      trimStartMs: 0,
      trimEndMs: ms,
      hasAudio: true,
      effect: effect,
      effectStrength: k,
      enhanceSpeech: speech,
    );

void main() {
  group('motionAt', () {
    test('zoom in grows from 1 to 1.2 over the clip; zoom out does the reverse', () {
      expect(motionAt(MotionKind.zoomIn, 0, 4, 1).scale, 1);
      expect(motionAt(MotionKind.zoomIn, 4, 4, 1).scale, closeTo(1.2, 1e-9));
      expect(motionAt(MotionKind.zoomIn, 2, 4, 0.5).scale, closeTo(1.05, 1e-9));
      expect(motionAt(MotionKind.zoomOut, 0, 4, 1).scale, closeTo(1.2, 1e-9));
      expect(motionAt(MotionKind.zoomOut, 9, 4, 1).scale, 1, reason: 'clamped after the end');
    });

    test('shake and pan never move the window past the zoom margin', () {
      for (final kind in [MotionKind.shake, MotionKind.drift]) {
        for (var t = 0.0; t <= 5; t += 0.013) {
          final f = motionAt(kind, t, 5, 1);
          final margin = (f.scale - 1) / 2; // per side, as a fraction of the frame
          expect(f.dx.abs(), lessThanOrEqualTo(margin + 1e-9), reason: '$kind dx at $t');
          expect(f.dy.abs(), lessThanOrEqualTo(margin + 1e-9), reason: '$kind dy at $t');
        }
      }
    });

    test('flash starts white and is gone after its length', () {
      expect(motionAt(MotionKind.flash, 0, 3, 1).flash, 1);
      expect(motionAt(MotionKind.flash, 0.2, 3, 1).flash, closeTo(0.5, 1e-9));
      expect(motionAt(MotionKind.flash, 0.5, 3, 1).flash, 0);
    });
  });

  group('effect catalogue', () {
    test('ids are unique and each effect is exactly one of motion, stylise or glow', () {
      final ids = effectPresets.map((e) => e.id).toSet();
      expect(ids.length, effectPresets.length);
      for (final e in effectPresets) {
        expect([e.motion, e.style, e.glow].where((x) => x != null).length, 1, reason: e.id);
        // Ink edges would need a second split branch in the export graph.
        expect(e.style?.edges ?? 0, 0, reason: e.id);
      }
    });

    test('unknown ids behave as no effect', () {
      expect(effectById('nope'), isNull);
      expect(effectById(null), isNull);
      expect(effectStyle('fx_zoom_in', 1), isNull, reason: 'motion effects have no style');
      expect(effectStyle('fx_glitch', 0), isNull);
    });
  });

  group('export graph', () {
    test('zoom in = per-frame scale then crop back to the frame size', () {
      final g = graph(build([video(effect: 'fx_zoom_in')]));
      expect(g, contains("scale=w='2*trunc(1280*(1+0.2000*min(t/4.0000,1))/2)'"));
      expect(g, contains(':eval=frame:'));
      expect(g, contains("crop=w=1280:h=720:x='(iw-1280)/2+(0)*1280'"));
    });

    test('flash is a fade from white; strength 0 adds nothing', () {
      expect(graph(build([video(effect: 'fx_flash')])), contains('fade=t=in:st=0:d=0.400:color=white'));
      final none = graph(build([video(effect: 'fx_zoom_in', k: 0)]));
      expect(none, isNot(contains('eval=frame')));
    });

    test('stylise effects reuse the look steps, after the look', () {
      final g = graph(build([video(effect: 'fx_glitch')]));
      expect(g, contains('rgbashift'));
      final withLook = graph(build([
        const ExportClip(path: '/a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 3000, look: 'mono', effect: 'fx_glitch'),
      ]));
      expect(withLook.indexOf('colorchannelmixer'), lessThan(withLook.indexOf('rgbashift')));
    });

    test('Enhance speech adds the voice chain to that clip only', () {
      expect(graph(build([video()])), isNot(contains('afftdn')));
      final g = graph(build([video(speech: true)]));
      expect(g, contains(speechEnhanceFilters.join(',')));
    });

    test('voice-overs are delayed to their spot and mixed into the clip bus', () {
      final c = build([video(ms: 6000)], voice: const [
        ExportVoiceOver(path: '/v1.m4a', startMs: 1500, volume: 0.8),
        ExportVoiceOver(path: '/v2.m4a', startMs: 4000, enhance: false),
      ]);
      final g = graph(c);
      expect(c.args.where((a) => a == '/v1.m4a' || a == '/v2.m4a').length, 2);
      expect(g, contains('[1:a]aresample=44100'));
      expect(g, contains('volume=0.800,adelay=1500:all=1[vo0]'));
      expect(g, contains('[2:a]aresample=44100,aformat=sample_fmts=fltp:channel_layouts=stereo,volume=1.000,adelay=4000:all=1[vo1]'));
      expect(g, contains('[a0][vo0][vo1]amix=inputs=3:duration=first'));
      expect(c.args, containsAllInOrder(['-map', '[avo]']));
    });

    test('with music, voice-over inputs come after the music input and ducking hears them', () {
      final c = build(
        [video(ms: 6000)],
        music: const ExportMusic(path: '/m.wav', trimStartMs: 0, trimEndMs: 6000, offsetMs: 0, volume: 1),
        voice: const [ExportVoiceOver(path: '/v.m4a', startMs: 0)],
        duck: true,
      );
      final g = graph(c);
      expect(g, contains('[2:a]aresample'));
      expect(g, contains('[avo]asplit=2[dsc][dmix]'));
    });
  });

  group('templates', () {
    test('every template references real looks, effects and music, with sensible slots', () {
      final ids = <String>{};
      for (final t in videoTemplates) {
        expect(ids.add(t.id), isTrue, reason: 'duplicate ${t.id}');
        expect(t.slotsMs, isNotEmpty);
        expect(t.slotsMs.every((s) => s >= 500), isTrue, reason: t.id);
        if (t.look != null) expect(lookById(t.look).id, t.look, reason: t.id);
        for (final e in t.effects) {
          if (e != null) expect(effectById(e), isNotNull, reason: '${t.id}: $e');
        }
        expect(transitionOptions.any((o) => o.id == t.transition), isTrue, reason: '${t.id}: unknown transition');
        expect(discoverCategoryById(t.category), isNotNull, reason: '${t.id}: unknown category');
        if (t.musicId != null) {
          final known = audioLibrary.any((s) => s.id == t.musicId) || bundledAudioLibrary.any((b) => b.id == t.musicId);
          expect(known, isTrue, reason: '${t.id}: unknown music ${t.musicId}');
        }
        if (t.beats != null) {
          expect(t.isBeatSynced, isTrue, reason: '${t.id}: beat template needs music with a tempo');
          // An xfade overlaps clips, shortening the timeline and moving every
          // later cut off the beat.
          expect(isOverlapTransition(t.transition), isFalse, reason: '${t.id}: overlapping transition');
        }
      }
    });

    test('every Discover tab has categories and every category has templates', () {
      for (final tab in DiscoverTab.values) {
        final cats = discoverCategories.where((c) => c.tab == tab);
        expect(cats, isNotEmpty, reason: tab.name);
        for (final c in cats) {
          expect(videoTemplates.where((t) => t.category == c.id), isNotEmpty, reason: c.id);
        }
      }
    });

    test('beat slots end exactly on beats of the music (no rounding drift)', () {
      final t = videoTemplates.firstWhere((t) => t.id == 'tpl_gaming_montage'); // 124 bpm
      expect(t.bpm, 124);
      const beatMs = 60000 / 124;
      var end = 0, beats = 0;
      for (var i = 0; i < t.slotsMs.length; i++) {
        end += t.slotsMs[i];
        beats += t.beats![i];
        expect((end - beats * beatMs).abs(), lessThanOrEqualTo(0.5), reason: 'slot $i');
      }
    });

    test('beat plan: a short video ends on the last beat it reaches and later cuts stay on the grid', () {
      final t = videoTemplates.firstWhere((t) => t.id == 'tpl_ig_beat'); // 120 bpm, 2 beats = 1000 ms
      expect(t.beatMs, 500);
      final plan = planTemplateClips(t, [null, 700, 300, 9000]);
      // 1000 | 700 → 500 (1 beat) | 300 (no beat inside: off grid) | 1200, back on beat 6 (3000)
      expect(plan.map((p) => p.lengthMs), [1000, 500, 300, 1200]);
      var cursor = 0;
      for (final p in plan.take(2)) {
        cursor += p.lengthMs;
        expect(cursor % 500, 0);
      }
      expect((cursor + 300 + 1200) % 500, 0, reason: 'the clip after an off-grid one lands back on a beat');
    });

    test('clips are trimmed to their slot, short videos keep their length, last clip is a cut', () {
      final t = videoTemplates.firstWhere((t) => t.id == 'tpl_ig_travel');
      final plan = planTemplateClips(t, [10000, 900, null]);
      expect(plan, const [
        TemplateClipPlan(1500, 'fx_zoom_in', 'cut'),
        TemplateClipPlan(900, null, 'cut'),
        TemplateClipPlan(1500, 'fx_pulse', 'cut'),
      ]);
      final yt = videoTemplates.firstWhere((t) => t.id == 'tpl_yt_intro');
      final p2 = planTemplateClips(yt, [9000, 9000, 9000, 9000]);
      expect(p2.map((p) => p.lengthMs), [2500, 2500, 3500, 2500], reason: 'slots repeat');
      expect(p2.map((p) => p.transitionOut), ['dissolve', 'dissolve', 'dissolve', 'cut']);
      expect(yt.mode, EditMode.youtube);
    });

    test('titles counted from the end land at the end; ones that do not fit are dropped', () {
      final t = videoTemplates.firstWhere((t) => t.id == 'tpl_yt_intro');
      final placed = placeTemplateTexts(t, 8000);
      expect(placed.map((p) => (p.$1.content, p.$2, p.$3)), [
        ('YOUR CHANNEL', 0, 3000),
        ('new video every week', 600, 3000),
        ('Subscribe', 5000, 7800),
      ]);
      expect(placeTemplateTexts(t, 200), isEmpty, reason: "nothing gets 300 ms");
    });
  });

  group('glow', () {
    test('both presets are glow effects with a usable spec', () {
      for (final id in ['fx_glow', 'fx_dreamy']) {
        final e = effectById(id)!;
        expect(e.kind, EffectKind.glow);
        expect(e.glow, isNotNull);
        expect(e.style, isNull);
        expect(e.motion, isNull);
      }
    });

    test('strength scales the blend opacity; 0 or non-glow means no glow', () {
      expect(glowAt('fx_glow', 0), isNull);
      expect(glowAt('fx_vhs', 1), isNull);
      expect(glowAt(null, 1), isNull);
      expect(glowAt('fx_glow', 0.5)!.opacity, closeTo(0.425, 1e-9));
    });

    test('export splits, blurs the highlights and screen-blends them back', () {
      final g = graph(build([video(effect: 'fx_glow')]));
      expect(g, contains('format=gbrp,split[ga0][gb0]'));
      // 720p 16:9 → 1280 wide; radius 0.025 → sigma 32.
      expect(g, contains('[gb0]colorlevels=rimin=0.550:gimin=0.550:bimin=0.550,gblur=sigma=32.00[gc0]'));
      expect(g, contains('[ga0][gc0]blend=all_mode=screen:all_opacity=0.850'));
      expect(g, contains('format=yuv420p'));
    });

    test('a clip without glow has no glow branch', () {
      expect(graph(build([video(effect: 'fx_vhs')])), isNot(contains('blend=all_mode=screen')));
    });
  });

}
