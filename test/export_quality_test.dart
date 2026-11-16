import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/export/export_command_builder.dart';
import 'package:video_editor_app/export/export_models.dart';

/// Export quality settings (2026-11-11): encoder options, resize filter,
/// optional enhance pass.
ExportCommand build({VideoEncoder encoder = VideoEncoder.androidHardwareHigh, bool enhance = false, int fps = 30}) =>
    buildExportCommand(
      clips: const [ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 2000)],
      overlays: const [],
      music: null,
      aspectRatio: 9 / 16,
      quality: ExportQuality.p1080,
      fps: fps,
      encoder: encoder,
      outputPath: '/o.mp4',
      fontPaths: const {'Default': '/f.ttf'},
      textFilePaths: const {},
      enhance: enhance,
    );

String graph(ExportCommand c) => c.args[c.args.indexOf('-filter_complex') + 1];

void main() {
  test('hardware encoders are tried High-profile first, and every encoder sets a 2 s keyframe interval', () {
    expect(VideoEncoder.values.first, VideoEncoder.androidHardwareHigh);
    final high = encoderArgs(VideoEncoder.androidHardwareHigh, 16000000, fps: 30);
    expect(high, containsAllInOrder(['-c:v', 'h264_mediacodec', '-b:v', '16000000']));
    expect(high, containsAllInOrder(['-profile:v', 'high', '-bitrate_mode', 'vbr']));
    for (final e in VideoEncoder.values) {
      final a = encoderArgs(e, 8000000, fps: 60);
      expect(a.sublist(a.indexOf('-g'), a.indexOf('-g') + 2), ['-g', '120'], reason: e.name);
    }
    expect(encoderArgs(VideoEncoder.androidHardware, 1, fps: 30), isNot(contains('-profile:v')),
        reason: 'the plain fallback must use device defaults');
  });

  test('the software fallback is tuned (quality range, RD macroblocks)', () {
    final a = encoderArgs(VideoEncoder.software, 16000000);
    expect(a, containsAllInOrder(['-c:v', 'mpeg4']));
    expect(a, containsAllInOrder(['-qmin', '2', '-qmax', '6', '-mbd', 'rd']));
  });

  test('frames are resized with lanczos', () {
    expect(graph(build()), contains('force_original_aspect_ratio=decrease:flags=lanczos'));
  });

  test('enhance adds denoise + sharpen only when asked', () {
    expect(graph(build()), isNot(contains('cas=')));
    final g = graph(build(enhance: true));
    expect(g, contains('atadenoise='));
    expect(g, contains('cas=strength=0.45'));
  });

  test('4K renders at 2160 on the short side', () {
    final c = buildExportCommand(
      clips: const [ExportClip(path: 'a.mp4', isPhoto: false, trimStartMs: 0, trimEndMs: 1000)],
      overlays: const [],
      music: null,
      aspectRatio: 16 / 9,
      quality: ExportQuality.p2160,
      fps: 30,
      encoder: VideoEncoder.androidHardwareHigh,
      outputPath: '/o.mp4',
      fontPaths: const {'Default': '/f.ttf'},
      textFilePaths: const {},
    );
    expect((c.width, c.height), (3840, 2160));
  });

  test('every encoder has a label, and only the software one warns', () {
    for (final e in VideoEncoder.values) {
      expect(videoEncoderLabel(e), isNotEmpty);
    }
    expect(videoEncoderLabel(VideoEncoder.software), contains('lower quality'));
  });
}
