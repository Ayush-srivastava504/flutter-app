/// Audio Studio: one edit = plain data (`AudioProjects.editJson`), rendered
/// by FFmpeg as one filter graph ([buildAudioRenderArgs]). Previews are real
/// renders of the same graph, so what you hear is what you save.
///
/// Every filter used here was found in the phone's libavfilter.so
/// (2026-11-11) and the graphs were run through FFmpeg 7.1 on desktop.
/// Options are always named (FACTS B-06).
library audio_edit;

import 'dart:convert';
import 'dart:math' as math;

import '../export/export_command_builder.dart' show atempoChain, speechEnhanceFilters;

class AudioEdit {
  // --- Edit
  final int trimStartMs;

  /// Null = to the end of the source.
  final int? trimEndMs;
  final int fadeInMs;
  final int fadeOutMs;

  /// -24..+12 dB.
  final double gainDb;

  /// 0.5..2 (tempo, pitch kept).
  final double speed;

  /// -12..+12 semitones (tempo kept).
  final double pitch;
  final bool reverse;

  // --- Clean up
  final double denoise; // 0..1
  final bool enhanceSpeech;
  final double lowCutHz; // 0 = off
  final double highCutHz; // 0 = off

  // --- Tone
  final double bassDb; // -12..12
  final double midDb;
  final double trebleDb;
  final double compress; // 0..1

  // --- Space
  final double reverbSize; // 0 = off .. 1 = cathedral
  final double reverbMix; // 0..1 wet
  final double reverbTone; // 0 dark .. 1 bright
  final int echoMs; // 0 = off
  final double echoFeedback; // 0..0.9
  final double chorus; // 0..1
  final double width; // 0..1 extra stereo

  // --- Finish
  final bool normalize;

  /// Last voice preset applied, for highlighting only.
  final String preset;

  const AudioEdit({
    this.trimStartMs = 0,
    this.trimEndMs,
    this.fadeInMs = 0,
    this.fadeOutMs = 0,
    this.gainDb = 0,
    this.speed = 1,
    this.pitch = 0,
    this.reverse = false,
    this.denoise = 0,
    this.enhanceSpeech = false,
    this.lowCutHz = 0,
    this.highCutHz = 0,
    this.bassDb = 0,
    this.midDb = 0,
    this.trebleDb = 0,
    this.compress = 0,
    this.reverbSize = 0,
    this.reverbMix = 0.3,
    this.reverbTone = 0.5,
    this.echoMs = 0,
    this.echoFeedback = 0.35,
    this.chorus = 0,
    this.width = 0,
    this.normalize = false,
    this.preset = 'none',
  });

  bool get hasReverb => reverbSize > 0.001 && reverbMix > 0.001;

  /// Length of the result for a source [sourceMs] long.
  int outputMs(int sourceMs) {
    final end = (trimEndMs ?? sourceMs).clamp(0, sourceMs);
    final start = trimStartMs.clamp(0, end);
    return ((end - start) / (speed <= 0 ? 1 : speed)).round();
  }

  Map<String, Object?> toMap() => {
        'v': 1,
        'ts': trimStartMs,
        'te': trimEndMs,
        'fi': fadeInMs,
        'fo': fadeOutMs,
        'g': gainDb,
        'sp': speed,
        'pi': pitch,
        'rv': reverse,
        'dn': denoise,
        'es': enhanceSpeech,
        'lc': lowCutHz,
        'hc': highCutHz,
        'b': bassDb,
        'm': midDb,
        't': trebleDb,
        'c': compress,
        'rs': reverbSize,
        'rm': reverbMix,
        'rt': reverbTone,
        'em': echoMs,
        'ef': echoFeedback,
        'ch': chorus,
        'w': width,
        'n': normalize,
        'p': preset,
      };

  String toJson() => jsonEncode(toMap());

  /// Unknown or broken JSON gives a neutral edit.
  static AudioEdit fromJson(String? json) {
    if (json == null || json.isEmpty) return const AudioEdit();
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      double d(String k, double def, double lo, double hi) => ((m[k] as num?)?.toDouble() ?? def).clamp(lo, hi);
      int i(String k, int def) => (m[k] as num?)?.toInt() ?? def;
      return AudioEdit(
        trimStartMs: math.max(0, i('ts', 0)),
        trimEndMs: (m['te'] as num?)?.toInt(),
        fadeInMs: math.max(0, i('fi', 0)),
        fadeOutMs: math.max(0, i('fo', 0)),
        gainDb: d('g', 0, -24, 12),
        speed: d('sp', 1, 0.5, 2),
        pitch: d('pi', 0, -12, 12),
        reverse: m['rv'] == true,
        denoise: d('dn', 0, 0, 1),
        enhanceSpeech: m['es'] == true,
        lowCutHz: d('lc', 0, 0, 500),
        highCutHz: d('hc', 0, 0, 20000),
        bassDb: d('b', 0, -12, 12),
        midDb: d('m', 0, -12, 12),
        trebleDb: d('t', 0, -12, 12),
        compress: d('c', 0, 0, 1),
        reverbSize: d('rs', 0, 0, 1),
        reverbMix: d('rm', 0.3, 0, 1),
        reverbTone: d('rt', 0.5, 0, 1),
        echoMs: i('em', 0).clamp(0, 1500),
        echoFeedback: d('ef', 0.35, 0, 0.9),
        chorus: d('ch', 0, 0, 1),
        width: d('w', 0, 0, 1),
        normalize: m['n'] == true,
        preset: m['p'] as String? ?? 'none',
      );
    } catch (_) {
      return const AudioEdit();
    }
  }

  AudioEdit copyWith({
    int? trimStartMs,
    int? trimEndMs,
    bool clearTrimEnd = false,
    int? fadeInMs,
    int? fadeOutMs,
    double? gainDb,
    double? speed,
    double? pitch,
    bool? reverse,
    double? denoise,
    bool? enhanceSpeech,
    double? lowCutHz,
    double? highCutHz,
    double? bassDb,
    double? midDb,
    double? trebleDb,
    double? compress,
    double? reverbSize,
    double? reverbMix,
    double? reverbTone,
    int? echoMs,
    double? echoFeedback,
    double? chorus,
    double? width,
    bool? normalize,
    String? preset,
  }) =>
      AudioEdit(
        trimStartMs: trimStartMs ?? this.trimStartMs,
        trimEndMs: clearTrimEnd ? null : (trimEndMs ?? this.trimEndMs),
        fadeInMs: fadeInMs ?? this.fadeInMs,
        fadeOutMs: fadeOutMs ?? this.fadeOutMs,
        gainDb: gainDb ?? this.gainDb,
        speed: speed ?? this.speed,
        pitch: pitch ?? this.pitch,
        reverse: reverse ?? this.reverse,
        denoise: denoise ?? this.denoise,
        enhanceSpeech: enhanceSpeech ?? this.enhanceSpeech,
        lowCutHz: lowCutHz ?? this.lowCutHz,
        highCutHz: highCutHz ?? this.highCutHz,
        bassDb: bassDb ?? this.bassDb,
        midDb: midDb ?? this.midDb,
        trebleDb: trebleDb ?? this.trebleDb,
        compress: compress ?? this.compress,
        reverbSize: reverbSize ?? this.reverbSize,
        reverbMix: reverbMix ?? this.reverbMix,
        reverbTone: reverbTone ?? this.reverbTone,
        echoMs: echoMs ?? this.echoMs,
        echoFeedback: echoFeedback ?? this.echoFeedback,
        chorus: chorus ?? this.chorus,
        width: width ?? this.width,
        normalize: normalize ?? this.normalize,
        preset: preset ?? this.preset,
      );

  @override
  bool operator ==(Object other) => other is AudioEdit && other.toJson() == toJson();

  @override
  int get hashCode => toJson().hashCode;
}

// ----------------------------------------------------------------------------- presets

class VoicePreset {
  final String id;
  final String label;
  final String hint;
  const VoicePreset(this.id, this.label, this.hint);
}

const List<VoicePreset> voicePresets = [
  VoicePreset('none', 'Original', 'No character effect'),
  VoicePreset('podcast', 'Podcast', 'Clean, warm, even voice'),
  VoicePreset('radio', 'Radio', 'Thin AM-radio band'),
  VoicePreset('telephone', 'Phone call', 'Narrow phone line'),
  VoicePreset('megaphone', 'Megaphone', 'Loud and boxy'),
  VoicePreset('underwater', 'Underwater', 'Muffled and wobbly'),
  VoicePreset('stadium', 'Stadium', 'Huge echoing space'),
  VoicePreset('cave', 'Cave', 'Dark rock-wall echo'),
  VoicePreset('chipmunk', 'Chipmunk', 'High and squeaky'),
  VoicePreset('deep', 'Deep voice', 'Low and heavy'),
  VoicePreset('dream', 'Dreamy', 'Soft, wide and washed'),
  VoicePreset('lofi', 'Lo-fi', 'Old tape, rolled-off highs'),
];

/// [edit] with a character preset: every "effect" field is reset first, then
/// the preset's own values set. Trim, fades, gain, speed and normalize stay.
AudioEdit applyVoicePreset(AudioEdit edit, String id) {
  final base = AudioEdit(
    trimStartMs: edit.trimStartMs,
    trimEndMs: edit.trimEndMs,
    fadeInMs: edit.fadeInMs,
    fadeOutMs: edit.fadeOutMs,
    gainDb: edit.gainDb,
    speed: edit.speed,
    reverse: edit.reverse,
    normalize: edit.normalize,
    preset: id,
  );
  return switch (id) {
    'podcast' => base.copyWith(
        enhanceSpeech: true, denoise: 0.4, bassDb: 2, compress: 0.6, reverbSize: 0.12, reverbMix: 0.08, normalize: true),
    'radio' => base.copyWith(lowCutHz: 450, highCutHz: 3800, midDb: 6, compress: 0.8),
    'telephone' => base.copyWith(lowCutHz: 320, highCutHz: 3200, midDb: 4, compress: 0.5),
    'megaphone' => base.copyWith(lowCutHz: 600, highCutHz: 4500, midDb: 10, compress: 1, gainDb: edit.gainDb + 2),
    'underwater' => base.copyWith(highCutHz: 700, bassDb: 6, chorus: 0.9, reverbSize: 0.4, reverbMix: 0.35, reverbTone: 0),
    'stadium' => base.copyWith(reverbSize: 0.9, reverbMix: 0.45, reverbTone: 0.6, echoMs: 380, echoFeedback: 0.3),
    'cave' => base.copyWith(reverbSize: 0.75, reverbMix: 0.5, reverbTone: 0.1, echoMs: 220, echoFeedback: 0.45, bassDb: 3),
    'chipmunk' => base.copyWith(pitch: 7),
    'deep' => base.copyWith(pitch: -5, bassDb: 3),
    'dream' => base.copyWith(chorus: 0.6, width: 0.8, reverbSize: 0.7, reverbMix: 0.5, reverbTone: 0.8, highCutHz: 9000),
    'lofi' => base.copyWith(lowCutHz: 120, highCutHz: 4500, compress: 0.7, chorus: 0.2),
    _ => base,
  };
}

// ----------------------------------------------------------------------------- the graph

String _n(double v) => v.toStringAsFixed(3);
String _s(num ms) => (ms / 1000).toStringAsFixed(3);

/// Output sample rate of every render.
const int audioStudioRate = 44100;

/// Reverb impulse length for [AudioEdit.reverbSize] (see `reverb_ir.dart`).
double reverbSeconds(double size) => 0.3 + 4.2 * size.clamp(0.0, 1.0);

/// The filter graph from input `[0:a]` (and, with reverb, the impulse
/// response on `[1:a]`) to `[out]`. [sourceMs] is the source length.
String audioEditGraph(AudioEdit e, int sourceMs) {
  final end = (e.trimEndMs ?? sourceMs).clamp(0, sourceMs);
  final start = e.trimStartMs.clamp(0, end);
  final outMs = e.outputMs(sourceMs);
  final chain = <String>[
    'atrim=start=${_s(start)}:end=${_s(end)}',
    'asetpts=PTS-STARTPTS',
    'aformat=sample_fmts=fltp:sample_rates=$audioStudioRate:channel_layouts=stereo',
    if (e.reverse) 'areverse',
  ];

  // Pitch without changing tempo: resample to shift pitch (which also
  // changes speed by r), then atempo by speed / r to land on the wanted tempo.
  final r = math.pow(2, e.pitch / 12).toDouble();
  if (e.pitch.abs() > 0.01) {
    chain.addAll(['asetrate=${(audioStudioRate * r).round()}', 'aresample=$audioStudioRate']);
  }
  final tempo = e.speed / (e.pitch.abs() > 0.01 ? r : 1);
  if ((tempo - 1).abs() > 0.001) chain.addAll(atempoChain(tempo));

  if (e.lowCutHz > 0) chain.add('highpass=f=${e.lowCutHz.round()}');
  if (e.highCutHz > 0) chain.add('lowpass=f=${e.highCutHz.round()}');
  if (e.denoise > 0.001) chain.add('afftdn=nr=${(6 + 24 * e.denoise).toStringAsFixed(1)}:nf=-40');
  if (e.enhanceSpeech) chain.addAll(speechEnhanceFilters);
  if (e.bassDb.abs() > 0.05) chain.add('bass=g=${_n(e.bassDb)}:f=110');
  if (e.midDb.abs() > 0.05) chain.add('equalizer=f=1200:t=q:w=0.9:g=${_n(e.midDb)}');
  if (e.trebleDb.abs() > 0.05) chain.add('treble=g=${_n(e.trebleDb)}:f=4000');
  if (e.compress > 0.01) {
    chain.add('acompressor=threshold=${_n(0.25 - 0.2 * e.compress)}:ratio=${_n(2 + 6 * e.compress)}'
        ':attack=10:release=150:makeup=${_n(1 + 1.5 * e.compress)}');
  }
  if (e.chorus > 0.01) {
    final g = e.chorus;
    chain.add('chorus=in_gain=0.7:out_gain=0.9:delays=${(40 + 20 * g).round()}|${(55 + 25 * g).round()}'
        ':decays=${_n(0.25 + 0.3 * g)}|${_n(0.2 + 0.25 * g)}:speeds=0.3|0.45:depths=${_n(1 + 2 * g)}|${_n(1.4 + 2 * g)}');
  }
  if (e.echoMs > 0) {
    final d = e.echoMs;
    final f = e.echoFeedback;
    chain.add('aecho=in_gain=0.8:out_gain=0.85:delays=$d|${d * 2}|${d * 3}'
        ':decays=${_n(f)}|${_n(f * f)}|${_n(f * f * f)}');
  }

  final parts = <String>[];
  var label = 'pre';
  parts.add('[0:a]${chain.join(',')}[$label]');

  if (e.hasReverb) {
    // Convolution reverb: the impulse response (input 1) is generated by the
    // app with unit energy, so FFmpeg's own IR normalisation is switched off.
    final m = e.reverbMix.clamp(0.0, 1.0);
    parts
      ..add('[1:a]aformat=sample_fmts=fltp:sample_rates=$audioStudioRate:channel_layouts=stereo[ir]')
      ..add('[$label]asplit=2[dry][wsrc]')
      ..add('[wsrc][ir]afir=irnorm=-1:maxir=6[wet]')
      // Equal-power crossfade; the wet path measured 2.5 dB hotter than dry
      // (unit-energy IR + tail), hence 0.75. Loudness stays flat across the
      // whole Mix range (measured: -32.0 LUFS at 0.2, 0.5, 0.8 and 1.0).
      ..add("[dry][wet]amix=inputs=2:weights='${_n(math.cos(m * math.pi / 2))} ${_n(0.75 * math.sin(m * math.pi / 2))}'"
          ':normalize=0:duration=first[rv]');
    label = 'rv';
  }

  final tail = <String>[
    if (e.width > 0.01) 'extrastereo=m=${_n(1 + 1.5 * e.width)}',
    if (e.gainDb.abs() > 0.01) 'volume=${_n(e.gainDb)}dB',
    if (e.fadeInMs > 0) 'afade=t=in:st=0:d=${_s(math.min(e.fadeInMs, outMs))}',
    if (e.fadeOutMs > 0)
      'afade=t=out:st=${_s(math.max(0, outMs - e.fadeOutMs))}:d=${_s(math.min(e.fadeOutMs, outMs))}',
    if (e.normalize) 'loudnorm=I=-14:TP=-1.5:LRA=11',
    'aresample=$audioStudioRate',
    'alimiter=limit=0.97',
  ];
  parts.add('[$label]${tail.join(',')}[out]');
  return parts.join(';');
}

enum AudioFormat {
  m4a('M4A (AAC)', 'm4a'),
  mp3('MP3', 'mp3'),
  wav('WAV (lossless)', 'wav');

  final String label;
  final String ext;
  const AudioFormat(this.label, this.ext);
}

/// Full FFmpeg arguments: render [src] with [edit] to [out]. [irPath] is
/// required when the edit has reverb.
List<String> buildAudioRenderArgs({
  required String src,
  required int sourceMs,
  required AudioEdit edit,
  required String out,
  AudioFormat format = AudioFormat.m4a,
  String? irPath,
}) {
  if (edit.hasReverb && irPath == null) throw ArgumentError('reverb needs an impulse response file');
  return [
    '-y',
    '-i',
    src,
    if (edit.hasReverb) ...['-i', irPath!],
    '-filter_complex',
    audioEditGraph(edit, sourceMs),
    '-map',
    '[out]',
    '-vn',
    ...switch (format) {
      AudioFormat.m4a => ['-c:a', 'aac', '-b:a', '192k'],
      AudioFormat.mp3 => ['-c:a', 'libmp3lame', '-q:a', '2'],
      AudioFormat.wav => ['-c:a', 'pcm_s16le'],
    },
    '-ar',
    '$audioStudioRate',
    out,
  ];
}
