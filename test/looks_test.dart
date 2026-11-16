import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/export/export_command_builder.dart';
import 'package:video_editor_app/export/export_models.dart';
import 'package:video_editor_app/models/look_x.dart';

/// The look catalogue (`look_x.dart`) and how it exports.
void main() {
  /// FFmpeg filters confirmed present in the phone's FFmpegKit build
  /// (libavfilter.so, 2026-11-11). A look may only export to these.
  const phoneFilters = {
    'colorchannelmixer', 'lutrgb', 'colorbalance', 'negate', 'pixelize', 'unsharp', 'rgbashift', 'noise', 'vignette', 'format',
  };

  test('ids are unique, "none" is first, and every category is used', () {
    final ids = [for (final l in lookPresets) l.id];
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids.first, 'none');
    expect({for (final l in lookPresets.skip(1)) l.category}, LookCategory.values.toSet());
    expect(lookPresets.length, greaterThanOrEqualTo(25));
  });

  test('every matrix is 4x5 and every effect is in range', () {
    for (final l in lookPresets) {
      if (l.matrix != null) expect(l.matrix, hasLength(20), reason: l.id);
      for (final v in [l.edges, l.sharpen, l.grain, l.vignette]) {
        expect(v, inInclusiveRange(0, 1), reason: l.id);
      }
      expect(l.posterize == 0 || l.posterize >= 2, isTrue, reason: l.id);
    }
  });

  test('the original F7 looks keep their ids (they are stored in Clips.look)', () {
    for (final id in ['none', 'mono', 'sepia', 'vintage', 'cool', 'warm', 'vignette']) {
      expect(lookById(id).id, id);
    }
  });

  test('every look exports only to filters the phone build has', () {
    for (final l in lookPresets) {
      for (final step in lookFilters(l.id, outputWidth: 720)) {
        if (step.startsWith(edgeStepPrefix)) continue;
        final name = step.split('=').first;
        expect(phoneFilters, contains(name), reason: '${l.id}: $step');
      }
    }
  });

  test('strength 0 is the same as no look; strength scales effects', () {
    for (final l in lookPresets) {
      expect(lookFilters(l.id, strength: 0), isEmpty, reason: l.id);
    }
    final half = scaledLook('gothic', 0.5);
    expect(half.vignette, closeTo(lookById('gothic').vignette / 2, 1e-9));
    expect(half.matrix![0], closeTo((1 + lookById('gothic').matrix![0]) / 2, 1e-9));
  });

  test('pixel sizes scale with the output width', () {
    expect(lookFilters('pixel', outputWidth: 1080), contains('pixelize=width=14:height=14'));
    expect(lookFilters('pixel', outputWidth: 540), contains('pixelize=width=7:height=7'));
    expect(lookFilters('glitch', outputWidth: 1080), contains('rgbashift=rh=-7:bh=7'));
  });

  test('split-tone looks export colorbalance with the shadow/highlight pushes', () {
    final f = lookFilters('pro_blockbuster');
    expect(f, contains('colorbalance=rs=-0.120:gs=0.020:bs=0.140:rh=0.140:gh=0.040:bh=-0.120'));
    final half = lookFilters('pro_blockbuster', strength: 0.5);
    expect(half, contains('colorbalance=rs=-0.060:gs=0.010:bs=0.070:rh=0.070:gh=0.020:bh=-0.060'));
  });

  test('anime builds an ink-outline branch: split, edge-detect, multiply back', () {
    final cmd = buildExportCommand(
      clips: const [ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 2000, look: 'anime')],
      overlays: const [],
      music: null,
      aspectRatio: 9 / 16,
      quality: ExportQuality.p720,
      fps: 30,
      encoder: VideoEncoder.software,
      outputPath: '/o.mp4',
      fontPaths: const {'Default': '/f.ttf'},
      textFilePaths: const {},
    );
    final g = cmd.args[cmd.args.indexOf('-filter_complex') + 1];
    expect(g, contains('split[ea0][eb0]'));
    expect(g, contains('[eb0]$edgeBranchFilters[ec0]'));
    expect(g, contains('[ea0][ec0]blend=c0_mode=multiply:c0_opacity=0.600'));
    expect(g, contains('[v0]'));
    expect(g, isNot(contains(edgeStepPrefix)), reason: 'the marker never reaches FFmpeg');
  });

  test('x-ray inverts with negate (not a negative matrix, which colorchannelmixer would clip)', () {
    final f = lookFilters('xray');
    expect(f, contains('negate'));
    for (final step in f.where((s) => s.startsWith('colorchannelmixer='))) {
      final coeffs = step.substring('colorchannelmixer='.length).split(':').map((kv) => double.parse(kv.split('=').last));
      expect(coeffs.every((c) => c >= -0.2), isTrue, reason: step);
    }
  });
}
