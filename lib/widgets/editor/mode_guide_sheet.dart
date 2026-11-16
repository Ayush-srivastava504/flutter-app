import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/edit_mode.dart';
import '../common/ui_kit.dart';

/// The short "how this mode works" guide. Shown automatically the first time
/// a project of each mode is opened, and from the dock's Tips button.
Future<void> showModeGuide(BuildContext context, EditMode mode) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _ModeGuide(mode: mode),
  );
}

const Map<EditMode, List<(IconData, String, String)>> _tips = {
  EditMode.youtube: [
    (Icons.crop_16_9, 'Frame stays 16:9', 'Vertical clips are fitted inside it. Open a clip\'s Trim tab to switch Fit, Fill or Blur.'),
    (Icons.record_voice_over_outlined, 'Enhance speech', 'Less background noise and a clearer, more even voice — on one clip or all. Heard in the export.'),
    (Icons.graphic_eq, 'Jump cuts', 'Removes the silent pauses from talking-head clips — on one clip or all of them.'),
    (Icons.format_list_numbered, 'Chapters', 'Clips of 10 s or more become chapters. A text title inside a chapter names it. Copy the list into your description.'),
    (Icons.volume_down_outlined, 'Ducking', 'Turn it on and the music dips whenever your clips have sound (applied in the export).'),
    (Icons.grid_on_outlined, 'Safe zones', 'Thirds and title-safe lines on the preview, so titles never get cut off.'),
  ],
  EditMode.insta: [
    (Icons.crop_portrait, 'Frame stays 9:16', 'Horizontal clips are fitted. Open a clip\'s Trim tab and pick Fill or Blur to cover the whole screen.'),
    (Icons.title, 'Mind the bottom', 'The app you post to puts its buttons and caption low on the screen — keep titles in the upper two-thirds.'),
    (Icons.music_note_outlined, 'Cut to the music', 'Add a song first, then trim clips so cuts land on the beat.'),
    (Icons.ios_share_outlined, 'Export', '1080p at 30 fps is the sweet spot for vertical video.'),
  ],
  EditMode.normal: [
    (Icons.aspect_ratio, 'Frame shape', 'Your first video picks it. Change it any time with the frame button at the top.'),
    (Icons.touch_app_outlined, 'Tap a clip', 'Trim, split at the playhead, change speed, rotate, or open Filters for looks.'),
    (Icons.auto_awesome, 'Just ask', 'Tap ✨ and type what you want, like "make clip 2 black and white".'),
  ],
};

class _ModeGuide extends StatelessWidget {
  final EditMode mode;
  const _ModeGuide({required this.mode});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: mode.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(mode.icon, color: mode.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(mode.label, style: Theme.of(context).textTheme.titleLarge)),
                    if (mode.isPro) ...[const SizedBox(width: 8), const ProBadge()],
                  ]),
                  Text(mode.tagline, style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            for (final (icon, title, body) in _tips[mode]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(icon, size: 20, color: mode.isPro ? AppColors.pro : AppColors.ember),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(body, style: const TextStyle(color: AppColors.textDim, height: 1.35)),
                    ]),
                  ),
                ]),
              ),
            const SizedBox(height: 4),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
          ],
        ),
      ),
    );
  }
}
