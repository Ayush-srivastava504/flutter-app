# ClipForge — the whole app explained (for someone new to app development)

Read top to bottom once (30 min). After that, use it as a map.

---

## 1. What this app is

ClipForge is a CapCut-style **mobile video editor**. A user can:

- create a **project** and pick its shape (aspect ratio, default 9:16)
- import **videos and photos** from the gallery onto a **timeline**
- **trim**, **split**, **delete** and **re-order** clips
- apply **filters** (brightness / contrast / saturation) per clip or to all clips
- add **transitions** between clips (`cut`, `fade`, `dissolve`)
- add one **background music** track (from the phone or 3 bundled loops), with volume, trim and offset
- add **text overlays** (font, colour, size, position, start/end time)
- **undo / redo** every edit, with autosave
- **export** one MP4, save it to the gallery and share it

**Core idea — non-destructive editing.** The app never changes the user's original files. Every edit is just a number in a database row ("trim this clip from 1.0 s to 4.0 s"). Only at export time are all those numbers combined into one new video file.

---

## 2. The tools it is built with (plain-English)

| Tool | What it is | Where you meet it |
|---|---|---|
| **Flutter / Dart** | Google's toolkit for building phone apps from one codebase. Dart is the language. Everything on screen is a *widget*. | all of `lib/` |
| **Riverpod** (`flutter_riverpod`) | "State management": a way to hold data (current project's clips, which clip is selected, playhead time) so many widgets can read it and automatically redraw when it changes. | `lib/providers/`, anything using `ref.watch` |
| **Drift** (on SQLite) | A database stored on the phone. You describe tables in Dart and Drift generates the code to read/write them. | `lib/data/` |
| **video_player** | Plays video for the *editor preview*. | `lib/widgets/video_preview_player.dart` |
| **just_audio** | Plays the background music *during preview*. | same file |
| **FFmpegKit** (`ffmpeg_kit_flutter_new_full`) | FFmpeg (the industry-standard video tool) packaged for phones. Used for **export** and for reading file info (rotation, duration). | `lib/export/`, `lib/services/*metadata*` |
| **image_picker / file_picker** | Gallery picker / audio-file picker. | `lib/services/*import*` |
| **gal / share_plus** | Save the finished video to the gallery / open the share sheet. | `lib/export/gallery_share_service.dart` |
| **flutter_local_notifications, wakelock_plus** | Export progress notification; keep the screen on while exporting. | `lib/export/` |

---

## 3. The mental model: five layers

```
  SCREENS & WIDGETS   what the user sees and taps         lib/screens, lib/widgets
          │  ref.watch(...)  (read, auto-redraw)   ▲
          ▼                                         │ streams
      PROVIDERS        glue: "the clips of project X"   lib/providers
          │                                         ▲
          ▼                                         │
      DATABASE         the single source of truth      lib/data/project_database.dart
          ▲
          │ writes
      SERVICES         import media, probe files, thumbnails   lib/services
      EXPORT PIPELINE  database rows → FFmpeg command → MP4    lib/export
```

**The most important rule in this codebase:** *the database is the source of truth.* A widget never "holds" the list of clips. It asks the database for a **stream** of clips; when anything changes a row, the stream emits again and every widget showing clips redraws itself. That's why undo/redo, autosave and export all work off the same rows.

---

## 4. Folder map

```
lib/
  main.dart                 app start: wraps everything in ProviderScope (Riverpod), sets dark theme
  router/app_router.dart    3 screens: Home "/" → Editor "/editor" → Export "/export"
  app/                      launch_gate (onboarding vs home), onboarding_screen, app_prefs (tiny JSON settings file)
  screens/
    home_screen.dart        list/create projects, "Resume last project" card
    editor_screen.dart      the big one (~700 lines): preview + timeline + bottom panels
    export_screen.dart      quality picker → progress → done / failed
  widgets/
    video_preview_player.dart   plays the clip under the playhead (+ music, filters, text layer)
    text_overlay_layer.dart     draws & drags text on the preview
    history_actions.dart        undo/redo buttons
    common/state_views.dart     shared Loading / Empty / Error views
    timeline/                   everything below the preview:
      timeline_strip.dart, timeline_clip_tile.dart   thumbnails, drag-reorder, pinch zoom, transition picker
      timeline_scrub_bar.dart                        the playhead bar
      trim_panel.dart                                trim handles, split, delete, volume/mute
      filter_panel.dart                              brightness/contrast/saturation + presets
      audio_track_panel.dart / audio_track_lane.dart music controls + its timeline lane
      text_overlay_panel.dart / text_overlay_strip.dart  text editing + its timeline lane
  providers/                timeline_providers (clips, selected clip, playhead, zoom), audio_providers, text_overlay_providers
  models/                   small helper types + *pure math* (no UI): clip_x, color_filter_x, transition_x, text_overlay_x, media_asset, audio_asset, bundled_track
  data/
    project_database.dart   tables + all database operations (the file to edit when you add stored data)
    project_database.g.dart GENERATED by Drift. Never edit by hand.
    database_provider.dart  makes the one database instance available to Riverpod
  history/                  undo/redo (project_history.dart watches the DB and snapshots; history_stack.dart is the generic stack)
  services/                 media_import_service, audio_import_service, thumbnail_service, permission_service, *_metadata_service (FFprobe)
  export/                   see section 8
test/                       unit tests for the pure logic (run in seconds, no phone)
tools/                      Python reference of the export graph + verifier that runs it through real FFmpeg
third_party/video_thumbnail  a patched local copy of a plugin (kept so the Android build works)
assets/                     3 audio loops, DejaVu fonts (used for export text)
android/ ios/ web/ …        platform "shells" Flutter generated. You rarely touch these (permissions, build settings).
docs/history/               the old PHASE_*_PROGRESS notes
```

---

## 5. The data model (4 tables, `project_database.dart`)

| Table | One row = | Key columns |
|---|---|---|
| **Projects** | one editing session | `id`, `name`, `aspectRatio`, `createdAt`, `updatedAt` |
| **Clips** | one video/photo on the timeline | `sourceUri` (path to original file), `orderIndex`, `trimStartMs`, `trimEndMs`, `durationMs`, `transitionOut` (cut/fade/dissolve), `brightness`, `contrast`, `saturation`, `filterPreset`, `muted`, `volume`, `rotationDegrees`, `thumbnailUri` |
| **AudioTracks** | the background music | `sourceUri`, `trimStartMs/EndMs`, `offsetMs` (where it starts on the timeline), `volume` |
| **TextOverlays** | one piece of text | `content`, `fontFamily`, `colorValue`, `fontSize`, `positionX/Y` (0–1 fractions of the frame), `startMs`, `endMs`, `alignment` |

Notes you need:
- Times are **milliseconds**. Positions are **fractions** (0–1), not pixels, so they survive different screen sizes.
- A photo is just a `Clip` whose file has an image extension (`.jpg/.png/…`); the app doesn't store "type". Photos get a fixed 3 s slot.
- `schemaVersion` is currently **5**. Changing a table means bumping it and writing a migration (section 10).

---

## 6. How the main flows work

**App start** → `main()` → `ProviderScope` → `LaunchGate` checks the small prefs file → onboarding (first time) or `HomeScreen`.

**Create project** → Home inserts a `Projects` row and opens the Editor with its `id`.

**Import a clip** → `MediaImportService.pickVideo()` opens the gallery (image_picker copies the pick into the app's **cache** folder), measures size/duration with a throw-away `VideoPlayerController`, reads rotation with FFprobe, makes a thumbnail → `db.appendClip(...)` inserts a row → the `clipsProvider` stream fires → the timeline shows the new tile. *No widget was told "add a tile"; the DB change did it.*

**Edit anything** (drag a trim handle, move a slider) → widget calls a `db.updateClip(...)`-style method → stream emits → preview/timeline redraw.

**Undo/redo** → `ProjectHistory` listens to the clips/audio/overlay streams, waits 450 ms of quiet, saves a *snapshot* of all rows (50 deep). Undo = restore a snapshot in one transaction. Because it watches the database, **every new feature that stores its data in those three tables gets undo/redo for free.**

**Export** → section 8.

---

## 7. Preview vs. export — the thing that will bite you in the 25 features

There are **two completely separate renderers**:

| | Live preview | Export |
|---|---|---|
| Engine | Flutter widgets + `video_player` + `just_audio` | one big FFmpeg command |
| Filters | a colour matrix over the video | FFmpeg `eq` filter (same maths) |
| Text | Flutter `Text` widgets | FFmpeg `drawtext` (bundled DejaVu fonts) |
| Transitions | thumbnail-based approximation | real cross-dissolve / dip-to-black |
| Plays across clips? | **No** — loops inside the selected clip (known gap) | yes, whole timeline |

So for **every feature that changes how the video looks or sounds**, you have to build it **twice** (preview + export) and keep them matching. Features that only change the editor UI (e.g. timeline zoom, themes) need no export work. Plan the 25 features with this in mind (section 11).

---

## 8. The export pipeline in detail (`lib/export/`)

```
ExportScreen ──tap──▶ ExportController.start()           export_controller.dart
                        │ keep screen awake, set up notifications
                        ▼
                      ExportService.export()              export_service.dart
                        │ 1 read project rows from the DB
                        │ 2 check every source file still exists
                        │ 3 probe each video: does it have an audio track?
                        │ 4 copy fonts out of the app bundle; write each text to a .txt file
                        │ 5 build the FFmpeg command  ──▶ export_command_builder.dart (pure, tested)
                        │ 6 run it ──▶ ExportEngine.run()   export_engine.dart (only file that touches FFmpegKit)
                        │ 7 if it fails, try the next encoder
                        ▼
                      ExportController: save to gallery (gal), offer Share, show notification
```

**The FFmpeg command (the heart).** `buildExportCommand` writes one `-filter_complex` graph:
1. each clip → trim → set fps (30 unless the user picked 24/60 on the Export screen) → scale + pad to output size → filters (`eq`) → fades; its audio → trim → volume (or generated silence for photos/silent clips)
2. clips joined pairwise with `concat` (cut/fade) or `xfade` + `acrossfade` (dissolve; shortens the video)
3. text → `drawtext` with `enable='between(t,start,end)'`; times shifted earlier after dissolves
4. music → trim → volume → delay → `amix` with the clip audio → limiter
5. encode: **hardware H.264** (`h264_mediacodec` on Android, `h264_videotoolbox` on iOS); fallback **`mpeg4`** (the FFmpegKit build used has no libx264). Audio AAC. Output `ClipForge_<timestamp>.mp4` in the temp folder.

`tools/graph_prototype.py` is the same graph in Python; `tools/verify_export_graph.py` renders it with real FFmpeg and checks duration/size/streams. **If you change the Dart builder, change the Python one and re-run `scripts/dev.sh graph`.**

### Status of the export problem
- I re-ran the graph verifier on real FFmpeg 6.1: **the filter graph itself renders correctly** (720×1280, 9.4 s, h264+aac).
- So the failure is on the app/phone side: FFmpegKit not loading, the encoder, a missing/expired source file, gallery/notification step, or a Dart bug. The code was written without a Flutter SDK and has never been run on a device (see `docs/history/PHASE_8_9_PROGRESS.md`), so nothing in it has been proven on a phone yet.
- Before this cleanup the app **hid the real error**: the FFmpeg log was never printed and the screen said only "failed unexpectedly". Also, if FFmpegKit threw while *starting*, the export would hang at 0% forever. Both are fixed (see "What changed" below).

### How to find the real cause in 2 minutes
1. `scripts/dev.sh run`, build a project with **one clip**, tap Export.
2. If it fails: tap **Copy error details** on the Export screen and read the first lines:
   - `FFmpegKit failed to start …` → the native library isn't loading: wrong ABI (use `run` on a phone, `emu` on an x86_64 emulator), a stale build (`scripts/dev.sh clean`), or — release builds only — R8 stripping it (try `flutter run --release --no-shrink`).
   - `Unknown encoder 'h264_mediacodec'` / `Error while opening encoder` on the first try → normal on some devices/emulators; the app should then retry with `mpeg4`. If **both** attempts fail, the second block of the log is the real error.
   - `No such file or directory` → the clip's source file is gone. The picker copies media into the app *cache*, which Android may clear. Re-import the clip. (Long-term fix: copy imports to the app documents folder.)
   - A `drawtext` / font error → a text overlay problem; delete the text and retry to confirm.
3. Same info live: `scripts/dev.sh logs` (lines starting with `[export]`).
4. Paste the copied details to me and I can fix it directly.

---

## 9. Your daily development loop (this is what makes it fast)

| You changed… | Do this | Time |
|---|---|---|
| UI code (widgets, colours, layout) | save → **hot reload** (`r` in the terminal / ⚡ in the IDE) | ~1 s |
| Provider/state initial values, `main()` | **hot restart** (`R`) | ~3 s |
| A table in `project_database.dart` | `scripts/dev.sh gen`, then restart the app (+ migration, section 10) | ~20 s |
| `pubspec.yaml` dependency, `AndroidManifest.xml`, Gradle, assets, native code | full re-run (`scripts/dev.sh run`) | 1–5 min |
| Pure logic (maths, builders, database ops) | write a **test** and run `flutter test path/to_test.dart` — no phone | ~2 s |

**Rules that keep it fast**
1. Leave `flutter run` open all day. Only stop it for the "full re-run" row above.
2. Always run with `scripts/dev.sh run` (ARM64 only). The default builds FFmpegKit's libraries for 4–5 CPU types, which is the biggest cause of slow Android builds here.
3. Keep logic in **pure functions** (like `export_command_builder.dart`) and test those. A test is 100× faster than tapping through the app.
4. Run `scripts/dev.sh check` before you move on to the next feature. A broken analyzer is much cheaper to fix one feature later than ten.
5. `android/gradle.properties` is currently tuned for a low-RAM machine (2.5 GB Gradle, 2 workers, no parallel). If you have ≥ 16 GB RAM you can raise `org.gradle.jvmargs` to `-Xmx4G`, set `org.gradle.workers.max=4` and `org.gradle.parallel=true`. Don't change it if builds currently succeed and you're unsure of your RAM.
6. Don't commit/ship the `_work/` folder (it's now git-ignored; `verify_export_graph.py` regenerates it).

---

## 10. Recipe: adding a feature (copy this checklist for each of the 25)

Example: **per-clip playback speed**.

1. **Write the spec in one line**: what the user does, what changes in the output.
2. **Schema** (if it needs stored data): add a column in `project_database.dart` (`RealColumn get speed => real().withDefault(const Constant(1.0))();`), bump `schemaVersion`, add `if (from < 6) await m.addColumn(clips, clips.speed);` in `onUpgrade`, run `scripts/dev.sh gen`. Add a migration test next to `project_database_migration_test.dart`.
3. **DB method** to change it (one `update`), if the generic `updateClip` isn't enough.
4. **UI**: a control in the right panel (`trim_panel.dart`, `filter_panel.dart`, or a new panel) that calls the DB method. It reads the clip via `ref.watch(clipsProvider(...))`. Because history watches the DB, undo works automatically.
5. **Preview**: make `VideoPreviewPlayer` honour it (`controller.setPlaybackSpeed`).
6. **Export**: extend `ExportClip` (`export_models.dart`), map it in `export_inputs.dart`, add the FFmpeg bit in `export_command_builder.dart` (`setpts=PTS/speed`, `atempo=speed`), and **update `durationMs` maths** — speed changes the clip's rendered length, which affects transitions, text timing and music.
7. **Mirror it in `tools/graph_prototype.py`**, run `scripts/dev.sh graph`.
8. **Test** the pure parts, then `scripts/dev.sh check`.
9. **Try it on the phone** with a project that uses the new feature *and* an old feature (regressions hide there).

Skip steps 5–7 for UI-only features. Skip 2–3 for features that need no saved data.

---

## 11. Planning the 25 features (rapid prototyping advice)

Sort every feature into one of three buckets *before* you start; the bucket decides the cost:

| Bucket | Examples | Cost |
|---|---|---|
| **A. UI-only** | timeline tweaks, themes, project rename/duplicate, onboarding, settings | cheap — a widget + maybe a provider |
| **B. Preview + export** | speed, crop/zoom, rotate, stickers, picture-in-picture, new filters, audio fades | 2–3× — see recipe |
| **C. Needs native/new plugin** | foreground service for long exports, voice-over recording, video stabilisation, AI features | expensive — slow rebuilds, plugin quirks |

Suggested order: **fix export first** (everything in bucket B depends on it), then all bucket A, then B ordered by "touches fewest files", and C last.

Ground rules that protect a fast-moving prototype:
- One feature = one small commit. If something breaks you know which.
- Never skip the migration when you add a column — upgrading installs crash otherwise.
- After each B-feature, export a project **using all features so far** at least once.
- Keep `README`/this guide updated in one line when you add a table or screen.

---

## 12. Known gaps and traps (honest list)

- **Export has never been run on a device** (written without an SDK). Treat every export-related claim as unproven until you've exported once on a real phone.
- **Imports live in the cache folder.** The system can delete them → "source missing" at export. Safer: copy picked files into the documents directory on import.
- **No cross-clip playback in preview** (loops inside one clip). Export is fine.
- **Preview shows thumbnails for transitions**, export renders real ones — they won't look identical.
- **Whole editor body rebuilds on every playhead tick** (`EditorScreen._buildBody` watches `playheadMsProvider`). Fine now; becomes laggy with many clips. Fix: move that watch into small `Consumer` widgets.
- **Text**: size is scaled assuming a 360-px-wide preview; left/right alignment isn't applied in export (always centred); "Cursive" maps to a serif italic.
- **HEIC photos** often can't be decoded by FFmpeg.
- **Long exports can be killed by Android** when the app is backgrounded (needs a native foreground service; not built).
- **No libx264**: the fallback `mpeg4` encoder is slower and bigger-file than H.264. Fine for prototyping.
- **Free disk space isn't pre-checked**; the app only notices when the write fails.
- Generated files (`*.g.dart`) are committed so tests run without `build_runner`; remember to regenerate after table edits or the app won't compile.

---

## 13. Glossary

- **Widget** – a building block of the screen (button, text, list). Screens are trees of widgets.
- **Hot reload / restart** – push code changes into the running app in ~1–3 s without reinstalling.
- **Provider** – a named, shared piece of data/logic Riverpod hands to any widget.
- **`ref.watch` / `ref.read`** – read a provider and *redraw when it changes* / read it once.
- **Stream** – data that arrives repeatedly over time; Drift streams re-emit whenever the table changes.
- **Migration** – code that upgrades an existing user's database to the new table layout.
- **Codegen / build_runner** – tool that writes the `*.g.dart` files from your table definitions.
- **ABI** – the CPU type (arm64-v8a = nearly all modern phones; x86_64 = most emulators).
- **Encoder** – the part that turns raw frames into H.264/MPEG-4 video.
- **Filter graph** – FFmpeg's wiring diagram of video/audio steps (`-filter_complex`).
- **Non-destructive** – edits are stored as instructions, originals never change.

---

## What changed in this cleanup
- Removed `_work/` (5.6 MB of generated test media; now git-ignored) and an empty `flutter/` folder.
- Moved the six `PHASE_*_PROGRESS.md` files to `docs/history/`; rewrote the stale README (it still described "Phase 2" and mentioned files that don't exist).
- Added `scripts/dev.sh` (fast ARM64 run, check, codegen, graph test, export logs) and `org.gradle.caching=true`.
- Export diagnostics: failures now carry encoder + full FFmpeg command + log tail, printed as `[export] FAILED …` and copyable from the Export screen; unexpected Dart errors print a stack trace; a failure to *start* FFmpegKit now ends the export with an error instead of hanging.
- **Not verified:** these Dart edits were made without a Dart/Flutter SDK (none is available in my environment). Run `scripts/dev.sh check` first; if the analyzer complains about anything in `lib/export/` or `export_screen.dart`, send me the message.
