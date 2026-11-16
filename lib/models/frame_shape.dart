import 'dart:math' as math;

/// Frame shapes the editor offers (F6), as (label, width / height).
const List<(String, double)> frameShapes = [
  ('9:16', 9 / 16),
  ('16:9', 16 / 9),
  ('1:1', 1),
  ('4:5', 4 / 5),
  ('4:3', 4 / 3),
];

/// The offered frame shape closest to a [width] x [height] video that is
/// rotated by [rotationDegrees] (90/270 swap the sides). Null when the size
/// is unknown, so the caller keeps whatever shape it has.
double? nearestFrameShape(int width, int height, {int rotationDegrees = 0}) {
  if (width <= 0 || height <= 0) return null;
  final rotated = rotationDegrees % 180 != 0;
  final ratio = rotated ? height / width : width / height;
  var best = frameShapes.first.$2;
  for (final (_, r) in frameShapes) {
    // Compare on a log scale so 16:9 vs 9:16 are equally far from 1:1.
    if ((math.log(r) - math.log(ratio)).abs() < (math.log(best) - math.log(ratio)).abs()) best = r;
  }
  return best;
}
