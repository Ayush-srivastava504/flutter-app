import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database_provider.dart';
import '../data/project_database.dart';
import '../router/app_router.dart';
import '../services/permission_service.dart';

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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final projects = snapshot.data!;
          if (projects.isEmpty) {
            return const Center(
              child: Text(
                'No projects yet.\nTap "New Project" to start editing.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return ListTile(
                leading: const Icon(Icons.movie_outlined),
                title: Text(project.name),
                subtitle: Text('Updated ${project.updatedAt}'),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.editor,
                  arguments: project.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
