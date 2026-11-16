import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../models/chroma_key.dart';
import '../models/color_filter_x.dart';
import '../models/look_x.dart';
import '../photo/photo_edit.dart';

/// Loads the app's fragment shaders once, and fills their uniforms. The
/// preview widgets and the full-resolution photo renderer both go through
/// here, so a shader is always configured the same way.
///
/// Programs are null when the device can't use shader image filters (no
/// Impeller) or the asset fails to load; callers then fall back.
class ShaderPrograms {
  static Future<ui.FragmentProgram?>? _look;
  static Future<ui.FragmentProgram?>? _adjust;
  static Future<ui.FragmentProgram?>? _key;

  static Future<ui.FragmentProgram?> look() => _look ??= _load('shaders/look.frag');
  static Future<ui.FragmentProgram?> adjust() => _adjust ??= _load('shaders/adjust.frag');
  static Future<ui.FragmentProgram?> key() => _key ??= _load('shaders/key.frag');

  static Future<ui.FragmentProgram?> _load(String asset) async {
    if (!ui.ImageFilter.isShaderFilterSupported) return null;
    try {
      return await ui.FragmentProgram.fromAsset(asset);
    } catch (e) {
      debugPrint('[shader] $asset unavailable: $e');
      return null;
    }
  }
}

/// The look shader's uniforms (layout must match `shaders/look.frag`).
/// [matrix] is the combined slider + look matrix; [pxScale] is texture
/// pixels per 1080 px of frame width.
ui.FragmentShader configureLookShader(
  ui.FragmentProgram program,
  List<double> matrix,
  ScaledLook look,
  double pxScale,
) {
  final s = program.fragmentShader();
  var i = 2; // 0,1 = uSize, set by the engine
  void put(double v) => s.setFloat(i++, v);
  for (final row in [0, 5, 10]) {
    put(matrix[row]);
    put(matrix[row + 1]);
    put(matrix[row + 2]);
    put(matrix[row + 4] / 255);
  }
  put(look.negate);
  put(look.pixelate * pxScale);
  put(look.posterize.toDouble());
  put(look.posterizeMix);
  put(look.edges);
  put(look.sharpen);
  put(look.chroma * pxScale);
  put(look.grain);
  put(look.vignette);
  put(17.0); // grain seed
  put(0);
  put(0);
  final sh = look.shadows ?? const [0.0, 0.0, 0.0];
  final hi = look.highlights ?? const [0.0, 0.0, 0.0];
  for (final v in [...sh, 0.0, ...hi, 0.0]) {
    put(v);
  }
  return s;
}

/// The colour matrix the look shader gets for [look] (no slider adjust).
List<double> lookMatrixFor(ScaledLook look) {
  final m = look.matrix;
  return m ?? buildColorMatrix();
}

/// The Tune shader's uniforms (layout must match `shaders/adjust.frag`).
ui.FragmentShader configureAdjustShader(ui.FragmentProgram program, PhotoEdit edit, double pxScale) {
  final s = program.fragmentShader();
  var i = 2;
  void put(double v) => s.setFloat(i++, v);
  for (final id in [
    'exposure', 'brightness', 'contrast', 'saturation', //
    'highlights', 'shadows', 'whites', 'blacks', //
    'vibrance', 'warmth', 'tint', 'fade', //
    'clarity', 'sharpen', 'vignette', 'grain', //
  ]) {
    put(edit.value(id));
  }
  put(pxScale);
  put(31.0); // grain seed
  put(0);
  put(0);
  return s;
}

/// The background-removal shader's uniforms (layout must match
/// `shaders/key.frag`). [samplePx] is the 3x3 sampling step in texture
/// pixels (≈ the export's 2x chroma subsampling).
ui.FragmentShader configureKeyShader(ui.FragmentProgram program, ChromaKeySpec spec, {double samplePx = 2}) {
  final s = program.fragmentShader();
  var i = 2;
  void put(double v) => s.setFloat(i++, v);
  put(((spec.color >> 16) & 0xFF) / 255);
  put(((spec.color >> 8) & 0xFF) / 255);
  put((spec.color & 0xFF) / 255);
  put(spec.similarity);
  put(spec.blend);
  final type = spec.despill ? despillTypeFor(spec.color) : null;
  put(type == 'green' ? 1 : type == 'blue' ? 2 : 0);
  put(samplePx);
  put(0);
  return s;
}
