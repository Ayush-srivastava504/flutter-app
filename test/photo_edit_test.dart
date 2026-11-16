import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/photo/photo_edit.dart';
import 'package:video_editor_app/photo/photo_export_service.dart';

void main() {
  group('PhotoEdit', () {
    test('round-trips through JSON', () {
      final e = const PhotoEdit()
          .withAdjust('exposure', 0.3)
          .withAdjust('fade', 0.5)
          .copyWith(look: 'pro_blockbuster', lookStrength: 0.7, turns: 1, flipH: true, straighten: -4.5, cropRatio: 4 / 5);
      final back = PhotoEdit.decode(e.encode());
      expect(back, e);
      expect(back.value('exposure'), 0.3);
      expect(back.value('contrast'), 0, reason: 'unset sliders read as 0');
      expect((back.look, back.lookStrength, back.turns, back.flipH, back.straighten, back.cropRatio),
          ('pro_blockbuster', 0.7, 1, true, -4.5, 4 / 5));
    });

    test('a slider back at 0 is removed, so an untouched photo is "original"', () {
      final e = const PhotoEdit().withAdjust('contrast', 0.4).withAdjust('contrast', 0);
      expect(e.adjust, isEmpty);
      expect(e.isOriginal, isTrue);
    });

    test('corrupt or hostile data never throws and is clamped', () {
      expect(PhotoEdit.decode('not json'), const PhotoEdit());
      expect(PhotoEdit.decode(null), const PhotoEdit());
      final e = PhotoEdit.decode('{"adjust":{"exposure":9,"fade":-3,"bogus":1},"turns":7,"straighten":200}');
      expect(e.value('exposure'), 1.0);
      expect(e.value('fade'), 0.0, reason: 'fade has min 0');
      expect(e.adjust.containsKey('bogus'), isFalse);
      expect(e.turns, 3);
      expect(e.straighten, 45);
    });

    test('every Tune param id is unique and the shader order covers them all', () {
      final ids = [for (final p in adjustParams) p.id];
      expect(ids.toSet(), hasLength(ids.length));
      // Must match configureAdjustShader's uniform order (shaders/adjust.frag).
      expect(ids.toSet(), {
        'exposure', 'brightness', 'contrast', 'saturation', 'highlights', 'shadows', 'whites', 'blacks', //
        'vibrance', 'warmth', 'tint', 'fade', 'clarity', 'sharpen', 'vignette', 'grain',
      });
    });
  });

  group('croppedSize', () {
    test('no edit = the photo itself', () {
      final s = croppedSize(const PhotoEdit(), 4000, 3000);
      expect((s.width, s.height), (4000.0, 3000.0));
    });

    test('a quarter turn swaps the sides', () {
      final s = croppedSize(const PhotoEdit(turns: 1), 4000, 3000);
      expect((s.width, s.height), (3000.0, 4000.0));
    });

    test('a 1:1 crop of a landscape photo is limited by its height', () {
      final s = croppedSize(const PhotoEdit(cropRatio: 1), 4000, 3000);
      expect((s.width, s.height), (3000.0, 3000.0));
    });

    test('straightening shrinks the crop so no empty corner shows', () {
      for (final deg in [1.0, 5.0, 15.0, -30.0, 45.0]) {
        final e = PhotoEdit(straighten: deg);
        final s = croppedSize(e, 4000, 3000);
        expect(s.width / s.height, closeTo(4000 / 3000, 1e-9), reason: 'keeps the shape');
        expect(s.width, lessThan(4000));
        // All four corners of the crop, rotated back, must lie inside the photo.
        final a = deg * math.pi / 180;
        for (final (x, y) in [(1, 1), (1, -1), (-1, 1), (-1, -1)]) {
          final cx = x * s.width / 2, cy = y * s.height / 2;
          final rx = cx * math.cos(a) - cy * math.sin(a);
          final ry = cx * math.sin(a) + cy * math.cos(a);
          expect(rx.abs(), lessThanOrEqualTo(2000 + 1e-6), reason: '$deg°');
          expect(ry.abs(), lessThanOrEqualTo(1500 + 1e-6), reason: '$deg°');
        }
      }
    });
  });

  group('photo save formats', () {
    test('JPEG is 4:4:4 at near-lossless quality; WebP uses libwebp; PNG needs no conversion', () {
      expect(photoConvertArgs('in.png', 'o.jpg', PhotoFormat.jpeg),
          ['-y', '-i', 'in.png', '-c:v', 'mjpeg', '-pix_fmt', 'yuvj444p', '-q:v', '2', 'o.jpg']);
      expect(photoConvertArgs('in.png', 'o.webp', PhotoFormat.webp), containsAllInOrder(['-c:v', 'libwebp']));
      expect(photoConvertArgs('in.png', 'o.png', PhotoFormat.png), isEmpty);
    });
  });
}
