import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database_provider.dart';
import '../data/project_database.dart';
import '../photo/auto_enhance.dart';
import '../photo/photo_canvas.dart';
import '../photo/photo_edit.dart';
import '../photo/photo_export_service.dart';
import '../photo/photo_renderer.dart' show decodePhoto;
import '../widgets/look_gallery.dart';

/// Photo Studio editor (MASTER_PLAN Phase 1): Tune, Looks, Crop & rotate,
/// hold-to-compare, undo/redo, full-resolution save.
///
/// The edit is held here while editing and written to the database when a
/// change is committed (slider released, chip tapped), never per drag frame.
class PhotoEditorScreen extends ConsumerStatefulWidget {
  final String photoId;
  const PhotoEditorScreen({super.key, required this.photoId});

  @override
  ConsumerState<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

enum _Tool { tune, looks, crop }

class _PhotoEditorScreenState extends ConsumerState<PhotoEditorScreen> {
  PhotoProject? _photo;
  PhotoEdit _edit = const PhotoEdit();
  final List<PhotoEdit> _undo = [];
  final List<PhotoEdit> _redo = [];
  _Tool _tool = _Tool.tune;
  String _param = adjustParams.first.id;
  bool _comparing = false;
  bool _saving = false;

  /// Measured once per photo (small decode) — drives Auto and the
  /// "For this photo" looks.
  PhotoStats? _stats;
  List<String> _suggested = const [];

  /// Edit at the start of an in-progress slider drag (one undo step per drag).
  PhotoEdit? _dragStart;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final photo = await ref.read(projectDatabaseProvider).getPhotoProject(widget.photoId);
    if (!mounted) return;
    setState(() {
      _photo = photo;
      _edit = PhotoEdit.decode(photo?.editJson);
    });
    if (photo != null) unawaited(_analyze(photo.sourceUri));
  }

  Future<void> _analyze(String path) async {
    try {
      final img = await decodePhoto(path, maxSide: 256);
      final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      final w = img.width, h = img.height;
      img.dispose();
      if (data == null || !mounted) return;
      final stats = analyzeRgba(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), w, h);
      setState(() {
        _stats = stats;
        _suggested = suggestLooks(stats);
      });
    } catch (e) {
      debugPrint('[photo] analysis failed: $e');
    }
  }

  /// One tap: set the Tune sliders Auto measured for this photo. Sliders
  /// Auto doesn't touch (fade, vignette, grain…) keep the user's values.
  void _autoEnhance() {
    final stats = _stats;
    if (stats == null) return;
    final auto = autoAdjust(stats);
    var next = _edit;
    for (final p in const ['exposure', 'blacks', 'whites', 'shadows', 'highlights', 'contrast', 'warmth', 'tint',
        'vibrance', 'clarity', 'sharpen']) {
      next = next.withAdjust(p, auto[p] ?? 0);
    }
    _commit(next);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(auto.isEmpty
            ? 'This photo already looks balanced.'
            : 'Auto-enhanced ${auto.length} settings. Tap Undo to go back.'),
      ));
  }

  // --- edits ----------------------------------------------------------------

  /// A finished change: record undo, save.
  void _commit(PhotoEdit next, {PhotoEdit? before}) {
    final from = before ?? _edit;
    if (next == from) {
      setState(() => _edit = next);
      return;
    }
    setState(() {
      _undo.add(from);
      if (_undo.length > 100) _undo.removeAt(0);
      _redo.clear();
      _edit = next;
    });
    _persist();
  }

  /// Live change while dragging (no undo entry, no save yet).
  void _preview(PhotoEdit next) {
    _dragStart ??= _edit;
    setState(() => _edit = next);
  }

  void _endDrag() {
    final start = _dragStart;
    _dragStart = null;
    if (start != null) _commit(_edit, before: start);
  }

  void _undoEdit() {
    if (_undo.isEmpty) return;
    setState(() {
      _redo.add(_edit);
      _edit = _undo.removeLast();
    });
    _persist();
  }

  void _redoEdit() {
    if (_redo.isEmpty) return;
    setState(() {
      _undo.add(_edit);
      _edit = _redo.removeLast();
    });
    _persist();
  }

  void _persist() {
    unawaited(ref.read(projectDatabaseProvider).savePhotoEdit(widget.photoId, _edit.encode()));
  }

  // --- save -----------------------------------------------------------------

  Future<void> _save() async {
    final photo = _photo;
    if (photo == null || _saving) return;
    final format = await showModalBottomSheet<PhotoFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Save a copy at full resolution', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            for (final f in PhotoFormat.values)
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(f.label),
                subtitle: Text(const {
                  PhotoFormat.jpeg: 'Best for sharing — small, high quality',
                  PhotoFormat.png: 'Lossless — largest file',
                  PhotoFormat.webp: 'Smallest file, good quality',
                }[f]!),
                onTap: () => Navigator.pop(context, f),
              ),
          ],
        ),
      ),
    );
    if (format == null || !mounted) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await PhotoExportService().export(sourcePath: photo.sourceUri, edit: _edit, format: format);
      messenger.showSnackBar(SnackBar(
        content: Text(r.complete
            ? 'Saved to gallery (${r.width}×${r.height}).'
            : 'Saved, but this device couldn\'t render every effect.'),
        // Flutter 3.4x makes a SnackBar with an action persist by default;
        // this one followed the user back to Home and covered the audio row.
        persist: false,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () => Share.shareXFiles([XFile(r.path)], text: 'Edited with ClipForge'),
        ),
      ));
    } on PhotoExportException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Couldn\'t save the photo: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // --- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(photo?.name ?? 'Photo', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _undo.isEmpty ? null : _undoEdit,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: _redo.isEmpty ? null : _redoEdit,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: photo == null || _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: photo == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(child: _canvas(photo)),
                  _toolPanel(photo),
                  _toolTabs(),
                ],
              ),
            ),
    );
  }

  Widget _canvas(PhotoProject photo) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            // Hold anywhere on the photo to see the original.
            onLongPressStart: (_) => setState(() => _comparing = true),
            onLongPressEnd: (_) => setState(() => _comparing = false),
            child: InteractiveViewer(
              maxScale: 8,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: PhotoCanvas(sourcePath: photo.sourceUri, edit: _edit, showOriginal: _comparing),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 8,
          child: AnimatedOpacity(
            opacity: _comparing ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: const _Tag('Original'),
          ),
        ),
        if (!_edit.isOriginal)
          Positioned(
            right: 12,
            bottom: 8,
            child: Listener(
              // A button you press and hold, for people who don't know the
              // long-press gesture.
              onPointerDown: (_) => setState(() => _comparing = true),
              onPointerUp: (_) => setState(() => _comparing = false),
              onPointerCancel: (_) => setState(() => _comparing = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.compare, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Hold to compare', style: TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _toolTabs() {
    Widget tab(_Tool t, IconData icon, String label) {
      final selected = _tool == t;
      final color = selected ? Theme.of(context).colorScheme.primary : Colors.white60;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tool = t),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: color),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ]),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.surface,
      child: Row(children: [
        tab(_Tool.tune, Icons.tune, 'Tune'),
        tab(_Tool.looks, Icons.auto_awesome, 'Looks'),
        tab(_Tool.crop, Icons.crop_rotate, 'Crop'),
      ]),
    );
  }

  Widget _toolPanel(PhotoProject photo) {
    return Container(
      color: AppColors.surfaceHigh,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: switch (_tool) {
        _Tool.tune => _tunePanel(),
        _Tool.looks => LookGallery(
            imagePath: photo.sourceUri,
            selectedId: _edit.look,
            strength: _edit.lookStrength,
            onSelect: (id) => _commit(_edit.copyWith(look: id == 'none' ? null : id, lookStrength: 1.0)),
            onStrengthChanged: (v) => _preview(_edit.copyWith(lookStrength: v)),
            onStrengthCommitted: (v) {
              _preview(_edit.copyWith(lookStrength: v));
              _endDrag();
            },
            suggested: _suggested,
          ),
        _Tool.crop => _cropPanel(),
      },
    );
  }

  Widget _tunePanel() {
    final param = adjustParamById(_param);
    final value = _edit.value(param.id);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  avatar: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Auto'),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  onPressed: _stats == null ? null : _autoEnhance,
                ),
              ),
              for (final p in adjustParams)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(p.label),
                    labelStyle: const TextStyle(fontSize: 12),
                    // A dot on tools that are in use, so edits are easy to find.
                    avatar: _edit.value(p.id) != 0
                        ? Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary)
                        : null,
                    selected: _param == p.id,
                    onSelected: (_) => setState(() => _param = p.id),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                min: param.min,
                max: param.max,
                value: value.clamp(param.min, param.max),
                onChanged: (v) => _preview(_edit.withAdjust(param.id, (v * 100).round() / 100)),
                onChangeEnd: (_) => _endDrag(),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '${value > 0 ? '+' : ''}${(value * 100).round()}',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt, size: 20),
              tooltip: 'Reset ${param.label}',
              onPressed: value == 0 ? null : () => _commit(_edit.withAdjust(param.id, 0)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cropPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (label, ratio) in cropRatios)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(label),
                    labelStyle: const TextStyle(fontSize: 12),
                    selected: _edit.cropRatio == ratio,
                    onSelected: (_) => _commit(_edit.copyWith(cropRatio: ratio)),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
              tooltip: 'Rotate 90°',
              onPressed: () => _commit(_edit.copyWith(turns: (_edit.turns + 1) % 4)),
            ),
            IconButton(
              icon: Icon(Icons.flip, color: _edit.flipH ? Theme.of(context).colorScheme.primary : null),
              tooltip: 'Flip horizontal',
              onPressed: () => _commit(_edit.copyWith(flipH: !_edit.flipH)),
            ),
            IconButton(
              icon: RotatedBox(
                quarterTurns: 1,
                child: Icon(Icons.flip, color: _edit.flipV ? Theme.of(context).colorScheme.primary : null),
              ),
              tooltip: 'Flip vertical',
              onPressed: () => _commit(_edit.copyWith(flipV: !_edit.flipV)),
            ),
            const Icon(Icons.straighten, size: 18, color: Colors.white54),
            Expanded(
              child: Slider(
                min: -45,
                max: 45,
                divisions: 180,
                value: _edit.straighten,
                onChanged: (v) => _preview(_edit.copyWith(straighten: v)),
                onChangeEnd: (_) => _endDrag(),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text('${_edit.straighten.toStringAsFixed(1)}°',
                  textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}
