import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/models/color_filter_x.dart';

void main() {
  group('buildColorMatrix', () {
    test('is the identity matrix when everything is neutral', () {
      final m = buildColorMatrix();
      expect(m, const [
        1, 0, 0, 0, 0, //
        0, 1, 0, 0, 0, //
        0, 0, 1, 0, 0, //
        0, 0, 0, 1, 0, //
      ]);
    });

    test('returns a 4x5 (20-value) flat matrix regardless of inputs', () {
      final m = buildColorMatrix(brightness: 0.4, contrast: -0.2, saturation: 0.9);
      expect(m, hasLength(20));
    });

    test('full-positive brightness adds a flat +255 offset per channel', () {
      final m = buildColorMatrix(brightness: 1.0);
      // Offset column indices in the flat 4x5 layout are 4, 9, 14.
      expect(m[4], closeTo(255, 0.001));
      expect(m[9], closeTo(255, 0.001));
      expect(m[14], closeTo(255, 0.001));
      // Alpha row/column (index 19) is untouched by brightness.
      expect(m[19], 0);
    });

    test('full-negative brightness subtracts 255 per channel', () {
      final m = buildColorMatrix(brightness: -1.0);
      expect(m[4], closeTo(-255, 0.001));
      expect(m[9], closeTo(-255, 0.001));
      expect(m[14], closeTo(-255, 0.001));
    });

    test('brightness values outside -1..1 are clamped', () {
      final over = buildColorMatrix(brightness: 5.0);
      final atMax = buildColorMatrix(brightness: 1.0);
      expect(over, atMax);
    });

    test('zero contrast/saturation with nonzero brightness only offsets',
        () {
      final m = buildColorMatrix(brightness: 0.2);
      // Diagonal scale terms (R,R / G,G / B,B) stay at 1 — only the
      // offset column should move.
      expect(m[0], 1); // R,R
      expect(m[6], 1); // G,G
      expect(m[12], 1); // B,B
    });

    test('full-negative saturation collapses to equal RGB weights per row',
        () {
      final m = buildColorMatrix(saturation: -1.0);
      // Every row's R/G/B coefficients should equal the Rec.601 luma
      // weights, since s = 1 + (-1) = 0 removes the "+(1-lum)*s" term
      // entirely, leaving each row as [lumR, lumG, lumB, 0, 0].
      expect(m[0], closeTo(0.213, 0.001));
      expect(m[1], closeTo(0.715, 0.001));
      expect(m[2], closeTo(0.072, 0.001));
    });

    test('composing brightness+contrast+saturation is order-stable', () {
      // Calling twice with the same inputs must be deterministic (pure
      // function, no hidden state) — this is what lets FilterPanel and
      // VideoPreviewPlayer safely rebuild the matrix on every frame.
      final a = buildColorMatrix(brightness: 0.3, contrast: 0.1, saturation: -0.2);
      final b = buildColorMatrix(brightness: 0.3, contrast: 0.1, saturation: -0.2);
      expect(a, b);
    });
  });

  group('isNeutralFilter', () {
    test('true only when all three values are exactly 0', () {
      expect(isNeutralFilter(), isTrue);
      expect(isNeutralFilter(brightness: 0, contrast: 0, saturation: 0), isTrue);
      expect(isNeutralFilter(brightness: 0.01), isFalse);
      expect(isNeutralFilter(contrast: -0.01), isFalse);
      expect(isNeutralFilter(saturation: 0.01), isFalse);
    });
  });

  group('filterPresets', () {
    test('starts with the no-op "Original" preset', () {
      expect(filterPresets.first.id, 'none');
      expect(
        isNeutralFilter(
          brightness: filterPresets.first.brightness,
          contrast: filterPresets.first.contrast,
          saturation: filterPresets.first.saturation,
        ),
        isTrue,
      );
    });

    test('spec calls for 3-5 additional presets beyond Original', () {
      expect(filterPresets.length - 1, inInclusiveRange(3, 5));
    });

    test('every preset has a unique id', () {
      final ids = filterPresets.map((p) => p.id).toSet();
      expect(ids.length, filterPresets.length);
    });
  });

  group('presetById', () {
    test('finds a preset by id', () {
      expect(presetById('vivid').label, 'Vivid');
    });

    test('falls back to the first (Original) preset for an unknown id', () {
      expect(presetById('not-a-real-id').id, 'none');
      expect(presetById(null).id, 'none');
    });
  });
}
