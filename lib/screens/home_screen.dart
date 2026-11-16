import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../app/app_theme.dart';
import '../app/launch_gate.dart' show appPrefsProvider;
import '../app/onboarding_screen.dart';
import '../data/database_provider.dart';
import '../data/project_database.dart';
import '../models/edit_mode.dart';
import '../photo/photo_renderer.dart' show readImageSize;
import '../router/app_router.dart';
import '../services/media_import_service.dart';
import '../services/permission_service.dart';
import '../models/video_template.dart';
import '../services/analytics_service.dart';
import '../services/sample_project_service.dart';
import '../services/template_service.dart';
import '../widgets/audio_projects_row.dart';
import '../widgets/audio_studio_start.dart';
import '../widgets/brand/clipforge_logo.dart';
import '../widgets/common/state_views.dart';
import '../widgets/common/ui_kit.dart';
import '../widgets/templates_section.dart';

/// Everything Home lists, loaded together so the screen settles in one frame.
typedef _HomeData = ({List<Project> projects, Map<String, String> covers, String? lastId});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<_HomeData> _data = _load();
  bool _isLoadingSample = false;
  bool _isImportingPhoto = false;
  String? _buildingTemplateId;

  /// Templates: pick media, build the project, open it.
  Future<void> _useTemplate(VideoTemplate t) async {
    if (_buildingTemplateId != null) return;
    setState(() => _buildingTemplateId = t.id);
    try {
      final media = await MediaImportService().pickMultipleMedia(limit: 20);
      if (media.isEmpty) return;
      final id = await TemplateService(ref.read(projectDatabaseProvider)).create(t, media);
      Analytics.instance.log('template_used', {'template': t.id, 'clips': media.length});
      if (mounted) await _open(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't build that template: $e")));
      }
    } finally {
      if (mounted) setState(() => _buildingTemplateId = null);
    }
  }

  @override
  void initState() {
    super.initState();
    // Ask up front so the picker in the Editor never stalls on a
    // mid-flow permission dialog. permission_handler only supports
    // Android/iOS — skip on desktop/web so those platforms don't
    // crash on startup; they don't need a runtime prompt anyway.
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PermissionService.requestMediaPermissions();
      });
    }
  }

  Future<_HomeData> _load() async {
    final db = ref.read(projectDatabaseProvider);
    final projects = [...await db.allProjects()]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final covers = await db.projectCoverThumbnails();
    final lastId = await ref.read(appPrefsProvider).lastProjectId;
    return (projects: projects, covers: covers, lastId: lastId);
  }

  void _refresh() {
    if (!mounted) return;
    // Block body: an arrow here would return the Future to setState, which
    // throws ("setState() callback argument returned a Future") and leaves
    // Home stale after every editor visit / rename / delete.
    setState(() {
      _data = _load();
    });
  }

  // --- Actions --------------------------------------------------------------

  Future<void> _createProject(EditMode mode) async {
    final db = ref.read(projectDatabaseProvider);
    final id = const Uuid().v4();
    final now = DateTime.now();
    await db.insertProject(
      ProjectsCompanion.insert(
        id: id,
        name: switch (mode) {
          EditMode.youtube => 'New YouTube video',
          EditMode.insta => 'New Insta clip',
          EditMode.normal => 'Untitled project',
        },
        mode: Value(mode.name),
        aspectRatio: Value(mode.lockedAspect ?? 9 / 16),
        createdAt: now,
        updatedAt: now,
      ),
    );
    Analytics.instance.log('project_created', {'mode': mode.name});
    if (mounted) await _open(id);
  }

  /// Photo Studio: pick a photo, copy it into app storage (the original in
  /// the gallery is never touched) and open the photo editor.
  Future<void> _newPhoto() async {
    if (_isImportingPhoto) return;
    setState(() => _isImportingPhoto = true);
    try {
      final asset = await MediaImportService().pickPhoto();
      if (asset == null) return;
      final size = await readImageSize(asset.uri);
      final now = DateTime.now();
      final id = const Uuid().v4();
      await ref.read(projectDatabaseProvider).insertPhotoProject(PhotoProjectsCompanion.insert(
            id: id,
            name: 'Photo ${_date(now)}',
            sourceUri: asset.uri,
            width: Value(size.width),
            height: Value(size.height),
            createdAt: now,
            updatedAt: now,
          ));
      if (mounted) await Navigator.pushNamed(context, AppRouter.photo, arguments: id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn\'t open that photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImportingPhoto = false);
    }
  }

  static String _date(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _deletePhoto(PhotoProject photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this edit?'),
        content: const Text('Your original photo in the gallery is not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await ref.read(projectDatabaseProvider).deletePhotoProject(photo.id);
  }

  /// P2 (`docs/FEATURE_PLAN_25.md` §1): debug-only fixture, so every
  /// feature from here on can be tried in seconds without hand-picking
  /// media from the gallery first. See `sample_project_service.dart`.
  Future<void> _loadSampleProject() async {
    if (_isLoadingSample) return;
    setState(() => _isLoadingSample = true);
    try {
      final id = await SampleProjectService(ref.read(projectDatabaseProvider)).create();
      if (mounted) await _open(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load the sample project: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSample = false);
    }
  }

  Future<void> _open(String id) async {
    await Navigator.pushNamed(context, AppRouter.editor, arguments: id);
    _refresh(); // new thumbnail / "edited …" after editing
  }

  void _showTutorial() {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => OnboardingScreen(onFinished: () => Navigator.of(ctx).pop()),
    ));
  }

  Future<void> _rename(Project project) async {
    final controller = TextEditingController(text: project.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Project name'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Rename')),
        ],
      ),
    );
    controller.dispose();
    final trimmed = newName?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == project.name) return;
    await ref.read(projectDatabaseProvider).renameProject(project.id, trimmed);
    _refresh();
  }

  Future<void> _duplicate(Project project) async {
    final newId = await ref.read(projectDatabaseProvider).duplicateProject(project.id);
    if (!mounted || newId == null) return;
    _refresh();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Duplicated "${project.name}"')));
  }

  Future<void> _delete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('"${project.name}" and everything in it will be permanently deleted. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(projectDatabaseProvider).deleteProjectCascade(project.id);
    final prefs = ref.read(appPrefsProvider);
    if (await prefs.lastProjectId == project.id) await prefs.setLastProjectId(null);
    _refresh();
  }

  Widget _projectMenu(Project project) {
    return PopupMenuButton<_ProjectAction>(
      tooltip: 'Project options',
      icon: const Icon(Icons.more_horiz, color: AppColors.textDim, size: 20),
      padding: EdgeInsets.zero,
      onSelected: (action) => switch (action) {
        _ProjectAction.rename => _rename(project),
        _ProjectAction.duplicate => _duplicate(project),
        _ProjectAction.delete => _delete(project),
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _ProjectAction.rename, child: Text('Rename')),
        PopupMenuItem(value: _ProjectAction.duplicate, child: Text('Duplicate')),
        PopupMenuItem(value: _ProjectAction.delete, child: Text('Delete')),
      ],
    );
  }

  static String _when(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    if (d.inDays < 7) return '${d.inDays} d ago';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  // --- Layout ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_HomeData>(
          future: _data,
          builder: (context, snap) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
                    child: Row(children: [
                      // Scales down instead of overflowing on narrow phones / big text.
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(fit: BoxFit.scaleDown, child: ClipForgeLogo(height: 26)),
                        ),
                      ),
                      if (kDebugMode)
                        IconButton(
                          icon: _isLoadingSample
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.bug_report_outlined, color: AppColors.textFaint),
                          tooltip: 'Load sample project',
                          onPressed: _isLoadingSample ? null : _loadSampleProject,
                        ),
                      IconButton(
                        icon: const Icon(Icons.help_outline_rounded, color: AppColors.textDim),
                        tooltip: 'How it works',
                        onPressed: _showTutorial,
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: AppColors.textDim),
                        tooltip: 'Settings',
                        onPressed: () => Navigator.pushNamed(context, AppRouter.settings),
                      ),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
                    child: Text('What are we\nmaking today?', style: theme.textTheme.headlineMedium?.copyWith(height: 1.1)),
                  ),
                ),
                const SliverToBoxAdapter(child: SectionHeader('Start a video')),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(children: [
                      _YoutubeHeroCard(onTap: () => _createProject(EditMode.youtube)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _ModeCard(mode: EditMode.insta, onTap: () => _createProject(EditMode.insta))),
                        const SizedBox(width: 12),
                        Expanded(child: _ModeCard(mode: EditMode.normal, onTap: () => _createProject(EditMode.normal))),
                      ]),
                      const SizedBox(height: 12),
                      _PhotoStudioCard(busy: _isImportingPhoto, onTap: _newPhoto),
                      const SizedBox(height: 12),
                      AudioStudioCard(onTap: () => showAudioStudioStart(context, ref)),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SectionHeader('Discover',
                      trailing: Text('Pick a style, add your clips', style: TextStyle(color: AppColors.textFaint, fontSize: 12))),
                ),
                SliverToBoxAdapter(child: DiscoverSection(onUse: _useTemplate, busyId: _buildingTemplateId)),
                ..._projectSlivers(snap),
                _photoSliver(),
                const SliverToBoxAdapter(child: AudioProjectsSection()),
                // SafeArea(bottom: false) lets the list run edge-to-edge, so the
                // last row needs the nav-bar inset itself or it ends up under it.
                SliverToBoxAdapter(child: SizedBox(height: 32 + MediaQuery.paddingOf(context).bottom)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _projectSlivers(AsyncSnapshot<_HomeData> snap) {
    if (snap.hasError) {
      return [
        SliverToBoxAdapter(
          child: ErrorStateView(message: 'Couldn\'t load your projects: ${snap.error}', onRetry: _refresh),
        ),
      ];
    }
    final data = snap.data;
    if (data == null) {
      return const [SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: LoadingStateView()))];
    }
    final projects = data.projects;
    final resume = projects.where((p) => p.id == data.lastId).firstOrNull;
    return [
      if (resume != null) ...[
        const SliverToBoxAdapter(child: SectionHeader('Pick up where you left off')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: _ResumeCard(
              project: resume,
              cover: data.covers[resume.id],
              subtitle: 'Edited ${_when(resume.updatedAt)}',
              menu: _projectMenu(resume),
              onTap: () => _open(resume.id),
            ),
          ),
        ),
      ],
      SliverToBoxAdapter(
        child: SectionHeader(
          'Your videos',
          trailing: projects.isEmpty
              ? null
              : Text('${projects.length}', style: const TextStyle(color: AppColors.textFaint)),
        ),
      ),
      if (projects.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _EmptyProjects(),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            delegate: SliverChildBuilderDelegate(
              childCount: projects.length,
              (context, i) {
                final p = projects[i];
                return _ProjectTile(
                  project: p,
                  cover: data.covers[p.id],
                  subtitle: _when(p.updatedAt),
                  menu: _projectMenu(p),
                  onTap: () => _open(p.id),
                );
              },
            ),
          ),
        ),
    ];
  }

  Widget _photoSliver() {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<PhotoProject>>(
        stream: ref.watch(projectDatabaseProvider).watchPhotoProjects(),
        builder: (context, snap) {
          final photos = snap.data ?? const <PhotoProject>[];
          if (photos.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader('Your photos', trailing: Text('Hold to delete', style: TextStyle(color: AppColors.textFaint, fontSize: 12))),
            SizedBox(
              height: 116,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final photo = photos[i];
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRouter.photo, arguments: photo.id),
                    onLongPress: () => _deletePhoto(photo),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Image.file(
                        File(photo.sourceUri),
                        width: 116,
                        height: 116,
                        fit: BoxFit.cover,
                        cacheWidth: 232,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(width: 116, height: 116, child: ColoredBox(color: AppColors.surfaceHigh)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// --- Cards --------------------------------------------------------------------

class _YoutubeHeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _YoutubeHeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const mode = EditMode.youtube;
    return TapCard(
      onTap: onTap,
      radius: AppRadii.lg,
      padding: EdgeInsets.zero,
      borderColor: mode.color.withValues(alpha: 0.35),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [mode.color.withValues(alpha: 0.20), AppColors.surface, AppColors.surface],
            stops: const [0, 0.55, 1],
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            _ModeIcon(mode: mode, size: 44),
            Spacer(),
            ProBadge(),
          ]),
          const SizedBox(height: 16),
          Text(mode.label, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 3),
          Text(mode.tagline, style: const TextStyle(color: AppColors.textDim)),
          const SizedBox(height: 14),
          const Wrap(spacing: 6, runSpacing: 6, children: [
            _FeatureTag('Jump cuts'),
            _FeatureTag('Chapters'),
            _FeatureTag('Loudness'),
            _FeatureTag('Captions'),
            _FeatureTag('4K export'),
          ]),
        ]),
      ),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  final String text;
  const _FeatureTag(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDim)),
      );
}

class _ModeIcon extends StatelessWidget {
  final EditMode mode;
  final double size;
  const _ModeIcon({required this.mode, this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: mode.color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(mode.icon, color: mode.color, size: size * 0.5),
      );
}

class _ModeCard extends StatelessWidget {
  final EditMode mode;
  final VoidCallback onTap;
  const _ModeCard({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapCard(
      onTap: onTap,
      radius: AppRadii.lg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _ModeIcon(mode: mode),
        const SizedBox(height: 22),
        Text(mode.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(mode.tagline,
            maxLines: 2, style: const TextStyle(color: AppColors.textDim, fontSize: 12.5, height: 1.3)),
      ]),
    );
  }
}

class _PhotoStudioCard extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;
  const _PhotoStudioCard({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapCard(
      onTap: busy ? null : onTap,
      radius: AppRadii.lg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.photo.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.photo),
                )
              : const Icon(Icons.photo_outlined, color: AppColors.photo, size: 20),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Photo Studio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('Tune, looks and crop a single photo', style: TextStyle(color: AppColors.textDim, fontSize: 12.5)),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textFaint),
      ]),
    );
  }
}

class _Cover extends StatelessWidget {
  final String? path;
  final EditMode mode;
  const _Cover({required this.path, required this.mode});

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: mode.color.withValues(alpha: 0.10),
      child: Center(child: Icon(mode.icon, color: mode.color.withValues(alpha: 0.7))),
    );
    final p = path;
    if (p == null) return fallback;
    return Image.file(File(p), fit: BoxFit.cover, cacheWidth: 400, errorBuilder: (_, __, ___) => fallback);
  }
}

class _ResumeCard extends StatelessWidget {
  final Project project;
  final String? cover;
  final String subtitle;
  final Widget menu;
  final VoidCallback onTap;
  const _ResumeCard({
    required this.project,
    required this.cover,
    required this.subtitle,
    required this.menu,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mode = EditMode.fromName(project.mode);
    return TapCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: SizedBox(width: 88, height: 60, child: _Cover(path: cover, mode: mode)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(project.name,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [
              ModeChip(mode, dense: true),
              const SizedBox(width: 8),
              Flexible(
                child: Text(subtitle,
                    overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
              ),
            ]),
          ]),
        ),
        menu,
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: AppColors.ember, shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF1A0E08)),
        ),
      ]),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  final String? cover;
  final String subtitle;
  final Widget menu;
  final VoidCallback onTap;
  const _ProjectTile({
    required this.project,
    required this.cover,
    required this.subtitle,
    required this.menu,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mode = EditMode.fromName(project.mode);
    return TapCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            _Cover(path: cover, mode: mode),
            Positioned(left: 8, top: 8, child: ModeChip(mode, dense: true)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 0, 6),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5)),
              ]),
            ),
            menu,
          ]),
        ),
      ]),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.line),
        ),
        child: const Row(children: [
          InfinityMark(size: 44, background: AppColors.ink),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'No videos yet. Pick a mode above, then tap + in the editor to bring in your first clip.',
              style: TextStyle(color: AppColors.textDim, height: 1.35),
            ),
          ),
        ]),
      );
}

enum _ProjectAction { rename, duplicate, delete }
