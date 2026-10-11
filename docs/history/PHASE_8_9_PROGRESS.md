# Phase 8 (Export) + Phase 9 (Polish & UX) — progress

## Read this first: verification status

| Thing | Status |
|---|---|
| FFmpeg filter graph (trim, order, filters, fade/dissolve, text, music, mixed aspect ratios, photos) | **Verified** — rendered through a real FFmpeg 6.1 (`python3 tools/verify_export_graph.py`); durations, size, streams and frames checked, plus 5 edge cases |
| Dart port of that graph (`lib/export/export_command_builder.dart`) | **Hand-ported, not executed** — no Dart/Flutter SDK was available when this was written. Unit tests are in `test/export_command_builder_test.dart`; expectations were checked by hand against the code, but **run `flutter test` first** |
| All other Dart (service, controller, screens, history, onboarding) | **Not compiled.** Bracket balance and import paths were checked mechanically; nothing else. Expect a few small analyzer fixes |
| FFmpegKit API calls (`lib/export/export_engine.dart`) | **Unverified against the fork.** All FFmpegKit use is isolated in that one file |
| Anything on a device (encoders, notifications, gallery, memory, 60fps) | **Not tested** — no devices. Phase 9's "test on low/high-end devices, profile memory" is a to-do for you, with the checklist below |

First steps on your machine:
1. `flutter pub add ffmpeg_kit_flutter_new_full` (pins a real version over the `any` in pubspec) then `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter analyze` and `flutter test`
4. If `export_engine.dart` doesn't compile, fix the import paths / method names there (the fork mirrors the original API but I couldn't confirm it).

## IMPORTANT: the old FFmpeg dependency was dead

`ffmpeg_kit_flutter ^6.0.3` (in the Phase 7 pubspec) cannot be built any more: FFmpegKit was retired and its 6.0 binaries were removed on 1 April 2025. Replaced with the community fork `ffmpeg_kit_flutter_new_full` (non-GPL "full" build: has libfreetype for text, no libx264). Because there is no libx264, export uses the platform hardware H.264 encoder (`h264_mediacodec` on Android, `h264_videotoolbox` on iOS) and falls back to MPEG-4 if that fails.

## Phase 8 — Export

- **Pipeline** (`lib/export/`): `export_command_builder.dart` (pure) → `export_service.dart` (loads project, probes audio, writes fonts/text files, runs, retries on a second encoder, classifies failures) → `export_engine.dart` (FFmpegKit seam) → `export_controller.dart` (state, wakelock, notifications, gallery save, share).
- **What gets rendered:** clips in order with trims; per-clip brightness/contrast/saturation → `eq` (same maths as the preview matrix); original audio with per-clip mute/volume (silent clips and photos get generated silence so audio never drifts); background music with trim/offset/volume, mixed with limiter; text overlays via `drawtext` (positions as frame fractions, centred; timing in timeline time); transitions.
- **Transitions:** *Dissolve* is a real overlapping cross-dissolve (≤600 ms), which shortens the output; text and music that sit after it are shifted earlier by the overlap so they stay on the same picture. *Fade* dips through black (300 ms each side) without changing length. This closes the "true two-video crossfade" gap listed in Phase 7 — for export. The live *preview* is still thumbnail-based.
- **Resolution:** 720p / 1080p (short side), long side from the project's aspect ratio; size estimate shown before exporting.
- **Progress:** FFmpeg's reported output time ÷ total rendered length → progress bar + throttled progress notification.
- **Background:** FFmpeg runs on a native thread, so export normally continues while the app is backgrounded; screen-wake is held during export and a completion/failure notification is posted. **Not done:** an Android foreground service, which is what actually stops the OS killing a long export under memory pressure — it needs native Kotlin. Do this next if long exports get killed.
- **Save + share:** auto-saves to the gallery (`gal`, album "ClipForge") and offers a share sheet (`share_plus`); if the gallery save is denied the file is kept and a "Save to gallery" button is offered.
- **Failures:** nothing to export, missing source file, insufficient storage (FFmpeg `ENOSPC` / `GalException.notEnoughSpace`), interrupted/cancelled, unsupported codec (including the encoder-fallback retry) — each with a plain-language message and Try again. Free space is **not pre-checked** (needs a platform channel); it's detected when the write fails.
- **Fonts:** overlay font presets map to bundled DejaVu fonts (`assets/fonts/`, free licence in `LICENSE-DejaVu.txt`) because FFmpeg can't resolve the system family names the preview uses. *Cursive* maps to DejaVu Serif Italic (no cursive font is bundled).

### Known limits
- Overlay font size is scaled assuming a 360-logical-px-wide preview frame (`previewReferenceWidth`); text may look slightly bigger/smaller than the preview on very different screens. Fix by storing the real preview frame width.
- Overlay multi-line alignment (left/right) isn't applied — text is centred (FFmpeg's `text_align` isn't available on all builds).
- HEIC photos usually can't be decoded by FFmpeg → reported as an unsupported-format failure. Convert on import if you want them supported.
- Clip rotation metadata is left to FFmpeg's auto-rotate (don't also rotate by hand).

## Phase 9 — Polish & UX

- **Undo/redo** (`lib/history/`): watches the project's clip/audio/overlay rows, snapshots them (450 ms debounce, so a slider drag or burst of edits = one step, 50 deep) and restores a snapshot in a single transaction. Covers every existing edit without instrumenting each widget. Buttons in the editor app bar. `HistoryStack` is generic and tested.
- **Autosave:** every edit already persisted to SQLite; added the missing pieces — `updatedAt` stamped on change, "Saved HH:mm" indicator in the editor, and a "Resume <project>" card on Home (last-opened project remembered in a small JSON file, no new dependency). Home also sorts by most recently updated and refreshes after returning from the editor.
- **Onboarding:** 3 screens, shown once (`lib/app/`).
- **Empty / loading / error states:** shared widgets in `lib/widgets/common/state_views.dart`, applied to Home, Editor and Export. **Fixed a bug:** Home showed an endless spinner if loading projects threw.
- **Performance (code audit only):** capped image decode sizes (timeline thumbs 240 px, preview thumbs 720 px, photos 1440 px — a 12 MP photo clip previously decoded to ~48 MB), added `RepaintBoundary` around the preview and timeline strip, `gaplessPlayback` on thumbs. **Not done:** `EditorScreen._buildBody` still watches `playheadMsProvider`, so the whole editor body rebuilds on each playhead change. The fix is to move that watch into leaf `Consumer`s (preview, scrub bar, text layer). I left it because it's a structural change I couldn't verify without running the app — profile first (below).
- Export memory: hardware encoder, single pass, no frames pass through Dart, inputs scaled inside FFmpeg.

### Device checklist (yours to run)
1. Profile editor with 10+ clips: Flutter DevTools → Performance, scrub the timeline; look for >16 ms frames. If the editor body rebuild shows up, do the Consumer split above.
2. Memory: DevTools → Memory while adding photos/clips, then during a 1080p export of a 2–3 min project on a low-RAM device.
3. Export a project using every feature on one low-end and one high-end phone, Android + iOS; background the app mid-export; fill the disk to test the storage message; deny gallery permission.
4. Check the encoder fallback actually triggers (force `VideoEncoder.software` in `ExportService`'s encoder list).

## Housekeeping
- `pubspec.yaml` listed `assets/images/` but the folder didn't exist in the zip (Flutter fails the build on that) — added a `.gitkeep`.
- Android `minSdk` raised to ≥24 (FFmpegKit) and core-library desugaring enabled (notifications). iOS already targets 15.
- `NSPhotoLibraryAddUsageDescription` and `POST_NOTIFICATIONS` were already present.
- `tools/graph_prototype.py` + `tools/verify_export_graph.py`: the executable reference for the graph. If you change the Dart builder, change the prototype and re-run the verifier.

## Next: Phase 10
Tests exist for the builder, failure classification and history stack; still to write: export-service tests with a fake `ExportEngine` (the seam is there), data-model tests for snapshot/restore, then crash reporting/analytics, store assets.
