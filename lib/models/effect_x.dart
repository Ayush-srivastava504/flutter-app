/// Effects (`Clips.effect`, schema v11): one per clip, on top of its look.
///
/// Two kinds, both plain data so the preview and the export can't disagree
/// about what an effect *is*:
///
///  * **Motion** ([MotionKind]) — a per-frame zoom / pan / shake / flash.
///    [motionAt] is the single formula: the preview turns it into a
///    `Transform` (editor `_MotionLayer`); the export turns the same
///    formula into FFmpeg expressions ([motionFilters]):
///    `scale=…:eval=frame` → `crop` back to the frame size (verified with
///    FFmpeg 7.1 on desktop, 2026-11-11).
///  * **Stylise** — a [LookSpec] (chroma split, grain, pixelate, posterize,
///    negate, sharpen, vignette) drawn by the same shader / FFmpeg steps as
///    looks, as a second pass after the clip's look.
///
/// Order on both sides: look → stylise effect → motion → (export) fades.
/// Pure Dart — no `dart:ui` — so it is unit-tested directly.
library effect_x;

import 'dart:math' as math;

import 'look_x.dart';

enum EffectKind { motion, stylise, glow }

enum MotionKind { zoomIn, zoomOut, pulse, shake, drift, flash }

/// Bloom: the parts of the frame brighter than [threshold] are blurred and
/// screen-blended back over the picture.
///
/// Export (`export_command_builder.dart`): `split` → on one copy
/// `colorlevels` (black point = threshold) + `gblur` → `blend=screen` with
/// opacity [opacity]·strength. Preview (`GlowLayer`): the same highlight
/// pass as a colour matrix + `ImageFilter.blur`, added on top. Desktop
/// FFmpeg 7.1 checked 2026-11-13; the phone's libavfilter has
/// colorlevels / gblur / blend.
class GlowSpec {
  /// 0..1 — only brighter parts glow.
  final double threshold;

  /// Blur sigma as a fraction of the frame width.
  final double radius;

  /// Blend opacity at full strength.
  final double opacity;

  const GlowSpec({required this.threshold, required this.radius, required this.opacity});
}

class EffectSpec {
  /// Stored in `Clips.effect` — never rename, add a new id instead.
  final String id;
  final String label;
  final String hint;
  final EffectKind kind;
  final MotionKind? motion;
  final LookSpec? style;
  final GlowSpec? glow;

  const EffectSpec.motion(this.id, this.label, this.hint, MotionKind this.motion)
      : kind = EffectKind.motion,
        style = null,
        glow = null;

  const EffectSpec.stylise(this.id, this.label, this.hint, LookSpec this.style)
      : kind = EffectKind.stylise,
        motion = null,
        glow = null;

  const EffectSpec.glow(this.id, this.label, this.hint, GlowSpec this.glow)
      : kind = EffectKind.glow,
        motion = null,
        style = null;
}

const List<EffectSpec> effectPresets = [
  EffectSpec.motion('fx_zoom_in', 'Zoom in', 'Slow push towards the subject', MotionKind.zoomIn),
  EffectSpec.motion('fx_zoom_out', 'Zoom out', 'Starts close, pulls back', MotionKind.zoomOut),
  EffectSpec.motion('fx_pan', 'Pan', 'Ken Burns drift, left to right', MotionKind.drift),
  EffectSpec.motion('fx_pulse', 'Beat pulse', 'Bumps twice a second (120 bpm)', MotionKind.pulse),
  EffectSpec.motion('fx_shake', 'Shake', 'Handheld camera shake', MotionKind.shake),
  EffectSpec.motion('fx_flash', 'Flash', 'Opens on a white flash', MotionKind.flash),
  EffectSpec.stylise('fx_vhs', 'VHS', 'Colour bleed and tape noise',
      LookSpec('fx_vhs', 'VHS', LookCategory.fun, chroma: 3, grain: 0.35, vignette: 0.15)),
  EffectSpec.stylise(
      'fx_glitch', 'Glitch', 'Split RGB channels', LookSpec('fx_glitch', 'Glitch', LookCategory.fun, chroma: 8, grain: 0.2)),
  EffectSpec.stylise(
      'fx_grain', 'Film grain', 'Fine moving grain', LookSpec('fx_grain', 'Film grain', LookCategory.fun, grain: 0.45)),
  EffectSpec.stylise(
      'fx_pixel', 'Pixelate', 'Big chunky pixels', LookSpec('fx_pixel', 'Pixelate', LookCategory.fun, pixelate: 18)),
  EffectSpec.stylise(
      'fx_poster', 'Poster', 'Flat bands of colour', LookSpec('fx_poster', 'Poster', LookCategory.fun, posterize: 5)),
  EffectSpec.stylise(
      'fx_spot', 'Spotlight', 'Dark edges, bright centre', LookSpec('fx_spot', 'Spotlight', LookCategory.fun, vignette: 0.9)),
  EffectSpec.stylise(
      'fx_detail', 'Detail', 'Strong sharpening', LookSpec('fx_detail', 'Detail', LookCategory.fun, sharpen: 0.9)),
  EffectSpec.stylise(
      'fx_invert', 'Invert', 'Photo negative', LookSpec('fx_invert', 'Invert', LookCategory.fun, negate: true)),
  EffectSpec.glow('fx_glow', 'Glow', 'Highlights bloom with soft light',
      GlowSpec(threshold: 0.55, radius: 0.025, opacity: 0.85)),
  EffectSpec.glow('fx_dreamy', 'Dreamy', 'Wide, hazy glow over the whole picture',
      GlowSpec(threshold: 0.3, radius: 0.045, opacity: 0.6)),
];

/// Effective glow at strength [k], or null when [id] isn't a glow effect.
({double threshold, double sigmaFraction, double opacity})? glowAt(String? id, double k) {
  final g = effectById(id)?.glow;
  k = k.clamp(0.0, 1.0);
  if (g == null || k <= 0) return null;
  return (threshold: g.threshold, sigmaFraction: g.radius, opacity: g.opacity * k);
}

/// The highlight branch of the glow for a [width]-pixel-wide frame (the
/// part between `split` and `blend`).
String glowBranchFilters(({double threshold, double sigmaFraction, double opacity}) g, int width) {
  final t = g.threshold.toStringAsFixed(3);
  final sigma = (g.sigmaFraction * width).clamp(1.0, 200.0).toStringAsFixed(2);
  return 'colorlevels=rimin=$t:gimin=$t:bimin=$t,gblur=sigma=$sigma';
}

/// The effect with [id], or null for none / unknown ids (old or bad rows
/// behave as "no effect" instead of failing an export).
EffectSpec? effectById(String? id) {
  if (id == null) return null;
  for (final e in effectPresets) {
    if (e.id == id) return e;
  }
  return null;
}

/// One frame of a motion effect: zoom [scale] about the centre, then the
/// view window moved by [dx]/[dy] (fractions of the frame), plus a white
/// [flash] over the frame (0..1).
class MotionFrame {
  final double scale;
  final double dx;
  final double dy;
  final double flash;
  const MotionFrame({this.scale = 1, this.dx = 0, this.dy = 0, this.flash = 0});
}

const double _zoom = 0.2, _pulse = 0.06, _shakeScale = 0.06, _driftScale = 0.12, _flashSec = 0.4;

/// [t] seconds into a clip that lasts [duration] seconds, effect strength [k].
MotionFrame motionAt(MotionKind kind, double t, double duration, double k) {
  k = k.clamp(0.0, 1.0);
  final p = duration <= 0 ? 0.0 : (t / duration).clamp(0.0, 1.0);
  switch (kind) {
    case MotionKind.zoomIn:
      return MotionFrame(scale: 1 + _zoom * k * p);
    case MotionKind.zoomOut:
      return MotionFrame(scale: 1 + _zoom * k * (1 - p));
    case MotionKind.pulse:
      return MotionFrame(scale: 1 + _pulse * k * math.sin(2 * math.pi * t).abs());
    case MotionKind.shake:
      return MotionFrame(
        scale: 1 + _shakeScale * k,
        dx: 0.02 * k * math.sin(2 * math.pi * 7 * t),
        dy: 0.015 * k * math.sin(2 * math.pi * 9 * t + 1),
      );
    case MotionKind.drift:
      return MotionFrame(scale: 1 + _driftScale * k, dx: 0.05 * k * (2 * p - 1));
    case MotionKind.flash:
      final d = flashSeconds(k);
      return MotionFrame(flash: d <= 0 ? 0 : (1 - t / d).clamp(0.0, 1.0));
  }
}

/// Length of the white flash at strength [k] (export `fade … color=white`).
double flashSeconds(double k) => k <= 0 ? 0 : math.max(0.05, _flashSec * k.clamp(0.0, 1.0));

String _n(double v) => v.toStringAsFixed(4);

/// FFmpeg steps for a motion effect on a [w]x[h] frame for a clip that
/// lasts [durationSec] — the same formulas as [motionAt], with `t` the
/// clip's own output time (it starts at 0 after the clip's `setpts`).
List<String> motionFilters(MotionKind kind, double durationSec, double k, int w, int h, {String scaleFlags = 'flags=bicubic'}) {
  k = k.clamp(0.0, 1.0);
  if (k == 0) return const [];
  final d = durationSec <= 0 ? 1.0 : durationSec;
  final p = 'min(t/${_n(d)},1)';
  String s, dx = '0', dy = '0';
  switch (kind) {
    case MotionKind.flash:
      return ['fade=t=in:st=0:d=${flashSeconds(k).toStringAsFixed(3)}:color=white'];
    case MotionKind.zoomIn:
      s = '1+${_n(_zoom * k)}*$p';
    case MotionKind.zoomOut:
      s = '1+${_n(_zoom * k)}*(1-$p)';
    case MotionKind.pulse:
      s = '1+${_n(_pulse * k)}*abs(sin(2*PI*t))';
    case MotionKind.shake:
      s = _n(1 + _shakeScale * k);
      dx = '${_n(0.02 * k)}*sin(2*PI*7*t)';
      dy = '${_n(0.015 * k)}*sin(2*PI*9*t+1)';
    case MotionKind.drift:
      s = _n(1 + _driftScale * k);
      dx = '${_n(0.05 * k)}*(2*$p-1)';
  }
  return [
    "scale=w='2*trunc($w*($s)/2)':h='2*trunc($h*($s)/2)':eval=frame:$scaleFlags",
    "crop=w=$w:h=$h:x='(iw-$w)/2+($dx)*$w':y='(ih-$h)/2+($dy)*$h'",
    'setsar=1',
  ];
}

/// The look-style spec of a stylise effect at [k], or null.
ScaledLook? effectStyle(String? id, double k) {
  final s = effectById(id)?.style;
  if (s == null || k <= 0) return null;
  return ScaledLook(s, k);
}
