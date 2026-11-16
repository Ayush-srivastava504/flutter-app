import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../models/look_x.dart';
import '../widgets/shader_programs.dart';
import 'photo_edit.dart';

/// Decodes the image at [path], scaled so its longest side is at most
/// [maxSide] (null = full size). Keeps the aspect ratio.
Future<ui.Image> decodePhoto(String path, {int? maxSide}) async {
  final buffer = await ui.ImmutableBuffer.fromFilePath(path);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  int? tw, th;
  if (maxSide != null && math.max(descriptor.width, descriptor.height) > maxSide) {
    if (descriptor.width >= descriptor.height) {
      tw = maxSide;
    } else {
      th = maxSide;
    }
  }
  final codec = await descriptor.instantiateCodec(targetWidth: tw, targetHeight: th);
  final frame = await codec.getNextFrame();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  return frame.image;
}

/// Pixel size of the image at [path] without decoding the pixels.
Future<({int width, int height})> readImageSize(String path) async {
  final buffer = await ui.ImmutableBuffer.fromFilePath(path);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final size = (width: descriptor.width, height: descriptor.height);
  descriptor.dispose();
  buffer.dispose();
  return size;
}

/// Draws [image] with the geometry of [edit] (flip, quarter turns,
/// straighten, crop) filling a canvas of [out] size. Shared by the preview
/// painter and the full-resolution renderer.
void paintGeometry(Canvas canvas, ui.Image image, PhotoEdit edit, Size out) {
  final crop = croppedSize(edit, image.width.toDouble(), image.height.toDouble());
  final k = out.width / crop.width; // image px -> output px
  canvas.save();
  canvas.clipRect(Offset.zero & out);
  canvas.translate(out.width / 2, out.height / 2);
  canvas.rotate(edit.straighten * math.pi / 180);
  canvas.rotate((edit.turns % 4) * math.pi / 2);
  canvas.scale(edit.flipH ? -1 : 1, edit.flipV ? -1 : 1);
  final w = image.width * k, h = image.height * k;
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromCenter(center: Offset.zero, width: w, height: h),
    Paint()..filterQuality = FilterQuality.high,
  );
  canvas.restore();
}

/// The longest side the full-resolution render is attempted at. Larger
/// photos are scaled down to this (tiled rendering is MASTER_PLAN §3.2,
/// not built yet); if the GPU still refuses, [renderPhoto] retries smaller.
const int maxRenderSide = 8192;

/// Renders [source] with every step of [edit]: geometry, then Tune
/// (`adjust.frag`), then the look (`look.frag`) — the same shaders and order
/// as the on-screen preview, so the saved photo matches what was shown.
///
/// Without shader support (no Impeller) Tune is skipped and the look falls
/// back to its colour matrix; [RenderResult.complete] is then false so the
/// caller can warn.
Future<RenderResult> renderPhoto(ui.Image source, PhotoEdit edit) async {
  final crop = croppedSize(edit, source.width.toDouble(), source.height.toDouble());
  var scale = math.min(1.0, maxRenderSide / math.max(crop.width, crop.height));
  while (true) {
    try {
      return await _render(source, edit, crop, scale);
    } catch (_) {
      if (scale < 0.2) rethrow;
      scale /= 2; // GPU texture too large: try half the size
    }
  }
}

class RenderResult {
  final ui.Image image;

  /// False when part of the edit couldn't be rendered on this device.
  final bool complete;
  const RenderResult(this.image, this.complete);
}

Future<RenderResult> _render(ui.Image source, PhotoEdit edit, ({double width, double height}) crop, double scale) async {
  final w = (crop.width * scale).round().clamp(1, 1 << 15);
  final h = (crop.height * scale).round().clamp(1, 1 << 15);
  final size = Size(w.toDouble(), h.toDouble());
  final pxScale = w / 1080;
  var complete = true;

  Future<ui.Image> pass(void Function(Canvas c) draw) async {
    final rec = ui.PictureRecorder();
    draw(Canvas(rec));
    final pic = rec.endRecording();
    final img = await pic.toImage(w, h);
    pic.dispose();
    return img;
  }

  var img = await pass((c) => paintGeometry(c, source, edit, size));

  if (edit.hasAdjust) {
    final program = await ShaderPrograms.adjust();
    if (program == null) {
      complete = false;
    } else {
      final prev = img;
      final shader = configureAdjustShader(program, edit, pxScale);
      img = await pass((c) {
        c.saveLayer(Offset.zero & size, Paint()..imageFilter = ui.ImageFilter.shader(shader));
        c.drawImage(prev, Offset.zero, Paint());
        c.restore();
      });
      prev.dispose();
      shader.dispose();
    }
  }

  if (edit.hasLook) {
    final look = scaledLook(edit.look, edit.lookStrength);
    if (!look.isNone) {
      final program = await ShaderPrograms.look();
      final prev = img;
      if (program != null) {
        final shader = configureLookShader(program, lookMatrixFor(look), look, pxScale);
        img = await pass((c) {
          c.saveLayer(Offset.zero & size, Paint()..imageFilter = ui.ImageFilter.shader(shader));
          c.drawImage(prev, Offset.zero, Paint());
          c.restore();
        });
        shader.dispose();
      } else {
        if (look.spec.needsShader) complete = false;
        img = await pass((c) => c.drawImage(prev, Offset.zero, Paint()..colorFilter = ColorFilter.matrix(lookMatrixFor(look))));
      }
      prev.dispose();
    }
  }
  return RenderResult(img, complete);
}
