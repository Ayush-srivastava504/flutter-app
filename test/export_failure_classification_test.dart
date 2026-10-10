import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/export/export_models.dart';
import 'package:video_editor_app/export/export_service.dart';

void main() {
  test('disk full is recognised', () {
    expect(classifyFfmpegLog('av_interleaved_write_frame(): No space left on device'), ExportFailureKind.insufficientStorage);
  });
  test('codec problems are recognised', () {
    expect(classifyFfmpegLog("Unknown encoder 'h264_mediacodec'"), ExportFailureKind.unsupportedCodec);
    expect(classifyFfmpegLog('x.heic: Invalid data found when processing input'), ExportFailureKind.unsupportedCodec);
  });
  test('missing sources vs missing fonts', () {
    expect(classifyFfmpegLog('/sdcard/a.mp4: No such file or directory'), ExportFailureKind.sourceMissing);
    expect(classifyFfmpegLog("Cannot open fontfile: No such file or directory"), ExportFailureKind.unknown);
  });
  test('anything else is unknown, and every kind has a message', () {
    expect(classifyFfmpegLog('something odd'), ExportFailureKind.unknown);
    for (final k in ExportFailureKind.values) {
      expect(failureMessage(k), isNotEmpty);
    }
  });
  test('size estimate scales with duration and quality', () {
    expect(estimatedExportBytes(ExportQuality.p1080, 10000) > estimatedExportBytes(ExportQuality.p720, 10000), isTrue);
    expect(estimatedExportBytes(ExportQuality.p720, 20000), 2 * estimatedExportBytes(ExportQuality.p720, 10000));
  });
}
