/// One-tap Auto enhance and "looks for this photo" — measured from the
/// photo's own pixels, no ML model (MASTER_PLAN P3.1).
///
/// Pure Dart: [analyzeRgba] takes raw RGBA bytes (the photo decoded small,
/// ~256 px), so everything here is unit-tested with synthetic images.
library auto_enhance;

import 'dart:math' as math;
import 'dart:typed_data';

class PhotoStats {
  /// Luminance percentiles (0..1).
  final double p01, p10, p50, p90, p97, p99;

  /// Mean R, G, B of mid-tone pixels (0..1) — for white balance.
  final double meanR, meanG, meanB;

  /// Mean colourfulness (max-min per pixel, 0..1).
  final double meanSaturation;

  /// Share of pixels (0..1) that are clearly…
  final double skin, green, blue, warm;

  const PhotoStats({
    required this.p01,
    required this.p10,
    required this.p50,
    required this.p90,
    required this.p97,
    required this.p99,
    required this.meanR,
    required this.meanG,
    required this.meanB,
    required this.meanSaturation,
    required this.skin,
    required this.green,
    required this.blue,
    required this.warm,
  });

  double get range => p90 - p10;
}

PhotoStats analyzeRgba(Uint8List rgba, int width, int height) {
  final n = width * height;
  if (n == 0 || rgba.length < n * 4) throw ArgumentError('rgba is smaller than width*height*4');
  final hist = List<int>.filled(256, 0);
  double sr = 0, sg = 0, sb = 0, sat = 0;
  var mid = 0, skin = 0, green = 0, blue = 0, warm = 0;

  for (var i = 0; i < n; i++) {
    final r = rgba[i * 4] / 255, g = rgba[i * 4 + 1] / 255, b = rgba[i * 4 + 2] / 255;
    final l = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    hist[(l * 255).round().clamp(0, 255)]++;
    final mx = math.max(r, math.max(g, b)), mn = math.min(r, math.min(g, b));
    final s = mx - mn;
    sat += s;
    if (l > 0.15 && l < 0.85) {
      sr += r;
      sg += g;
      sb += b;
      mid++;
    }
    if (s < 0.12 || mx < 0.12) continue; // grey or too dark to judge colour
    final h = _hue(r, g, b, mx, s);
    if (h >= 5 && h <= 45 && r > g && g > b && s < 0.55 && l > 0.25) skin++;
    if (h >= 70 && h <= 170) green++;
    if (h >= 180 && h <= 250) blue++;
    if ((h <= 60 || h >= 330) && s > 0.35) warm++;
  }

  double pct(double q) {
    final target = q * n;
    var acc = 0;
    for (var v = 0; v < 256; v++) {
      acc += hist[v];
      if (acc >= target) return v / 255;
    }
    return 1;
  }

  final m = math.max(mid, 1);
  return PhotoStats(
    p01: pct(0.01),
    p10: pct(0.10),
    p50: pct(0.50),
    p90: pct(0.90),
    p97: pct(0.97),
    p99: pct(0.99),
    meanR: mid == 0 ? 0.5 : sr / m,
    meanG: mid == 0 ? 0.5 : sg / m,
    meanB: mid == 0 ? 0.5 : sb / m,
    meanSaturation: sat / n,
    skin: skin / n,
    green: green / n,
    blue: blue / n,
    warm: warm / n,
  );
}

double _hue(double r, double g, double b, double mx, double d) {
  double h;
  if (mx == r) {
    h = ((g - b) / d) % 6;
  } else if (mx == g) {
    h = (b - r) / d + 2;
  } else {
    h = (r - g) / d + 4;
  }
  h *= 60;
  return h < 0 ? h + 360 : h;
}

double _r2(double v) => (v * 100).round() / 100;

/// Tune values (ids from `adjustParams`) that correct [s]. Every value is
/// conservative — Auto should never be the thing a user has to undo — and
/// values within ±0.03 are dropped as noise.
Map<String, double> autoAdjust(PhotoStats s) {
  final out = <String, double>{};
  void set(String id, double v, double lo, double hi) {
    final c = _r2(v.clamp(lo, hi).toDouble());
    if (c.abs() >= 0.03) out[id] = c;
  }

  // Black / white points: stretch to use the full range (adjust.frag:
  // black point = -blacks*0.12, white point = 1 - whites*0.12).
  if (s.p01 > 0.03) set('blacks', -(s.p01 - 0.01) / 0.12 * 0.7, -0.8, 0);
  if (s.p99 < 0.96) set('whites', (0.99 - s.p99) / 0.12 * 0.7, 0, 0.8);

  // Exposure: bring the median toward ~0.46. Stops = log2(target/median);
  // the slider maps ±1 to ±2 stops, applied at half strength.
  final median = math.max(s.p50, 0.02);
  set('exposure', math.log(0.46 / median) / math.ln2 / 2 * 0.5, -0.4, 0.5);

  // Recover crushed shadows / clipped highlights.
  if (s.p10 < 0.07) set('shadows', (0.07 - s.p10) * 4, 0, 0.4);
  // Only when a real area is blown out (≥3% of pixels), not a few specks.
  if (s.p97 >= 0.985) set('highlights', -(s.p90 - 0.7) * 1.5, -0.4, 0);

  // Flat (hazy) photos get contrast; already punchy ones are left alone.
  if (s.range < 0.55) set('contrast', (0.55 - s.range) * 0.9, 0, 0.3);

  // Grey-world white balance at half strength (adjust.frag: red *=
  // 1+0.18w, blue *= 1-0.18w; green *= 1-0.12t).
  final rb = s.meanR + s.meanB;
  if (rb > 0.05) set('warmth', (s.meanB - s.meanR) / (0.18 * rb) * 0.5, -0.35, 0.35);
  final avgRB = rb / 2;
  if (s.meanG > 0.05) set('tint', (1 - avgRB / s.meanG) / 0.12 * 0.5, -0.25, 0.25);

  // Dull colour gets vibrance (which spares already-vivid colours).
  // (Not on near-colourless photos: there is no colour to bring out.)
  if (s.meanSaturation > 0.04 && s.meanSaturation < 0.28) {
    set('vibrance', (0.28 - s.meanSaturation) * 1.6, 0, 0.35);
  }

  // A touch of detail on every photo.
  set('clarity', 0.12, 0, 1);
  set('sharpen', 0.15, 0, 1);
  return out;
}

/// Up to [max] look ids (`lookPresets`) that suit the photo, best first.
List<String> suggestLooks(PhotoStats s, {int max = 6}) {
  final scores = <String, double>{};
  void add(String id, double v) => scores[id] = (scores[id] ?? 0) + v;

  final dark = s.p50 < 0.25;
  final flat = s.range < 0.4;
  final dull = s.meanSaturation < 0.15;

  add('pro_clean', 0.3); // safe default for anything
  if (s.skin > 0.08) {
    add('pro_portrait', 1 + s.skin * 4);
    add('pro_airy', 0.6 + s.skin * 2);
    add('polaroid', 0.4);
  }
  if (s.green + s.blue > 0.25) {
    add('pro_landscape', 1 + (s.green + s.blue) * 2);
    add('pro_blockbuster', 0.6 + s.blue * 2);
    add('golden', 0.4 + s.green);
  }
  if (s.blue > 0.3) add('cool', 0.5 + s.blue);
  if (s.warm > 0.2) {
    add('pro_food', 0.8 + s.warm * 2);
    add('golden', 0.6 + s.warm);
    add('warm', 0.4);
  }
  if (dark) {
    add('pro_night', 1.5);
    add('cyberpunk', 0.8);
    add('noir', 0.7);
    add('moody', 0.6);
  } else if (s.p50 > 0.6) {
    add('pro_airy', 0.8);
    add('dreamy', 0.6);
  }
  if (flat) {
    add('pro_bleach', 0.5);
    add('pop', 0.6);
    add('crisp', 0.5);
  }
  if (dull) {
    add('pro_mono', 1.0);
    add('noir', 0.6);
    add('film', 0.5);
  } else {
    add('cinematic', 0.5);
    add('pro_matte', 0.35);
  }

  final ranked = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return [for (final e in ranked.take(max)) e.key];
}
