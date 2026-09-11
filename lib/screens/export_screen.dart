import 'package:flutter/material.dart';

/// Export screen scaffold. The actual FFmpeg compositing pipeline,
/// resolution selection, and progress reporting are built in Phase 8.
class ExportScreen extends StatelessWidget {
  final String projectId;

  const ExportScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Export pipeline (Phase 8)'),
            const SizedBox(height: 8),
            Text('Project: $projectId', style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
