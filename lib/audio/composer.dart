/// Audio Studio → Compose: a small beat + chords maker, rendered on the phone
/// by a pure-Dart synth (no samples, no packages). The result is a WAV that
/// opens in the audio editor like any other sound, so reverb, echo, EQ… all
/// apply to it.
///
/// A [Composition] is plain data (`AudioProjects.composeJson`); [renderComposition]
/// turns it into interleaved stereo samples. Deterministic: same data, same sound.
library composer;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

const int composeRate = 44100;

const List<String> noteNames = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
const List<String> drumRows = ['kick', 'snare', 'clap', 'hat', 'open'];
const List<String> drumLabels = ['Kick', 'Snare', 'Clap', 'Hi-hat', 'Open hat'];

enum ComposeInstrument {
  keys('Electric keys'),
  pad('Warm pad'),
  pluck('Plucked strings'),
  piano('Piano');

  final String label;
  const ComposeInstrument(this.label);
}

class Composition {
  final int bpm; // 60..160
  final int keyRoot; // 0..11 (C..B)
  final bool minor;

  /// One chord per bar, as scale degrees 0..6 (I..VII), 4 bars.
  final List<int> chords;
  final ComposeInstrument instrument;
  final bool bass;
  final bool melody;

  /// 16 steps per row, rows as in [drumRows].
  final List<List<bool>> drums;
  final double swing; // 0..0.5
  final int repeats; // times the 4-bar loop plays, 1..8
  final String style;

  const Composition({
    this.bpm = 90,
    this.keyRoot = 9,
    this.minor = true,
    this.chords = const [0, 5, 2, 6],
    this.instrument = ComposeInstrument.keys,
    this.bass = true,
    this.melody = true,
    this.drums = const [],
    this.swing = 0.2,
    this.repeats = 4,
    this.style = 'lofi',
  });

  List<List<bool>> get grid => drums.length == drumRows.length
      ? drums
      : [for (var _ in drumRows) List<bool>.filled(16, false)];

  double get beatSec => 60 / bpm;
  double get barSec => beatSec * 4;
  double get lengthSec => barSec * 4 * repeats;

  Composition copyWith({
    int? bpm,
    int? keyRoot,
    bool? minor,
    List<int>? chords,
    ComposeInstrument? instrument,
    bool? bass,
    bool? melody,
    List<List<bool>>? drums,
    double? swing,
    int? repeats,
    String? style,
  }) =>
      Composition(
        bpm: bpm ?? this.bpm,
        keyRoot: keyRoot ?? this.keyRoot,
        minor: minor ?? this.minor,
        chords: chords ?? this.chords,
        instrument: instrument ?? this.instrument,
        bass: bass ?? this.bass,
        melody: melody ?? this.melody,
        drums: drums ?? this.drums,
        swing: swing ?? this.swing,
        repeats: repeats ?? this.repeats,
        style: style ?? this.style,
      );

  String toJson() => jsonEncode({
        'v': 1,
        'bpm': bpm,
        'key': keyRoot,
        'minor': minor,
        'chords': chords,
        'inst': instrument.name,
        'bass': bass,
        'mel': melody,
        'drums': [for (final r in grid) r.map((b) => b ? 1 : 0).join()],
        'swing': swing,
        'rep': repeats,
        'style': style,
      });

  static Composition fromJson(String? json) {
    if (json == null || json.isEmpty) return stylePreset('lofi');
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      return Composition(
        bpm: ((m['bpm'] as num?) ?? 90).toInt().clamp(60, 160),
        keyRoot: ((m['key'] as num?) ?? 9).toInt() % 12,
        minor: m['minor'] != false,
        chords: [for (final c in (m['chords'] as List? ?? const [0, 5, 2, 6])) (c as num).toInt().clamp(0, 6)],
        instrument: ComposeInstrument.values
            .firstWhere((i) => i.name == m['inst'], orElse: () => ComposeInstrument.keys),
        bass: m['bass'] != false,
        melody: m['mel'] != false,
        drums: [
          for (final r in (m['drums'] as List? ?? const []))
            [for (var i = 0; i < 16; i++) i < (r as String).length && r[i] == '1'],
        ],
        swing: ((m['swing'] as num?) ?? 0.2).toDouble().clamp(0.0, 0.5),
        repeats: ((m['rep'] as num?) ?? 4).toInt().clamp(1, 8),
        style: m['style'] as String? ?? 'custom',
      );
    } catch (_) {
      return stylePreset('lofi');
    }
  }
}

List<bool> _p(String s) => [for (var i = 0; i < 16; i++) s[i] == 'x'];

const List<(String, String)> composeStyles = [
  ('lofi', 'Lofi'),
  ('hiphop', 'Hip-hop'),
  ('pop', 'Pop'),
  ('house', 'House'),
  ('trap', 'Trap'),
  ('chill', 'Chill'),
];

/// A ready starting point for each style.
Composition stylePreset(String id) => switch (id) {
      'hiphop' => Composition(
          bpm: 90, keyRoot: 9, minor: true, chords: const [0, 3, 4, 0], instrument: ComposeInstrument.piano,
          swing: 0.18, style: id,
          drums: [_p('x......xx.x.....'), _p('....x.......x...'), _p('................'), _p('x.x.x.x.x.xxx.x.'), _p('................')]),
      'pop' => Composition(
          bpm: 118, keyRoot: 0, minor: false, chords: const [0, 4, 5, 3], instrument: ComposeInstrument.pluck,
          swing: 0, style: id,
          drums: [_p('x...x...x...x...'), _p('................'), _p('....x.......x...'), _p('..x...x...x...x.'), _p('................')]),
      'house' => Composition(
          bpm: 124, keyRoot: 9, minor: true, chords: const [0, 3, 6, 2], instrument: ComposeInstrument.piano,
          swing: 0, style: id,
          drums: [_p('x...x...x...x...'), _p('................'), _p('....x.......x...'), _p('x.xxx.xxx.xxx.xx'), _p('..x...x...x...x.')]),
      'trap' => Composition(
          bpm: 140, keyRoot: 4, minor: true, chords: const [0, 5, 3, 4], instrument: ComposeInstrument.pad,
          swing: 0, style: id,
          drums: [_p('x.....x...x.....'), _p('........x.......'), _p('................'), _p('xxxxxxxxxxxxxxxx'), _p('................')]),
      'chill' => Composition(
          bpm: 84, keyRoot: 2, minor: false, chords: const [0, 5, 3, 4], instrument: ComposeInstrument.pad,
          swing: 0.1, style: id,
          drums: [_p('x.......x.......'), _p('................'), _p('....x.......x...'), _p('..x...x...x...x.'), _p('................')]),
      _ => Composition(
          bpm: 80, keyRoot: 2, minor: true, chords: const [0, 3, 6, 2], instrument: ComposeInstrument.keys,
          swing: 0.28, style: 'lofi',
          drums: [_p('x.......x.x.....'), _p('....x.......x...'), _p('................'), _p('x.x.x.x.x.x.x.x.'), _p('................')]),
    };

const List<int> _major = [0, 2, 4, 5, 7, 9, 11];
const List<int> _minor = [0, 2, 3, 5, 7, 8, 10];

/// Chord symbol for scale degree [d] in the composition's key (e.g. "Am7").
String chordName(Composition c, int d) {
  final notes = chordNotes(c, d);
  final root = notes.first % 12;
  final third = (notes[1] - notes[0]) % 12;
  final fifth = (notes[2] - notes[0]) % 12;
  final seventh = (notes[3] - notes[0]) % 12;
  final q = switch ((third, fifth, seventh)) {
    (4, 7, 11) => 'maj7',
    (4, 7, 10) => '7',
    (3, 7, 10) => 'm7',
    (3, 6, 10) => 'm7b5',
    (3, 6, 9) => 'dim7',
    _ => '',
  };
  return '${noteNames[root]}$q';
}

/// MIDI notes of the diatonic seventh chord on degree [d] (around middle C).
List<int> chordNotes(Composition c, int d) {
  final scale = c.minor ? _minor : _major;
  int deg(int k) => scale[k % 7] + 12 * (k ~/ 7);
  final base = 48 + c.keyRoot;
  return [for (final k in [d, d + 2, d + 4, d + 6]) base + deg(k)];
}

/// Roman numeral label for degree [d] in this key (I, ii, … in major).
String degreeLabel(Composition c, int d) {
  const up = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];
  final notes = chordNotes(c, d);
  final minorThird = (notes[1] - notes[0]) % 12 == 3;
  return minorThird ? up[d].toLowerCase() : up[d];
}

// ----------------------------------------------------------------------------- synth

double _hz(num m) => 440 * math.pow(2, (m - 69) / 12).toDouble();

class _Buf {
  final Float32List l, r;
  _Buf(int n)
      : l = Float32List(n),
        r = Float32List(n);

  void add(Float32List x, int at, double gain, double pan) {
    final gl = gain * math.cos((pan + 1) * math.pi / 4) * 1.414;
    final gr = gain * math.sin((pan + 1) * math.pi / 4) * 1.414;
    for (var i = 0; i < x.length; i++) {
      final j = at + i;
      if (j < 0) continue;
      if (j >= l.length) break;
      l[j] += x[i] * gl;
      r[j] += x[i] * gr;
    }
  }
}

Float32List _keys(double f, double dur, double vel) {
  final n = ((dur + 1.0) * composeRate).round();
  final x = Float32List(n);
  final off = (dur * composeRate).round();
  for (var i = 0; i < n; i++) {
    final t = i / composeRate;
    var e = math.exp(-t * 1.0) * math.min(1, t / 0.004);
    if (i > off) e *= math.exp(-(i - off) / composeRate * 9);
    x[i] = (math.sin(2 * math.pi * f * t) +
            0.3 * math.sin(4 * math.pi * f * t) * math.exp(-t * 3) +
            0.08 * math.sin(2 * math.pi * 7.02 * f * t) * math.exp(-t * 14)) *
        e *
        vel;
  }
  return x;
}

Float32List _piano(double f, double dur, double vel) {
  final n = ((dur + 1.2) * composeRate).round();
  final x = Float32List(n);
  final off = (dur * composeRate).round();
  const amps = [1.0, 0.45, 0.22, 0.12, 0.07];
  for (var i = 0; i < n; i++) {
    final t = i / composeRate;
    var v = 0.0;
    for (var h = 0; h < amps.length; h++) {
      v += amps[h] * math.sin(2 * math.pi * (h + 1) * f * t) * math.exp(-t * (1.1 + h * 0.6));
    }
    var e = math.min(1.0, t / 0.003);
    if (i > off) e *= math.exp(-(i - off) / composeRate * 6);
    x[i] = v * e * vel;
  }
  return x;
}

Float32List _pad(double f, double dur) {
  final n = ((dur + 1.0) * composeRate).round();
  final x = Float32List(n);
  final off = (dur * composeRate).round();
  var lp = 0.0;
  final a = 1 - math.exp(-2 * math.pi * 1800 / composeRate);
  for (var i = 0; i < n; i++) {
    final t = i / composeRate;
    // Two detuned saws.
    final s1 = 2 * ((f * 1.004 * t) % 1) - 1;
    final s2 = 2 * ((f * 0.996 * t + 0.3) % 1) - 1;
    lp += a * ((s1 + s2) * 0.5 - lp);
    var e = math.min(1.0, t / 0.5);
    if (i > off) e *= math.exp(-(i - off) / composeRate * 3);
    x[i] = lp * e * 0.6;
  }
  return x;
}

Float32List _pluck(double f, double dur, math.Random g) {
  final period = math.max(2, (composeRate / f).round());
  final n = ((dur + 0.6) * composeRate).round();
  final y = Float32List(n + period + 2);
  var lp = 0.0;
  for (var i = 1; i <= period; i++) {
    lp += 0.5 * ((g.nextDouble() * 2 - 1) - lp);
    y[i] = lp;
  }
  for (var i = period + 1; i < n; i++) {
    y[i] = 0.996 * 0.5 * (y[i - period] + y[i - period - 1]);
  }
  final off = (dur * composeRate).round();
  final x = Float32List(n);
  for (var i = 0; i < n; i++) {
    x[i] = y[i + 1] * (i > off ? math.exp(-(i - off) / composeRate * 12) : 1);
  }
  return x;
}

Float32List _bass(double f, double dur) {
  final n = ((dur + 0.12) * composeRate).round();
  final x = Float32List(n);
  final off = (dur * composeRate).round();
  for (var i = 0; i < n; i++) {
    final t = i / composeRate;
    var e = math.min(1.0, t / 0.006);
    if (i > off) e *= math.exp(-(i - off) / composeRate * 30);
    final v = math.sin(2 * math.pi * f * t) + 0.25 * math.sin(4 * math.pi * f * t);
    x[i] = _tanh(1.4 * v * e) * 0.8;
  }
  return x;
}

double _tanh(double v) {
  final e = math.exp(2 * v);
  return (e - 1) / (e + 1);
}

Map<String, Float32List> _drumKit(math.Random g) {
  Float32List make(double seconds, double Function(double t, double noise) fn) {
    final n = (seconds * composeRate).round();
    final x = Float32List(n);
    for (var i = 0; i < n; i++) {
      x[i] = fn(i / composeRate, g.nextDouble() * 2 - 1);
    }
    return x;
  }

  // Kick: pitch-swept sine.
  var ph = 0.0;
  final kick = make(0.45, (t, _) {
    final f = 46 + 110 * math.exp(-t * 32);
    ph += 2 * math.pi * f / composeRate;
    return _tanh(1.6 * math.sin(ph) * math.exp(-t * 7));
  });
  // Noise-based parts get a crude one-pole high/low-pass inline.
  var hpPrev = 0.0, hpOut = 0.0;
  double hp(double v, double a) {
    hpOut = a * (hpOut + v - hpPrev);
    hpPrev = v;
    return hpOut;
  }

  final snare = make(0.3, (t, n) => (hp(n, 0.7) * 0.8 + 0.6 * math.sin(2 * math.pi * 188 * t) * math.exp(-t * 10)) * math.exp(-t * 17));
  hpPrev = hpOut = 0;
  final clap = make(0.35, (t, n) {
    final burst = (t < 0.01 || (t > 0.011 && t < 0.021)) ? 1.0 : 0.0;
    return hp(n, 0.85) * (burst * 0.8 + math.exp(-(t - 0.022).abs() * 14) * 0.7) * 0.7;
  });
  hpPrev = hpOut = 0;
  final hat = make(0.07, (t, n) => hp(n, 0.95) * math.exp(-t * 70) * 0.35);
  hpPrev = hpOut = 0;
  final open = make(0.3, (t, n) => hp(n, 0.95) * math.exp(-t * 11) * 0.3);
  return {'kick': kick, 'snare': snare, 'clap': clap, 'hat': hat, 'open': open};
}

const Map<String, double> _drumGain = {'kick': 0.95, 'snare': 0.6, 'clap': 0.55, 'hat': 0.5, 'open': 0.4};
const Map<String, double> _drumPan = {'kick': 0, 'snare': 0.05, 'clap': -0.05, 'hat': 0.25, 'open': 0.3};

/// Interleaved stereo samples (-1..1) of [c], with a short ring-out at the end.
Float32List renderComposition(Composition c) {
  final g = math.Random(1234);
  final total = ((c.lengthSec + 1.5) * composeRate).round();
  final buf = _Buf(total);
  final step = c.barSec / 16;
  int at(int bar, int s) =>
      ((bar * c.barSec + s * step + (s.isOdd ? c.swing * step : 0)) * composeRate).round();

  final kit = _drumKit(g);
  final grid = c.grid;
  final bars = 4 * c.repeats;
  final scale = c.minor ? _minor : _major;

  for (var bar = 0; bar < bars; bar++) {
    final degree = c.chords[bar % c.chords.length];
    final notes = chordNotes(c, degree);
    final t0 = (bar * c.barSec * composeRate).round();

    // Chords.
    switch (c.instrument) {
      case ComposeInstrument.pad:
        for (final m in notes) {
          buf.add(_pad(_hz(m), c.barSec), t0, 0.11, 0);
        }
      case ComposeInstrument.pluck:
        for (final s in const [0, 3, 6, 10, 12]) {
          for (var k = 0; k < notes.length; k++) {
            buf.add(_pluck(_hz(notes[k] + 12), step * 2, g), at(bar, s) + k * 90, 0.12, -0.2 + k * 0.13);
          }
        }
      case ComposeInstrument.piano:
        for (final s in const [0, 6, 10]) {
          for (final m in notes) {
            buf.add(_piano(_hz(m + 12), step * 3, 0.55), at(bar, s), 0.12, 0.1);
          }
        }
      case ComposeInstrument.keys:
        for (var k = 0; k < notes.length; k++) {
          buf.add(_keys(_hz(notes[k]), c.barSec * 0.95, 0.6), t0 + k * 200, 0.2, -0.3 + k * 0.2);
        }
    }

    // Bass on the root, twice a bar.
    if (c.bass) {
      for (final s in const [0, 8]) {
        buf.add(_bass(_hz(notes.first - 12), step * 7), at(bar, s), 0.5, 0);
      }
    }

    // Drums (first bar of the very first loop stays light, as an intro).
    for (var r = 0; r < drumRows.length; r++) {
      final name = drumRows[r];
      if (bar == 0 && name != 'hat' && name != 'open' && bars > 4) continue;
      for (var s = 0; s < 16; s++) {
        if (grid[r][s]) buf.add(kit[name]!, at(bar, s), _drumGain[name]!, _drumPan[name]!);
      }
    }

    // A simple melody on the second half of every loop: chord tones and
    // scale steps, the same phrase each time it comes round.
    if (c.melody && bar % 4 >= 2) {
      final mg = math.Random(bar % 4 * 31 + degree);
      for (var s = 0; s < 16; s += 2) {
        if (mg.nextDouble() < 0.45) continue;
        final k = degree + const [0, 2, 4, 7][mg.nextInt(4)] + (mg.nextBool() ? 1 : 0);
        final m = 60 + c.keyRoot + scale[k % 7] + 12 * (k ~/ 7);
        buf.add(_keys(_hz(m + 12), step * 1.5, 0.5), at(bar, s), 0.09, 0.25);
      }
    }
  }

  // Master: gentle saturation, then peak-normalise to 0.8 (headroom for reverb/echo in the editor).
  var peak = 1e-9;
  final out = Float32List(total * 2);
  for (var i = 0; i < total; i++) {
    final l = _tanh(buf.l[i] * 1.1), r = _tanh(buf.r[i] * 1.1);
    out[i * 2] = l;
    out[i * 2 + 1] = r;
    peak = math.max(peak, math.max(l.abs(), r.abs()));
  }
  final gain = 0.8 / peak;
  for (var i = 0; i < out.length; i++) {
    out[i] *= gain;
  }
  // Short fade at the very end so the ring-out never clicks.
  final fade = (0.5 * composeRate).round();
  for (var i = 0; i < fade; i++) {
    final k = i / fade;
    out[(total - 1 - i) * 2] *= k;
    out[(total - 1 - i) * 2 + 1] *= k;
  }
  return out;
}
