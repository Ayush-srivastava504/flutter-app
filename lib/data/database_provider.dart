import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'project_database.dart';

/// Single shared database instance for the app's lifetime.
final projectDatabaseProvider = Provider<ProjectDatabase>((ref) {
  final db = ProjectDatabase();
  ref.onDispose(db.close);
  return db;
});
