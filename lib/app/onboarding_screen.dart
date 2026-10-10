import 'package:flutter/material.dart';

/// Three-page first-run intro. [onFinished] fires on Skip or on the last page's Get started.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = <_Page>[
    _Page(Icons.video_library_outlined, 'Bring your clips',
        'Import videos and photos, then trim, split and reorder them on the timeline.'),
    _Page(Icons.auto_awesome_outlined, 'Make it yours',
        'Add music, text, filters and transitions. Everything previews live as you edit.'),
    _Page(Icons.ios_share_outlined, 'Export & share',
        'Render in 720p or 1080p, save to your gallery and share — your edits are saved automatically.'),
  ];

  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _pages.length - 1) {
      widget.onFinished();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: widget.onFinished, child: const Text('Skip')),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                for (final pg in _pages)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(pg.icon, size: 96, color: theme.colorScheme.primary),
                      const SizedBox(height: 32),
                      Text(pg.title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text(pg.body,
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                          textAlign: TextAlign.center),
                    ]),
                  ),
              ],
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < _pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: i == _index ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i == _index ? theme.colorScheme.primary : Colors.white24,
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _next, child: Text(last ? 'Get started' : 'Next')),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Page {
  final IconData icon;
  final String title;
  final String body;
  const _Page(this.icon, this.title, this.body);
}
