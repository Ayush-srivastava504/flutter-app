import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/models/color_filter_x.dart';
import 'package:video_editor_app/models/look_x.dart';

/// Tests for F7 (look presets).
void main() {
  test('lookPresets lists "none" first, matching filterPresets\' convention', () {
    expect(lookPresets.first.id, 'none');
  });

  test('lookById falls back to "none" for an unknown or null id', () {
    expect(lookById('not-a-real-look').id, 'none');
    expect(lookById(null).id, 'none');
  });

  test('"none" and null have no color matrix', () {
    expect(lookColorMatrix('none'), isNull);
    expect(lookColorMatrix(null), isNull);
  });

  test('every named look except "vignette" returns a 20-value flat matrix', () {
    for (final id in ['mono', 'sepia', 'vintage', 'cool', 'warm']) {
      final m = lookColorMatrix(id);
      expect(m, isNotNull, reason: '$id should have a color matrix');
      expect(m, hasLength(20), reason: '$id matrix should be 4x5 flat');
    }
  });

  test('"vignette" has no color matrix of its own (handled via vignetteOpacity)', () {
    expect(lookColorMatrix('vignette'), isNull);
  });

  test('mono reuses color_filter_x\'s full-desaturation matrix exactly', () {
    expect(lookColorMatrix('mono'), monoMatrix());
  });

  test('vignetteOpacity is only non-zero for the vignette look', () {
    expect(vignetteOpacity('vignette'), greaterThan(0));
    for (final id in ['none', 'mono', 'sepia', 'vintage', 'cool', 'warm']) {
      expect(vignetteOpacity(id), 0.0, reason: '$id should have no vignette');
    }
    expect(vignetteOpacity(null), 0.0);
  });

  test('composeMatrices(identity, m) returns m unchanged', () {
    const identity = <double>[
      1, 0, 0, 0, 0, //
      0, 1, 0, 0, 0, //
      0, 0, 1, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
    final sepia = lookColorMatrix('sepia')!;
    final composed = composeMatrices(identity, sepia);
    for (var i = 0; i < composed.length; i++) {
      expect(composed[i], closeTo(sepia[i], 1e-9));
    }
  });
}
