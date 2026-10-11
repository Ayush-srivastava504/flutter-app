# Phase 3 — Media Import & Preview (complete)

## Built this pass (second half)
- `lib/services/thumbnail_service.dart` — generates a cached JPEG
  thumbnail for a video via `video_thumbnail`. Cache key is the
  source file's name + last-modified time, stored under the app's
  cache directory (`thumbnails/`), so re-importing the same file
  never regenerates its thumbnail. Best-effort: returns null on
  failure rather than blocking import.
- `lib/services/media_metadata_service.dart` — reads the real
  rotation flag from a video's container metadata via `FFprobeKit`
  (from `ffmpeg_kit_flutter`). Checks both the legacy `tags.rotate`
  location and the `side_data_list` display-matrix location used by
  most current phone footage, normalizes negative/off-angle values
  to the nearest of 0/90/180/270. This is metadata probing only —
  it does not run an actual FFmpeg command, so FFmpeg itself is
  still untouched until the Phase 8 export pipeline.
- `lib/models/media_asset.dart` — added `thumbnailUri` (nullable;
  null for photos or failed generation). `rotationDegrees` doc
  comment updated now that it's a real read, not a placeholder.
- `lib/services/media_import_service.dart` — wired both services in:
  after the throwaway `VideoPlayerController` initializes, rotation
  and thumbnail are fetched (sequentially, to avoid three readers on
  the same file at once) before the `MediaAsset` is returned.
- `lib/widgets/video_preview_player.dart` — while a clip is
  initializing, shows its cached thumbnail (dimmed, with a spinner
  on top) instead of a bare spinner on black, when one is available.

## Not done yet
Nothing — first half (import + single-clip preview) and second half
(thumbnails + rotation metadata) are both done. Everything Phase 4's
timeline needs from a `MediaAsset` (duration, dimensions, rotation,
thumbnail) now exists.

## Next step
Phase 4: the timeline itself — ordered clips, thumbnail strip (now
unblocked), scrubbing, and a playhead the preview syncs to instead of
"most recently imported clip."
