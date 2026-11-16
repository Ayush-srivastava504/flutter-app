import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/edit_mode.dart';

/// Small shared building blocks so screens look like one app.

class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.pro.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.pro.withValues(alpha: 0.6)),
        ),
        child: const Text('PRO',
            style: TextStyle(color: AppColors.pro, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
      );
}

/// Section heading with an optional trailing action ("See all", count…).
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsets padding;
  const SectionHeader(this.title, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 10)});

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(children: [
          Expanded(
            child: Text(title,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), Flexible(child: trailing!)],
        ]),
      );
}

/// Coloured dot + mode name, for project tiles and the editor title.
class ModeChip extends StatelessWidget {
  final EditMode mode;
  final bool dense;
  const ModeChip(this.mode, {super.key, this.dense = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 2 : 3),
        decoration: BoxDecoration(
          color: mode.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(mode.icon, size: dense ? 11 : 13, color: mode.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(mode.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: mode.color, fontSize: dense ? 10 : 11.5, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

/// Rounded surface card with an ink ripple.
class TapCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets padding;
  final Color color;
  final Color? borderColor;
  final double radius;

  const TapCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.borderColor,
    this.radius = AppRadii.md,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: borderColor ?? AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      );
}
