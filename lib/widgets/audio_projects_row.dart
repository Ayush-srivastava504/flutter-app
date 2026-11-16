import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_theme.dart';
import '../data/database_provider.dart';
import '../data/project_database.dart';
import '../router/app_router.dart';
import 'common/ui_kit.dart';

/// Home → Audio Studio card (full width, like Photo Studio).
class AudioStudioCard extends StatelessWidget {
  final VoidCallback onTap;
  const AudioStudioCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapCard(
      onTap: onTap,
      radius: AppRadii.lg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.pro.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.graphic_eq, color: AppColors.pro, size: 20),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Audio Studio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('Edit, reverb & voice FX, or compose a beat',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textDim, fontSize: 12.5)),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textFaint),
      ]),
    );
  }
}

/// Home → "Your audio": recent audio edits and beats. Hold to delete.
class AudioProjectsSection extends ConsumerWidget {
  const AudioProjectsSection({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, AudioProject a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${a.name}"?'),
        content: const Text('Files you already saved to your phone are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await ref.read(projectDatabaseProvider).deleteAudioProject(a.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<AudioProject>>(
      stream: ref.watch(projectDatabaseProvider).watchAudioProjects(),
      builder: (context, snap) {
        final items = snap.data ?? const <AudioProject>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHeader('Your audio',
              trailing: Text('Hold to delete', style: TextStyle(color: AppColors.textFaint, fontSize: 12))),
          SizedBox(
            // Grows with the phone's font size instead of clipping the second line.
            height: MediaQuery.textScalerOf(context).scale(48) + 28,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final a = items[i];
                final isBeat = a.composeJson != null;
                final s = a.durationMs ~/ 1000;
                return SizedBox(
                  width: 196,
                  child: TapCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    onTap: () => Navigator.pushNamed(
                      context,
                      isBeat && a.sourceUri == null ? AppRouter.compose : AppRouter.audio,
                      arguments: a.id,
                    ),
                    onLongPress: () => _delete(context, ref, a),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.pro.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(isBeat ? Icons.piano_outlined : Icons.graphic_eq, color: AppColors.pro, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(a.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              '${isBeat ? 'Beat' : 'Audio'}${s > 0 ? ' · ${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]);
      },
    );
  }
}
