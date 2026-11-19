import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// The ClipForge mark: one open, pen-drawn infinity loop with an over/under
/// crossing. Same geometry as `tools/make_app_icon.py` (the launcher icon) —
/// change both together.
class InfinityMarkGeometry {
  static const tStart = 0.32;
  static const tEnd = 2 * math.pi + 0.10;
  static const taper = 0.85;
  static const tilt = -5 * math.pi / 180;
  static const rightScale = 1.10;

  /// Point on the mark for parameter [t], in a unit box (x about -1..1.1).
  static Offset point(double t) {
    final s = math.sin(t);
    final d = 1 + s * s;
    var x = math.cos(t) / d;
    var y = s * math.cos(t) / d;
    if (x > 0) {
      x *= rightScale;
      y *= rightScale;
    }
    final c = math.cos(tilt), sn = math.sin(tilt);
    return Offset(x * c - y * sn, x * sn + y * c);
  }

  /// Relative stroke width at [t]: heavier on down-strokes, tapered ends.
  static double width(double t) {
    var w = 1.0 + 0.32 * math.cos(t - 0.9);
    final a = math.min(t - tStart, tEnd - t) / taper;
    if (a < 1) {
      final k = a.clamp(0.0, 1.0);
      w *= 0.18 + 0.82 * (k * k * (3 - 2 * k));
    }
    return w;
  }
}

class InfinityMark extends StatelessWidget {
  /// Width of the mark; height is half of it.
  final double size;
  final Color color;

  /// Colour behind the mark — used to cut the small gap at the crossing.
  final Color background;

  /// 0..1: how much of the stroke is drawn (for the intro animation).
  final double progress;

  const InfinityMark({
    super.key,
    this.size = 48,
    this.color = AppColors.ember,
    this.background = AppColors.ink,
    this.progress = 1,
  });

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          size: Size(size, size * 0.5),
          painter: _InfinityPainter(color, background, progress),
        ),
      );
}

class _InfinityPainter extends CustomPainter {
  final Color color;
  final Color background;
  final double progress;
  _InfinityPainter(this.color, this.background, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.44;
    final center = Offset(size.width * 0.48, size.height / 2);
    final base = size.width * 0.085;
    Offset p(double t) => center + InfinityMarkGeometry.point(t) * r;

    final paint = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;

    void stroke(double t0, double t1, Color c, {double extra = 0}) {
      if (t1 <= t0) return;
      final n = math.max(4, (220 * (t1 - t0) / (2 * math.pi)).round());
      paint.color = c;
      var prev = p(t0);
      for (var i = 1; i <= n; i++) {
        final t = t0 + (t1 - t0) * i / n;
        final next = p(t);
        paint.strokeWidth = base * InfinityMarkGeometry.width(t) + extra * 2;
        canvas.drawLine(prev, next, paint);
        prev = next;
      }
    }

    const t0 = InfinityMarkGeometry.tStart;
    final tEnd = t0 + (InfinityMarkGeometry.tEnd - t0) * progress.clamp(0.0, 1.0);
    stroke(t0, tEnd, color);

    // Over/under at the crossing the pen passes second.
    const over = 3 * math.pi / 2;
    if (tEnd > over - 0.42) {
      stroke(over - 0.20, math.min(over + 0.20, tEnd), background, extra: base * 0.30);
      stroke(over - 0.42, math.min(over + 0.42, tEnd), color);
    }
  }

  @override
  bool shouldRepaint(_InfinityPainter old) =>
      old.color != color || old.background != background || old.progress != progress;
}

/// Mark + "ClipForge" wordmark, for headers.
class ClipForgeLogo extends StatelessWidget {
  final double height;
  const ClipForgeLogo({super.key, this.height = 28});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InfinityMark(size: height * 1.6),
        SizedBox(width: height * 0.35),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Clip', style: TextStyle(fontWeight: FontWeight.w800)),
            TextSpan(
              text: 'er',
              style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.text.withValues(alpha: 0.72)),
            ),
          ]),
          style: TextStyle(fontSize: height * 0.78, letterSpacing: -0.6, color: AppColors.text, height: 1),
        ),
      ],
    );
  }
}
