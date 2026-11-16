/// F12: a minimal, forgiving `.srt` (SubRip) subtitle parser. Pure Dart,
/// no file I/O — `editor_screen.dart`'s subtitle-import flow reads the
/// picked file's text itself and hands it to [parseSrt]; this file only
/// turns text into entries, so it's directly unit-testable
/// (`test/srt_parser_test.dart`) without a file picker or a database.
library srt_parser;

class SrtEntry {
  final int startMs;
  final int endMs;
  final String text;

  const SrtEntry({required this.startMs, required this.endMs, required this.text});
}

/// `HH:MM:SS,mmm --> HH:MM:SS,mmm` (SubRip's standard comma separator;
/// also accepts a period, which some generators use instead).
final RegExp _timeLine = RegExp(
  r'(\d{1,2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{1,2}):(\d{2}):(\d{2})[,.](\d{3})',
);

/// Parses [srt] into entries, in file order, skipping any block that
/// doesn't look like a valid cue rather than throwing — subtitle files
/// found online are often slightly malformed (a missing index number, a
/// stray blank line, a leading BOM), and importing the 90% of a file
/// that parses cleanly beats refusing all of it over one bad cue.
List<SrtEntry> parseSrt(String srt) {
  final cleaned = srt
      .replaceFirst('\uFEFF', '') // a leading UTF-8 BOM, if present
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
  final blocks = cleaned.split(RegExp(r'\n\s*\n'));
  final entries = <SrtEntry>[];

  for (final block in blocks) {
    final lines = block.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) continue;

    // The index line (a bare cue number) is optional and ignored here —
    // only the timestamp line's position matters, wherever it is.
    final timeLineIndex = lines.indexWhere((l) => _timeLine.hasMatch(l));
    if (timeLineIndex == -1) continue;

    final match = _timeLine.firstMatch(lines[timeLineIndex])!;
    final startMs = _toMs(match, 1);
    final endMs = _toMs(match, 5);
    if (endMs <= startMs) continue; // malformed or zero-length cue

    final text = lines.sublist(timeLineIndex + 1).join('\n').trim();
    if (text.isEmpty) continue;

    entries.add(SrtEntry(startMs: startMs, endMs: endMs, text: text));
  }
  return entries;
}

/// Converts the 4 capture groups starting at [g] (hours, minutes,
/// seconds, milliseconds) into a single millisecond offset.
int _toMs(Match m, int g) {
  final h = int.parse(m.group(g)!);
  final min = int.parse(m.group(g + 1)!);
  final s = int.parse(m.group(g + 2)!);
  final ms = int.parse(m.group(g + 3)!);
  return ((h * 3600 + min * 60 + s) * 1000) + ms;
}
