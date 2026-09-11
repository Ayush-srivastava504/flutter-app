import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database_provider.dart';
import '../../data/project_database.dart';
import '../../models/text_overlay_x.dart';
import '../../providers/text_overlay_providers.dart';

/// Shown when a text overlay is selected (tapped on the canvas, or just
/// created via `EditorScreen`'s text tool): content, font/size/color/
/// alignment, drag-free timing (two sliders bounded by the video
/// timeline's total length), and delete.
///
/// Positioning itself isn't edited here — that's the canvas drag in
/// `TextOverlayLayer`, same split `AudioTrackPanel` uses (this panel
/// edits values; the canvas widget is what actually shows/moves them).
class TextOverlayPanel extends ConsumerStatefulWidget {
  final TextOverlay overlay;
  final int totalTimelineMs;

  const TextOverlayPanel({
    super.key,
    required this.overlay,
    required this.totalTimelineMs,
  });

  @override
  ConsumerState<TextOverlayPanel> createState() => _TextOverlayPanelState();
}

class _TextOverlayPanelState extends ConsumerState<TextOverlayPanel> {
  late TextEditingController _contentController;
  late String _fontFamilyKey;
  late double _fontSize;
  late int _colorValue;
  late int _alignment;
  late double _startMs;
  late double _endMs;

  @override
  void initState() {
    super.initState();
    _loadFrom(widget.overlay);
  }

  @override
  void didUpdateWidget(covariant TextOverlayPanel old) {
    super.didUpdateWidget(old);
    if (old.overlay.id != widget.overlay.id) _loadFrom(widget.overlay);
  }

  void _loadFrom(TextOverlay o) {
    _contentController = TextEditingController(text: o.content);
    _fontFamilyKey = textFontPresets.containsKey(o.fontFamily)
        ? o.fontFamily
        : 'Default';
    _fontSize = o.fontSize;
    _colorValue = o.colorValue;
    _alignment = o.alignment;
    _startMs = o.startMs.toDouble();
    _endMs = o.endMs.toDouble();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _commit() {
    ref.read(projectDatabaseProvider).updateTextOverlay(
          widget.overlay.copyWith(
            content: _contentController.text.trim().isEmpty
                ? ' '
                : _contentController.text,
            fontFamily: _fontFamilyKey,
            fontSize: _fontSize,
            colorValue: _colorValue,
            alignment: _alignment,
            startMs: _startMs.round(),
            endMs: _endMs.round(),
          ),
        );
  }

  Future<void> _delete() async {
    await ref.read(projectDatabaseProvider).deleteTextOverlay(widget.overlay.id);
    ref.read(selectedTextOverlayIdProvider.notifier).state = null;
    ref.read(textPanelOpenProvider.notifier).state = false;
  }

  void _close() {
    ref.read(textPanelOpenProvider.notifier).state = false;
    ref.read(selectedTextOverlayIdProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    // Timing sliders need a real span to work over — fall back to a 5s
    // window if there's no video yet (text-only project) so the slider
    // isn't degenerate at max==0.
    final maxMs = widget.totalTimelineMs > 0
        ? widget.totalTimelineMs.toDouble()
        : (_endMs > 0 ? _endMs : 5000.0);
    final startMs = _startMs.clamp(0.0, maxMs);
    final minEndMs = (startMs + 100).clamp(0.0, maxMs);
    final endMs = _endMs.clamp(minEndMs, maxMs);

    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.title, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                const Text('Text', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Delete text',
                  onPressed: _delete,
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white70),
                  tooltip: 'Done',
                  onPressed: () {
                    _commit();
                    _close();
                  },
                ),
              ],
            ),
            TextField(
              controller: _contentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Enter text',
                hintStyle: TextStyle(color: Colors.white38),
                isDense: true,
              ),
              onChanged: (_) => _commit(),
            ),
            const _SectionLabel('Font'),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in textFontPresets.entries)
                  ChoiceChip(
                    label: Text(entry.key),
                    selected: _fontFamilyKey == entry.key,
                    onSelected: (_) {
                      setState(() => _fontFamilyKey = entry.key);
                      _commit();
                    },
                  ),
              ],
            ),
            const _SectionLabel('Size'),
            Slider(
              value: _fontSize.clamp(12, 72),
              min: 12,
              max: 72,
              divisions: 60,
              label: _fontSize.round().toString(),
              onChanged: (v) => setState(() => _fontSize = v),
              onChangeEnd: (_) => _commit(),
            ),
            const _SectionLabel('Color'),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final color in textColorPresets)
                    GestureDetector(
                      onTap: () {
                        setState(() => _colorValue = color.value);
                        _commit();
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _colorValue == color.value
                                ? Colors.white
                                : Colors.white24,
                            width: _colorValue == color.value ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const _SectionLabel('Alignment'),
            Row(
              children: [
                for (var i = 0; i < textAlignmentIcons.length; i++)
                  IconButton(
                    icon: Icon(
                      textAlignmentIcons[i],
                      color: _alignment == i ? Colors.white : Colors.white38,
                    ),
                    onPressed: () {
                      setState(() => _alignment = i);
                      _commit();
                    },
                  ),
              ],
            ),
            _SectionLabel(
              'Timing  ${(startMs / 1000).toStringAsFixed(1)}s – '
              '${(endMs / 1000).toStringAsFixed(1)}s',
            ),
            RangeSlider(
              values: RangeValues(startMs, endMs),
              min: 0,
              max: maxMs,
              onChanged: (range) {
                setState(() {
                  _startMs = range.start;
                  _endMs = range.end < range.start + 100
                      ? range.start + 100
                      : range.end;
                });
              },
              onChangeEnd: (_) => _commit(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    );
  }
}
