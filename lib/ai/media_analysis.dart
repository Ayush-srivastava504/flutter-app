/// Pure helpers for the smart tools: FFmpeg analysis command lines, parsers
/// for what those commands print, and the maths that turns the results
/// into edits. No Flutter, no FFmpegKit — everything here is unit-tested
/// against captured log text.
///
/// ⚠️ The filters used (`silencedetect`, `select=gt(scene,…)` + `showinfo`,
/// `volumedetect`) are standard FFmpeg filters but have NOT been run
/// through the phone's FFmpegKit build — see docs/FFMPEG_COOKBOOK.md.
library media_analysis;

import 'dart:math' as math;

/// Runs a read-only FFmpeg analysis pass and returns everything it logged.
/// The real implementation is `FfmpegKitEngine` (all FFmpeg execution stays
/// in `lib/export/export_engine.dart`); tests use a fake that returns
/// canned log text.
abstract class MediaAnalyzer {
  Future<String> analyze(List<String> args);
}

String _sec(int ms) => (ms / 1000).toStringAsFixed(3);

/// Common prefix: analyse only [startMs, endMs) of [path]. `-ss` before
/// `-i` seeks the input, so every timestamp FFmpeg prints is measured from
/// [startMs] (i.e. from the clip's trim start).
List<String> _window(String path, int startMs, int endMs) => [
      '-hide_banner',
      '-nostats',
      '-ss', _sec(startMs),
      '-t', _sec(endMs - startMs),
      '-i', path,
    ];

List<String> silenceDetectArgs(
  String path,
  int startMs,
  int endMs, {
  int noiseDb = -35,
  int minSilenceMs = 500,
}) =>
    [
      ..._window(path, startMs, endMs),
      '-vn',
      '-af', 'silencedetect=noise=${noiseDb}dB:d=${_sec(minSilenceMs)}',
      '-f', 'null', '-',
    ];

List<String> sceneDetectArgs(String path, int startMs, int endMs, {double threshold = 0.35}) => [
      ..._window(path, startMs, endMs),
      '-an',
      '-vf', "select='gt(scene,${threshold.toStringAsFixed(2)})',showinfo",
      '-f', 'null', '-',
    ];

List<String> volumeDetectArgs(String path, int startMs, int endMs) => [
      ..._window(path, startMs, endMs),
      '-vn',
      '-af', 'volumedetect',
      '-f', 'null', '-',
    ];

/// Silent ranges `(startMs, endMs)` from a `silencedetect` log, ascending.
/// A silence still open when the file ends (a `silence_start` with no
/// matching `silence_end`) runs to [totalMs].
List<(int, int)> parseSilences(String log, {required int totalMs}) {
  final out = <(int, int)>[];
  int? open;
  final re = RegExp(r'silence_(start|end):\s*(-?\d+(?:\.\d+)?)');
  for (final m in re.allMatches(log)) {
    final ms = (double.parse(m[2]!) * 1000).round().clamp(0, totalMs).toInt();
    if (m[1] == 'start') {
      open = ms;
    } else {
      final start = open ?? 0;
      if (ms > start) out.add((start, ms));
      open = null;
    }
  }
  if (open != null && totalMs > open) out.add((open, totalMs));
  return out;
}

/// The parts to keep once [silences] are removed from `[0, totalMs)`.
///
/// [padMs] of each silence is left in place on both sides so speech isn't
/// clipped mid-breath; kept parts shorter than [minKeepMs] are dropped
/// (a cough between two pauses isn't worth its own clip).
List<(int, int)> keepRanges(
  List<(int, int)> silences,
  int totalMs, {
  int padMs = 100,
  int minKeepMs = 300,
}) {
  final out = <(int, int)>[];
  var cursor = 0;
  void keep(int start, int end) {
    if (end - start >= minKeepMs) out.add((start, end));
  }

  for (final (s, e) in silences) {
    final cutStart = math.min(s + padMs, e);
    final cutEnd = math.max(e - padMs, cutStart);
    if (cutEnd <= cutStart) continue; // silence shorter than its padding
    if (cutStart > cursor) keep(cursor, cutStart);
    cursor = math.max(cursor, cutEnd);
  }
  if (cursor < totalMs) keep(cursor, totalMs);
  return out;
}

/// Scene-change times (ms) from a `select=gt(scene,…),showinfo` log.
List<int> parseSceneTimesMs(String log) {
  final out = <int>[];
  for (final m in RegExp(r'pts_time:\s*(-?\d+(?:\.\d+)?)').allMatches(log)) {
    final ms = (double.parse(m[1]!) * 1000).round();
    if (ms > 0) out.add(ms);
  }
  out.sort();
  return out;
}

/// Contiguous segments of `[0, totalMs)` cut at [cutsMs]. A cut that
/// would leave a segment shorter than [minSegmentMs] is ignored, so flashy
/// footage doesn't shatter into dozens of slivers.
List<(int, int)> segmentsFromCuts(List<int> cutsMs, int totalMs, {int minSegmentMs = 500}) {
  final out = <(int, int)>[];
  var start = 0;
  for (final cut in [...cutsMs]..sort()) {
    if (cut - start < minSegmentMs || totalMs - cut < minSegmentMs) continue;
    out.add((start, cut));
    start = cut;
  }
  if (totalMs > start) out.add((start, totalMs));
  return out;
}

/// `mean_volume` (dB) from a `volumedetect` log, or null if absent (no
/// audio stream, or the run failed).
double? parseMeanVolumeDb(String log) {
  final m = RegExp(r'mean_volume:\s*(-?\d+(?:\.\d+)?)\s*dB').firstMatch(log);
  return m == null ? null : double.parse(m[1]!);
}

/// Volume multipliers (0–1) that bring every clip to the same loudness.
///
/// Clip volume can only attenuate (the slider and the preview top out at
/// 1.0), so louder clips are turned *down* to the quietest one — but never
/// by more than [maxCutDb], so one near-silent clip can't drag the whole
/// project down to a whisper. Clips within 1 dB of the target are left
/// untouched (gain 1.0).
Map<String, double> balanceGains(Map<String, double> meanDbById, {double maxCutDb = 12}) {
  if (meanDbById.length < 2) return {for (final id in meanDbById.keys) id: 1.0};
  final loudest = meanDbById.values.reduce(math.max);
  final quietest = meanDbById.values.reduce(math.min);
  final target = math.max(quietest, loudest - maxCutDb);
  return {
    for (final e in meanDbById.entries)
      e.key: e.value - target <= 1.0 ? 1.0 : math.pow(10, (target - e.value) / 20).toDouble(),
  };
}
