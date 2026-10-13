import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/project_database.dart';
import '../models/bundled_track.dart';
import 'thumbnail_service.dart';

/// P2 (`docs/FEATURE_PLAN_25.md` §1): "a fixture project for fast
/// testing" — a debug-only button on Home builds a project from two
/// tiny synthetic clips + one photo bundled in `assets/dev/` (generated
/// with `ffmpeg`'s `lavfi` test sources, so there's no licence/
/// provenance question the way there is for the bundled music loops —
/// see `docs/FACTS.md` F-81) plus one track from the *existing* bundled
/// music library (reuses `AudioImportService`'s idea, not its class,
/// since that service is built around `image_picker`/`file_picker`
/// results, not direct asset-bundle access) — deliberately not a fourth
/// bundled audio file, to avoid growing `assets/` for a dev-only path.
///
/// Only ever called from a `kDebugMode`-gated button
/// (`home_screen.dart`) — never reachable in a release build. The
/// ~60 KB of `assets/dev/` media still ships in every build regardless
/// of build mode (pubspec assets aren't build-mode-conditional); see
/// the final report for the `docs/LAUNCH_CHECKLIST.md` APK-size note.
class SampleProjectService {
  static const _clip1Asset = 'assets/dev/sample_clip_1.mp4';
  static const _clip2Asset = 'assets/dev/sample_clip_2.mp4';
  static const _photoAsset = 'assets/dev/sample_photo.jpg';

  // Hardcoded rather than probed: these are fixed files shipped with
  // the app, not user-picked ones — same rationale as
  // `BundledTrack.durationMs`. Re-verify with `ffprobe` if the assets
  // are ever regenerated (`docs/DEV_FIXTURE_ASSETS.md` has the command).
  static const _clip1DurationMs = 1500;
  static const _clip2DurationMs = 1500;
  static const _photoDurationMs = 3000;

  final ProjectDatabase _db;
  final ThumbnailService _thumbnailService;
  final Future<Directory> Function() _documentsDir;
  static const _uuid = Uuid();

  SampleProjectService(
    this._db, {
    ThumbnailService? thumbnailService,
    Future<Directory> Function()? documentsDir,
  })  : _thumbnailService = thumbnailService ?? ThumbnailService(),
        _documentsDir = documentsDir ?? getApplicationDocumentsDirectory;

  /// Creates "Sample Project" (or "Sample Project (2)", "(3)", … if one
  /// already exists — same idea as never silently overwriting) with 2
  /// video clips, 1 photo clip (default 3 s, matching
  /// `EditorScreen._photoDurationMs`), and a bundled music track.
  /// Returns the new project's id so the caller can navigate straight
  /// into the Editor, same as `HomeScreen._createProject`.
  Future<String> create() async {
    final clip1Path = await _copyAssetToDocuments(_clip1Asset, 'dev_sample_clip_1.mp4');
    final clip2Path = await _copyAssetToDocuments(_clip2Asset, 'dev_sample_clip_2.mp4');
    final photoPath = await _copyAssetToDocuments(_photoAsset, 'dev_sample_photo.jpg');
    final musicTrack = bundledAudioLibrary.first;
    final musicPath = await _copyAssetToDocuments(
      musicTrack.assetPath,
      'dev_sample_music${p.extension(musicTrack.assetPath)}',
    );

    // Best-effort thumbnails so the sample timeline looks like a real
    // one; a failed generation just leaves the tile's placeholder icon
    // (see `_Thumbnail` in `timeline_clip_tile.dart`) — never blocks
    // creating the project.
    final clip1Thumb = await _thumbnailService.generateAndCache(clip1Path);
    final clip2Thumb = await _thumbnailService.generateAndCache(clip2Path);

    final projectId = _uuid.v4();
    final now = DateTime.now();
    final name = await _nextAvailableName();

    await _db.insertProject(ProjectsCompanion.insert(
      id: projectId,
      name: name,
      createdAt: now,
      updatedAt: now,
    ));

    // Sequential, not parallel: `appendClip` computes orderIndex from
    // the current clip count, so these must resolve one at a time to
    // land at 0/1/2 instead of racing to the same index.
    await _db.appendClip(
      id: _uuid.v4(),
      projectId: projectId,
      sourceUri: clip1Path,
      durationMs: _clip1DurationMs,
      thumbnailUri: clip1Thumb,
    );
    await _db.appendClip(
      id: _uuid.v4(),
      projectId: projectId,
      sourceUri: clip2Path,
      durationMs: _clip2DurationMs,
      thumbnailUri: clip2Thumb,
    );
    await _db.appendClip(
      id: _uuid.v4(),
      projectId: projectId,
      sourceUri: photoPath,
      durationMs: _photoDurationMs,
    );

    await _db.setAudioTrack(
      id: _uuid.v4(),
      projectId: projectId,
      sourceUri: musicPath,
      durationMs: musicTrack.durationMs,
    );

    return projectId;
  }

  Future<String> _nextAvailableName() async {
    final existing = (await _db.allProjects()).map((proj) => proj.name).toSet();
    if (!existing.contains('Sample Project')) return 'Sample Project';
    var n = 2;
    while (existing.contains('Sample Project ($n)')) {
      n++;
    }
    return 'Sample Project ($n)';
  }

  /// Copies a bundled asset into `<documents>/dev_samples/[destName]`,
  /// skipped if that file is already there — same idempotent pattern as
  /// `AudioImportService.pickFromLibrary` (picking the same library
  /// track twice shouldn't churn disk). Means tapping "Load sample
  /// project" repeatedly creates a new project each time, but all of
  /// them share the same underlying copied files — non-destructive
  /// editing already makes several rows sharing one `sourceUri` a
  /// supported shape (see `duplicateProject`, P1's `MediaStorageService`
  /// doesn't need to touch these since they're written straight into
  /// documents, never through the cache dir).
  Future<String> _copyAssetToDocuments(String assetPath, String destName) async {
    final dir = await _documentsDir();
    final destDir = Directory(p.join(dir.path, 'dev_samples'));
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final destFile = File(p.join(destDir.path, destName));
    if (!await destFile.exists()) {
      final bytes = await rootBundle.load(assetPath);
      await destFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }
    return destFile.path;
  }
}
