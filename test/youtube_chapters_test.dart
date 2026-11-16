import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/models/edit_mode.dart';
import 'package:video_editor_app/models/youtube_chapters.dart';

void main() {
  group('buildChapters', () {
    test('one chapter per clip when every clip is long enough', () {
      final c = buildChapters(clipStartsMs: [0, 20000, 45000], totalMs: 70000);
      expect(c, const [ChapterMark(0, 'Intro'), ChapterMark(20000, 'Part 2'), ChapterMark(45000, 'Part 3')]);
      expect(meetsYoutubeChapterRules(c, 70000), isTrue);
    });

    test('short clips are merged into the chapter before them', () {
      final c = buildChapters(clipStartsMs: [0, 4000, 8000, 15000, 30000], totalMs: 50000);
      expect(c.map((m) => m.startMs), [0, 15000, 30000]);
    });

    test('a final chapter shorter than 10 s is dropped', () {
      final c = buildChapters(clipStartsMs: [0, 20000, 40000, 45000], totalMs: 48000);
      expect(c.map((m) => m.startMs), [0, 20000]);
      expect(meetsYoutubeChapterRules(c, 48000), isFalse, reason: 'needs three chapters');
    });

    test('text overlays name the chapter they start in', () {
      final c = buildChapters(
        clipStartsMs: [0, 20000, 45000],
        totalMs: 70000,
        titles: [(46000, 'Final thoughts\nsecond line'), (21000, 'Tap to edit'), (25000, ' The setup ')],
      );
      expect(c.map((m) => m.title), ['Intro', 'The setup', 'Final thoughts']);
    });

    test('empty timeline has no chapters', () {
      expect(buildChapters(clipStartsMs: const [], totalMs: 0), isEmpty);
    });
  });

  test('formatChapterList uses m:ss, or h:mm:ss for videos of an hour or more', () {
    const chapters = [ChapterMark(0, 'Intro'), ChapterMark(754000, 'Deep dive')];
    expect(formatChapterList(chapters, 900000), '0:00 Intro\n12:34 Deep dive');
    expect(formatChapterList(chapters, 3600000), '0:00:00 Intro\n0:12:34 Deep dive');
  });

  test('EditMode.fromName falls back to Quick Edit', () {
    expect(EditMode.fromName('youtube'), EditMode.youtube);
    expect(EditMode.fromName(null), EditMode.normal);
    expect(EditMode.fromName('bogus'), EditMode.normal);
    expect(EditMode.youtube.lockedAspect, 16 / 9);
    expect(EditMode.insta.lockedAspect, 9 / 16);
    expect(EditMode.normal.lockedAspect, isNull);
  });
}
