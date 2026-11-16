/// Looks ("filters" in the UI): named styles layered on top of the
/// brightness/contrast/saturation sliders.
///
/// A look is plain data — a [LookSpec] — so the preview and the export
/// can't disagree about *what* a look is, only about how faithfully they
/// draw it:
///
///  * **Preview** (`widgets/look_filtered.dart`): one GPU fragment shader
///    (`shaders/look.frag`) applies every part below in order. On a device
///    without Impeller only the colour matrix and vignette are shown.
///  * **Export** (`lookFilters` in `export/export_command_builder.dart`):
///    FFmpeg filters that exist in the phone's (non-GPL) FFmpegKit build.
///
/// Order, identical on both sides: colour matrix → split tone → negate →
/// pixelate → posterize → ink edges → sharpen → chroma split → grain →
/// vignette.
///
/// Pure Dart (no `dart:ui`) so it is unit-tested directly.
library look_x;

import 'color_filter_x.dart' show buildColorMatrix, composeMatrices, monoMatrix;

enum LookCategory { pro, classic, mood, film, art, fun }

String lookCategoryLabel(LookCategory c) => const {
      LookCategory.pro: 'Pro',
      LookCategory.classic: 'Classic',
      LookCategory.mood: 'Mood',
      LookCategory.film: 'Film',
      LookCategory.art: 'Art',
      LookCategory.fun: 'Fun',
    }[c]!;

class LookSpec {
  final String id;
  final String label;
  final LookCategory category;

  /// 4x5 colour matrix in `ColorFilter.matrix` layout (offsets in 0..255),
  /// or null for none.
  final List<double>? matrix;

  /// Block size in pixels at a 1080-px-wide frame (0 = off).
  final double pixelate;

  /// Number of colour levels per channel (0 = off, else ≥ 2).
  final int posterize;

  /// Ink-outline strength 0..1.
  final double edges;

  /// Unsharp amount 0..1.
  final double sharpen;

  /// Red/blue channel split in pixels at 1080 px wide (0 = off).
  final double chroma;

  /// Film grain 0..1.
  final double grain;

  /// Vignette darkness 0..1.
  final double vignette;

  /// Split toning: RGB push (-1..1 each) applied to the shadows and to the
  /// highlights, using FFmpeg `colorbalance`'s weighting (the preview shader
  /// copies its formula). Null = none.
  final List<double>? shadows;
  final List<double>? highlights;

  /// Invert the colours right after the matrix. Separate from the matrix
  /// because FFmpeg's `colorchannelmixer` clips negative results before the
  /// offset is added, so an inverting matrix can't be exported faithfully.
  final bool negate;

  const LookSpec(
    this.id,
    this.label,
    this.category, {
    this.matrix,
    this.pixelate = 0,
    this.posterize = 0,
    this.edges = 0,
    this.sharpen = 0,
    this.chroma = 0,
    this.grain = 0,
    this.vignette = 0,
    this.negate = false,
    this.shadows,
    this.highlights,
  });

  bool get isNone => id == 'none';

  /// True when anything besides the matrix and vignette is used — i.e. the
  /// preview needs the shader to show it.
  bool get needsShader => shadows != null || highlights != null || negate || pixelate > 0 || posterize > 0 || edges > 0 || sharpen > 0 || chroma > 0 || grain > 0;
}

/// Kept as a type name for callers that only need id + label.
typedef LookPreset = LookSpec;

// --- matrix helpers -------------------------------------------------------

const List<double> _identity = [
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// Per-channel gain plus offset (offset in 0..255).
List<double> _gain(double r, double g, double b, {double or = 0, double og = 0, double ob = 0}) => [
      r, 0, 0, 0, or, //
      0, g, 0, 0, og, //
      0, 0, b, 0, ob, //
      0, 0, 0, 1, 0, //
    ];

/// Apply [steps] left to right (first step touches the pixel first).
List<double> _chain(List<List<double>> steps) {
  var m = _identity;
  for (final s in steps) {
    m = composeMatrices(s, m);
  }
  return m;
}

List<double> _bcs(double b, double c, double s) => buildColorMatrix(brightness: b, contrast: c, saturation: s);

/// Maps luminance onto a gradient from [dark] to [light] (RGB 0..255).
List<double> _duotone(List<double> dark, List<double> light) {
  const lr = 0.213, lg = 0.715, lb = 0.072;
  List<double> row(int ch) {
    final k = (light[ch] - dark[ch]) / 255;
    return [k * lr, k * lg, k * lb, 0, dark[ch]];
  }

  return [...row(0), ...row(1), ...row(2), 0, 0, 0, 1, 0];
}

const List<double> _sepiaMatrix = [
  0.393, 0.769, 0.189, 0, 0, //
  0.349, 0.686, 0.168, 0, 0, //
  0.272, 0.534, 0.131, 0, 0, //
  0, 0, 0, 1, 0, //
];

const List<double> _vintageMatrix = [
  0.75, 0.20, 0.05, 0, 0, //
  0.10, 0.70, 0.20, 0, 0, //
  0.15, 0.20, 0.55, 0, 0, //
  0, 0, 0, 1, 0, //
];

const List<double> _coolMatrix = [
  0.85, 0.05, 0.0, 0, 0, //
  0.0, 0.95, 0.05, 0, 0, //
  0.0, 0.10, 1.05, 0, 0, //
  0, 0, 0, 1, 0, //
];

const List<double> _warmMatrix = [
  1.05, 0.08, 0.0, 0, 0, //
  0.0, 1.0, 0.0, 0, 0, //
  0.0, 0.0, 0.88, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// Teal shadows / orange skin: pushes red and blue apart.
const List<double> _tealOrange = [
  1.10, 0.02, -0.06, 0, 0, //
  0.02, 0.98, 0.02, 0, 0, //
  -0.08, 0.06, 1.08, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// Colour inversion as a matrix — only used for the no-shader preview
/// fallback (see [LookSpec.negate]).
const List<double> invertMatrix = [
  -1, 0, 0, 0, 255, //
  0, -1, 0, 0, 255, //
  0, 0, -1, 0, 255, //
  0, 0, 0, 1, 0, //
];

// --- the catalogue --------------------------------------------------------

/// Every look, 'none' first. Ids are stored in `Clips.look`, so never
/// rename one — add a new id instead.
final List<LookSpec> lookPresets = [
  const LookSpec('none', 'None', LookCategory.classic),
  // Pro: restrained grades of the kind used in commercial and broadcast
  // work — split toning and gentle curves rather than heavy effects.
  LookSpec('pro_clean', 'Clean', LookCategory.pro, matrix: _bcs(0.02, 0.06, 0.08), sharpen: 0.25),
  LookSpec('pro_blockbuster', 'Blockbuster', LookCategory.pro,
      matrix: _bcs(-0.02, 0.18, 0.05),
      shadows: const [-0.12, 0.02, 0.14],
      highlights: const [0.14, 0.04, -0.12],
      vignette: 0.25),
  LookSpec('pro_portrait', 'Portrait', LookCategory.pro,
      matrix: _bcs(0.03, -0.05, -0.05), highlights: const [0.06, 0.02, -0.04], shadows: const [0.02, 0, 0.03]),
  LookSpec('pro_landscape', 'Landscape', LookCategory.pro,
      matrix: _bcs(0, 0.12, 0.3), shadows: const [-0.03, 0.0, 0.08], sharpen: 0.35),
  LookSpec('pro_bleach', 'Bleach bypass', LookCategory.pro,
      matrix: _bcs(-0.02, 0.4, -0.5), vignette: 0.2),
  LookSpec('pro_cross', 'Cross process', LookCategory.pro,
      matrix: _bcs(0.02, 0.2, 0.15), shadows: const [-0.05, 0.0, 0.18], highlights: const [0.08, 0.12, -0.12]),
  LookSpec('pro_matte', 'Matte', LookCategory.pro,
      matrix: _chain([_bcs(0, -0.12, -0.12), _gain(0.92, 0.92, 0.92, or: 18, og: 18, ob: 20)]),
      shadows: const [0, 0.02, 0.05]),
  LookSpec('pro_airy', 'Airy', LookCategory.pro,
      matrix: _bcs(0.08, -0.12, -0.05), highlights: const [0.04, 0.02, 0.0]),
  LookSpec('pro_food', 'Food', LookCategory.pro,
      matrix: _bcs(0.03, 0.1, 0.25), highlights: const [0.06, 0.03, -0.06], sharpen: 0.3),
  LookSpec('pro_night', 'Night city', LookCategory.pro,
      matrix: _bcs(-0.04, 0.2, 0.1), shadows: const [-0.06, 0.0, 0.16], highlights: const [0.1, 0.04, -0.04]),
  LookSpec('pro_mono', 'Fine-art B&W', LookCategory.pro,
      matrix: _chain([monoMatrix(), _bcs(0, 0.22, 0)]), shadows: const [0, 0.01, 0.03], sharpen: 0.3),
  // Classic (the original F7 set — values unchanged).
  LookSpec('mono', 'B&W', LookCategory.classic, matrix: monoMatrix()),
  const LookSpec('sepia', 'Sepia', LookCategory.classic, matrix: _sepiaMatrix),
  const LookSpec('vintage', 'Vintage', LookCategory.classic, matrix: _vintageMatrix),
  const LookSpec('cool', 'Cool', LookCategory.classic, matrix: _coolMatrix),
  const LookSpec('warm', 'Warm', LookCategory.classic, matrix: _warmMatrix),
  const LookSpec('vignette', 'Vignette', LookCategory.classic, vignette: 0.45),
  LookSpec('crisp', 'Crisp', LookCategory.classic, matrix: _bcs(0.02, 0.12, 0.08), sharpen: 0.55),
  LookSpec('pop', 'Pop', LookCategory.classic, matrix: _bcs(0.03, 0.18, 0.55), sharpen: 0.3),

  // Mood
  LookSpec('gothic', 'Gothic', LookCategory.mood,
      matrix: _chain([_bcs(-0.12, 0.35, -0.75), _gain(0.92, 0.84, 1.10, or: 4, ob: 14)]),
      vignette: 0.75,
      grain: 0.18),
  LookSpec('noir', 'Noir', LookCategory.mood,
      matrix: _chain([monoMatrix(), _bcs(-0.05, 0.45, 0)]), vignette: 0.6, grain: 0.25),
  LookSpec('moody', 'Moody', LookCategory.mood,
      matrix: _chain([_bcs(-0.08, 0.15, -0.3), _gain(0.95, 1.0, 1.06, ob: 6)]), vignette: 0.35),
  LookSpec('cinematic', 'Cinematic', LookCategory.mood,
      matrix: _chain([_bcs(-0.02, 0.15, 0.15), _tealOrange]), vignette: 0.3),
  LookSpec('dreamy', 'Dreamy', LookCategory.mood,
      matrix: _chain([_bcs(0.06, -0.2, -0.1), _gain(1.04, 0.97, 1.04, or: 12, og: 6, ob: 14)])),
  LookSpec('golden', 'Golden hour', LookCategory.mood,
      matrix: _chain([_bcs(0.02, 0.05, 0.12), _gain(1.12, 1.02, 0.80, or: 8, og: 4)]), vignette: 0.2),

  // Film
  LookSpec('film', 'Film', LookCategory.film,
      matrix: _chain([_bcs(0, -0.12, -0.1), _gain(0.94, 0.92, 0.86, or: 18, og: 16, ob: 14)]),
      grain: 0.3,
      vignette: 0.2),
  LookSpec('faded', 'Faded', LookCategory.film,
      matrix: _chain([_bcs(0, -0.3, -0.25), _gain(0.88, 0.88, 0.88, or: 26, og: 26, ob: 28)])),
  LookSpec('vhs', 'VHS', LookCategory.film,
      matrix: _chain([_bcs(0.02, -0.1, -0.15), _gain(1.02, 0.98, 0.94, or: 8, ob: 4)]),
      chroma: 3,
      grain: 0.35),
  LookSpec('polaroid', 'Instant', LookCategory.film,
      matrix: _chain([_bcs(0.04, -0.08, -0.05), _gain(1.0, 0.98, 0.9, or: 14, og: 12, ob: 20)]),
      vignette: 0.3),

  // Art
  LookSpec('anime', 'Anime', LookCategory.art,
      matrix: _bcs(0.04, 0.15, 0.45), posterize: 8, edges: 0.6, sharpen: 0.3),
  LookSpec('cartoon', 'Cartoon', LookCategory.art,
      matrix: _bcs(0.02, 0.25, 0.6), posterize: 5, edges: 0.9),
  LookSpec('comic', 'Comic', LookCategory.art,
      matrix: _bcs(0.0, 0.35, 0.3), posterize: 4, edges: 1.0, grain: 0.1),
  LookSpec('sketch', 'Sketch', LookCategory.art,
      matrix: _chain([monoMatrix(), _bcs(0.3, -0.35, 0)]), edges: 1.0),
  LookSpec('duotone', 'Duotone', LookCategory.art, matrix: _duotone([40, 12, 90], [255, 170, 90])),
  LookSpec('oil', 'Painting', LookCategory.art, matrix: _bcs(0.02, 0.1, 0.35), posterize: 12, sharpen: 0.4),

  // Fun
  LookSpec('cyberpunk', 'Cyberpunk', LookCategory.fun,
      matrix: _chain([_bcs(0, 0.2, 0.3), _gain(1.1, 0.8, 1.2, or: 10, ob: 20)]),
      chroma: 2,
      vignette: 0.3),
  const LookSpec('glitch', 'Glitch', LookCategory.fun, chroma: 7, grain: 0.2),
  LookSpec('pixel', 'Pixel', LookCategory.fun, matrix: _bcs(0, 0.1, 0.2), pixelate: 14),
  LookSpec('xray', 'X-ray', LookCategory.fun, matrix: _chain([monoMatrix(), _bcs(0, 0.2, 0)]), negate: true),
];

LookSpec lookById(String? id) => lookPresets.firstWhere((l) => l.id == id, orElse: () => lookPresets.first);

/// [spec] blended with "no look" by [strength] (0..1). 1 returns [spec]
/// unchanged; 0 returns the equivalent of 'none'. Posterize levels can't be
/// fractional, so posterize is blended by mixing (see `posterizeMix`).
class ScaledLook {
  final LookSpec spec;
  final double strength;
  const ScaledLook(this.spec, this.strength);

  double get _k => strength.clamp(0.0, 1.0).toDouble();

  List<double>? get matrix {
    final m = spec.matrix;
    if (m == null || _k == 0) return null;
    if (_k == 1) return m; // exact, no rounding from the blend below
    return [for (var i = 0; i < 20; i++) _identity[i] + (m[i] - _identity[i]) * _k];
  }

  double get pixelate => spec.pixelate * _k;
  int get posterize => _k == 0 ? 0 : spec.posterize;
  double get posterizeMix => spec.posterize > 0 ? _k : 0;
  double get edges => spec.edges * _k;
  double get sharpen => spec.sharpen * _k;
  double get chroma => spec.chroma * _k;
  double get grain => spec.grain * _k;
  double get vignette => spec.vignette * _k;

  List<double>? get shadows => _scale3(spec.shadows);
  List<double>? get highlights => _scale3(spec.highlights);
  List<double>? _scale3(List<double>? v) => v == null || _k == 0 ? null : [for (final x in v) x * _k];

  /// Mix of the inverted image (0..1).
  double get negate => spec.negate ? _k : 0;

  bool get isNone => spec.isNone || _k == 0;
}

ScaledLook scaledLook(String? id, [double strength = 1.0]) => ScaledLook(lookById(id), strength);

/// The colour-matrix part of [look] at [strength], or null when it has none.
List<double>? lookColorMatrix(String? look, [double strength = 1.0]) => scaledLook(look, strength).matrix;

/// Vignette darkness of [look] (0 = none).
double vignetteOpacity(String? look, [double strength = 1.0]) => scaledLook(look, strength).vignette;
