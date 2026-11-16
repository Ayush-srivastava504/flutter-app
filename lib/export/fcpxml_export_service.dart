/// F29: project interchange export.
///
/// Serializes the current timeline to FCPXML 1.10 — the XML interchange
/// format Final Cut Pro, DaVinci Resolve and Premiere Pro can all import —
/// so a rough cut started on ClipForge can be finished on a desktop NLE.
///
/// Scope, deliberately kept narrow (see `docs/FEATURE_PLAN_25.md` F29):
/// clip order, in/out points, rotation, one music track and text-overlay
/// titles all round-trip. `transitionOut` (fade/dissolve) is written as a
/// `<note>` on the clip rather than an overlapping FCPXML `<transition>`,
/// because overlap/offset geometry for transitions differs across NLEs —
/// a clean cut list that imports correctly everywhere beats a transition
/// that imports wrong somewhere. No color grade, no speed changes (the app
/// doesn't have per-clip speed yet either). This is a pure string builder
/// (`buildFcpxml`) plus a thin file-writing wrapper (`FcpxmlExportService`),
/// split the same way `export_command_builder.dart`/`export_service.dart`
/// are, so the XML logic is unit-testable without drift or platform
/// channels.
library fcpxml_export;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/project_database.dart';
import 'export_command_builder.dart' show exportDimensions;
import 'export_models.dart' show defaultExportFps;

/// One timeline clip as FCPXML needs it. Unlike `ExportClip`
/// (export_models.dart, used by the ffmpeg pipeline), this keeps the
/// clip's *source* file's full untrimmed duration separate from the
/// trimmed in/out range — FCPXML writes one `<asset>` per source file
/// (covering its whole duration) and then references an in/out range of
/// it from the spine, rather than baking the trim into the asset itself.
class FcpxmlClip {
  final String path;
  final int sourceDurationMs;
  final int trimStartMs;
  final int trimEndMs;
  final String transitionOut; // cut | fade | dissolve
  final int rotationDegrees;

  const FcpxmlClip({
    required this.path,
    required this.sourceDurationMs,
    required this.trimStartMs,
    required this.trimEndMs,
    this.transitionOut = 'cut',
    this.rotationDegrees = 0,
  });

  int get durationMs => trimEndMs - trimStartMs;
}

class FcpxmlAudioTrack {
  final String path;
  final int sourceDurationMs;
  final int trimStartMs;
  final int trimEndMs;
  final int offsetMs;

  const FcpxmlAudioTrack({
    required this.path,
    required this.sourceDurationMs,
    required this.trimStartMs,
    required this.trimEndMs,
    this.offsetMs = 0,
  });

  int get durationMs => trimEndMs - trimStartMs;
}

class FcpxmlOverlay {
  final String content;
  final int startMs;
  final int endMs;

  const FcpxmlOverlay({required this.content, required this.startMs, required this.endMs});
}

/// Maps drift rows to the plain FCPXML types above. Mirrors
/// `exportClipsFrom`/`exportOverlaysFrom`/`exportMusicFrom` in
/// `export_inputs.dart`, but keeps each source file's full untrimmed
/// `durationMs`, which FCPXML's per-file `<asset>` needs and the ffmpeg
/// pipeline doesn't.
List<FcpxmlClip> fcpxmlClipsFrom(List<Clip> rows) => [
      for (final c in rows)
        FcpxmlClip(
          path: c.sourceUri,
          sourceDurationMs: c.durationMs,
          trimStartMs: c.trimStartMs,
          trimEndMs: c.trimEndMs,
          transitionOut: c.transitionOut,
          rotationDegrees: c.rotationDegrees,
        ),
    ];

FcpxmlAudioTrack? fcpxmlAudioFrom(AudioTrack? t) => t == null
    ? null
    : FcpxmlAudioTrack(
        path: t.sourceUri,
        sourceDurationMs: t.durationMs,
        trimStartMs: t.trimStartMs,
        trimEndMs: t.trimEndMs,
        offsetMs: t.offsetMs,
      );

List<FcpxmlOverlay> fcpxmlOverlaysFrom(List<TextOverlay> rows) => [
      for (final o in rows) FcpxmlOverlay(content: o.content, startMs: o.startMs, endMs: o.endMs),
    ];

/// Builds a complete FCPXML 1.10 document for one timeline. Pure string
/// building, no file I/O — see `FcpxmlExportService.exportProject` for the
/// on-device entry point that reads the database and writes the file.
///
/// [aspectRatio] follows the same width/height convention as the video
/// exporter (`exportDimensions` in `export_command_builder.dart`), using a
/// fixed 1080-px short side as the sequence's reference resolution.
String buildFcpxml({
  required String projectName,
  required double aspectRatio,
  required List<FcpxmlClip> clips,
  FcpxmlAudioTrack? audio,
  List<FcpxmlOverlay> overlays = const [],
  int fps = defaultExportFps,
}) {
  final (width, height) = exportDimensions(aspectRatio, 1080);
  final frameDuration = '1/${fps}s';

  // --- resource ids: r1 = format, r2 = basic-title effect, then one id
  // per distinct source file (clips, then audio) in first-seen order.
  // A split or duplicated clip reuses its parent's `sourceUri` (see
  // `ProjectDatabase.splitClip`/`duplicateClip`), so the *same* source
  // file commonly appears in more than one `FcpxmlClip` — dedupe by path
  // here so each file still gets exactly one `<asset>` resource, not one
  // per clip that references it (which would emit several `<asset>`
  // elements sharing the same id — invalid XML).
  var nextId = 1;
  final formatId = 'r${nextId++}';
  final titleEffectId = 'r${nextId++}';
  final assetIds = <String, String>{}; // sourceUri -> resource id, first-seen order
  final sourceDurationByPath = <String, int>{}; // sourceUri -> full source duration
  String idFor(String path) => assetIds.putIfAbsent(path, () => 'r${nextId++}');
  for (final c in clips) {
    idFor(c.path);
    sourceDurationByPath.putIfAbsent(c.path, () => c.sourceDurationMs);
  }
  if (audio != null) idFor(audio.path);

  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<!DOCTYPE fcpxml>');
  buffer.writeln('<fcpxml version="1.10">');
  buffer.writeln('  <resources>');
  buffer.writeln(
    '    <format id="$formatId" name="FFVideoFormat${height}p$fps" '
    'frameDuration="$frameDuration" width="$width" height="$height"/>',
  );
  if (overlays.isNotEmpty) {
    buffer.writeln(
      '    <effect id="$titleEffectId" name="Basic Title" '
      'uid=".../Titles.localized/Bumper-Opener.localized/Basic Title.localized/Basic Title.moti"/>',
    );
  }
  // One `<asset>` per distinct path in `assetIds` (first-seen order),
  // not per clip — see the dedupe note above.
  for (final path in assetIds.keys) {
    final id = assetIds[path]!;
    final name = _escape(p.basenameWithoutExtension(path));
    final clipSourceDuration = sourceDurationByPath[path];
    if (clipSourceDuration != null) {
      buffer.writeln(
        '    <asset id="$id" name="$name" src="${_fileUri(path)}" '
        'start="0s" duration="${_rational(clipSourceDuration)}" '
        'hasVideo="1" hasAudio="1" format="$formatId"/>',
      );
    } else {
      // Only reachable for `audio.path` when it never also appears as a
      // video clip's path (the normal case: music track is a separate file).
      buffer.writeln(
        '    <asset id="$id" name="$name" src="${_fileUri(path)}" '
        'start="0s" duration="${_rational(audio!.sourceDurationMs)}" hasAudio="1"/>',
      );
    }
  }
  buffer.writeln('  </resources>');

  // --- library / event / project / sequence / spine ---
  final totalMs = clips.fold<int>(0, (sum, c) => sum + c.durationMs);
  buffer.writeln('  <library>');
  buffer.writeln('    <event name="${_escape(projectName)}">');
  buffer.writeln('      <project name="${_escape(projectName)}">');
  buffer.writeln(
    '        <sequence format="$formatId" duration="${_rational(totalMs)}" tcStart="0s">',
  );
  buffer.writeln('          <spine>');

  var cursorMs = 0;
  for (final c in clips) {
    final id = assetIds[c.path]!;
    final name = _escape(p.basenameWithoutExtension(c.path));
    final rotate =
        c.rotationDegrees != 0 ? '<adjust-transform rotation="${-c.rotationDegrees}"/>' : '';
    final note = c.transitionOut != 'cut'
        ? '<note>Outgoing transition in ClipForge: ${_escape(c.transitionOut)} '
            '(not rendered here — add it in your NLE)</note>'
        : '';
    buffer.writeln(
      '            <asset-clip ref="$id" offset="${_rational(cursorMs)}" name="$name" '
      'start="${_rational(c.trimStartMs)}" duration="${_rational(c.durationMs)}" '
      'tcFormat="NDF">$rotate$note</asset-clip>',
    );
    cursorMs += c.durationMs;
  }

  if (audio != null) {
    final id = assetIds[audio.path]!;
    final name = _escape(p.basenameWithoutExtension(audio.path));
    buffer.writeln(
      '            <asset-clip ref="$id" lane="-1" offset="${_rational(audio.offsetMs)}" '
      'name="$name" start="${_rational(audio.trimStartMs)}" '
      'duration="${_rational(audio.durationMs)}" role="music"/>',
    );
  }

  for (var i = 0; i < overlays.length; i++) {
    final o = overlays[i];
    final durMs = o.endMs - o.startMs;
    if (durMs <= 0) continue;
    final styleId = 'ts$i';
    buffer.writeln(
      '            <title ref="$titleEffectId" name="${_escape(o.content)}" '
      'offset="${_rational(o.startMs)}" duration="${_rational(durMs)}" lane="1">'
      '<text><text-style ref="$styleId">${_escape(o.content)}</text-style></text>'
      '<text-style-def id="$styleId"><text-style font="Helvetica" fontSize="48" '
      'fontColor="1 1 1 1" alignment="center"/></text-style-def>'
      '</title>',
    );
  }

  buffer.writeln('          </spine>');
  buffer.writeln('        </sequence>');
  buffer.writeln('      </project>');
  buffer.writeln('    </event>');
  buffer.writeln('  </library>');
  buffer.writeln('</fcpxml>');
  return buffer.toString();
}

/// FCPXML times are rational seconds; `ms/1000s` is always exact (no
/// floating-point drift) and valid wherever a `<time>` value is accepted.
String _rational(int ms) => '$ms/1000s';

String _fileUri(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.startsWith('/') ? 'file://$normalized' : 'file:///$normalized';
}

String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// Reads a project from the database and writes its FCPXML to a temp
/// file. Mirrors `ExportService`'s `_tempDir` pattern so it's equally
/// testable with a fake temp-dir function.
class FcpxmlExportService {
  final ProjectDatabase db;
  final Future<Directory> Function() _tempDir;

  FcpxmlExportService({required this.db, Future<Directory> Function()? tempDir})
      : _tempDir = tempDir ?? getTemporaryDirectory;

  /// Builds the project's FCPXML and writes it to disk. Returns the file
  /// path, or null if the project doesn't exist or has no clips yet
  /// (nothing to export — same condition the video exporter checks).
  Future<String?> exportProject(String projectId) async {
    final project = await db.getProject(projectId);
    if (project == null) return null;

    final snapshot = await db.snapshotProject(projectId);
    if (snapshot.clips.isEmpty) return null;

    final xml = buildFcpxml(
      projectName: project.name,
      aspectRatio: project.aspectRatio,
      clips: fcpxmlClipsFrom(snapshot.clips),
      audio: fcpxmlAudioFrom(snapshot.audioTracks.isEmpty ? null : snapshot.audioTracks.first),
      overlays: fcpxmlOverlaysFrom(snapshot.overlays),
    );

    final dir = await _tempDir();
    final safeName = project.name.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '_').trim();
    final file = File(p.join(dir.path, '${safeName.isEmpty ? 'ClipForge' : safeName}.fcpxml'));
    await file.writeAsString(xml);
    return file.path;
  }
}
