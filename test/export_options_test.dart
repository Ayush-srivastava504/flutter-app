import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/app/app_prefs.dart';
import 'package:video_editor_app/export/export_command_builder.dart';
import 'package:video_editor_app/export/export_models.dart';
import 'package:video_editor_app/export/export_service.dart' show estimatedExportBytes;

/// Tests for F5 (export resolution + frame rate).
ExportCommand build(
  List<ExportClip> clips, {
  ExportQuality q = ExportQuality.p720,
  int? fps,
  double aspect = 9 / 16,
  VideoEncoder encoder = VideoEncoder.software,
}) =>
    buildExportCommand(
      clips: clips,
      overlays: const [],
      aspectRatio: aspect,
      quality: q,
      fps: fps ?? defaultExportFps,
      encoder: encoder,
      outputPath: '/out/o.mp4',
      fontPaths: const {'Default': '/f/Sans.ttf'},
      textFilePaths: const {},
    );

ExportClip video(String path, {String t = 'cut'}) =>
    ExportClip(path: path, isPhoto: false, trimStartMs: 0, trimEndMs: 3000, transitionOut: t, hasAudio: true);

ExportClip photo(String path) =>
    ExportClip(path: path, isPhoto: true, trimStartMs: 0, trimEndMs: 2000);

String graph(ExportCommand c) => c.args[c.args.indexOf('-filter_complex') + 1];
String after(ExportCommand c, String flag) => c.args[c.args.indexOf(flag) + 1];

void main() {
  group('480p', () {
    test('is offered, in ascending order', () {
      expect(ExportQuality.values, [ExportQuality.p480, ExportQuality.p720, ExportQuality.p1080, ExportQuality.p2160]);
      expect(ExportQuality.p480.label, '480p');
      expect(ExportQuality.p480.shortSide, 480);
    });

    test('dimensions are even for common aspect ratios', () {
      expect(exportDimensions(9 / 16, 480), (480, 854));
      expect(exportDimensions(16 / 9, 480), (854, 480));
      expect(exportDimensions(1, 480), (480, 480));
      expect(exportDimensions(4 / 5, 480), (480, 600));
    });

    test('command renders at 480x854 for a portrait project', () {
      final cmd = build([video('a.mp4')], q: ExportQuality.p480);
      expect((cmd.width, cmd.height), (480, 854));
      expect(graph(cmd), contains('scale=480:854:force_original_aspect_ratio=decrease'));
      expect(after(cmd, '-b:v'), '4000000');
    });
  });

  group('frame rate in the command', () {
    test('default is 30 fps everywhere (old behaviour unchanged)', () {
      final cmd = build([photo('p.jpg'), video('a.mp4')]);
      expect(cmd.args.join(' '), contains('-loop 1 -framerate 30 -t 2.000 -i p.jpg'));
      expect('fps=30'.allMatches(graph(cmd)).length, 2);
      expect(after(cmd, '-r'), '30');
      expect(after(cmd, '-b:v'), '8000000');
    });

    for (final fps in exportFpsOptions) {
      test('$fps fps drives fps= filter, photo -framerate and output -r', () {
        final cmd = build([photo('p.jpg'), video('a.mp4'), video('b.mp4')], fps: fps);
        final g = graph(cmd);
        expect('fps=$fps,'.allMatches(g).length, 3); // one per clip chain
        for (final other in exportFpsOptions.where((o) => o != fps)) {
          expect(g, isNot(contains('fps=$other,')));
        }
        expect(cmd.args.join(' '), contains('-loop 1 -framerate $fps -t 2.000 -i p.jpg'));
        expect(after(cmd, '-r'), '$fps');
      });
    }

    test('frame rate does not change the timeline length or transitions', () {
      final clips = [video('a.mp4', t: 'dissolve'), video('b.mp4')];
      final a = build(clips, fps: 24);
      final b = build(clips, fps: 60);
      expect(a.totalDurationMs, b.totalDurationMs);
      expect(a.totalDurationMs, 5400);
      expect(graph(b), contains('xfade=transition=fade:duration=0.600:offset=2.400'));
    });

    test('rejects a nonsensical frame rate', () {
      expect(() => build([video('a.mp4')], fps: 0), throwsArgumentError);
      expect(() => build([video('a.mp4')], fps: 500), throwsArgumentError);
    });
  });

  group('bitrate and size estimate', () {
    test('60 fps gets 1.5x the base bitrate; 24 and 30 use the base', () {
      expect(exportVideoBitrate(ExportQuality.p720, 24), 8000000);
      expect(exportVideoBitrate(ExportQuality.p720, 30), 8000000);
      expect(exportVideoBitrate(ExportQuality.p720, 60), 12000000);
      expect(exportVideoBitrate(ExportQuality.p1080, 30), 16000000);
      expect(exportVideoBitrate(ExportQuality.p1080, 60), 24000000);
      expect(exportVideoBitrate(ExportQuality.p480, 60), 6000000);
    });

    test('command uses the fps-adjusted bitrate on every encoder', () {
      for (final e in VideoEncoder.values) {
        final cmd = build([video('a.mp4')], fps: 60, encoder: e);
        expect(after(cmd, '-b:v'), '12000000', reason: e.name);
      }
    });

    test('estimate grows with fps and keeps the old two-argument behaviour', () {
      final base = estimatedExportBytes(ExportQuality.p720, 10000);
      expect(estimatedExportBytes(ExportQuality.p720, 10000, fps: 30), base);
      expect(estimatedExportBytes(ExportQuality.p720, 10000, fps: 60), greaterThan(base));
      expect(estimatedExportBytes(ExportQuality.p480, 10000), lessThan(base));
    });
  });

  group('saved choices', () {
    test('ExportQuality.tryParse accepts known names and rejects the rest', () {
      expect(ExportQuality.tryParse('p480'), ExportQuality.p480);
      expect(ExportQuality.tryParse('p1080'), ExportQuality.p1080);
      expect(ExportQuality.tryParse('p4k'), isNull);
      expect(ExportQuality.tryParse(null), isNull);
    });

    test('sanitizeExportFps falls back to 30 for anything not offered', () {
      expect(sanitizeExportFps(24), 24);
      expect(sanitizeExportFps(60), 60);
      expect(sanitizeExportFps(45), 30);
      expect(sanitizeExportFps(null), 30);
    });

    group('AppPrefs', () {
      late Directory dir;
      setUp(() => dir = Directory.systemTemp.createTempSync('prefs_test'));
      tearDown(() => dir.deleteSync(recursive: true));

      test('nothing saved yet -> nulls', () async {
        final prefs = AppPrefs(directory: () async => dir);
        expect(await prefs.exportQualityName, isNull);
        expect(await prefs.exportFps, isNull);
      });

      test('round-trips across a fresh AppPrefs instance (i.e. an app restart)', () async {
        await AppPrefs(directory: () async => dir).setExportSettings(qualityName: 'p480', fps: 60);

        final reopened = AppPrefs(directory: () async => dir);
        expect(await reopened.exportQualityName, 'p480');
        expect(await reopened.exportFps, 60);
      });

      test('saving export choices keeps the other prefs', () async {
        final prefs = AppPrefs(directory: () async => dir);
        await prefs.setOnboardingDone();
        await prefs.setLastProjectId('proj-1');
        await prefs.setExportSettings(qualityName: 'p720', fps: 24);

        final reopened = AppPrefs(directory: () async => dir);
        expect(await reopened.onboardingDone, isTrue);
        expect(await reopened.lastProjectId, 'proj-1');
        expect(await reopened.exportFps, 24);
      });

      test('a wrongly-typed stored fps reads as null instead of throwing', () async {
        File('${dir.path}/clipforge_prefs.json').writeAsStringSync('{"exportFps":"fast","exportQuality":"p720"}');
        final prefs = AppPrefs(directory: () async => dir);
        expect(await prefs.exportFps, isNull);
        expect(sanitizeExportFps(await prefs.exportFps), 30);
      });
    });
  });
}
