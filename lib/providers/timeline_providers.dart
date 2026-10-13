import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_provider.dart';
import '../data/project_database.dart';

/// Live list of a project's clips, ordered by [Clip.orderIndex]. This is
/// the single source of truth the timeline UI and preview player both
/// read from — no separate in-memory copy, so DB writes (reorder, trim,
/// split, delete) show up everywhere immediately via the underlying
/// drift stream.
final clipsProvider =
    StreamProvider.family<List<Clip>, String>((ref, projectId) {
  final db = ref.watch(projectDatabaseProvider);
  return db.watchClips(projectId);
});

/// Id of the clip currently selected on the timeline (tapped, or being
/// trimmed). Null when nothing is selected.
final selectedClipIdProvider = StateProvider<String?>((ref) => null);

/// Playhead position in milliseconds, measured from the start of the
/// whole (trimmed) timeline — clip 0's trimmed start is playhead 0.
/// Drives both the live preview and where "split at playhead" cuts.
final playheadMsProvider = StateProvider<int>((ref) => 0);

/// How many timeline pixels represent one second of (trimmed) clip
/// duration. Adjustable by pinch on the clip strip; clamped in the strip
/// widget so clips never collapse to nothing or sprawl off-screen.
final timelineZoomProvider = StateProvider<double>((ref) => 40.0);

/// F4: when on, scrubbing the timeline bar snaps the playhead to a clip edge
/// that is within a few pixels. Off by default; not persisted.
final snapScrubProvider = StateProvider<bool>((ref) => false);
