import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

/// Voice-over recording through Android's MediaRecorder (see
/// `MainActivity.kt`, channel `clipforge/recorder`). Files go to
/// `<documents>/voiceovers/<uuid>.m4a` — app storage, never uploaded.
class VoiceRecorder {
  static const _channel = MethodChannel('clipforge/recorder');

  String? _path;
  String? get path => _path;

  /// Asks for the microphone if needed. False when the user said no.
  Future<bool> ensurePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> start() async {
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'voiceovers'));
    await dir.create(recursive: true);
    _path = p.join(dir.path, '${const Uuid().v4()}.m4a');
    await _channel.invokeMethod<bool>('start', {'path': _path});
  }

  /// Stops; returns the recording length in ms (0 = nothing usable).
  Future<int> stop() async => await _channel.invokeMethod<int>('stop') ?? 0;

  Future<void> cancel() => _channel.invokeMethod<void>('cancel');

  /// Peak level since the last call, 0..1.
  Future<double> level() async {
    final a = await _channel.invokeMethod<int>('amplitude') ?? 0;
    return (a / 32767).clamp(0.0, 1.0);
  }
}
