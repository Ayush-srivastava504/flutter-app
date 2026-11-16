import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../ai/media_analysis.dart';
import '../data/project_database.dart';
import '../models/auto_cut.dart';
import '../models/clip_x.dart';

/// AutoCut → "Cut to the beat": rebuilds the timeline from the project's
/// clips so every cut lands on the music's beat (see `models/auto_cut.dart`).
/// One transaction, so undo puts the old timeline back in one step.
class AutoCutService {
  final ProjectDatabase db;
  final MediaAnalyzer analyzer;
  AutoCutService(this.db, this.analyzer);

  /// The music's tempo: known for library tracks, otherwise measured from
  /// the first 90 s (decoded to mono 11 kHz PCM by FFmpeg, analysed in Dart).
  Future<Tempo?> tempoOf(String musicPath) async {
    final known = libraryTempoFor(musicPath);
    if (known != null) return known;
    final dir = await getTemporaryDirectory();
    final raw = File(p.join(dir.path, 'autocut_${DateTime.now().millisecondsSinceEpoch}.pcm'));
    try {
      await analyzer.analyze(['-y', '-i', musicPath, '-t', '90', '-ac', '1', '-ar', '11025', '-f', 's16le', raw.path]);
      if (!await raw.exists()) return null;
      final bytes = await raw.readAsBytes();
      final pcm = bytes.buffer.asInt16List(bytes.offsetInBytes, bytes.lengthInBytes ~/ 2);
      return estimateTempo(Float64List.fromList([for (final v in pcm) v / 32768]), 11025);
    } finally {
      if (await raw.exists()) await raw.delete();
    }
  }

  /// Returns a message for the user. Throws [StateError] with a readable
  /// reason when it can't run.
  Future<String> cutToBeat(String projectId, {required int beatsPerCut}) async {
    final music = await db.getAudioTrack(projectId);
    if (music == null) throw StateError('Add music first — AutoCut cuts to its beat.');
    final clips = await db.watchClips(projectId).first;
    if (clips.isEmpty) throw StateError('Add some clips first.');
    final tempo = await tempoOf(music.sourceUri);
    if (tempo == null) throw StateError("Couldn't find a steady beat in this music. Try a library track.");

    // Put a beat exactly where the music starts, and start the music with the video.
    final trimStart = beatAlignedTrimStart(tempo, music.trimStartMs);
    final available = music.durationMs - trimStart;
    final sources = [
      for (final c in clips)
        BeatSource(c.id, c.isPhoto ? 0 : c.trimStartMs, c.trimEndMs,
            isPhoto: c.isPhoto, speed: c.isPhoto ? 1.0 : c.effectiveSpeed),
    ];
    final plan = planBeatCuts(sources, beatMs: tempo.beatMs, beatsPerCut: beatsPerCut, targetMs: available);
    if (plan.isEmpty) throw StateError('The clips are too short for this cut length. Try fewer beats per cut.');

    final byId = {for (final c in clips) c.id: c};
    final rows = <Clip>[];
    for (var i = 0; i < plan.length; i++) {
      final seg = plan[i];
      final src = byId[seg.clipId]!;
      rows.add(src.copyWith(
        id: const Uuid().v4(),
        orderIndex: i,
        trimStartMs: seg.srcStartMs,
        trimEndMs: seg.srcEndMs,
        durationMs: src.isPhoto ? seg.lengthMs : src.durationMs,
        transitionOut: 'cut', // overlapping transitions would pull cuts off the beat
      ));
    }
    await db.replaceProjectClips(projectId, rows);

    final total = plan.fold<int>(0, (a, s) => a + s.lengthMs);
    final end = (trimStart + total).clamp(trimStart + 1, music.durationMs);
    await db.updateAudioTrack(music.copyWith(
      offsetMs: 0,
      trimStartMs: trimStart,
      trimEndMs: end,
      fadeOutMs: (end - trimStart) > 3000 ? 1200 : 0,
    ));
    final secs = (total / 1000).toStringAsFixed(1);
    return 'Cut ${plan.length} clips on the beat — ${tempo.bpm.round()} bpm, every $beatsPerCut '
        'beat${beatsPerCut == 1 ? '' : 's'}, $secs s.';
  }
}
