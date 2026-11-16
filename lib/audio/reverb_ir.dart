import 'dart:math' as math;
import 'dart:typed_data';

import 'audio_edit.dart' show audioStudioRate, reverbSeconds;
import 'wav.dart';

/// Impulse response for the convolution reverb (`afir` in `audio_edit.dart`):
/// a short pre-delay, a handful of early reflections, then a decorrelated
/// stereo noise tail that decays 60 dB over the room length and gets darker
/// as it fades (air absorbs highs first). [tone] 0 = dark stone room,
/// 1 = bright hall. Scaled to unit energy per channel so the wet signal is
/// about as loud as the dry one. Deterministic (fixed seed).
Float32List reverbImpulse(double size, double tone, {int sampleRate = audioStudioRate}) {
  final seconds = reverbSeconds(size);
  final n = (seconds * sampleRate).round();
  final out = Float32List(n * 2);
  final rng = math.Random(4242);
  final preDelay = (0.008 + 0.025 * size) * sampleRate;

  for (var ch = 0; ch < 2; ch++) {
    // Early reflections: a few taps in the first ~80 ms.
    for (var k = 0; k < 6; k++) {
      final at = (preDelay + rng.nextDouble() * 0.07 * sampleRate * (0.4 + size)).round();
      if (at < n) out[at * 2 + ch] += (0.6 - k * 0.07) * (rng.nextBool() ? 1 : -1);
    }
    // Diffuse tail with time-varying one-pole low-pass.
    var lp = 0.0;
    final cutStart = 3000 + 9000 * tone; // Hz at the start of the tail
    final cutEnd = 600 + 2500 * tone; // Hz at the end
    for (var i = preDelay.round(); i < n; i++) {
      final t = i / n;
      final env = math.exp(-6.9 * t) * math.min(1.0, (i - preDelay) / (0.01 * sampleRate) + 0.05);
      final cut = cutStart + (cutEnd - cutStart) * t;
      final a = 1 - math.exp(-2 * math.pi * cut / sampleRate);
      lp += a * ((rng.nextDouble() * 2 - 1) - lp);
      out[i * 2 + ch] += lp * env * 0.5;
    }
    var energy = 0.0;
    for (var i = 0; i < n; i++) {
      energy += out[i * 2 + ch] * out[i * 2 + ch];
    }
    final g = energy > 0 ? 1 / math.sqrt(energy) : 0.0;
    for (var i = 0; i < n; i++) {
      out[i * 2 + ch] *= g;
    }
  }
  return out;
}

/// Float WAV bytes of [reverbImpulse] (unit energy kept exactly).
Uint8List reverbImpulseWav(double size, double tone) => encodeWavFloat32(reverbImpulse(size, tone));
