import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_provider.dart';
import '../data/project_database.dart';

/// Live list of a project's text overlays. Same "no separate in-memory
/// copy" rule as [clipsProvider]/[audioTrackProvider] — reads straight
/// off the drift stream so edits from `TextOverlayPanel` or a canvas
/// drag show up immediately everywhere.
final textOverlaysProvider =
    StreamProvider.family<List<TextOverlay>, String>((ref, projectId) {
  final db = ref.watch(projectDatabaseProvider);
  return db.watchTextOverlays(projectId);
});

/// Id of the overlay currently selected for editing — tapped on the
/// canvas, or just created. Null when the text tool isn't focused on any
/// particular overlay.
final selectedTextOverlayIdProvider = StateProvider<String?>((ref) => null);

/// Whether `TextOverlayPanel` occupies the bottom tool area. Kept
/// separate from [selectedTextOverlayIdProvider] itself (rather than
/// treating "selected" and "panel open" as the same thing) so tapping an
/// overlay on the canvas to see which one it is doesn't necessarily have
/// to pop the editor open — mirrors `audioPanelOpenProvider`'s split
/// from clip selection.
final textPanelOpenProvider = StateProvider<bool>((ref) => false);
