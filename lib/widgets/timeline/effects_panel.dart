import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../data/database_provider.dart';
import '../../data/project_database.dart';
import '../../models/clip_x.dart';
import '../../models/effect_x.dart';
import '../look_filtered.dart';
import '../glow_overlay.dart';

/// The clip's Effects section: one effect per clip (on top of its look),
/// in two groups — Motion (zoom, pan, pulse, shake, flash) and Stylise
/// (VHS, glitch, grain…) — with a strength slider and "use on every clip".
class EffectsPanel extends ConsumerStatefulWidget {
  final Clip clip;
  const EffectsPanel({super.key, required this.clip});

  @override
  ConsumerState<EffectsPanel> createState() => _EffectsPanelState();
}

const Map<String, IconData> _motionIcons = {
  'fx_zoom_in': Icons.zoom_in,
  'fx_zoom_out': Icons.zoom_out,
  'fx_pan': Icons.panorama_horizontal,
  'fx_pulse': Icons.radio_button_checked,
  'fx_shake': Icons.vibration,
  'fx_flash': Icons.flash_on,
};

class _EffectsPanelState extends ConsumerState<EffectsPanel> {
  late double _strength = widget.clip.effectStrength;

  @override
  void didUpdateWidget(covariant EffectsPanel old) {
    super.didUpdateWidget(old);
    if (old.clip.id != widget.clip.id || old.clip.effectStrength != widget.clip.effectStrength) {
      _strength = widget.clip.effectStrength;
    }
  }

  void _select(String? id) {
    final current = widget.clip.effect;
    final next = id == current ? null : id; // tapping the active one turns it off
    ref.read(projectDatabaseProvider).updateClip(widget.clip.copyWith(effect: Value(next), effectStrength: 1.0));
  }

  Future<void> _toAll() async {
    await ref
        .read(projectDatabaseProvider)
        .applyEffectToAllClips(widget.clip.projectId, widget.clip.effect, widget.clip.effectStrength);
    if (!mounted) return;
    final e = effectById(widget.clip.effect);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e == null ? 'Effects removed from every clip.' : '"${e.label}" is now on every clip.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final selected = effectById(widget.clip.effect);
    final thumb = widget.clip.isPhoto ? widget.clip.sourceUri : widget.clip.thumbnailUri;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _GroupLabel('Motion', 'Moves the picture over the length of the clip'),
          SizedBox(
            height: 84,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              _EffectTile(
                label: 'None',
                selected: selected == null,
                onTap: () => _select(null),
                child: const Icon(Icons.block, color: AppColors.textDim),
              ),
              for (final e in effectPresets.where((e) => e.kind == EffectKind.motion))
                _EffectTile(
                  label: e.label,
                  selected: selected?.id == e.id,
                  onTap: () => _select(e.id),
                  child: Icon(_motionIcons[e.id] ?? Icons.animation, color: AppColors.text),
                ),
            ]),
          ),
          const SizedBox(height: 6),
          const _GroupLabel('Stylise', 'Texture on top of the clip\'s look'),
          SizedBox(
            height: 84,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final e in effectPresets.where((e) => e.kind == EffectKind.stylise))
                _EffectTile(
                  label: e.label,
                  selected: selected?.id == e.id,
                  onTap: () => _select(e.id),
                  child: LookFiltered(spec: e.style, child: _Thumb(path: thumb)),
                ),
            ]),
          ),
          const SizedBox(height: 6),
          const _GroupLabel('Glow', 'Soft light blooming from the bright parts'),
          SizedBox(
            height: 84,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final e in effectPresets.where((e) => e.kind == EffectKind.glow))
                _EffectTile(
                  label: e.label,
                  selected: selected?.id == e.id,
                  onTap: () => _select(e.id),
                  child: Stack(fit: StackFit.expand, children: [
                    _Thumb(path: thumb),
                    GlowOverlay(effectId: e.id, strength: 1),
                  ]),
                ),
            ]),
          ),
          if (selected != null) ...[
            const SizedBox(height: 4),
            Text(selected.hint, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
            Row(children: [
              const Icon(Icons.tune, size: 16, color: AppColors.textDim),
              const SizedBox(width: 6),
              const Text('Strength', style: TextStyle(fontSize: 12.5)),
              Expanded(
                child: Slider(
                  value: _strength.clamp(0.0, 1.0),
                  divisions: 20,
                  onChanged: (v) => setState(() => _strength = v),
                  onChangeEnd: (v) =>
                      ref.read(projectDatabaseProvider).updateClip(widget.clip.copyWith(effectStrength: v)),
                ),
              ),
              SizedBox(
                width: 38,
                child: Text('${(_strength * 100).round()}%',
                    textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              ),
            ]),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _toAll,
              icon: const Icon(Icons.done_all, size: 18),
              label: Text(selected == null ? 'Remove effects from every clip' : 'Use this effect on every clip'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String title;
  final String hint;
  const _GroupLabel(this.title, this.hint);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(hint,
                overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5)),
          ),
        ]),
      );
}

class _EffectTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  const _EffectTile({required this.label, required this.selected, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 66,
        margin: const EdgeInsets.only(right: 8),
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? AppColors.ember : AppColors.line, width: selected ? 2 : 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: ColoredBox(color: AppColors.surfaceHigh, child: Center(child: child)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.ember : AppColors.textDim,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              )),
        ]),
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
    const fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF3A2A24), Color(0xFF23303A)]),
      ),
      child: SizedBox.expand(),
    );
    if (p == null) return fallback;
    return Image.file(File(p),
        width: 60, height: 60, fit: BoxFit.cover, cacheWidth: 140, errorBuilder: (_, __, ___) => fallback);
  }
}
