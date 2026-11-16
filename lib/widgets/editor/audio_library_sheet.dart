import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/app_theme.dart';
import '../../models/audio_library.dart';
import '../../models/bundled_track.dart';
import '../../models/library_sound.dart';

/// The built-in royalty-free music library (CC0, made in-house — see
/// `tools/make_audio_library.py`), plus the three older loops. Resolves to
/// the chosen track, or null.
Future<BundledTrack?> showMusicLibrary(BuildContext context) {
  return showModalBottomSheet<BundledTrack>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LibrarySheet(sfx: false),
  );
}

/// The sound-effects library. Resolves to the chosen effect, or null.
Future<LibrarySound?> showSfxLibrary(BuildContext context) {
  return showModalBottomSheet<LibrarySound>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LibrarySheet(sfx: true),
  );
}

const _classic = 'Classic loops';

const Map<String, IconData> _categoryIcons = {
  'Lofi': Icons.nightlight_outlined,
  'Chill': Icons.wb_twilight_outlined,
  'Upbeat': Icons.wb_sunny_outlined,
  'Hip-hop': Icons.graphic_eq,
  'Electronic': Icons.bolt_outlined,
  'Cinematic': Icons.theaters_outlined,
  'Ambient': Icons.blur_on,
  'Acoustic': Icons.music_note_outlined,
  _classic: Icons.loop,
  'Transitions': Icons.air,
  'UI & pop-ups': Icons.touch_app_outlined,
  'Real world': Icons.public,
};

class _Item {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String assetPath;
  final int durationMs;
  final BundledTrack track;
  final LibrarySound? sound;
  const _Item(this.id, this.title, this.subtitle, this.category, this.assetPath, this.durationMs, this.track, this.sound);
}

class _LibrarySheet extends StatefulWidget {
  final bool sfx;
  const _LibrarySheet({required this.sfx});

  @override
  State<_LibrarySheet> createState() => _LibrarySheetState();
}

class _LibrarySheetState extends State<_LibrarySheet> {
  final _player = AudioPlayer();
  StreamSubscription<PlayerState>? _sub;
  String? _playingId;
  String? _category;

  late final List<_Item> _items = [
    for (final s in audioLibrary.where((s) => s.isSfx == widget.sfx))
      _Item(s.id, s.title, s.isSfx ? '${(s.durationMs / 1000).toStringAsFixed(1)} s' : s.mood, s.category, s.assetPath,
          s.durationMs, s.asTrack, s),
    if (!widget.sfx)
      for (final t in bundledAudioLibrary)
        _Item(t.id, t.title, 'Short loop', _classic, t.assetPath, t.durationMs, t, null),
  ];

  late final List<String> _categories = {for (final i in _items) i.category}.toList();

  @override
  void initState() {
    super.initState();
    _sub = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed && mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle(_Item item) async {
    if (_playingId == item.id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    setState(() => _playingId = item.id);
    try {
      await _player.setAsset(item.assetPath);
      await _player.seek(Duration.zero);
      unawaited(_player.play());
    } catch (_) {
      if (mounted) setState(() => _playingId = null);
    }
  }

  void _choose(_Item item) {
    _player.stop();
    if (widget.sfx) {
      Navigator.pop(context, item.sound);
    } else {
      Navigator.pop(context, item.track);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _items.where((i) => _category == null || i.category == _category).toList();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.82),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Row(children: [
              Icon(widget.sfx ? Icons.surround_sound_outlined : Icons.library_music_outlined, color: AppColors.ember),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.sfx ? 'Sound effects' : 'Music library',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              'Made in-house and free to use anywhere — including monetised YouTube videos. '
              'No credit needed, no copyright claims.',
              style: TextStyle(color: AppColors.textDim, fontSize: 12.5, height: 1.3),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _Chip('All', null, _category == null, () => setState(() => _category = null)),
                for (final c in _categories) _Chip(c, _categoryIcons[c], _category == c, () => setState(() => _category = c)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              itemCount: shown.length,
              itemBuilder: (context, i) {
                final item = shown[i];
                final playing = _playingId == item.id;
                final s = item.sound;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: IconButton.filledTonal(
                    tooltip: playing ? 'Stop' : 'Listen',
                    onPressed: () => _toggle(item),
                    icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    [
                      item.subtitle,
                      if (s != null && !s.isSfx) '${s.bpm} bpm',
                      if (!widget.sfx) _len(item.durationMs),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                  trailing: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 14)),
                    onPressed: () => _choose(item),
                    child: Text(widget.sfx ? 'Add' : 'Use'),
                  ),
                  onTap: () => _toggle(item),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  static String _len(int ms) {
    final s = (ms / 1000).round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(this.label, this.icon, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          avatar: icon == null ? null : Icon(icon, size: 16),
          label: Text(label),
          labelStyle: const TextStyle(fontSize: 12.5),
          visualDensity: VisualDensity.compact,
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}
