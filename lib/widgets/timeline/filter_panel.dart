import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database_provider.dart';
import '../../data/project_database.dart';
import '../../models/color_filter_x.dart';

/// Shown alongside [TrimPanel] (via `EditorScreen`'s clip-panel tab
/// switch) whenever a clip is selected: brightness/contrast/saturation
/// sliders plus the bundled preset chips. `VideoPreviewPlayer` reads
/// these same three columns live, so every drag/tap here shows up on
/// the preview immediately — see its Phase 7 doc comment.
///
/// Phase 7 (second half) adds the scope toggle: "This clip" (the
/// original, still the default) edits only [clip]'s row; "All clips"
/// applies the same brightness/contrast/saturation to every clip in
/// the project at once via [ProjectDatabase.applyFilterToAllClips] —
/// the "globally" half of the spec's item 3.
class FilterPanel extends ConsumerStatefulWidget {
  final Clip clip;

  const FilterPanel({super.key, required this.clip});

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

enum _FilterScope { thisClip, allClips }

class _FilterPanelState extends ConsumerState<FilterPanel> {
  late double _brightness;
  late double _contrast;
  late double _saturation;
  _FilterScope _scope = _FilterScope.thisClip;

  @override
  void initState() {
    super.initState();
    _loadFrom(widget.clip);
  }

  @override
  void didUpdateWidget(covariant FilterPanel old) {
    super.didUpdateWidget(old);
    if (old.clip.id != widget.clip.id) _loadFrom(widget.clip);
  }

  void _loadFrom(Clip clip) {
    _brightness = clip.brightness;
    _contrast = clip.contrast;
    _saturation = clip.saturation;
  }

  /// Applies [preset]'s fixed values immediately (presets are a single
  /// tap, not a drag, so there's no separate "commit on release" step
  /// the way the sliders below have).
  void _applyPreset(FilterPreset preset) {
    setState(() {
      _brightness = preset.brightness;
      _contrast = preset.contrast;
      _saturation = preset.saturation;
    });
    _persist(filterPreset: preset.id);
  }

  /// Persists the current slider values. Dragging a slider away from
  /// whatever preset was active makes this "Custom" — [filterPreset] is
  /// cleared to null rather than left pointing at a preset whose exact
  /// numbers no longer match, so no chip stays incorrectly highlighted.
  void _commit() => _persist(filterPreset: null);

  /// Routes to either a single-clip update or the project-wide bulk
  /// update, depending on [_scope] — the one place that decision is
  /// made, so [_applyPreset]/[_commit] don't each need their own
  /// if/else.
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
    final activePresetId = widget.clip.filterPreset;

    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Apply to:',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('This clip'),
                labelStyle: const TextStyle(fontSize: 12),
                selected: _scope == _FilterScope.thisClip,
                onSelected: (_) =>
                    setState(() => _scope = _FilterScope.thisClip),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('All clips'),
                labelStyle: const TextStyle(fontSize: 12),
                selected: _scope == _FilterScope.allClips,
                onSelected: (_) =>
                    setState(() => _scope = _FilterScope.allClips),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final preset in filterPresets)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(preset.label),
                      labelStyle: const TextStyle(fontSize: 12),
                      selected: activePresetId == preset.id ||
                          (activePresetId == null && preset.id == 'none'),
                      onSelected: (_) => _applyPreset(preset),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
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
        ],
      ),
    );
  }
}

/// One labeled -1.0..1.0 slider, centered on 0 (`divisions` gives a
/// faint tick there so "no change" is easy to find by feel).
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
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
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
        SizedBox(
          width: 32,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
