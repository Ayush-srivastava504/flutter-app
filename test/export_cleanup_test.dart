import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:video_editor_app/data/project_database.dart';
import 'package:video_editor_app/export/export_engine.dart';
import 'package:video_editor_app/export/export_models.dart';
import 'package:video_editor_app/export/export_service.dart';

/// Writes a partial output file (as FFmpeg does) and then reports [result].
class _FakeEngine implements ExportEngine {
  final EngineResult result;
  _FakeEngine(this.result);

  @override
  Future<bool> hasAudioStream(String path) async => false;

  @override
  Future<EngineResult> run(List<String> args, {required void Function(int timeMs) onTimeMs}) async {
    await File(args.last).writeAsBytes(List.filled(4096, 1));
    return result;
  }

  @override
  Future<void> cancel() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProjectDatabase db;
  late Directory tmp;

  setUp(() async {
    db = ProjectDatabase.forTesting(NativeDatabase.memory());
    tmp = await Directory.systemTemp.createTemp('cf_export_cleanup');
    final photo = File(p.join(tmp.path, 'a.jpg'))..writeAsBytesSync([1, 2, 3]);
    final now = DateTime.now();
    await db.insertProject(ProjectsCompanion.insert(id: 'p', name: 'p', createdAt: now, updatedAt: now));
    await db.appendClip(id: 'c', projectId: 'p', sourceUri: photo.path, durationMs: 3000);
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  List<Directory> exportDirs() =>
      tmp.listSync().whereType<Directory>().where((d) => p.basename(d.path).startsWith('export_')).toList();

  Future<Object?> run(EngineResult r) async {
    final service = ExportService(db: db, engine: _FakeEngine(r), tempDir: () async => tmp, encoders: [VideoEncoder.software]);
    try {
      await service.export(projectId: 'p', quality: ExportQuality.p720, onProgress: (_) {});
      return null;
    } catch (e) {
      return e;
    }
  }

  test('a cancelled export leaves no partial MP4 behind', () async {
    final err = await run(const EngineResult(success: false, cancelled: true, log: ''));
    expect(err, isA<ExportFailure>().having((e) => e.kind, 'kind', ExportFailureKind.interrupted));
    expect(exportDirs(), isEmpty);
  });

  test('a failed export leaves no partial MP4 behind', () async {
    final err = await run(const EngineResult(success: false, cancelled: false, log: 'boom'));
    expect(err, isA<ExportFailure>());
    expect(exportDirs(), isEmpty);
  });

  test('a finished export keeps its MP4 (until saved/shared) but drops scratch text files', () async {
    final err = await run(const EngineResult(success: true, cancelled: false, log: ''));
    expect(err, isNull);
    final files = exportDirs().single.listSync().whereType<File>().map((f) => p.extension(f.path)).toList();
    expect(files, ['.mp4']);
  });
}
