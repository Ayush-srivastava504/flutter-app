# ClipForge — testing guide

Three layers: **automated unit tests** (seconds, no phone), **graph verification** (real FFmpeg on your computer), **manual phone tests** (the only proof the app works).
Status when this was written (2026-10-11): the reviewer could run the graph verification (✅ passed, FACTS F-67) but **could not run `flutter analyze` / `flutter test` / any phone test** (no SDK/device). So every box in §3 starts **unticked**.

## 1. Automated
| Command | What it proves | Reviewer ran it? |
|---|---|---|
| `scripts/dev.sh check` (= `flutter analyze && flutter test`) | static analysis clean + all unit tests green | ❌ no SDK |
| `scripts/dev.sh graph` (= `python3 tools/verify_export_graph.py`) | the **Python** export graph renders in real FFmpeg with the right duration/size/streams | ✅ OK (720×1280, 9.4 s, h264+aac, desktop FFmpeg 6.1.1) |

Existing test files (`test/`): `color_filter_matrix_test`, `export_command_builder_test`, `export_failure_classification_test`, `history_stack_test`, `project_database_migration_test` (+ `support/legacy_v3_database*.dart`), `text_overlay_layer_math_test`, `text_overlay_timing_test`, `transition_preview_test`.

**Gaps worth filling (in this order):**
1. `splitClip` — must keep `volume`, `filterPreset` (bug B-01) and have the intended `transitionOut` on both halves (B-02).
2. DB ops: `deleteClipAndReindex` keeps `orderIndex` 0..n-1; `reorderClips`; `applyFilterToAllClips`.
3. Migration 4→5 and 5→(next) with real rows.
4. `exportClipsFrom` / `exportMusicFrom` / `exportOverlaysFrom` mappings (`export_inputs.dart`).
5. Dart builder ↔ Python prototype parity: a test that asserts key substrings of the Dart command for a fixed project, and the same fixed project in `graph_prototype.py`.

## 2. Test media
- Generate synthetic files on your computer: `bash tools/make_test_media.sh` (needs desktop `ffmpeg`; creates portrait 1080p, landscape 1080p, 4K without audio, square 24 fps, 90°-rotated metadata, 0.8 s clip, two photos, two music files). Tested with FFmpeg 6.1.1. Copy them to the phone (gallery for video/photo, Files/Downloads for music).
- **Also use real phone clips** the generator cannot make: a clip recorded by the phone camera in **HEVC/H.265**, one with **variable frame rate** (screen recording), a long one (≥ 5 min), a **HEIC photo** (expected to fail gracefully, FACTS §6), a 0-byte/corrupt file.

## 3. Manual phone test matrix
Run on at least **2 phones**: one recent (Android 14/15/16) and one low-end/older (Android 10–12, ≤ 4 GB RAM). Tick `[ ]` → `[x]` and write the phone model + app version in the margin.
**Do all of §3 on a `--release` build installed like a user would (from the bundle/Play internal test), not just debug.** Release behaves differently (R8, signing, no hot-reload).

### A. First run
| ID | Steps | Expected |
|---|---|---|
| A1 | Fresh install, open | Onboarding appears once; "Skip" and "Get started" both land on Home; relaunch skips onboarding |
| A2 | Observe permission prompts | **After the checklist fixes:** no prompt at launch. (Today the app prompts for media + microphone — FACTS F-21.) |
| A3 | Rotate phone / switch dark-light | No crash; layout intact (activity handles config changes) |

### B. Import
| ID | Steps | Expected |
|---|---|---|
| B1 | Create project → add portrait clip | Tile + thumbnail appear; duration right; preview plays |
| B2 | Add landscape clip to a 9:16 project | Letterboxed (black bars), not stretched |
| B3 | Add the 90°-rotated-metadata clip | Displays upright in preview **and** in export |
| B4 | Add photo (12 MP jpg) | 3 s slot; no out-of-memory; scrubbing smooth |
| B5 | Add HEIC photo (if you have one) | Either works or fails with a clear message — **no crash** |
| B6 | Cancel the picker | No spinner stuck, no crash |
| B7 | Add 10 clips quickly | UI stays responsive; order correct |
| B8 | Add music from Files; also a bundled loop | Music lane shows the track; preview plays in sync |
| B9 | Deny every permission the app asks for, then import | Import still works through the system picker (this is why `READ_MEDIA_*` can be removed) |

### C. Editing
| ID | Steps | Expected |
|---|---|---|
| C1 | Trim start/end handles | Timeline shortens; preview stays inside trim |
| C2 | Split at playhead, then play both halves | Both halves keep **volume, filter, mute** (B-01!) |
| C3 | Delete middle clip | Remaining clips contiguous; undo restores exactly |
| C4 | Reorder by drag | New order persists after leaving and reopening the project |
| C5 | Filters: sliders, presets, "apply to all" | Preview changes live; values persist |
| C6 | Transition cut/fade/dissolve between 2 clips | Persists; export shows matching behaviour (dissolve shortens by ≤0.6 s) |
| C7 | Text: add, move, resize, color, timing, 3 overlays | Overlay appears only inside its time range |
| C8 | Music: volume, trim, offset | Matches in export |
| C9 | Undo/redo 20 steps back and forth | State identical each time; no crash; "saved" indicator updates |
| C10 | Kill the app mid-edit (swipe away), reopen | Last edit present (autosave) |

### D. Export (the launch-critical block)
| ID | Steps | Expected |
|---|---|---|
| X1 | 1 clip, 720p | Completes; MP4 plays in gallery with sound; saved in album "ClipForge" |
| X2 | 3 clips + dissolve + text + music, 1080p | Completes; length = sum − dissolve overlaps; text/music aligned with picture |
| X3 | Project with a photo + silent clip + clip with audio | No audio glitches; silent parts silent |
| X4 | Cancel mid-export | Returns to idle; no crash; no partial file shown as success |
| X6 | 1 clip + photo, 480p @ 24 fps (F5) | Completes; output is 480×854 (portrait), plays smoothly; size noticeably smaller than X1 |
| X7 | 3 clips, 1080p @ 60 fps (F5) | Completes, or fails cleanly then falls back to `mpeg4` (see `scripts/dev.sh logs`); note which. Reopen the Export screen: last quality + fps are pre-selected |
| X5 | Lock the screen / switch app for 30 s during a 1-min export | Either finishes or fails with a clear message (no foreground service yet — FACTS F-68) |
| X6 | Almost-full storage | "Not enough free storage" message, not a generic crash |
| X7 | Delete a source file from the gallery after import, then export | "Clip no longer on this device" message |
| X8 | Share button after export | Share sheet opens with the MP4 |
| X9 | Notification permission denied (Android 13+) | Export still works |
| X10 | Force the fallback: low-end phone or emulator without the hardware encoder | `[export] FAILED … h264_mediacodec` then success on `mpeg4` (check `scripts/dev.sh logs`) |
| X11 | Note export time + encoder for X1, X2 | Record in `PERFORMANCE.md` §6 |

### E. Data and upgrade
| ID | Steps | Expected |
|---|---|---|
| E1 | Install previous build, create a project with clips+music+text, install new build over it | Project opens and exports (migration worked) |
| E2 | Reboot phone, reopen project | Clips still found (cache-dir risk, FACTS F-50) — if "source missing", P1 is needed |
| E3 | "Clear cache" in Android settings, reopen project | Expected to expose F-50 today; record the result |

### F. Release / store gates (see `LAUNCH_CHECKLIST.md` for commands)
| ID | Check | Expected |
|---|---|---|
| R1 | Release build starts and FFmpegKit loads (export works) | R8 did not strip it (FACTS U-02) |
| R2 | `bash tools/check_16kb.sh <aab>` | `ALL OK` (FACTS U-03) |
| R3 | Merged manifest permission list | Matches `LAUNCH_CHECKLIST.md` §3 (no `INTERNET`, no `READ_MEDIA_*`, no `RECORD_AUDIO`) |
| R4 | Play **pre-launch report** (after uploading to internal/closed track) | No crashes/ANRs on its devices |
| R5 | Android 16 (API 36) device or emulator | No behaviour regressions (target SDK 36) |
| R6 | A device/emulator with a **16 KB page size** system image | App starts and exports |

## 4. Regression suite after **every** feature
1. `scripts/dev.sh check` green.
2. If export changed: `scripts/dev.sh graph` green + B-scenarios X1 and X2.
3. If the schema changed: E1 (upgrade) and an old project still exporting.
4. C2, C3, C9 (undo/redo and split are where regressions hide).
5. Heavy-filter features: X11 timing.

## 5. Bug report template (paste to Claude)
```
App version / build type (debug|release):
Phone + Android version:
Scenario ID (e.g. X2) and steps:
Expected / Actual:
Export error details (Export screen → "Copy error details"):
Logs: scripts/dev.sh logs   (lines starting with [export])
```
