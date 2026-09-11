import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database_provider.dart';
import '../../data/project_database.dart';
import '../../providers/audio_providers.dart';
import '../../providers/text_overlay_providers.dart';
import '../../providers/timeline_providers.dart';
import 'timeline_clip_tile.dart';

/// The horizontal strip of clip thumbnails. Long-press-drag a tile to
/// reorder it (persisted via [ProjectDatabase.reorderClips]); pinch
/// anywhere on the strip to zoom the time scale in/out.
class TimelineStrip extends ConsumerWidget {
  final String projectId;
  final List<Clip> clips;

  const TimelineStrip({
    super.key,
    required this.projectId,
    required this.clips,
  });

  static const double _minZoom = 10;
  static const double _maxZoom = 200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(timelineZoomProvider);
    final selectedId = ref.watch(selectedClipIdProvider);

    if (clips.isEmpty) {
      return const Center(
        child: Text(
          'Import a clip to start your timeline',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    // Captured at gesture start so a pinch scales relative to the zoom
    // level when fingers touched down, not whatever it drifted to mid-drag.
    var zoomAtGestureStart = zoom;

    return GestureDetector(
      onScaleStart: (_) => zoomAtGestureStart = ref.read(timelineZoomProvider),
      onScaleUpdate: (details) {
        final next =
            (zoomAtGestureStart * details.scale).clamp(_minZoom, _maxZoom);
        ref.read(timelineZoomProvider.notifier).state = next;
      },
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: clips.length,
        onReorder: (oldIndex, newIndex) {
          final ids = clips.map((c) => c.id).toList();
          if (newIndex > oldIndex) newIndex -= 1;
          final moved = ids.removeAt(oldIndex);
          ids.insert(newIndex, moved);
          ref.read(projectDatabaseProvider).reorderClips(projectId, ids);
        },
        itemBuilder: (context, index) {
          final clip = clips[index];
          return ReorderableDragStartListener(
            key: ValueKey(clip.id),
            index: index,
            child: TimelineClipTile(
              clip: clip,
              isSelected: clip.id == selectedId,
              pixelsPerSecond: zoom,
              onTap: () {
                ref.read(selectedClipIdProvider.notifier).state = clip.id;
                ref.read(audioPanelOpenProvider.notifier).state = false;
                ref.read(textPanelOpenProvider.notifier).state = false;
              },
            ),
          );
        },
      ),
    );
  }
}
