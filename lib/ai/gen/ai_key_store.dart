import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_provider.dart';

/// Where API keys and model overrides live. Keys are stored with
/// `flutter_secure_storage` (Android Keystore–backed encryption); they never
/// leave the phone except in the request to their own provider.
abstract class AiKeyStore {
  Future<String?> key(AiProvider p);
  Future<void> setKey(AiProvider p, String? key);
  Future<String?> modelOverride(AiProvider p, GenKind kind);
  Future<void> setModelOverride(AiProvider p, GenKind kind, String? model);

  /// The model to call: the override if set, else the provider default.
  Future<String?> model(AiProvider p, GenKind kind) async {
    final o = (await modelOverride(p, kind))?.trim();
    return (o == null || o.isEmpty) ? p.defaultModel(kind) : o;
  }

  /// Providers that have a key and can make [kind].
  Future<List<AiProvider>> ready(GenKind kind) async => [
        for (final p in AiProvider.values)
          if (p.supports(kind) && ((await key(p))?.trim().isNotEmpty ?? false)) p,
      ];
}

class SecureAiKeyStore extends AiKeyStore {
  final FlutterSecureStorage _s;
  SecureAiKeyStore([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();

  static String _k(AiProvider p) => 'ai_key_${p.name}';
  static String _m(AiProvider p, GenKind k) => 'ai_model_${p.name}_${k.name}';

  @override
  Future<String?> key(AiProvider p) => _s.read(key: _k(p));

  @override
  Future<void> setKey(AiProvider p, String? key) {
    final v = key?.trim();
    return v == null || v.isEmpty ? _s.delete(key: _k(p)) : _s.write(key: _k(p), value: v);
  }

  @override
  Future<String?> modelOverride(AiProvider p, GenKind kind) => _s.read(key: _m(p, kind));

  @override
  Future<void> setModelOverride(AiProvider p, GenKind kind, String? model) {
    final v = model?.trim();
    return v == null || v.isEmpty ? _s.delete(key: _m(p, kind)) : _s.write(key: _m(p, kind), value: v);
  }
}

/// In-memory store for tests.
class MemoryAiKeyStore extends AiKeyStore {
  final Map<String, String> _m = {};

  @override
  Future<String?> key(AiProvider p) async => _m['k_${p.name}'];

  @override
  Future<void> setKey(AiProvider p, String? key) async {
    final v = key?.trim();
    if (v == null || v.isEmpty) {
      _m.remove('k_${p.name}');
    } else {
      _m['k_${p.name}'] = v;
    }
  }

  @override
  Future<String?> modelOverride(AiProvider p, GenKind kind) async => _m['m_${p.name}_${kind.name}'];

  @override
  Future<void> setModelOverride(AiProvider p, GenKind kind, String? model) async {
    final v = model?.trim();
    if (v == null || v.isEmpty) {
      _m.remove('m_${p.name}_${kind.name}');
    } else {
      _m['m_${p.name}_${kind.name}'] = v;
    }
  }
}
