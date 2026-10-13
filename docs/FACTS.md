# ClipForge — verified facts, known bugs, and unknowns

**Purpose:** the single place Claude (and you) can check "is this actually true?" before building.
**Snapshot:** repo zip `clipforge-clean (1).zip`, checked 2026-10-11. Re-verify a line if the file it cites has changed.

Legend: ✅ verified (how is stated) · ⚠️ NOT verified · 🐞 known bug · 📚 doc drift (an older doc was wrong).
"Read" = confirmed by reading the cited file. "Ran" = executed in the review environment.

**What could NOT be run in the review environment:** no Flutter/Dart SDK, no Android device/emulator, no Gradle build. So `flutter analyze`, `flutter test`, the Dart export builder, FFmpegKit on a phone and the release build have **not** been run by the reviewer.

---

## 1. Identity and build configuration
| ID | Fact | Evidence |
|---|---|---|
| F-01 ✅ | Product name ClipForge; Dart package name is `video_editor_app` (version `0.1.0`, no `+build` number). | Read `pubspec.yaml` |
| F-02 ✅ | Android `namespace` and `applicationId` = `com.ayushstudio.clipforge`. | Read `android/app/build.gradle.kts` |
| F-03 ✅ | `minSdk = max(24, flutter.minSdkVersion)` (FFmpegKit needs API 24+). | Read `build.gradle.kts:26` |
| F-04 ✅ | `targetSdk` and `compileSdk` come from the **installed Flutter SDK** (`flutter.targetSdkVersion`), not pinned in the repo. | Read `build.gradle.kts:27` |
| F-05 ✅ | Gradle wrapper 8.14.3; AGP 8.11.1; Kotlin plugin 2.2.20; Java/Kotlin target 17; core-library desugaring enabled (desugar_jdk_libs 2.1.4). | Read `gradle-wrapper.properties`, `settings.gradle.kts`, `build.gradle.kts` |
| F-06 ✅ | **Release builds are signed with the debug key** (`signingConfig = signingConfigs.getByName("debug")`, marked TODO). | Read `build.gradle.kts` release block |
| F-07 ✅ | `android/.gitignore` already ignores `key.properties`, `*.keystore`, `*.jks`. | Read `android/.gitignore` |
| F-08 ✅ | No `proguard-rules.pro` / R8 config file in the repo. | `find android -name "proguard*"` → none |
| F-09 ✅ | Launcher label is `clipforge` (lowercase) in the manifest; `MaterialApp.title` is `Video Editor`; share text is `Made with ClipForge`. | Read `AndroidManifest.xml`, `main.dart`, `gallery_share_service.dart` |
| F-10 ✅ | `lib/` is ~10.1k lines of Dart (3.6k of it generated `project_database.g.dart`); 8 unit-test files + `test/support/`. | Ran `wc -l` |
| F-11 ⚠️ | `pubspec.lock` records `sdks: dart >=3.13.0, flutter >=3.44.0`, while `pubspec.yaml` says `sdk: >=3.3.0 <4.0.0`. The lock is the stricter truth; confirm your installed `flutter --version` satisfies it. | Read both files; not checked against an installed SDK |

## 2. Permissions (Android)
| ID | Fact | Evidence |
|---|---|---|
| F-20 ✅ | Main manifest declares: `READ_MEDIA_VIDEO`, `READ_MEDIA_IMAGES`, `READ_MEDIA_AUDIO`, `READ_EXTERNAL_STORAGE` (maxSdk 32), `WRITE_EXTERNAL_STORAGE` (maxSdk 28), `RECORD_AUDIO`, `POST_NOTIFICATIONS`. | Read `AndroidManifest.xml` |
| F-21 ✅ | `HomeScreen.initState` calls `PermissionService.requestMediaPermissions()` on Android/iOS at first paint. It requests photos, videos, storage **and microphone**. | Read `home_screen.dart:23-35`, `permission_service.dart` |
| F-22 ✅ | Nothing in `lib/` records audio (voice-over is feature F20, not built). `RECORD_AUDIO` is therefore declared and prompted **without a feature that uses it**. | `grep` for record/mic usage |
| F-23 ✅ | Media is imported through `image_picker` (`pickVideo`/`pickImage`) and audio through `file_picker`. | Read `media_import_service.dart`, `audio_import_service.dart` |
| F-24 ✅ | `INTERNET` is declared only in the `debug` (and profile) manifests, **not** in `main`. | Read `app/src/*/AndroidManifest.xml` |
| F-25 ⚠️ | The **merged release manifest** (after plugin manifests are merged) has not been inspected. Plugins can add permissions. Check it — command in `docs/LAUNCH_CHECKLIST.md` §3. | not run |

## 3. Offline / privacy facts (used for the Play Data-safety form)
| ID | Fact | Evidence |
|---|---|---|
| F-30 ✅ | No network permission in the main manifest (see F-24). | Read |
| F-31 ✅ | `pubspec.yaml` has no analytics, crash-reporting, ads, auth or HTTP package. | `grep` for firebase/crashlytics/sentry/admob/analytics → none |
| F-32 ✅ | `lib/` contains no `http`/`dio`/socket code. | `grep` |
| F-33 ✅ | The only data that leaves the app is what the user sends via the share sheet (`share_plus`) or saves to the gallery (`gal`). | Read `gallery_share_service.dart` |
| F-34 ⚠️ | Re-confirm F-30 against the **merged** manifest (F-25) before filling the Data-safety form. | not run |

## 4. Data layer
| ID | Fact | Evidence |
|---|---|---|
| F-40 ✅ | `schemaVersion = 5`. Tables: `Projects`, `Clips`, `AudioTracks`, `TextOverlays`. Migrations exist for 1→2, 2→3, 3→4, 4→5. | Read `project_database.dart` |
| F-41 ✅ | DB file: `<app documents dir>/project_db.sqlite`, opened with `NativeDatabase.createInBackground`. | Read `_openConnection` |
| F-42 ✅ | Undo/redo snapshots only Clips + AudioTracks + TextOverlays (`ProjectSnapshot`). **Projects row (name, aspect ratio) is not in undo.** | Read `ProjectSnapshot`, `restoreProject` |
| F-43 ✅ | History: 450 ms debounce, 50-step limit; each capture re-reads **all** rows of the project. | Read `project_history.dart` |
| F-44 ✅ | No `PRAGMA foreign_keys` / `beforeOpen` anywhere → the `references(...)` columns are **not enforced** by SQLite; deleting a project would leave orphan rows unless code deletes children. | `grep` in `lib/` |
| F-45 ✅ | F1 shipped 2026-10-11: `ProjectDatabase.renameProject`/`deleteProjectCascade`/`duplicateProject` plus a ⋮ menu on each Home project card. Not yet run on a device/SDK (see note at the top of this file). | Read `project_database.dart`, `home_screen.dart`; `test/project_crud_test.dart` (not run, no SDK) |
| F-46 ✅ | A project has **one** audio track (`getAudioTrack`/`watchSingleOrNull`). | Read |
| F-47 ✅ | New projects are created as "Untitled Project" with the default aspect ratio 9/16; no aspect-ratio picker exists (planned as F6). | Read `home_screen.dart`, table default |
| F-48 ✅ | App prefs are one JSON file `clipforge_prefs.json` in the documents dir (`onboardingDone`, `lastProjectId`, and since 2026-10-13 `exportQuality` + `exportFps`). | Read `app_prefs.dart` |
| F-49 ✅ | F2 shipped 2026-10-13: `ProjectDatabase.duplicateClip(clipId, {newClipId})` inserts a copy at orderIndex+1 and shifts later clips in one transaction; the original's `transitionOut` becomes `cut` and the copy inherits it. Button "Duplicate clip" in `TrimPanel`. Undo works through the existing Clips snapshot. Not run on a device/SDK. | Read `project_database.dart`, `trim_panel.dart`; `test/duplicate_clip_test.dart` (not run, no SDK) |

## 5. Import and storage
| ID | Fact | Evidence |
|---|---|---|
| F-50 ✅ | P1 shipped 2026-10-11: `image_picker`/`file_picker` still hand back a path in the OS-clearable cache dir, but `MediaImportService`/`AudioImportService` now copy it into `<documents>/imported_media/` via `MediaStorageService` before it's ever stored as `sourceUri`. A `MediaRepairService` sweep (run once per launch from `LaunchGate`) also repairs rows from projects imported before this pass, where the file still exists. Rows whose cache file is already gone can't be repaired and still fail export with "source missing" — same as before P1. ⚠️ Not run on a device (no SDK here); `isInCache`'s cache-dir detection (`getTemporaryDirectory()` + `getApplicationCacheDirectory()`) is unverified against where `image_picker`/`file_picker` actually place files on a real phone. | Read `media_storage_service.dart`, `media_repair_service.dart`, `media_import_service.dart`, `audio_import_service.dart`, `launch_gate.dart`; tests in `test/media_storage_service_test.dart`, `test/media_repair_service_test.dart` (not run, no SDK) |
| F-51 ✅ | Import order per video: `VideoPlayerController.initialize()` → FFprobe rotation → thumbnail (sequential, on purpose). | Read `_buildVideoAsset` |
| F-52 ✅ | Thumbnails: 320 px wide JPEG q75 cached in `<cache>/thumbnails/<name>_<mtime>.jpg`. Cache dir is also clearable by the OS. | Read `thumbnail_service.dart` |
| F-53 ✅ | Timeline thumbnails decode at `cacheWidth: 240`; preview photos at 720/1440. | Read `timeline_clip_tile.dart:155`, `video_preview_player.dart:513,535` |
| F-54 ✅ | `video_thumbnail` is a **local patched copy** (`third_party/video_thumbnail`, MIT) wired via `dependency_overrides`. | Read `pubspec.yaml`, `LICENSE` |

## 6. Export pipeline
| ID | Fact | Evidence |
|---|---|---|
| F-60 ✅ | Quality presets: `p480` (short side 480, 2.5 Mbit/s), `p720` (720, 5 Mbit/s) and `p1080` (1080, 10 Mbit/s); frame rate 24/30/60 (default 30), 60 fps uses 1.5× the base bitrate (`exportVideoBitrate`) (changed 2026-10-13, F5). AAC 192 kbit/s @ 44.1 kHz, `+faststart`, `yuv420p`. | Read `export_models.dart`, `export_command_builder.dart` |
| F-61 ✅ | Encoder order: Android → `h264_mediacodec`, iOS → `h264_videotoolbox`, then `mpeg4` fallback (the non-GPL FFmpegKit build has no libx264). | Read `export_service.dart`, `export_models.dart` |
| F-62 ✅ | If the first encoder fails, the next is tried unless the failure is *disk full* or *source missing*. | Read `export_service.dart` |
| F-63 ✅ | Transitions supported in export: `cut`, `fade` (dip to black, ≤300 ms), `dissolve` (xfade `fade`, ≤600 ms, shortens output). Unknown names behave as `cut`. | Read `_boundaryAfter` |
| F-64 ✅ | Text is rendered with `drawtext` from per-overlay **text files** (avoids escaping bugs); 4 bundled DejaVu fonts; alignment is not honoured (always centred on `positionX`). | Read builder + `export_service.dart` |
| F-65 ✅ | Music is mixed with `amix … normalize=0` then `alimiter=limit=0.97`; offset is remapped after dissolves. | Read builder |
| F-66 ✅ | Output goes to `<temp>/export_<ms>/ClipForge_<ms>.mp4`; export folders older than 1 day are pruned at the next export; saved to the gallery album `ClipForge` via `gal`. | Read `export_service.dart`, `gallery_share_service.dart` |
| F-67 ✅ | **Ran** `tools/verify_export_graph.py` (the *Python* copy of the graph) on desktop FFmpeg 6.1.1: output 720×1280, 9.4 s, h264 + aac → "OK"; re-ran 2026-10-13 with F5, which also renders 480p@24 (480×854) and 720p@60 (720×1280) → "OK". This proves the filter graph logic, **not** the Dart builder, FFmpegKit, or the phone encoder. | Ran 2026-10-11 |
| F-68 ✅ | The wake lock is held during export; there is **no** foreground service (planned F22). | Read `export_controller.dart`, manifest |

## 7. Preview / editor
| ID | Fact | Evidence |
|---|---|---|
| F-70 ✅ | Preview plays **one clip at a time**; it loops inside the selected clip and does not continue across a clip boundary (planned F21). | Read class comment in `video_preview_player.dart` |
| F-71 ✅ | `EditorScreen._buildBody` calls `ref.watch(playheadMsProvider)` (`editor_screen.dart:366`) → the whole editor body rebuilds on every playhead tick. | Read |
| F-72 ✅ | Preview and timeline are wrapped in `RepaintBoundary`. | Read `editor_screen.dart` |
| F-73 ✅ | Navigation is plain `Navigator` with 3 routes: `/` (LaunchGate → onboarding or Home), `/editor`, `/export`. | Read `app_router.dart` |
| F-74 ✅ | F4 shipped 2026-10-13: a `PlayheadControls` row under the scrub bar (previous/next clip, ±1 frame at 30 fps, `m:ss:ff` timecode, snap toggle). Pure helpers (`clipBoundariesMs`, `previousBoundaryMs`, `nextBoundaryMs`, `stepFrameMs`, `snapToBoundaryMs`, `formatTimecode`) live in `models/clip_x.dart`; every playhead move goes through `seekTimeline` (`playhead_controls.dart`). Snap is off by default and not persisted (`snapScrubProvider`). Only the timecode `Consumer` watches the playhead (F-71 is unchanged). Not run on a device/SDK. | Read `playhead_controls.dart`, `timeline_scrub_bar.dart`, `editor_screen.dart`; `test/playhead_tools_test.dart` (not run, no SDK; the frame-step arithmetic was simulated in Python) |

## 8. Assets and licences
| ID | Fact | Evidence |
|---|---|---|
| F-80 ✅ | `assets/` is 3.3 MB: 3 WAV loops (14 s, 12 s, 10 s — `retro_pulse`, `ambient_drift`, `gentle_morning`) and DejaVu fonts (Sans, Serif, Serif-Italic, Sans-Mono). | Ran `du`, `ffprobe` |
| F-81 ⚠️ | **Licence/provenance of the 3 WAV loops is unknown**: the files carry no metadata tags and no licence file exists. You must confirm you created them or hold a licence that allows commercial redistribution. | Ran `ffprobe` (no tags) |
| F-82 ✅ | DejaVu fonts ship with their licence file (Bitstream Vera licence + public-domain changes). | Read `assets/fonts/LICENSE-DejaVu.txt` |
| F-83 ✅ | `ffmpeg_kit_flutter_new_full` is the LGPL-3.0 "Full" variant (no GPL libraries, no libx264). | pub.dev package page (search 2026-10-11) |
| F-84 ✅ | P2 shipped 2026-10-12: `assets/dev/` (~60 KB — 2 synthetic h264 clips + 1 JPEG, generated with desktop `ffmpeg lavfi` sources, no licence question) backs a `kDebugMode`-gated "Load sample project" button in Home's app bar (`sample_project_service.dart`). These assets ship in **every** build, debug or release — pubspec assets aren't build-mode-conditional — so `assets/` is now ~3.36 MB, not 3.3 MB (F-80). Negligible for the Play 16 KB-page/size checks, but flagging per `docs/LAUNCH_CHECKLIST.md`'s APK-size note. | Read `pubspec.yaml`, `sample_project_service.dart`, `home_screen.dart`; `du -sh assets/dev` |

---

## 9. 🐞 Known bugs (read from code; not reproduced on a device)
| ID | Bug | Where | Impact |
|---|---|---|---|
| B-01 ✅ fixed 2026-10-12 | `splitClip` creates the second half **without copying `volume` and `filterPreset`** (it copies rotation, thumbnail, transition, brightness/contrast/saturation, muted). The second half returns to volume 1.0 and loses its preset label. | `project_database.dart` `splitClip` | Fixed: both fields are now copied to the second half. Covered by `test/split_clip_test.dart` (not run, no SDK). |
| B-02 ✅ fixed 2026-10-12 | `splitClip` copies `transitionOut` to the new clip **and the original keeps its own**, so the first half now has a transition *into its own second half*. | same | Fixed: the first half is now forced to `cut` at the new boundary; the second half inherits the original's outgoing transition. Covered by `test/split_clip_test.dart` (not run, no SDK). |
| B-03 🐞 | Release build is debug-signed (F-06). | `build.gradle.kts` | Play Console rejects it / cannot be updated later with a proper key. |
| B-04 🐞 | Microphone + media permissions are requested at launch although unused / picker-based (F-21, F-22). | `permission_service.dart`, manifest | Play review risk, and a poor first-run experience. |

## 10. 📚 Doc drift (older docs vs. code)
| ID | Older claim | Truth |
|---|---|---|
| D-01 📚 | Earlier project notes mention a `TimelinePreviewPlayer` that plays across clip boundaries. | **Does not exist in this repo** (`grep` finds nothing). Preview is single-clip (F-70). |
| D-02 📚 | `APP_GUIDE.md` §8/§12 says export "has never been run on a device". | May still be true — **owner must confirm** (U-01). Do not assume export works on a phone until it has been run. |
| D-04 📚 | The header comment of `export_engine.dart` says "All FFmpegKit usage is confined to this file". | FFprobeKit is also imported in `media_metadata_service.dart` and `audio_metadata_service.dart` (read-only probing). Compositing/execution is only in `export_engine.dart`. |
| D-03 📚 | `APP_GUIDE.md` §4 lists `docs/history/` as old notes. | Still true; those files describe the build process and can contradict the current code. |

## 11. ⚠️ Unknowns — ask the owner or test; do **not** guess
| ID | Question | How to settle it |
|---|---|---|
| U-01 | Has a real phone ever exported an MP4 successfully (1 clip, then 3 clips)? | Run `docs/TESTING.md` §3 scenario E1–E3 |
| U-02 | Does the **release** build (R8/shrinking) still load FFmpegKit? | Install a `--release` build on a phone; export |
| U-03 | Are FFmpegKit's native libraries 16 KB-page aligned in version 2.5.7? | `bash tools/check_16kb.sh app-release.aab` |
| U-04 | What `targetSdk` does your installed Flutter produce? (Play requires 36 for new apps/updates since 2026-08-31.) | Inspect built AAB / set `targetSdk = 36` explicitly |
| U-05 | Merged-manifest permission list (F-25). | `docs/LAUNCH_CHECKLIST.md` §3 |
| U-06 | Is your Play developer account personal (created after 2023-11-13) or an organisation? | Play Console → account details. Decides whether production is possible today (`LAUNCH_CHECKLIST.md` §0) |
| U-07 | Provenance/licence of the 3 audio loops (F-81). | Owner answers |
| U-08 | Does the *Dart* export builder produce exactly the same graph as the Python prototype? | Dart tests in `test/export_command_builder_test.dart` (not run by the reviewer) + a real export |

---
*Update rule:* when a fact changes, edit the line, keep its ID, and append `(changed YYYY-MM-DD)`.
