import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../data/database_provider.dart';
import '../../data/project_database.dart';
import '../../models/chroma_key.dart';
import '../../models/clip_x.dart';
import '../../services/media_import_service.dart';

/// The clip's Background section: colour-key background removal
/// (`models/chroma_key.dart`) with an eyedropper on the clip's own frame,
/// and a new background (colour or photo).
class BackgroundPanel extends ConsumerStatefulWidget {
  final Clip clip;
  const BackgroundPanel({super.key, required this.clip});

  @override
  ConsumerState<BackgroundPanel> createState() => _BackgroundPanelState();
}

const List<int> _bgSwatches = [0x15161A, 0xFFFFFF, 0xFF7A45, 0x2F6BFF, 0x7BD389, 0xC58BF2, 0x000000];

class _BackgroundPanelState extends ConsumerState<BackgroundPanel> {
  late ChromaKeySpec? _spec = ChromaKeySpec.tryParse(widget.clip.keyJson);
  ui.Image? _frame;
  ByteData? _pixels;
  Offset? _picked; // 0..1 in the frame

  @override
  void initState() {
    super.initState();
    _loadFrame();
  }

  @override
  void didUpdateWidget(covariant BackgroundPanel old) {
    super.didUpdateWidget(old);
    if (old.clip.keyJson != widget.clip.keyJson) _spec = ChromaKeySpec.tryParse(widget.clip.keyJson);
    if (old.clip.id != widget.clip.id) {
      _picked = null;
      _loadFrame();
    }
  }

  @override
  void dispose() {
    _frame?.dispose();
    super.dispose();
  }

  /// The clip's thumbnail (or the photo itself), small, for the eyedropper.
  Future<void> _loadFrame() async {
    final path = widget.clip.isPhoto ? widget.clip.sourceUri : widget.clip.thumbnailUri;
    if (path == null) return;
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 320);
      final frame = (await codec.getNextFrame()).image;
      final pixels = await frame.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (!mounted) return;
      setState(() {
        _frame?.dispose();
        _frame = frame;
        _pixels = pixels;
      });
    } catch (_) {
      // No eyedropper without a frame; the presets still work.
    }
  }

  void _save(ChromaKeySpec? spec) {
    setState(() => _spec = spec);
    ref.read(projectDatabaseProvider).updateClip(widget.clip.copyWith(keyJson: Value(spec?.toJson())));
  }

  void _pick(Offset local, Size box) {
    final frame = _frame, pixels = _pixels;
    if (frame == null || pixels == null) return;
    final fx = (local.dx / box.width).clamp(0.0, 0.999), fy = (local.dy / box.height).clamp(0.0, 0.999);
    // Average a small patch so a noisy pixel doesn't decide the key colour.
    var r = 0, g = 0, b = 0, count = 0;
    final cx = (fx * frame.width).floor(), cy = (fy * frame.height).floor();
    for (var y = cy - 2; y <= cy + 2; y++) {
      for (var x = cx - 2; x <= cx + 2; x++) {
        if (x < 0 || y < 0 || x >= frame.width || y >= frame.height) continue;
        final o = (y * frame.width + x) * 4;
        r += pixels.getUint8(o);
        g += pixels.getUint8(o + 1);
        b += pixels.getUint8(o + 2);
        count++;
      }
    }
    if (count == 0) return;
    setState(() => _picked = Offset(fx, fy));
    _save((_spec ?? const ChromaKeySpec()).copyWith(color: (r ~/ count) << 16 | (g ~/ count) << 8 | (b ~/ count)));
  }

  Future<void> _pickPhotoBackground() async {
    final asset = await MediaImportService().pickPhoto();
    if (asset == null || !mounted) return;
    _save((_spec ?? const ChromaKeySpec()).copyWith(bg: 'image', bgImage: asset.uri));
  }

  Future<void> _toAll() async {
    final db = ref.read(projectDatabaseProvider);
    final clips = await db.watchClips(widget.clip.projectId).first;
    for (final c in clips) {
      await db.updateClip(c.copyWith(keyJson: Value(_spec?.toJson())));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(_spec == null ? 'Background removal off for every clip.' : 'Same background removal on every clip.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.person_remove_alt_1_outlined, color: AppColors.ember),
              title: const Text('Remove background', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Green screen, blue screen or any plain single-colour wall',
                  style: TextStyle(color: AppColors.textDim, fontSize: 12)),
              value: spec != null,
              onChanged: (on) => _save(on ? const ChromaKeySpec() : null),
            ),
            if (spec != null) ..._controls(spec),
            if (spec == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Film in front of an evenly lit green or blue screen for the cleanest cut. '
                  'Cutting a person out of an ordinary room needs an AI model — not included yet.',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 11.5, height: 1.35),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _controls(ChromaKeySpec spec) {
    final despillType = despillTypeFor(spec.color);
    return [
      Row(children: [
        const Text('Key colour', style: TextStyle(fontSize: 12.5, color: AppColors.textDim)),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(spacing: 6, children: [
            _KeyChip('Green', ChromaKeySpec.greenScreen, spec.color == ChromaKeySpec.greenScreen,
                () => _save(spec.copyWith(color: ChromaKeySpec.greenScreen))),
            _KeyChip('Blue', ChromaKeySpec.blueScreen, spec.color == ChromaKeySpec.blueScreen,
                () => _save(spec.copyWith(color: ChromaKeySpec.blueScreen))),
            if (spec.color != ChromaKeySpec.greenScreen && spec.color != ChromaKeySpec.blueScreen)
              _KeyChip('Picked', spec.color, true, () {}),
          ]),
        ),
      ]),
      if (_frame != null) ...[
        const SizedBox(height: 6),
        const Text('Or tap the background in the picture to pick its colour',
            style: TextStyle(fontSize: 11.5, color: AppColors.textFaint)),
        const SizedBox(height: 6),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: SizedBox(
              height: 110,
              child: AspectRatio(
                aspectRatio: _frame!.width / _frame!.height,
                child: LayoutBuilder(builder: (context, c) {
                  final box = Size(c.maxWidth, c.maxHeight);
                  return GestureDetector(
                    onTapDown: (d) => _pick(d.localPosition, box),
                    child: Stack(fit: StackFit.expand, children: [
                      RawImage(image: _frame, fit: BoxFit.fill),
                      if (_picked != null)
                        Positioned(
                          left: _picked!.dx * box.width - 10,
                          top: _picked!.dy * box.height - 10,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              color: Color(0xFF000000 | spec.color),
                            ),
                          ),
                        ),
                    ]),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
      _Slider('Amount', spec.similarity, 0.02, 0.3, (v) => setState(() => _spec = spec.copyWith(similarity: v)),
          (v) => _save(spec.copyWith(similarity: v))),
      _Slider('Edge softness', spec.blend, 0, 0.2, (v) => setState(() => _spec = spec.copyWith(blend: v)),
          (v) => _save(spec.copyWith(blend: v))),
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: const Text('Remove colour fringe'),
        subtitle: Text(
          despillType == null ? 'Only for green or blue keys' : 'Takes the $despillType glow off hair and edges',
          style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5),
        ),
        value: spec.despill && despillType != null,
        onChanged: despillType == null ? null : (on) => _save(spec.copyWith(despill: on)),
      ),
      const SizedBox(height: 4),
      const Text('New background', style: TextStyle(fontSize: 12.5, color: AppColors.textDim)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (final c in _bgSwatches)
          GestureDetector(
            onTap: () => _save(ChromaKeySpec(
                color: spec.color,
                similarity: spec.similarity,
                blend: spec.blend,
                despill: spec.despill,
                bg: 'color',
                bgColor: c)),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Color(0xFF000000 | c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: !spec.usesImage && spec.bgColor == c ? AppColors.ember : AppColors.line,
                  width: !spec.usesImage && spec.bgColor == c ? 2.5 : 1,
                ),
              ),
            ),
          ),
        ActionChip(
          avatar: Icon(spec.usesImage ? Icons.check : Icons.add_photo_alternate_outlined, size: 16),
          label: Text(spec.usesImage ? 'Photo set' : 'Photo…'),
          onPressed: _pickPhotoBackground,
        ),
      ]),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _toAll,
          icon: const Icon(Icons.done_all, size: 18),
          label: const Text('Use on every clip'),
        ),
      ),
    ];
  }
}

class _KeyChip extends StatelessWidget {
  final String label;
  final int color;
  final bool selected;
  final VoidCallback onTap;
  const _KeyChip(this.label, this.color, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) => ChoiceChip(
        avatar: CircleAvatar(backgroundColor: Color(0xFF000000 | color), radius: 7),
        label: Text(label),
        labelStyle: const TextStyle(fontSize: 12),
        visualDensity: VisualDensity.compact,
        selected: selected,
        onSelected: (_) => onTap(),
      );
}

class _Slider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onEnd;
  const _Slider(this.label, this.value, this.min, this.max, this.onChanged, this.onEnd);

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(width: 92, child: Text(label, style: const TextStyle(fontSize: 12.5))),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: onEnd,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text('${((value - min) / (max - min) * 100).round()}',
              textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
        ),
      ]);
}
