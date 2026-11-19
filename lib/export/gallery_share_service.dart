import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import 'export_models.dart';

/// Saves a finished export to the device gallery and opens the share sheet.
class GalleryShareService {
  static const String album = 'Cliper';

  /// Saves to the gallery. Throws [ExportFailure] with a person-readable message.
  Future<void> saveToGallery(String path) async {
    try {
      if (!await Gal.hasAccess(toAlbum: true)) {
        if (!await Gal.requestAccess(toAlbum: true)) {
          throw const ExportFailure(
            ExportFailureKind.unknown,
            'Cliper needs permission to save to your gallery. '
            'Allow it in system settings, or use Share to send the file elsewhere.',
          );
        }
      }
      await Gal.putVideo(path, album: album);
    } on GalException catch (e) {
      switch (e.type) {
        case GalExceptionType.notEnoughSpace:
          throw ExportFailure(ExportFailureKind.insufficientStorage,
              'Not enough free storage to save the video to your gallery.');
        case GalExceptionType.accessDenied:
          throw const ExportFailure(
            ExportFailureKind.unknown,
            'Cliper needs permission to save to your gallery. Allow it in system settings.',
          );
        default:
          throw ExportFailure(ExportFailureKind.unknown, 'Couldn\'t save to the gallery.', detail: e.toString());
      }
    }
  }

  Future<void> share(String path) =>
      Share.shareXFiles([XFile(path, mimeType: 'video/mp4')], text: 'Made with Cliper');

  /// Opens the share sheet for a non-video export file, e.g. the F29
  /// FCPXML project file. Generic (unlike [share]) so it's not tied to
  /// a video mime type.
  Future<void> shareFile(String path, {required String mimeType, String? text}) =>
      Share.shareXFiles([XFile(path, mimeType: mimeType)], text: text ?? 'Made with Cliper');
}
