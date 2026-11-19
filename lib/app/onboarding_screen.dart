import 'package:flutter/material.dart';

import '../models/edit_mode.dart';
import '../widgets/brand/clipforge_logo.dart';
import '../widgets/common/ui_kit.dart';
import 'app_theme.dart';

/// First-run tutorial: what ClipForge is, the three editor modes, a map of
/// the editor screen, how a video gets made, and the Pro toolkit. Shown once
/// on first launch ([LaunchGate]) and again from Home's "How it works".
/// [onFinished] fires on Skip or on the last page's button.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pageCount = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _pageCount - 1) {
      widget.onFinished();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pageCount - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(children: [
              Text('${_index + 1} / $_pageCount',
                  style: const TextStyle(color: AppColors.textFaint, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (!last) TextButton(onPressed: widget.onFinished, child: const Text('Skip')),
            ]),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: const [
                _WelcomePage(),
                _ModesPage(),
                _EditorMapPage(),
                _WorkflowPage(),
                _ProPage(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Row(children: [
              for (var i = 0; i < _pageCount; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.only(right: 6),
                  width: i == _index ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i == _index ? AppColors.ember : AppColors.surfaceTop,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _next,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(last ? 'Start editing' : 'Next', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Title + body + content, the same layout on every page.
class _PageFrame extends StatelessWidget {
  final String kicker;
  final String title;
  final String body;
  final Widget child;
  const _PageFrame({required this.kicker, required this.title, required this.body, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      children: [
        Text(kicker.toUpperCase(),
            style:
                const TextStyle(color: AppColors.ember, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(body, style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textDim, height: 1.4)),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}

// --- 1. Welcome ---------------------------------------------------------------

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Centred on tall screens, scrollable on short ones (or with big text).
    return LayoutBuilder(builder: (context, c) {
      final short = c.maxHeight < 560;
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight - 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The mark draws itself once, like a pen stroke.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeInOutCubic,
                builder: (_, v, __) => InfinityMark(size: short ? 104 : 150, progress: v),
              ),
              SizedBox(height: short ? 20 : 36),
              Text('Make videos\nthat keep going.', style: theme.textTheme.headlineMedium?.copyWith(height: 1.1)),
              const SizedBox(height: 14),
              Text(
                'Cliper is a full video, photo and audio studio that lives on your phone. '
                'No account, no watermark, and it works without internet.',
                style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textDim, height: 1.45),
              ),
              const SizedBox(height: 28),
              const Wrap(spacing: 8, runSpacing: 8, children: [
                _Pill(Icons.wifi_off_rounded, 'Works offline'),
                _Pill(Icons.lock_outline_rounded, 'Private'),
                _Pill(Icons.high_quality_outlined, 'Up to 4K'),
                _Pill(Icons.auto_awesome_mosaic_outlined, 'Templates'),
              ]),
            ],
          ),
        ),
      );
    });
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: AppColors.textDim),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );
}

// --- 2. Modes -----------------------------------------------------------------

class _ModesPage extends StatelessWidget {
  const _ModesPage();

  static const _detail = {
    EditMode.youtube: 'For long videos. Locks the frame to 16:9 and adds the Pro toolkit: '
        'jump cuts, scene split, loudness balance, chapters, captions and music ducking.',
    EditMode.insta: 'For Reels and Shorts. Locks the frame to vertical 9:16 so nothing you '
        'import ends up letterboxed.',
    EditMode.normal: 'The classic editor. Your first video decides the frame shape, and you can '
        'change it any time.',
  };

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      kicker: 'Three ways to edit',
      title: 'Pick the mode that fits the video',
      body: 'You choose a mode when you start a project — or start from a template on Home, '
          'which picks the mode for you. All three share the same timeline, looks, effects, text and music.',
      child: Column(children: [
        for (final m in EditMode.values) ...[
          _ModeExplainer(mode: m, detail: _detail[m]!),
          const SizedBox(height: 12),
        ],
      ]),
    );
  }
}

class _ModeExplainer extends StatelessWidget {
  final EditMode mode;
  final String detail;
  const _ModeExplainer({required this.mode, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _FrameGlyph(mode: mode),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(mode.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              if (mode.isPro) ...[const SizedBox(width: 8), const ProBadge()],
            ]),
            const SizedBox(height: 4),
            Text(detail, style: const TextStyle(color: AppColors.textDim, fontSize: 13, height: 1.35)),
          ]),
        ),
      ]),
    );
  }
}

/// A small outline of the mode's frame shape (16:9, 9:16, or "any").
class _FrameGlyph extends StatelessWidget {
  final EditMode mode;
  const _FrameGlyph({required this.mode});

  @override
  Widget build(BuildContext context) {
    final aspect = mode.lockedAspect;
    final (w, h) = aspect == null ? (30.0, 30.0) : (aspect > 1 ? (44.0, 25.0) : (22.0, 38.0));
    return SizedBox(
      width: 48,
      height: 44,
      child: Center(
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: mode.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: mode.color, width: 1.6),
          ),
          child: Icon(mode.icon, size: 15, color: mode.color),
        ),
      ),
    );
  }
}

// --- 3. Editor map ------------------------------------------------------------

class _EditorMapPage extends StatelessWidget {
  const _EditorMapPage();

  @override
  Widget build(BuildContext context) {
    return const _PageFrame(
      kicker: 'Find your way',
      title: 'The editor, in four parts',
      body: 'Everything you do is saved as you go, and the undo button reverses any step.',
      child: Column(children: [
        _EditorSketch(),
        SizedBox(height: 18),
        _Legend(1, 'Preview', 'Plays what the export will look like. Drag the bar under it to scrub.'),
        _Legend(
            2, 'Clips', 'Tap a clip to trim, split, speed it up or give it a look. Drag a clip sideways to reorder.'),
        _Legend(3, 'Music & text', 'Tap a lane to add a song or a title, then tap it again to edit.'),
        _Legend(
            4, 'Tool dock', 'Add media, text, music, voice-over and captions — and in YouTube Studio, the Pro tools.'),
      ]),
    );
  }
}

/// A hand-built miniature of the editor with numbered regions.
class _EditorSketch extends StatelessWidget {
  const _EditorSketch();

  @override
  Widget build(BuildContext context) {
    Widget bar(Color c, {double h = 14, double? w}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(children: [
        Stack(children: [
          Container(
            height: 120,
            decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Container(
                width: 150,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3A2A24), Color(0xFF23303A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: AppColors.text, size: 30),
              ),
            ),
          ),
          const Positioned(left: 8, top: 8, child: _Num(1)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const _Num(2),
          const SizedBox(width: 8),
          for (final f in [3, 2, 4])
            Expanded(
              flex: f,
              child: Container(
                height: 30,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTop,
                  borderRadius: BorderRadius.circular(5),
                  border: f == 2 ? Border.all(color: AppColors.ember, width: 1.5) : null,
                ),
              ),
            ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const _Num(3),
          const SizedBox(width: 8),
          Expanded(
            child: Column(children: [
              bar(AppColors.normal.withValues(alpha: 0.35)),
              const SizedBox(height: 4),
              Row(children: [
                const Spacer(flex: 2),
                Expanded(flex: 3, child: bar(AppColors.insta.withValues(alpha: 0.4), h: 10)),
                const Spacer(flex: 4),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const _Num(4),
          const SizedBox(width: 8),
          for (final i in [
            Icons.add,
            Icons.title,
            Icons.music_note_outlined,
            Icons.subtitles_outlined,
            Icons.auto_awesome
          ])
            Expanded(child: Icon(i, size: 18, color: AppColors.textDim)),
        ]),
      ]),
    );
  }
}

class _Num extends StatelessWidget {
  final int n;
  const _Num(this.n);

  @override
  Widget build(BuildContext context) => Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.ember, shape: BoxShape.circle),
        child: Text('$n', style: const TextStyle(color: Color(0xFF1A0E08), fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

class _Legend extends StatelessWidget {
  final int n;
  final String title;
  final String body;
  const _Legend(this.n, this.title, this.body);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Num(n),
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

// --- 4. Workflow --------------------------------------------------------------

class _WorkflowPage extends StatelessWidget {
  const _WorkflowPage();

  @override
  Widget build(BuildContext context) {
    return const _PageFrame(
      kicker: 'How a video gets made',
      title: 'Four steps, start to share',
      body: 'Nothing touches your original files. Every cut and colour change is just a note '
          'the export follows.',
      child: Column(children: [
        _Step(1, Icons.add_photo_alternate_outlined, 'Bring in your clips',
            'Tap + to add videos, photos or an .srt subtitle file. They land on the timeline in order.'),
        _Step(2, Icons.content_cut, 'Shape each clip',
            'Tap a clip. Edit trims, splits and speeds it up; Filters gives it a look; Effects adds zoom, shake, VHS and more.'),
        _Step(3, Icons.music_note_outlined, 'Add music, voice and words',
            'Pick a song, record a voice-over with Voice, and add titles you can drag around the preview.'),
        _Step(4, Icons.ios_share_outlined, 'Export',
            'Choose 480p up to 4K at 24, 30 or 60 fps. The video saves to your gallery, ready to post.',
            last: true),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final IconData icon;
  final String title;
  final String body;
  final bool last;
  const _Step(this.n, this.icon, this.title, this.body, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Column(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(icon, size: 20, color: AppColors.ember),
          ),
          if (!last)
            Expanded(
              child: Container(width: 1.5, margin: const EdgeInsets.symmetric(vertical: 4), color: AppColors.line),
            ),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 18, top: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Step $n · $title', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(color: AppColors.textDim, height: 1.35)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// --- 5. Pro + assistant -------------------------------------------------------

class _ProPage extends StatelessWidget {
  const _ProPage();

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      kicker: 'YouTube Studio',
      title: 'Tools that save you an evening',
      body: 'These live in the Pro dock of YouTube Studio projects. Each one is a normal edit, '
          'so undo takes it back.',
      child: Column(children: [
        // Rows that size to their content (not a fixed-aspect grid), so
        // long text or a large system font can never overflow a tile.
        const _TileRow(
          _ProTile(Icons.record_voice_over_outlined, 'Enhance speech', 'Cleans noise and makes voices clear and even'),
          _ProTile(Icons.graphic_eq, 'Jump cuts', 'Removes the silent pauses from talking clips'),
        ),
        const _TileRow(
          _ProTile(Icons.movie_filter_outlined, 'Scene split', 'Cuts a long clip wherever the shot changes'),
          _ProTile(Icons.equalizer, 'Loudness', 'Evens out volume between clips'),
        ),
        const _TileRow(
          _ProTile(Icons.format_list_numbered, 'Chapters', 'Timestamps ready for your description'),
          _ProTile(Icons.grid_on_outlined, 'Safe zones', 'Thirds and title-safe lines on the preview'),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.line),
          ),
          child: const Row(children: [
            Icon(Icons.auto_awesome, color: AppColors.ember),
            SizedBox(width: 12),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: 'In every mode: ', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(
                  text: 'tap ✨ and type what you want, like "speed up 2x and make it black and white".',
                  style: TextStyle(color: AppColors.textDim),
                ),
              ])),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TileRow extends StatelessWidget {
  final Widget a;
  final Widget b;
  const _TileRow(this.a, this.b);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: a),
            const SizedBox(width: 10),
            Expanded(child: b),
          ]),
        ),
      );
}

class _ProTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _ProTile(this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: AppColors.pro),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(color: AppColors.textDim, fontSize: 11.5, height: 1.25)),
        ]),
      );
}
