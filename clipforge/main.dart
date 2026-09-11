import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../models/media_asset.dart';
import 'media_metadata_service.dart';
import 'thumbnail_service.dart';

/// Phase 3: pulling a clip out of the gallery and turning it into a
/// [MediaAsset] the rest of the app can preview.
///
/// Duration and pixel size come from a throwaway [VideoPlayerController]
/// (first half). Rotation metadata and a cached thumbnail (second half)
/// come from [MediaMetadataService] and [ThumbnailService] respectively —
/// both run after the controller initializes, so a slow probe/thumbnail
/// never delays getting *something* onto the preview.
class MediaImportService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final ThumbnailService _thumbnailService = ThumbnailService();
  final MediaMetadataService _metadataService = MediaMetadataService();

  /// Opens the gallery filtered to videos. Returns null if the user
  /// cancels the picker.
  Future<MediaAsset?> pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return null;
    return _buildVideoAsset(file.path);
  }

  /// Opens the gallery filtered to photos. Returns null if the user
  /// cancels the picker.
  Future<MediaAsset?> pickPhoto() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return _buildPhotoAsset(file.path);
  }

  Future<MediaAsset> _buildVideoAsset(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      final size = controller.value.size;

      // Run these after initialize() rather than in parallel with it —
      // FFprobe and the thumbnail generator both open the file
      // themselves, and staggering avoids three concurrent readers on
      // the same file on slower devices.
      final rotationDegrees =
          await _metadataService.readRotationDegrees(path);
      final thumbnailUri = await _thumbnailService.generateAndCache(path);

      return MediaAsset(
        id: _uuid.v4(),
        uri: path,
        type: MediaAssetType.video,
        duration: controller.value.duration,
        width: size.width.round(),
        height: size.height.round(),
        rotationDegrees: rotationDegrees,
        thumbnailUri: thumbnailUri,
      );
    } finally {
      await controller.dispose();
    }
  }

  Future<MediaAsset> _buildPhotoAsset(String path) async {
    // Photos get a fixed duration once dropped on the timeline in
    // Phase 4; for now we just record that it's a photo with no
    // intrinsic duration and unknown pixel size until first painted.
    // No thumbnail needed — the photo file itself already is one.
    return MediaAsset(
      id: _uuid.v4(),
      uri: path,
      type: MediaAssetType.photo,
      width: 0,
      height: 0,
    );
  }
}
