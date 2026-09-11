import 'package:permission_handler/permission_handler.dart';

/// Requests the permissions the editor needs before letting the user
/// import media. Call this from the Home screen on first launch and
/// again lazily if a request was previously denied.
class PermissionService {
  static Future<bool> requestMediaPermissions() async {
    final statuses = await [
      Permission.photos, // iOS gallery / Android 13+ media
      Permission.videos,
      Permission.storage, // Android <13 fallback
      Permission.microphone, // needed if we later support audio recording
    ].request();

    // Consider granted if at least photo/video access succeeded —
    // storage permission is a no-op on newer Android and may report denied.
    return statuses[Permission.photos]?.isGranted == true ||
        statuses[Permission.videos]?.isGranted == true;
  }

  static Future<bool> hasMediaPermissions() async {
    final photos = await Permission.photos.status;
    final videos = await Permission.videos.status;
    return photos.isGranted || videos.isGranted;
  }
}
