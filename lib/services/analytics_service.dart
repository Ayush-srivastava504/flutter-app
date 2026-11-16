import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics + Crashlytics behind one switch.
///
/// * **Optional:** without `android/app/google-services.json` the Gradle
///   plugin isn't applied, `Firebase.initializeApp()` fails, and every call
///   here is a no-op ([available] is false).
/// * **Opt-out:** Settings → Privacy (`AppPrefs.analyticsEnabled`).
/// * **What is sent:** event names and small non-personal parameters
///   (mode, template id, export quality, provider name, success). Never
///   prompts, file names, media or API keys.
class Analytics {
  Analytics._();
  static final Analytics instance = Analytics._();

  bool available = false;
  bool _enabled = true;

  Future<void> init({required bool enabled}) async {
    _enabled = enabled;
    try {
      await Firebase.initializeApp();
      available = true;
    } catch (e) {
      debugPrint('[analytics] off — Firebase not configured ($e)');
      available = false;
      return;
    }
    await setEnabled(enabled);
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      if (_enabled && !kDebugMode) FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (_enabled && !kDebugMode) FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return false;
    };
  }

  Future<void> setEnabled(bool on) async {
    _enabled = on;
    if (!available) return;
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(on);
      // No crash reports from debug builds — they'd drown the real ones.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(on && !kDebugMode);
    } catch (e) {
      debugPrint('[analytics] setEnabled failed: $e');
    }
  }

  /// Logs [name] with [params] (strings/numbers only). Never throws.
  Future<void> log(String name, [Map<String, Object>? params]) async {
    if (!available || !_enabled) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('[analytics] $name failed: $e');
    }
  }
}
