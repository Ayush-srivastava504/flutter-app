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
