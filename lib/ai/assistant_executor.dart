import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../data/project_database.dart';
import '../models/clip_x.dart';
import '../models/fit_mode_x.dart';
import 'auto_polish.dart';
import 'edit_action.dart';
import 'media_analysis.dart';

/// What the editor looked like when the request was made.
class AssistantContext {
  final String projectId;
  final String? selectedClipId;
  final int playheadMs;
  const AssistantContext({required this.projectId, this.selectedClipId, this.playheadMs = 0});
}

/// The outcome of one action: what happened, in words the user can read.
class ActionResult {
  final EditAction action;
  final bool ok;
  final String message;
  const ActionResult(this.action, this.ok, this.message);

  @override
  String toString() => '${ok ? 'OK' : 'SKIPPED'}: $message';
}

/// An action that can't be carried out as asked (no clip selected, nothing
/// to trim…). Reported back to the user; never a crash.
class _Refused implements Exception {
  final String reason;
  const _Refused(this.reason);
}

/// Applies [EditAction]s to the database, one at a time, each re-reading
/// the project first so a later action sees what an earlier one changed.
/// Every write goes through the same `ProjectDatabase` methods the editor's
/// own controls use, so undo/redo and autosave work with no extra code.
class AssistantExecutor {
  final ProjectDatabase db;

  /// Needed only for the analysis-driven [SmartTool]s; without one those
  /// actions are refused with a clear message.
  final MediaAnalyzer? analyzer;

  final Future<void> Function()? onUndo;
  final Future<void> Function()? onRedo;
  final String Function() _newId;

  AssistantExecutor(
    this.db, {
    this.analyzer,
    this.onUndo,
    this.onRedo,
    String Function()? newId,
  }) : _newId = newId ?? (() => const Uuid().v4());

  /// Shortest a clip may be left after a trim, in source ms (same floor as
  /// the trim handles in `TrimPanel`).
  static const int minClipMs = 200;
  static const int minPhotoMs = 500;
  static const int maxPhotoMs = 60000;

  Future<List<ActionResult>> run(List<EditAction> actions, AssistantContext ctx) async {
    final results = <ActionResult>[];
    for (final action in actions) {
      try {
        results.add(ActionResult(action, true, await _apply(action, ctx)));
      } on _Refused catch (r) {
        results.add(ActionResult(action, false, r.reason));
      } catch (e) {
        results.add(ActionResult(action, false, '${action.describe()} failed: $e'));
      }
    }
    return results;
  }

  Future<List<Clip>> _clips(AssistantContext ctx) => db.watchClips(ctx.projectId).first;

  Future<List<Clip>> _targets(ClipScope scope, AssistantContext ctx) async {
    final clips = await _clips(ctx);
    if (clips.isEmpty) throw const _Refused('There are no clips yet.');
    if (scope.all) return clips;
    final index = scope.index;
    if (index != null) {
      if (index == -1) return [clips.last];
      if (index < 1 || index > clips.length) {
        throw _Refused('There is no clip $index (the project has ${clips.length}).');
      }
      return [clips[index - 1]];
    }
    for (final c in clips) {
      if (c.id == ctx.selectedClipId) return [c];
    }
    final under = positionAt(layoutTimeline(clips), ctx.playheadMs);
    if (under != null) return [under.clip];
    throw const _Refused('Select a clip first.');
  }

  static String _count(int n) => n == 1 ? '1 clip' : '$n clips';

  Future<String> _apply(EditAction action, AssistantContext ctx) async {
    switch (action) {
      case SetSpeed():
        final videos = (await _targets(action.scope, ctx)).where((c) => !c.isPhoto).toList();
        if (videos.isEmpty) throw const _Refused('Photos have no speed to change.');
        final speed = action.speed.clamp(minClipSpeed, maxClipSpeed).toDouble();
        for (final c in videos) {
          await db.updateClip(c.copyWith(speed: speed));
        }
        return 'Set ${_count(videos.length)} to ${speed}x speed.';

      case SetMuted():
        final targets = await _targets(action.scope, ctx);
        for (final c in targets) {
          await db.updateClip(c.copyWith(muted: action.muted));
        }
        return '${action.muted ? 'Muted' : 'Unmuted'} ${_count(targets.length)}.';

      case SetVolume():
        final targets = await _targets(action.scope, ctx);
        final volume = action.volume.clamp(0.0, 1.0).toDouble();
        for (final c in targets) {
          await db.updateClip(c.copyWith(volume: volume));
        }
        return 'Set the volume of ${_count(targets.length)} to ${(volume * 100).round()}%.';

      case SetLook():
        final targets = await _targets(action.scope, ctx);
        for (final c in targets) {
          await db.updateClip(c.copyWith(look: Value(action.look), lookStrength: action.strength));
        }
        return action.look == null
            ? 'Removed the look from ${_count(targets.length)}.'
            : 'Applied the ${action.look} look to ${_count(targets.length)}.';

      case AdjustColor():
        final targets = await _targets(action.scope, ctx);
        double nudge(double v, double d) => (v + d).clamp(-1.0, 1.0).toDouble();
        for (final c in targets) {
          await db.updateClip(c.copyWith(
            brightness: nudge(c.brightness, action.brightness),
            contrast: nudge(c.contrast, action.contrast),
            saturation: nudge(c.saturation, action.saturation),
            filterPreset: const Value(null), // no longer matches a preset chip
          ));
        }
        return 'Adjusted the colour of ${_count(targets.length)}.';

      case ResetColor():
        final targets = await _targets(action.scope, ctx);
        for (final c in targets) {
          await db.updateClip(
            c.copyWith(brightness: 0, contrast: 0, saturation: 0, filterPreset: const Value(null)),
          );
        }
        return 'Reset the colour of ${_count(targets.length)}.';

      case RotateClip():
        final targets = await _targets(action.scope, ctx);
        for (final c in targets) {
          await db.updateClip(c.copyWith(turns: ((c.turns + action.quarterTurns) % 4 + 4) % 4));
        }
        return 'Rotated ${_count(targets.length)}.';

      case FlipClip():
        final targets = await _targets(action.scope, ctx);
        for (final c in targets) {
          await db.updateClip(action.horizontal ? c.copyWith(flipH: !c.flipH) : c.copyWith(flipV: !c.flipV));
        }
        return 'Flipped ${_count(targets.length)}.';

      case SetFitMode():
        final targets = await _targets(action.scope, ctx);
        final mode = normalizeFitMode(action.mode);
        for (final c in targets) {
          await db.updateClip(c.copyWith(fitMode: mode));
        }
        return 'Set ${_count(targets.length)} to $mode the frame.';

      case TrimClip():
        return _trim(action, ctx);

      case SplitAtPlayhead():
        final clips = await _clips(ctx);
        final pos = positionAt(layoutTimeline(clips), ctx.playheadMs);
        if (pos == null) throw const _Refused('There are no clips yet.');
        final offset = ctx.playheadMs - pos.startMs;
        if (offset <= 0 || offset >= pos.clip.trimmedDurationMs) {
          throw const _Refused('Move the playhead inside a clip to split it.');
        }
        await db.splitClip(pos.clip.id, pos.clip.timelineToSourceOffsetMs(offset), _newId());
        return 'Split the clip at the playhead.';

      case DeleteClips():
        final targets = await _targets(action.scope, ctx);
        for (final c in targets) {
          await db.deleteClipAndReindex(ctx.projectId, c.id);
        }
        return 'Deleted ${_count(targets.length)}.';

      case DuplicateClips():
        final targets = await _targets(action.scope, ctx);
        for (final c in targets) {
          await db.duplicateClip(c.id, newClipId: _newId());
        }
        return 'Duplicated ${_count(targets.length)}.';

      case SetTransition():
        if (action.scope.all) {
          final clips = await _clips(ctx);
          if (clips.length < 2) throw const _Refused('Transitions need at least two clips.');
          await db.applyTransitionToAllClips(ctx.projectId, action.transition);
          return 'Set every transition to ${action.transition}.';
        }
        final clips = await _clips(ctx);
        final target = (await _targets(action.scope, ctx)).single;
        if (clips.isNotEmpty && clips.last.id == target.id) {
          throw const _Refused('The last clip has no next clip to transition into.');
        }
        await db.updateClip(target.copyWith(transitionOut: action.transition));
        return 'Set the transition after clip ${target.orderIndex + 1} to ${action.transition}.';

      case AddText():
        final clips = await _clips(ctx);
        final totalMs = clips.fold<int>(0, (sum, c) => sum + c.trimmedDurationMs);
        final spanMs = totalMs > 0 ? totalMs : 5000;
        final startMs = ctx.playheadMs.clamp(0, math.max(0, spanMs - 100)).toInt();
        await db.insertTextOverlay(TextOverlaysCompanion.insert(
          id: _newId(),
          projectId: ctx.projectId,
          content: action.content,
          startMs: Value(startMs),
          endMs: math.min(startMs + 3000, spanMs),
        ));
        return 'Added the text "${action.content}".';

      case SetAspectRatio():
        if (action.aspectRatio < 0.4 || action.aspectRatio > 2.5) {
          throw _Refused('${action.label} is outside the supported frame shapes.');
        }
        await db.setAspectRatio(ctx.projectId, action.aspectRatio);
        return 'Changed the frame to ${action.label}.';

      case SetMusicVolume():
        final track = await _music(ctx);
        await db.updateAudioTrack(track.copyWith(volume: action.volume.clamp(0.0, 1.0).toDouble()));
        return 'Set the music volume to ${(action.volume * 100).round()}%.';

      case SetMusicFade():
        final track = await _music(ctx);
        final cap = (track.trimEndMs - track.trimStartMs) ~/ 2; // in/out must not overlap
        final fadeIn = action.fadeInMs == null ? track.fadeInMs : action.fadeInMs!.clamp(0, cap).toInt();
        final fadeOut = action.fadeOutMs == null ? track.fadeOutMs : action.fadeOutMs!.clamp(0, cap).toInt();
        await db.updateAudioTrack(track.copyWith(fadeInMs: fadeIn, fadeOutMs: fadeOut));
        return 'Set the music fades (in ${fadeIn / 1000} s, out ${fadeOut / 1000} s).';

      case FitMusicToTimeline():
        final track = await _music(ctx);
        final clips = await _clips(ctx);
        final totalMs = clips.fold<int>(0, (sum, c) => sum + c.trimmedDurationMs);
        final room = totalMs - track.offsetMs;
        if (room <= 0) throw const _Refused('The music starts after the video ends.');
        final newEnd = math.min(track.trimEndMs, track.trimStartMs + room);
        if (newEnd == track.trimEndMs) return 'The music already ends with the video.';
        final cap = (newEnd - track.trimStartMs) ~/ 2;
        await db.updateAudioTrack(track.copyWith(
          trimEndMs: newEnd,
          fadeInMs: math.min(track.fadeInMs, cap),
          fadeOutMs: math.min(track.fadeOutMs, cap),
        ));
        return 'Ended the music with the video.';

      case RemoveMusic():
        final track = await _music(ctx);
        await db.deleteAudioTrack(track.id);
        return 'Removed the music.';

      case SetDucking():
        await db.setDuckMusic(ctx.projectId, action.enabled);
        return action.enabled
            ? 'Music will dip under clip sound in the exported video.'
            : 'Turned music ducking off.';

      case RunSmartTool():
        return _smart(action, ctx);

      case UndoEdit():
        if (onUndo == null) throw const _Refused('Undo is not available here.');
        await onUndo!();
        return 'Undid the last edit.';

      case RedoEdit():
        if (onRedo == null) throw const _Refused('Redo is not available here.');
        await onRedo!();
        return 'Redid the last edit.';

      case ClipAction():
        // Unreachable: every concrete ClipAction is handled above. Kept so
        // a new subclass fails loudly here instead of being ignored.
        throw _Refused('${action.describe()} is not supported yet.');
    }
  }

  Future<AudioTrack> _music(AssistantContext ctx) async {
    final track = await db.getAudioTrack(ctx.projectId);
    if (track == null) throw const _Refused('This project has no music yet.');
    return track;
  }

  Future<String> _trim(TrimClip action, AssistantContext ctx) async {
    if (action.ms <= 0) throw const _Refused('Say how much to trim, e.g. "2 seconds".');
    final targets = await _targets(action.scope, ctx);
    var changed = 0;
    for (final c in targets) {
      if (c.isPhoto) {
        final current = c.trimmedDurationMs;
        final next = action.kind == TrimKind.keepFirst ? action.ms : current - action.ms;
        if (next < minPhotoMs && action.kind != TrimKind.keepFirst) continue;
        await db.setPhotoDuration(c.id, next.clamp(minPhotoMs, maxPhotoMs).toInt());
        changed++;
        continue;
      }
      final sourceMs = c.timelineToSourceOffsetMs(action.ms);
      var start = c.trimStartMs;
      var end = c.trimEndMs;
      switch (action.kind) {
        case TrimKind.removeStart:
          start += sourceMs;
        case TrimKind.removeEnd:
          end -= sourceMs;
        case TrimKind.keepFirst:
          end = math.min(end, start + sourceMs);
      }
      if (end - start < minClipMs) continue; // would leave nothing
      if (start == c.trimStartMs && end == c.trimEndMs) continue; // already that short
      await db.updateClip(c.copyWith(trimStartMs: start, trimEndMs: end));
      changed++;
    }
    if (changed == 0) {
      throw const _Refused('That trim would leave nothing (or the clip is already that short).');
    }
    return 'Trimmed ${_count(changed)}.';
  }

  // --- smart tools --------------------------------------------------------

  Future<String> _smart(RunSmartTool action, AssistantContext ctx) async {
    if (action.tool == SmartTool.autoPolish) {
      final project = await db.getProject(ctx.projectId);
      final plan = planAutoPolish(
        clips: await _clips(ctx),
        music: await db.getAudioTrack(ctx.projectId),
        duckMusic: project?.duckMusic ?? false,
      );
      if (plan.isEmpty) return 'Nothing to polish — transitions and music fades are already set.';
      final results = await run(plan, ctx);
      final done = results.where((r) => r.ok).length;
      final transitions = plan.whereType<SetTransition>().length;
      return 'Polished the project: $done change${done == 1 ? '' : 's'}'
          '${transitions > 0 ? ' ($transitions dissolve${transitions == 1 ? '' : 's'} added)' : ''}.';
    }

    final analyzer = this.analyzer;
    if (analyzer == null) throw const _Refused('Media analysis is not available on this device.');

    final videos = (await _targets(action.scope, ctx)).where((c) => !c.isPhoto).toList();
    if (videos.isEmpty) throw const _Refused('This works on video clips, not photos.');

    switch (action.tool) {
      case SmartTool.removeSilences:
        var removedMs = 0;
        var touched = 0;
        for (final c in videos) {
          final span = c.sourceSpanMs;
          final log = await analyzer.analyze(silenceDetectArgs(c.sourceUri, c.trimStartMs, c.trimEndMs));
          final keeps = keepRanges(parseSilences(log, totalMs: span), span);
          final keptMs = keeps.fold<int>(0, (sum, r) => sum + (r.$2 - r.$1));
          if (keeps.isEmpty || keptMs >= span) continue; // all silent, or nothing to cut
          await db.replaceClipWithSegments(
            c.id,
            [for (final (s, e) in keeps) (c.trimStartMs + s, c.trimStartMs + e)],
            newId: _newId,
          );
          removedMs += span - keptMs;
          touched++;
        }
        if (touched == 0) return 'No silent parts found.';
        return 'Removed ${(removedMs / 1000).toStringAsFixed(1)} s of silence from ${_count(touched)}.';

      case SmartTool.splitScenes:
        var pieces = 0;
        for (final c in videos) {
          final span = c.sourceSpanMs;
          final log = await analyzer.analyze(sceneDetectArgs(c.sourceUri, c.trimStartMs, c.trimEndMs));
          final segments = segmentsFromCuts(parseSceneTimesMs(log), span);
          if (segments.length < 2) continue;
          await db.replaceClipWithSegments(
            c.id,
            [for (final (s, e) in segments) (c.trimStartMs + s, c.trimStartMs + e)],
            newId: _newId,
          );
          pieces += segments.length;
        }
        if (pieces == 0) return 'No scene changes found.';
        return 'Split into $pieces clips at scene changes.';

      case SmartTool.balanceLoudness:
        final audible = videos.where((c) => !c.muted).toList();
        final means = <String, double>{};
        for (final c in audible) {
          final log = await analyzer.analyze(volumeDetectArgs(c.sourceUri, c.trimStartMs, c.trimEndMs));
          final mean = parseMeanVolumeDb(log);
          if (mean != null) means[c.id] = mean;
        }
        if (means.length < 2) throw const _Refused('Balancing needs at least two clips with sound.');
        final gains = balanceGains(means);
        var changed = 0;
        for (final c in audible) {
          final gain = gains[c.id];
          if (gain == null || (gain - c.volume).abs() < 0.01) continue;
          await db.updateClip(c.copyWith(volume: gain));
          changed++;
        }
        return changed == 0
            ? 'The clips are already at a similar loudness.'
            : 'Balanced loudness: adjusted ${_count(changed)}.';

      case SmartTool.autoPolish:
        throw StateError('handled above');
    }
  }
}
