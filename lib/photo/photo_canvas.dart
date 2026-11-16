import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../widgets/look_filtered.dart';
import '../widgets/shader_programs.dart';
import 'photo_edit.dart';
import 'photo_renderer.dart';

/// The photo on screen with every edit applied, in the same order as the
/// full-resolution export: geometry → Tune shader → look shader.
///
/// [showOriginal] draws the untouched photo instead (hold-to-compare).
class PhotoCanvas extends StatefulWidget {
  final String sourcePath;
  final PhotoEdit edit;
  final bool showOriginal;

  const PhotoCanvas({super.key, required this.sourcePath, required this.edit, this.showOriginal = false});

  @override
  State<PhotoCanvas> createState() => _PhotoCanvasState();
}

class _PhotoCanvasState extends State<PhotoCanvas> {
  /// Longest side of the on-screen copy: sharp on a 1440p display while
  /// keeping shader work small. The export decodes the full file.
  static const int previewSide = 2048;

  ui.Image? _image;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant PhotoCanvas old) {
    super.didUpdateWidget(old);
    if (old.sourcePath != widget.sourcePath) _decode();
  }

  Future<void> _decode() async {
    try {
      final img = await decodePhoto(widget.sourcePath, maxSide: previewSide);
      if (!mounted) {
        img.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = img;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    if (_error != null) {
      return const Center(child: Text("Couldn't open this photo.", style: TextStyle(color: Colors.white54)));
    }
    if (img == null) return const Center(child: CircularProgressIndicator());

    if (widget.showOriginal) {
      return Center(
        child: AspectRatio(
          aspectRatio: img.width / img.height,
          child: RawImage(image: img, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
        ),
      );
    }

    final crop = croppedSize(widget.edit, img.width.toDouble(), img.height.toDouble());
    return Center(
      child: AspectRatio(
        aspectRatio: crop.width / crop.height,
        child: LookFiltered(
          look: widget.edit.look,
          strength: widget.edit.lookStrength,
          child: AdjustFiltered(
            edit: widget.edit,
            child: CustomPaint(painter: _GeometryPainter(img, widget.edit), size: Size.infinite),
          ),
        ),
      ),
    );
  }
}

class _GeometryPainter extends CustomPainter {
  final ui.Image image;
  final PhotoEdit edit;
  _GeometryPainter(this.image, this.edit);

  @override
  void paint(Canvas canvas, Size size) => paintGeometry(canvas, image, edit, size);

  @override
  bool shouldRepaint(_GeometryPainter old) =>
      old.image != image ||
      old.edit.turns != edit.turns ||
      old.edit.flipH != edit.flipH ||
      old.edit.flipV != edit.flipV ||
      old.edit.straighten != edit.straighten ||
      old.edit.cropRatio != edit.cropRatio;
}

/// Applies the Tune shader (`shaders/adjust.frag`) to [child]. Without
/// shader support it shows [child] unchanged (Tune then only appears in a
/// device that supports it — the export reports that as incomplete).
class AdjustFiltered extends StatefulWidget {
  final PhotoEdit edit;
  final Widget child;
  const AdjustFiltered({super.key, required this.edit, required this.child});

  @override
  State<AdjustFiltered> createState() => _AdjustFilteredState();
}

class _AdjustFilteredState extends State<AdjustFiltered> {
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    ShaderPrograms.adjust().then((p) {
      if (mounted && p != null) setState(() => _program = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final program = _program;
    if (program == null || !widget.edit.hasAdjust) return widget.child;
    return LayoutBuilder(builder: (context, c) {
      final texWidth = c.maxWidth * MediaQuery.devicePixelRatioOf(context);
      return ImageFiltered(
        imageFilter: ui.ImageFilter.shader(configureAdjustShader(program, widget.edit, texWidth / 1080)),
        child: widget.child,
      );
    });
  }
}
