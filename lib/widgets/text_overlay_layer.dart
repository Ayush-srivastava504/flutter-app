import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_provider.dart';
import '../data/project_database.dart';
import '../models/text_overlay_x.dart';
import '../providers/text_overlay_providers.dart';

/// Draws whichever [overlays] are active at [playheadMs] on top of the
/// preview canvas, and lets the user drag each one to reposition it.
///
/// Stacked directly over `VideoPreviewPlayer` in `EditorScreen` rather
/// than folded into that widget — `VideoPreviewPlayer` only knows about
/// one clip's local playback position, while overlay timing is
/// timeline-relative (like the music track), and the editor screen
/// already has `playheadMs` on hand. Keeping this separate also means a
/// drag here never has to fight the video controller for gesture
/// priority.
///
/// [playheadMs] now advances during live playback too, not just on
/// scrub — `EditorScreen` wires `VideoPreviewPlayer.onPositionTick`
/// into `playheadMsProvider` (Phase 6, second pass), so overlays
/// appear/disappear in step with playback within the clip that's
/// currently open. It still doesn't follow the playhead across a clip
/// boundary onto the *next* clip, since nothing else in the app does
/// continuous cross-clip playback yet either (see PHASE_4_PROGRESS.md /
/// PHASE_5_PROGRESS.md) — that's a bigger, non-overlay-specific gap.
class TextOverlayLayer extends ConsumerStatefulWidget {
  final List<TextOverlay> overlays;
  final int playheadMs;

  /// The active clip's video aspect ratio (width / height), once
  /// `VideoPreviewPlayer` has reported it via `onAspectRatioKnown` —
  /// null before that, or for photo clips (which don't report one yet).
  /// Used to map overlay positions onto the actual letterboxed video
  /// frame inside the preview canvas rather than the full canvas.
  final double? frameAspectRatio;

  const TextOverlayLayer({
    super.key,
    required this.overlays,
    required this.playheadMs,
    this.frameAspectRatio,
  });

  @override
  ConsumerState<TextOverlayLayer> createState() => _TextOverlayLayerState();
}

class _TextOverlayLayerState extends ConsumerState<TextOverlayLayer> {
  /// Position while a drag is in progress, keyed by overlay id — kept
  /// local rather than written to the DB on every pan delta (same
  /// "local state, commit on release" pattern `TrimPanel` uses for trim
  /// handles) so dragging doesn't spam sqlite writes every frame.
  final Map<String, Offset> _dragPositions = {};

  @override
  Widget build(BuildContext context) {
    final active =
        widget.overlays.where((o) => o.activeAt(widget.playheadMs)).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    final selectedId = ref.watch(selectedTextOverlayIdProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final frame = letterboxedFrame(constraints.biggest, widget.frameAspectRatio);
        return Stack(
          children: [
            for (final overlay in active)
              _PositionedOverlay(
                key: ValueKey(overlay.id),
                overlay: overlay,
                frameOffset: frame.offset,
                frameSize: frame.size,
                isSelected: overlay.id == selectedId,
                dragPosition: _dragPositions[overlay.id],
                onSelect: () {
                  ref.read(selectedTextOverlayIdProvider.notifier).state =
                      overlay.id;
                  ref.read(textPanelOpenProvider.notifier).state = true;
                },
                onDragUpdate: (pos) =>
                    setState(() => _dragPositions[overlay.id] = pos),
                onDragEnd: () {
                  final pos = _dragPositions.remove(overlay.id);
                  if (pos == null) return;
                  ref.read(projectDatabaseProvider).updateTextOverlay(
                        overlay.copyWith(positionX: pos.dx, positionY: pos.dy),
                      );
                  setState(() {});
                },
              ),
          ],
        );
      },
    );
  }
}

class _PositionedOverlay extends StatelessWidget {
  final TextOverlay overlay;
  final Offset frameOffset;
  final Size frameSize;
  final bool isSelected;
  final Offset? dragPosition;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;

  const _PositionedOverlay({
    super.key,
    required this.overlay,
    required this.frameOffset,
    required this.frameSize,
    required this.isSelected,
    required this.dragPosition,
    required this.onSelect,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = dragPosition ?? Offset(overlay.positionX, overlay.positionY);

    return Positioned(
      left: frameOffset.dx + fraction.dx * frameSize.width,
      top: frameOffset.dy + fraction.dy * frameSize.height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSelect,
          onPanStart: (_) => onSelect(),
          onPanUpdate: (details) {
            final current = dragPosition ??
                Offset(overlay.positionX, overlay.positionY);
            onDragUpdate(dragFractionDelta(current, details.delta, frameSize));
          },
          onPanEnd: (_) => onDragEnd(),
          child: Container(
            constraints: BoxConstraints(maxWidth: frameSize.width * 0.9),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              // F8: the background-box toggle, painted behind the text
              // itself (same `boxColorValue` export's `drawtext
              // box=1:boxcolor=...` uses).
              color: overlay.boxEnabled ? Color(overlay.boxColorValue) : null,
              border: isSelected
                  ? Border.all(color: Colors.white70, width: 1)
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: _StyledOverlayText(overlay: overlay),
          ),
        ),
      ),
    );
  }
}

/// F8: renders [overlay]'s fill text, plus — when [TextOverlay.outlineWidth]
/// is set — a stroked copy of the same text behind it. `TextStyle` has no
/// native stroke, so this is the standard Flutter trick: two `Text`
/// widgets stacked, the back one painted with a stroke `Paint` via
/// `foreground`, the front one the normal filled text. [TextOverlay.bold]
/// uses a real heavier `FontWeight` here (unlike export's `drawtext`,
/// which has no bold font file bundled and has to fake it with a thin
/// border instead — see `export_command_builder.dart`'s doc comment on
/// that).
class _StyledOverlayText extends StatelessWidget {
  final TextOverlay overlay;

  const _StyledOverlayText({required this.overlay});

  @override
  Widget build(BuildContext context) {
    final weight = overlay.bold ? FontWeight.w900 : FontWeight.w600;
    final fill = Text(
      overlay.content,
      textAlign: textAlignForIndex(overlay.alignment),
      style: TextStyle(
        color: Color(overlay.colorValue),
        fontSize: overlay.fontSize,
        fontFamily: textFontPresets[overlay.fontFamily],
        fontWeight: weight,
        shadows: const [Shadow(blurRadius: 4, color: Colors.black87)],
      ),
    );
    if (overlay.outlineWidth <= 0) return fill;

    final stroke = Text(
      overlay.content,
      textAlign: textAlignForIndex(overlay.alignment),
      style: TextStyle(
        fontSize: overlay.fontSize,
        fontFamily: textFontPresets[overlay.fontFamily],
        fontWeight: weight,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = overlay.outlineWidth
          ..color = Color(overlay.outlineColorValue),
      ),
    );
    return Stack(alignment: Alignment.center, children: [stroke, fill]);
  }
}
