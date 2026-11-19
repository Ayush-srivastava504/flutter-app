// On-device check of every look (filter) and every Stylise / Glow effect,
// in the preview (the real GPU shader, read back from the screen) and in
// the export (the real FFmpeg filters). Catches "doesn't apply" (output
// identical to no look) and "turns black" (dark or empty picture).
// Results are printed as `LOOK>` lines; crops go to <docs>/qa_out/looks.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_editor_app/data/project_database.dart';
import 'package:video_editor_app/export/export_models.dart';
import 'package:video_editor_app/export/export_service.dart';
import 'package:video_editor_app/models/effect_x.dart';
import 'package:video_editor_app/models/look_x.dart';
import 'package:video_editor_app/widgets/glow_overlay.dart';
import 'package:video_editor_app/widgets/look_filtered.dart';
import 'package:video_editor_app/widgets/shader_programs.dart';

import 'support/qa_media.dart';

class _Stats {
  final double meanLuma;
  final double blackFrac;
  final double diff; // mean |Δ| vs the unfiltered picture, 0..1
  /// Rows (of 240) that are entirely black — a shader that produced NaN
  /// or sampled outside the picture leaves whole black bands.
  final int blackRows;
  _Stats(this.meanLuma, this.blackFrac, this.diff, this.blackRows);
  @override
  String toString() => 'luma=${meanLuma.toStringAsFixed(3)} black=${(blackFrac * 100).toStringAsFixed(0)}% '
      'diff=${diff.toStringAsFixed(3)} blackRows=$blackRows';
}

_Stats _stats(Uint8List rgba, Uint8List? base) {
  var sum = 0.0, black = 0, d = 0.0;
  final n = rgba.length ~/ 4;
  for (var i = 0; i < rgba.length; i += 4) {
    final l = (0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2]) / 255;
    sum += l;
    if (l < 0.04) black++;
    if (base != null) {
      d += ((rgba[i] - base[i]).abs() + (rgba[i + 1] - base[i + 1]).abs() + (rgba[i + 2] - base[i + 2]).abs()) / 765;
    }
  }
  var rows = 0;
  const w = 360;
  for (var y = 0; y < rgba.length ~/ (w * 4); y++) {
    var allBlack = true;
    for (var x = 0; x < w && allBlack; x += 4) {
      final i = (y * w + x) * 4;
      if (rgba[i] + rgba[i + 1] + rgba[i + 2] > 12) allBlack = false;
    }
    if (allBlack) rows++;
  }
  return _Stats(sum / n, black / n, d / n, rows);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final results = <String>[];

  late Directory docs;
  late Directory out;
  late Map<String, String> syn;

  setUpAll(() async {
    docs = await getApplicationDocumentsDirectory();
    out = Directory(p.join(docs.path, 'qa_out', 'looks'))..createSync(recursive: true);
    syn = await makeSyntheticMedia(Directory(p.join(docs.path, 'qa_syn')));
    qaLog('shader filters supported: ${ui.ImageFilter.isShaderFilterSupported}; '
        'look program: ${await ShaderPrograms.look() != null}');
  });

  tearDownAll(() {
    qaLog('LOOK SUMMARY\n${results.join('\n')}\nTOTAL ${results.length} '
        'FAIL ${results.where((r) => r.startsWith('FAIL')).length}');
  });

  // ---- Preview: the real widget + shader, placed below a 260 px header like
  // the editor's preview, captured from the whole screen. ---------------
  final cases = <(String, Widget Function(Widget child))>[
    for (final l in lookPresets) ('look:${l.id}', (c) => LookFiltered(look: l.id, child: c)),
    for (final e in effectPresets.where((e) => e.kind == EffectKind.stylise))
      // The editor nests the effect pass around the look pass.
      ('fx:${e.id}', (c) => LookFiltered(spec: e.style, strength: 1, child: LookFiltered(child: c))),
    for (final e in effectPresets.where((e) => e.kind == EffectKind.glow))
      ('fx:${e.id}', (c) => Stack(fit: StackFit.expand, children: [c, GlowOverlay(effectId: e.id, strength: 1)])),
    ('look:cinematic+fx:fx_vhs',
        (c) => LookFiltered(spec: effectById('fx_vhs')!.style, strength: 1, child: LookFiltered(look: 'cinematic', child: c))),
  ];

  testWidgets('preview: every look and effect changes the picture and never blacks it out', (tester) async {
    // Smooth gradients and fine detail (flat colour bars hide posterize,
    // subtle grades and sharpening).
    final photo = p.join(docs.path, 'qa_syn', 'look_photo.png');
    if (!File(photo).existsSync()) {
      final (ok, log) = await ffmpeg(['-f', 'lavfi', '-i', 'mandelbrot=s=1440x960:end_pts=1', '-frames:v', '1', photo]);
      expect(ok, isTrue, reason: log);
    }
    final rootKey = GlobalKey();
    final boxKey = GlobalKey();
    await ShaderPrograms.look();
    Uint8List? base;

    Future<Uint8List> capture(Widget Function(Widget) wrap) async {
      await tester.pumpWidget(RepaintBoundary(
        key: rootKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.grey,
            body: Column(children: [
              const SizedBox(height: 260),
              SizedBox(
                key: boxKey,
                width: 360,
                height: 240,
                child: wrap(Image.file(File(photo), fit: BoxFit.cover, cacheWidth: 1080, gaplessPlayback: true)),
              ),
            ]),
          ),
        ),
      ));
      // Image decode + shader program load happen off the frame.
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
      }
      final rect = tester.getRect(find.byKey(boxKey));
      final boundary = rootKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final img = await boundary.toImage(pixelRatio: 1);
        final data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
        final w = img.width;
        final crop = BytesBuilder();
        for (var y = rect.top.round(); y < rect.bottom.round(); y++) {
          crop.add(data.sublist((y * w + rect.left.round()) * 4, (y * w + rect.right.round()) * 4));
        }
        return crop.toBytes();
      });
      return bytes!;
    }

    Future<void> savePng(String name, Uint8List rgba) => tester.runAsync(() async {
          final c = Completer<ui.Image>();
          ui.decodeImageFromPixels(rgba, 360, 240, ui.PixelFormat.rgba8888, c.complete);
          final png = await (await c.future).toByteData(format: ui.ImageByteFormat.png);
          await File(p.join(out.path, '${name.replaceAll(':', '_')}.png')).writeAsBytes(png!.buffer.asUint8List());
        });

    base = await capture((c) => c);
    await savePng('preview_base', base);
    final baseStats = _stats(base, null);
    qaLog('LOOK> preview base: $baseStats');
    for (final (name, wrap) in cases) {
      final px = await capture(wrap);
      final s = _stats(px, base);
      final problems = <String>[];
      if (!name.endsWith(':none')) {
        if (s.diff < 0.004) problems.add('not applied (same as original)');
        if (s.blackFrac > 0.6 || s.meanLuma < 0.06) problems.add('picture went black');
        if (s.blackRows > baseStats.blackRows + 3) problems.add('${s.blackRows} rows fully black');
      }
      // Subtle effects must stay close to the original: a big difference
      // means the shader sampled the wrong place (shifted / cropped picture).
      if ({'fx:fx_grain', 'fx:fx_detail'}.contains(name) && s.diff > 0.12) problems.add('picture displaced');
      await savePng('preview_$name', px);
      final line = '${problems.isEmpty ? 'PASS' : 'FAIL'} preview $name $s${problems.isEmpty ? '' : ' :: ${problems.join('; ')}'}';
      results.add(line);
      qaLog('LOOK> $line');
    }
    expect(results.where((r) => r.startsWith('FAIL preview')), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 10)));

  // ---- Export: one 3 s clip with each look / effect through real FFmpeg. --
  testWidgets('export: every look and effect renders (not black, not unchanged)', (tester) async {
    final db = ProjectDatabase.forTesting(NativeDatabase.memory());
    final exporter = ExportService(db: db);
    final src = p.join(docs.path, 'qa_syn', 'look_src.mp4');
    if (!File(src).existsSync()) {
      final (ok, log) = await ffmpeg(['-i', syn['syn_land_1080p30.mp4']!, '-t', '2', '-c', 'copy', src]);
      expect(ok, isTrue, reason: log);
    }

    Future<(double, DecodeScan, Probe)> exportWith({String? look, String? effect}) async {
      final id = 'p${DateTime.now().microsecondsSinceEpoch}';
      final now = DateTime.now();
      await db.insertProject(ProjectsCompanion.insert(id: id, name: id, aspectRatio: const Value(16 / 9), createdAt: now, updatedAt: now));
      await db.appendClip(id: '${id}c', projectId: id, sourceUri: src, durationMs: 2000);
      final c = (await db.getClip('${id}c'))!;
      await db.updateClip(c.copyWith(look: Value(look), effect: Value(effect), lookStrength: 1, effectStrength: 1));
      final f = await exporter.export(projectId: id, quality: ExportQuality.p720, onProgress: (_) {});
      final (_, log) = await ffmpeg(['-i', f.path, '-vf', 'signalstats,metadata=print:key=lavfi.signalstats.YAVG', '-an', '-f', 'null', '-']);
      final ys = RegExp(r'YAVG=([\d.]+)').allMatches(log).map((m) => double.parse(m.group(1)!)).toList();
      final yavg = ys.isEmpty ? -1.0 : ys.reduce((a, b) => a + b) / ys.length;
      final scan = await scanDecode(f.path);
      final pr = await probe(f.path, countFrames: false);
      await contactSheet(f.path, pr.durationS, p.join(out.path, 'export_${look ?? 'none'}_${effect ?? 'none'}.png'));
      await f.delete();
      await db.deleteProjectCascade(id);
      return (yavg, scan, pr);
    }

    final (baseY, _, _) = await exportWith();
    qaLog('LOOK> export base YAVG=${baseY.toStringAsFixed(1)}');
    final exportCases = <(String?, String?)>[
      for (final l in lookPresets.where((l) => !l.isNone)) (l.id, null),
      for (final e in effectPresets.where((e) => e.kind != EffectKind.motion)) (null, e.id),
      ('cinematic', 'fx_vhs'),
      ('noir', 'fx_glow'),
    ];
    for (final (look, effect) in exportCases) {
      final name = [if (look != null) 'look:$look', if (effect != null) 'fx:$effect'].join('+');
      final problems = <String>[];
      try {
        final (y, scan, pr) = await exportWith(look: look, effect: effect);
        if (y < 0) problems.add('no stats');
        if (y >= 0 && y < 20) problems.add('black (YAVG ${y.toStringAsFixed(1)})');
        final black = scan.black.fold<double>(0, (a, b) => a + b.$2 - b.$1);
        if (black > 0.5) problems.add('black ${black.toStringAsFixed(1)}s');
        if (scan.errors.isNotEmpty) problems.add('decode errors');
        final line = '${problems.isEmpty ? 'PASS' : 'FAIL'} export $name YAVG=${y.toStringAsFixed(1)} '
            '(base ${baseY.toStringAsFixed(1)}) ${pr.width}x${pr.height}${problems.isEmpty ? '' : ' :: ${problems.join('; ')}'}';
        results.add(line);
        qaLog('LOOK> $line');
      } catch (e) {
        final line = 'FAIL export $name :: $e';
        results.add(line);
        qaLog('LOOK> $line');
      }
    }
    await db.close();
    expect(results.where((r) => r.startsWith('FAIL export')), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 20)));
}
