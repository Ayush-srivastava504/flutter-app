/// What kind of source file a [MediaAsset] wraps.
enum MediaAssetType { video, photo }

/// A media file the user has picked from the device gallery, with just
/// enough metadata to preview it and, later, drop it onto the timeline
/// as a [Clip] (see Phase 4).
///
/// This is intentionally separate from the `Clips` drift table: a
/// [MediaAsset] describes the *source file* (what it is, how long it
/// is, how it's oriented). A `Clip` describes *how that source is used
/// on the timeline* (trim points, order, transition, filters). Keeping
/// them apart is what makes non-destructive editing possible later —
/// the source metadata never changes even as edit metadata does.
class MediaAsset {
  final String id;
  final String uri;
  final MediaAssetType type;

  /// Null for photos.
  final Duration? duration;

  final int width;
  final int height;

  /// Degrees of rotation baked into the file's metadata (0/90/180/270).
  /// Needed early because portrait clips shot on phones very often
  /// carry a rotation flag rather than a swapped width/height, and
  /// ignoring it is a common source of sideways-video bugs. Read from
  /// the container via [MediaMetadataService]; 0 if absent or unread.
  final int rotationDegrees;

  /// Path to a cached thumbnail image, or null for photos (which don't
  /// need one) or if generation failed. Populated by [ThumbnailService]
  /// at import time; Phase 4's timeline strip is the first consumer.
  final String? thumbnailUri;

  const MediaAsset({
    required this.id,
    required this.uri,
    required this.type,
    required this.width,
    required this.height,
    this.duration,
    this.rotationDegrees = 0,
    this.thumbnailUri,
  });

  /// Width/height after accounting for [rotationDegrees], i.e. what the
  /// footage actually looks like on screen rather than what the raw
  /// container reports.
  int get displayWidth => _isSideways ? height : width;
  int get displayHeight => _isSideways ? width : height;

  bool get _isSideways => rotationDegrees == 90 || rotationDegrees == 270;

  double get aspectRatio =>
      displayHeight == 0 ? 1 : displayWidth / displayHeight;

  bool get isVideo => type == MediaAssetType.video;
}
