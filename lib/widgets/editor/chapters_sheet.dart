import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../app/app_theme.dart';
import '../../models/youtube_chapters.dart';

/// YouTube Studio → Chapters: shows the chapter list built from the timeline
/// and copies it for the video description.
Future<void> showChaptersSheet(
  BuildContext context, {
  required List<int> clipStartsMs,
  required int totalMs,
  required List<(int, String)> titles,
}) {
  final chapters = buildChapters(clipStartsMs: clipStartsMs, totalMs: totalMs, titles: titles);
  final ok = meetsYoutubeChapterRules(chapters, totalMs);
  final text = formatChapterList(chapters, totalMs);
  final withHours = totalMs >= 3600 * 1000;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            Text('Chapters', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Built from your clips. Clips under 10 s join the chapter before them; '
              'a text title inside a chapter becomes its name.',
              style: TextStyle(color: AppColors.textDim, height: 1.35),
            ),
            const SizedBox(height: 16),
            if (chapters.isEmpty)
              const Text('Add clips to the timeline first.', style: TextStyle(color: AppColors.textFaint))
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  for (final c in chapters)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      child: Row(children: [
                        SizedBox(
                          width: withHours ? 72 : 52,
                          child: Text(
                            formatChapterTime(c.startMs, withHours: withHours),
                            style: const TextStyle(
                                color: AppColors.pro, fontFeatures: [FontFeature.tabularFigures()], fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(child: Text(c.title, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                ]),
              ),
            const SizedBox(height: 12),
            if (chapters.isNotEmpty)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(ok ? Icons.check_circle_outline : Icons.info_outline,
                    size: 18, color: ok ? AppColors.ok : AppColors.warn),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ok
                        ? 'Ready — YouTube will show these as chapters.'
                        : 'YouTube needs at least $youtubeMinChapters chapters of 10 s or more. '
                            'Add or lengthen clips, then check again.',
                    style: TextStyle(color: ok ? AppColors.ok : AppColors.warn, fontSize: 13),
                  ),
                ),
              ]),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: chapters.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Chapters copied — paste them into your description.')));
                      }
                    },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy for description'),
            ),
          ],
        ),
      ),
    ),
  );
}
