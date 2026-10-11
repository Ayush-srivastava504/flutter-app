import 'package:ffmpeg_kit_flutter_new_full/ffprobe_kit.dart';

/// Reads the rotation flag baked into a video's container metadata.
///
/// This is read-only probing, not compositing — it uses FFprobeKit
/// (bundled with `ffmpeg_kit_flutter`) rather than running an actual
/// FFmpeg command, so it doesn't conflict with the project's rule that
/// FFmpeg itself stays reserved for the Phase 8 export pipeline.
///
/// `video_player` already displays portrait clips correctly today
/// (see [MediaAsset] doc comment), which is why this didn't block
/// Phase 3's first half. But the export pipeline (Phase 8) composites
/// raw frames with FFmpeg directly and needs the real flag to avoid
/// baking a sideways video into the final export.
class MediaMetadataService {
  static const _validRotations = [0, 90, 180, 270];

  /// Returns the clip's rotation in degrees (0/90/180/270), or 0 if no
  /// rotation metadata is present or it can't be read.
  Future<int> readRotationDegrees(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      final streams = info?.getStreams() ?? const [];

      for (final stream in streams) {
        if (stream.getType() != 'video') continue;

        final props = stream.getAllProperties();
        if (props == null) continue;

        // Legacy location: an explicit "rotate" tag. Common on files
        // from older camera apps and some Android devices.
        final tags = props['tags'];
        if (tags is Map && tags['rotate'] != null) {
          return _normalize(tags['rotate']);
        }

        // Modern location: most current phone footage (iOS and recent
        // Android) signals orientation via a display matrix in
        // side_data_list instead of a tag.
        final sideDataList = props['side_data_list'];
        if (sideDataList is List) {
          for (final sideData in sideDataList) {
            if (sideData is Map && sideData['rotation'] != null) {
              return _normalize(sideData['rotation']);
            }
          }
        }
      }
    } catch (_) {
      // Probing failed (corrupt file, unsupported container, etc).
      // Fall back to "no rotation" rather than surfacing an error —
      // this is supplementary metadata, not required for preview.
    }
    return 0;
  }

  /// Display-matrix rotation is sometimes negative (e.g. -90) and
  /// occasionally slightly off a clean quarter-turn. Snap it to the
  /// nearest of 0/90/180/270, which covers every real-world case.
  int _normalize(Object? raw) {
    final parsed = int.tryParse(raw.toString());
    if (parsed == null) return 0;

    final positive = ((parsed % 360) + 360) % 360;
    return _validRotations.reduce(
      (a, b) => (positive - a).abs() <= (positive - b).abs() ? a : b,
    );
  }
}
