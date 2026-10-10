import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/launch_gate.dart' show appPrefsProvider;
import '../data/database_provider.dart';
import '../data/project_database.dart';
import '../router/app_router.dart';
import '../services/permission_service.dart';
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

  Future<void> _open(String id) async {
    await Navigator.pushNamed(context, AppRouter.editor, arguments: id);
    if (mounted) setState(() {}); // refresh "Updated …" after editing
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
      appBar: AppBar(title: const Text('My Projects')),
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
                        onTap: () => _open(resumable.first.id),
                      ),
                    );
                  }
                  final project = projects[index - (resumable.isEmpty ? 0 : 1)];
                  return ListTile(
                    leading: const Icon(Icons.movie_outlined),
                    title: Text(project.name),
                    subtitle: Text('Updated ${_when(project.updatedAt)}'),
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
