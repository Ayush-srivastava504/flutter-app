# ClipForge — dependencies, pinned versions and API traps

**Source of truth for versions: `pubspec.lock`** (read 2026-10-11). If the lock changes, update this table.
Rule for Claude: write code for **these** versions. If you are not certain an API exists in that version, read the package source in `~/.pub-cache/hosted/pub.dev/<package>-<version>/lib/` or the pub.dev changelog before using it. Never use an API "from memory" for a package in this table.

## 1. Runtime packages
| Package | pubspec | Locked | Used for | Where | Traps / rules |
|---|---|---|---|---|---|
| `flutter_riverpod` | ^2.5.1 | **2.6.1** | state | `lib/providers/`, screens | The code uses `StateProvider`, `StateNotifierProvider`, `StreamProvider.family`, `ChangeNotifierProvider.autoDispose.family`. Follow these patterns. **Do not write Riverpod 3 syntax** and do not migrate providers as a side effect of a feature. |
| `drift` | ^2.16.0 | **2.34.3** | SQLite ORM | `lib/data/` | Tables are classes extending `Table`; generated code is `project_database.g.dart` (**never hand-edit**). Use `transaction(() async {…})` for multi-row writes. `NativeDatabase.createInBackground`. |
| `sqlite3_flutter_libs` | ^0.5.20 | 0.5.42 | bundled SQLite | — | ⚠️ Not verified that this is the recommended pairing for drift 2.34 — do not touch unless the DB fails to open on a device. |
| `path_provider` | ^2.1.3 | 2.1.6 | documents/cache/temp dirs | many | Cache and temp dirs can be cleared by Android (see FACTS F-50). Persistent user data belongs in the **documents** dir. |
| `path` | ^1.9.0 | 1.9.1 | path joins | many | — |
| `image_picker` | ^1.1.2 | 1.2.3 | gallery pick (video/photo) | `media_import_service.dart` | Copies the pick into the app cache. Use `pickVideo` / `pickImage` as the code does. |
| `file_picker` | ^8.0.3 | 8.3.7 | audio file pick | `audio_import_service.dart` | Version 8.x API. |
| `permission_handler` | ^11.3.1 | 11.4.0 | runtime permissions | `permission_service.dart` | Android 13+: `Permission.photos`/`videos` map to `READ_MEDIA_*`. See `LAUNCH_CHECKLIST.md` — these should be **removed** for Play. |
| `video_player` | ^2.9.1 | **2.14.0** | preview playback | `video_preview_player.dart` | Preview only, never export. One controller per visible clip; always `dispose()`. |
| `just_audio` | ^0.9.40 | 0.9.46 | music during preview | `video_preview_player.dart` | Kept in sync with the video position (tolerance 180 ms). |
| `video_thumbnail` | ^0.5.3 | **local path override** | thumbnails | `third_party/video_thumbnail` | Patched local copy (MIT). Don't replace with the hosted package without testing the Android build. |
| `ffmpeg_kit_flutter_new_full` | ^2.5.7 | **2.5.7** | export + FFprobe | `lib/export/export_engine.dart`, `lib/services/media_metadata_service.dart`, `lib/services/audio_metadata_service.dart` | See §2. |
| `gal` | ^2.3.1 | 2.3.3 | save to gallery | `gallery_share_service.dart` | `Gal.putVideo(path, album: 'ClipForge')`. |
| `share_plus` | ^10.1.4 | 10.1.4 | share sheet | `gallery_share_service.dart` | Code uses `Share.shareXFiles([...], text: …)` (valid in 10.x). Do **not** switch to newer share_plus API shapes without bumping the version deliberately. |
| `flutter_local_notifications` | ^17.2.4 | 17.2.4 | export notification | `export_notifier.dart` | Requires core-library desugaring (already enabled in Gradle). |
| `wakelock_plus` | ^1.2.8 | 1.5.2 | keep screen on while exporting | `export_controller.dart` | Enable/disable around export only. |
| `uuid` | ^4.4.0 | 4.6.0 | ids | many | — |

Dev: `drift_dev` 2.34.5, `build_runner` 2.16.0, `flutter_lints` 4.0.0, `flutter_test` (SDK).
SDK per lock: **Dart ≥ 3.13, Flutter ≥ 3.44** (FACTS F-11).

## 2. FFmpegKit — what is true and what is not
- Package: **`ffmpeg_kit_flutter_new_full`** (community fork). The original `ffmpeg_kit_flutter` was retired by its author in 2025 and its binaries removed — **never** add or import it. (Stated in `pubspec.yaml` and `export_engine.dart`; consistent with pub.dev.)
- Imports used in this repo (the only ones that are proven to match this version's file layout in the code): `ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart`, `ffprobe_kit.dart`, `return_code.dart`. FFmpeg *execution* stays in `lib/export/export_engine.dart`; read-only FFprobe probing is in `lib/services/media_metadata_service.dart` and `lib/services/audio_metadata_service.dart`.
- Licence: **LGPL-3.0**, "Full" variant = **no GPL libraries, no libx264/x265**. Consequences: encode with `h264_mediacodec` (Android) / `h264_videotoolbox` (iOS) / `mpeg4` fallback. Switching to a "-GPL" variant would impose GPL obligations on the whole app — **do not do it** without the owner's explicit decision.
- Minimum Android API 24 (matches `minSdk`).
- ⚠️ **Not verified:** that the 2.5.7 native libraries are 16 KB-page aligned (Play requirement, see `LAUNCH_CHECKLIST.md` §1-L4). A different fork named `ffmpeg_kit_16kb` advertises 16 KB support, but check which licence variant it ships before ever considering it.
- ⚠️ **Not verified:** the FFmpeg version inside 2.5.7 (desktop tests in `FFMPEG_COOKBOOK.md` used 6.1.1). Filter availability can differ — see the cookbook's "run on phone" column.
- ABIs: Android 5 ABIs by default (arm-v7a, arm64-v8a, x86, x86_64, …) per the package docs → big binary. `scripts/dev.sh run` builds arm64 only for speed. For the store use an **AAB** (Play delivers per-ABI splits) — see `PERFORMANCE.md` §4.

## 3. Rules for adding or upgrading a package
1. Ask the owner first.
2. Check: licence (no GPL/AGPL), maintained recently, **native code?** (then 16 KB alignment + APK size), Android API 24+ ok, no `INTERNET` permission added (offline claim, FACTS F-30).
3. After the change: `flutter pub get`, `scripts/dev.sh check`, a **release** build on a phone, `bash tools/check_16kb.sh`, and re-check the merged manifest.
4. Update this file and `docs/legal/THIRD_PARTY_NOTICES.md` in the same change.
