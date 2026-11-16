/// The assistant's vocabulary: every edit it can make, as plain data.
///
/// A planner (the on-device rule-based one in `command_planner.dart`, or
/// any future one) turns a request into a list of these; `AssistantExecutor`
/// applies them to the database. Keeping the two apart means a planner can
/// never do anything the editor's own controls can't, and every action is
/// undoable through the normal project history.
library edit_action;

/// Which clip(s) an action applies to.
class ClipScope {
  /// Every clip in the project.
  final bool all;

  /// 1-based clip number; -1 means the last clip. Null (with [all] false)
  /// means "the selected clip, or the one under the playhead".
  final int? index;

  const ClipScope.selected()
      : all = false,
        index = null;
  const ClipScope.all()
      : all = true,
        index = null;
  const ClipScope.index(int this.index) : all = false;

  String get label {
    if (all) return 'all clips';
    if (index == null) return 'the selected clip';
    return index == -1 ? 'the last clip' : 'clip $index';
  }

  @override
  bool operator ==(Object other) => other is ClipScope && other.all == all && other.index == index;

  @override
  int get hashCode => Object.hash(all, index);

  @override
  String toString() => 'ClipScope($label)';
}

/// Analysis-driven tools that need to read the media, not just the rows.
enum SmartTool { removeSilences, splitScenes, balanceLoudness, autoPolish }

sealed class EditAction {
  const EditAction();

  /// One short human-readable line, shown as the plan before/after it runs.
  String describe();

  @override
  String toString() => describe();
}

abstract class ClipAction extends EditAction {
  final ClipScope scope;
  const ClipAction(this.scope);
}

class SetSpeed extends ClipAction {
  final double speed;
  const SetSpeed(super.scope, this.speed);
  @override
  String describe() => 'Set speed of ${scope.label} to ${_num(speed)}x';
}

class SetMuted extends ClipAction {
  final bool muted;
  const SetMuted(super.scope, this.muted);
  @override
  String describe() => '${muted ? 'Mute' : 'Unmute'} ${scope.label}';
}

class SetVolume extends ClipAction {
  /// 0.0–1.0
  final double volume;
  const SetVolume(super.scope, this.volume);
  @override
  String describe() => 'Set volume of ${scope.label} to ${(volume * 100).round()}%';
}

class SetLook extends ClipAction {
  /// A `lookPresets` id, or null to remove the look.
  final String? look;

  /// 0..1, how strongly the look is applied.
  final double strength;
  const SetLook(super.scope, this.look, {this.strength = 1.0});
  @override
  String describe() => look == null
      ? 'Remove the look from ${scope.label}'
      : 'Apply the $look look${strength < 1 ? ' at ${(strength * 100).round()}%' : ''} to ${scope.label}';
}

/// Relative nudge to brightness/contrast/saturation (each -1..1).
class AdjustColor extends ClipAction {
  final double brightness;
  final double contrast;
  final double saturation;
  const AdjustColor(super.scope, {this.brightness = 0, this.contrast = 0, this.saturation = 0});
  @override
  String describe() {
    final parts = <String>[
      if (brightness != 0) 'brightness ${_signed(brightness)}',
      if (contrast != 0) 'contrast ${_signed(contrast)}',
      if (saturation != 0) 'saturation ${_signed(saturation)}',
    ];
    return 'Adjust ${parts.join(', ')} on ${scope.label}';
  }
}

class ResetColor extends ClipAction {
  const ResetColor(super.scope);
  @override
  String describe() => 'Reset colour adjustments on ${scope.label}';
}

class RotateClip extends ClipAction {
  /// Quarter-turns clockwise to add (negative = counter-clockwise).
  final int quarterTurns;
  const RotateClip(super.scope, this.quarterTurns);
  @override
  String describe() => 'Rotate ${scope.label} by ${quarterTurns * 90}°';
}

class FlipClip extends ClipAction {
  final bool horizontal;
  const FlipClip(super.scope, {required this.horizontal});
  @override
  String describe() => 'Flip ${scope.label} ${horizontal ? 'horizontally' : 'vertically'}';
}

class SetFitMode extends ClipAction {
  final String mode;
  const SetFitMode(super.scope, this.mode);
  @override
  String describe() => 'Set ${scope.label} to $mode the frame';
}

/// Which part of a clip a [TrimClip] removes or keeps.
enum TrimKind {
  /// Remove [TrimClip.ms] from the start.
  removeStart,

  /// Remove [TrimClip.ms] from the end.
  removeEnd,

  /// Keep only the first [TrimClip.ms] (for a photo: show it this long).
  keepFirst,
}

/// [ms] is timeline time (what the user sees), not source time.
class TrimClip extends ClipAction {
  final TrimKind kind;
  final int ms;
  const TrimClip(super.scope, this.kind, this.ms);
  @override
  String describe() {
    final s = _num(ms / 1000);
    switch (kind) {
      case TrimKind.removeStart:
        return 'Trim $s s off the start of ${scope.label}';
      case TrimKind.removeEnd:
        return 'Trim $s s off the end of ${scope.label}';
      case TrimKind.keepFirst:
        return 'Shorten ${scope.label} to $s s';
    }
  }
}

class SplitAtPlayhead extends EditAction {
  const SplitAtPlayhead();
  @override
  String describe() => 'Split the clip at the playhead';
}

class DeleteClips extends ClipAction {
  const DeleteClips(super.scope);
  @override
  String describe() => 'Delete ${scope.label}';
}

class DuplicateClips extends ClipAction {
  const DuplicateClips(super.scope);
  @override
  String describe() => 'Duplicate ${scope.label}';
}

class SetTransition extends ClipAction {
  /// A `transitionOptions` id.
  final String transition;
  const SetTransition(super.scope, this.transition);
  @override
  String describe() => scope.all
      ? 'Use the $transition transition between all clips'
      : 'Use the $transition transition after ${scope.label}';
}

class AddText extends EditAction {
  final String content;
  const AddText(this.content);
  @override
  String describe() => 'Add text "$content" at the playhead';
}

class SetAspectRatio extends EditAction {
  final double aspectRatio;
  final String label;
  const SetAspectRatio(this.aspectRatio, this.label);
  @override
  String describe() => 'Change the frame to $label';
}

class SetMusicVolume extends EditAction {
  final double volume;
  const SetMusicVolume(this.volume);
  @override
  String describe() => 'Set music volume to ${(volume * 100).round()}%';
}

class SetMusicFade extends EditAction {
  /// Null leaves that side unchanged.
  final int? fadeInMs;
  final int? fadeOutMs;
  const SetMusicFade({this.fadeInMs, this.fadeOutMs});
  @override
  String describe() {
    final parts = <String>[
      if (fadeInMs != null) 'in ${_num(fadeInMs! / 1000)} s',
      if (fadeOutMs != null) 'out ${_num(fadeOutMs! / 1000)} s',
    ];
    return 'Fade the music ${parts.join(' and ')}';
  }
}

/// Trims the end of the music so it stops when the video does.
class FitMusicToTimeline extends EditAction {
  const FitMusicToTimeline();
  @override
  String describe() => 'End the music when the video ends';
}

class RemoveMusic extends EditAction {
  const RemoveMusic();
  @override
  String describe() => 'Remove the music';
}

class SetDucking extends EditAction {
  final bool enabled;
  const SetDucking(this.enabled);
  @override
  String describe() => enabled ? 'Lower the music while clips have sound (on export)' : 'Turn music ducking off';
}

class RunSmartTool extends ClipAction {
  final SmartTool tool;
  const RunSmartTool(this.tool, super.scope);
  @override
  String describe() {
    switch (tool) {
      case SmartTool.removeSilences:
        return 'Remove silent parts from ${scope.label}';
      case SmartTool.splitScenes:
        return 'Split ${scope.label} at scene changes';
      case SmartTool.balanceLoudness:
        return 'Balance the loudness of the clips';
      case SmartTool.autoPolish:
        return 'Auto-polish the project';
    }
  }
}

class UndoEdit extends EditAction {
  const UndoEdit();
  @override
  String describe() => 'Undo';
}

class RedoEdit extends EditAction {
  const RedoEdit();
  @override
  String describe() => 'Redo';
}

String _num(num v) {
  final s = v.toStringAsFixed(2);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}

String _signed(double v) => '${v > 0 ? '+' : ''}${(v * 100).round()}%';
