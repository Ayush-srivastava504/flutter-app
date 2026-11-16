import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/models/srt_parser.dart';

/// Tests for F12 (subtitle import).
void main() {
  test('parses a well-formed two-cue file', () {
    const srt = '''
1
00:00:01,000 --> 00:00:04,000
Hello world

2
00:00:05,500 --> 00:00:07,250
Second line
''';
    final entries = parseSrt(srt);
    expect(entries.length, 2);
    expect(entries[0].startMs, 1000);
    expect(entries[0].endMs, 4000);
    expect(entries[0].text, 'Hello world');
    expect(entries[1].startMs, 5500);
    expect(entries[1].endMs, 7250);
  });

  test('joins a multi-line cue\'s text with newlines', () {
    const srt = '''
1
00:00:00,000 --> 00:00:02,000
Line one
Line two
''';
    final entries = parseSrt(srt);
    expect(entries.single.text, 'Line one\nLine two');
  });

  test('tolerates a leading UTF-8 BOM', () {
    final entries = parseSrt('\uFEFF1\n00:00:00,000 --> 00:00:01,000\nHi\n');
    expect(entries.single.text, 'Hi');
  });

  test('tolerates CRLF line endings', () {
    final entries =
        parseSrt('1\r\n00:00:00,000 --> 00:00:01,000\r\nHi\r\n\r\n2\r\n00:00:02,000 --> 00:00:03,000\r\nBye\r\n');
    expect(entries.length, 2);
    expect(entries[0].text, 'Hi');
    expect(entries[1].text, 'Bye');
  });

  test('accepts a period instead of a comma before milliseconds', () {
    final entries = parseSrt('00:00:00.000 --> 00:00:01.000\nHi\n');
    expect(entries.single.text, 'Hi');
  });

  test('skips a block with no timestamp line instead of throwing', () {
    const srt = '''
Not a real cue, just stray text

1
00:00:00,000 --> 00:00:01,000
Real cue
''';
    expect(() => parseSrt(srt), returnsNormally);
    final entries = parseSrt(srt);
    expect(entries.length, 1);
    expect(entries.single.text, 'Real cue');
  });

  test('skips a cue whose end time is not after its start time', () {
    const srt = '''
1
00:00:05,000 --> 00:00:05,000
Zero length, skipped

2
00:00:05,000 --> 00:00:04,000
Backwards, skipped

3
00:00:01,000 --> 00:00:02,000
Kept
''';
    final entries = parseSrt(srt);
    expect(entries.length, 1);
    expect(entries.single.text, 'Kept');
  });

  test('skips a cue with an empty text body', () {
    const srt = '''
1
00:00:00,000 --> 00:00:01,000

2
00:00:02,000 --> 00:00:03,000
Not empty
''';
    final entries = parseSrt(srt);
    expect(entries.length, 1);
    expect(entries.single.text, 'Not empty');
  });

  test('entries come back in file order', () {
    const srt = '''
1
00:00:10,000 --> 00:00:11,000
Third chronologically but first in the file

2
00:00:01,000 --> 00:00:02,000
First chronologically but second in the file
''';
    final entries = parseSrt(srt);
    expect(entries[0].startMs, 10000);
    expect(entries[1].startMs, 1000);
  });

  test('an empty or whitespace-only file parses to no entries', () {
    expect(parseSrt(''), isEmpty);
    expect(parseSrt('   \n\n   '), isEmpty);
  });

  test('hour/minute/second math is correct, not just the millisecond part', () {
    final entries = parseSrt('00:01:02,003 --> 01:02:03,004\nHi\n');
    // 1*60000 + 2*1000 + 3 = 62003
    expect(entries.single.startMs, 62003);
    // 1*3600000 + 2*60000 + 3*1000 + 4 = 3723004
    expect(entries.single.endMs, 3723004);
  });
}
