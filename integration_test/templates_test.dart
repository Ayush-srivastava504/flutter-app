// On-device check of every template: build the project from real media,
// export it with the real FFmpeg, and verify the result's length.
// Media is pushed to <docs>/tpl_media by scripts/run_template_device_test.sh.
import 'dart:io';

import 'package:video_editor_app/data/project_database.dart';
import 'package:video_editor_app/export/export_models.dart';
import 'package:video_editor_app/export/export_service.dart';
import 'package:video_editor_app/models/video_template.dart';
import 'package:video_editor_app/services/media_import_service.dart';
import 'package:video_editor_app/services/template_service.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffprobe_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every template builds and exports on the device', (tester) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'tpl_media'));
    final files = dir.listSync().whereType<File>().map((f) => f.path).toList()..sort();
    final videos = files.where((f) => f.endsWith('.mp4')).toList();
    final photos = files.where((f) => f.endsWith('.jpg')).toList();
    expect(videos.length, greaterThanOrEqualTo(3));
    expect(photos.length, greaterThanOrEqualTo(3));

    final importer = MediaImportService();
    final vAssets = [for (final v in videos) await importer.assetFromFile(v)];
    final pAssets = [for (final v in photos) await importer.assetFromFile(v)];

    final db = ProjectDatabase();
    final service = TemplateService(db);
    final exporter = ExportService(db: db);
    final report = StringBuffer();
    final failures = <String>[];

    for (final t in videoTemplates) {
      for (final variant in ['videos', 'mixed']) {
        final n = t.suggestedClips;
        final media = [
          for (var i = 0; i < n; i++)
            variant == 'videos' || i.isEven ? vAssets[i % vAssets.length] : pAssets[i % pAssets.length],
        ];
        final label = '${t.id} [$variant] ($n clips)';
        final sw = Stopwatch()..start();
        try {
          final id = await service.create(t, media);
          final clips = await db.watchClips(id).first;
          expect(clips.length, n, reason: 'clip count');
          final project = await db.getProject(id);
          final file = await exporter.export(
            projectId: id,
            quality: ExportQuality.p720,
            onProgress: (_) {},
          );
          final size = await file.length();
          final session = await FFprobeKit.getMediaInformation(file.path);
          final info = session.getMediaInformation();
          final secs = double.tryParse(info?.getDuration() ?? '') ?? 0;
          final expectedMs = clips.fold<int>(0, (a, c) => a + (c.trimEndMs - c.trimStartMs));
          final okLen = secs > 0 && (secs * 1000 - expectedMs).abs() < expectedMs * 0.25 + 1500;
          final streams = info?.getStreams() ?? [];
          final hasMusic = streams.any((s) => s.getType() == 'audio');
          final wantsMusic = t.musicId != null;
          final status = (size > 10000 && okLen && (!wantsMusic || hasMusic)) ? 'PASS' : 'FAIL';
          report.writeln('$status $label aspect=${project?.aspectRatio.toStringAsFixed(2)} '
              'len=${secs.toStringAsFixed(1)}s expected≈${(expectedMs / 1000).toStringAsFixed(1)}s '
              'size=${(size / 1024).round()}KB audio=$hasMusic text=${t.texts.length} '
              'encoder=${exporter.lastEncoderUsed?.name} took=${sw.elapsed.inSeconds}s');
          if (status == 'FAIL') failures.add(label);
          await file.delete();
        } catch (e, st) {
          report.writeln('ERROR $label: $e');
          failures.add(label);
          // ignore: avoid_print
          print('ERROR $label: $e\n$st');
        }
        // ignore: avoid_print
        print('TPL> ${report.toString().trim().split('\n').last}');
      }
    }
    // ignore: avoid_print
    print('TPL-REPORT\n$report\nTPL-FAILURES: ${failures.length}');
    expect(failures, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 60)));
}
