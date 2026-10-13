import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Tiny key/value store (one JSON file in app documents) for the few things
/// the app remembers across launches (onboarding, last project, export choices). Avoids a new dependency.
class AppPrefs {
  final Future<Directory> Function() _dir;
  Map<String, dynamic>? _cache;

  AppPrefs({Future<Directory> Function()? directory}) : _dir = directory ?? getApplicationDocumentsDirectory;

  Future<File> _file() async => File(p.join((await _dir()).path, 'clipforge_prefs.json'));

  Future<Map<String, dynamic>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final f = await _file();
      _cache = await f.exists() ? (jsonDecode(await f.readAsString()) as Map<String, dynamic>) : <String, dynamic>{};
    } catch (_) {
      _cache = <String, dynamic>{}; // corrupt file → start fresh rather than crash on launch
    }
    return _cache!;
  }

  Future<void> _save() async {
    try {
      await (await _file()).writeAsString(jsonEncode(_cache ?? {}), flush: true);
    } catch (_) {}
  }

  Future<bool> get onboardingDone async => (await _load())['onboardingDone'] == true;

  Future<void> setOnboardingDone() async {
    (await _load())['onboardingDone'] = true;
    await _save();
  }

  /// Last export choices, so the Export screen opens on what the user used
  /// last time (F5). Stored as plain values (quality enum name, fps int) —
  /// `ExportQuality.tryParse` / `sanitizeExportFps` validate them on read.
  Future<String?> get exportQualityName async => (await _load())['exportQuality'] as String?;

  Future<int?> get exportFps async {
    final v = (await _load())['exportFps'];
    return v is int ? v : null;
  }

  Future<void> setExportSettings({required String qualityName, required int fps}) async {
    final m = await _load();
    m['exportQuality'] = qualityName;
    m['exportFps'] = fps;
    await _save();
  }

  /// The project the user was last editing, so the home screen can offer "Resume".
  Future<String?> get lastProjectId async => (await _load())['lastProjectId'] as String?;

  Future<void> setLastProjectId(String? id) async {
    final m = await _load();
    if (id == null) {
      m.remove('lastProjectId');
    } else {
      m['lastProjectId'] = id;
    }
    await _save();
  }
}
