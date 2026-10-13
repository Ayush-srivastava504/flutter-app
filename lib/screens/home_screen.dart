import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/launch_gate.dart' show appPrefsProvider;
import '../data/database_provider.dart';
import '../data/project_database.dart';
import '../router/app_router.dart';
import '../services/permission_service.dart';
import '../services/sample_project_service.dart';
import '../widgets/common/state_views.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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

  Future<void> _createProject() async {
    final db = ref.read(projectDatabaseProvider);
    final id = const Uuid().v4();
    final now = DateTime.now();

    await db.insertProject(
      ProjectsCompanion.insert(
        id: id,
        name: 'Untitled Project',
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (mounted) {
      Navigator.pushNamed(context, AppRouter.editor, arguments: id);
    }
  }

  bool _isLoadingSample = false;

  /// P2 (`docs/FEATURE_PLAN_25.md` §1): debug-only fixture, so every
  /// feature from here on can be tried in seconds without hand-picking
  /// media from the gallery first. See `sample_project_service.dart`.
  Future<void> _loadSampleProject() async {
    if (_isLoadingSample) return;
    setState(() => _isLoadingSample = true);
    try {
      final id = await SampleProjectService(ref.read(projectDatabaseProvider)).create();
      if (mounted) {
        Navigator.pushNamed(context, AppRouter.editor, arguments: id);
      }
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
    if (mounted) setState(() {}); // refresh "Updated …" after editing
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = newName?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == project.name) return;

    await ref.read(projectDatabaseProvider).renameProject(project.id, trimmed);
    if (mounted) setState(() {});
  }

  Future<void> _duplicate(Project project) async {
    final newId = await ref.read(projectDatabaseProvider).duplicateProject(project.id);
    if (!mounted || newId == null) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicated "${project.name}"')),
    );
  }

  Future<void> _delete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('"${project.name}" and everything in it will be permanently deleted. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
    if (await prefs.lastProjectId == project.id) {
      await prefs.setLastProjectId(null);
    }
    if (mounted) setState(() {});
  }

  Widget _projectMenu(Project project) {
    return PopupMenuButton<_ProjectAction>(
      tooltip: 'Project options',
      onSelected: (action) {
        switch (action) {
          case _ProjectAction.rename:
            _rename(project);
            break;
          case _ProjectAction.duplicate:
            _duplicate(project);
            break;
          case _ProjectAction.delete:
            _delete(project);
            break;
        }
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

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(projectDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: _isLoadingSample
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bug_report_outlined),
              tooltip: 'Load sample project',
              onPressed: _isLoadingSample ? null : _loadSampleProject,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProject,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: FutureBuilder<List<Project>>(
        future: db.allProjects(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorStateView(
              message: 'Couldn\'t load your projects: ${snapshot.error}',
              onRetry: () => setState(() {}),
            );
          }
          if (!snapshot.hasData) {
            return const LoadingStateView();
          }
          final projects = [...snapshot.data!]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          if (projects.isEmpty) {
            return EmptyStateView(
              icon: Icons.video_library_outlined,
              title: 'No projects yet',
              message: 'Create a project to start trimming, adding music and text, and exporting.',
              actionLabel: 'New project',
              onAction: _createProject,
            );
          }
          return FutureBuilder<String?>(
            future: ref.read(appPrefsProvider).lastProjectId,
            builder: (context, lastSnap) {
              final lastId = lastSnap.data;
              final resumable = projects.where((p) => p.id == lastId).toList();
              return ListView.builder(
                itemCount: projects.length + (resumable.isEmpty ? 0 : 1),
                itemBuilder: (context, index) {
                  if (resumable.isNotEmpty && index == 0) {
                    return Card(
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text('Resume “${resumable.first.name}”'),
                        subtitle: const Text('Pick up where you left off'),
                        trailing: _projectMenu(resumable.first),
                        onTap: () => _open(resumable.first.id),
                      ),
                    );
                  }
                  final project = projects[index - (resumable.isEmpty ? 0 : 1)];
                  return ListTile(
                    leading: const Icon(Icons.movie_outlined),
                    title: Text(project.name),
                    subtitle: Text('Updated ${_when(project.updatedAt)}'),
                    trailing: _projectMenu(project),
                    onTap: () => _open(project.id),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

enum _ProjectAction { rename, duplicate, delete }
