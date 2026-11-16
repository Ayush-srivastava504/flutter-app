import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class DockTool {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Highlighted as switched on (toggles such as Safe zones / Ducking).
  final bool active;

  /// Shows a spinner instead of the icon.
  final bool busy;

  const DockTool(this.icon, this.label, this.onTap, {this.active = false, this.busy = false});
}

/// The editor's bottom tool bar when nothing is selected: a scrolling row of
/// [tools], then (YouTube Studio only) a gold "PRO" group of [proTools].
class ToolDock extends StatelessWidget {
  final List<DockTool> tools;
  final List<DockTool> proTools;
  const ToolDock({super.key, required this.tools, this.proTools = const []});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            children: [
              for (final t in tools) _DockButton(tool: t, accent: AppColors.ember),
              if (proTools.isNotEmpty) ...[
                const _ProDivider(),
                for (final t in proTools) _DockButton(tool: t, accent: AppColors.pro, iconColor: AppColors.pro),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final DockTool tool;
  final Color accent;
  final Color? iconColor;
  const _DockButton({required this.tool, required this.accent, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final enabled = tool.onTap != null && !tool.busy;
    final fg = tool.active ? accent : (iconColor ?? AppColors.text);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Material(
        color: tool.active ? accent.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: enabled ? tool.onTap : null,
          child: SizedBox(
            width: 64,
            child: Opacity(
              opacity: enabled || tool.busy ? 1 : 0.4,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(
                  height: 22,
                  child: tool.busy
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                      : Icon(tool.icon, size: 22, color: fg),
                ),
                const SizedBox(height: 5),
                Text(
                  tool.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tool.active ? accent : AppColors.textDim,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProDivider extends StatelessWidget {
  const _ProDivider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(children: [
          Container(width: 1, color: AppColors.line),
          const SizedBox(width: 8),
          const RotatedBox(
            quarterTurns: 3,
            child: Text('PRO',
                style: TextStyle(color: AppColors.pro, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ),
        ]),
      );
}
