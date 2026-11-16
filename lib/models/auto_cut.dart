/// AutoCut: re-cut the timeline so every cut lands on the music's beat.
///
/// Pure Dart (tested in `test/autocut_test.dart`):
///  * [libraryTempoFor] — library tracks know their tempo and start on a beat.
///  * [estimateTempo] — any other music: onset envelope + autocorrelation
///    over 60–180 BPM, then the beat phase that best lines up with onsets.
///  * [planBeatCuts] — which part of which clip fills each beat-length slot:
///    clips take turns, and the slots taken from one clip are spread evenly
///    across it (not just its first seconds).
library auto_cut;

import 'dart:math' as math;

import 'audio_library.dart';

class Tempo {
  final double bpm;

  /// Where the first beat falls in the audio file.
  final int firstBeatMs;
  const Tempo(this.bpm, this.firstBeatMs);

  double get beatMs => 60000 / bpm;

  @override
  String toString() => 'Tempo(${bpm.toStringAsFixed(1)} bpm, first beat $firstBeatMs ms)';
}

/// Library music is copied in as `bundled_audio/<id>.m4a`; its tempo is known
/// and it starts exactly on a beat. Null for anything else.
Tempo? libraryTempoFor(String musicPath) {
  final name = musicPath.replaceAll('\\', '/').split('/').last;
  final id = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
  for (final s in audioLibrary) {
    if (!s.isSfx && s.id == id && s.bpm > 0) return Tempo(s.bpm.toDouble(), 0);
  }
  return null;
}

/// Tempo of mono [samples] (-1..1) at [sampleRate]. Null when the audio is
/// too short or has no clear pulse.
Tempo? estimateTempo(List<double> samples, int sampleRate, {double minBpm = 60, double maxBpm = 180}) {
  const hop = 256, win = 512;
  final frames = (samples.length - win) ~/ hop;
  if (frames < 64) return null;

  // Onset strength: rise in log energy, frame to frame.
  final energy = List<double>.filled(frames, 0);
  for (var f = 0; f < frames; f++) {
    var e = 0.0;
    final o = f * hop;
    for (var i = 0; i < win; i++) {
      final v = samples[o + i];
      e += v * v;
    }
    energy[f] = math.log(1e-8 + e);
  }
  final onset = List<double>.filled(frames, 0);
  for (var f = 1; f < frames; f++) {
    onset[f] = math.max(0, energy[f] - energy[f - 1]);
  }
  // Remove the slow trend so loud passages don't dominate.
  final fps = sampleRate / hop;
  final avgN = math.max(1, fps.round());
  var run = 0.0;
  final detr = List<double>.filled(frames, 0);
  for (var f = 0; f < frames; f++) {
    run += onset[f];
    if (f >= avgN) run -= onset[f - avgN];
    detr[f] = math.max(0, onset[f] - run / math.min(f + 1, avgN));
  }

  // Autocorrelation over the allowed tempo range, with a mild preference for
  // ~110 BPM so a beat isn't mistaken for half or double time.
  final minLag = (60 * fps / maxBpm).floor(), maxLag = (60 * fps / minBpm).ceil();
  if (maxLag >= frames ~/ 2) return null;
  var best = -1.0;
  var bestLag = minLag;
  for (var lag = minLag; lag <= maxLag; lag++) {
    var r = 0.0;
    for (var f = 0; f + lag < frames; f++) {
      r += detr[f] * detr[f + lag];
    }
    r /= (frames - lag);
    final bpm = 60 * fps / lag;
    final prior = math.exp(-0.5 * math.pow(math.log(bpm / 110) / 0.55, 2));
    final s = r * (0.6 + 0.4 * prior);
    if (s > best) {
      best = s;
      bestLag = lag;
    }
  }
  if (best <= 0) return null;

  // Refine tempo and phase together: a fine search around the
  // autocorrelation peak for the beat grid that collects the most onset
  // strength on average. Then compare half and double time, weighted by how
  // likely each tempo is, so a 120 bpm beat isn't reported as 60.
  double comb(double lag, double phase) {
    var sum = 0.0;
    var count = 0;
    for (var t = phase; t < frames - 1; t += lag) {
      final i = t.floor();
      final fr = t - i;
      sum += detr[i] * (1 - fr) + detr[i + 1] * fr;
      count++;
    }
    return count == 0 ? 0 : sum / count;
  }

  (double, double, double) refine(double lag0) {
    var bestS = -1.0, bestL = lag0, bestP = 0.0;
    for (var k = -15; k <= 15; k++) {
      final lag = lag0 * (1 + k * 0.002);
      for (var phase = 0.0; phase < lag; phase += 0.25) {
        final sc = comb(lag, phase);
        if (sc > bestS) {
          bestS = sc;
          bestL = lag;
          bestP = phase;
        }
      }
    }
    return (bestL, bestP, bestS);
  }

  double prior(double bpm) => math.exp(-0.5 * math.pow(math.log(bpm / 110) / 0.55, 2));

  final lag0 = bestLag.toDouble();
  var chosen = (lag0, 0.0, -1.0);
  var chosenScore = -1.0;
  for (final cand in [lag0, lag0 / 2, lag0 * 2]) {
    final bpm = 60 * fps / cand;
    if (bpm < minBpm * 0.99 || bpm > maxBpm * 1.01 || cand * 2 >= frames) continue;
    final r = refine(cand);
    final sc = r.$3 * prior(60 * fps / r.$1);
    if (sc > chosenScore) {
      chosenScore = sc;
      chosen = r;
    }
  }
  if (chosenScore <= 0) return null;
  final bpm = 60 * fps / chosen.$1;

  // A frame's energy jumps as soon as a hit enters its window, i.e. up to a
  // window before the hit itself; report the middle of that range.
  final firstBeat = (chosen.$2 * hop + win - hop / 2) / sampleRate * 1000;
  return Tempo(bpm, (firstBeat % (60000 / bpm)).round());
}

/// A clip's usable material for AutoCut.
class BeatSource {
  final String clipId;
  final int srcStartMs;
  final int srcEndMs;
  final bool isPhoto;
  final double speed;
  const BeatSource(this.clipId, this.srcStartMs, this.srcEndMs, {this.isPhoto = false, this.speed = 1.0});
}

/// One new clip: [clipId]'s source from [srcStartMs] to [srcEndMs], playing
/// for [lengthMs] on the timeline.
class BeatSegment {
  final String clipId;
  final int srcStartMs;
  final int srcEndMs;
  final int lengthMs;
  const BeatSegment(this.clipId, this.srcStartMs, this.srcEndMs, this.lengthMs);

  @override
  bool operator ==(Object other) =>
      other is BeatSegment &&
      other.clipId == clipId &&
      other.srcStartMs == srcStartMs &&
      other.srcEndMs == srcEndMs &&
      other.lengthMs == lengthMs;

  @override
  int get hashCode => Object.hash(clipId, srcStartMs, srcEndMs, lengthMs);

  @override
  String toString() => 'BeatSegment($clipId, $srcStartMs-$srcEndMs, $lengthMs)';
}

/// Fills up to [targetMs] of timeline with segments [beatsPerCut] beats long.
/// Slot boundaries are rounded from the exact beat grid, so cuts never drift
/// off the beat however many there are. Each photo is used once.
List<BeatSegment> planBeatCuts(
  List<BeatSource> sources, {
  required double beatMs,
  required int beatsPerCut,
  required int targetMs,
  int maxSegments = 300,
}) {
  if (sources.isEmpty || beatMs <= 0 || beatsPerCut <= 0 || targetMs <= 0) return const [];
  final cut = beatMs * beatsPerCut;
  final slots = math.min(maxSegments, math.max(1, (targetMs / cut).floor()));
  int slotLen(int i) => ((i + 1) * cut).round() - (i * cut).round();

  // How many slots each source could fill (video: by length; photo: once).
  int capacity(BeatSource s) {
    if (s.isPhoto) return 1;
    final need = (cut * s.speed).ceil();
    return need <= 0 ? 0 : (s.srcEndMs - s.srcStartMs) ~/ need;
  }

  final cap = [for (final s in sources) capacity(s)];
  // Round-robin assignment of slots to sources that still have room.
  final order = <int>[];
  final used = List<int>.filled(sources.length, 0);
  var k = 0;
  while (order.length < slots) {
    var placed = false;
    for (var j = 0; j < sources.length && order.length < slots; j++) {
      final s = (k + j) % sources.length;
      if (used[s] < cap[s]) {
        order.add(s);
        used[s]++;
        placed = true;
      }
    }
    k++;
    if (!placed) break; // every clip is used up
  }

  // Spread each source's slots evenly across its material.
  final nth = List<int>.filled(sources.length, 0);
  final out = <BeatSegment>[];
  for (var i = 0; i < order.length; i++) {
    final s = sources[order[i]];
    final len = slotLen(i);
    if (s.isPhoto) {
      out.add(BeatSegment(s.clipId, 0, len, len));
      continue;
    }
    final srcLen = (len * s.speed).round();
    final span = s.srcEndMs - s.srcStartMs;
    final count = used[order[i]];
    final j = nth[order[i]]++;
    final free = math.max(0, span - srcLen);
    final start = s.srcStartMs + (count <= 1 ? 0 : (free * j / (count - 1)).round());
    out.add(BeatSegment(s.clipId, start, start + srcLen, len));
  }
  return out;
}

/// Music trim start that puts a beat exactly at the start of the music on
/// the timeline: the first beat at or after [currentTrimStartMs].
int beatAlignedTrimStart(Tempo t, int currentTrimStartMs) {
  final b = t.beatMs;
  final k = ((currentTrimStartMs - t.firstBeatMs) / b).ceil();
  return math.max(0, (t.firstBeatMs + k * b).round());
}
