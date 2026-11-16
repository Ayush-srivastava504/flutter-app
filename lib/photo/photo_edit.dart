/// Everything a photo edit is, as plain data (no Flutter): Tune values,
/// look, geometry. Stored as JSON in `PhotoProjects.editJson` so adding a
/// tool never needs a schema change. Rendered by `photo_renderer.dart`
/// (preview and full-resolution export use the same code and shaders).
library photo_edit;

import 'dart:convert';
import 'dart:math' as math;

/// One Tune slider.
class AdjustParam {
  final String id;
  final String label;
  final double min;
  final double max;

  const AdjustParam(this.id, this.label, {this.min = -1, this.max = 1});
}

/// Tune sliders, in the order shown. Ids are stored in user data: never
/// rename one. Their maths lives in `shaders/adjust.frag`.
const List<AdjustParam> adjustParams = [
  AdjustParam('exposure', 'Exposure'),
  AdjustParam('brightness', 'Brightness'),
  AdjustParam('contrast', 'Contrast'),
  AdjustParam('highlights', 'Highlights'),
  AdjustParam('shadows', 'Shadows'),
  AdjustParam('whites', 'Whites'),
  AdjustParam('blacks', 'Blacks'),
  AdjustParam('saturation', 'Saturation'),
  AdjustParam('vibrance', 'Vibrance'),
  AdjustParam('warmth', 'Warmth'),
  AdjustParam('tint', 'Tint'),
  AdjustParam('fade', 'Fade', min: 0),
  AdjustParam('clarity', 'Clarity'),
  AdjustParam('sharpen', 'Sharpen', min: 0),
  AdjustParam('vignette', 'Vignette', min: 0),
  AdjustParam('grain', 'Grain', min: 0),
];

AdjustParam adjustParamById(String id) => adjustParams.firstWhere((p) => p.id == id);

/// Crop aspect presets: (label, width/height) — null ratio = keep the
/// photo's own shape.
const List<(String, double?)> cropRatios = [
  ('Original', null),
  ('1:1', 1),
  ('4:5', 4 / 5),
  ('3:2', 3 / 2),
  ('16:9', 16 / 9),
  ('9:16', 9 / 16),
];

class PhotoEdit {
  static const int currentVersion = 1;

  /// Tune values by [AdjustParam.id]; missing = 0.
  final Map<String, double> adjust;
  final String? look;
  final double lookStrength;

  /// Quarter turns clockwise (0..3).
  final int turns;
  final bool flipH;
  final bool flipV;

  /// Straighten angle in degrees (-45..45).
  final double straighten;

  /// Crop shape (width / height); null = the photo's own shape.
  final double? cropRatio;

  const PhotoEdit({
    this.adjust = const {},
    this.look,
    this.lookStrength = 1.0,
    this.turns = 0,
    this.flipH = false,
    this.flipV = false,
    this.straighten = 0,
    this.cropRatio,
  });

  double value(String id) => adjust[id] ?? 0;

  bool get hasAdjust => adjust.values.any((v) => v != 0);
  bool get hasLook => look != null && look != 'none';
  bool get hasGeometry => turns % 4 != 0 || flipH || flipV || straighten != 0 || cropRatio != null;
  bool get isOriginal => !hasAdjust && !hasLook && !hasGeometry;

  PhotoEdit withAdjust(String id, double v) {
    final next = Map<String, double>.of(adjust);
    if (v == 0) {
      next.remove(id);
    } else {
      next[id] = v;
    }
    return copyWith(adjust: next);
  }

  PhotoEdit copyWith({
    Map<String, double>? adjust,
    Object? look = _keep,
    double? lookStrength,
    int? turns,
    bool? flipH,
    bool? flipV,
    double? straighten,
    Object? cropRatio = _keep,
  }) =>
      PhotoEdit(
        adjust: adjust ?? this.adjust,
        look: identical(look, _keep) ? this.look : look as String?,
        lookStrength: lookStrength ?? this.lookStrength,
        turns: turns ?? this.turns,
        flipH: flipH ?? this.flipH,
        flipV: flipV ?? this.flipV,
        straighten: straighten ?? this.straighten,
        cropRatio: identical(cropRatio, _keep) ? this.cropRatio : cropRatio as double?,
      );

  Map<String, Object?> toJson() => {
        'version': currentVersion,
        'adjust': adjust,
        'look': look,
        'lookStrength': lookStrength,
        'turns': turns,
        'flipH': flipH,
        'flipV': flipV,
        'straighten': straighten,
        'cropRatio': cropRatio,
      };

  String encode() => jsonEncode(toJson());

  /// Never throws: unreadable or unknown data falls back to "no edit", so a
  /// corrupt row can't stop the photo from opening.
  static PhotoEdit decode(String? source) {
    if (source == null || source.isEmpty) return const PhotoEdit();
    try {
      final j = jsonDecode(source) as Map<String, dynamic>;
      double d(Object? v, double fallback) => v is num ? v.toDouble() : fallback;
      final rawAdjust = j['adjust'];
      final adjust = <String, double>{};
      if (rawAdjust is Map) {
        for (final e in rawAdjust.entries) {
          final known = adjustParams.where((p) => p.id == e.key).firstOrNull;
          if (known != null && e.value is num) {
            adjust[known.id] = (e.value as num).toDouble().clamp(known.min, known.max);
          }
        }
      }
      return PhotoEdit(
        adjust: adjust,
        look: j['look'] as String?,
        lookStrength: d(j['lookStrength'], 1).clamp(0.0, 1.0),
        turns: ((j['turns'] as num?)?.toInt() ?? 0) % 4,
        flipH: j['flipH'] == true,
        flipV: j['flipV'] == true,
        straighten: d(j['straighten'], 0).clamp(-45.0, 45.0),
        cropRatio: (j['cropRatio'] as num?)?.toDouble(),
      );
    } catch (_) {
      return const PhotoEdit();
    }
  }

  @override
  bool operator ==(Object other) => other is PhotoEdit && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
}

const Object _keep = Object();

/// Output size of [edit] applied to a [srcW] x [srcH] image: quarter turns
/// swap the sides, then the largest centred rectangle of the crop ratio that
/// fits inside the image rotated by the straighten angle (so no empty
/// corners ever show).
({double width, double height}) croppedSize(PhotoEdit edit, double srcW, double srcH) {
  final swap = edit.turns % 2 == 1;
  final w = swap ? srcH : srcW;
  final h = swap ? srcW : srcH;
  final ratio = edit.cropRatio ?? w / h;
  final a = edit.straighten.abs() * math.pi / 180;
  final c = math.cos(a), s = math.sin(a);
  // A centred x-by-(x/ratio) rect rotated by a must fit in w x h:
  //   x*c + (x/ratio)*s <= w   and   x*s + (x/ratio)*c <= h
  final x = math.min(w / (c + s / ratio), h / (s + c / ratio));
  return (width: x, height: x / ratio);
}
