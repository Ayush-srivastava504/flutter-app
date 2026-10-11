# ClipForge — next 25 features, easiest to hardest

Written so that **one feature = one Claude session**. Read `docs/APP_GUIDE.md` first (architecture, preview-vs-export rule, the feature recipe). This file does not repeat it.

---

## 0. How to use this document

**Start of every session, paste:**
> Read `docs/APP_GUIDE.md` and feature **F__** in `docs/FEATURE_PLAN_25.md`. Build only that feature, following the recipe in APP_GUIDE section 10. Use the next free schema version. Update `tools/graph_prototype.py` if you touch the export builder. Add tests for the pure logic. Finish by listing every file you changed and what I must test on the phone.

**Rules for every feature (Definition of Done)**
1. `scripts/dev.sh check` is green (analyze + tests).
2. If it changes how video/audio looks or sounds: it works in the **preview AND the export**, and `scripts/dev.sh graph` still passes.
3. If it adds a column/table: schema version bumped, migration written, migration test added, `scripts/dev.sh gen` run.
4. Undo/redo works (it does automatically if the data lives in Clips / AudioTracks / TextOverlays; **new tables must be added to `ProjectSnapshot` and `restoreProject`** in `project_database.dart`).
5. An old project (made before the feature) still opens and exports.
6. Claude lists what it could **not** verify (it has no phone/SDK) so you test exactly that.

**Effort key** (Claude sessions, not hours): **S** = one short session, **M** = one full session, **L** = may need 2–3 sessions, split it.
**Type key:** **A** = UI/data only, **B** = needs preview + export work, **C** = needs native code or a new plugin.

---

## 1. Do these first (not part of the 25)

| ID | What | Why it comes first |
|---|---|---|
| **P0** | **Make export work on a real phone.** Follow APP_GUIDE section 8 ("find the real cause in 2 minutes"), paste the copied error to Claude, fix, export a 1-clip, then a 3-clip project. | 14 of the 25 features need export. Building on an unproven export multiplies bugs. |
| **P1** | **Copy imported media into the app's documents folder** (`lib/services/media_import_service.dart`, `audio_import_service.dart`). The picker currently leaves files in the cache folder, which Android can clear → "source missing" at export. Keep the original path out of the DB; store the copy's path. Add a one-time repair for existing rows (if `sourceUri` is in cache and exists, copy it and update the row). | Prevents the most likely random export failure. Tiny change, huge reliability gain. |
| **P2** | **A fixture project for fast testing:** a debug-only button on Home ("Load sample project") that creates a project from 2 short videos + 1 photo + music bundled in `assets/dev/`. | Saves minutes on every manual test of every feature below. |

---

## 2. Schema map (planned order)

`schemaVersion` is **5** today. Numbers below are a suggestion; always use the *next free* one when you build.

| Feature | Schema change | Version |
|---|---|---|
| F7 Looks | `Clips.look` (text, nullable) | 6 |
| F8 Text style | `TextOverlays`: `bold`, `boxEnabled`, `boxColor`, `outlineWidth`, `outlineColor` | 7 |
| F9 Music fades | `AudioTracks.fadeInMs`, `fadeOutMs` | 8 |
| F10 Rotate/flip | `Clips.turns` (0–3), `flipH`, `flipV` | 9 |
| F11 Speed | `Clips.speed` (real, default 1.0) | 10 |
| F14 Crop/zoom | `Clips.zoom`, `panX`, `panY`, `kenBurns` | 11 |
| F15 Fit mode | `Clips.fitMode` (text: fit/fill/blur) | 12 |
| F16 Image overlays | new table `ImageOverlays` | 13 |
| F17 Reverse | `Clips.reversed` | 14 |
| F18 Audio lanes | `AudioTracks.kind`, `lane` | 15 |
| F19 Ducking | `Projects.duckMusic`, `duckAmount` | 16 |
| F23 Keyframes | new table `Keyframes` | 17 |
| F24 PiP | new table `OverlayClips` | 18 |
| F25 Chroma key | columns on `OverlayClips` | 19 |

---

## 3. The 25 features

### TIER 1 — Easy (UI and data only, no export change unless noted)

**F1 · Project management: rename, delete, duplicate** — A · S
- *User sees:* long-press / ⋮ menu on a project card in Home → Rename, Duplicate, Delete (with confirm).
- *Work:* `ProjectDatabase.renameProject`, `deleteProject` (delete Clips, AudioTracks, TextOverlays of that project in one transaction, also clear `lastProjectId` in `AppPrefs` if it matches), `duplicateProject` (copy all rows with new UUIDs, same source files). Files: `project_database.dart`, `home_screen.dart`.
- *Done when:* deleting the resume-card project removes the card; a duplicate edits independently; tests for delete cascade and duplicate id remapping.
- *Risk:* forgetting a table when deleting leaves orphan rows → test with a project that has clips, music and text.

**F2 · Duplicate clip** — A · S
- *User sees:* "Duplicate" in the trim panel; the copy appears right after the original.
- *Work:* `ProjectDatabase.duplicateClip` (new id, orderIndex+1, shift later clips, one transaction). Files: `project_database.dart`, `trim_panel.dart`.
- *Done when:* orderIndex stays contiguous 0..n-1; undo removes the copy; export renders both.

**F3 · Photo duration control** — A · S
- *User sees:* selecting a photo clip shows a slider/stepper 1–15 s (default 3).
- *Work:* for photo clips set `durationMs` and `trimEndMs` together (trim start stays 0). Hide the trim handles for photos. Files: `trim_panel.dart`, `project_database.dart` (`setPhotoDuration`).
- *Export:* none (builder already uses `-t` from the clip duration).
- *Done when:* changing the duration moves the timeline, text and music alignment, and the exported length matches.

**F4 · Playhead tools** — A · S
- *User sees:* buttons: previous clip / next clip / back 1 frame / forward 1 frame; optional "snap to clip edges" when scrubbing.
- *Work:* pure helpers next to `layoutTimeline` (nearest boundary, frame step = 1000/30 ms) + tests; buttons in the editor controls. Files: `models/clip_x.dart`, `editor_screen.dart`, `timeline_scrub_bar.dart`.
- *Done when:* helper tests cover first/last clip and empty timeline.

**F5 · Export options: resolution and frame rate** — A/B · S
- *User sees:* quality picker gets 480p / 720p / 1080p and 24 / 30 / 60 fps; last choice remembered.
- *Work:* add `p480` to `ExportQuality`; replace the constant `exportFps` with a parameter of `buildExportCommand`; make the 3 `fps=`/`-r` places use it; store last choice in `AppPrefs`; update size estimate. Update `graph_prototype.py`. Files: `export_models.dart`, `export_command_builder.dart`, `export_screen.dart`, `app_prefs.dart`, tests.
- *Risk:* 60 fps on the hardware encoder at 1080p may fail on weak phones; the existing encoder fallback should catch it. Test on a real device.

**F6 · Project aspect ratio picker** — A/B · M
- *User sees:* chips 9:16, 16:9, 1:1, 4:5, 4:3 in the editor; preview canvas and export both change shape.
- *Work:* `Projects.aspectRatio` already exists and the export already honours it. Add `setAspectRatio`, a picker, and make the **preview canvas** use it (verify how `editor_screen.dart` sizes the preview; text positions are fractions so they survive). Files: `project_database.dart`, `editor_screen.dart`, `text_overlay_layer.dart`.
- *Done when:* a 16:9 project exports 1920×1080 at 1080p; mixed-orientation clips letterbox correctly in both.
- *Note:* not in the undo snapshot today (Projects row). Either accept that or add aspect ratio to `ProjectSnapshot`; say which in the summary.

### TIER 2 — Medium-easy (one new column + preview + export)

**F7 · Look presets (B&W, sepia, vintage, cool, warm, vignette)** — B · M
- *Schema:* `Clips.look`. Applies *in addition to* the brightness/contrast/saturation sliders.
- *Preview:* extend `models/color_filter_x.dart` (colour-matrix math, already unit-tested) with one matrix per look; vignette via a radial-gradient overlay in `_FilterPreview`.
- *Export:* in `export_command_builder.dart` after the `eq` step: mono `hue=s=0`; sepia `colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131:0`; cool/warm `colorbalance` or `colortemperature`-style `colorchannelmixer`; vignette `vignette`.
- *Done when:* tests assert each look's filter string; `graph` renders every look; "apply to all" also sets looks.

**F8 · Text styling v2** — B · M
- *Schema:* bold, background box + colour, outline width + colour on `TextOverlays`.
- *Work:* panel controls in `text_overlay_panel.dart`; preview in `text_overlay_layer.dart`. Export: `drawtext` options `box=1:boxcolor=…@…:boxborderw=…`, `borderw=…:bordercolor=…`; bundle `DejaVuSans-Bold.ttf` (same licence) and map "Default bold" in `ExportService._fontAssets`. Honour left/right alignment in export by computing `x` from the overlay position instead of centring (note: `text_align` is not reliable across FFmpeg builds).
- *Risk:* preview font vs export font look slightly different; accept, but keep size scaling consistent (`previewReferenceWidth`).

**F9 · Music fade in/out + master volume** — B · S
- *Schema:* `AudioTracks.fadeInMs`, `fadeOutMs`.
- *Preview:* ramp `just_audio` volume near the start/end in `VideoPreviewPlayer._syncMusic`.
- *Export:* append `afade=t=in:st=0:d=…` and `afade=t=out:st=…:d=…` to the music chain *before* `adelay`. Fade-out start = trimmed length − fade.
- *Done when:* test asserts the filter text; fades longer than the trimmed track are clamped.

**F10 · Rotate and flip clip** — B · M
- *Schema:* `Clips.turns` (0–3 quarter turns), `flipH`, `flipV` (separate from the container flag `rotationDegrees`; never mix them).
- *Preview:* `Transform.rotate`/`Transform.flip` around the video widget; aspect ratio swaps on odd turns (use it in `letterboxedFrame`).
- *Export:* **before** scale/pad insert `transpose=1` / `transpose=2` / `hflip` / `vflip` (FFmpeg already auto-rotates the container flag, so these apply on top of it).
- *Done when:* a 90°-turned landscape clip fills a portrait project correctly in preview and export.

**F11 · Per-clip speed (0.25×–4×)** — B · M
- *Schema:* `Clips.speed`.
- *Rule:* **rendered duration = (trimEnd − trimStart) / speed.** Add one helper (`effectiveDurationMs`) and use it **everywhere** durations matter: `layoutTimeline`/`positionAt`, `exportClipsFrom`, `_boundaryAfter`, `exportDurationMs`, text/music remapping, the timeline tile width.
- *Preview:* `controller.setPlaybackSpeed(speed)`.
- *Export:* video `setpts=(PTS-STARTPTS)/speed`; audio `atempo` (chain `atempo=2,atempo=…` for values outside 0.5–2); photos ignore speed.
- *Done when:* tests prove a 4-s clip at 2× renders 2 s and later text/music stay glued to the same picture; slow-motion audio stays in pitch.
- *Risk:* highest regression risk of the tier — this touches the timeline maths. Run all existing tests.

**F12 · Subtitle (.srt) import** — A · M
- *User sees:* "Import subtitles" → pick an .srt → each cue becomes a text overlay at the bottom with its start/end.
- *Work:* pure parser `lib/models/srt_parser.dart` (+ tests with multi-line cues, comma milliseconds, BOM, empty file), batch insert with one transaction (so undo removes all at once). File picker already a dependency. Files: parser, `project_database.dart` (`insertOverlays`), `text_overlay_panel.dart`.
- *Export:* none, it reuses text overlays.
- *Risk:* 300+ cues makes 300 `drawtext` filters; warn above ~100 and test export time.

### TIER 3 — Medium (real filter-graph work)

**F13 · More transitions (slide, wipe, zoom, circle)** — B · M
- *Work:* `transitionOut` is already a free text field; add values `slideleft`, `wipeleft`, `circleopen`, `zoomin`. In `_boundaryAfter` / the join loop treat them like `dissolve` but emit `xfade=transition=<name>`. Picker UI in `timeline_clip_tile.dart`; preview keeps the approximation (`models/transition_x.dart`).
- *Done when:* `graph` renders every transition name; unknown names fall back to `fade` rather than failing.

**F14 · Crop / zoom / pan, and Ken Burns for photos** — B · L
- *Schema:* `zoom` (1–4), `panX`, `panY` (fractions), `kenBurns` (bool; zooms from 1× to chosen zoom over the clip).
- *Preview:* `Transform.scale` + `Alignment` offset; Ken Burns via `TweenAnimationBuilder` tied to the playhead.
- *Export:* static: `crop=iw/zoom:ih/zoom:x:y` **before** scale/pad. Ken Burns: `zoompan=z=…:d=<frames>:s=WxH:fps=30` on photos (scale the photo up first, e.g. 2× the output, to avoid jitter).
- *Risk:* `zoompan` is slow and jittery on low-res photos; limit to photos in v1, add video crop only (no animation).

**F15 · Fit modes: fit, fill, blurred background** — B · M
- *Schema:* `Clips.fitMode`.
- *Export:* fit = today. fill = `scale=…:force_original_aspect_ratio=increase,crop=w:h`. blur = split the input: background `scale(increase),crop,boxblur=20:2`, foreground `scale(decrease)`, `overlay=(W-w)/2:(H-h)/2`.
- *Preview:* `BoxFit.contain/cover`; blur via `ImageFiltered` + a second video texture is costly, so preview shows a dark dim background and export shows the real blur (document the difference).
- *Done when:* a landscape clip in a 9:16 project shows the blurred bars in the export.

**F16 · Image overlays (stickers, logo/watermark)** — B · L
- *Schema:* new table `ImageOverlays` (path, x, y, scale, rotation, opacity, startMs, endMs). **Add it to `ProjectSnapshot` + `restoreProject`.**
- *UI:* "Add sticker" (image_picker), drag/pinch on the preview (copy the pattern in `text_overlay_layer.dart`), lane like `text_overlay_strip.dart`.
- *Export:* each image becomes an extra `-i` input (use `-loop 1`), `scale=<w>:-1`, `format=rgba,colorchannelmixer=aa=<opacity>`, `overlay=x:y:enable='between(t,s,e)'`. Remember the input index shifts: images go **after** clips and **before** music, or update the `[$n:a]` music index.
- *Risk:* input-index bookkeeping is the classic bug here; add a test with 2 clips + 2 images + music.

**F17 · Freeze frame and reverse clip** — B · M
- *Freeze frame:* no schema. "Freeze here" extracts the frame at the playhead with FFmpeg (`-ss t -frames:v 1 out.png` into the documents folder), splits the clip there, and inserts a photo clip of that frame (default 2 s) between the halves.
- *Reverse:* `Clips.reversed`. Export `reverse`+`areverse` after the trim. **`reverse` buffers the whole clip in RAM**, so cap reverse at 10 s of source and show a message otherwise.
- *Done when:* the freeze image exists after an app restart (documents folder, not cache) and exports.

**F18 · Multiple audio lanes (music + sound effects + voice)** — B · L
- *Schema:* `AudioTracks.kind` (music/sfx/voice), `lane`. Today the code assumes **one** track (`getAudioTrack` singular, `audioTrackProvider`, `exportMusicFrom`, a single music input). Refactor to lists: `watchAudioTracks`, `ExportMusic` → `List<ExportAudio>`, one `amix` with N inputs.
- *UI:* lane per track in `audio_track_lane.dart`; add/remove tracks.
- *Done when:* migration keeps the existing single track as `kind=music`; 3 tracks mix without clipping (limiter stays last); history snapshot restores all of them.

**F19 · Audio ducking (music dips when clips/voice talk)** — B · M
- *Schema:* `Projects.duckMusic`, `duckAmount`.
- *Export:* `sidechaincompress` with the clip-audio bus as the sidechain input, applied to the music before `amix`. Needs the clip audio split with `asplit` (one copy to the mix, one as the sidechain).
- *Preview:* approximate by lowering `just_audio` volume while the current clip is un-muted and has audio, or skip preview and label it "applied on export".
- *Depends on:* works alone, best after F18/F20.

### TIER 4 — Hard (new subsystems, native code, or architecture)

**F20 · Voice-over recording** — C · L
- *Needs:* the `record` plugin (mic permission and `RECORD_AUDIO` are already declared) and F18.
- *Flow:* hold-to-record at the playhead while the preview plays (muted or with headphones); save an m4a in the documents folder; insert as an `AudioTracks` row `kind=voice`, `offsetMs = playhead`.
- *Risk:* recording while the preview plays picks up speaker sound; recommend headphones in the UI. Pure native-plugin rebuild (slow); test on device only.

**F21 · Continuous cross-clip playback in the preview** — B · L
- *Why hard:* today the preview loops inside one clip (known gap). Needs a playback controller that owns **the whole timeline**: pre-initialise the next clip's `VideoPlayerController`, swap at the boundary, keep music and text on the one timeline clock.
- *Plan:* new `TimelinePlayer` (pure state machine + tests for boundary handling and seeking across clips) driving two controllers (current/next). Move the playhead ownership out of `VideoPreviewPlayer`.
- *Do it together with:* the editor performance fix (move `playheadMsProvider` watches into leaf `Consumer`s) or it will stutter.
- *Risk:* biggest architectural change in the plan; keep a feature flag and the old behaviour until it is solid.

**F22 · Android foreground service for long exports** — C · L
- *Why:* Android may kill a long export when the app is backgrounded.
- *Work:* Kotlin foreground service + manifest entries (`FOREGROUND_SERVICE`, media-processing type for newer Android) started/stopped from `ExportController` via a small MethodChannel; keep the progress notification owned by the service; handle "app killed, restart export" with a clear message (no resume in v1).
- *Risk:* store policy for foreground-service types; native build time; test on Android 13/14/15 devices.

**F23 · Keyframe animation (position, scale, rotation, opacity)** — B · L
- *Schema:* table `Keyframes` (targetType, targetId, property, timeMs, value, easing). Add to snapshot/restore. Start with **text overlays and image overlays** (F16).
- *Preview:* a pure interpolator `valueAt(keyframes, t)` (tests!) read by the overlay layers each tick.
- *Export:* `drawtext`/`overlay` accept expressions in `x`, `y`, `alpha`; generate piecewise expressions `if(lt(t,t1),…,…)` from the keyframes (cap at ~8 per property to keep expressions small).
- *Risk:* expression escaping inside `filter_complex`; build the expression generator as a pure function with tests first.

**F24 · Picture-in-picture (second video track)** — B · L
- *Schema:* table `OverlayClips` (path, trim, x, y, scale, opacity, startMs, volume). Snapshot/restore.
- *UI:* new timeline lane; drag/resize on the preview like image overlays.
- *Export:* extra video input trimmed with `setpts=PTS-STARTPTS+<start>/TB`, scaled, `overlay=…:enable='between(t,s,e)'`; its audio into the F18 mixer.
- *Risk:* two simultaneous decoders in preview and 2+ in export; test memory on a low-end phone.

**F25 · Chroma key (green screen) on PiP clips** — B · M (after F24)
- *Schema:* on `OverlayClips`: `keyColor`, `similarity`, `blend`.
- *Export:* `chromakey=color=0x00FF00:similarity=0.15:blend=0.1` (then `format=yuva420p`) before overlay.
- *Preview:* no real-time keying in Flutter without a shader; show the raw PiP with a "key applied on export" badge, or write a fragment shader (stretch goal).
- *Done when:* a green-screen sample renders transparent in the export; sliders for similarity/blend persist.

---

## 4. Dependency graph (what must come before what)

```
P0 ─▶ everything marked B
P1 ─▶ F17 (freeze frames), F20 (recordings), F12 (none, but safest)
F3 ─▶ F14 (Ken Burns uses photo duration)
F11 ─▶ (touches timeline maths; do before F13/F14/F17 so they use effectiveDurationMs)
F16 ─▶ F23 (keyframes on overlays), F24 (reuses drag/resize UI)
F18 ─▶ F19, F20
F24 ─▶ F25
F21 ─▶ none, but do after F11 (timeline maths settled)
```

## 5. Cut line, if you run short on time
- **Ship-ready core (F1–F13):** feels like a real editor, mostly low risk.
- **"Wow" additions:** F14, F15, F16, F20.
- **Park until later:** F21, F22, F23, F24, F25 (the hard tier); and anything ML (auto-captions via speech-to-text, background removal, beat sync), which needs on-device models and is a separate project.

## 6. Pitfalls that apply to many features
- **Duration maths lives in 5 places** (timeline layout, `exportClipsFrom`, `_boundaryAfter`, `exportDurationMs`, text/music remap). Any feature that changes a clip's length (F3, F11, F17) must update all five.
- **FFmpeg input indexes:** the music input is `[$n:a]` where n = clip count. Every feature that adds inputs (F16, F18, F24) must change that deliberately and have a test.
- **Preview ≠ export.** Write one line in each feature's summary: "preview does X, export does Y".
- **New tables** are invisible to undo until added to `ProjectSnapshot`/`restoreProject`.
- **Never edit `*.g.dart`.** Edit tables, run `scripts/dev.sh gen`.
- **Hardware encoder limits:** the first export attempt uses `h264_mediacodec`; heavy graphs (F15 blur, F24 PiP, F14 zoompan) are likelier to trigger the fallback to the slower `mpeg4`. Time a 30-second export after each of those.
