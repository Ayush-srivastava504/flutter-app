# ClipForge — Master plan: Photo Studio + Video Studio

> Written 2026-11-11. Supersedes nothing: `docs/FEATURE_PLAN_25.md` stays the detailed spec for
> its remaining items (F14, F16–F18, F20–F25); this plan places them in the bigger picture and
> adds everything else. Session rules in `docs/CLAUDE.md` still apply (one feature per session,
> final report, preview ≠ export line, docs kept true).

## 0. What we are building

One app, two studios that share one engine:

| | **Photo Studio** | **Video Studio** |
|---|---|---|
| Benchmark | Snapseed, Lightroom Mobile | CapCut, VN, LumaFusion |
| How we beat it | Layers + masks on every tool, editable history stack, LUT import, saveable/shareable looks, batch edit, 16-bit float pipeline, fully offline | Same look/adjust engine as photos, offline smart tools, pro audio, scopes, LUTs, HEVC/4K, project interchange (FCPXML) |
| Output | JPEG / PNG / WebP / HEIF* at full resolution | MP4 (H.264 / HEVC), GIF, audio-only, stills |

\* HEIF output depends on the Android encoder; not verified.

**Product promise (unchanged, FACTS F-30..F-32):** works offline, no account, no ads, no tracking.
AI features run on the device. Anything that would break this is listed as a decision in §9.

## 1. Where we are today (2026-11-11)

Video Studio already has: multi-clip timeline, trim/split/duplicate/delete, reorder, undo/redo +
autosave, 7 transitions, text overlays (styling, SRT import), music (trim, fades, ducking),
speed 0.25–4×, rotate/flip, fit/fill/blur, frame shapes, playhead tools, **39 looks + strength**
(GPU shader preview), before/after compare, offline assistant + smart tools (silence removal,
scene split, loudness balance, auto-polish), export 480p–4K with hardware H.264 High profile,
enhance pass, FCPXML export. 308 unit tests.

Photo Studio: nothing yet (photos can only be clips on the video timeline).

Open items carried in: see Phase 0.

## 2. Ground rules (every feature)

1. **Offline by default.** No network code. ML runs on-device with models bundled or shipped as
   on-demand asset packs (decision D2).
2. **Only filters that exist in the phone build.** The FFmpegKit build is non-GPL. Verified
   present (name strings in `libavfilter.so`, 2026-11-11): see §8. GPL filters (`eq`, `boxblur`,
   `hqdn3d`, `smartblur`, vid.stab, rubberband) are **absent** — never use them.
3. **Never pass FFmpeg options positionally** unless checked against the filter's option table
   (FACTS B-06 — this caused the blue export bug).
4. **One spec, two renderers.** Every visual tool is plain data (like `LookSpec`) rendered by the
   GPU shader for preview *and* photo export, and by FFmpeg for video export.
5. **Non-destructive.** Originals are never modified; edits are data in SQLite.
6. **Measured on the target phone** (Samsung SM-A366E, Android 16) before a feature is "done":
   preview ≥ 30 fps on 1080p, export time recorded in `docs/PERFORMANCE.md`.
7. **New package = named first** (owner OK'd small ones, 2026-11-11): name, size, licence,
   16 KB-page support.

## 3. Architecture

```
               ┌──────────────── Home ─────────────────┐
               │  Edit photo   │   Edit video   │ Recent │
               └──────┬────────┴───────┬─────────────────┘
                      ▼                ▼
             Photo Studio        Video Studio
                      │                │
   ┌──────────────────┴────────────────┴───────────────────┐
   │ SHARED CORE                                            │
   │  Edit specs (pure Dart): Look, Adjust, Curve, HSL,     │
   │    SplitTone, Mask, Text, Sticker, Crop/Transform      │
   │  Renderers: GPU shader chain (preview + photo export)  │
   │             FFmpeg graph builder (video export)        │
   │  Masks: brush, radial, linear, luminance, color, AI    │
   │  Analysis: histogram, auto-tone, scenes, beats, speech │
   │  Assistant: planner → EditActions → executor           │
   │  Project DB (Drift) + history (undo/redo, autosave)    │
   │  Media IO: import, thumbnails, gallery save, share     │
   └────────────────────────────────────────────────────────┘
```

### 3.1 The edit-stack model (both studios)

Snapseed's best idea is the **stack**: an ordered list of tool steps you can reopen, reorder,
toggle or delete at any time. We adopt it everywhere:

- `EditStep { id, kind, params (JSON), mask (nullable), enabled, order }`
- Photo: steps belong to the photo. Video: steps belong to a clip (and later to an adjustment
  layer that spans clips).
- Each `kind` has: a pure spec, a shader pass, and (if it can apply to video) an FFmpeg mapping.
- The existing per-clip columns (brightness, look, …) become the first steps; a migration turns
  old columns into steps so nothing breaks (session X3).
- **Phase 1 shortcut (2026-11-11):** photos store their edits as one versioned JSON document
  (`PhotoProjects.editJson`, model `lib/photo/photo_edit.dart`) — a fixed set of tools, no
  per-step rows yet. Convert to `EditStep` rows when masks (P2.4) make per-step data necessary;
  the JSON `version` field exists for that migration.

### 3.2 Photo pipeline (new)

- **Preview:** decode at screen resolution, run the shader chain per step (one fragment shader
  per kind, composed with `ImageFilter.compose` or ping-pong `ui.Image`s). Masks are textures.
- **Export at full resolution, same shaders:** render offscreen with `PictureRecorder` →
  `toImage` in **tiles** (GPU max texture is often 4096–8192 px; a 50 MP photo needs tiling with
  a margin for neighbour-sampling tools), stitch, encode. Because preview and export use the same
  shader, **photo export is pixel-identical to the preview** — something the video path can only
  approximate.
- **Encoding:** PNG via `toByteData(png)`; JPEG/WebP via FFmpeg's `mjpeg` / `libwebp` encoders
  (both present) from the PNG, or a small encoder package (decision D3). Keep EXIF (date,
  orientation reset, GPS only if the user opts in).
- **Precision:** shaders run in float; keep intermediate images in a float format where the GPU
  allows, so heavy edits don't band.

### 3.3 Video pipeline (existing, extended)

Preview = video_player texture + shader `ImageFiltered`; export = one FFmpeg command. New for
the Pro phases: **proxy files** (720p H.264 made in the background) for smooth editing of 4K
footage, and **continuous playback** across clips (FEATURE_PLAN F21).

## 4. Photo Studio — features

Effort: **S** (≤1 session), **M** (1–2), **L** (3+). Class: **A** shader/UI only, **B** needs
CPU analysis, **C** needs an ML model (decision D2).

### Phase P1 — Photo MVP ("a real photo editor")
| ID | Feature | Class | Effort | Notes |
|---|---|---|---|---|
| P1.1 | Home: *Edit photo / Edit video*, photo projects in Recent | A | S | New `PhotoProjects` + `EditSteps` tables |
| P1.2 | Photo editor screen: big zoomable canvas, tool bar, stack panel, compare (hold + split) | A | M | Reuse `LookFiltered` compare |
| P1.3 | **Tune**: exposure, brightness, contrast, highlights, shadows, whites, blacks, saturation, vibrance, warmth, tint, fade | A | M | One `adjust.frag`; values in the step's JSON |
| P1.4 | **Looks** (all 39 + strength) on photos | A | S | Already built |
| P1.5 | **Crop & rotate**: ratios, free, straighten ±45°, flip, rotate 90° | A | M | Transform step; export crops the full-res source |
| P1.6 | **Details**: sharpen, structure (local contrast), clarity, noise reduction | A | M | Multi-tap shader; NR = bilateral |
| P1.7 | **Vignette** (centre, size, feather) and **grain** (amount, size) | A | S | |
| P1.8 | Full-resolution export (tiled), JPEG quality / PNG / WebP, save + share | A | M | §3.2 |
| P1.9 | Histogram + clipping warnings | B | S | Computed on the preview image |

### Phase P2 — Photo Pro ("better than Snapseed")
| ID | Feature | Class | Effort | Notes |
|---|---|---|---|---|
| P2.1 | **Curves**: RGB + per-channel, presets | A | M | Curve baked to a 256×1 LUT texture |
| P2.2 | **HSL / colour mixer**: hue, saturation, luminance for 8 colour bands | A | M | |
| P2.3 | **Colour grading wheels**: shadows / midtones / highlights + balance | A | M | Generalises split tone |
| P2.4 | **Masks on every step**: brush (size, feather, erase), radial, linear gradient, luminance range, colour range | A | L | Mask = texture; brush strokes stored as vector paths so they re-render at full res |
| P2.5 | **Selective / control points** (Snapseed-style): tap to place, drag to adjust | A | M | Implemented as auto colour+distance masks |
| P2.6 | **Healing / spot removal** (clone + blend) | B | L | Patch-match on CPU in an isolate; ML inpainting later (P3.3) |
| P2.7 | **Perspective** (keystone H/V) and lens correction | A | M | Homography in shader |
| P2.8 | **Text, stickers, frames/borders**, watermark/brand kit | A | M | Shares the overlay system with video (V2.3) |
| P2.9 | **LUT import** (`.cube`) as looks; save own looks as presets; share preset file | A | M | 3D LUT texture; same LUT drives video via `lut3d` (present) |
| P2.10 | **Copy/paste edits & batch edit** (apply a stack to many photos, batch export) | A | M | |
| P2.11 | Effects: HDR-scape, glamour glow, tonal contrast, drama, double exposure, tilt-shift, lens blur (depth-free) | A | M each | Each is a shader kind |
| P2.12 | Edit history browser: jump to any step, branch | A | S | Stack already gives this |

### Phase P3 — Photo AI (on-device, decision D2)
| ID | Feature | Class | Notes |
|---|---|---|---|
| P3.1 | **Auto-enhance** (one tap): exposure/contrast/WB from histogram + grey-world | B | No model needed — ship early |
| P3.2 | **Select subject / sky / person** → mask | C | Segmentation model |
| P3.3 | **Magic eraser** (remove object) | C | Inpainting model; heavy |
| P3.4 | **Background remove / replace / blur (portrait mode)** | C | Uses P3.2 |
| P3.5 | **Face retouch**: smooth skin, eyes, teeth (face landmarks) | C | |
| P3.6 | **Upscale ×2/×4** (super-resolution) | C | Slow on mid-range; show estimate |
| P3.7 | **Anime / art style transfer** (real AI, beyond the filter looks) | C | Style-transfer model per style |
| P3.8 | Natural-language editing ("make the sky moodier") via the existing assistant + masks | B/C | Planner learns photo actions |

## 5. Video Studio — features

### Phase V1 — Finish the core (mostly FEATURE_PLAN_25)
| ID | Feature | Effort | Notes |
|---|---|---|---|
| V1.1 | **Continuous playback across clips** (F21) | L | Biggest UX gap today |
| V1.2 | Crop / zoom / pan, Ken Burns (F14) | M | `zoompan` present |
| V1.3 | Freeze frame, reverse (F17) | M | `reverse` buffers RAM → cap length |
| V1.4 | Multiple audio lanes: music + SFX + voice (F18), voice-over recording (F20) | L | Needs `record` package (D3) |
| V1.5 | Image overlays / stickers / logo (F16) | L | Shares P2.8 overlay system |
| V1.6 | Foreground service for long exports (F22) | M | |
| V1.7 | Timeline: pinch-zoom, magnetic snapping, multi-select, ripple delete | M | |

### Phase V2 — Video Pro (CapCut-class)
| ID | Feature | Effort | Notes |
|---|---|---|---|
| V2.1 | **Multi-track timeline**: overlay video (PiP, F24), multiple text/sticker tracks | L | Architecture change: tracks table |
| V2.2 | **Keyframes** for position/scale/rotation/opacity/volume/any adjust value (F23), easing curves | L | |
| V2.3 | **Text pro**: templates, per-word animation (typewriter, pop, bounce), outlines/shadows, fonts import | L | `ass` subtitles filter present for animated text export |
| V2.4 | **Chroma key** (F25) + despill, colour key, luma key | M | `chromakey`, `despill`, `colorkey` present |
| V2.5 | **Masks on clips** (shape/linear/radial, feathered) + blend modes | L | `maskedmerge`, `blend` present |
| V2.6 | **Speed curves** (ramps) + smooth slow-mo (frame interpolation) | L | `minterpolate` present; very slow → preview at low res |
| V2.7 | **Colour pro**: wheels, curves, HSL, LUT import, **scopes** (histogram, waveform, vectorscope) | L | Shares P2 specs; `lut3d`, `waveform`, `vectorscope` present |
| V2.8 | **Stabilisation** | M | `deshake` present (vid.stab is GPL, absent) |
| V2.9 | **Audio pro**: noise reduction (`afftdn`, `arnndn`), loudness normalisation to −14 LUFS (`loudnorm`), EQ, compressor, de-esser, voice effects (echo, chorus, robot, pitch via `asetrate`) | M | All present; no rubberband |
| V2.10 | **Adjustment layers** (one edit stack over a time range) | M | |
| V2.11 | **Export pro**: HEVC (`hevc_mediacodec`), 10-bit/HDR passthrough (`zscale`/`tonemap` present), 24/25/30/50/60 fps, GIF, audio-only, frame grab, platform presets (Reels, Shorts, TikTok, YouTube) | M | |
| V2.12 | **Proxies** for 4K/HEVC editing | M | Background job |
| V2.13 | **Templates**: save a project as a template with placeholders, apply to new media | L | |

### Phase V3 — Video AI (on-device)
| ID | Feature | Class | Notes |
|---|---|---|---|
| V3.1 | **Auto captions** (speech-to-text) with styling + SRT export | C | Whisper-class model, largest single asset |
| V3.2 | **Beat sync**: detect beats in music, snap cuts / auto-cut to beat | B | Onset detection on decoded PCM — no model |
| V3.3 | **Auto-reframe** (keep the subject in frame when changing 16:9 → 9:16) | C | Face/person detection per frame |
| V3.4 | **Background removal** without green screen | C | Segmentation per frame; slow |
| V3.5 | **Highlight finder**: best moments from long clips (motion, faces, audio peaks, `scdet`) | B | |
| V3.6 | **Filler-word / silence removal** for talking videos | B/C | Silence: done; "um" needs speech model |
| V3.7 | Assistant v2: multi-step plans, explains what it did, works on photos too | B | |

## 6. "Enterprise level" — quality bar, not just features

| Area | Target |
|---|---|
| Reliability | No data loss: autosave every edit (have), crash-safe DB writes, export never blocks the editor, resumable after app kill |
| Performance | Preview ≥ 30 fps for 1080p with 3 looks/adjusts; photo export of 12 MP < 3 s; video export ≤ 1.5× real-time at 1080p on the target phone |
| Testing | Unit tests for every spec and FFmpeg mapping (have 308); widget layout tests at 320/360/412 px (have); golden images for shaders; device test matrix (`docs/TESTING.md`) |
| Diagnostics | Local, user-controlled: "Copy error details" (have), exportable debug log, no telemetry |
| Projects | Backup/restore a project as one file (media + DB rows), duplicate, templates, cloud-free transfer via share sheet |
| Brand kit | Saved fonts, colours, logo watermark, intro/outro, export presets |
| Accessibility | Screen-reader labels on all controls, 48 dp targets, contrast ≥ 4.5:1, large-text layouts |
| Localisation | All strings in ARB files; RTL layout support |
| Design | One design system: tokens (colours, spacing, radii), component library, motion guidelines, dark + light theme |
| Legal | Licence notices for every bundled font/model/package; privacy policy matches reality |

## 7. Roadmap (ordered; each line ≈ one or two sessions)

**Phase 0 — Stabilise (now)**
1. Verify the colour fix on the phone (export Cool/Blockbuster/Anime; FACTS B-06).
2. Fix: an export missing from the gallery (file left in cache).
3. Bring `tools/graph_prototype.py` up to date with looks v2, or retire it in favour of device
   golden tests (decision D4).
4. Design system v1 (tokens, components) — everything after builds on it.

**Phase 1 — Photo MVP:** X1 edit-step tables + migration → P1.1 → P1.2 → P1.3 → P1.5 → P1.8 →
P1.4 → P1.6 → P1.7 → P1.9 → P3.1 (auto-enhance, no model).

**Phase 2 — Video core:** V1.1 → V1.7 → V1.2 → V1.3 → V1.5 → V1.4 → V1.6.

**Phase 3 — Photo Pro:** P2.1 → P2.2 → P2.4 → P2.5 → P2.3 → P2.9 → P2.7 → P2.8 → P2.10 → P2.6 → P2.11 → P2.12.

**Phase 4 — Video Pro:** V2.7 (shares P2 colour specs) → V2.9 → V2.11 → V2.1 → V2.2 → V2.4 →
V2.5 → V2.3 → V2.8 → V2.10 → V2.12 → V2.6 → V2.13.

**Phase 5 — AI (after D2):** P3.2 → P3.4 → V3.2 → V3.5 → V3.1 → P3.3 → V3.3 → P3.5 → P3.6 →
P3.7 → V3.4 → V3.6 → V3.7/P3.8.

**Phase 6 — Launch quality:** accessibility, localisation, Play Store checklist
(`docs/LAUNCH_CHECKLIST.md`: release signing B-03, permissions B-04), performance pass.

Roughly 70–90 sessions in total. Phases 1 and 2 can interleave; Phase 3 depends on Phase 1;
Phase 4's colour work depends on Phase 3's specs.

### Dependencies
```
X1 edit steps ─▶ every P* tool, V2.7, V2.10
P2.4 masks ───▶ P2.5, P3.2–P3.5, V2.5
P2.8 overlays ─▶ V1.5, V2.3
V1.1 playback ─▶ V2.1, V2.2, V2.6
V2.1 tracks ──▶ V2.2, V2.4, V2.5, V2.13
D2 (ML) ──────▶ all class-C items
```

## 8. Phone FFmpeg capability map (checked 2026-11-11, `libavfilter.so`/`libavcodec.so` name strings)

Present and planned for: colorchannelmixer, lutrgb, lut3d, haldclut, colorbalance, curves,
colorlevels, vibrance, huesaturation, selectivecolor, exposure, colortemperature, gblur, avgblur,
dblur, bilateral, nlmeans, unsharp, cas, atadenoise, deband, vignette, noise, edgedetect, blend,
maskedmerge, alphamerge, overlay, xfade, zoompan, rotate, v360, lenscorrection, chromakey,
colorkey, despill, hsvkey, backgroundkey, deshake, minterpolate, framerate, reverse, drawtext,
ass, subtitles, zscale, tonemap, colorspace, histogram, waveform, vectorscope, scdet,
freezedetect, blackdetect; audio: atempo, asetrate, afftdn, arnndn, anlmdn, loudnorm, ebur128,
dynaudnorm, speechnorm, silenceremove, silencedetect, volumedetect, sidechaincompress,
acompressor, equalizer, superequalizer, firequalizer, highpass, lowpass, deesser, adeclick,
aecho, chorus, flanger, vibrato, tremolo, stereowiden, crystalizer, aexciter, areverse.
Encoders: h264_mediacodec, hevc_mediacodec, av1_mediacodec, mpeg4, libkvazaar, libvpx(-vp9),
prores_ks, dnxhd, mjpeg, png, libwebp(_anim), gif, apng, tiff, aac, libmp3lame, libopus, flac.

**Absent:** eq, boxblur, smartblur, hqdn3d, vid.stab, rubberband, cropdetect, libx264,
libopenh264, libaom, libsvtav1, libvmaf.

⚠️ A name string proves the filter is compiled in, not that a given option set works on this
phone. Each feature still runs once on the device before it is marked done.

## 9. Decisions needed from the owner

| # | Decision | Options | Recommendation |
|---|---|---|---|
| D1 | App structure | One app with two studios / two separate apps | **One app**: shared engine, one store listing |
| D2 | How to ship ML models (needed for every class-C feature) | (a) Bundle small models in the APK; (b) Play asset packs downloaded on first use (needs network once); (c) Google ML Kit on-device (closed source, Play Services); (d) skip ML | **(b) asset packs + open models** (MediaPipe/ONNX/TFLite): app stays small, offline after download. Requires changing "no network" to "no network except optional model downloads" in the privacy policy |
| D3 | Packages | `record` (voice-over), an image codec package (JPEG/WebP/HEIF) vs FFmpeg encoders, an ML runtime | Decide per feature; FFmpeg encoders first to avoid a package |
| D4 | Python graph mirror | Keep updating / retire for device golden tests | Retire; replace with on-device golden exports |
| D5 | Monetisation | Free / one-time Pro unlock / subscription | Affects which features ship in which build; no ads (promise) |
| D6 | iOS | Android only / later iOS | Android first; keep code platform-neutral |
| D7 | Min Android version | Current / raise to Android 10+ | Raising simplifies storage and HEVC |

## 10. Risks

| Risk | Mitigation |
|---|---|
| Preview and export drift apart (happened: B-06) | One spec per tool; tests that parse generated FFmpeg filters like FFmpeg does; photo export uses the preview shader itself |
| Mid-range GPU too slow for stacked shaders | Merge steps into one pass where possible; preview at reduced resolution while dragging |
| ML models make the app huge | Asset packs (D2), per-feature download |
| Very large photos exceed GPU texture limits | Tiled export (§3.2) |
| FFmpeg filter exists but misbehaves on device | Run every new filter once on the phone; record in `docs/FFMPEG_COOKBOOK.md` |
| Scope creep | Phase gates: a phase ends with a phone test pass and a release-able build |
