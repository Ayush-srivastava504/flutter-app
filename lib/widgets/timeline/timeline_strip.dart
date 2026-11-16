import 'dart:ui' as ui show Clip;

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database_provider.dart';
import '../../data/project_database.dart';
import '../../models/transition_x.dart';
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

  /// "+" at the end of the strip: add more clips (always visible, so adding
  /// never depends on which panel is open).
  final VoidCallback? onAdd;

  const TimelineStrip({
    super.key,
    required this.projectId,
    required this.clips,
    this.onAdd,
  });

  static const double _minZoom = 10;
  static const double _maxZoom = 200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(timelineZoomProvider);
    final selectedId = ref.watch(selectedClipIdProvider);

    if (clips.isEmpty) {
      return Center(
        child: onAdd == null
            ? const Text('Import a clip to start your timeline', style: TextStyle(color: AppColors.textDim))
            : TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add videos or photos'),
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
        footer: onAdd == null ? null : _AddTile(onTap: onAdd!),
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
          // Delayed (long-press) drag: with the immediate listener every
          // horizontal swipe that started on a tile dragged that clip, so
          // just scrolling the timeline silently reordered the edit.
          return ReorderableDelayedDragStartListener(
            key: ValueKey(clip.id),
            index: index,
            child: TimelineClipTile(
              clip: clip,
              isSelected: clip.id == selectedId,
              pixelsPerSecond: zoom,
              isLast: isLast,
              onTap: () {
                // Tapping the selected clip again closes its panel (back to the tools).
                ref.read(selectedClipIdProvider.notifier).state = clip.id == selectedId ? null : clip.id;
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
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Row(children: [
                Expanded(
                  child: Text('Transition into the next clip', style: Theme.of(sheetContext).textTheme.titleMedium),
                ),
                TextButton.icon(
                  onPressed: () {
                    ref.read(projectDatabaseProvider).applyTransitionToAllClips(clip.projectId, clip.transitionOut);
                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Use on every cut'),
                ),
              ]),
              for (final group in transitionGroups) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Text(group,
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in transitionOptions.where((o) => o.group == group))
                      _TransitionOption(
                        icon: transitionIcon(option.id),
                        label: option.label,
                        trendy: option.trendy,
                        selected: clip.transitionOut == option.id,
                        onTap: () => _setTransition(ref, sheetContext, clip, option.id),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'The preview shows a quick blend; the export draws the real transition.',
                style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
              ),
            ],
          ),
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
  final bool trendy;
  final VoidCallback onTap;

  const _TransitionOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trendy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: ui.Clip.none, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.ember.withValues(alpha: 0.16) : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadii.sm + 2),
                border: Border.all(color: selected ? AppColors.ember : AppColors.line, width: selected ? 2 : 1),
              ),
              child: Icon(icon, color: selected ? AppColors.ember : AppColors.text, size: 22),
            ),
            if (trendy)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.youtube, borderRadius: BorderRadius.circular(4)),
                  child: const Text('HOT',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                ),
              ),
          ]),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: selected ? AppColors.ember : AppColors.textDim)),
        ]),
      ),
    );
  }
}

/// The "+" tile at the end of the timeline.
class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
      child: Material(
        color: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: const BorderSide(color: AppColors.ember, width: 1.4),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: onTap,
          child: const SizedBox(
            width: 52,
            child: Tooltip(
              message: 'Add videos or photos',
              child: Icon(Icons.add_rounded, color: AppColors.ember, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
