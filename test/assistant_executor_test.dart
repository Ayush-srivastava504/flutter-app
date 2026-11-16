import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/ai/assistant_executor.dart';
import 'package:video_editor_app/ai/edit_action.dart';
import 'package:video_editor_app/ai/media_analysis.dart';
import 'package:video_editor_app/data/project_database.dart';

import 'support/fixtures.dart';

/// Returns canned FFmpeg logs, keyed by which analysis filter was asked for.
class _FakeAnalyzer implements MediaAnalyzer {
  final Map<String, String> logs;
  final List<List<String>> calls = [];
  _FakeAnalyzer(this.logs);

  @override
  Future<String> analyze(List<String> args) async {
    calls.add(args);
    final joined = args.join(' ');
    for (final e in logs.entries) {
      if (joined.contains(e.key)) return e.value;
    }
    return '';
  }
}

void main() {
  late ProjectDatabase db;
  var nextId = 0;
  const ctx = AssistantContext(projectId: 'p1', selectedClipId: 'b');

  AssistantExecutor executor({MediaAnalyzer? analyzer}) =>
      AssistantExecutor(db, analyzer: analyzer, newId: () => 'new${nextId++}');

  Future<List<Clip>> clips() => db.watchClips('p1').first;

  setUp(() async {
    nextId = 0;
    db = ProjectDatabase.forTesting(NativeDatabase.memory());
    await seedProject(db, [
      clipRow(id: 'a', trimEndMs: 4000),
      clipRow(id: 'b', trimStartMs: 1000, trimEndMs: 7000, durationMs: 10000),
      clipRow(id: 'c', sourceUri: '/p.jpg', trimEndMs: 3000),
    ]);
  });
  tearDown(() => db.close());

  test('selected-clip scope only touches the selected clip', () async {
    final r = await executor().run([const SetSpeed(ClipScope.selected(), 2)], ctx);
    expect(r.single.ok, isTrue);
    expect([for (final c in await clips()) c.speed], [1.0, 2.0, 1.0]);
  });

  test('all-clips speed skips photos', () async {
    await executor().run([const SetSpeed(ClipScope.all(), 2)], ctx);
    expect([for (final c in await clips()) c.speed], [2.0, 2.0, 1.0]);
  });

  test('with nothing selected, the clip under the playhead is used', () async {
    const noSelection = AssistantContext(projectId: 'p1', playheadMs: 5000); // inside clip b (4000..10000)
    await executor().run([const SetMuted(ClipScope.selected(), true)], noSelection);
    expect([for (final c in await clips()) c.muted], [false, true, false]);
  });

  test('an out-of-range clip number is refused with a message, nothing changes', () async {
    final r = await executor().run([const SetMuted(ClipScope.index(9), true)], ctx);
    expect(r.single.ok, isFalse);
    expect(r.single.message, contains('no clip 9'));
    expect((await clips()).any((c) => c.muted), isFalse);
  });

  test('later actions see earlier ones (trim after speed works in timeline time)', () async {
    await executor().run([
      const SetSpeed(ClipScope.selected(), 2),
      const TrimClip(ClipScope.selected(), TrimKind.removeStart, 1000), // 1 s of timeline = 2 s of source at 2x
    ], ctx);
    final b = (await clips())[1];
    expect((b.trimStartMs, b.trimEndMs), (3000, 7000));
  });

  test('a trim that would leave nothing is refused', () async {
    final r = await executor().run([const TrimClip(ClipScope.index(1), TrimKind.removeEnd, 4000)], ctx);
    expect(r.single.ok, isFalse);
    expect((await clips()).first.trimEndMs, 4000);
  });

  test('trimming a photo changes how long it shows', () async {
    await executor().run([const TrimClip(ClipScope.index(3), TrimKind.keepFirst, 1500)], ctx);
    final photo = (await clips()).last;
    expect((photo.trimStartMs, photo.trimEndMs, photo.durationMs), (0, 1500, 1500));
  });

  test('split at the playhead uses source time for a sped-up clip', () async {
    await executor().run([const SetSpeed(ClipScope.selected(), 2)], ctx);
    // b now spans timeline 4000..7000 (6 s of source at 2x); split 1 s in.
    await executor().run([const SplitAtPlayhead()], const AssistantContext(projectId: 'p1', playheadMs: 5000));
    final all = await clips();
    expect(all, hasLength(4));
    expect((all[1].trimStartMs, all[1].trimEndMs), (1000, 3000));
    expect((all[2].trimStartMs, all[2].trimEndMs), (3000, 7000));
  });

  test('transition on all clips, and the last clip refuses one', () async {
    await executor().run([const SetTransition(ClipScope.all(), 'slideleft')], ctx);
    expect((await clips()).map((c) => c.transitionOut).toSet(), {'slideleft'});
    final r = await executor().run([const SetTransition(ClipScope.index(-1), 'fade')], ctx);
    expect(r.single.ok, isFalse);
  });

  test('frame shape and ducking land on the project row', () async {
    await executor().run([const SetAspectRatio(1, '1:1'), const SetDucking(true)], ctx);
    final p = await db.getProject('p1');
    expect((p!.aspectRatio, p.duckMusic), (1.0, true));
  });

  test('music actions without music are refused, not crashed', () async {
    final r = await executor().run([const SetMusicVolume(0.5), const RemoveMusic()], ctx);
    expect(r.every((x) => !x.ok), isTrue);
  });

  test('fitting music to the timeline trims its end', () async {
    await seedMusic(db, durationMs: 30000, offsetMs: 1000);
    await executor().run([const FitMusicToTimeline()], ctx);
    final m = await db.getAudioTrack('p1');
    expect(m!.trimEndMs, 12000); // timeline is 4 + 6 + 3 = 13 s, music starts at 1 s
  });

  group('smart tools', () {
    test('remove silences replaces the clip with its non-silent parts', () async {
      final analyzer = _FakeAnalyzer({
        'silencedetect': 'silence_start: 2.0\nsilence_end: 4.0\n',
      });
      final r = await executor(analyzer: analyzer).run([const RunSmartTool(SmartTool.removeSilences, ClipScope.selected())], ctx);
      expect(r.single.ok, isTrue, reason: r.single.message);
      // Analysis ran on b's trim window only.
      expect(analyzer.calls.single, containsAllInOrder(['-ss', '1.000', '-t', '6.000']));
      final all = await clips();
      expect([for (final c in all) c.id], ['a', 'b', 'new0', 'c']);
      // Silence 2.0–4.0 s into the window (= source 3000–5000), padded 100 ms.
      expect((all[1].trimStartMs, all[1].trimEndMs), (1000, 3100));
      expect((all[2].trimStartMs, all[2].trimEndMs), (4900, 7000));
    });

    test('no silence found leaves the clip alone', () async {
      final r = await executor(analyzer: _FakeAnalyzer({})).run(
        [const RunSmartTool(SmartTool.removeSilences, ClipScope.selected())],
        ctx,
      );
      expect(r.single.message, 'No silent parts found.');
      expect(await clips(), hasLength(3));
    });

    test('split scenes cuts at detected changes', () async {
      final analyzer = _FakeAnalyzer({'scene': 'pts_time:2.5\npts_time:4.0\n'});
      await executor(analyzer: analyzer).run([const RunSmartTool(SmartTool.splitScenes, ClipScope.selected())], ctx);
      final all = await clips();
      expect([for (final c in all) (c.trimStartMs, c.trimEndMs)], [
        (0, 4000),
        (1000, 3500),
        (3500, 5000),
        (5000, 7000),
        (0, 3000),
      ]);
    });

    test('balance loudness turns the louder clip down', () async {
      // A different level per clip, told apart by the trim window it seeks to.
      final loudness = _FakeAnalyzer({'-ss 0.000': 'mean_volume: -14.0 dB', '-ss 1.000': 'mean_volume: -20.0 dB'});
      await executor(analyzer: loudness).run([const RunSmartTool(SmartTool.balanceLoudness, ClipScope.all())], ctx);
      final all = await clips();
      expect(all[0].volume, closeTo(0.501, 0.001)); // -6 dB
      expect(all[1].volume, 1.0);
    });

    test('without an analyzer the analysis tools are refused politely', () async {
      final r = await executor().run([const RunSmartTool(SmartTool.splitScenes, ClipScope.selected())], ctx);
      expect(r.single.ok, isFalse);
    });

    test('auto-polish adds dissolves and music touches, and is idempotent', () async {
      await seedMusic(db, durationMs: 30000);
      final first = await executor().run([const RunSmartTool(SmartTool.autoPolish, ClipScope.all())], ctx);
      expect(first.single.ok, isTrue);
      final all = await clips();
      expect([for (final c in all) c.transitionOut], ['dissolve', 'dissolve', 'cut']);
      final m = await db.getAudioTrack('p1');
      expect((m!.trimEndMs, m.fadeInMs, m.fadeOutMs), (13000, 800, 1500));
      expect((await db.getProject('p1'))!.duckMusic, isTrue);

      final second = await executor().run([const RunSmartTool(SmartTool.autoPolish, ClipScope.all())], ctx);
      expect(second.single.message, startsWith('Nothing to polish'));
    });
  });
}
