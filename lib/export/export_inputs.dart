import '../data/project_database.dart';
import '../models/chroma_key.dart';
import '../models/media_kind.dart';
import 'export_models.dart';

export '../models/media_kind.dart' show isPhotoPath, photoExtensions;

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
          look: c.look,
          lookStrength: c.lookStrength,
          turns: c.turns,
          flipH: c.flipH,
          flipV: c.flipV,
          // F11: speed is a no-op for photos (nothing to speed up) —
          // enforced here, not just left to the UI, so a stray non-1.0
          // value on a photo row (e.g. from old data) can't change a
          // photo's `-t` duration at export.
          speed: isPhotoPath(c.sourceUri) ? 1.0 : c.speed,
          fitMode: c.fitMode,
          effect: c.effect,
          effectStrength: c.effectStrength,
          enhanceSpeech: c.enhanceSpeech,
          chromaKey: ChromaKeySpec.tryParse(c.keyJson),
        ),
    ];

List<ExportVoiceOver> exportVoiceOversFrom(List<VoiceOver> rows) => [
      for (final v in rows)
        ExportVoiceOver(path: v.sourceUri, startMs: v.startMs, volume: v.volume, enhance: v.enhance),
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
          bold: o.bold,
          boxEnabled: o.boxEnabled,
          boxColorValue: o.boxColorValue,
          outlineWidth: o.outlineWidth,
          outlineColorValue: o.outlineColorValue,
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
        fadeInMs: t.fadeInMs,
        fadeOutMs: t.fadeOutMs,
      );
