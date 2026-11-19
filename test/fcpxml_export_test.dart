import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/export/fcpxml_export_service.dart';

/// Tests for F29 (FCPXML project-interchange export). Exercises
/// `buildFcpxml` directly with plain `FcpxmlClip`/`FcpxmlAudioTrack`/
/// `FcpxmlOverlay` values — no database or platform channels needed,
/// same approach as `export_command_builder_test.dart`.

FcpxmlClip clip(
  String path,
  int start,
  int end, {
  int sourceDurationMs = 20000,
  String t = 'cut',
  int rotation = 0,
}) =>
    FcpxmlClip(
      path: path,
      sourceDurationMs: sourceDurationMs,
      trimStartMs: start,
      trimEndMs: end,
      transitionOut: t,
      rotationDegrees: rotation,
    );

void main() {
  test('wraps a minimal timeline in a valid-looking FCPXML document', () {
    final xml = buildFcpxml(
      projectName: 'My Trip',
      aspectRatio: 9 / 16,
      clips: [clip('/a/one.mp4', 0, 5000)],
    );

    expect(xml, contains('<?xml version="1.0" encoding="UTF-8"?>'));
    expect(xml, contains('<fcpxml version="1.10">'));
    expect(xml, contains('</fcpxml>'));
    expect(xml, contains('<project name="My Trip">'));
  });

  test('sequence duration is the sum of trimmed clip durations, not source durations', () {
    final xml = buildFcpxml(
      projectName: 'P',
      aspectRatio: 9 / 16,
      clips: [
        clip('/a/one.mp4', 1000, 4000, sourceDurationMs: 20000), // 3s used
        clip('/a/two.mp4', 0, 2000, sourceDurationMs: 20000), // 2s used
      ],
    );
    // 3s + 2s = 5s = 5000/1000s
    expect(xml, contains('duration="5000/1000s"'));
  });

  test('clips land sequentially on the spine: second clip offset = first clip\'s duration', () {
    final xml = buildFcpxml(
      projectName: 'P',
      aspectRatio: 9 / 16,
      clips: [
        clip('/a/one.mp4', 0, 3000), // 3s
        clip('/a/two.mp4', 0, 2000), // 2s
      ],
    );
    expect(xml, contains('offset="0/1000s"'));
    expect(xml, contains('offset="3000/1000s"'));
  });

  test('each distinct source file gets exactly one asset resource, reused by its asset-clip', () {
    final xml = buildFcpxml(
      projectName: 'P',
      aspectRatio: 9 / 16,
      clips: [
        clip('/a/same.mp4', 0, 1000),
        clip('/a/same.mp4', 1000, 2000), // a split: same source file twice
        clip('/a/other.mp4', 0, 1000),
      ],
    );
    expect('<asset id='.allMatches(xml).length, 2); // two distinct source files
    expect('<asset-clip '.allMatches(xml).length, 3); // three timeline segments
  });

  test('a non-cut transitionOut is recorded as a note, not rendered as overlap', () {
    final xml = buildFcpxml(
      projectName: 'P',
      aspectRatio: 9 / 16,
      clips: [clip('/a/one.mp4', 0, 1000, t: 'dissolve')],
    );
    expect(xml, contains('<note>Outgoing transition in Cliper: dissolve'));
    // still a plain sequential asset-clip, no <transition> element:
    expect(xml.contains('<transition'), isFalse);
  });

  test('non-zero rotation emits an adjust-transform, zero rotation does not', () {
    final rotated = buildFcpxml(
      projectName: 'P',
      aspectRatio: 9 / 16,
      clips: [clip('/a/one.mp4', 0, 1000, rotation: 90)],
    );
    expect(rotated, contains('<adjust-transform rotation="-90"/>'));

    final upright = buildFcpxml(
      projectName: 'P',
      aspectRatio: 9 / 16,
      clips: [clip('/a/one.mp4', 0, 1000, rotation: 0)],
    );
    expect(upright.contains('<adjust-transform'), isFalse);
  });

  test('a music track becomes a lane -1 asset-clip at its timeline offset', () {
    final xml = buildFcpxml(
      projectName: 'P',
      aspectRatio: 9 / 16,
      clips: [clip('/a/one.mp4', 0, 5000)],
      audio: const FcpxmlAudioTrack(
        path: '/m/song.mp3',
        sourceDurationMs: 60000,
        trimStartMs: 0,
        trimEndMs: 4000,
        offsetMs: 500,
      ),
    );
    expect(xml, contains('lane="-1"'));
    expect(xml, contains('offset="500/1000s"'));
    expect(xml, contains('role="music"'));
  });

  test('overlays become titles only when they have positive duration', () {
    final xml = buildFcpxml(
      projectName: 'P',
      aspectRatio: 9 / 16,
      clips: [clip('/a/one.mp4', 0, 5000)],
      overlays: const [
        FcpxmlOverlay(content: 'Hello', startMs: 0, endMs: 1000),
        FcpxmlOverlay(content: 'Zero-length, skipped', startMs: 1000, endMs: 1000),
      ],
    );
    expect('<title '.allMatches(xml).length, 1);
    expect(xml, contains('Hello'));
    expect(xml, isNot(contains('Zero-length, skipped')));
  });

  test('special XML characters in names/content are escaped', () {
    final xml = buildFcpxml(
      projectName: 'Mom & Dad <3',
      aspectRatio: 9 / 16,
      clips: [clip('/a/one.mp4', 0, 1000)],
      overlays: const [FcpxmlOverlay(content: 'A & B < C', startMs: 0, endMs: 500)],
    );
    expect(xml, contains('Mom &amp; Dad &lt;3'));
    expect(xml, contains('A &amp; B &lt; C'));
    expect(xml, isNot(contains('Mom & Dad <3')));
  });

  test('frame duration follows the requested fps', () {
    final xml = buildFcpxml(
      projectName: 'P',
      aspectRatio: 9 / 16,
      clips: [clip('/a/one.mp4', 0, 1000)],
      fps: 24,
    );
    expect(xml, contains('frameDuration="1/24s"'));
  });

  test('file paths are turned into file:// URIs', () {
    final xml = buildFcpxml(
      projectName: 'P',
      aspectRatio: 9 / 16,
      clips: [clip('/storage/emulated/0/Cliper/one.mp4', 0, 1000)],
    );
    expect(xml, contains('src="file:///storage/emulated/0/Cliper/one.mp4"'));
  });

  test('portrait aspect ratio yields a taller-than-wide format, matching exportDimensions', () {
    final xml = buildFcpxml(
      projectName: 'P',
      aspectRatio: 9 / 16,
      clips: [clip('/a/one.mp4', 0, 1000)],
    );
    expect(xml, contains('width="1080" height="1920"'));
  });

  test('landscape aspect ratio yields a wider-than-tall format', () {
    final xml = buildFcpxml(
      projectName: 'P',
      aspectRatio: 16 / 9,
      clips: [clip('/a/one.mp4', 0, 1000)],
    );
    expect(xml, contains('width="1920" height="1080"'));
  });
}
