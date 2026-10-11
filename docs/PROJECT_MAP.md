# ClipForge — what every folder and file is

Put this at `D:\Video editor\docs\PROJECT_MAP.md`. It answers "what is this file and may I touch it?".

**Tags:** `EDIT` you change it while building features · `RARE` only occasionally · `NEVER` generated or managed by a tool, don't edit by hand · `DELETABLE` safe to delete, it is rebuilt automatically

---

## 1. The top level of `D:\Video editor`

| Item | What it is | Tag |
|---|---|---|
| `lib\` | **The app's Dart code.** Nearly everything you build lives here (section 2). | EDIT |
| `test\` | Automated tests for the pure logic. Run in seconds, no phone. | EDIT |
| `assets\` | Files packed into the app: 3 music loops, DejaVu fonts (used for text in exports). | RARE |
| `android\` | The Android "shell" that Flutter wraps your Dart code in. Permissions, build settings, app icon. | RARE |
| `ios\` `macos\` `linux\` `windows\` `web\` | The same kind of shell for other platforms. The app is built for phones, so you can ignore them. They are tiny; leave them. | NEVER |
| `third_party\video_thumbnail\` | A patched local copy of the `video_thumbnail` plugin. `pubspec.yaml` points at it so the Android build works with your Gradle version. Don't delete. | NEVER |
| `tools\` | Python scripts that test the export recipe on your computer using real FFmpeg. | RARE |
| `scripts\dev.sh` | Shortcut commands. It's a bash script, so on Windows it needs Git Bash or WSL; PowerShell equivalents are in section 7. | RARE |
| `docs\` | Documentation: `APP_GUIDE.md`, `FEATURE_PLAN_25.md`, this file, and `history\` (old phase notes). | EDIT |
| `pubspec.yaml` | **The app's shopping list**: name, version, every package it uses, which asset folders to include. | EDIT |
| `pubspec.lock` | The exact versions `pub get` picked. Auto-written. Commit it, don't edit it. | NEVER |
| `analysis_options.yaml` | Rules for the code checker (`flutter analyze`) and which folders it ignores. | RARE |
| `.gitignore` | Tells git which files not to track (build output, the SDK copy, scratch). | RARE |
| `.metadata` | Flutter's note of which Flutter version created the project. | NEVER |
| `README.md` | Short "how to run it" page. | RARE |
| `.dart_tool\` | Flutter/Dart's private cache for this project (package locations, build_runner cache). Recreated by `flutter pub get`. | DELETABLE |
| `build\` | Compiled output (APKs, intermediate files). It was 1.8 GB. Recreated by the next build. | DELETABLE |
| `.flutter-plugins-dependencies` | Auto-generated list of the plugins in use. | DELETABLE |
| `.git\` | Your git history. 82 MB. Deleting it erases your history. | NEVER |
| `.vscode\` | Your VS Code settings for this project. I haven't seen its contents; it is harmless. | RARE |
| `_work\` | Scratch media made by `tools\verify_export_graph.py`. Already deleted; it comes back if you run that script. | DELETABLE |
| `flutter\` | **A 2.3 GB copy of the Flutter SDK inside your project.** Your `android\local.properties` points to `D:\flutter`, so Android builds use *that* copy, not this one (section 8 explains what to do). | see section 8 |

---

## 2. `lib\` — the app itself

Read in this order if you want to understand it: `main.dart` → `router` → `screens` → `providers` → `data` → `widgets` → `export`.

### `lib\main.dart`  `RARE`
App entry. Wraps everything in `ProviderScope` (Riverpod's storage), sets the dark purple Material 3 theme, starts at the Home route.

### `lib\router\`
| File | Does |
|---|---|
| `app_router.dart` | Three screens and how to open them: `/` (launch gate → Home), `/editor` (needs a project id), `/export` (needs a project id). Plain Flutter `Navigator`. Add new screens here. `EDIT` |

### `lib\app\` — first-launch and settings
| File | Does |
|---|---|
| `launch_gate.dart` | Decides: first run → onboarding, otherwise Home. |
| `onboarding_screen.dart` | The 3-page intro. |
| `app_prefs.dart` | A tiny settings store: one JSON file (`clipforge_prefs.json`) that remembers "onboarding done" and "last project". Put new simple settings here (e.g. last export quality). `EDIT` |

### `lib\screens\` — the three full screens
| File | Does |
|---|---|
| `home_screen.dart` | Project list, "New project", the "Resume last project" card. Asks for media permission on first launch. |
| `editor_screen.dart` | **The biggest file (649 lines).** Lays out the preview on top, timeline strip, scrub bar, music lane, text lane, and the bottom panels (Trim / Filters / Music / Text). Starts media imports and opens Export. Most UI features touch it. `EDIT` |
| `export_screen.dart` | Quality picker → progress bar → "ready" (Share / Save to gallery) or "failed" (Try again / **Copy error details**). |

### `lib\data\` — the database (source of truth)
| File | Does |
|---|---|
| `project_database.dart` | **Defines the 4 tables** (Projects, Clips, AudioTracks, TextOverlays) and every read/write function (append clip, reorder, split, delete, apply filter to all, snapshot/restore for undo…). Also the migrations (`schemaVersion` is 5). Edit this when a feature needs stored data. `EDIT` |
| `project_database.g.dart` | **Generated** by Drift from the file above (138 KB). Never edit. Regenerate with `dart run build_runner build --delete-conflicting-outputs` after changing a table. `NEVER` |
| `database_provider.dart` | Makes one shared database object available to the whole app. |

### `lib\providers\` — "live views" of the database
| File | Does |
|---|---|
| `timeline_providers.dart` | `clipsProvider` (live list of clips), `selectedClipIdProvider`, `playheadMsProvider` (current time on the timeline), `timelineZoomProvider`. |
| `audio_providers.dart` | `audioTrackProvider` (the music track), `audioPanelOpenProvider`. |
| `text_overlay_providers.dart` | `textOverlaysProvider`, selected text id, text-panel-open flag. |

Idea: a widget does `ref.watch(clipsProvider(id))` and redraws itself whenever the database changes.

### `lib\models\` — small helper types and pure maths (no screens)
| File | Does |
|---|---|
| `media_asset.dart` | A picked photo/video before it becomes a clip: path, duration, size, rotation, thumbnail. |
| `audio_asset.dart` | A picked music file: path, duration, name. |
| `bundled_track.dart` | The 3 built-in music loops and their lengths. |
| `clip_x.dart` | Timeline layout maths: where each clip starts/ends, and "which clip is under the playhead" (`layoutTimeline`, `positionAt`). |
| `color_filter_x.dart` | Brightness/contrast/saturation → colour matrix for the preview, plus the filter presets. |
| `transition_x.dart` | Transition preview maths (how the thumbnail cross-fade looks near a boundary). |
| `text_overlay_x.dart` | Text-overlay maths: visible at time T?, font presets, letterbox position/drag mapping. |

### `lib\history\` — undo/redo + autosave
| File | Does |
|---|---|
| `history_stack.dart` | A generic undo/redo stack (no Flutter code, so it is unit-tested). |
| `project_history.dart` | Watches the database, takes a snapshot 450 ms after a burst of edits (50 deep), restores one on undo/redo, stamps "Saved HH:mm". |

### `lib\services\` — talks to the phone
| File | Does |
|---|---|
| `media_import_service.dart` | Opens the gallery, reads size/duration (`video_player`), rotation (FFprobe), makes a thumbnail → a `MediaAsset`. |
| `audio_import_service.dart` | Picks a music file or copies a bundled loop out of the app package into a real file. |
| `media_metadata_service.dart` | Reads a video's rotation flag with FFprobe. |
| `audio_metadata_service.dart` | Reads a music file's duration with FFprobe. |
| `thumbnail_service.dart` | Makes and caches a JPEG thumbnail per video. |
| `permission_service.dart` | Asks Android/iOS for photo/video/mic permission. |

### `lib\widgets\` — reusable screen pieces
| File | Does |
|---|---|
| `video_preview_player.dart` | **The preview.** Plays the clip under the playhead with `video_player`, plays music with `just_audio`, applies filters, shows photos, reports its position back. 563 lines. |
| `text_overlay_layer.dart` | Draws text on the preview and lets you drag it. |
| `history_actions.dart` | Undo/redo buttons + the "Saved" label in the app bar. |
| `common\state_views.dart` | Shared Loading / Empty / Error screens. |
| `timeline\timeline_strip.dart` | The row of clip thumbnails: long-press to reorder, pinch to zoom. |
| `timeline\timeline_clip_tile.dart` | One thumbnail tile + the transition button between tiles. |
| `timeline\timeline_scrub_bar.dart` | The bar you drag to move the playhead. |
| `timeline\trim_panel.dart` | Trim handles, split at playhead, delete, mute/volume for the selected clip. |
| `timeline\filter_panel.dart` | Brightness/contrast/saturation sliders, preset chips, "apply to all". |
| `timeline\audio_track_panel.dart` | Music trim, offset, volume, remove. |
| `timeline\audio_track_lane.dart` | The thin lane showing where the music sits on the timeline. |
| `timeline\text_overlay_panel.dart` | Text content, font, size, colour, alignment, start/end. |
| `timeline\text_overlay_strip.dart` | Lane showing every text's time range. |

### `lib\export\` — turning the project into an MP4
| File | Does |
|---|---|
| `export_models.dart` | Plain data types: `ExportQuality` (720p/1080p), `ExportClip`, `ExportOverlay`, `ExportMusic`, `VideoEncoder`, `ExportFailure(Kind)`. |
| `export_inputs.dart` | Converts database rows into those plain types; decides photo vs video by file extension. |
| `export_command_builder.dart` | **The heart:** builds the long FFmpeg command (trim, scale, filters, transitions, text, music, encoder). Pure code, fully tested. `EDIT` |
| `export_engine.dart` | The only file that touches FFmpegKit: runs the command, collects the log and progress, can cancel. Never hangs now if FFmpeg fails to start. |
| `export_service.dart` | Orchestrates: loads rows, checks files exist, probes audio, writes fonts/text files, runs the command, retries with the next encoder, classifies failures, prints/records the error details. |
| `export_controller.dart` | Holds export state for the screen (idle/running/done/failed), keeps the screen awake, notifications, saves to gallery. |
| `export_notifier.dart` | The progress and "export complete/failed" notifications. |
| `gallery_share_service.dart` | Saves to the gallery (`gal`) and opens the share sheet (`share_plus`). |

---

## 3. `test\`
| File | Tests |
|---|---|
| `export_command_builder_test.dart` | The FFmpeg command text for various projects. |
| `export_failure_classification_test.dart` | FFmpeg log → "disk full / missing file / bad codec". |
| `history_stack_test.dart` | Undo/redo stack. |
| `project_database_migration_test.dart` | Old database versions upgrade correctly. |
| `color_filter_matrix_test.dart` | Filter maths. |
| `transition_preview_test.dart` | Transition preview maths. |
| `text_overlay_timing_test.dart` | When text is visible. |
| `text_overlay_layer_math_test.dart` | Letterbox and drag position maths. |
| `support\legacy_v3_database.dart` (+ `.g.dart` generated) | A stand-in "old version-3 database" used by the migration test. |

Run all: `flutter test`. Run one: `flutter test test\history_stack_test.dart`.

---

## 4. `assets\`
`audio\` three WAV loops (`gentle_morning`, `retro_pulse`, `ambient_drift`) · `fonts\` four DejaVu fonts + licence, needed because FFmpeg can't use the phone's system fonts for exported text · `images\` empty (`.gitkeep` only exists because Flutter fails the build if a declared folder is missing).

---

## 5. `android\` (the Android shell)
| File | Does |
|---|---|
| `local.properties` | **Your machine's paths** (Flutter SDK `D:\flutter`, Android SDK). Auto-generated, never commit. |
| `settings.gradle.kts` | Which Gradle plugins/versions to use (Android Gradle Plugin 8.11.1, Kotlin 2.2.20). Reads the Flutter path from `local.properties`. |
| `build.gradle.kts` | Top-level build config; moves build output to `D:\Video editor\build`. |
| `gradle.properties` | Build tuning: memory (2.5 GB), 2 workers, caching on. Edit this to tune build speed. |
| `gradle\wrapper\gradle-wrapper.properties` | Which Gradle version to download (8.14.3). |
| `app\build.gradle.kts` | **App-level config:** app id `com.ayushstudio.clipforge`, minSdk 24 (FFmpegKit needs it), Java 17, desugaring for notifications, release signing (debug keys for now). |
| `app\src\main\AndroidManifest.xml` | **Permissions** (photos, video, audio, mic, notifications) and the main activity. Edit when a feature needs a new permission. |
| `app\src\debug\` and `profile\` AndroidManifest | Extra permissions for debug/profile builds (internet for hot reload). |
| `app\src\main\kotlin\…\MainActivity.kt` | The 1-class Kotlin entry point. You'd edit it only for native code (e.g. a foreground service). |
| `app\src\main\res\` | App icon (`mipmap-*`), splash/launch background (`drawable*`), theme (`values*`). |

## 6. Other platform folders (leave alone)
- `ios\` — `Runner\Info.plist` holds iPhone permission texts; `Podfile` isn't present because it's generated on a Mac. 
- `macos\`, `linux\`, `windows\`, `web\` — standard Flutter shells (icons, CMake, `index.html`). The app is not tuned for them.

## 7. `tools\`, `scripts\`, `third_party\`, `docs\`
| Path | Does |
|---|---|
| `tools\graph_prototype.py` | The export recipe written in Python (reference copy of the Dart builder). |
| `tools\verify_export_graph.py` | Renders a test project with real FFmpeg and checks length, size, streams. Needs `ffmpeg` and `python` installed. |
| `scripts\dev.sh` | Shortcuts. **PowerShell equivalents:** run: `flutter run --target-platform android-arm64` · check: `flutter analyze; flutter test` · generate DB code: `dart run build_runner build --delete-conflicting-outputs` · watch: `dart run build_runner watch --delete-conflicting-outputs` · clean: `flutter clean; flutter pub get` · export logs: `adb logcat -c; adb logcat \| Select-String "ffmpeg","\[export\]"` |
| `third_party\video_thumbnail\` | Patched plugin copy (see section 1). |
| `docs\history\` | The old per-phase progress notes. |

---

## 8. The `flutter\` folder inside the project (read this)
- Your build uses `D:\flutter` (see `android\local.properties`). Android builds do **not** use `D:\Video editor\flutter`.
- Earlier today you ran `.\flutter\bin\flutter pub get`, so Dart's package file `.dart_tool\package_config.json` may now point at the *inner* SDK.
- **To remove the 2.3 GB copy safely:**
  1. Check the outer SDK exists: `Test-Path D:\flutter\bin\flutter.bat` (must say `True`).
  2. Use it from now on: `D:\flutter\bin\flutter pub get` (or add `D:\flutter\bin` to PATH).
  3. Run `D:\flutter\bin\flutter analyze` once to confirm it works.
  4. Then `Remove-Item -Recurse -Force "D:\Video editor\flutter"`.
- Keep `/flutter/` in `.gitignore` until it's deleted. If it was ever committed, `.git` will still hold it (check `git ls-files flutter | Measure-Object`).

---

## 9. One path through the code: "user taps Export"
`export_screen.dart` (button) → `export_controller.dart` `start()` → `export_service.dart` `export()` loads rows from `data\project_database.dart` → `export_inputs.dart` converts rows → `export_command_builder.dart` builds the command → `export_engine.dart` runs FFmpeg → on success `gallery_share_service.dart` saves it → `export_screen.dart` shows "Your video is ready".

If any single file here is still unclear, tell me its name and I'll walk through it line by line.
