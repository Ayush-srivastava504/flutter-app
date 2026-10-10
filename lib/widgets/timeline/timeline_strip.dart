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
          final isLast = index == clips.length - 1;
          return ReorderableDragStartListener(
            key: ValueKey(clip.id),
            index: index,
            child: TimelineClipTile(
              clip: clip,
              isSelected: clip.id == selectedId,
              pixelsPerSecond: zoom,
              isLast: isLast,
              onTap: () {
                ref.read(selectedClipIdProvider.notifier).state = clip.id;
                ref.read(audioPanelOpenProvider.notifier).state = false;
                ref.read(textPanelOpenProvider.notifier).state = false;
              },
              onTransitionTap:
                  isLast ? null : () => _pickTransition(context, ref, clip),
            ),
          );
        },
      ),
    );
  }

  /// Opens a small picker for the transition into the *next* clip
  /// (i.e. [Clip.transitionOut] on [clip]) — cut, fade, or
  /// cross-dissolve, per the Phase 7 spec. Actually blending the two
  /// clips' frames together in the live preview is export-pipeline
  /// territory (Phase 8); this pass persists the choice and reflects
  /// it on the timeline tile, same "edit the model now, render it
  /// later" split Phase 4's non-destructive trim already established.
  void _pickTransition(BuildContext context, WidgetRef ref, Clip clip) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Transition into next clip',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            _TransitionOption(
              icon: Icons.content_cut,
              label: 'Cut',
              selected: clip.transitionOut == 'cut',
              onTap: () => _setTransition(ref, sheetContext, clip, 'cut'),
            ),
            _TransitionOption(
              icon: Icons.gradient,
              label: 'Fade',
              selected: clip.transitionOut == 'fade',
              onTap: () => _setTransition(ref, sheetContext, clip, 'fade'),
            ),
            _TransitionOption(
              icon: Icons.blur_on,
              label: 'Cross-dissolve',
              selected: clip.transitionOut == 'dissolve',
              onTap: () => _setTransition(ref, sheetContext, clip, 'dissolve'),
            ),
          ],
        ),
      ),
    );
  }

  void _setTransition(
    WidgetRef ref,
    BuildContext sheetContext,
    Clip clip,
    String transition,
  ) {
    ref
        .read(projectDatabaseProvider)
        .updateClip(clip.copyWith(transitionOut: transition));
    Navigator.pop(sheetContext);
  }
}

class _TransitionOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TransitionOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Theme.of(context).colorScheme.secondary : Colors.white70,
      ),
      title: Text(label),
      trailing: selected ? const Icon(Icons.check, size: 18) : null,
      onTap: onTap,
    );
  }
}
