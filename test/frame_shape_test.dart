import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/models/frame_shape.dart';

void main() {
  test('picks the closest offered frame shape for a video', () {
    expect(nearestFrameShape(1920, 1080), 16 / 9);
    expect(nearestFrameShape(1080, 1920), 9 / 16);
    expect(nearestFrameShape(1080, 1080), 1);
    expect(nearestFrameShape(1440, 1080), 4 / 3);
    expect(nearestFrameShape(1080, 1350), 4 / 5);
  });

  test('a phone video stored landscape with a 90-degree rotation is portrait', () {
    expect(nearestFrameShape(1920, 1080, rotationDegrees: 90), 9 / 16);
    expect(nearestFrameShape(1920, 1080, rotationDegrees: 270), 9 / 16);
    expect(nearestFrameShape(1920, 1080, rotationDegrees: 180), 16 / 9);
  });

  test('unknown size keeps the current shape', () {
    expect(nearestFrameShape(0, 0), isNull);
  });
}
