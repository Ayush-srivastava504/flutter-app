import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/data/project_database.dart';

import 'support/legacy_v3_database.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('project_db_migration_test');
    dbFile = File('${tempDir.path}/project_db.sqlite');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'upgrading a real (pre-Phase-6) v3 install creates a usable '
    'TextOverlays table',
    () async {
      // Build a database at the Phase-5 (v3) shape: projects/clips/
      // audio_tracks only, no text_overlays — this is what a real
      // upgrading install looked like before this pass, per the note
      // on `from < 4` in ProjectDatabase.migration ("any real upgrading
      // install would be missing the table entirely").
      final legacyDb = LegacyV3Database(NativeDatabase(dbFile));
      // Force the database to actually open and run its own onCreate,
      // which also stamps the file with schema version 3.
      await legacyDb.customStatement('SELECT 1');
      await legacyDb.close();

      // Reopen with the real (current, v4) ProjectDatabase — this
      // should detect the stored version 3 and run the v3->v4
      // onUpgrade step, creating `textOverlays`.
      final db = ProjectDatabase.forTesting(NativeDatabase(dbFile));

      await db.insertProject(ProjectsCompanion.insert(
        id: 'p1',
        name: 'Upgraded project',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ));

      // If the migration hadn't created the table, this would throw
      // (no such table) instead of succeeding.
      await db.insertTextOverlay(TextOverlaysCompanion.insert(
        id: 't1',
        projectId: 'p1',
        content: 'hello',
        endMs: 1000,
      ));

      final overlays = await db.watchTextOverlays('p1').first;
      expect(overlays, hasLength(1));
      expect(overlays.single.content, 'hello');
      // Confirms the migration's new `alignment` column landed with its
      // documented default (1 = center) rather than erroring or being
      // left null.
      expect(overlays.single.alignment, 1);

      await db.close();
    },
  );

  test('a brand-new (fresh install) database already has TextOverlays', () async {
    // The onCreate path (`createAll()`), exercised separately from the
    // onUpgrade path above so a regression in one doesn't hide behind
    // the other passing.
    final db = ProjectDatabase.forTesting(NativeDatabase(dbFile));

    await db.insertProject(ProjectsCompanion.insert(
      id: 'p1',
      name: 'Fresh project',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ));
    await db.insertTextOverlay(TextOverlaysCompanion.insert(
      id: 't1',
      projectId: 'p1',
      content: 'hello',
      endMs: 1000,
    ));

    final overlay = await db.getTextOverlay('t1');
    expect(overlay, isNotNull);
    expect(overlay!.content, 'hello');

    await db.close();
  });
}
