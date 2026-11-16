import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/models/look_x.dart';
import 'package:video_editor_app/photo/auto_enhance.dart';
import 'package:video_editor_app/photo/photo_edit.dart';

/// A 64x64 test image whose pixel at (x, y) is [color](x, y) (RGB 0..255).
PhotoStats image(List<int> Function(int x, int y) color) {
  const w = 64, h = 64;
  final bytes = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final c = color(x, y);
      final i = (y * w + x) * 4;
      bytes[i] = c[0];
      bytes[i + 1] = c[1];
      bytes[i + 2] = c[2];
      bytes[i + 3] = 255;
    }
  }
  return analyzeRgba(bytes, w, h);
}

/// A grey ramp from [lo] to [hi] (0..255) across x, tinted by [tint].
PhotoStats ramp(int lo, int hi, {List<int> tint = const [0, 0, 0]}) => image((x, y) {
      final v = lo + (hi - lo) * x / 63;
      return [for (var c = 0; c < 3; c++) (v + tint[c]).round().clamp(0, 255)];
    });

void main() {
  group('autoAdjust', () {
    test('a dark photo is brightened, never darkened', () {
      final a = autoAdjust(ramp(0, 90));
      expect(a['exposure'], greaterThan(0.1));
      expect(a['whites'], greaterThan(0), reason: 'stretch to use the full range');
    });

    test('a bright photo is darkened', () {
      expect(autoAdjust(ramp(140, 255))['exposure'], lessThan(0));
    });

    test('a well-exposed, full-range, neutral photo is left almost alone', () {
      final a = autoAdjust(ramp(0, 255));
      expect(a.keys.toSet(), {'clarity', 'sharpen'}, reason: 'only the gentle detail boost');
    });

    test('a photo with a large blown-out area gets highlights pulled back', () {
      // Right fifth of the frame is pure white.
      final a = autoAdjust(image((x, y) => x > 51 ? [255, 255, 255] : [x * 4, x * 4, x * 4]));
      expect(a['highlights'], lessThan(0));
    });

    test('a flat, hazy photo gets contrast and lifted blacks are pulled down', () {
      final a = autoAdjust(ramp(70, 170));
      expect(a['contrast'], greaterThan(0.1));
      expect(a['blacks'], lessThan(0));
    });

    test('a blue cast is corrected warmer; an orange cast cooler', () {
      expect(autoAdjust(ramp(20, 230, tint: [-20, 0, 25]))['warmth'], greaterThan(0.1));
      expect(autoAdjust(ramp(20, 230, tint: [25, 0, -20]))['warmth'], lessThan(-0.1));
    });

    test('every value stays inside its slider range', () {
      final rng = math.Random(7);
      for (var t = 0; t < 30; t++) {
        final lo = rng.nextInt(200), hi = lo + rng.nextInt(256 - lo);
        final a = autoAdjust(ramp(lo, hi, tint: [rng.nextInt(60) - 30, rng.nextInt(60) - 30, rng.nextInt(60) - 30]));
        for (final e in a.entries) {
          final p = adjustParamById(e.key);
          expect(e.value, inInclusiveRange(p.min, p.max), reason: '${e.key} for $lo..$hi');
        }
      }
    });
  });

  group('suggestLooks', () {
    test('only real look ids, no duplicates', () {
      final s = suggestLooks(ramp(0, 255));
      expect(s.toSet(), hasLength(s.length));
      for (final id in s) {
        expect(lookById(id).id, id);
      }
    });

    test('a dark photo gets night grades first', () {
      expect(suggestLooks(ramp(0, 60)).first, 'pro_night');
    });

    test('a green-and-blue landscape gets the landscape grade first', () {
      final s = image((x, y) => y < 32 ? [90, 150, 230] : [60, 140, 50]);
      expect(suggestLooks(s).first, 'pro_landscape');
    });

    test('skin tones get the portrait grade first', () {
      final s = image((x, y) => [220, 170, 140]);
      expect(s.skin, greaterThan(0.5));
      expect(suggestLooks(s).first, 'pro_portrait');
    });

    test('a colourless photo gets black-and-white', () {
      expect(suggestLooks(ramp(20, 230)), contains('pro_mono'));
    });
  });
}
