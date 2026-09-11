import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Generates a JPEG thumbnail for an imported video and caches it on
/// disk so the same source file is never re-thumbnailed twice.
///
/// Phase 4's timeline will call [generateAndCache] once per clip when
/// building its thumbnail strip; caching here is what keeps that cheap
/// even after the user scrubs the timeline or reopens a project.
class ThumbnailService {
  static const int _thumbnailWidth = 320;
  static const int _thumbnailQuality = 75;

  /// Returns the path of a cached (or newly generated) thumbnail for the
  /// video at [sourceUri], or null if generation fails — a missing
  /// thumbnail should never block import or preview, both of which work
  /// without one.
  Future<String?> generateAndCache(String sourceUri) async {
    try {
      final cacheDir = await _thumbnailCacheDir();
      final cacheKey = await _cacheKeyFor(sourceUri);
      final cachedFile = File(p.join(cacheDir.path, '$cacheKey.jpg'));

      if (await cachedFile.exists()) {
        return cachedFile.path;
      }

      final generatedPath = await VideoThumbnail.thumbnailFile(
        video: sourceUri,
        thumbnailPath: cacheDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: _thumbnailWidth,
        quality: _thumbnailQuality,
      );
      if (generatedPath == null) return null;

      // video_thumbnail names the file itself; move it to our stable
      // cache-key name so the exists() check above can find it next time.
      if (generatedPath == cachedFile.path) return generatedPath;
      final generatedFile = File(generatedPath);
      if (!await generatedFile.exists()) return null;
      final movedFile = await generatedFile.rename(cachedFile.path);
      return movedFile.path;
    } catch (_) {
      // Thumbnail generation is best-effort. Phase 4 can retry lazily
      // if a clip is still missing one when the timeline needs it.
      return null;
    }
  }

  /// Deletes every cached thumbnail. Exposed for a future "clear cache"
  /// setting; not wired to any UI yet.
  Future<void> clearCache() async {
    try {
      final cacheDir = await _thumbnailCacheDir();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (_) {
      // Non-critical: worst case, stale thumbnails just take up space.
    }
  }

  Future<Directory> _thumbnailCacheDir() async {
    final appCacheDir = await getApplicationCacheDirectory();
    final dir = Directory(p.join(appCacheDir.path, 'thumbnails'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Keys the cache off the source file's name + last-modified time
  /// rather than its full contents (no hashing package required, and
  /// still correct: if the file at that path changes, mtime changes).
  Future<String> _cacheKeyFor(String sourceUri) async {
    final base = p.basenameWithoutExtension(sourceUri);
    final safeBase = base.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

    try {
      final stat = await File(sourceUri).stat();
      return '${safeBase}_${stat.modified.millisecondsSinceEpoch}';
    } catch (_) {
      // Source file stat failed (unusual, but shouldn't crash caching) —
      // fall back to a name-only key.
      return safeBase;
    }
  }
}
