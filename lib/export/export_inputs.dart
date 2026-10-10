import 'package:path/path.dart' as p;

import '../data/project_database.dart';
import 'export_models.dart';

/// Same extension set `EditorScreen` uses to infer photo-vs-video (the Clips
/// table doesn't store media type).
const Set<String> photoExtensions = {'.jpg', '.jpeg', '.png', '.heic', '.webp', '.gif'};

bool isPhotoPath(String path) => photoExtensions.contains(p.extension(path).toLowerCase());

/// Maps drift rows to the plain export types. [hasAudio] says which source
/// files actually contain an audio stream (probed once per file).
List<ExportClip> exportClipsFrom(List<Clip> rows, Map<String, bool> hasAudio) => [
      for (final c in rows)
        ExportClip(
          path: c.sourceUri,
          isPhoto: isPhotoPath(c.sourceUri),
          trimStartMs: c.trimStartMs,
          trimEndMs: c.trimEndMs,
          transitionOut: c.transitionOut,
          brightness: c.brightness,
          contrast: c.contrast,
          saturation: c.saturation,
          muted: c.muted,
          volume: c.volume,
          hasAudio: hasAudio[c.sourceUri] ?? false,
        ),
    ];

List<ExportOverlay> exportOverlaysFrom(List<TextOverlay> rows) => [
      for (final o in rows)
        ExportOverlay(
          id: o.id,
          content: o.content,
          fontFamily: o.fontFamily,
          colorValue: o.colorValue,
          fontSize: o.fontSize,
          positionX: o.positionX,
          positionY: o.positionY,
          startMs: o.startMs,
          endMs: o.endMs,
        ),
    ];

ExportMusic? exportMusicFrom(AudioTrack? t) => t == null
    ? null
    : ExportMusic(
        path: t.sourceUri,
        trimStartMs: t.trimStartMs,
        trimEndMs: t.trimEndMs,
        offsetMs: t.offsetMs,
        volume: t.volume,
      );
