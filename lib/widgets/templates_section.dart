import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/audio_library.dart';
import '../models/bundled_track.dart';
import '../models/effect_x.dart';
import '../models/look_x.dart';
import '../models/transition_x.dart';
import '../models/video_template.dart';
import 'common/ui_kit.dart';

/// Home → Discover: four tabs (YouTube video, Insta story, Insta post,
/// Posts), each a list of categories with a row of template cards.
/// [onUse] runs the pick-media → build-project flow for the chosen template.
class DiscoverSection extends StatefulWidget {
  final ValueChanged<VideoTemplate> onUse;
  final String? busyId;
  const DiscoverSection({super.key, required this.onUse, this.busyId});

  @override
  State<DiscoverSection> createState() => _DiscoverSectionState();
}

class _DiscoverSectionState extends State<DiscoverSection> {
  DiscoverTab _tab = DiscoverTab.youtube;

  @override
  Widget build(BuildContext context) {
    final cats = discoverCategories.where((c) => c.tab == _tab).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 44,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: DiscoverTab.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final tab = DiscoverTab.values[i];
            final on = tab == _tab;
            return Center(
              child: Material(
                color: on ? AppColors.ember : AppColors.surfaceHigh,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => setState(() => _tab = tab),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(tab.icon, size: 16, color: on ? AppColors.ink : AppColors.textDim),
                      const SizedBox(width: 6),
                      Text(tab.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: on ? AppColors.ink : AppColors.text,
                          )),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      for (final c in cats) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(children: [
            Icon(c.icon, size: 16, color: c.to),
            const SizedBox(width: 8),
            Expanded(
              child: Text(c.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            ),
          ]),
        ),
        _CategoryRow(
          key: ValueKey('discover-row-${c.id}'),
          templates: videoTemplates.where((t) => t.category == c.id).toList(),
          busyId: widget.busyId,
          onOpen: (t) => TemplatesRow.showDetails(context, t, widget.onUse),
        ),
      ],
    ]);
  }
}

class _CategoryRow extends StatelessWidget {
  final List<VideoTemplate> templates;
  final String? busyId;
  final ValueChanged<VideoTemplate> onOpen;
  const _CategoryRow({super.key, required this.templates, required this.busyId, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    // Grows with the phone's text size so the two text lines never clip.
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return SizedBox(
      height: 168 + 40 * scale,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => DiscoverCard(
          template: templates[i],
          busy: busyId == templates[i].id,
          onTap: busyId != null ? null : () => onOpen(templates[i]),
        ),
      ),
    );
  }
}

/// A poster-style template card: category gradient, frame shape and beat
/// badges, the edit's rhythm as a storyboard strip, name and length.
class DiscoverCard extends StatelessWidget {
  final VideoTemplate template;
  final bool busy;
  final VoidCallback? onTap;
  const DiscoverCard({super.key, required this.template, this.busy = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = template;
    final c = t.discoverCategory;
    final from = c?.from ?? AppColors.surfaceHigh;
    final to = c?.to ?? AppColors.surfaceTop;
    return SizedBox(
      width: 150,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [from, to]),
                ),
                child: Stack(children: [
                  Positioned(
                    right: -10,
                    bottom: 18,
                    child: Icon(c?.icon ?? Icons.auto_awesome, size: 84, color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    right: 8,
                    child: Wrap(spacing: 4, runSpacing: 4, children: [
                      _Badge(shapeLabel(t)),
                      if (t.isBeatSynced) _Badge('On beat · ${t.bpm} bpm', icon: Icons.graphic_eq),
                    ]),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: _Storyboard(template: t, height: 12, light: true),
                  ),
                  if (busy)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black38,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      ),
                    ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text('${t.suggestedClips} clips · ${(t.lengthMs / 1000).toStringAsFixed(0)} s',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  static String shapeLabel(VideoTemplate t) {
    final a = t.aspect ?? t.mode.lockedAspect;
    if (a == null) return 'Any shape';
    for (final (label, v) in const [('16:9', 16 / 9), ('9:16', 9 / 16), ('4:5', 4 / 5), ('1:1', 1.0)]) {
      if ((a - v).abs() < 0.01) return label;
    }
    return a.toStringAsFixed(2);
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _Badge(this.text, {this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 11, color: Colors.white), const SizedBox(width: 3)],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

/// Opens a template's details sheet (shared by Discover and tests).
class TemplatesRow {
  TemplatesRow._();

  static void showDetails(BuildContext context, VideoTemplate t, ValueChanged<VideoTemplate> onUse) =>
      _TemplateDetails.show(context, t, onUse);
}

class _TemplateDetails {
  static void show(BuildContext context, VideoTemplate t, ValueChanged<VideoTemplate> onUse) {
    final look = lookById(t.look);
    final effects = {for (final e in t.effects) effectById(e)?.label}.whereType<String>().toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Scrolls (and is height-capped) so it fits small phones, landscape and
      // big system text; the button stays at the end of the list.
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.88),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(t.name, style: Theme.of(ctx).textTheme.titleLarge)),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: ModeChip(t.mode)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(t.tagline, style: const TextStyle(color: AppColors.textDim)),
              const SizedBox(height: 16),
              _Storyboard(template: t, height: 46, showLengths: true),
              const SizedBox(height: 16),
              _Fact(Icons.view_week_outlined, '${t.suggestedClips} clips',
                  'Pick them in order. Fewer is fine; more repeat the pattern.'),
              _Fact(Icons.palette_outlined, 'Look: ${look.label}',
                  look.isNone ? 'No colour grade' : 'Applied to every clip'),
              if (t.isBeatSynced)
                _Fact(Icons.graphic_eq, 'On the beat',
                    'Every cut lands on a beat of the music (${t.bpm} bpm). Short videos are cut to whole beats.'),
              _Fact(Icons.crop_free, 'Frame', DiscoverCard.shapeLabel(t)),
              if (effects.isNotEmpty) _Fact(Icons.animation, 'Effects', effects.join(' · ')),
              if (t.transition != 'cut') _Fact(Icons.compare_arrows, 'Transitions', _transitionName(t.transition)),
              if (t.texts.isNotEmpty)
                _Fact(Icons.title, 'Titles', '${t.texts.map((x) => '"${x.content}"').join(', ')} — tap to change'),
              if (t.musicId != null)
                _Fact(Icons.music_note_outlined, 'Music',
                    '${_musicTitle(t.musicId!)} — ${t.duckMusic ? 'dips under voices' : 'faded at the end'}'),
              const SizedBox(height: 8),
              const Text('Everything stays editable after — it becomes a normal project.',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  onUse(t);
                },
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text('Pick ${t.suggestedClips} clips'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  static String _transitionName(String id) =>
      transitionOptions.where((o) => o.id == id).firstOrNull?.label ?? id;

  static String _musicTitle(String id) =>
      audioLibrary.where((s) => s.id == id).firstOrNull?.title ??
      bundledAudioLibrary.where((b) => b.id == id).firstOrNull?.title ??
      'Included';
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Fact(this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: AppColors.ember),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$title  ', style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: body, style: const TextStyle(color: AppColors.textDim)),
            ])),
          ),
        ]),
      );
}

/// The template's slots as a row of blocks sized by length, with a dot on
/// slots that have an effect — a quick picture of the edit's rhythm.
class _Storyboard extends StatelessWidget {
  final VideoTemplate template;
  final double height;
  final bool showLengths;

  /// White blocks, for drawing on a coloured card.
  final bool light;
  const _Storyboard({required this.template, required this.height, this.showLengths = false, this.light = false});

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : template.mode.color;
    final slots = template.slotsMs;
    return SizedBox(
      height: height,
      child: Row(children: [
        for (var i = 0; i < slots.length; i++)
          Expanded(
            flex: slots[i],
            child: Container(
              margin: EdgeInsets.only(right: i == slots.length - 1 ? 0 : 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18 + 0.5 * (i.isEven ? 1 : 0.6)),
                borderRadius: BorderRadius.circular(light ? 3 : 6),
              ),
              alignment: Alignment.center,
              child: showLengths
                  ? Text('${(slots[i] / 1000).toStringAsFixed(slots[i] % 1000 == 0 ? 0 : 1)}s',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink))
                  : (template.effects.isNotEmpty && template.effects[i % template.effects.length] != null)
                      ? Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                        )
                      : null,
            ),
          ),
      ]),
    );
  }
}
