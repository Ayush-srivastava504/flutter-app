import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../models/media_asset.dart';
import '../models/media_kind.dart';
import 'media_metadata_service.dart';
import 'media_storage_service.dart';
import 'thumbnail_service.dart';

/// Phase 3: pulling a clip out of the gallery and turning it into a
/// [MediaAsset] the rest of the app can preview.
///
/// Duration and pixel size come from a throwaway [VideoPlayerController]
/// (first half). Rotation metadata and a cached thumbnail (second half)
/// come from [MediaMetadataService] and [ThumbnailService] respectively —
/// both run after the controller initializes, so a slow probe/thumbnail
/// never delays getting *something* onto the preview.
///
/// P1 (`docs/FEATURE_PLAN_25.md` §1): the file `image_picker` hands back
/// lives in the OS-clearable cache dir (`docs/FACTS.md` F-50), so before
/// anything else runs, [MediaStorageService] copies it into the app's
/// documents dir and every later step (probing, thumbnailing, the
/// [MediaAsset] itself) works off that durable copy instead.
class MediaImportService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final ThumbnailService _thumbnailService = ThumbnailService();
  final MediaMetadataService _metadataService = MediaMetadataService();
  final MediaStorageService _storageService;

  MediaImportService({MediaStorageService? storageService})
      : _storageService = storageService ?? MediaStorageService();

  /// Opens the gallery filtered to videos. Returns null if the user
  /// cancels the picker.
  Future<MediaAsset?> pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return null;
    final persistedPath = await _storageService.persistToDocuments(file.path, consumeCacheSource: true);
    return _buildVideoAsset(persistedPath);
  }

  /// Opens the gallery filtered to photos. Returns null if the user
  /// cancels the picker.
  Future<MediaAsset?> pickPhoto() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final persistedPath = await _storageService.persistToDocuments(file.path, consumeCacheSource: true);
    return _buildPhotoAsset(persistedPath);
  }

  /// A file the app already owns (e.g. an AI-generated image or video in
  /// the documents dir) as a timeline-ready asset.
  Future<MediaAsset> assetFromFile(String path) =>
      isPhotoPath(path) ? _buildPhotoAsset(path) : _buildVideoAsset(path);

  /// Templates: pick several videos and photos at once, in the order the
  /// user tapped them. Empty if the picker is cancelled.
  Future<List<MediaAsset>> pickMultipleMedia({int? limit}) async {
    final files = await _picker.pickMultipleMedia(limit: limit != null && limit >= 2 ? limit : null);
    final out = <MediaAsset>[];
    for (final f in files) {
      final path = await _storageService.persistToDocuments(f.path, consumeCacheSource: true);
      out.add(isPhotoPath(path) ? await _buildPhotoAsset(path) : await _buildVideoAsset(path));
    }
    return out;
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
