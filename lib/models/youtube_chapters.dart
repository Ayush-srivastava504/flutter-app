/// YouTube chapters (Pro toolkit): turns the timeline's clip boundaries into
/// the "0:00 Intro / 1:42 Setup …" list YouTube reads from a description.
///
/// YouTube only shows chapters when the list starts at 0:00, has at least
/// [youtubeMinChapters] entries, and every chapter is at least
/// [youtubeMinChapterMs] long — [buildChapters] merges short clips so the
/// result satisfies the last two rules whenever the video is long enough.
library;

const int youtubeMinChapterMs = 10000;
const int youtubeMinChapters = 3;

class ChapterMark {
  final int startMs;
  final String title;
  const ChapterMark(this.startMs, this.title);

  @override
  bool operator ==(Object other) => other is ChapterMark && other.startMs == startMs && other.title == title;

  @override
  int get hashCode => Object.hash(startMs, title);

  @override
  String toString() => 'ChapterMark($startMs, $title)';
}

/// [clipStartsMs]: timeline start of every clip. [titles]: (startMs, text)
/// of text overlays — the first one inside a chapter names it.
List<ChapterMark> buildChapters({
  required List<int> clipStartsMs,
  required int totalMs,
  List<(int, String)> titles = const [],
  int minChapterMs = youtubeMinChapterMs,
}) {
  if (totalMs <= 0) return const [];
  final candidates = {0, ...clipStartsMs.where((s) => s > 0 && s < totalMs)}.toList()..sort();
  final starts = <int>[];
  for (final s in candidates) {
    if (starts.isNotEmpty && s - starts.last < minChapterMs) continue;
    if (s > 0 && totalMs - s < minChapterMs) break; // last chapter would be too short
    starts.add(s);
  }

  final sortedTitles = [...titles]..sort((a, b) => a.$1.compareTo(b.$1));
  return [
    for (var i = 0; i < starts.length; i++)
      ChapterMark(
        starts[i],
        _titleFor(starts[i], i + 1 < starts.length ? starts[i + 1] : totalMs, sortedTitles) ??
            (i == 0 ? 'Intro' : 'Part ${i + 1}'),
      ),
  ];
}

String? _titleFor(int from, int to, List<(int, String)> titles) {
  for (final (start, text) in titles) {
    if (start < from || start >= to) continue;
    final line = text.split('\n').map((l) => l.trim()).firstWhere((l) => l.isNotEmpty, orElse: () => '');
    if (line.isEmpty || line == 'Tap to edit') continue;
    return line.length > 48 ? '${line.substring(0, 47)}…' : line;
  }
  return null;
}

/// True when YouTube will turn [chapters] into chapters on the video.
bool meetsYoutubeChapterRules(List<ChapterMark> chapters, int totalMs) {
  if (chapters.length < youtubeMinChapters || chapters.first.startMs != 0) return false;
  for (var i = 0; i < chapters.length; i++) {
    final end = i + 1 < chapters.length ? chapters[i + 1].startMs : totalMs;
    if (end - chapters[i].startMs < youtubeMinChapterMs) return false;
  }
  return true;
}

/// `m:ss`, or `h:mm:ss` when the video is an hour or longer.
String formatChapterTime(int ms, {required bool withHours}) {
  final s = ms ~/ 1000;
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  final ss = sec.toString().padLeft(2, '0');
  return withHours ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '${h * 60 + m}:$ss';
}

/// The text to paste into the video description.
String formatChapterList(List<ChapterMark> chapters, int totalMs) {
  final withHours = totalMs >= 3600 * 1000;
  return chapters.map((c) => '${formatChapterTime(c.startMs, withHours: withHours)} ${c.title}').join('\n');
}
