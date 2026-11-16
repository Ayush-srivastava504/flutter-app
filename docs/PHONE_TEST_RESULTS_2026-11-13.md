# Phone test results — 2026-11-13

Device: Samsung Galaxy A36 (SM-A366E), Android 16. Debug build (`flutter run`), driven over adb by Claude.
Exports were pulled to the PC and checked with ffprobe (size, length, streams, audio levels, frame grids).
Test IDs refer to `docs/PHONE_TEST_PLAN.md`.

## Fixed this session (all verified on the phone unless noted)
| # | Bug | Cause | Fix |
|---|---|---|---|
| 1 | **Text could not be typed** — keyboard opened and closed instantly | Keyboard shrank the editor body until it was wider than tall → editor switched to its landscape layout → text field rebuilt, lost focus | `editor_screen.dart`: choose layout from the screen size, not the keyboard-shrunk box. Regression test in `editor_layout_test.dart` (fails without the fix) |
| 2 | **Scrolling the timeline reordered clips** | `ReorderableDragStartListener` starts a drag on any touch-move | `timeline_strip.dart`: `ReorderableDelayedDragStartListener` (long-press to drag). Verified: 6 hard swipes, order unchanged |
| 3 | Home never refreshed after leaving the editor (new project missing, wrong "Pick up where you left off") | `setState(() => _data = _load())` returns a Future → setState throws | `home_screen.dart`: block body |
| 4 | Photo clips showed a placeholder icon in the timeline; projects starting with a photo had no cover on Home | Photos have no `thumbnailUri` | `timeline_clip_tile.dart`, `projectCoverThumbnails()` fall back to the photo file |
| 5 | "Saved to gallery" snackbar never went away and covered "Your audio" on Home | Flutter 3.47 makes snackbars with an action persist | `photo_editor_screen.dart`: `persist: false`, 6 s (not re-verified on phone) |
| 6 | Every import stored twice (picker's cache copy never deleted) — ~880 MB of cache on this phone | `persistToDocuments` only copied | `media_storage_service.dart`: `consumeCacheSource` (copy + delete scratch file + empty folder) used by the import services only — never by the repair pass (duplicated clips share a source). Verified: import adds 1 file to `imported_media`, 0 to cache. 2 new unit tests |

`flutter analyze`: 34 infos (= baseline). `flutter test`: 436 passed.

## Passed
P0-1..P0-5 · first-run Home · FCPXML export (J6) · import video / photo via picker · trim/duplicate/speed (4.9 s → 3.9 s at 1.25×) · undo ×3 / redo ×3 restores exactly · looks (Blockbuster) · fit Blur · effects (VHS) · 26-transition picker; all 24 xfade names present in the phone's libavfilter · 5 chained `doors` transitions export (23.7 s = 26.7 − 5×0.6) · text overlay (after fix) · music library (12 tracks, preview + use) · AutoCut beat cut (20 pieces, speed-aware) + one-step undo · Remove silences (runs; "No silent parts found" on party audio) · voice-over record → lane → export (present only in its 0–14 s window) · Assistant ("make the first clip black and white" → mono look; nonsense → polite message) · export cancel (no file in gallery) · Photo Studio (Pop look, JPEG saved full-res 2296×4080, upright) · Audio Studio (reverb + echo → MP3 in Music/ClipForge, 4:03).

## Open issues — not fixed (need a decision or more work)
| Sev | Issue |
|---|---|
| High | ~880 MB of old picker copies still in the app cache on this phone. Safe cleanup must skip any path a project still references (pre-P1 projects). Needs owner OK. |
| Med | Effects: "Motion" and "Stylise" look like two independent choices but share one `effect` column — choosing VHS silently removed Zoom in. Needs a schema change (2 columns) or a UI that says "one effect per clip". |
| Med | Selecting a clip does not move the playhead/preview to it — you edit clip 3 while seeing clip 1. |
| Med | ~20 empty "New YouTube video" projects on Home: every tap on a mode card creates a project even if you back out with no media. |
| Low | Text in export is thin/plain; preview is bold with shadow (font/weight mismatch). |
| Low | "One video" / Photo Studio open the system picker in multi-select mode (needs an extra "Done"). |
| Low | Photo clip panel shows mute + volume (photos have no sound). |
| Low | Voice-over sheet: "Tap to record" label sits under the navigation bar. |
| Low | Assistant "Try one of the examples below" — examples are hidden after the first command. |
| Low | Cancelled export says "The export was interrupted" — should say "cancelled". |
| Low | Debug-only assertion: a `ListTile` inside a `ColoredBox` in the music library sheet (ink splash invisible). |
| Info | Timeline time is `m:ss:ff` (frames) — "0:12:26" is 12 s 26 frames; easy to misread. |
| Info | Exported files go to Pictures/ClipForge (videos too), not Movies. |

## Not tested yet (needs a person, or later)
Release build (R8) · onboarding on a fresh install · rotation · split/delete/reorder by long-press drag · SRT import · chapters · templates · Insta/YouTube mode specifics · Remove background on a green-screen clip · speech enhance on real speech · Remove silences on a talking clip · beat composer · 4K / 60 fps export · locking the screen mid-export · low storage · deleted source file · audio quality by ear (Claude cannot hear).
