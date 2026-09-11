import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
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

  /// Degrees of rotation baked into the source container (0/90/180/270).
  /// Carried over from MediaAsset at import time so the timeline/preview
  /// don't need to re-probe the file to display it right-side-up.
  IntColumn get rotationDegrees => integer().withDefault(const Constant(0))();

  /// Cached thumbnail for this clip's timeline tile. Copied from the
  /// MediaAsset that created the clip; a split clip reuses its parent's.
  TextColumn get thumbnailUri => text().nullable()();

  TextColumn get transitionOut =>
      text().withDefault(const Constant('cut'))(); // cut | fade | dissolve
  RealColumn get brightness => real().withDefault(const Constant(0))();
  RealColumn get contrast => real().withDefault(const Constant(0))();
  RealColumn get saturation => real().withDefault(const Constant(0))();
  BoolColumn get muted => boolean().withDefault(const Constant(false))();

  /// Independent volume for this clip's *original* audio (0.0–1.0),
  /// separate from [muted] — mute is a hard on/off, this is the level
  /// applied when it isn't muted. Added Phase 5 (second half); mirrors
  /// `AudioTracks.volume`'s range/semantics so `TrimPanel` and
  /// `AudioTrackPanel`'s sliders behave the same way.
  RealColumn get volume => real().withDefault(const Constant(1.0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A single background-music track aligned against the video timeline.
class AudioTracks extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get sourceUri => text()();

  /// The source file's full untrimmed duration, in ms — kept separate
  /// from trimStartMs/trimEndMs so a trim can be dragged back out after
  /// being narrowed, same rationale as Clips.durationMs above.
  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  IntColumn get trimStartMs => integer().withDefault(const Constant(0))();
  IntColumn get trimEndMs => integer()();
  IntColumn get offsetMs => integer().withDefault(const Constant(0))();
  RealColumn get volume => real().withDefault(const Constant(1.0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A text overlay positioned on the preview canvas with its own timing.
/// Phase 6: table existed as a stub since Phase 5 but was never wired to
/// a migration, CRUD, or UI — this pass finishes all three. `positionX`/
/// `positionY` are fractions (0.0–1.0) of the preview canvas, not raw
/// pixels, so they stay valid across different preview widget sizes
/// (rotation, different device, etc.) the same way `AudioTracks`'
/// ms-based fields stay valid across zoom levels.
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

  /// 0 = left, 1 = center, 2 = right — see `TextAlignment` in
  /// `models/text_overlay_x.dart` for the enum this maps to. Stored as
  /// an int rather than a text enum for the same reason `transitionOut`
  /// above is a string, not the other way: drift doesn't need a custom
  /// converter for a 3-value int, so keep it plain.
  IntColumn get alignment => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Projects, Clips, AudioTracks, TextOverlays])
class ProjectDatabase extends _$ProjectDatabase {
  ProjectDatabase() : super(_openConnection());

  /// Test-only constructor that takes an explicit [executor] instead of
  /// opening the real on-device file via [_openConnection] (which needs
  /// `path_provider`'s platform channel — unavailable outside a running
  /// Flutter app). Lets migration/CRUD tests run against an in-memory
  /// or temp-file database instead. See
  /// `test/project_database_migration_test.dart`.
  @visibleForTesting
  ProjectDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Phase 5 (first half): AudioTracks gained `durationMs`. See
            // the column's doc comment above for why it's separate from
            // trimEndMs.
            await m.addColumn(audioTracks, audioTracks.durationMs);
          }
          if (from < 3) {
            // Phase 5 (second half): Clips gained `volume`, the
            // continuous counterpart to the `muted` flag added back in
            // Phase 4.
            await m.addColumn(clips, clips.volume);
          }
          if (from < 4) {
            // Phase 6: TextOverlays was already declared as a table
            // (stub, unused) back when Phase 5 shipped, but schemaVersion
            // was never bumped for it, so `onCreate`'s `createAll()` was
            // the only path that ever actually created it — any real
            // upgrading install would be missing the table entirely.
            // Create it now for those installs; fresh installs already
            // get it via `createAll()` and just no-op past this branch.
            await m.createTable(textOverlays);
          }
        },
      );

  // --- Query helpers -------------------------------------------------

  Future<List<Project>> allProjects() => select(projects).get();

  Future<int> insertProject(ProjectsCompanion project) =>
      into(projects).insert(project);

  Stream<List<Clip>> watchClips(String projectId) =>
      (select(clips)
            ..where((c) => c.projectId.equals(projectId))
            ..orderBy([(c) => OrderingTerm.asc(c.orderIndex)]))
          .watch();

  Future<Clip?> getClip(String id) =>
      (select(clips)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> insertClip(ClipsCompanion clip) => into(clips).insert(clip);

  /// Accepts either a `Clip` (e.g. from `.copyWith`) or a raw
  /// `ClipsCompanion` — both implement `Insertable<Clip>`.
  Future<bool> updateClip(Insertable<Clip> clip) =>
      update(clips).replace(clip);

  Future<int> deleteClip(String id) =>
      (delete(clips)..where((c) => c.id.equals(id))).go();

  /// Appends a new clip to the end of [projectId]'s timeline. Used by the
  /// media importer (Phase 3) to drop a freshly picked asset straight
  /// onto the timeline (Phase 4).
  Future<void> appendClip({
    required String id,
    required String projectId,
    required String sourceUri,
    required int durationMs,
    int rotationDegrees = 0,
    String? thumbnailUri,
  }) async {
    final existing = await (select(clips)
          ..where((c) => c.projectId.equals(projectId)))
        .get();
    await into(clips).insert(ClipsCompanion.insert(
      id: id,
      projectId: projectId,
      sourceUri: sourceUri,
      orderIndex: existing.length,
      durationMs: durationMs,
      trimEndMs: durationMs,
      rotationDegrees: Value(rotationDegrees),
      thumbnailUri: Value(thumbnailUri),
    ));
  }

  /// Persists a new clip order after a timeline drag-reorder. Runs as one
  /// transaction so the UI never observes a half-reordered list.
  Future<void> reorderClips(String projectId, List<String> orderedIds) {
    return transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(clips)..where((c) => c.id.equals(orderedIds[i])))
            .write(ClipsCompanion(orderIndex: Value(i)));
      }
    });
  }

  /// Deletes a clip and closes the resulting gap in orderIndex so the
  /// remaining clips stay contiguous (0..n-1) — split/reorder both rely
  /// on that invariant.
  Future<void> deleteClipAndReindex(String projectId, String clipId) {
    return transaction(() async {
      await (delete(clips)..where((c) => c.id.equals(clipId))).go();
      final remaining = await (select(clips)
            ..where((c) => c.projectId.equals(projectId))
            ..orderBy([(c) => OrderingTerm.asc(c.orderIndex)]))
          .get();
      for (var i = 0; i < remaining.length; i++) {
        if (remaining[i].orderIndex != i) {
          await (update(clips)..where((c) => c.id.equals(remaining[i].id)))
              .write(ClipsCompanion(orderIndex: Value(i)));
        }
      }
    });
  }

  /// Splits [clipId] at [splitAtTrimmedMs], measured from that clip's own
  /// trimmed start (0..trimmedDuration — i.e. playhead-relative-to-clip,
  /// not absolute source time). The original row keeps its id and becomes
  /// [trimStart, splitPoint); a new row with id [newId] covers
  /// [splitPoint, trimEnd) and takes orderIndex+1, with every later clip
  /// shifted down by one to make room. No-ops if the split point falls
  /// outside the clip's trimmed range.
  Future<void> splitClip(String clipId, int splitAtTrimmedMs, String newId) {
    return transaction(() async {
      final original = await getClip(clipId);
      if (original == null) return;
      final splitAbsoluteMs = original.trimStartMs + splitAtTrimmedMs;
      if (splitAbsoluteMs <= original.trimStartMs ||
          splitAbsoluteMs >= original.trimEndMs) {
        return;
      }

      final laterClips = await (select(clips)
            ..where((c) =>
                c.projectId.equals(original.projectId) &
                c.orderIndex.isBiggerThanValue(original.orderIndex)))
          .get();
      for (final later in laterClips) {
        await (update(clips)..where((c) => c.id.equals(later.id)))
            .write(ClipsCompanion(orderIndex: Value(later.orderIndex + 1)));
      }

      await (update(clips)..where((c) => c.id.equals(clipId)))
          .write(ClipsCompanion(trimEndMs: Value(splitAbsoluteMs)));

      await into(clips).insert(ClipsCompanion.insert(
        id: newId,
        projectId: original.projectId,
        sourceUri: original.sourceUri,
        orderIndex: original.orderIndex + 1,
        durationMs: original.durationMs,
        trimEndMs: original.trimEndMs,
        trimStartMs: Value(splitAbsoluteMs),
        rotationDegrees: Value(original.rotationDegrees),
        thumbnailUri: Value(original.thumbnailUri),
        transitionOut: Value(original.transitionOut),
        brightness: Value(original.brightness),
        contrast: Value(original.contrast),
        saturation: Value(original.saturation),
        muted: Value(original.muted),
      ));
    });
  }

  // --- Audio track query helpers --------------------------------------
  //
  // Phase 5 (first half): a project has at most one background-music
  // track. Layering multiple simultaneous tracks would mean rethinking
  // these as `watchAudioTracks` (plural) + per-track ids on export mixing
  // — left as a later extension rather than guessed at now.

  Stream<AudioTrack?> watchAudioTrack(String projectId) =>
      (select(audioTracks)..where((a) => a.projectId.equals(projectId)))
          .watchSingleOrNull();

  Future<AudioTrack?> getAudioTrack(String projectId) =>
      (select(audioTracks)..where((a) => a.projectId.equals(projectId)))
          .getSingleOrNull();

  /// Attaches [sourceUri] to [projectId] as its background-music track,
  /// replacing whatever track was there before. Trim starts covering the
  /// full file and offset starts at 0 (aligned to the very start of the
  /// video timeline); both are then adjustable non-destructively via
  /// [updateAudioTrack] — same pattern as clip trimming.
  Future<void> setAudioTrack({
    required String id,
    required String projectId,
    required String sourceUri,
    required int durationMs,
  }) async {
    final existing = await getAudioTrack(projectId);
    if (existing != null) {
      await (delete(audioTracks)..where((a) => a.id.equals(existing.id)))
          .go();
    }
    await into(audioTracks).insert(AudioTracksCompanion.insert(
      id: id,
      projectId: projectId,
      sourceUri: sourceUri,
      durationMs: Value(durationMs),
      trimEndMs: durationMs,
    ));
  }

  /// Accepts either an `AudioTrack` (e.g. from `.copyWith`) or a raw
  /// `AudioTracksCompanion` — both implement `Insertable<AudioTrack>`.
  Future<bool> updateAudioTrack(Insertable<AudioTrack> track) =>
      update(audioTracks).replace(track);

  Future<int> deleteAudioTrack(String id) =>
      (delete(audioTracks)..where((a) => a.id.equals(id))).go();

  // --- Text overlay query helpers (Phase 6) ---------------------------
  //
  // Unlike AudioTracks (one per project), a project can have any number
  // of TextOverlays — that's the whole point of "multiple simultaneous
  // or sequential" overlays from the spec, so these are plural from the
  // start rather than a single-row `get`/`set` pair.

  Stream<List<TextOverlay>> watchTextOverlays(String projectId) =>
      (select(textOverlays)..where((t) => t.projectId.equals(projectId)))
          .watch();

  Future<TextOverlay?> getTextOverlay(String id) =>
      (select(textOverlays)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertTextOverlay(TextOverlaysCompanion overlay) =>
      into(textOverlays).insert(overlay);

  /// Accepts either a `TextOverlay` (e.g. from `.copyWith`) or a raw
  /// `TextOverlaysCompanion` — same pattern as `updateClip`/
  /// `updateAudioTrack` above.
  Future<bool> updateTextOverlay(Insertable<TextOverlay> overlay) =>
      update(textOverlays).replace(overlay);

  Future<int> deleteTextOverlay(String id) =>
      (delete(textOverlays)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'project_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
