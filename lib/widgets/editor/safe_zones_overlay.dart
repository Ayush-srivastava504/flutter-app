import 'package:flutter/material.dart';

/// Preview-only guides (never exported): rule-of-thirds lines, plus the
/// action-safe (93 %) and title-safe (90 %) frames used in broadcast and
/// still a good rule for where titles won't be cropped by players or TVs.
class SafeZonesOverlay extends StatelessWidget {
  const SafeZonesOverlay({super.key});

  @override
  Widget build(BuildContext context) =>
      const IgnorePointer(child: CustomPaint(painter: _SafeZonesPainter(), size: Size.infinite));
}

class _SafeZonesPainter extends CustomPainter {
  const _SafeZonesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final thirds = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    for (final f in [1 / 3, 2 / 3]) {
      canvas.drawLine(Offset(size.width * f, 0), Offset(size.width * f, size.height), thirds);
      canvas.drawLine(Offset(0, size.height * f), Offset(size.width, size.height * f), thirds);
    }

    Rect inset(double keep) {
      final dx = size.width * (1 - keep) / 2, dy = size.height * (1 - keep) / 2;
      return Rect.fromLTRB(dx, dy, size.width - dx, size.height - dy);
    }

    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(inset(0.93), frame..color = const Color(0xFFE8B65A).withValues(alpha: 0.55));
    canvas.drawRect(inset(0.90), frame..color = const Color(0xFFE8B65A).withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(_SafeZonesPainter oldDelegate) => false;
}
