import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/project_database.dart';
import '../../providers/audio_providers.dart';
import '../../providers/text_overlay_providers.dart';
import '../../providers/timeline_providers.dart';

/// Thin multi-row lane, sitting under [AudioTrackLane], giving an
/// at-a-glance view of where every text overlay sits against the
/// (trimmed) video timeline — the gap `PHASE_6_PROGRESS.md` flagged
/// alongside the audio-waveform note: before this, the only way to see
/// an overlay's timing was opening `TextOverlayPanel` and reading its
/// `RangeSlider` one overlay at a time, with no way to see how several
/// overlays relate to each other.
///
/// Overlays are assigned to rows with simple greedy interval
/// partitioning (sorted by start time, each overlay takes the first row
/// whose last-placed overlay has already ended) so simultaneous
/// overlays stack into separate rows instead of drawing on top of each
/// other, while sequential ones share a row. Tapping a segment selects
/// that overlay and opens `TextOverlayPanel`, same entry point as
/// tapping it on the canvas.
///
/// Collapses to nothing when there are no overlays yet — the "Add text"
/// button in `EditorScreen`'s tool row is the entry point, so there's
/// nothing here worth a permanent empty-state lane (unlike
/// `AudioTrackLane`, whose empty state doubles as the way to attach
/// music at all).
class TextOverlayStrip extends ConsumerWidget {
  final List<TextOverlay> overlays;
  final int totalMs;

  const TextOverlayStrip({
    super.key,
    required this.overlays,
    required this.totalMs,
  });

  static const double _rowHeight = 18;
  static const int _maxVisibleRows = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (overlays.isEmpty) return const SizedBox.shrink();

    final spanMs = totalMs > 0
        ? totalMs
        : overlays.map((o) => o.endMs).fold(0, math.max);
    if (spanMs <= 0) return const SizedBox.shrink();

    final rows = <int, List<TextOverlay>>{};
    final rowEndMs = <int>[];
    final sorted = [...overlays]
      ..sort((a, b) => a.startMs.compareTo(b.startMs));
    for (final overlay in sorted) {
      var row = rowEndMs.indexWhere((end) => end <= overlay.startMs);
      if (row == -1) {
        row = rowEndMs.length;
        rowEndMs.add(overlay.endMs);
      } else {
        rowEndMs[row] = overlay.endMs;
      }
      rows.putIfAbsent(row, () => []).add(overlay);
    }

    final rowCount = rowEndMs.length;
    final visibleRows = rowCount.clamp(1, _maxVisibleRows);
    final laneHeight = visibleRows * _rowHeight + 8;

    final selectedId = ref.watch(selectedTextOverlayIdProvider);
    final textPanelOpen = ref.watch(textPanelOpenProvider);

    void select(TextOverlay overlay) {
      ref.read(selectedTextOverlayIdProvider.notifier).state = overlay.id;
      ref.read(textPanelOpenProvider.notifier).state = true;
      ref.read(audioPanelOpenProvider.notifier).state = false;
      ref.read(selectedClipIdProvider.notifier).state = null;
    }

    final body = _StripBody(
      rows: rows,
      rowCount: rowCount,
      spanMs: spanMs,
      selectedId: selectedId,
      textPanelOpen: textPanelOpen,
      onSelect: select,
      rowHeight: _rowHeight,
    );

    return SizedBox(
      height: laneHeight,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: rowCount > _maxVisibleRows
            ? SingleChildScrollView(child: body)
            : body,
      ),
    );
  }
}

class _StripBody extends StatelessWidget {
  final Map<int, List<TextOverlay>> rows;
  final int rowCount;
  final int spanMs;
  final String? selectedId;
  final bool textPanelOpen;
  final ValueChanged<TextOverlay> onSelect;
  final double rowHeight;

  const _StripBody({
    required this.rows,
    required this.rowCount,
    required this.spanMs,
    required this.selectedId,
    required this.textPanelOpen,
    required this.onSelect,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double msToX(int ms) => (ms / spanMs) * width;

        return SizedBox(
          height: rowCount * rowHeight,
          child: Stack(
            children: [
              for (final entry in rows.entries)
                for (final overlay in entry.value)
                  Positioned(
                    left: msToX(overlay.startMs).clamp(0.0, width),
                    width: (msToX(overlay.endMs) - msToX(overlay.startMs))
                        .clamp(4.0, width),
                    top: entry.key * rowHeight,
                    height: rowHeight - 2,
                    child: GestureDetector(
                      onTap: () => onSelect(overlay),
                      child: Container(
                        margin: const EdgeInsets.only(right: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: overlay.id == selectedId && textPanelOpen
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context)
                                  .colorScheme
                                  .tertiary
                                  .withOpacity(0.6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          overlay.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
