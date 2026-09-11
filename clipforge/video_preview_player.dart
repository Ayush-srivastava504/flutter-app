import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'project_database.g.dart';

/// A Project is the top-level container for one editing session.
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get aspectRatio => real().withDefault(const Constant(9 / 16))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ordered clips on the timeline. Non-destructive: sourceUri always points
/// at the original imported media; trimStart/trimEnd/order are metadata
/// only and are combined at export time, never baked into the source file.
class Clips extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get sourceUri => text()();
  IntColumn get orderIndex => integer()();
  IntColumn get trimStartMs => integer().withDefault(const Constant(0))();
  IntColumn get trimEndMs => integer()();
  IntColumn get durationMs => integer()();
  TextColumn get transitionOut =>
      text().withDefault(const Constant('cut'))(); // cut | fade | dissolve
  RealColumn get brightness => real().withDefault(const Constant(0))();
  RealColumn get contrast => real().withDefault(const Constant(0))();
  RealColumn get saturation => real().withDefault(const Constant(0))();
  BoolColumn get muted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A single background-music track aligned against the video timeline.
class AudioTracks extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get sourceUri => text()();
  IntColumn get trimStartMs => integer().withDefault(const Constant(0))();
  IntColumn get trimEndMs => integer()();
  IntColumn get offsetMs => integer().withDefault(const Constant(0))();
  RealColumn get volume => real().withDefault(const Constant(1.0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A text overlay positioned on the preview canvas with its own timing.
class TextOverlays extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get content => text()();
  TextColumn get fontFamily => text().withDefault(const Constant('Default'))();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFFFFFFFF))();
  RealColumn get fontSize => real().withDefault(const Constant(24))();
  RealColumn get positionX => real().withDefault(const Constant(0.5))();
  RealColumn get positionY => real().withDefault(const Constant(0.5))();
  IntColumn get startMs => integer().withDefault(const Constant(0))();
  IntColumn get endMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Projects, Clips, AudioTracks, TextOverlays])
class ProjectDatabase extends _$ProjectDatabase {
  ProjectDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // --- Query helpers -------------------------------------------------

  Future<List<Project>> allProjects() => select(projects).get();

  Future<int> insertProject(ProjectsCompanion project) =>
      into(projects).insert(project);

  Stream<List<Clip>> watchClips(String projectId) =>
      (select(clips)
            ..where((c) => c.projectId.equals(projectId))
            ..orderBy([(c) => OrderingTerm.asc(c.orderIndex)]))
          .watch();

  Future<int> insertClip(ClipsCompanion clip) => into(clips).insert(clip);

  Future<bool> updateClip(ClipsCompanion clip) => update(clips).replace(clip);

  Future<int> deleteClip(String id) =>
      (delete(clips)..where((c) => c.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'project_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
