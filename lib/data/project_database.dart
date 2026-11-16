import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show listEquals, visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/media_kind.dart' show isPhotoPath;

part 'project_database.g.dart';

const _uuid = Uuid();

/// A Project is the top-level container for one editing session.
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get aspectRatio => real().withDefault(const Constant(9 / 16))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// F19: when true, export lowers the music while clip audio is audible
  /// (FFmpeg `sidechaincompress`). Export-only — the preview does not duck.
  BoolColumn get duckMusic => boolean().withDefault(const Constant(false))();

  /// v10: which editor mode the project was started in (`EditMode.name`:
  /// youtube | insta | normal). Rows from before v10 read as 'normal'.
  TextColumn get mode => text().withDefault(const Constant('normal'))();

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

  /// Which `FilterPreset` (see `models/color_filter_x.dart`) this clip's
  /// brightness/contrast/saturation currently match, or null once the
  /// user drags a slider away from any preset ("Custom"). Purely a UI
  /// convenience so `FilterPanel` can highlight the active chip — the
  /// three numeric columns above are always the source of truth for
  /// what actually renders, both in the live preview and (Phase 8) at
  /// export.
  TextColumn get filterPreset => text().nullable()();
  BoolColumn get muted => boolean().withDefault(const Constant(false))();

  /// Independent volume for this clip's *original* audio (0.0–1.0),
  /// separate from [muted] — mute is a hard on/off, this is the level
  /// applied when it isn't muted. Added Phase 5 (second half); mirrors
  /// `AudioTracks.volume`'s range/semantics so `TrimPanel` and
  /// `AudioTrackPanel`'s sliders behave the same way.
  RealColumn get volume => real().withDefault(const Constant(1.0))();

  /// F7: which stylized look (see `models/look_x.dart`'s `lookPresets`)
  /// is layered on top of the brightness/contrast/saturation sliders
  /// above, or null for none. Unlike [filterPreset] (a shortcut for the
  /// three numeric sliders), a look's math — colorchannelmixer, a
  /// vignette — isn't expressible as brightness/contrast/saturation, so
  /// it needs its own column rather than reusing [filterPreset].
  TextColumn get look => text().nullable()();

  /// F10: quarter-turns clockwise (0–3) applied on top of
  /// [rotationDegrees] (the container-level rotation already baked into
  /// the source file). A user-requested rotate, not a re-probe of the
  /// file.
  IntColumn get turns => integer().withDefault(const Constant(0))();
  BoolColumn get flipH => boolean().withDefault(const Constant(false))();
  BoolColumn get flipV => boolean().withDefault(const Constant(false))();

  /// F11: constant per-clip playback speed, 0.5–2.0 (1.0 = unchanged).
  /// Scoped to this range so export needs exactly one FFmpeg `atempo`
  /// filter for the audio path — `atempo`'s own valid range is 0.5–2.0,
  /// and chaining several to cover a wider range is deliberately out of
  /// scope for this pass (see `export_command_builder.dart`). Ramped
  /// (mid-clip) speed changes are out of scope too — this is constant
  /// speed for the whole clip, same "v1 scope" call the original F11
  /// plan already made. Ignored for photo clips (nothing to speed up).
  RealColumn get speed => real().withDefault(const Constant(1.0))();

  /// F15: how a clip whose shape differs from the project's fills the
  /// frame — 'fit' (letterbox, the pre-F15 behaviour), 'fill' (crop to
  /// cover) or 'blur' (fit over a blurred, cropped copy of itself). See
  /// `models/fit_mode_x.dart`.
  TextColumn get fitMode => text().withDefault(const Constant('fit'))();

  /// How strongly [look] is applied, 0..1 (1 = the look as designed).
  RealColumn get lookStrength => real().withDefault(const Constant(1.0))();

  /// v11: one effect from `models/effect_x.dart` (motion or stylise), or
  /// null for none, and how strongly it applies (0..1).
  TextColumn get effect => text().nullable()();
  RealColumn get effectStrength => real().withDefault(const Constant(1.0))();

  /// v11: export cleans this clip's voice (denoise, EQ, compression).
  /// Export-only — the preview plays the original sound.
  BoolColumn get enhanceSpeech => boolean().withDefault(const Constant(false))();

  /// v12: background removal (`models/chroma_key.dart` JSON), or null.
  TextColumn get keyJson => text().nullable()();

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

  /// F9: fade the music in/out at its own start/end (i.e. within the
  /// trimmed window above, not the timeline) — 0 means no fade, same
  /// "0 is the neutral default" convention every other optional column
  /// here uses. Applied at export via FFmpeg `afade`; the preview
  /// approximates it with a volume ramp (see `VideoPreviewPlayer`) since
  /// `just_audio` has no frame-accurate fade filter — export is the
  /// exact version, same relationship F15/F19 already have between
  /// preview and export elsewhere in this app.
  IntColumn get fadeInMs => integer().withDefault(const Constant(0))();
  IntColumn get fadeOutMs => integer().withDefault(const Constant(0))();

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

  /// F8 (text styling v2): bold weight, a background box, and an
  /// outline/stroke — on top of the font/size/color/alignment above.
  /// [boxColorValue] and [outlineColorValue] are independent of
  /// [colorValue] (the text fill) so e.g. white text can sit on a black
  /// box without the two colors being forced to match.
  BoolColumn get bold => boolean().withDefault(const Constant(false))();
  BoolColumn get boxEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get boxColorValue =>
      integer().withDefault(const Constant(0x99000000))();

  /// Outline width in the same logical-px space [fontSize] uses; 0 means
  /// no outline (the pre-F8 behavior — every overlay before this column
  /// existed effectively had width 0).
  RealColumn get outlineWidth => real().withDefault(const Constant(0))();
  IntColumn get outlineColorValue =>
      integer().withDefault(const Constant(0xFF000000))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Immutable copy of a project's editable rows. Drift data classes have value
/// equality, so two snapshots compare equal iff nothing visible changed.
class ProjectSnapshot {
  final List<Clip> clips;
  final List<AudioTrack> audioTracks;
  final List<TextOverlay> overlays;
  final List<VoiceOver> voiceOvers;
  const ProjectSnapshot(this.clips, this.audioTracks, this.overlays, [this.voiceOvers = const []]);

  @override
  bool operator ==(Object other) =>
      other is ProjectSnapshot &&
      listEquals(clips, other.clips) &&
      listEquals(audioTracks, other.audioTracks) &&
      listEquals(overlays, other.overlays) &&
      listEquals(voiceOvers, other.voiceOvers);

  @override
  int get hashCode => Object.hash(
      Object.hashAll(clips), Object.hashAll(audioTracks), Object.hashAll(overlays), Object.hashAll(voiceOvers));
}

/// v11: narration recorded in the app (or any audio file) placed on the
/// timeline at [startMs]. Several per project; mixed under the clips'
/// sound in the export, before music ducking, so ducking also dips the
/// music under narration.
class VoiceOvers extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get sourceUri => text()();

  /// Timeline position where it starts.
  IntColumn get startMs => integer()();
  IntColumn get durationMs => integer()();
  RealColumn get volume => real().withDefault(const Constant(1.0))();

  /// Same voice clean-up as `Clips.enhanceSpeech`; on by default.
  BoolColumn get enhance => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// v13 Audio Studio: one row per audio edit or composition. The edit
/// (`lib/audio/audio_edit.dart`) and the composition (`lib/audio/composer.dart`)
/// are JSON documents; undo/redo lives in the audio screens, like photos.
class AudioProjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// The audio being edited (an imported copy, a recording, or a rendered
  /// composition). Null for a composition that hasn't been rendered yet.
  TextColumn get sourceUri => text().nullable()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get editJson => text().withDefault(const Constant(''))();
  TextColumn get composeJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Photo Studio (MASTER_PLAN Phase 1): one row per edited photo. The edit
/// itself is a versioned JSON document (`lib/photo/photo_edit.dart`), so
/// new tools don't need schema changes. Undo/redo for photos lives in the
/// photo editor, not in `ProjectSnapshot` (that covers video projects).
class PhotoProjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// The imported copy in app storage (never modified).
  TextColumn get sourceUri => text()();
  IntColumn get width => integer().withDefault(const Constant(0))();
  IntColumn get height => integer().withDefault(const Constant(0))();
  TextColumn get editJson => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Projects, Clips, AudioTracks, TextOverlays, PhotoProjects, VoiceOvers, AudioProjects])
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
  int get schemaVersion => 13;

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
          if (from < 5) {
            // Phase 7 (first half): Clips gained `filterPreset`, a
            // nullable label for whichever `FilterPreset` the clip's
            // existing brightness/contrast/saturation columns match.
            // Those three columns already existed (declared ahead of
            // this phase) but nothing wrote to them yet — installs
            // upgrading from here simply get `null` (== "Custom"/no
            // preset), same as every clip's actual 0/0/0 default.
            await m.addColumn(clips, clips.filterPreset);
          }
          if (from < 6) {
            // Tier 2 batch (F7 look, F8 text styling v2, F9 music
            // fades, F10 rotate/flip, F11 speed): every new column
            // defaults to its existing-row-safe neutral value (null
            // look, no rotation/flip, 1.0x speed, no box/outline, no
            // fade), so upgrading installs see no visible change to
            // anything already on their timeline until they touch one
            // of these controls.
            await m.addColumn(clips, clips.look);
            await m.addColumn(clips, clips.turns);
            await m.addColumn(clips, clips.flipH);
            await m.addColumn(clips, clips.flipV);
            await m.addColumn(clips, clips.speed);
            // Installs older than v4 just got `textOverlays` from
            // `createTable` above, which already uses today's full column
            // set — adding these again would fail with "duplicate column".
            if (from >= 4) {
              await m.addColumn(textOverlays, textOverlays.bold);
              await m.addColumn(textOverlays, textOverlays.boxEnabled);
              await m.addColumn(textOverlays, textOverlays.boxColorValue);
              await m.addColumn(textOverlays, textOverlays.outlineWidth);
              await m.addColumn(textOverlays, textOverlays.outlineColorValue);
            }
            await m.addColumn(audioTracks, audioTracks.fadeInMs);
            await m.addColumn(audioTracks, audioTracks.fadeOutMs);
          }
          if (from < 7) {
            // F15 fit mode + F19 music ducking. Both default to the
            // pre-existing behaviour ('fit', no ducking).
            await m.addColumn(clips, clips.fitMode);
            await m.addColumn(projects, projects.duckMusic);
          }
          if (from < 8) {
            // Look strength slider (defaults to the full look, as before).
            await m.addColumn(clips, clips.lookStrength);
          }
          if (from < 9) {
            // Photo Studio.
            await m.createTable(photoProjects);
          }
          if (from < 10) {
            // Editor modes (YouTube Studio / Insta Clip / Quick Edit).
            await m.addColumn(projects, projects.mode);
          }
          if (from < 11) {
            // Effects, speech enhancement, voice-over.
            await m.addColumn(clips, clips.effect);
            await m.addColumn(clips, clips.effectStrength);
            await m.addColumn(clips, clips.enhanceSpeech);
            await m.createTable(voiceOvers);
          }
          if (from < 12) {
            // Background removal.
            await m.addColumn(clips, clips.keyJson);
          }
          if (from < 13) {
            // Audio Studio.
            await m.createTable(audioProjects);
          }
        },
      );

  // --- Query helpers -------------------------------------------------

  Future<List<Project>> allProjects() => select(projects).get();

  // --- Photo Studio ---------------------------------------------------------

  Stream<List<PhotoProject>> watchPhotoProjects() =>
      (select(photoProjects)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Stream<PhotoProject?> watchPhotoProject(String id) =>
      (select(photoProjects)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<PhotoProject?> getPhotoProject(String id) =>
      (select(photoProjects)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertPhotoProject(PhotoProjectsCompanion row) => into(photoProjects).insert(row);

  Future<void> savePhotoEdit(String id, String editJson) =>
      (update(photoProjects)..where((t) => t.id.equals(id))).write(
        PhotoProjectsCompanion(editJson: Value(editJson), updatedAt: Value(DateTime.now())),
      );

  Future<void> renamePhotoProject(String id, String name) =>
      (update(photoProjects)..where((t) => t.id.equals(id))).write(
        PhotoProjectsCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
      );

  Future<void> deletePhotoProject(String id) => (delete(photoProjects)..where((t) => t.id.equals(id))).go();

  /// Every clip in every project, regardless of `projectId` — unlike
  /// [watchClips], which is scoped to one project's timeline. Used by
  /// `MediaRepairService`'s one-time cache-to-documents repair pass
  /// (P1), which has to sweep the whole database, not just the
  /// currently open project.
  Future<List<Clip>> allClipsAcrossProjects() => select(clips).get();

  /// Every audio track in every project. See [allClipsAcrossProjects].
  Future<List<AudioTrack>> allAudioTracksAcrossProjects() =>
      select(audioTracks).get();

  Future<Project?> getProject(String id) =>
      (select(projects)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Project?> watchProject(String id) =>
      (select(projects)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// F6: changes the project's frame shape (width / height). Not part of
  /// the undo snapshot — `ProjectSnapshot` covers clips/audio/text only.
  Future<void> setAspectRatio(String id, double aspectRatio) =>
      (update(projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(aspectRatio: Value(aspectRatio), updatedAt: Value(DateTime.now())),
      );

  /// F19: turns music ducking on/off (export-only). Not in undo, like
  /// [setAspectRatio].
  Future<void> setDuckMusic(String id, bool duck) =>
      (update(projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(duckMusic: Value(duck), updatedAt: Value(DateTime.now())),
      );

  /// Autosave stamp: edits are written to SQLite as they happen, so "saving"
  /// is just recording when the project last changed.
  Future<void> touchProject(String id) =>
      (update(projects)..where((t) => t.id.equals(id)))
          .write(ProjectsCompanion(updatedAt: Value(DateTime.now())));

  /// Everything undo/redo needs to put a project back exactly as it was.
  Future<ProjectSnapshot> snapshotProject(String projectId) async {
    final c = await (select(clips)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex), (t) => OrderingTerm.asc(t.id)]))
        .get();
    final a = await (select(audioTracks)..where((t) => t.projectId.equals(projectId))).get();
    final o = await (select(textOverlays)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.startMs), (t) => OrderingTerm.asc(t.id)]))
        .get();
    final v = await (select(voiceOvers)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.startMs), (t) => OrderingTerm.asc(t.id)]))
        .get();
    return ProjectSnapshot(c, a, o, v);
  }

  /// Replaces the project's clips/audio/overlays with [s] in one transaction,
  /// so streams (timeline, preview) update once, not row by row.
  Future<void> restoreProject(String projectId, ProjectSnapshot s) => transaction(() async {
        await (delete(clips)..where((t) => t.projectId.equals(projectId))).go();
        await (delete(audioTracks)..where((t) => t.projectId.equals(projectId))).go();
        await (delete(textOverlays)..where((t) => t.projectId.equals(projectId))).go();
        await (delete(voiceOvers)..where((t) => t.projectId.equals(projectId))).go();
        for (final v in s.voiceOvers) {
          await into(voiceOvers).insert(v.toCompanion(false));
        }
        for (final c in s.clips) {
          await into(clips).insert(c.toCompanion(false));
        }
        for (final a in s.audioTracks) {
          await into(audioTracks).insert(a.toCompanion(false));
        }
        for (final o in s.overlays) {
          await into(textOverlays).insert(o.toCompanion(false));
        }
      });

  /// First-clip thumbnail per project (for the Home grid), keyed by project id.
  Future<Map<String, String>> projectCoverThumbnails() async {
    final rows = await (select(clips)..where((c) => c.orderIndex.equals(0))).get();
    // A photo clip has no generated thumbnail; the photo itself is the cover.
    return {
      for (final c in rows)
        if ((c.thumbnailUri ?? (isPhotoPath(c.sourceUri) ? c.sourceUri : null)) case final String uri)
          c.projectId: uri,
    };
  }

  // --- Audio Studio (v13) -------------------------------------------------

  Stream<List<AudioProject>> watchAudioProjects() =>
      (select(audioProjects)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<AudioProject?> getAudioProject(String id) =>
      (select(audioProjects)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertAudioProject(AudioProjectsCompanion row) => into(audioProjects).insert(row);

  Future<void> updateAudioProject(String id, AudioProjectsCompanion changes) =>
      (update(audioProjects)..where((t) => t.id.equals(id)))
          .write(changes.copyWith(updatedAt: Value(DateTime.now())));

  Future<void> deleteAudioProject(String id) => (delete(audioProjects)..where((t) => t.id.equals(id))).go();

  // --- Voice-over (v11) ----------------------------------------------------

  Stream<List<VoiceOver>> watchVoiceOvers(String projectId) => (select(voiceOvers)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([(t) => OrderingTerm.asc(t.startMs)]))
      .watch();

  Future<List<VoiceOver>> getVoiceOvers(String projectId) => (select(voiceOvers)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([(t) => OrderingTerm.asc(t.startMs)]))
      .get();

  Future<void> insertVoiceOver(VoiceOversCompanion row) => into(voiceOvers).insert(row);

  Future<bool> updateVoiceOver(VoiceOver row) => update(voiceOvers).replace(row);

  Future<int> deleteVoiceOver(String id) => (delete(voiceOvers)..where((t) => t.id.equals(id))).go();

  /// Same look (and strength) on every clip of a project.
  Future<void> applyLookToAllClips(String projectId, String? look, double strength) =>
      (update(clips)..where((t) => t.projectId.equals(projectId)))
          .write(ClipsCompanion(look: Value(look), lookStrength: Value(strength)));

  /// Same effect (and strength) on every clip of a project.
  Future<void> applyEffectToAllClips(String projectId, String? effect, double strength) =>
      (update(clips)..where((t) => t.projectId.equals(projectId)))
          .write(ClipsCompanion(effect: Value(effect), effectStrength: Value(strength)));

  /// AutoCut: replaces the project's whole timeline with [rows] (already
  /// numbered by `orderIndex`) in one transaction — one undo step.
  Future<void> replaceProjectClips(String projectId, List<Clip> rows) => transaction(() async {
        await (delete(clips)..where((t) => t.projectId.equals(projectId))).go();
        for (final r in rows) {
          await into(clips).insert(r.toCompanion(false));
        }
      });

  /// Speech clean-up for every clip of a project at once.
  Future<void> setEnhanceSpeechForAll(String projectId, bool on) =>
      (update(clips)..where((t) => t.projectId.equals(projectId))).write(ClipsCompanion(enhanceSpeech: Value(on)));

  Future<int> insertProject(ProjectsCompanion project) =>
      into(projects).insert(project);

  // --- Project management (F1: rename / delete / duplicate) ----------

  /// Renames [id]'s project and bumps `updatedAt` (same convention as
  /// [touchProject]). No-op if the project no longer exists.
  Future<void> renameProject(String id, String newName) =>
      (update(projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(name: Value(newName), updatedAt: Value(DateTime.now())),
      );

  /// Deletes a project and every row that belongs to it (Clips,
  /// AudioTracks, TextOverlays) in one transaction. SQLite's
  /// `references(...)` columns are **not** enforced here (see
  /// `docs/FACTS.md` F-44), so without this cascade, deleting just the
  /// `Projects` row would leave orphan child rows behind forever.
  /// Does not touch `AppPrefs.lastProjectId` — the caller (Home screen)
  /// clears that if it matches, since `AppPrefs` lives outside the DB.
  Future<void> deleteProjectCascade(String id) => transaction(() async {
        await (delete(clips)..where((t) => t.projectId.equals(id))).go();
        await (delete(audioTracks)..where((t) => t.projectId.equals(id))).go();
        await (delete(textOverlays)..where((t) => t.projectId.equals(id))).go();
        await (delete(voiceOvers)..where((t) => t.projectId.equals(id))).go();
        await (delete(projects)..where((t) => t.id.equals(id))).go();
      });

  /// Copies [id]'s project row plus every Clip/AudioTrack/TextOverlay
  /// that belongs to it, each with a fresh id, so the duplicate edits
  /// completely independently of the original (new undo history, moving
  /// a clip in one never touches the other). Source media is referenced,
  /// not copied — the duplicate's clips/audio point at the same
  /// `sourceUri` files as the original, same as a split clip reusing its
  /// parent's source (see `splitClip`).
  ///
  /// [newProjectId] lets tests/callers control the new id; otherwise one
  /// is generated. Returns the new project's id, or null if [id] doesn't
  /// exist.
  Future<String?> duplicateProject(String id, {String? newProjectId}) async {
    final original = await getProject(id);
    if (original == null) return null;

    final snapshot = await snapshotProject(id);
    final newId = newProjectId ?? _uuid.v4();
    final now = DateTime.now();

    await transaction(() async {
      await into(projects).insert(ProjectsCompanion.insert(
        id: newId,
        name: '${original.name} (copy)',
        aspectRatio: Value(original.aspectRatio),
        duckMusic: Value(original.duckMusic),
        mode: Value(original.mode),
        createdAt: now,
        updatedAt: now,
      ));
      for (final c in snapshot.clips) {
        await into(clips).insert(
          c.copyWith(id: _uuid.v4(), projectId: newId).toCompanion(false),
        );
      }
      for (final a in snapshot.audioTracks) {
        await into(audioTracks).insert(
          a.copyWith(id: _uuid.v4(), projectId: newId).toCompanion(false),
        );
      }
      for (final o in snapshot.overlays) {
        await into(textOverlays).insert(
          o.copyWith(id: _uuid.v4(), projectId: newId).toCompanion(false),
        );
      }
      for (final v in snapshot.voiceOvers) {
        await into(voiceOvers).insert(
          v.copyWith(id: _uuid.v4(), projectId: newId).toCompanion(false),
        );
      }
    });

    return newId;
  }

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

  /// Sets brightness/contrast/saturation (and, for the presets picker,
  /// [filterPreset]) on every clip in [projectId] at once — the
  /// "globally" half of Phase 7's spec item 3. Runs as one transaction,
  /// same rationale as [reorderClips]/[deleteClipAndReindex]: the UI
  /// should never observe some clips updated and others not.
  Future<void> applyFilterToAllClips(
    String projectId, {
    required double brightness,
    required double contrast,
    required double saturation,
    String? filterPreset,
  }) {
    return transaction(() async {
      final all = await (select(clips)
            ..where((c) => c.projectId.equals(projectId)))
          .get();
      for (final c in all) {
        await (update(clips)..where((row) => row.id.equals(c.id))).write(
          ClipsCompanion(
            brightness: Value(brightness),
            contrast: Value(contrast),
            saturation: Value(saturation),
            filterPreset: Value(filterPreset),
          ),
        );
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

      // The first half now ends at the split point and hands the transition
      // *into* the second half off to that second half; it becomes a plain
      // cut at the new boundary so export doesn't fade/dissolve into itself
      // (B-02). The second half inherits the original's outgoing transition.
      await (update(clips)..where((c) => c.id.equals(clipId))).write(
        ClipsCompanion(trimEndMs: Value(splitAbsoluteMs), transitionOut: const Value('cut')),
      );

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
        // B-01: these were previously dropped, so the second half silently
        // reset to volume 1.0 and lost its look/filter preset.
        volume: Value(original.volume),
        filterPreset: Value(original.filterPreset),
        // Same B-01 rationale for the Tier-2 columns (F7/F10/F11): without
        // these, splitting a rotated/flipped/sped-up/look-applied clip
        // would silently reset the second half to upright/1x/no-look.
        look: Value(original.look),
        turns: Value(original.turns),
        flipH: Value(original.flipH),
        flipV: Value(original.flipV),
        speed: Value(original.speed),
        fitMode: Value(original.fitMode),
        lookStrength: Value(original.lookStrength),
        effect: Value(original.effect),
        effectStrength: Value(original.effectStrength),
        enhanceSpeech: Value(original.enhanceSpeech),
        keyJson: Value(original.keyJson),
      ));
    });
  }

  /// Replaces [clipId] with one clip per entry of [segments] — each a
  /// `(startMs, endMs)` range in *source* time — keeping their order. Used
  /// by the smart tools ("remove silences" keeps the non-silent ranges,
  /// "split at scene changes" keeps contiguous ranges).
  ///
  /// The original row keeps its id and becomes the first segment; the rest
  /// are copies inserted right after it. Only the last segment keeps the
  /// original's outgoing transition (the others cut into their own next
  /// part, same rule as [splitClip]). Segments are clamped to the clip's
  /// current trim window; empty or out-of-range ones are dropped. No-op
  /// (returns an empty list) if nothing valid remains.
  ///
  /// Returns the ids of the resulting clips in timeline order.
  Future<List<String>> replaceClipWithSegments(
    String clipId,
    List<(int, int)> segments, {
    String Function()? newId,
  }) {
    return transaction(() async {
      final original = await getClip(clipId);
      if (original == null) return <String>[];

      final valid = <(int, int)>[];
      for (final (s, e) in segments) {
        final start = s.clamp(original.trimStartMs, original.trimEndMs).toInt();
        final end = e.clamp(original.trimStartMs, original.trimEndMs).toInt();
        if (end > start) valid.add((start, end));
      }
      if (valid.isEmpty) return <String>[];

      final extra = valid.length - 1;
      if (extra > 0) {
        final laterClips = await (select(clips)
              ..where((c) =>
                  c.projectId.equals(original.projectId) &
                  c.orderIndex.isBiggerThanValue(original.orderIndex)))
            .get();
        for (final later in laterClips) {
          await (update(clips)..where((c) => c.id.equals(later.id)))
              .write(ClipsCompanion(orderIndex: Value(later.orderIndex + extra)));
        }
      }

      final ids = <String>[];
      for (var i = 0; i < valid.length; i++) {
        final (start, end) = valid[i];
        final isLast = i == valid.length - 1;
        final transition = isLast ? original.transitionOut : 'cut';
        if (i == 0) {
          await (update(clips)..where((c) => c.id.equals(clipId))).write(
            ClipsCompanion(
              trimStartMs: Value(start),
              trimEndMs: Value(end),
              transitionOut: Value(transition),
            ),
          );
          ids.add(clipId);
        } else {
          final id = newId?.call() ?? _uuid.v4();
          await into(clips).insert(
            original
                .copyWith(
                  id: id,
                  orderIndex: original.orderIndex + i,
                  trimStartMs: start,
                  trimEndMs: end,
                  transitionOut: transition,
                )
                .toCompanion(false),
          );
          ids.add(id);
        }
      }
      return ids;
    });
  }

  /// F3: sets how long a photo clip stays on screen. A photo has no source
  /// duration, so `durationMs` and `trimEndMs` move together and the trim
  /// start stays 0.
  Future<void> setPhotoDuration(String clipId, int durationMs) =>
      (update(clips)..where((c) => c.id.equals(clipId))).write(
        ClipsCompanion(
          trimStartMs: const Value(0),
          trimEndMs: Value(durationMs),
          durationMs: Value(durationMs),
        ),
      );

  /// Sets the same outgoing transition on every clip of [projectId] in one
  /// transaction (one undo step).
  Future<void> applyTransitionToAllClips(String projectId, String transition) =>
      (update(clips)..where((c) => c.projectId.equals(projectId)))
          .write(ClipsCompanion(transitionOut: Value(transition)));

  /// F2: inserts a copy of [clipId] immediately after it (orderIndex + 1)
  /// and shifts every later clip down by one, so orderIndex stays
  /// contiguous 0..n-1. One transaction, so the UI (and undo history) never
  /// sees a half-shifted timeline.
  ///
  /// Every column is copied (trim, filter, volume, mute, thumbnail,
  /// rotation, ...) via `copyWith`, so a column added to `Clips` later is
  /// carried over automatically. The source file is referenced, not copied
  /// — same as `splitClip`.
  ///
  /// Transition: the original now leads into its own copy, so it becomes a
  /// plain `cut` and the copy inherits the original's outgoing transition
  /// (same rule as `splitClip`, B-02).
  ///
  /// Text overlays and music are positioned in absolute timeline ms and are
  /// not remapped, exactly as for delete/reorder/split: the later part of
  /// the timeline moves right by the copy's length, they do not.
  ///
  /// [newClipId] lets tests/callers control the new id; otherwise one is
  /// generated. Returns the new clip's id, or null if [clipId] doesn't exist.
  Future<String?> duplicateClip(String clipId, {String? newClipId}) {
    return transaction(() async {
      final original = await getClip(clipId);
      if (original == null) return null;
      final newId = newClipId ?? _uuid.v4();

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
          .write(const ClipsCompanion(transitionOut: Value('cut')));

      await into(clips).insert(
        original
            .copyWith(id: newId, orderIndex: original.orderIndex + 1)
            .toCompanion(false),
      );
      return newId;
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

  /// F12: inserts every parsed subtitle cue as its own `TextOverlay` in
  /// one transaction, so a large `.srt` file either lands entirely or
  /// (on an error partway through) not at all — never half-imported.
  Future<void> insertTextOverlays(List<TextOverlaysCompanion> overlays) =>
      transaction(() async {
        for (final o in overlays) {
          await into(textOverlays).insert(o);
        }
      });

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
