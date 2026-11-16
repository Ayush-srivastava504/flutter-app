import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/color_filter_x.dart';
import '../models/look_x.dart';
import 'shader_programs.dart';

/// Draws [child] with the brightness/contrast/saturation sliders and a look
/// (`models/look_x.dart`) applied — the preview side of what
/// `buildExportCommand` renders.
///
/// With Impeller (the default renderer on current Android) everything runs
/// in one GPU pass of `shaders/look.frag`. Without it, only the colour
/// matrix and vignette are shown; posterize, ink edges, sharpen, chroma
/// split, pixelate and grain then appear only in the export.
class LookFiltered extends StatefulWidget {
  final double brightness;
  final double contrast;
  final double saturation;
  final String? look;

  /// Draw this spec instead of looking up [look] (stylise effects).
  final LookSpec? spec;
  final double strength;
  final Widget child;

  /// Before/after compare: when set (0..1), the original is shown left of
  /// this fraction of the width and the filtered result right of it, with
  /// a divider and "Before" / "After" tags. Null = normal preview.
  final double? compareSplit;

  const LookFiltered({
    super.key,
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.look,
    this.spec,
    this.strength = 1.0,
    required this.child,
    this.compareSplit,
  });

  @override
  State<LookFiltered> createState() => _LookFilteredState();
}

class _LookFilteredState extends State<LookFiltered> {
  ui.FragmentProgram? _loaded;

  @override
  void initState() {
    super.initState();
    ShaderPrograms.look().then((p) {
      if (mounted && p != null) setState(() => _loaded = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _buildFiltered(context);
    final split = widget.compareSplit;
    if (split == null) return filtered;
    final look = lookById(widget.look);
    final after = look.isNone
        ? 'After · Adjusted'
        : 'After · ${look.label}${widget.strength < 0.999 ? ' ${(widget.strength * 100).round()}%' : ''}';
    return LayoutBuilder(builder: (context, c) {
      final x = c.maxWidth * split.clamp(0.0, 1.0);
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          ClipRect(clipper: _RightOf(x), child: filtered),
          Positioned(
            left: x - 1,
            top: 0,
            bottom: 0,
            width: 2,
            child: const IgnorePointer(child: ColoredBox(color: Colors.white)),
          ),
          Positioned(
            left: x - 16,
            top: c.maxHeight / 2 - 16,
            child: IgnorePointer(
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.compare_arrows, size: 20, color: Colors.black87),
              ),
            ),
          ),
          const Positioned(left: 8, top: 8, child: _Tag('Before')),
          Positioned(right: 8, top: 8, child: _Tag(after)),
        ],
      );
    });
  }

  Widget _buildFiltered(BuildContext context) {
    final spec = widget.spec;
    final look = spec != null ? ScaledLook(spec, widget.strength) : scaledLook(widget.look, widget.strength);
    final bcsNeutral = isNeutralFilter(
      brightness: widget.brightness,
      contrast: widget.contrast,
      saturation: widget.saturation,
    );
    if (bcsNeutral && look.isNone) return widget.child;

    // Sliders first, then the look's own matrix — same as the export.
    var matrix = buildColorMatrix(
      brightness: widget.brightness,
      contrast: widget.contrast,
      saturation: widget.saturation,
    );
    final lookMatrix = look.matrix;
    if (lookMatrix != null) matrix = composeMatrices(lookMatrix, matrix);

    final program = _loaded;
    if (program != null && !look.isNone && look.spec.needsShader) {
      return LayoutBuilder(builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final texWidth = (constraints.hasBoundedWidth ? constraints.maxWidth : 360) * dpr;
        return ImageFiltered(
          imageFilter: ui.ImageFilter.shader(configureLookShader(program, matrix, look, texWidth / 1080)),
          child: widget.child,
        );
      });
    }

    // Fallback: colour matrix (+ inversion) and a vignette overlay.
    if (look.negate > 0) {
      final inv = composeMatrices(invertMatrix, matrix);
      matrix = [for (var i = 0; i < 20; i++) matrix[i] + (inv[i] - matrix[i]) * look.negate];
    }
    Widget content = ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: widget.child);
    if (look.vignette > 0) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: look.vignette)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      );
    }
    return content;
  }
}

class _RightOf extends CustomClipper<Rect> {
  final double x;
  const _RightOf(this.x);

  @override
  Rect getClip(Size size) => Rect.fromLTRB(x, 0, size.width, size.height);

  @override
  bool shouldReclip(_RightOf old) => old.x != x;
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
