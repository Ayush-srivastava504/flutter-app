import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'ai_key_store.dart';
import 'ai_provider.dart';
import 'generators.dart';

final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => SecureAiKeyStore());

/// Runs one generation and saves the result into the app's documents
/// folder (`generated_media/`), so it behaves exactly like imported media:
/// it survives cache clears and the export can read it.
class GenerationJob {
  final AiKeyStore keys;
  final Future<Directory> Function() documentsDir;
  Generator? _generator;

  GenerationJob(this.keys, {Future<Directory> Function()? documentsDir})
      : documentsDir = documentsDir ?? getApplicationDocumentsDirectory;

  /// Returns the saved file's path.
  Future<String> run(AiProvider provider, GenRequest request,
      {void Function(String status)? onStatus, Generator Function(String key, String model)? make}) async {
    if (request.prompt.trim().isEmpty) throw const GenerationException('Describe what you want first.');
    if (!provider.supports(request.kind)) {
      throw GenerationException('${provider.label} can\'t make ${request.kind.name}s.');
    }
    final key = (await keys.key(provider))?.trim();
    if (key == null || key.isEmpty) {
      throw GenerationException('Add your ${provider.label} API key in Settings → AI keys first.');
    }
    final model = await keys.model(provider, request.kind);
    if (model == null) throw GenerationException('No ${request.kind.name} model set for ${provider.label}.');

    final g = (make ?? (k, m) => makeGenerator(provider, k, m))(key, model);
    _generator = g;
    try {
      final media = await g.generate(request, onStatus: onStatus);
      if (media.bytes.isEmpty) throw const GenerationException('The file came back empty. Try again.');
      final dir = Directory(p.join((await documentsDir()).path, 'generated_media'));
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, '${const Uuid().v4()}.${media.extension}'));
      await file.writeAsBytes(media.bytes, flush: true);
      return file.path;
    } finally {
      _generator = null;
      if (!g.cancelled) g.client.close();
    }
  }

  void cancel() => _generator?.cancel();
}
