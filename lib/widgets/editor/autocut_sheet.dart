import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/assistant_providers.dart';
import '../../app/app_theme.dart';
import '../../data/database_provider.dart';
import '../../models/auto_cut.dart';
import '../../providers/audio_providers.dart';
import '../../services/auto_cut_service.dart';

/// What the AutoCut sheet asks the editor to run next.
enum AutoCutChoice { silences, scenes }

/// AutoCut: cut to the beat (runs here), or hand back one of the analysis
/// tools for the editor to run on "this clip / every clip".
Future<AutoCutChoice?> showAutoCutSheet(BuildContext context, String projectId) {
  return showModalBottomSheet<AutoCutChoice>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AutoCutSheet(projectId: projectId),
  );
}

class _AutoCutSheet extends ConsumerStatefulWidget {
  final String projectId;
  const _AutoCutSheet({required this.projectId});

  @override
  ConsumerState<_AutoCutSheet> createState() => _AutoCutSheetState();
}

class _AutoCutSheetState extends ConsumerState<_AutoCutSheet> {
  int _beats = 2;
  bool _busy = false;
  String? _error;

  Future<void> _cut() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final msg = await AutoCutService(ref.read(projectDatabaseProvider), ref.read(mediaAnalyzerProvider))
          .cutToBeat(widget.projectId, beatsPerCut: _beats);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text('$msg Undo puts it back.')));
    } on StateError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'AutoCut failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final music = ref.watch(audioTrackProvider(widget.projectId)).value;
    final known = music == null ? null : libraryTempoFor(music.sourceUri);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.auto_fix_high, color: AppColors.ember),
            const SizedBox(width: 10),
            Text('AutoCut', style: Theme.of(context).textTheme.titleLarge),
          ]),
          const SizedBox(height: 4),
          const Text('Let Cliper do the cutting. Every option is one step, and undo takes it back.',
              style: TextStyle(color: AppColors.textDim)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Row(children: [
                Icon(Icons.music_note_outlined, color: AppColors.ember, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Cut to the beat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                music == null
                    ? 'Add music first. AutoCut slices your clips into pieces that change exactly on its beat.'
                    : known != null
                        ? 'Music: ${known.bpm.round()} bpm. Your clips become beat-length pieces, taken in turns '
                            'and spread across each clip.'
                        : 'The beat of your music is measured on the phone, then your clips become beat-length pieces.',
                style: const TextStyle(color: AppColors.textDim, fontSize: 12.5, height: 1.35),
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 1, label: Text('Fast'), tooltip: 'Cut every beat'),
                  ButtonSegment(value: 2, label: Text('Normal'), tooltip: 'Cut every 2 beats'),
                  ButtonSegment(value: 4, label: Text('Slow'), tooltip: 'Cut every bar (4 beats)'),
                ],
                selected: {_beats},
                onSelectionChanged: _busy ? null : (s) => setState(() => _beats = s.first),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.warn, fontSize: 12.5)),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: music == null || _busy ? null : _cut,
                icon: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.content_cut, size: 18),
                label: Text(_busy ? 'Cutting…' : 'Cut to the beat'),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          _Option(
            icon: Icons.graphic_eq,
            title: 'Remove silences',
            body: 'Jump cuts: drops the quiet pauses from talking clips.',
            onTap: _busy ? null : () => Navigator.pop(context, AutoCutChoice.silences),
          ),
          _Option(
            icon: Icons.movie_filter_outlined,
            title: 'Split at scene changes',
            body: 'Cuts long clips wherever the shot changes, ready to trim or reorder.',
            onTap: _busy ? null : () => Navigator.pop(context, AutoCutChoice.scenes),
          ),
        ]),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;
  const _Option({required this.icon, required this.title, required this.body, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(icon, color: AppColors.ember),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(body, style: const TextStyle(color: AppColors.textDim, fontSize: 12.5)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}
