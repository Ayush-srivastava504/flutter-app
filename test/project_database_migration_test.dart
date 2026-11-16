import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/data/project_database.dart';

/// Columns each schema version added, newest first, as SQL names. Used to
/// turn a freshly created (current) database file back into an older one:
/// create it with today's schema, drop what was added after the target
/// version, and stamp the older `user_version`. Deriving old shapes from the
/// real schema this way keeps them from drifting out of sync, which a
/// hand-maintained "legacy" table copy did (it silently grew every new
/// column, so the upgrade path was no longer being tested at all).
const Map<int, Map<String, List<String>>> _addedIn = {
  12: {
    'clips': ['key_json'],
  },
  11: {
    'clips': ['effect', 'effect_strength', 'enhance_speech'],
  },
  10: {
    'projects': ['mode'],
  },
  8: {
    'clips': ['look_strength'],
  },
  7: {
    'clips': ['fit_mode'],
    'projects': ['duck_music'],
  },
  6: {
    'clips': ['look', 'turns', 'flip_h', 'flip_v', 'speed'],
    'text_overlays': ['bold', 'box_enabled', 'box_color_value', 'outline_width', 'outline_color_value'],
    'audio_tracks': ['fade_in_ms', 'fade_out_ms'],
  },
  5: {
    'clips': ['filter_preset'],
  },
};

Future<void> _makeOldDatabase(File file, int version, {List<String> seedSql = const []}) async {
  final db = ProjectDatabase.forTesting(NativeDatabase(file));
  await db.customStatement('SELECT 1'); // force onCreate at the current version
  for (var v = db.schemaVersion; v > version; v--) {
    if (v == 13) {
      await db.customStatement('DROP TABLE audio_projects');
      continue;
    }
    if (v == 11) {
      await db.customStatement('DROP TABLE voice_overs');
    }
    if (v == 9) {
      await db.customStatement('DROP TABLE photo_projects');
      continue;
    }
    if (v == 4) {
      // v4 is when text_overlays was first created on upgrading installs.
      await db.customStatement('DROP TABLE text_overlays');
      continue;
    }
    for (final MapEntry(key: table, value: columns) in (_addedIn[v] ?? const {}).entries) {
      if (version < 4 && table == 'text_overlays') continue; // dropped wholesale above
      for (final column in columns) {
        await db.customStatement('ALTER TABLE $table DROP COLUMN $column');
      }
    }
  }
  for (final sql in seedSql) {
    await db.customStatement(sql); // rows in the old shape
  }
  await db.customStatement('PRAGMA user_version = $version');
  await db.close();
}

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('project_db_migration_test');
    dbFile = File('${tempDir.path}/project_db.sqlite');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<void> insertProject(ProjectDatabase db) => db.insertProject(ProjectsCompanion.insert(
        id: 'p1',
        name: 'Upgraded project',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ));

  for (final from in [3, 4, 5, 6, 7, 8, 9, 10, 11, 12]) {
    test('upgrading a v$from install reaches the current schema and every table works', () async {
      await _makeOldDatabase(dbFile, from);

      final db = ProjectDatabase.forTesting(NativeDatabase(dbFile));
      await insertProject(db);
      await db.insertClip(ClipsCompanion.insert(
        id: 'c1',
        projectId: 'p1',
        sourceUri: '/media/a.mp4',
        orderIndex: 0,
        trimEndMs: 4000,
        durationMs: 4000,
      ));
      await db.insertTextOverlay(TextOverlaysCompanion.insert(
        id: 't1',
        projectId: 'p1',
        content: 'hello',
        endMs: 1000,
      ));

      final clip = await db.getClip('c1');
      expect(clip!.fitMode, 'fit', reason: 'v7 column default');
      expect(clip.effect, isNull, reason: 'v11 column');
      expect(clip.effectStrength, 1.0);
      expect(clip.enhanceSpeech, isFalse);
      expect(clip.keyJson, isNull, reason: 'v12 column');
      // v13: the audio studio table exists and works.
      await db.insertAudioProject(AudioProjectsCompanion.insert(
        id: 'au1',
        name: 'Voice memo',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ));
      expect((await db.getAudioProject('au1'))!.editJson, '');
      // v11: the voice-over table exists and is part of undo snapshots.
      await db.insertVoiceOver(VoiceOversCompanion.insert(
        id: 'vo1',
        projectId: 'p1',
        sourceUri: '/v.m4a',
        startMs: 500,
        durationMs: 2000,
      ));
      final snap = await db.snapshotProject('p1');
      expect(snap.voiceOvers.single.enhance, isTrue);
      await db.deleteVoiceOver('vo1');
      await db.restoreProject('p1', snap);
      expect((await db.getVoiceOvers('p1')).single.id, 'vo1', reason: 'undo restores voice-overs');
      expect(clip.speed, 1.0, reason: 'v6 column default');
      expect(clip.filterPreset, isNull, reason: 'v5 column');
      expect((await db.getProject('p1'))!.duckMusic, isFalse);
      expect((await db.getProject('p1'))!.mode, 'normal', reason: 'v10 column default');
      final overlay = await db.getTextOverlay('t1');
      expect(overlay!.alignment, 1);
      expect(overlay.bold, isFalse);
      // v9: the photo table exists and works.
      await db.insertPhotoProject(PhotoProjectsCompanion.insert(
        id: 'ph1',
        name: 'Photo',
        sourceUri: '/p.jpg',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ));
      expect((await db.getPhotoProject('ph1'))!.editJson, '');

      await db.close();
    });
  }

  test('rows written before an upgrade survive it with neutral new values', () async {
    await _makeOldDatabase(dbFile, 6, seedSql: [
      "INSERT INTO projects (id, name, aspect_ratio, created_at, updated_at) VALUES ('p1', 'Old', 0.5625, 0, 0)",
      "INSERT INTO clips (id, project_id, source_uri, order_index, trim_start_ms, trim_end_ms, duration_ms, speed) "
          "VALUES ('c1', 'p1', '/a.mp4', 0, 0, 3000, 3000, 2.0)",
    ]);

    final db = ProjectDatabase.forTesting(NativeDatabase(dbFile));
    final clip = await db.getClip('c1');
    expect(clip!.speed, 2.0, reason: 'existing value kept');
    expect(clip.fitMode, 'fit');
    expect((await db.getProject('p1'))!.duckMusic, isFalse);
    expect((await db.getProject('p1'))!.mode, 'normal', reason: 'pre-v10 projects open in Quick Edit');
    await db.close();
  });

  test('duplicating a project keeps its editor mode', () async {
    final db = ProjectDatabase.forTesting(NativeDatabase(dbFile));
    await db.insertProject(ProjectsCompanion.insert(
      id: 'yt',
      name: 'Long video',
      mode: const Value('youtube'),
      aspectRatio: const Value(16 / 9),
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ));
    final copy = await db.duplicateProject('yt', newProjectId: 'yt2');
    expect((await db.getProject(copy!))!.mode, 'youtube');
    await db.close();
  });

  test('a brand-new database has every table', () async {
    final db = ProjectDatabase.forTesting(NativeDatabase(dbFile));
    await insertProject(db);
    await db.insertTextOverlay(TextOverlaysCompanion.insert(
      id: 't1',
      projectId: 'p1',
      content: 'hello',
      startMs: const Value(0),
      endMs: 1000,
    ));
    expect((await db.getTextOverlay('t1'))!.content, 'hello');
    await db.close();
  });
}
