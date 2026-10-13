import '../data/project_database.dart';

extension ClipTiming on Clip {
  int get trimmedDurationMs => trimEndMs - trimStartMs;
}

/// Where a clip sits on the overall (trimmed) timeline: [startMs, endMs),
/// measured from the very start of the timeline (clip 0's trimmed start
/// is always 0). Used to convert a playhead position into "which clip,
/// and how far into it" and vice versa.
class TimelinePosition {
  final Clip clip;
  final int startMs;
  final int endMs;

  const TimelinePosition(this.clip, this.startMs, this.endMs);

  bool contains(int playheadMs) => playheadMs >= startMs && playheadMs < endMs;
}

/// Lays clips out end-to-end in their current order. Must be recomputed
/// whenever the clip list changes (reorder, trim, split, delete) — it is
/// cheap (O(n)) so callers just call it fresh each build rather than
/// caching it.
List<TimelinePosition> layoutTimeline(List<Clip> clips) {
  var cursor = 0;
  final result = <TimelinePosition>[];
  for (final clip in clips) {
    final duration = clip.trimmedDurationMs;
    result.add(TimelinePosition(clip, cursor, cursor + duration));
    cursor += duration;
  }
  return result;
}

/// Finds which clip the playhead currently sits over, or null if the
/// timeline is empty. Clamps to the last clip if [playheadMs] runs past
/// the end (e.g. right after a trim shortens the current clip).
TimelinePosition? positionAt(List<TimelinePosition> layout, int playheadMs) {
  if (layout.isEmpty) return null;
  for (final pos in layout) {
    if (pos.contains(playheadMs)) return pos;
  }
  return playheadMs < layout.first.startMs ? layout.first : layout.last;
}

// --- F4: playhead tools ------------------------------------------------
//
// Pure helpers (no Flutter, no providers) so the maths is unit-tested. All
// times are ms on the trimmed timeline, the same axis as `playheadMsProvider`.

/// Frame rate used for single-frame stepping and the timecode readout. Matches
/// the default export rate; it is a UI convention, not the source clip's rate.
const int playheadFps = 30;

/// Every clip boundary on the timeline, ascending: each clip's start plus the
/// end of the last clip. Empty for an empty timeline.
List<int> clipBoundariesMs(List<TimelinePosition> layout) {
  if (layout.isEmpty) return const [];
  return [for (final p in layout) p.startMs, layout.last.endMs];
}

/// The closest boundary strictly before [playheadMs] ("previous clip"). From
/// the middle of a clip this is that clip's own start, like a media player's
/// previous button. Stays at the first boundary (0) when already there.
/// [boundaries] must be ascending, as returned by [clipBoundariesMs].
int previousBoundaryMs(List<int> boundaries, int playheadMs) {
  if (boundaries.isEmpty) return 0;
  var best = boundaries.first;
  for (final b in boundaries) {
    if (b < playheadMs) {
      best = b;
    } else {
      break;
    }
  }
  return best;
}

/// The closest boundary strictly after [playheadMs] ("next clip"). From inside
/// the last clip that is the end of the timeline; at the end it stays there.
int nextBoundaryMs(List<int> boundaries, int playheadMs) {
  if (boundaries.isEmpty) return 0;
  for (final b in boundaries) {
    if (b > playheadMs) return b;
  }
  return boundaries.last;
}

/// Moves [playheadMs] by [frames] whole frames (negative = back), landing on
/// a frame boundary and clamped to [0, totalMs]. Counting in frames rather
/// than adding 33 ms keeps repeated steps from drifting (1000/30 is not whole).
int stepFrameMs(int playheadMs, int frames, int totalMs, {int fps = playheadFps}) {
  if (totalMs <= 0) return 0;
  final frame = (playheadMs * fps / 1000).round() + frames;
  return (frame * 1000 / fps).round().clamp(0, totalMs).toInt();
}

/// Returns the boundary within [thresholdMs] of [ms] (the nearest one if
/// several), or [ms] unchanged when none is close enough or there are none.
int snapToBoundaryMs(List<int> boundaries, int ms, int thresholdMs) {
  var best = ms;
  var bestDistance = thresholdMs + 1;
  for (final b in boundaries) {
    final distance = (b - ms).abs();
    if (distance <= thresholdMs && distance < bestDistance) {
      best = b;
      bestDistance = distance;
    }
  }
  return best;
}

/// `m:ss:ff` (minutes, seconds, frame within the second), e.g. 3 s 400 ms at
/// 30 fps -> `0:03:12`.
String formatTimecode(int ms, {int fps = playheadFps}) {
  final totalFrames = ((ms < 0 ? 0 : ms) * fps / 1000).round();
  final frames = totalFrames % fps;
  final totalSeconds = totalFrames ~/ fps;
  final seconds = totalSeconds % 60;
  final minutes = totalSeconds ~/ 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}:${frames.toString().padLeft(2, '0')}';
}
