import '../data/project_database.dart';
import '../models/clip_x.dart';
import 'edit_action.dart';

/// Clips shorter than this on either side of a boundary keep their hard
/// cut: a 600 ms dissolve would eat most of them.
const int autoPolishMinClipMs = 1200;

/// "Auto-polish": the finishing touches an editor would add by hand,
/// expressed as ordinary [EditAction]s so the user can see exactly what
/// was done (and undo it). Pure — reads rows, returns a plan.
///
///  * a cross-dissolve at every boundary that is still a hard cut;
///  * music that outlasts the video is ended with the video;
///  * music without fades gets a short fade-in and a longer fade-out;
///  * ducking is switched on when there is both music and clip sound.
///
/// It never overrides a choice the user already made (an existing
/// transition, an existing fade), so running it twice changes nothing.
List<EditAction> planAutoPolish({
  required List<Clip> clips,
  required AudioTrack? music,
  required bool duckMusic,
}) {
  final actions = <EditAction>[];

  for (var i = 0; i < clips.length - 1; i++) {
    if (clips[i].transitionOut != 'cut') continue;
    if (clips[i].trimmedDurationMs < autoPolishMinClipMs || clips[i + 1].trimmedDurationMs < autoPolishMinClipMs) {
      continue;
    }
    actions.add(SetTransition(ClipScope.index(i + 1), 'dissolve'));
  }

  if (music != null && clips.isNotEmpty) {
    final totalMs = clips.fold<int>(0, (sum, c) => sum + c.trimmedDurationMs);
    final musicEndMs = music.offsetMs + (music.trimEndMs - music.trimStartMs);
    if (musicEndMs > totalMs && totalMs > music.offsetMs) actions.add(const FitMusicToTimeline());

    final fadeIn = music.fadeInMs == 0 ? 800 : null;
    final fadeOut = music.fadeOutMs == 0 ? 1500 : null;
    if (fadeIn != null || fadeOut != null) actions.add(SetMusicFade(fadeInMs: fadeIn, fadeOutMs: fadeOut));

    final clipsHaveSound = clips.any((c) => !c.isPhoto && !c.muted && c.volume > 0);
    if (clipsHaveSound && !duckMusic) actions.add(const SetDucking(true));
  }

  return actions;
}
