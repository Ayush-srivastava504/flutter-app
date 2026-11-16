import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/audio/audio_edit.dart';
import 'package:video_editor_app/audio/composer.dart';
import 'package:video_editor_app/audio/reverb_ir.dart';
import 'package:video_editor_app/audio/wav.dart';

/// Audio Studio (v13): the edit model and its FFmpeg graph, reverb impulses,
/// WAV helpers, and the composer's synth.
void main() {
  group('AudioEdit', () {
    test('JSON round-trips; broken JSON is a neutral edit', () {
      const e = AudioEdit(trimStartMs: 1200, trimEndMs: 9000, gainDb: -3, pitch: 4, reverse: true, reverbSize: 0.6,
          reverbMix: 0.4, echoMs: 250, chorus: 0.3, normalize: true, preset: 'cave');
      expect(AudioEdit.fromJson(e.toJson()), e);
      expect(AudioEdit.fromJson('{nope'), const AudioEdit());
      expect(AudioEdit.fromJson(null), const AudioEdit());
    });

    test('output length follows trim and speed', () {
      expect(const AudioEdit().outputMs(10000), 10000);
      expect(const AudioEdit(trimStartMs: 2000, trimEndMs: 8000, speed: 2).outputMs(10000), 3000);
      expect(const AudioEdit(trimEndMs: 99999).outputMs(4000), 4000, reason: 'trim end clamped to the source');
    });

    test('a neutral edit is just trim, format and the safety limiter', () {
      expect(
        audioEditGraph(const AudioEdit(), 5000),
        '[0:a]atrim=start=0.000:end=5.000,asetpts=PTS-STARTPTS,'
        'aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[pre];'
        '[pre]aresample=44100,alimiter=limit=0.97[out]',
      );
    });

    test('pitch shifts without changing tempo: resample up, tempo back down', () {
      final g = audioEditGraph(const AudioEdit(pitch: 12), 5000);
      expect(g, contains('asetrate=88200,aresample=44100,atempo=0.500'));
      final both = audioEditGraph(const AudioEdit(pitch: 12, speed: 2), 5000);
      expect(both, isNot(contains('atempo')), reason: 'octave up at double speed = plain resample');
    });

    test('reverb: unit-energy IR without FFmpeg normalisation, equal-power mix', () {
      final g = audioEditGraph(const AudioEdit(reverbSize: 0.5, reverbMix: 0.5), 5000);
      expect(g, contains('[wsrc][ir]afir=irnorm=-1:maxir=6[wet]'));
      expect(g, contains("weights='0.707 0.530'"));
      expect(() => buildAudioRenderArgs(src: '/a', sourceMs: 1, edit: const AudioEdit(reverbSize: 1), out: '/o.m4a'),
          throwsArgumentError);
      final args = buildAudioRenderArgs(
          src: '/a.mp3', sourceMs: 1000, edit: const AudioEdit(reverbSize: 1), out: '/o.mp3', format: AudioFormat.mp3, irPath: '/ir.wav');
      expect(args, containsAllInOrder(['-i', '/a.mp3', '-i', '/ir.wav']));
      expect(args, containsAllInOrder(['-c:a', 'libmp3lame']));
    });

    test('every option is passed by name (FACTS B-06)', () {
      const all = AudioEdit(denoise: 0.5, lowCutHz: 80, highCutHz: 9000, bassDb: 3, midDb: -2, trebleDb: 2, compress: 0.5,
          chorus: 0.5, echoMs: 300, width: 0.5, fadeInMs: 500, fadeOutMs: 500, gainDb: 2, normalize: true);
      final g = audioEditGraph(all, 10000);
      for (final f in ['highpass=f=', 'lowpass=f=', 'afftdn=nr=', 'bass=g=', 'equalizer=f=', 'treble=g=',
        'acompressor=threshold=', 'chorus=in_gain=', 'aecho=in_gain=', 'extrastereo=m=', 'volume=', 'afade=t=in', 'loudnorm=I=-14']) {
        expect(g, contains(f), reason: f);
      }
      expect(g, contains('afade=t=out:st=9.500:d=0.500'));
    });

    test('voice presets reset previous effects but keep trim, fades and gain', () {
      const start = AudioEdit(trimStartMs: 500, fadeInMs: 200, gainDb: -2, pitch: 7, reverbSize: 0.9, chorus: 1);
      final r = applyVoicePreset(start, 'radio');
      expect(r.trimStartMs, 500);
      expect(r.fadeInMs, 200);
      expect(r.pitch, 0, reason: 'chipmunk pitch from before is gone');
      expect(r.reverbSize, 0);
      expect(r.lowCutHz, greaterThan(0));
      expect(r.preset, 'radio');
      for (final p in voicePresets) {
        expect(applyVoicePreset(const AudioEdit(), p.id).preset, p.id);
      }
    });
  });

  group('reverb impulse', () {
    test('length follows room size, each channel has unit energy, channels differ', () {
      final ir = reverbImpulse(0.5, 0.5);
      expect(ir.length ~/ 2, (reverbSeconds(0.5) * 44100).round());
      for (final ch in [0, 1]) {
        var e = 0.0;
        for (var i = ch; i < ir.length; i += 2) {
          e += ir[i] * ir[i];
        }
        expect(e, closeTo(1, 1e-3));
      }
      expect(ir[20000], isNot(ir[20001]), reason: 'decorrelated stereo');
      expect(reverbImpulse(0.5, 0.5)[1234], ir[1234], reason: 'deterministic');
    });

    test('the tail decays', () {
      final ir = reverbImpulse(0.4, 0.5);
      double rms(int from, int to) {
        var s = 0.0;
        for (var i = from; i < to; i++) {
          s += ir[i * 2] * ir[i * 2];
        }
        return math.sqrt(s / (to - from));
      }

      final n = ir.length ~/ 2;
      expect(rms(n * 3 ~/ 4, n), lessThan(rms(n ~/ 8, n ~/ 4) / 10));
    });
  });

  group('wav', () {
    test('16-bit header and samples', () {
      final b = encodeWav16(Float32List.fromList([0, 1, -1, 0.5]), channels: 2, sampleRate: 8000);
      final d = ByteData.sublistView(b);
      expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF');
      expect(d.getUint16(22, Endian.little), 2);
      expect(d.getUint32(24, Endian.little), 8000);
      expect(d.getUint32(40, Endian.little), 8);
      expect(d.getInt16(46, Endian.little), 32767);
      expect(d.getInt16(48, Endian.little), -32767);
    });

    test('float WAV keeps exact values', () {
      final b = encodeWavFloat32(Float32List.fromList([0.001234, -0.5]));
      expect(ByteData.sublistView(b).getUint16(20, Endian.little), 3);
      expect(ByteData.sublistView(b).getFloat32(44, Endian.little), closeTo(0.001234, 1e-9));
    });

    test('waveform peaks', () {
      final pcm = Int16List.fromList([0, 100, -16384, 0, 32767, 5]);
      expect(peaksFromPcm16(pcm.buffer.asUint8List(), 3), [100 / 32768, 0.5, 32767 / 32768]);
    });
  });

  group('composer', () {
    test('chords are named correctly in major and minor keys', () {
      const cMajor = Composition(keyRoot: 0, minor: false);
      expect([for (var d = 0; d < 7; d++) chordName(cMajor, d)],
          ['Cmaj7', 'Dm7', 'Em7', 'Fmaj7', 'G7', 'Am7', 'Bm7b5']);
      expect([for (var d = 0; d < 7; d++) degreeLabel(cMajor, d)], ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii']);
      const aMinor = Composition(keyRoot: 9, minor: true);
      expect(chordName(aMinor, 0), 'Am7');
      expect(chordName(aMinor, 2), 'Cmaj7');
    });

    test('JSON round-trips, styles have full grids', () {
      for (final (id, _) in composeStyles) {
        final c = stylePreset(id);
        expect(c.grid.length, drumRows.length);
        expect(c.grid.every((r) => r.length == 16), isTrue);
        expect(Composition.fromJson(c.toJson()).toJson(), c.toJson(), reason: id);
      }
    });

    test('renders the right length, audibly, within full scale, the same every time', () {
      final c = stylePreset('lofi').copyWith(repeats: 1);
      final a = renderComposition(c);
      expect(a.length ~/ 2, ((c.lengthSec + 1.5) * composeRate).round());
      var peak = 0.0, energy = 0.0;
      for (final v in a) {
        peak = math.max(peak, v.abs());
        energy += v * v;
      }
      expect(peak, inInclusiveRange(0.5, 0.9001));
      expect(math.sqrt(energy / a.length), greaterThan(0.03));
      expect(renderComposition(c)[54321], a[54321]);
    });
  });
}
