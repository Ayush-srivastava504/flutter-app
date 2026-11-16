import 'package:drift/drift.dart' show Value;
import 'package:video_editor_app/data/project_database.dart';

/// A `Clip` row with every column at its table default unless overridden —
/// so a test only spells out the fields it is actually about, and adding a
/// column to `Clips` means updating this one helper, not every test.
Clip clipRow({
  String id = 'c',
  String projectId = 'p1',
  String sourceUri = '/media/a.mp4',
  int orderIndex = 0,
  int trimStartMs = 0,
  int trimEndMs = 4000,
  int? durationMs,
  String transitionOut = 'cut',
  bool muted = false,
  double volume = 1.0,
  double speed = 1.0,
  String fitMode = 'fit',
  String? look,
  String? effect,
  bool enhanceSpeech = false,
  String? keyJson,
}) =>
    Clip(
      id: id,
      projectId: projectId,
      sourceUri: sourceUri,
      orderIndex: orderIndex,
      trimStartMs: trimStartMs,
      trimEndMs: trimEndMs,
      durationMs: durationMs ?? trimEndMs,
      rotationDegrees: 0,
      transitionOut: transitionOut,
      brightness: 0,
      contrast: 0,
      saturation: 0,
      muted: muted,
      volume: volume,
      look: look,
      turns: 0,
      flipH: false,
      flipV: false,
      speed: speed,
      fitMode: fitMode,
      lookStrength: 1.0,
      effect: effect,
      effectStrength: 1.0,
      enhanceSpeech: enhanceSpeech,
      keyJson: keyJson,
    );

AudioTrack musicRow({
  int durationMs = 20000,
  int trimStartMs = 0,
  int? trimEndMs,
  int offsetMs = 0,
  int fadeInMs = 0,
  int fadeOutMs = 0,
}) =>
    AudioTrack(
      id: 'm',
      projectId: 'p1',
      sourceUri: '/media/m.mp3',
      durationMs: durationMs,
      trimStartMs: trimStartMs,
      trimEndMs: trimEndMs ?? durationMs,
      offsetMs: offsetMs,
      volume: 1.0,
      fadeInMs: fadeInMs,
      fadeOutMs: fadeOutMs,
    );

/// Inserts project `p1` and one clip per entry of [clips] (in order).
Future<void> seedProject(ProjectDatabase db, List<Clip> clips, {String projectId = 'p1'}) async {
  await db.insertProject(ProjectsCompanion.insert(
    id: projectId,
    name: 'Project',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ));
  for (var i = 0; i < clips.length; i++) {
    await db.insertClip(clips[i].copyWith(orderIndex: i, projectId: projectId).toCompanion(false));
  }
}

Future<void> seedMusic(ProjectDatabase db, {int durationMs = 20000, int offsetMs = 0}) =>
    db.into(db.audioTracks).insert(AudioTracksCompanion.insert(
          id: 'm',
          projectId: 'p1',
          sourceUri: '/media/m.mp3',
          durationMs: Value(durationMs),
          trimEndMs: durationMs,
          offsetMs: Value(offsetMs),
        ));
