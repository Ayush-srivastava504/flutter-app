import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../history/project_history.dart';

/// Undo / redo buttons plus the autosave "Saved HH:mm" indicator for the editor's AppBar.
class HistoryActions extends ConsumerWidget {
  final String projectId;
  const HistoryActions({super.key, required this.projectId});

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(projectHistoryProvider(projectId));
    final saved = history.lastSaved;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (saved != null)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text('Saved ${_hhmm(saved)}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ),
      IconButton(
        tooltip: 'Undo',
        icon: const Icon(Icons.undo),
        onPressed: history.canUndo ? history.undo : null,
      ),
      IconButton(
        tooltip: 'Redo',
        icon: const Icon(Icons.redo),
        onPressed: history.canRedo ? history.redo : null,
      ),
    ]);
  }
}
