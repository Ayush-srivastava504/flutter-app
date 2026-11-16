import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/ai/media_analysis.dart';

void main() {
  group('silences', () {
    const log = '''
[silencedetect @ 0x7f] silence_start: 1.2
[silencedetect @ 0x7f] silence_end: 2.7 | silence_duration: 1.5
[silencedetect @ 0x7f] silence_start: 5.0
''';

    test('parses pairs, and an open silence runs to the end', () {
      expect(parseSilences(log, totalMs: 6000), [(1200, 2700), (5000, 6000)]);
    });

    test('a negative start (FFmpeg can print -0.0x) clamps to 0', () {
      expect(parseSilences('silence_start: -0.02\nsilence_end: 0.8', totalMs: 3000), [(0, 800)]);
    });

    test('keepRanges leaves padding around each cut', () {
      final keeps = keepRanges([(1200, 2700), (5000, 6000)], 6000, padMs: 100);
      expect(keeps, [(0, 1300), (2600, 5100)]);
    });

    test('keepRanges drops slivers shorter than minKeepMs', () {
      // 200 ms of sound between two silences is dropped.
      final keeps = keepRanges([(0, 1000), (1200, 3000)], 5000, padMs: 0, minKeepMs: 300);
      expect(keeps, [(3000, 5000)]);
    });

    test('no silences keeps everything; all silence keeps nothing', () {
      expect(keepRanges([], 4000), [(0, 4000)]);
      expect(keepRanges([(0, 4000)], 4000, padMs: 0), isEmpty);
    });
  });

  group('scenes', () {
    test('parses pts_time from showinfo, ignoring t=0', () {
      const log = '''
[Parsed_showinfo_1 @ 0x1] n:   0 pts:      0 pts_time:0       pos:...
[Parsed_showinfo_1 @ 0x1] n:   1 pts:  64000 pts_time:2.5     pos:...
[Parsed_showinfo_1 @ 0x1] n:   2 pts: 128000 pts_time:5.04    pos:...
''';
      expect(parseSceneTimesMs(log), [2500, 5040]);
    });

    test('segmentsFromCuts ignores cuts that would leave tiny pieces', () {
      expect(segmentsFromCuts([2500, 2700, 5000], 6000, minSegmentMs: 500), [(0, 2500), (2500, 5000), (5000, 6000)]);
      expect(segmentsFromCuts([], 3000), [(0, 3000)]);
      expect(segmentsFromCuts([200], 3000), [(0, 3000)], reason: 'too close to the start');
    });
  });

  group('loudness', () {
    test('parses mean_volume', () {
      expect(parseMeanVolumeDb('[Parsed_volumedetect_0 @ 0x1] mean_volume: -23.4 dB'), -23.4);
      expect(parseMeanVolumeDb('no audio'), isNull);
    });

    test('balanceGains turns louder clips down to the quietest', () {
      final g = balanceGains({'a': -20, 'b': -26, 'c': -26.5});
      expect(g['a'], closeTo(0.473, 0.001)); // -6.5 dB
      expect(g['b'], 1.0, reason: 'within 1 dB of the target');
      expect(g['c'], 1.0);
    });

    test('never cuts more than maxCutDb', () {
      final g = balanceGains({'loud': -10, 'nearly-silent': -60}, maxCutDb: 12);
      expect(g['loud'], closeTo(0.251, 0.001)); // -12 dB
      expect(g['nearly-silent'], 1.0);
    });
  });

  test('analysis commands seek the trim window and write nothing', () {
    final args = silenceDetectArgs('/v.mp4', 1500, 4000);
    expect(args.sublist(args.indexOf('-ss'), args.indexOf('-ss') + 4), ['-ss', '1.500', '-t', '2.500']);
    expect(args.indexOf('-ss'), lessThan(args.indexOf('-i')), reason: 'input seek, so timestamps start at 0');
    expect(args.sublist(args.length - 3), ['-f', 'null', '-']);
    expect(sceneDetectArgs('/v.mp4', 0, 1000), contains("select='gt(scene,0.35)',showinfo"));
    expect(volumeDetectArgs('/v.mp4', 0, 1000), contains('volumedetect'));
  });
}
