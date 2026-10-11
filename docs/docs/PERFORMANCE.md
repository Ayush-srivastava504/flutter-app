# ClipForge — performance and optimisation

**Honesty rule for this document.** Nothing here was measured on a phone (no device/SDK in the review environment).
- **Verified (code)** = I read the code and the behaviour follows from it. Cite `file:line` when you rely on it.
- **Target** = a goal proposed for you to adopt or change. It is *not* a measurement.
- **Measure** = you must run the protocol in §5 and write the number into §6.
Do not turn a Target into a claim ("the app is fast") until §6 has a measured number.

---

## 1. What makes a video editor slow (the four places to look)
1. **UI jank** — too much rebuilt per frame while the preview plays or the user scrubs.
2. **Memory** — decoded bitmaps, extra video decoders, `reverse` buffering, many overlays.
3. **Export time/size** — filter-graph cost, encoder choice, bitrate, resolution.
4. **Startup and install size** — FFmpegKit native libraries dominate the binary.

## 2. Verified hotspots in the current code (ranked)
| # | Hotspot | Evidence | Why it matters | Fix (effort) |
|---|---|---|---|---|
| P-1 | **Whole editor body rebuilds on every playhead tick.** `_buildBody` does `ref.watch(playheadMsProvider)`; the preview calls `onPositionTick` continuously during playback. | `editor_screen.dart:366`; `video_preview_player.dart` (`onPositionTick` hook, class doc) | Timeline, panels and lanes rebuild ~every position tick; gets worse with many clips/overlays. Already noted in `APP_GUIDE.md` §12. | Move the playhead watch into small leaf `Consumer`s (scrub bar, text layer, current-clip lookup). Keep `RepaintBoundary`s. **S–M**, high value. |
| P-2 | **Undo snapshots re-read every row** of the project after each 450 ms quiet period; `restoreProject` deletes and re-inserts every row one `await` at a time. | `project_history.dart` (`debounce`, `limit: 50`), `project_database.dart` `snapshotProject`/`restoreProject` | Fine for dozens of rows; slows with many text overlays (e.g. a 300-cue subtitle import, plan F12) and holds 50 full snapshots in memory. | Use `batch((b){…})` for inserts; keep limit; consider diffing. **M**, do before F12. |
| P-3 | **Per-row update loops** in `applyFilterToAllClips`, `reorderClips`, `deleteClipAndReindex`, `splitClip` (one `await` per row inside a transaction). | `project_database.dart` | OK at <50 clips; each write also re-fires every watching stream (clips, history). | Use `batch` where a single statement can't do it. **S**. |
| P-4 | `appendClip` loads **all** clips just to compute `orderIndex = existing.length`. | `project_database.dart` `appendClip` | O(n) read per import. | `selectOnly` with `count`/`max`. **S**. |
| P-5 | **Import is sequential by design** (controller init → FFprobe → thumbnail) and uses a throw-away `VideoPlayerController` to read duration/size. | `media_import_service.dart` `_buildVideoAsset` | Several hundred ms per clip; the UI shows a spinner. Deliberate to avoid 3 concurrent readers. | Leave until measured (§5). |
| P-6 | **Imported media lives in the cache dir** → can be cleared → export fails (reliability, not speed). | FACTS F-50 | Re-import loop for users; also re-thumbnailing. | Copy to documents dir (plan P1). **S–M**. |
| P-7 | Fonts are bundled (≈1.8 MB) **and** copied to the temp dir at export time; they are copied once and reused (`file.exists && length>0`). | `export_service.dart` `_materialiseFonts` | Negligible. Do nothing. | — |
| P-8 | `fps=30` is a global constant; 60 fps is planned (F5). | `export_command_builder.dart` `exportFps` | 2× encode work; may trigger hardware-encoder failure → slow `mpeg4` fallback. | Time it (§5) before offering 60 fps. |

**Already good (keep):** timeline thumbnails decode at `cacheWidth: 240`; preview photos at 720/1440 (`timeline_clip_tile.dart:155`, `video_preview_player.dart:513,535`); `RepaintBoundary` around preview + timeline; hardware H.264 tried first; text via files (no escaping retries); export folders pruned after 1 day; `NativeDatabase.createInBackground` (DB off the UI isolate).

## 3. Budgets — **Targets** (adopt, change, then measure)
| Area | Target | Notes |
|---|---|---|
| Editor frame time while playing a 1080p clip | p95 build+raster each ≤ 16 ms on a mid-range phone (60 Hz) | Measure with DevTools in `--profile` (§5.1). |
| Cold start to Home visible | ≤ 2.0 s on a mid-range phone | Measure with `am start -W` (§5.3). |
| Import one 1-minute 1080p clip → tile visible | ≤ 2 s | |
| Undo/redo latency, 50 clips | ≤ 150 ms | |
| Export 1 min @ 1080p30, hardware encoder | ≤ 1× realtime (≤ 60 s) | Unknown until measured; software `mpeg4` fallback will be slower. |
| Peak RAM during export | ≤ 600 MB | `dumpsys meminfo` (§5.4). |
| Release install size (arm64 split) | decide after measuring (§5.5) | FFmpegKit "Full" is large. |
| Crash-free sessions | track in Play Console (Android vitals) after launch | |

## 4. Optimisation backlog (ordered by value ÷ effort)
**Do before launch (cheap, low risk):** none are *required*. Only reliability items from `LAUNCH_CHECKLIST.md` are launch-critical. P-1 is the best pre-launch win if you have a spare hour **and** can test on a phone.
**Do soon after launch:** P-1, P-6, B-01 (see FACTS), P-4, P-3.
**Do with the feature that needs it:** P-2 with F12 (subtitle import); a timing run with F5/F14/F15/F24 (heavy filters).
**Do not do yet:** custom video pipeline / GPU shaders / native rewrite; a second `VideoPlayerController` for cross-clip playback before F21's design is agreed (memory); anything that needs new native plugins on launch day.

### Install size (check before deciding anything)
- Ship an **Android App Bundle** (`flutter build appbundle --release`). Play serves per-ABI splits so users don't download all 5 FFmpegKit ABIs. (Verified fact about Play delivery; your actual per-device size must be read from Play Console / `--analyze-size`.)
- Dropping 32-bit ABIs (`ndk.abiFilters`) shrinks the bundle but excludes older 32-bit-only phones. **Don't decide without data** — check the device catalog in Play Console after upload.
- `flutter build apk --analyze-size --target-platform android-arm64 --release` writes a size report you can inspect in DevTools.

### Rules for every new feature (Claude must follow)
1. Never put `playheadMsProvider` (or any high-frequency state) in a widget that has a big subtree.
2. No database write per tick/frame. Writes happen on gesture end (`onChangeEnd`), not every slider move, unless the preview needs it (then debounce).
3. Decode images with `cacheWidth/cacheHeight`; never load a full-resolution photo for a 100 px tile.
4. One new video decoder = one new memory cost. State how many decoders the feature adds (preview + export).
5. State the expected FFmpeg cost of a new filter class: *cheap* (colour/eq/fade), *medium* (scale/crop/overlay), *heavy* (blur, zoompan, reverse, chroma key, multiple overlays). Heavy → time a 30 s export (§5.6) and report it.
6. Dispose controllers, players, timers, stream subscriptions. `ref.onDispose` for provider-owned resources.
7. Don't add a dependency for a perf win without the owner's OK.

## 5. Measurement protocol (copy-paste)
Use a **release or profile build on a physical mid-range phone**, never the emulator or a debug build, for numbers.
1. **Frame times:** `flutter run --profile --target-platform android-arm64` → DevTools → Performance → record while (a) playing a 1080p clip with 3 text overlays, (b) scrubbing the timeline, (c) dragging a trim handle. Record p95 UI and raster ms.
   Or: `adb shell dumpsys gfxinfo com.ayushstudio.clipforge reset`, perform the scenario, then `adb shell dumpsys gfxinfo com.ayushstudio.clipforge` and read "Janky frames".
2. **Rebuild counts:** DevTools → "Track widget rebuilds" while playing; the editor body should not be the top rebuilder after P-1.
3. **Cold start:** force-stop, then `adb shell am start -W -n com.ayushstudio.clipforge/.MainActivity` → read `TotalTime`. Repeat 5×, take the median.
4. **Memory:** `adb shell dumpsys meminfo com.ayushstudio.clipforge` at: idle Home, editor with 10 clips, mid-export. Record "TOTAL PSS".
5. **Size:** `flutter build appbundle --release`; note the `.aab` size; Play Console → "App size" after upload; and the `--analyze-size` report.
6. **Export time:** `scripts/dev.sh logs` shows `[export]` lines; time a 30 s project at 720p and 1080p, with and without the heavy filter. Record the encoder used (if `[export] FAILED` appears for `h264_mediacodec`, the run fell back to `mpeg4`).
7. Run each measurement **3 times**, record the median, the phone model, Android version, and the app version.

## 6. Measured results (fill this in — empty until you run §5)
| Date | Phone / Android | Build (release/profile) | Scenario | Metric | Value | Target | Pass? |
|---|---|---|---|---|---|---|---|
| | | | | | | | |
