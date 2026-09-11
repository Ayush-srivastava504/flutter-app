import 'package:drift/drift.dart';
import 'package:video_editor_app/data/project_database.dart'
    show Projects, Clips, AudioTracks;

part 'legacy_v3_database.g.dart';

/// Stand-in for `ProjectDatabase` **as it existed at schema version 3**
/// (end of Phase 5, before this pass's `TextOverlays` migration) —
/// reuses the real `Projects`/`Clips`/`AudioTracks` table definitions
/// (their shape hasn't changed since v3) but leaves `TextOverlays` out
/// entirely, since v3 installs never actually got that table (it was
/// declared but never migrated — see the `from < 4` comment in
/// `ProjectDatabase.migration`).
///
/// Exists purely so `project_database_migration_test.dart` can build a
/// realistic "old install" sqlite file to upgrade from, without
/// hand-writing CREATE TABLE statements that could drift out of sync
/// with the real schema.
@DriftDatabase(tables: [Projects, Clips, AudioTracks])
class LegacyV3Database extends _$LegacyV3Database {
  LegacyV3Database(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 3;
}
