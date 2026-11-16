import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../export/export_engine.dart';
import 'photo_edit.dart';
import 'photo_renderer.dart';

enum PhotoFormat {
  jpeg('JPEG', 'jpg'),
  png('PNG', 'png'),
  webp('WebP', 'webp');

  final String label;
  final String extension;
  const PhotoFormat(this.label, this.extension);
}

/// FFmpeg arguments that convert the rendered PNG at [input] to [format].
/// Encoders `mjpeg` and `libwebp` are in the phone's FFmpegKit build
/// (MASTER_PLAN §8). JPEG uses 4:4:4 chroma (no colour bleeding on edges)
/// at quality 2 (near-lossless); WebP quality 92.
List<String> photoConvertArgs(String input, String output, PhotoFormat format) {
  switch (format) {
    case PhotoFormat.jpeg:
      return ['-y', '-i', input, '-c:v', 'mjpeg', '-pix_fmt', 'yuvj444p', '-q:v', '2', output];
    case PhotoFormat.webp:
      return ['-y', '-i', input, '-c:v', 'libwebp', '-quality', '92', '-pix_fmt', 'yuv420p', output];
    case PhotoFormat.png:
      return const []; // already PNG
  }
}

class PhotoExportResult {
  final String path;
  final int width;
  final int height;

  /// False when this device couldn't render part of the edit (no shader
  /// support); the UI warns.
  final bool complete;
  const PhotoExportResult(this.path, this.width, this.height, this.complete);
}

class PhotoExportException implements Exception {
  final String message;
  final String? detail;
  const PhotoExportException(this.message, {this.detail});
  @override
  String toString() => message;
}

/// Renders a photo at full resolution with its edit and saves it to the
/// gallery album `ClipForge`.
class PhotoExportService {
  final ExportEngine engine;
  PhotoExportService({ExportEngine? engine}) : engine = engine ?? FfmpegKitEngine();

  Future<PhotoExportResult> export({
    required String sourcePath,
    required PhotoEdit edit,
    required PhotoFormat format,
  }) async {
    final source = await decodePhoto(sourcePath);
    final RenderResult result;
    try {
      result = await renderPhoto(source, edit);
    } finally {
      source.dispose();
    }
    final image = result.image;
    final w = image.width, h = image.height;
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw const PhotoExportException('Couldn\'t encode the photo.');

    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'photo_export'));
    await dir.create(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final png = File(p.join(dir.path, 'ClipForge_$stamp.png'));
    await png.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), flush: true);

    var out = png.path;
    if (format != PhotoFormat.png) {
      out = p.join(dir.path, 'ClipForge_$stamp.${format.extension}');
      final r = await engine.run(photoConvertArgs(png.path, out, format), onTimeMs: (_) {});
      if (!r.success || !await File(out).exists()) {
        debugPrint('[photo-export] convert failed\n${r.log}');
        throw PhotoExportException('Couldn\'t save as ${format.label}. Try PNG.', detail: r.log);
      }
      await png.delete();
    }

    try {
      if (!await Gal.hasAccess(toAlbum: true) && !await Gal.requestAccess(toAlbum: true)) {
        throw const PhotoExportException('ClipForge needs permission to save to your gallery.');
      }
      await Gal.putImage(out, album: 'ClipForge');
    } on GalException catch (e) {
      throw PhotoExportException('Couldn\'t save to the gallery.', detail: e.toString());
    }
    debugPrint('[photo-export] OK ${w}x$h ${format.label} -> $out');
    return PhotoExportResult(out, w, h, result.complete);
  }
}
