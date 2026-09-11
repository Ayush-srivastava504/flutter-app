import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_provider.dart';
import '../data/project_database.dart';

/// Live view of a project's background-music track (or null if none has
/// been imported yet). Same "no separate in-memory copy" rule as
/// [clipsProvider] — reads straight off the drift stream.
final audioTrackProvider =
    StreamProvider.family<AudioTrack?, String>((ref, projectId) {
  final db = ref.watch(projectDatabaseProvider);
  return db.watchAudioTrack(projectId);
});

/// Whether the audio-track tool panel is open. Kept separate from
/// [selectedClipIdProvider] rather than folding the music track into
/// that same id space — the editor screen clears one when the other
/// opens so they don't fight over the bottom panel.
final audioPanelOpenProvider = StateProvider<bool>((ref) => false);
