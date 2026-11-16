import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../data/project_database.dart';
import '../models/audio_library.dart';
import '../models/bundled_track.dart';
import '../models/clip_x.dart';
import '../models/frame_shape.dart';
import '../models/media_asset.dart';
import '../models/video_template.dart';
import 'audio_import_service.dart';

/// Builds a normal, fully editable project from a [VideoTemplate] and the
/// media the user picked: one clip per item (trimmed to its slot, with the
/// template's transition/look/effect), the template titles placed on the
/// real timeline length, and the template music faded to fit.
class TemplateService {
  final ProjectDatabase db;
  final AudioImportService audio;
  final Uuid _uuid = const Uuid();

  TemplateService(this.db, {AudioImportService? audio}) : audio = audio ?? AudioImportService();

  /// Returns the new project's id.
  Future<String> create(VideoTemplate t, List<MediaAsset> media) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final firstVideo = media.where((m) => m.isVideo).firstOrNull;
    final aspect = t.aspect ??
        t.mode.lockedAspect ??
        (firstVideo == null
            ? 9 / 16
            : nearestFrameShape(firstVideo.width, firstVideo.height, rotationDegrees: firstVideo.rotationDegrees) ??
                9 / 16);
    await db.insertProject(ProjectsCompanion.insert(
      id: id,
      name: t.name,
      mode: Value(t.mode.name),
      aspectRatio: Value(aspect),
      duckMusic: Value(t.duckMusic),
      createdAt: now,
      updatedAt: now,
    ));

    final plans = planTemplateClips(t, [for (final m in media) m.isVideo ? m.duration?.inMilliseconds : null]);
    for (var i = 0; i < media.length; i++) {
      final m = media[i];
      final plan = plans[i];
      final clipId = _uuid.v4();
      await db.appendClip(
        id: clipId,
        projectId: id,
        sourceUri: m.uri,
        durationMs: m.isVideo ? (m.duration?.inMilliseconds ?? plan.lengthMs) : plan.lengthMs,
        rotationDegrees: m.rotationDegrees,
        thumbnailUri: m.thumbnailUri,
      );
      final clip = await db.getClip(clipId);
      if (clip == null) continue;
      await db.updateClip(clip.copyWith(
        trimStartMs: 0,
        trimEndMs: plan.lengthMs,
        transitionOut: plan.transitionOut,
        look: Value(t.look),
        lookStrength: t.lookStrength,
        effect: Value(plan.effect),
        effectStrength: 1.0,
      ));
    }

    final clips = await db.watchClips(id).first;
    final layout = layoutTimeline(clips);
    final totalMs = layout.isEmpty ? 0 : layout.last.endMs;

    await db.insertTextOverlays([
      for (final (x, s, e) in placeTemplateTexts(t, totalMs))
        TextOverlaysCompanion.insert(
          id: _uuid.v4(),
          projectId: id,
          content: x.content,
          startMs: Value(s),
          endMs: e,
          positionY: Value(x.positionY),
          fontSize: Value(x.fontSize),
          bold: Value(x.bold),
          boxEnabled: Value(x.box),
          fontFamily: Value(x.fontFamily),
        ),
    ]);

    // Library tracks (with a tempo, for beat-synced templates) first, then
    // the older bundled loops.
    final libraryTrack = audioLibrary.where((s) => s.id == t.musicId && !s.isSfx).firstOrNull;
    final track = libraryTrack != null
        ? BundledTrack(
            id: libraryTrack.id,
            title: libraryTrack.title,
            assetPath: libraryTrack.assetPath,
            durationMs: libraryTrack.durationMs,
          )
        : bundledAudioLibrary.where((b) => b.id == t.musicId).firstOrNull;
    if (track != null && totalMs > 0) {
      final asset = await audio.pickFromLibrary(track);
      final musicId = _uuid.v4();
      await db.setAudioTrack(
        id: musicId,
        projectId: id,
        sourceUri: asset.uri,
        durationMs: asset.duration.inMilliseconds,
      );
      final row = await db.getAudioTrack(id);
      if (row != null) {
        final end = asset.duration.inMilliseconds < totalMs ? asset.duration.inMilliseconds : totalMs;
        await db.updateAudioTrack(row.copyWith(
          trimEndMs: end,
          fadeInMs: 300,
          fadeOutMs: end > 2000 ? 1200 : end ~/ 3,
          volume: t.duckMusic ? 0.7 : 0.9,
        ));
      }
    }
    return id;
  }
}
