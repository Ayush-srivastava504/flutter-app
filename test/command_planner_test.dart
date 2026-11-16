import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/ai/command_planner.dart';
import 'package:video_editor_app/ai/edit_action.dart';

const planner = LocalCommandPlanner();
List<EditAction> plan(String s) => planner.parse(s).actions;

void main() {
  test('every example chip in the sheet parses to at least one action, with nothing left over', () {
    for (final example in assistantExamples) {
      final p = planner.parse(example);
      expect(p.actions, isNotEmpty, reason: example);
      expect(p.unrecognized, isEmpty, reason: example);
    }
  });

  group('speed', () {
    test('multipliers, and "slow down 2x" means half speed', () {
      expect((plan('speed up 2x').single as SetSpeed).speed, 2.0);
      expect((plan('make it 1.5x').single as SetSpeed).speed, 1.5);
      expect((plan('slow down 2x').single as SetSpeed).speed, 0.5);
      expect((plan('slow motion').single as SetSpeed).speed, 0.5);
      expect((plan('half speed').single as SetSpeed).speed, 0.5);
      expect((plan('normal speed').single as SetSpeed).speed, 1.0);
    });

    test('is clamped to the supported range', () {
      expect((plan('speed up 10x').single as SetSpeed).speed, 4.0);
      expect((plan('slow down 8x').single as SetSpeed).speed, 0.25);
    });
  });

  group('scope', () {
    test('defaults to the selected clip', () {
      expect((plan('mute').single as SetMuted).scope, const ClipScope.selected());
    });
    test('all / every / numbered / ordinal clips', () {
      expect((plan('mute all clips').single as SetMuted).scope, const ClipScope.all());
      expect((plan('mute clip 3').single as SetMuted).scope, const ClipScope.index(3));
      expect((plan('mute the last clip').single as SetMuted).scope, const ClipScope.index(-1));
      expect((plan('mute the second clip').single as SetMuted).scope, const ClipScope.index(2));
    });
  });

  test('"black and white" is one look, not split on "and"', () {
    final actions = plan('make it black and white');
    expect(actions, hasLength(1));
    expect((actions.single as SetLook).look, 'mono');
  });

  test('compound requests produce one action per clause, in order', () {
    final actions = plan('trim the first 2 seconds, speed up 2x and make it sepia');
    expect(actions.map((a) => a.runtimeType), [TrimClip, SetSpeed, SetLook]);
    final trim = actions[0] as TrimClip;
    expect((trim.kind, trim.ms), (TrimKind.removeStart, 2000));
  });

  group('trim', () {
    test('start, end, and shorten-to', () {
      final end = plan('cut the last 1.5 seconds').single as TrimClip;
      expect((end.kind, end.ms), (TrimKind.removeEnd, 1500));
      final to = plan('trim it to 5 seconds').single as TrimClip;
      expect((to.kind, to.ms), (TrimKind.keepFirst, 5000));
      final ms = plan('remove the first 500ms').single as TrimClip;
      expect((ms.kind, ms.ms), (TrimKind.removeStart, 500));
    });

    test('"keep the last N seconds" is left unrecognised instead of guessed', () {
      final p = planner.parse('keep the last 3 seconds');
      expect(p.actions, isEmpty);
      expect(p.unrecognized, ['keep the last 3 seconds']);
    });
  });

  test('quoted text keeps its case and is not split on "and"', () {
    final add = plan('add text "Rock and Roll"').single as AddText;
    expect(add.content, 'Rock and Roll');
  });

  group('transitions', () {
    test('"between all clips" applies to all', () {
      final t = plan('dissolve between all clips').single as SetTransition;
      expect((t.transition, t.scope.all), ('dissolve', true));
    });
    test('names map to transition ids', () {
      expect((plan('add wipe transitions').single as SetTransition).transition, 'wipeleft');
      expect((plan('slide transitions').single as SetTransition).transition, 'slideleft');
      expect((plan('remove transitions').single as SetTransition).transition, 'cut');
    });
  });

  test('frame shape', () {
    expect((plan('make it square').single as SetAspectRatio).aspectRatio, 1.0);
    expect((plan('make it vertical').single as SetAspectRatio).label, '9:16');
    expect((plan('4:5').single as SetAspectRatio).aspectRatio, closeTo(0.8, 1e-9));
  });

  test('music', () {
    final fade = plan('fade music out 2s').single as SetMusicFade;
    expect((fade.fadeInMs, fade.fadeOutMs), (null, 2000));
    expect((plan('music volume 30%').single as SetMusicVolume).volume, closeTo(0.3, 1e-9));
    expect(plan('remove the music').single, isA<RemoveMusic>());
    expect((plan('turn off ducking').single as SetDucking).enabled, isFalse);
  });

  test('smart tools', () {
    expect((plan('remove silences').single as RunSmartTool).tool, SmartTool.removeSilences);
    expect((plan('cut out the pauses').single as RunSmartTool).tool, SmartTool.removeSilences);
    expect((plan('split at scene changes').single as RunSmartTool).tool, SmartTool.splitScenes);
    expect((plan('balance the audio').single as RunSmartTool).tool, SmartTool.balanceLoudness);
    expect((plan('auto polish').single as RunSmartTool).tool, SmartTool.autoPolish);
  });

  test('"remove the filter" resets the look, it does not delete the clip', () {
    final actions = plan('remove the filter');
    expect(actions.whereType<DeleteClips>(), isEmpty);
    expect(actions.whereType<SetLook>().single.look, isNull);
  });

  test('delete needs to mean a clip', () {
    expect(plan('delete this clip').single, isA<DeleteClips>());
    expect(plan('delete').single, isA<DeleteClips>());
    expect(planner.parse('delete the vibe').actions, isEmpty);
  });

  test('new looks by name, with optional strength', () {
    expect((plan('make it gothic').single as SetLook).look, 'gothic');
    expect((plan('anime style').single as SetLook).look, 'anime');
    expect((plan('cartoon').single as SetLook).look, 'cartoon');
    expect((plan('cinematic look').single as SetLook).look, 'cinematic');
    expect((plan('vhs effect').single as SetLook).look, 'vhs');
    expect((plan('noir').single as SetLook).look, 'noir');
    final half = plan('film look 50%').single as SetLook;
    expect((half.look, half.strength), ('film', 0.5));
  });

  test('undo / redo', () {
    expect(plan('undo').single, isA<UndoEdit>());
    expect(plan('redo that').single, isA<RedoEdit>());
  });

  test('gibberish is reported back, not acted on', () {
    final p = planner.parse('xyzzy plugh');
    expect(p.actions, isEmpty);
    expect(p.unrecognized, ['xyzzy plugh']);
  });
}
