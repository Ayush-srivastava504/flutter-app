import 'dart:io';

import '../data/project_database.dart';
import 'media_storage_service.dart';

/// Outcome of one [MediaRepairService.repairCachedMedia] pass, surfaced
/// mainly for logging/tests — the UI doesn't currently show this to the
/// user (a silent background repair; nothing to confirm or undo).
class MediaRepairResult {
  /// Rows whose `sourceUri` was moved from the cache dir into documents.
  final int repaired;

  /// Rows that still point at the cache dir and could not be moved —
  /// either the file is already gone, or the copy itself failed (disk
  /// full, permission denied). Either way, nothing changed for that row;
  /// it will still fail export with "source missing" exactly as it
  /// would have before P1.
  final int alreadyMissing;

  const MediaRepairResult({required this.repaired, required this.alreadyMissing});

  @override
  String toString() =>
      'MediaRepairResult(repaired: $repaired, alreadyMissing: $alreadyMissing)';
}

/// P1 (`docs/FEATURE_PLAN_25.md` §1), second half: "Add a one-time
/// repair for existing rows (if sourceUri is in cache and exists, copy
/// it and update the row)."
///
/// Covers two situations: a project created before this pass shipped
/// (its clips/audio still point into the cache dir), and an install
/// that upgrades straight from an older build without ever re-importing
/// anything. Both look identical from the DB's point of view — a row
/// whose `sourceUri` is still under the cache dir — so one sweep handles
/// both. Meant to be called once per app launch (see `LaunchGate`);
/// cheap to call repeatedly since a row that's already been moved no
/// longer matches [MediaStorageService.isInCache] on the next pass.
class MediaRepairService {
  final ProjectDatabase _db;
  final MediaStorageService _storage;

  MediaRepairService(this._db, {MediaStorageService? storage})
      : _storage = storage ?? MediaStorageService();

  Future<MediaRepairResult> repairCachedMedia() async {
    int repaired = 0;
    int alreadyMissing = 0;

    final clips = await _db.allClipsAcrossProjects();
    for (final clip in clips) {
      final outcome = await _repairOne(clip.sourceUri);
      if (outcome == null) continue;
      if (outcome.isEmpty) {
        alreadyMissing++;
        continue;
      }
      await _db.updateClip(clip.copyWith(sourceUri: outcome));
      repaired++;
    }

    final tracks = await _db.allAudioTracksAcrossProjects();
    for (final track in tracks) {
      final outcome = await _repairOne(track.sourceUri);
      if (outcome == null) continue;
      if (outcome.isEmpty) {
        alreadyMissing++;
        continue;
      }
      await _db.updateAudioTrack(track.copyWith(sourceUri: outcome));
      repaired++;
    }

    return MediaRepairResult(repaired: repaired, alreadyMissing: alreadyMissing);
  }

  /// Returns: null if [sourceUri] isn't in the cache dir (nothing to
  /// do); `''` if it is, but the file no longer exists (can't repair);
  /// otherwise the new, persisted path.
  Future<String?> _repairOne(String sourceUri) async {
    if (!await _storage.isInCache(sourceUri)) return null;
    if (!await File(sourceUri).exists()) return '';
    final persisted = await _storage.persistToDocuments(sourceUri);
    // persistToDocuments falls back to the original path on failure —
    // treat that the same as "still missing"/no progress rather than
    // writing a no-op update.
    return persisted == sourceUri ? '' : persisted;
  }
}
