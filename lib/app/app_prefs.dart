import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Tiny key/value store (one JSON file in app documents) for the two things
/// Phase 9 needs to remember across launches. Avoids a new dependency.
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
