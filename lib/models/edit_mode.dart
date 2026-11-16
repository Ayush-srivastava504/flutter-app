import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// The three ways to start a video project. Stored by [name] in
/// `Projects.mode` (schema v10).
///
/// - [youtube]: long-form 16:9, with the Pro toolkit (jump cuts, scene
///   split, loudness, chapters, captions, ducking, guides).
/// - [insta]: vertical 9:16 short clip — the standard editor, frame locked.
/// - [normal]: the standard editor; the first video picks the frame shape.
enum EditMode {
  youtube('YouTube Studio', 'Long-form 16:9 · Pro tools', Icons.smart_display_outlined, AppColors.youtube, 16 / 9),
  insta('Insta Clip', 'Vertical 9:16 reels & shorts', Icons.stay_current_portrait_outlined, AppColors.insta, 9 / 16),
  normal('Quick Edit', 'Any shape · simple & fast', Icons.content_cut, AppColors.normal, null);

  final String label;
  final String tagline;
  final IconData icon;
  final Color color;

  /// Frame shape the project starts in and keeps when media is imported,
  /// or null to let the first imported video choose (the old behaviour).
  final double? lockedAspect;

  const EditMode(this.label, this.tagline, this.icon, this.color, this.lockedAspect);

  bool get isPro => this == youtube;

  /// Unknown or missing values (rows from before v10) are [normal].
  static EditMode fromName(String? name) =>
      EditMode.values.firstWhere((m) => m.name == name, orElse: () => EditMode.normal);
}
