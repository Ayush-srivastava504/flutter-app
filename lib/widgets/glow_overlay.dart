import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/effect_x.dart';

/// Glow (bloom) for the preview: placed *above* the picture, it takes what
/// is painted behind it, keeps only the highlights, blurs them and
/// screen-blends the result back — the same steps as the export's
/// `colorlevels` → `gblur` → `blend=screen` (see [glowAt] / [GlowSpec]).
///
/// Why the maths matches: FFmpeg's `blend=screen:all_opacity=k` gives
/// `a + k·(screen(a,b) − a)` = `screen(a, k·b)`, so scaling the highlight
/// layer by k before a plain screen blend is exactly the export's result.
class GlowOverlay extends StatelessWidget {
  final String? effectId;
  final double strength;

  const GlowOverlay({super.key, required this.effectId, required this.strength});

  /// `colorlevels=rimin=t` (input t..1 → 0..1), then × opacity.
  static List<double> highlightMatrix(double threshold, double opacity) {
    final s = opacity / (1 - threshold).clamp(0.05, 1.0);
    final o = -threshold * s * 255;
    return [
      s, 0, 0, 0, o, //
      0, s, 0, 0, o,
      0, 0, s, 0, o,
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final g = glowAt(effectId, strength);
    if (g == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(builder: (context, box) {
          final width = box.maxWidth.isFinite ? box.maxWidth : 360.0;
          final sigma = (g.sigmaFraction * width).clamp(0.5, 120.0);
          return BackdropFilter(
            blendMode: BlendMode.screen,
            filter: ui.ImageFilter.compose(
              outer: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.clamp),
              inner: ui.ColorFilter.matrix(highlightMatrix(g.threshold, g.opacity)),
            ),
            child: const SizedBox.expand(),
          );
        }),
      ),
    );
  }
}
