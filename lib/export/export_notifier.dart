import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Progress + completion notifications for exports. Everything is best-effort:
/// a denied permission or an unsupported platform must never break an export.
///
/// NOTE (honest limit): FFmpeg runs on a native thread, so an export normally
/// keeps going when the app is backgrounded, and this notification tells the
/// user when it's done. A true Android foreground service (which stops the OS
/// killing a long export under memory pressure) would need native Kotlin and is
/// listed as follow-up in PHASE_8_PROGRESS.md.
class ExportNotifier {
  static const int _id = 4242;
  static const String _channelId = 'clipforge_export';
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _lastPercent = -1;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ));
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> progress(double fraction) async {
    if (!_ready) return;
    final percent = (fraction * 100).floor();
    if (percent == _lastPercent || percent % 5 != 0 && percent != 99) return; // throttle
    _lastPercent = percent;
    try {
      await _plugin.show(
        _id,
        'Exporting video',
        '$percent%',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Video export',
            channelDescription: 'Shows export progress',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            onlyAlertOnce: true,
            showProgress: true,
            maxProgress: 100,
            progress: percent,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> finished({required bool success, String? message}) async {
    _lastPercent = -1;
    if (!_ready) return;
    try {
      await _plugin.show(
        _id,
        success ? 'Export complete' : 'Export failed',
        message ?? (success ? 'Your video is ready to share.' : 'Open Cliper to try again.'),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Video export',
            channelDescription: 'Shows export progress',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  Future<void> clear() async {
    _lastPercent = -1;
    if (!_ready) return;
    try {
      await _plugin.cancel(_id);
    } catch (_) {}
  }
}
