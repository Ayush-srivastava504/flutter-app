/// Color-adjustment math for Phase 7 (Transitions & Filters).
///
/// Kept dependency-free (no `dart:ui` import) so it's plain, fast-to-test
/// logic — `test/color_filter_matrix_test.dart` exercises it directly.
/// `FilterPanel`/`VideoPreviewPlayer` turn the `List<double>` this
/// produces into a real `ColorFilter.matrix` at the widget layer.
library color_filter_x;

/// One named look: a fixed brightness/contrast/saturation triple a user
/// can tap instead of dragging three sliders. Values are in the same
/// [-1.0, 1.0] range as `Clips.brightness/contrast/saturation` — 0 means
/// "no change" on that axis, so `FilterPreset.original` is the identity
/// preset every new clip starts on.
class FilterPreset {
  final String id;
  final String label;
  final double brightness;
  final double contrast;
  final double saturation;

  const FilterPreset(
    this.id,
    this.label, {
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
  });
}

/// The bundled catalog (spec asks for 3–5). Ordered so "Original" — the
/// no-op — is always first, matching the position a user expects the
/// reset option to live in.
const List<FilterPreset> filterPresets = [
  FilterPreset('none', 'Original'),
  FilterPreset('vivid', 'Vivid', contrast: 0.15, saturation: 0.4),
  FilterPreset('warm', 'Warm', brightness: 0.05, contrast: 0.05, saturation: 0.15),
  FilterPreset('cool', 'Cool', contrast: 0.05, saturation: -0.1),
  FilterPreset('mono', 'B&W', contrast: 0.1, saturation: -1.0),
  FilterPreset('vintage', 'Vintage', brightness: -0.05, contrast: -0.15, saturation: -0.3),
];

FilterPreset presetById(String? id) =>
    filterPresets.firstWhere((p) => p.id == id, orElse: () => filterPresets.first);

/// Builds a 4x5 affine RGBA color matrix (the flat format
/// `ColorFilter.matrix` expects) from independent brightness/contrast/
/// saturation adjustments, each in [-1.0, 1.0] with 0 == unchanged —
/// the same semantics as the `Clips` columns this is fed from.
///
/// Composed by matrix-multiplying three classic per-effect matrices in
/// saturation → contrast → brightness order (each applied to the
/// previous stage's output), rather than trying to hand-derive one
/// combined formula — that keeps each effect's math independently
/// obvious and independently testable via the private matrices below.
List<double> buildColorMatrix({
  double brightness = 0,
  double contrast = 0,
  double saturation = 0,
}) {
  var m = _identityMatrix;
  m = _multiply(_saturationMatrix(saturation), m);
  m = _multiply(_contrastMatrix(contrast), m);
  m = _multiply(_brightnessMatrix(brightness), m);
  return m;
}

/// True when every channel is at its neutral value — lets callers skip
/// wrapping the preview in a `ColorFiltered` entirely for the (common)
/// unedited case rather than paying for a no-op filter every frame.
bool isNeutralFilter({
  double brightness = 0,
  double contrast = 0,
  double saturation = 0,
}) =>
    brightness == 0 && contrast == 0 && saturation == 0;

const List<double> _identityMatrix = [
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// Shifts every RGB channel by a flat amount. `brightness` of +1.0 adds
/// 255 (full white shift); -1.0 subtracts 255. `ColorFilter.matrix`
/// clamps the final per-pixel result to 0..255 itself, so no clamping
/// is needed here.
List<double> _brightnessMatrix(double brightness) {
  final b = _clamp(brightness) * 255;
  return [
    1, 0, 0, 0, b, //
    0, 1, 0, 0, b, //
    0, 0, 1, 0, b, //
    0, 0, 0, 1, 0, //
  ];
}

/// Scales each channel away from mid-gray (128). `contrast` of 0 keeps
/// the identity scale (c == 1); +1.0 doubles the spread (c == 2); -1.0
/// collapses everything to mid-gray (c == 0).
List<double> _contrastMatrix(double contrast) {
  final c = 1 + _clamp(contrast);
  final t = (1 - c) * 128;
  return [
    c, 0, 0, 0, t, //
    0, c, 0, 0, t, //
    0, 0, c, 0, t, //
    0, 0, 0, 1, 0, //
  ];
}

/// Blends each channel toward (saturation -1.0) or away from
/// (saturation +1.0) the standard-luminance grayscale value, using the
/// Rec. 601 luma weights also used by most basic video-editing "desat"
/// sliders.
List<double> _saturationMatrix(double saturation) {
  final s = 1 + _clamp(saturation);
  const lumR = 0.213, lumG = 0.715, lumB = 0.072;
  return [
    lumR + (1 - lumR) * s, lumG - lumG * s, lumB - lumB * s, 0, 0, //
    lumR - lumR * s, lumG + (1 - lumG) * s, lumB - lumB * s, 0, 0, //
    lumR - lumR * s, lumG - lumG * s, lumB + (1 - lumB) * s, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}

double _clamp(double v) => v < -1.0 ? -1.0 : (v > 1.0 ? 1.0 : v);

/// Composes two flat 4x5 affine color matrices as `a ∘ b` — i.e. [b] is
/// applied to the pixel first, then [a] to its result — by treating
/// each as a 5x5 homogeneous matrix with an implicit `[0,0,0,0,1]`
/// bottom row so the translation (offset) column composes correctly
/// under multiplication, then dropping that row from the result.
List<double> _multiply(List<double> a, List<double> b) {
  List<List<double>> to5x5(List<double> flat) => List.generate(5, (r) {
        if (r == 4) return const [0.0, 0.0, 0.0, 0.0, 1.0];
        return List.generate(5, (c) => flat[r * 5 + c]);
      });

  final ma = to5x5(a);
  final mb = to5x5(b);
  final result = List.generate(
    5,
    (r) => List.generate(5, (c) {
      var sum = 0.0;
      for (var k = 0; k < 5; k++) {
        sum += ma[r][k] * mb[k][c];
      }
      return sum;
    }),
  );

  return [
    for (var r = 0; r < 4; r++) for (var c = 0; c < 5; c++) result[r][c],
  ];
}
