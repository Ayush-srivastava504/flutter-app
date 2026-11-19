// On-device check of every template: build the project from real and
// synthetic media, export it with the phone's real FFmpeg, and verify the
// file (size, frame rate, length, frame count, audio, A/V sync, black
// frames, decode errors). Also covers the template edge cases: corrupt
// media, a deleted source, cancelling an export, rapid back-to-back builds.
//
// Camera media is copied into <docs>/tpl_media first (see
// docs/TEMPLATE_TEST_REPORT.md for the adb commands); synthetic media is
// made here. Select a subset with
//   --dart-define=TPL_VARIANTS=camera,mixed  --dart-define=TPL_IDS=tpl_birthday
// Results are printed as `TPL>` lines; contact sheets go to <docs>/qa_out.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_editor_app/data/project_database.dart';
import 'package:video_editor_app/export/export_command_builder.dart';
import 'package:video_editor_app/export/export_inputs.dart';
import 'package:video_editor_app/export/export_models.dart';
import 'package:video_editor_app/export/export_service.dart';
import 'package:video_editor_app/models/clip_x.dart';
import 'package:video_editor_app/models/media_asset.dart';
import 'package:video_editor_app/models/video_template.dart';
import 'package:video_editor_app/services/media_import_service.dart';
import 'package:video_editor_app/services/template_service.dart';

import 'support/qa_media.dart';

const _variantsArg = String.fromEnvironment('TPL_VARIANTS', defaultValue: 'camera,mixed,photos,synth,one,extra');
const _idsArg = String.fromEnvironment('TPL_IDS');
const _edgeArg = bool.fromEnvironment('TPL_EDGE', defaultValue: true);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late Directory outDir;
  late ProjectDatabase db;
  late TemplateService service;
  late ExportService exporter;
  final importer = MediaImportService();
  final camVideos = <MediaAsset>[];
  final camPhotos = <MediaAsset>[];
  final synVideos = <MediaAsset>[];
  final synPhotos = <MediaAsset>[];
  final syn = <String, String>{};
  final summary = <String>[];

  setUpAll(() async {
    docs = await getApplicationDocumentsDirectory();
    outDir = Directory(p.join(docs.path, 'qa_out'))..createSync(recursive: true);
    db = ProjectDatabase.forTesting(NativeDatabase.memory()); // keeps test projects off the user's Home
    service = TemplateService(db);
    exporter = ExportService(db: db);

    final cam = Directory(p.join(docs.path, 'tpl_media'));
    // `flutter test` reinstalls the app (wiping tpl_media), so copy the
    // camera samples in from /sdcard/Download/cliper_qa. Read access is
    // granted by `pm grant` from the PC right after install; wait for it.
    if (!cam.existsSync() || cam.listSync().isEmpty) {
      cam.createSync(recursive: true);
      final src = Directory('/sdcard/Download/cliper_qa');
      for (var i = 0; i < 60; i++) {
        try {
          final files = src.listSync().whereType<File>().toList();
          if (files.isNotEmpty && files.every((f) => f.lengthSync() > 0)) {
            for (final f in files) {
              await f.copy(p.join(cam.path, p.basename(f.path)));
            }
            break;
          }
        } catch (_) {}
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      qaLog('copied ${cam.listSync().length} camera samples into tpl_media');
    }
    final files = cam.existsSync() ? (cam.listSync().whereType<File>().map((f) => f.path).toList()..sort()) : <String>[];
    for (final f in files) {
      final a = await importer.assetFromFile(f);
      (a.isVideo ? camVideos : camPhotos).add(a);
      if (a.isVideo) {
        final pr = await probe(f, countFrames: false);
        qaLog('camera ${p.basename(f)}: $pr');
      }
    }

    syn.addAll(await makeSyntheticMedia(Directory(p.join(docs.path, 'qa_syn'))));
    for (final e in syn.entries) {
      if (e.key.contains('corrupt') || e.key.contains('long') || e.key.contains('4k')) continue;
      try {
        final a = await importer.assetFromFile(e.value);
        (a.isVideo ? synVideos : synPhotos).add(a);
        if (a.isVideo) qaLog('synthetic ${e.key}: ${await probe(e.value, countFrames: false)} asset=${a.width}x${a.height} rot=${a.rotationDegrees} dur=${a.duration?.inMilliseconds}');
      } catch (err) {
        qaLog('synthetic ${e.key} import failed: $err');
      }
    }
    qaLog('media: camera ${camVideos.length} videos/${camPhotos.length} photos, '
        'synthetic ${synVideos.length} videos/${synPhotos.length} photos');
  });

  tearDownAll(() async {
    qaLog('SUMMARY\n${summary.join('\n')}\nTOTAL ${summary.length} '
        'PASS ${summary.where((s) => s.startsWith('PASS')).length} '
        'FAIL ${summary.where((s) => !s.startsWith('PASS')).length}');
    await db.close();
  });

  List<MediaAsset> mediaFor(VideoTemplate t, String variant) {
    final n = t.suggestedClips;
    List<MediaAsset> cycle(List<MediaAsset> from, int count) => [for (var i = 0; i < count; i++) from[i % from.length]];
    final allPhotos = [...camPhotos, ...synPhotos];
    switch (variant) {
      case 'camera':
        return cycle(camVideos, n);
      case 'mixed':
        return [for (var i = 0; i < n; i++) i.isEven ? camVideos[i % camVideos.length] : allPhotos[i % allPhotos.length]];
      case 'photos':
        return cycle(allPhotos, n);
      case 'synth':
        return cycle(synVideos, n);
      case 'one':
        return [camVideos.first];
      case 'extra':
        return cycle([...camVideos, ...synVideos], n + 2);
    }
    throw ArgumentError(variant);
  }

  /// Builds [t] from [media], exports at 720p and checks everything.
  /// Returns the problems found (empty = pass).
  Future<List<String>> buildAndVerify(VideoTemplate t, List<MediaAsset> media, String label, {bool sheet = false}) async {
    final problems = <String>[];
    final sw = Stopwatch()..start();
    final id = await service.create(t, media);
    final buildMs = sw.elapsedMilliseconds;
    final clips = await db.watchClips(id).first;
    final project = (await db.getProject(id))!;
    if (clips.length != media.length) problems.add('clips ${clips.length} != ${media.length}');

    // Template settings carried onto every clip.
    final plans = planTemplateClips(t, [for (final m in media) m.isVideo ? m.duration?.inMilliseconds : null]);
    for (var i = 0; i < clips.length && i < plans.length; i++) {
      final c = clips[i];
      if (c.trimEndMs - c.trimStartMs != plans[i].lengthMs) problems.add('clip $i length ${c.trimEndMs - c.trimStartMs} != ${plans[i].lengthMs}');
      if (c.look != t.look) problems.add('clip $i look ${c.look}');
      if (c.effect != plans[i].effect) problems.add('clip $i effect ${c.effect}');
      if (c.transitionOut != plans[i].transitionOut) problems.add('clip $i transition ${c.transitionOut}');
    }
    final layoutMs = layoutTimeline(clips).last.endMs;
    final texts = await db.watchTextOverlays(id).first;
    final wantTexts = placeTemplateTexts(t, layoutMs).length;
    if (texts.length != wantTexts) problems.add('texts ${texts.length} != $wantTexts');
    for (final x in texts) {
      if (x.endMs > layoutMs || x.startMs < 0) problems.add('text "${x.content}" ${x.startMs}-${x.endMs} outside 0-$layoutMs');
    }
    final music = await db.getAudioTrack(id);
    if ((music != null) != (t.musicId != null)) problems.add('music track ${music != null} but template ${t.musicId}');

    final expectedMs = exportDurationMs(exportClipsFrom(clips, const {}));
    final (ew, eh) = exportDimensions(project.aspectRatio, ExportQuality.p720.shortSide);
    var lastP = 0.0;
    var progressBackwards = false;
    sw.reset();
    final file = await exporter.export(
      projectId: id,
      quality: ExportQuality.p720,
      onProgress: (v) {
        if (v + 0.001 < lastP && v != 0) progressBackwards = true;
        lastP = v;
      },
    );
    final exportMs = sw.elapsedMilliseconds;
    final size = await file.length();
    final pr = await probe(file.path);
    final scan = await scanDecode(file.path);

    if (size < 20000) problems.add('tiny file ${size}B');
    if (pr.width != ew || pr.height != eh) problems.add('size ${pr.width}x${pr.height} != ${ew}x$eh');
    if ((pr.fps - 30).abs() > 0.5) problems.add('fps ${pr.fps.toStringAsFixed(2)}');
    if ((pr.durationS * 1000 - expectedMs).abs() > 120) {
      problems.add('length ${pr.durationS.toStringAsFixed(2)}s != ${(expectedMs / 1000).toStringAsFixed(2)}s');
    }
    final wantFrames = (expectedMs / 1000 * 30).round();
    if ((pr.frames - wantFrames).abs() > 3) problems.add('frames ${pr.frames} != ~$wantFrames');
    final anyClipAudio = media.any((m) => m.isVideo && !m.uri.contains('noaudio'));
    if ((t.musicId != null || anyClipAudio) && !pr.hasAudio) problems.add('no audio stream');
    if (pr.audioDurationS != null && (pr.audioDurationS! - pr.videoDurationS).abs() > 0.15) {
      problems.add('A/V length differ: a=${pr.audioDurationS!.toStringAsFixed(2)} v=${pr.videoDurationS.toStringAsFixed(2)}');
    }
    final longBlack = scan.black.where((b) => b.$2 - b.$1 > 0.5).toList();
    if (longBlack.isNotEmpty) problems.add('black ${longBlack.map((b) => '${b.$1}-${b.$2}').join(',')}');
    if (scan.errors.isNotEmpty) problems.add('decode errors: ${scan.errors.take(2).join(' | ')}');
    if (progressBackwards) problems.add('progress went backwards');
    if (lastP != 1) problems.add('progress ended at $lastP');

    if (sheet) await contactSheet(file.path, pr.durationS, p.join(outDir.path, '${t.id}_${label.split(' ').last}.png'));
    final status = problems.isEmpty ? 'PASS' : 'FAIL';
    final line = '$status ${t.id} $label n=${media.length} aspect=${project.aspectRatio.toStringAsFixed(3)} '
        'out=$pr size=${(size / 1024).round()}KB shortBlack=${scan.black.length} texts=${texts.length} '
        'enc=${exporter.lastEncoderUsed?.name} build=${buildMs}ms export=${exportMs}ms'
        '${problems.isEmpty ? '' : ' :: ${problems.join('; ')}'}';
    summary.add(line);
    qaLog('TPL> $line');
    await file.delete();
    await db.deleteProjectCascade(id);
    return problems;
  }

  final variants = _variantsArg.split(',').where((v) => v.isNotEmpty).toList();
  final ids = _idsArg.isEmpty ? null : _idsArg.split(',').toSet();
  for (final t in videoTemplates.where((t) => ids == null || ids.contains(t.id))) {
    for (final variant in variants) {
      testWidgets('${t.id} [$variant]', (tester) async {
        if ((variant == 'camera' || variant == 'mixed' || variant == 'one') && camVideos.isEmpty) {
          markTestSkipped('no camera media pushed');
          return;
        }
        final problems = await buildAndVerify(t, mediaFor(t, variant), '[$variant]',
            sheet: variant == 'synth' || variant == 'camera');
        expect(problems, isEmpty);
      }, timeout: const Timeout(Duration(minutes: 6)));
    }
  }

  if (!_edgeArg) return;

  group('edge cases', () {
    testWidgets('large media: 4K clip and a 2-minute clip in one template', (tester) async {
      final big = <MediaAsset>[];
      for (final k in ['syn_4k.mp4', 'syn_long_120s.mp4']) {
        if (syn[k] != null) big.add(await importer.assetFromFile(syn[k]!));
      }
      expect(big, isNotEmpty);
      final problems = await buildAndVerify(templateById('tpl_yt_vlog')!, [...big, ...big], '[large]');
      expect(problems, isEmpty);
    }, timeout: const Timeout(Duration(minutes: 8)));

    testWidgets('HEVC input', (tester) async {
      if (syn['syn_hevc.mp4'] == null) {
        markTestSkipped('this phone FFmpeg could not encode HEVC test media');
        qaLog('EDGE> HEVC: skipped (no hevc encoder for test media)');
        return;
      }
      final a = await importer.assetFromFile(syn['syn_hevc.mp4']!);
      final problems = await buildAndVerify(templateById('tpl_yt_roadtrip')!, [a, a, a], '[hevc]');
      expect(problems, isEmpty);
    });

    testWidgets('corrupt "video" file is refused at import', (tester) async {
      Object? err;
      try {
        await importer.assetFromFile(syn['syn_corrupt.mp4']!);
      } catch (e) {
        err = e;
      }
      qaLog('EDGE> corrupt import: ${err == null ? 'ACCEPTED (bad)' : 'refused: ${err.runtimeType}: $err'}');
      expect(err, isNotNull);
    });

    testWidgets('source deleted after building → clear "source missing" export error', (tester) async {
      final src = camVideos.isNotEmpty ? camVideos.first.uri : synVideos.first.uri;
      final copy = p.join(docs.path, 'qa_syn', 'gone_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await File(src).copy(copy);
      final a = await importer.assetFromFile(copy);
      final id = await service.create(templateById('tpl_yt_intro')!, [a, a, a]);
      await File(copy).delete();
      Object? err;
      try {
        await exporter.export(projectId: id, quality: ExportQuality.p720, onProgress: (_) {});
      } catch (e) {
        err = e;
      }
      qaLog('EDGE> missing source: $err');
      expect(err, isA<ExportFailure>().having((e) => e.kind, 'kind', ExportFailureKind.sourceMissing));
      await db.deleteProjectCascade(id);
    });

    testWidgets('cancelling a template export stops it and leaves no partial MP4', (tester) async {
      final v = camVideos.isNotEmpty ? camVideos : synVideos;
      final id = await service.create(templateById('tpl_yt_vlog')!, [for (var i = 0; i < 5; i++) v[i % v.length]]);
      final tmp = await getTemporaryDirectory();
      final before = tmp.listSync().whereType<Directory>().where((d) => p.basename(d.path).startsWith('export_')).map((d) => d.path).toSet();
      final sw = Stopwatch()..start();
      final fut = exporter.export(projectId: id, quality: ExportQuality.p1080, onProgress: (_) {});
      await Future<void>.delayed(const Duration(seconds: 3));
      await exporter.cancel();
      Object? err;
      try {
        await fut;
      } catch (e) {
        err = e;
      }
      final newDirs = tmp.listSync().whereType<Directory>().where((d) => p.basename(d.path).startsWith('export_') && !before.contains(d.path));
      final leftovers = [for (final d in newDirs) ...d.listSync().whereType<File>().where((f) => f.path.endsWith('.mp4'))];
      qaLog('EDGE> cancel after 3s: stopped in ${sw.elapsedMilliseconds}ms, $err, leftover mp4: '
          '${leftovers.map((f) => '${p.basename(f.path)} ${f.lengthSync()}B').join(', ')}');
      expect(err, isA<ExportFailure>().having((e) => e.kind, 'kind', ExportFailureKind.interrupted));
      expect(leftovers, isEmpty, reason: 'cancelled export left a partial file');
      await db.deleteProjectCascade(id);
    });

    testWidgets('rapid back-to-back template builds stay consistent', (tester) async {
      final v = camVideos.isNotEmpty ? camVideos : synVideos;
      final sw = Stopwatch()..start();
      final built = await Future.wait([
        for (final t in videoTemplates) service.create(t, [for (var i = 0; i < t.suggestedClips; i++) v[i % v.length]]),
      ]);
      final ms = sw.elapsedMilliseconds;
      final bad = <String>[];
      for (var i = 0; i < built.length; i++) {
        final n = (await db.watchClips(built[i]).first).length;
        if (n != videoTemplates[i].suggestedClips) bad.add('${videoTemplates[i].id}: $n clips');
        await db.deleteProjectCascade(built[i]);
      }
      qaLog('EDGE> ${built.length} templates built concurrently in ${ms}ms; problems: ${bad.isEmpty ? 'none' : bad}');
      expect(bad, isEmpty);
    });
  });
}
