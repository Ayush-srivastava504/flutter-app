import 'dart:math' as math;
import 'dart:typed_data';

/// 16-bit PCM WAV bytes from interleaved float samples (-1..1).
Uint8List encodeWav16(Float32List interleaved, {int channels = 2, int sampleRate = 44100}) {
  final frames = interleaved.length ~/ channels;
  final dataBytes = frames * channels * 2;
  final b = ByteData(44 + dataBytes);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  b.setUint32(4, 36 + dataBytes, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, channels, Endian.little);
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * channels * 2, Endian.little);
  b.setUint16(32, channels * 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  str(36, 'data');
  b.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < frames * channels; i++) {
    final v = (interleaved[i].clamp(-1.0, 1.0) * 32767).round();
    b.setInt16(44 + i * 2, v, Endian.little);
  }
  return b.buffer.asUint8List();
}

/// 32-bit float WAV bytes (exact values — used for reverb impulses, whose
/// unit-energy scaling must survive).
Uint8List encodeWavFloat32(Float32List interleaved, {int channels = 2, int sampleRate = 44100}) {
  final frames = interleaved.length ~/ channels;
  final dataBytes = frames * channels * 4;
  final b = ByteData(44 + dataBytes);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  b.setUint32(4, 36 + dataBytes, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 3, Endian.little); // IEEE float
  b.setUint16(22, channels, Endian.little);
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * channels * 4, Endian.little);
  b.setUint16(32, channels * 4, Endian.little);
  b.setUint16(34, 32, Endian.little);
  str(36, 'data');
  b.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < frames * channels; i++) {
    b.setFloat32(44 + i * 4, interleaved[i], Endian.little);
  }
  return b.buffer.asUint8List();
}

/// Peak envelope of mono 16-bit PCM bytes (as FFmpeg `-f s16le` writes),
/// reduced to [buckets] values in 0..1 — the waveform drawing.
List<double> peaksFromPcm16(Uint8List bytes, int buckets) {
  final samples = bytes.buffer.asInt16List(bytes.offsetInBytes, bytes.lengthInBytes ~/ 2);
  if (samples.isEmpty || buckets <= 0) return const [];
  final per = math.max(1, samples.length ~/ buckets);
  final out = <double>[];
  for (var i = 0; i < samples.length; i += per) {
    var peak = 0;
    final end = math.min(samples.length, i + per);
    for (var j = i; j < end; j++) {
      final a = samples[j].abs();
      if (a > peak) peak = a;
    }
    out.add(peak / 32768);
  }
  return out;
}
