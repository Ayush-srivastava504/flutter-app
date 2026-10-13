import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/launch_gate.dart' show appPrefsProvider;
import '../export/export_command_builder.dart';
import '../export/export_controller.dart';
import '../export/export_inputs.dart';
import '../export/export_models.dart';
import '../export/export_service.dart';
import '../providers/timeline_providers.dart';
import '../widgets/common/state_views.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ExportScreen({super.key, required this.projectId});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportQuality _quality = ExportQuality.p1080;
  int _fps = defaultExportFps;

  @override
  void initState() {
    super.initState();
    _loadSavedChoices();
  }

  /// F5: reopen on whatever the user exported with last time.
  Future<void> _loadSavedChoices() async {
    final prefs = ref.read(appPrefsProvider);
    final quality = ExportQuality.tryParse(await prefs.exportQualityName);
    final fps = sanitizeExportFps(await prefs.exportFps);
    if (!mounted) return;
    setState(() {
      if (quality != null) _quality = quality;
      _fps = fps;
    });
  }

  void _saveChoices() => ref.read(appPrefsProvider).setExportSettings(qualityName: _quality.name, fps: _fps);

  @override
  Widget build(BuildContext context) {
    final clipsAsync = ref.watch(clipsProvider(widget.projectId));
    final state = ref.watch(exportControllerProvider(widget.projectId));
    final controller = ref.read(exportControllerProvider(widget.projectId).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: clipsAsync.when(
        loading: () => const LoadingStateView(message: 'Loading project…'),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (clips) {
          if (clips.isEmpty) {
            return EmptyStateView(
              icon: Icons.movie_creation_outlined,
              title: 'Nothing to export yet',
              message: 'Add a clip or photo to the timeline first.',
              actionLabel: 'Back to editor',
              onAction: () => Navigator.pop(context),
            );
          }
          final durationMs = exportDurationMs(exportClipsFrom(clips, const {}));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              switch (state.phase) {
                ExportPhase.idle => _picker(durationMs, controller),
                ExportPhase.running => _running(state, controller),
                ExportPhase.done => _done(state, controller),
                ExportPhase.failed => _failed(state, controller),
              },
            ],
          );
        },
      ),
    );
  }

  Widget _picker(int durationMs, ExportController controller) {
    final seconds = (durationMs / 1000).toStringAsFixed(1);
    final mb = (estimatedExportBytes(_quality, durationMs, fps: _fps) / 1e6).toStringAsFixed(0);
    final heavy = _fps >= 60 && _quality == ExportQuality.p1080;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Resolution', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      SegmentedButton<ExportQuality>(
        segments: [for (final q in ExportQuality.values) ButtonSegment(value: q, label: Text(q.label))],
        selected: {_quality},
        onSelectionChanged: (s) {
          setState(() => _quality = s.first);
          _saveChoices();
        },
      ),
      const SizedBox(height: 20),
      Text('Frame rate', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      SegmentedButton<int>(
        segments: [for (final f in exportFpsOptions) ButtonSegment(value: f, label: Text('$f fps'))],
        selected: {_fps},
        onSelectionChanged: (s) {
          setState(() => _fps = s.first);
          _saveChoices();
        },
      ),
      if (heavy) ...[
        const SizedBox(height: 8),
        const Text(
          '1080p at 60 fps is demanding. If the export fails, try 30 fps or 720p.',
          style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
        ),
      ],
      const SizedBox(height: 16),
      Text('$seconds s • about $mb MB', style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => controller.start(_quality, fps: _fps),
        icon: const Icon(Icons.movie_filter_outlined),
        label: const Text('Export video'),
      ),
    ]);
  }

  Widget _running(ExportState state, ExportController controller) {
    final pct = (state.progress * 100).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Exporting… $pct%', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16),
      LinearProgressIndicator(value: state.progress == 0 ? null : state.progress, minHeight: 8),
      const SizedBox(height: 12),
      const Text(
        'You can leave this screen — we\'ll notify you when it\'s done. '
        'Keep the app open for the fastest export.',
        style: TextStyle(color: Colors.white60),
      ),
      const SizedBox(height: 24),
      OutlinedButton(onPressed: controller.cancel, child: const Text('Cancel')),
    ]);
  }

  Widget _done(ExportState state, ExportController controller) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Icon(Icons.check_circle_outline, size: 64, color: Colors.greenAccent),
      const SizedBox(height: 12),
      Text('Your video is ready', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(
        state.savedToGallery ? 'Saved to your gallery.' : (state.saveError ?? 'Not saved to the gallery yet.'),
        textAlign: TextAlign.center,
        style: TextStyle(color: state.savedToGallery ? Colors.white70 : Colors.orangeAccent),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: controller.share, icon: const Icon(Icons.ios_share), label: const Text('Share')),
      if (!state.savedToGallery) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: controller.saveToGallery,
          icon: const Icon(Icons.download),
          label: const Text('Save to gallery'),
        ),
      ],
      const SizedBox(height: 8),
      TextButton(onPressed: controller.reset, child: const Text('Export again')),
    ]);
  }

  Widget _failed(ExportState state, ExportController controller) {
    final f = state.failure;
    final interrupted = f?.kind == ExportFailureKind.interrupted;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Icon(interrupted ? Icons.pause_circle_outline : Icons.error_outline, size: 64, color: Colors.orangeAccent),
      const SizedBox(height: 12),
      Text(interrupted ? 'Export stopped' : 'Export failed',
          style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(f?.message ?? failureMessage(ExportFailureKind.unknown), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      FilledButton(onPressed: () => controller.start(_quality, fps: _fps), child: const Text('Try again')),
      if (f?.detail != null)
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: f!.detail!));
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error details copied')));
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy error details'),
        ),
      TextButton(onPressed: controller.reset, child: const Text('Change settings')),
    ]);
  }
}
