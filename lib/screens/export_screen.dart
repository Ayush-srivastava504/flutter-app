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
import '../services/ads_service.dart';
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

  /// Light denoise + smart sharpening on every clip (`enhanceFilters`).
  bool _enhance = true;

  @override
  void initState() {
    super.initState();
    _loadSavedChoices();
    // The controller outlives this screen (so a running export survives
    // leaving it). A *finished* or failed export, though, belongs to the
    // edit as it was then — showing it again after the user changed a
    // filter would hand them the old video. Start fresh instead. Deferred
    // because providers can't be modified while the tree is building.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(exportControllerProvider(widget.projectId).notifier).resetIfFinished();
    });
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

  /// 4K is unlocked per export by a rewarded ad. When no ad can be shown
  /// (ads off, offline, no fill) the export just goes ahead.
  bool _uhdUnlocked = false;

  Future<void> _startExport(ExportController controller) async {
    if (_quality == ExportQuality.p2160 && !_uhdUnlocked && Ads.instance.ready.value) {
      final watch = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unlock 4K export'),
          content: const Text('Watch a short ad to export this video in 4K. '
              'Every other quality is free, no ad needed.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Watch ad')),
          ],
        ),
      );
      if (watch != true || !mounted) return;
      final outcome = await Ads.instance.unlockWithRewardedAd();
      if (!mounted) return;
      if (outcome == RewardOutcome.skipped) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Watch the whole ad to unlock 4K, or pick 1080p.')));
        return;
      }
      _uhdUnlocked = true; // earned, or no ad available: don't hold the export hostage
    }
    await controller.start(_quality, fps: _fps, enhance: _enhance);
    _uhdUnlocked = false; // one ad, one 4K export
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
    final heavy = _quality == ExportQuality.p2160 || (_fps >= 60 && _quality == ExportQuality.p1080);
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
      if (_quality == ExportQuality.p2160 && Ads.instance.ready.value) ...[
        const SizedBox(height: 6),
        const Row(children: [
          Icon(Icons.ondemand_video_rounded, size: 14, color: Colors.white60),
          SizedBox(width: 6),
          Expanded(
            child: Text('4K: watch a short ad to unlock this export.',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
          ),
        ]),
      ],
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
          '4K and 1080p at 60 fps are demanding: slower, and not every phone can '
          'encode them. If the export fails, try 1080p at 30 fps.',
          style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
        ),
      ],
      const SizedBox(height: 12),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Enhance quality'),
        subtitle: const Text('Reduces noise and sharpens detail. Export takes a little longer.',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        value: _enhance,
        onChanged: (v) => setState(() => _enhance = v),
      ),
      const SizedBox(height: 8),
      Text('$seconds s • about $mb MB', style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => _startExport(controller),
        icon: const Icon(Icons.movie_filter_outlined),
        label: const Text('Export video'),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _exportingProjectFile ? null : _exportProjectFile,
        icon: _exportingProjectFile
            ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.description_outlined),
        label: Text(_exportingProjectFile ? 'Preparing…' : 'Export project file (.fcpxml)'),
      ),
      const SizedBox(height: 4),
      const Text(
        'For finishing on a desktop editor (Premiere, Resolve, Final Cut). '
        'Clip order, trims and text carry over; re-add transitions there.',
        style: TextStyle(color: Colors.white38, fontSize: 11),
      ),
    ]);
  }

  bool _exportingProjectFile = false;

  /// F29: builds the FCPXML next to (not instead of) a rendered video —
  /// this is instant (no ffmpeg run), so unlike [ExportController.start]
  /// it doesn't need a phase/progress state, just a local busy flag for
  /// the button.
  Future<void> _exportProjectFile() async {
    setState(() => _exportingProjectFile = true);
    try {
      final service = ref.read(fcpxmlExportServiceProvider);
      final path = await service.exportProject(widget.projectId);
      if (!mounted) return;
      if (path == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Nothing to export yet.')));
        return;
      }
      await ref.read(galleryShareProvider).shareFile(
            path,
            mimeType: 'application/xml',
            text: 'Cliper project (FCPXML)',
          );
    } finally {
      if (mounted) setState(() => _exportingProjectFile = false);
    }
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
      if (state.encoder != null) ...[
        const SizedBox(height: 6),
        Text(
          'Encoded with: ${videoEncoderLabel(state.encoder!)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: state.encoder == VideoEncoder.software ? Colors.orangeAccent : Colors.white38,
          ),
        ),
      ],
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
      FilledButton(onPressed: () => controller.start(_quality, fps: _fps, enhance: _enhance), child: const Text('Try again')),
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
