/// Background removal (`Clips.keyJson`, schema v12): a colour key, as in
/// green-screen work. Pixels close to [color] (in chroma, so shadows on the
/// screen still key out) become transparent and the clip is laid over a new
/// background — a solid colour or a photo.
///
/// One spec, two renderers (same maths):
///  * **Export**: `chromakey` (FFmpeg's own formula) → optional `despill` →
///    `overlay` onto the background. Built by [chromaKeyFilters].
///  * **Preview**: `shaders/key.frag` copies `vf_chromakey.c`'s distance
///    (BT.601 chroma, 3×3 average) and `vf_despill.c`'s default spill maths.
///
/// Works on clips shot against an even, single-colour backdrop. Removing an
/// ordinary background (AI person cut-out) needs an on-device segmentation
/// model and is not part of this.
library chroma_key;

import 'dart:convert';
import 'dart:math' as math;

class ChromaKeySpec {
  /// Key colour, 0xRRGGBB.
  final int color;

  /// How far from [color] still counts as background (FFmpeg `similarity`).
  final double similarity;

  /// Soft edge width (FFmpeg `blend`); 0 = hard edge.
  final double blend;

  /// Remove the coloured fringe the screen reflects onto the subject.
  final bool despill;

  /// 'color' or 'image'.
  final String bg;
  final int bgColor;
  final String? bgImage;

  const ChromaKeySpec({
    this.color = greenScreen,
    this.similarity = defaultSimilarity,
    this.blend = defaultBlend,
    this.despill = true,
    this.bg = 'color',
    this.bgColor = 0x15161A,
    this.bgImage,
  });

  static const int greenScreen = 0x00B140;

  /// Defaults chosen from the maths, not taste: in this chroma distance any
  /// grey/black/white sits ~0.20 from a green or blue screen, while a
  /// shadowed patch of the same screen is ~0.06 away. 0.08 + 0.06 removes
  /// the screen and keeps every neutral fully opaque (see the tests).
  static const double defaultSimilarity = 0.08;
  static const double defaultBlend = 0.06;
  static const int blueScreen = 0x0047BB;

  bool get usesImage => bg == 'image' && bgImage != null && bgImage!.isNotEmpty;

  ChromaKeySpec copyWith({
    int? color,
    double? similarity,
    double? blend,
    bool? despill,
    String? bg,
    int? bgColor,
    String? bgImage,
  }) =>
      ChromaKeySpec(
        color: color ?? this.color,
        similarity: similarity ?? this.similarity,
        blend: blend ?? this.blend,
        despill: despill ?? this.despill,
        bg: bg ?? this.bg,
        bgColor: bgColor ?? this.bgColor,
        bgImage: bgImage ?? this.bgImage,
      );

  String toJson() => jsonEncode({
        'v': 1,
        'c': color,
        's': similarity,
        'b': blend,
        'd': despill,
        'bg': bg,
        'bgc': bgColor,
        if (bgImage != null) 'bgi': bgImage,
      });

  /// Null for null/empty/broken JSON — a bad row behaves as "no key".
  static ChromaKeySpec? tryParse(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      return ChromaKeySpec(
        color: (m['c'] as num).toInt() & 0xFFFFFF,
        similarity: ((m['s'] as num?) ?? defaultSimilarity).toDouble().clamp(0.01, 1.0),
        blend: ((m['b'] as num?) ?? defaultBlend).toDouble().clamp(0.0, 1.0),
        despill: m['d'] as bool? ?? true,
        bg: m['bg'] as String? ?? 'color',
        bgColor: ((m['bgc'] as num?) ?? 0x15161A).toInt() & 0xFFFFFF,
        bgImage: m['bgi'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) => other is ChromaKeySpec && other.toJson() == toJson();

  @override
  int get hashCode => toJson().hashCode;
}

/// Which `despill` flavour suits [rgb]: 'green', 'blue', or null when the key
/// colour is neither (despill only knows those two).
String? despillTypeFor(int rgb) {
  final r = (rgb >> 16) & 0xFF, g = (rgb >> 8) & 0xFF, b = rgb & 0xFF;
  if (g > r && g >= b) return 'green';
  if (b > r && b > g) return 'blue';
  return null;
}

/// BT.601 limited-range chroma (U, V) of a 0..1 RGB colour, offset-free — the
/// numbers `vf_chromakey.c` compares (its RGB_TO_U/V_CCIR, divided by 255).
(double, double) chromaUV(double r, double g, double b) =>
    (-0.148223 * r - 0.290993 * g + 0.439216 * b, 0.439216 * r - 0.367788 * g - 0.071427 * b);

/// Opacity FFmpeg's chromakey gives a flat area of colour [rgb] keyed by
/// [spec] (0 = removed, 1 = kept). Used by tests to keep preview and export
/// maths honest.
double keyAlpha(int rgb, ChromaKeySpec spec) {
  double c(int v, int s) => ((v >> s) & 0xFF) / 255;
  final (u, v) = chromaUV(c(rgb, 16), c(rgb, 8), c(rgb, 0));
  final (ku, kv) = chromaUV(c(spec.color, 16), c(spec.color, 8), c(spec.color, 0));
  final diff = math.sqrt(((u - ku) * (u - ku) + (v - kv) * (v - kv)) / 2);
  if (spec.blend > 0.0001) return ((diff - spec.similarity) / spec.blend).clamp(0.0, 1.0);
  return diff > spec.similarity ? 1 : 0;
}

String _hex(int rgb) => '0x${(rgb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// The keying steps (frame in → frame with alpha out). Options are named
/// (FACTS B-06); `despill` is given every scale explicitly because its
/// defaults assume green.
List<String> chromaKeyFilters(ChromaKeySpec spec) {
  String n(double v) => v.toStringAsFixed(3);
  final out = <String>[
    'format=yuva420p',
    'chromakey=color=${_hex(spec.color)}:similarity=${n(spec.similarity)}:blend=${n(spec.blend)}',
  ];
  final type = spec.despill ? despillTypeFor(spec.color) : null;
  if (type != null) {
    out
      ..add('format=rgba')
      ..add(type == 'green'
          ? 'despill=type=green:mix=0.5:expand=0:red=0:green=-1:blue=0'
          : 'despill=type=blue:mix=0.5:expand=0:red=0:green=0:blue=-1');
  }
  return out;
}

String ffmpegHexColor(int rgb) => _hex(rgb);
