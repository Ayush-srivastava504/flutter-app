import 'dart:io';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/look_x.dart';
import 'look_filtered.dart';

/// A horizontal strip of look tiles, each showing [imagePath] (the clip's
/// thumbnail, or the photo itself) with that look applied, grouped by
/// category tabs, plus a strength slider for the selected look.
class LookGallery extends StatefulWidget {
  final String? imagePath;
  final String? selectedId;
  final double strength;
  final ValueChanged<String> onSelect;

  /// Called while dragging (for a live preview) — may be null.
  final ValueChanged<double>? onStrengthChanged;

  /// Called once when the drag ends (persist here).
  final ValueChanged<double> onStrengthCommitted;

  /// Look ids picked for this image (`suggestLooks`); when non-empty a
  /// "For this photo" tab is shown first and opened by default.
  final List<String> suggested;

  const LookGallery({
    super.key,
    required this.imagePath,
    required this.selectedId,
    required this.strength,
    required this.onSelect,
    this.onStrengthChanged,
    required this.onStrengthCommitted,
    this.suggested = const [],
  });

  @override
  State<LookGallery> createState() => _LookGalleryState();
}

class _LookGalleryState extends State<LookGallery> {
  LookCategory? _category; // null = all
  late bool _forYou = widget.suggested.isNotEmpty;
  late double _strength = widget.strength;

  @override
  void didUpdateWidget(covariant LookGallery old) {
    super.didUpdateWidget(old);
    if (old.suggested.isEmpty && widget.suggested.isNotEmpty) _forYou = true;
    if (old.strength != widget.strength || old.selectedId != widget.selectedId) _strength = widget.strength;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selectedId ?? 'none';
    final looks = _forYou && widget.suggested.isNotEmpty
        ? [lookPresets.first, for (final id in widget.suggested) lookById(id)]
        : [
            for (final l in lookPresets)
              if (_category == null || l.isNone || l.category == _category) l,
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 30,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (widget.suggested.isNotEmpty)
                _CategoryTab(
                  label: '✨ For this photo',
                  selected: _forYou,
                  onTap: () => setState(() => _forYou = true),
                ),
              _CategoryTab(
                label: 'All',
                selected: !_forYou && _category == null,
                onTap: () => setState(() {
                  _forYou = false;
                  _category = null;
                }),
              ),
              for (final c in LookCategory.values)
                _CategoryTab(
                  label: lookCategoryLabel(c),
                  selected: !_forYou && _category == c,
                  onTap: () => setState(() {
                    _forYou = false;
                    _category = c;
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: looks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final look = looks[i];
              final isSelected = look.id == selected;
              return GestureDetector(
                onTap: () => widget.onSelect(look.id),
                child: SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? scheme.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: RepaintBoundary(
                            child: LookFiltered(look: look.id, child: _Thumb(path: widget.imagePath)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        look.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? scheme.primary : AppColors.textDim,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (selected != 'none')
          Row(
            children: [
              const Icon(Icons.tune, size: 16, color: AppColors.textDim),
              const SizedBox(width: 6),
              const Text('Strength', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _strength.clamp(0.0, 1.0),
                  divisions: 20,
                  onChanged: (v) {
                    setState(() => _strength = v);
                    widget.onStrengthChanged?.call(v);
                  },
                  onChangeEnd: widget.onStrengthCommitted,
                ),
              ),
              SizedBox(
                width: 36,
                child: Text('${(_strength * 100).round()}%',
                    textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
              ),
            ],
          ),
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? scheme.primary.withValues(alpha: 0.2) : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: selected ? scheme.primary : AppColors.textDim),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? path;
  const _Thumb({required this.path});

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p == null) {
      // No thumbnail yet: a colourful gradient still shows what a look does.
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB74D), Color(0xFF4FC3F7), Color(0xFF7E57C2)],
          ),
        ),
      );
    }
    return Image.file(
      File(p),
      fit: BoxFit.cover,
      cacheWidth: 160,
      errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.surfaceHigh),
    );
  }
}
