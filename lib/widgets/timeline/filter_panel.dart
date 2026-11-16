import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../data/database_provider.dart';
import '../../data/project_database.dart';
import '../../models/clip_x.dart';
import '../../models/color_filter_x.dart';
import '../../models/look_x.dart';
import '../look_gallery.dart';

/// The clip's Filters section, in two parts:
///
///  * **Looks** — the look gallery (categories, live thumbnails, strength)
///    plus "Use on every clip".
///  * **Adjust** — quick presets and the brightness / contrast / saturation
///    sliders, for this clip or all clips ([ProjectDatabase.applyFilterToAllClips]).
///
/// `VideoPreviewPlayer` reads the same columns live, so every change shows
/// on the preview immediately.
class FilterPanel extends ConsumerStatefulWidget {
  final Clip clip;

  const FilterPanel({super.key, required this.clip});

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

enum _Section { looks, adjust }

enum _FilterScope { thisClip, allClips }

class _FilterPanelState extends ConsumerState<FilterPanel> {
  late double _brightness;
  late double _contrast;
  late double _saturation;
  _FilterScope _scope = _FilterScope.thisClip;
  _Section _section = _Section.looks;

  @override
  void initState() {
    super.initState();
    _loadFrom(widget.clip);
  }

  @override
  void didUpdateWidget(covariant FilterPanel old) {
    super.didUpdateWidget(old);
    if (old.clip.id != widget.clip.id ||
        old.clip.brightness != widget.clip.brightness ||
        old.clip.contrast != widget.clip.contrast ||
        old.clip.saturation != widget.clip.saturation) {
      _loadFrom(widget.clip);
    }
  }

  void _loadFrom(Clip clip) {
    _brightness = clip.brightness;
    _contrast = clip.contrast;
    _saturation = clip.saturation;
  }

  void _applyPreset(FilterPreset preset) {
    setState(() {
      _brightness = preset.brightness;
      _contrast = preset.contrast;
      _saturation = preset.saturation;
    });
    _persist(filterPreset: preset.id);
  }

  /// Dragging a slider away from a preset makes it "Custom" (null preset).
  void _commit() => _persist(filterPreset: null);

  void _resetAdjust() {
    setState(() {
      _brightness = 0;
      _contrast = 0;
      _saturation = 0;
    });
    _persist(filterPreset: 'none');
  }

  void _applyLook(String id) {
    ref.read(projectDatabaseProvider).updateClip(
          // A new look starts at full strength.
          widget.clip.copyWith(look: Value(id == 'none' ? null : id), lookStrength: 1.0),
        );
  }

  Future<void> _lookToAll() async {
    await ref
        .read(projectDatabaseProvider)
        .applyLookToAllClips(widget.clip.projectId, widget.clip.look, widget.clip.lookStrength);
    if (!mounted) return;
    final name = lookById(widget.clip.look).label;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$name" is now on every clip.')));
  }

  void _persist({required String? filterPreset}) {
    final db = ref.read(projectDatabaseProvider);
    if (_scope == _FilterScope.allClips) {
      db.applyFilterToAllClips(
        widget.clip.projectId,
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        filterPreset: filterPreset,
      );
    } else {
      db.updateClip(
        widget.clip.copyWith(
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
          filterPreset: Value(filterPreset),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: SegmentedButton<_Section>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: _Section.looks, icon: Icon(Icons.palette_outlined, size: 16), label: Text('Looks')),
                  ButtonSegment(value: _Section.adjust, icon: Icon(Icons.tune, size: 16), label: Text('Adjust')),
                ],
                selected: {_section},
                onSelectionChanged: (s) => setState(() => _section = s.first),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          if (_section == _Section.looks) ..._looks() else ..._adjust(),
        ],
      ),
    );
  }

  List<Widget> _looks() => [
        LookGallery(
          imagePath: widget.clip.isPhoto ? widget.clip.sourceUri : widget.clip.thumbnailUri,
          selectedId: widget.clip.look,
          strength: widget.clip.lookStrength,
          onSelect: _applyLook,
          onStrengthCommitted: (v) => ref.read(projectDatabaseProvider).updateClip(widget.clip.copyWith(lookStrength: v)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _lookToAll,
            icon: const Icon(Icons.done_all, size: 18),
            label: Text(widget.clip.look == null ? 'Remove looks from every clip' : 'Use this look on every clip'),
          ),
        ),
      ];

  List<Widget> _adjust() {
    final activePresetId = widget.clip.filterPreset;
    final neutral = isNeutralFilter(brightness: _brightness, contrast: _contrast, saturation: _saturation);
    return [
      Row(children: [
        const Text('Apply to', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
        const SizedBox(width: 8),
        for (final (scope, label) in [(_FilterScope.thisClip, 'This clip'), (_FilterScope.allClips, 'All clips')])
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(label),
              labelStyle: const TextStyle(fontSize: 12),
              visualDensity: VisualDensity.compact,
              selected: _scope == scope,
              onSelected: (_) => setState(() => _scope = scope),
            ),
          ),
        const Spacer(),
        TextButton(onPressed: neutral ? null : _resetAdjust, child: const Text('Reset')),
      ]),
      const SizedBox(height: 4),
      SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final preset in filterPresets)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(preset.label),
                  labelStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                  selected: activePresetId == preset.id || (activePresetId == null && neutral && preset.id == 'none'),
                  onSelected: (_) => _applyPreset(preset),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      _AdjustSlider(
        icon: Icons.brightness_6_outlined,
        label: 'Brightness',
        value: _brightness,
        onChanged: (v) => setState(() => _brightness = v),
        onChangeEnd: (_) => _commit(),
      ),
      _AdjustSlider(
        icon: Icons.contrast,
        label: 'Contrast',
        value: _contrast,
        onChanged: (v) => setState(() => _contrast = v),
        onChangeEnd: (_) => _commit(),
      ),
      _AdjustSlider(
        icon: Icons.invert_colors_outlined,
        label: 'Saturation',
        value: _saturation,
        onChanged: (v) => setState(() => _saturation = v),
        onChangeEnd: (_) => _commit(),
      ),
    ];
  }
}

/// One labelled -1.0..1.0 slider centred on 0; double-tap the value to reset.
class _AdjustSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _AdjustSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final shown = (value * 100).round();
    return Row(
      children: [
        Icon(icon, color: AppColors.textDim, size: 18),
        const SizedBox(width: 6),
        SizedBox(width: 76, child: Text(label, style: const TextStyle(fontSize: 12.5))),
        Expanded(
          child: Slider(
            min: -1.0,
            max: 1.0,
            divisions: 40,
            value: value.clamp(-1.0, 1.0),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        GestureDetector(
          onDoubleTap: () {
            onChanged(0);
            onChangeEnd(0);
          },
          child: SizedBox(
            width: 36,
            child: Text(
              shown > 0 ? '+$shown' : '$shown',
              textAlign: TextAlign.right,
              style: TextStyle(color: shown == 0 ? AppColors.textFaint : AppColors.ember, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
