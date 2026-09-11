# Phase 6 Progress — Text & Overlays

Two passes. The first pass (below, "Built (first pass)") shipped items
1–5 from the spec — add/style/position/time/multiple overlays — as a
checkpoint, deliberately stopping short of the playback-sync gap,
letterboxing, timeline visualization, and tests. This second pass
("Built (second pass)") closes out all four, so Phase 6 is now a
finished phase rather than a checkpoint. What's left (bundled fonts,
burning text into the export, and the broader continuous-playback gap
that predates this phase) is genuinely out of scope for text overlays
specifically — see "Not done" at the bottom.

## Built (second pass — closing out Phase 6)

- **Live playhead sync during playback** (the checkpoint's main scope
  boundary): `VideoPreviewPlayer` gained `onPositionTick`, called on
  every controller tick with this clip's position mapped onto the
  timeline (the same mapping `_syncMusic` already used internally for
  the music track). `EditorScreen` wires it straight into
  `playheadMsProvider`, so — for the first time — that provider
  advances during live playback, not just on scrub. `TextOverlayLayer`
  needed no changes to benefit: it already just reads
  `playheadMsProvider`. One care point: the reported position is
  clamped to just under the clip's own end, since `_enforceTrimBounds`'s
  loop-back seek is async and hasn't necessarily landed by the time the
  tick fires — reporting the raw boundary value could momentarily read
  as the *next* clip's start and swap `VideoPreviewPlayer`'s key out
  from under the controller that's still actually playing. This is
  still scoped to *within* whichever clip is currently open, the same
  boundary Phase 4/5 already flagged for cross-clip playback in
  general — this pass doesn't touch that larger gap, just stops text
  overlays (and anything else reading the playhead) from freezing
  the moment you press play.
- **Position mapping under letterboxing**: `letterboxedFrame()` and
  `dragFractionDelta()` (new pure functions in `models/text_overlay_x.dart`,
  unit-tested in `test/text_overlay_layer_math_test.dart`) compute the
  actual video frame's rect inside the preview canvas — using the same
  "contain" fit the preview itself renders with — from a reported
  aspect ratio. `VideoPreviewPlayer` gained `onAspectRatioKnown`,
  called once its controller decodes the source's aspect ratio;
  `EditorScreen` caches it per clip id and feeds it to
  `TextOverlayLayer`, which now maps overlay positions/drags onto the
  letterboxed frame rather than the full canvas. Scoped to video clips
  — photos still map to the full canvas, since getting a photo's
  intrinsic size means a decode step this pass didn't take on; falls
  back to full-canvas behavior automatically when the aspect ratio
  isn't known yet, so this degrades gracefully rather than breaking
  photo-only projects.
- **Timeline-strip visualization of overlays**: `TextOverlayStrip`
  (new, under `AudioTrackLane` in `EditorScreen`'s layout) — a
  multi-row lane showing every overlay's `[startMs, endMs)` against the
  video timeline at a glance, the same "align spatially, not just via a
  slider" view `AudioTrackPanel` already gives music. Simultaneous
  overlays get greedy-interval-partitioned into separate rows (capped
  at 3 visible rows, scrollable beyond that) so they don't draw on top
  of each other; sequential ones share a row. Tapping a segment selects
  that overlay and opens `TextOverlayPanel`, same entry point as
  tapping it on the canvas. Collapses to nothing with zero overlays —
  unlike `AudioTrackLane`'s empty state, there's no "add" affordance to
  double as here, since the tool-row "Add text" button already covers
  that.
- **Tests** — the project's first ones. Three files, matching exactly
  the candidates the first pass's "Not done" section named:
  - `test/text_overlay_timing_test.dart` — `TextOverlayTiming.activeAt`
    (half-open interval, boundary behavior between adjacent/overlapping
    overlays).
  - `test/text_overlay_layer_math_test.dart` — `letterboxedFrame()` and
    `dragFractionDelta()`, the drag-to-fraction/letterbox math pulled
    out of `TextOverlayLayer`'s private widget into standalone
    functions specifically so they're unit-testable without pumping a
    widget tree.
  - `test/project_database_migration_test.dart` — the v3→v4
    `TextOverlays` migration, exercised against a realistic "old
    install" file (built via `test/support/legacy_v3_database.dart`, a
    second `@DriftDatabase` reusing the real `Projects`/`Clips`/
    `AudioTracks` table definitions frozen at schema version 3) rather
    than hand-written SQL that could drift out of sync with the real
    schema. Also covers the fresh-install (`onCreate`) path separately.
  - `ProjectDatabase` gained a `forTesting(QueryExecutor)` constructor
    (`@visibleForTesting`) so tests can point it at an in-memory/temp
    file instead of the real on-device path (which needs
    `path_provider`'s platform channel, unavailable outside a running
    app).
  - Run with `flutter test` after the usual `flutter pub get` +
    `dart run build_runner build --delete-conflicting-outputs` (the
    latter now also generates `test/support/legacy_v3_database.g.dart`
    — build_runner picks up any `@DriftDatabase`-annotated class in the
    package, not just ones under `lib/`).

## Built (first pass)

- **Data layer**: `TextOverlays` had existed as an unused table stub
  since the Phase 5 zip (declared in `@DriftDatabase(tables: [...])` but
  never migrated or queried). This pass:
  - Added an `alignment` column (0/1/2 = left/center/right — see
    `models/text_overlay_x.dart`), the one field the spec needed that
    the stub didn't have.
  - Bumped `schemaVersion` 3 → 4 and added the `from < 4` migration step
    that actually creates the table for anyone upgrading from a real
    Phase 5 install (previously only `onCreate`'s `createAll()` — i.e.
    brand-new installs — would ever have gotten it).
  - Added full CRUD on `ProjectDatabase`: `watchTextOverlays`,
    `getTextOverlay`, `insertTextOverlay`, `updateTextOverlay`,
    `deleteTextOverlay` — plural from the start (unlike `AudioTracks`),
    since "multiple simultaneous or sequential" overlays is the point.
- **Add a text box** (item 1): a "Add text" button lives in the tool row
  (`EditorScreen`, where the old static "Tools: Text · Transitions ·
  Filters" label was). Tapping it inserts a new overlay — centered,
  default content "Tap to edit", `startMs` = current playhead, `endMs` =
  +3s (clamped to the timeline's end) — and opens `TextOverlayPanel` on
  it immediately so there's no separate "now find your new box" step.
- **Styling** (item 2): `TextOverlayPanel` — a content field, four font
  presets, a size slider (12–72), eight color swatches, and a
  left/center/right alignment toggle. Font presets are generic family
  names (`serif`/`monospace`/`cursive`/default) rather than bundled font
  assets — see the doc comment on `textFontPresets` in
  `models/text_overlay_x.dart` for why, and the "Not done" note below.
- **Positioning via drag** (item 3): `TextOverlayLayer`, stacked on top
  of `VideoPreviewPlayer` in `EditorScreen`'s preview area. Each active
  overlay is a `Positioned` + `GestureDetector` using fractional
  (0.0–1.0) coordinates against the preview canvas size, so position
  stays valid regardless of device/canvas size — same reasoning
  `AudioTracks`' ms-based fields use to stay valid across zoom. Dragging
  keeps the new position in local widget state and only writes to the
  DB on release (same "local state, commit on end" pattern `TrimPanel`
  uses for trim handles), so a drag doesn't spam sqlite writes every
  frame. Tapping an overlay selects it and opens the panel.
- **Timing** (item 4): a `RangeSlider` in `TextOverlayPanel` bounded by
  the video timeline's total (trimmed) length, editing `startMs`/
  `endMs` directly. `TextOverlayLayer` only renders overlays where
  `playheadMs` falls in `[startMs, endMs)` — dragging the scrub bar
  shows/hides overlays exactly where you'd expect.
- **Multiple overlays** (item 5): structurally this was already covered
  by `TextOverlays` being one-row-per-overlay with its own timing/
  position — nothing about the data model or `TextOverlayLayer`'s
  render loop assumes there's only one. Two overlays with overlapping
  `[startMs, endMs)` both render (simultaneous); two with disjoint
  ranges each show only in their own window (sequential). The tool-row
  button shows a running count (`Add text (2)`, etc.) once there's more
  than zero, so it's discoverable that overlays are stacking up rather
  than being replaced.
- Panel precedence: text/audio/clip panels already didn't stack (each
  entry point closes the others — see `audioPanelOpenProvider` uses in
  `timeline_strip.dart`/`audio_track_lane.dart`). Extended the same
  convention so opening the text panel closes the audio/trim panels and
  vice versa, rather than fighting over the bottom third of the screen.

## Resolved this pass (was: "Known scope boundary")

`TextOverlayLayer` reads `playheadMsProvider`, which used to be
**only updated by scrubbing**, not by live playback — press play and
overlays stayed frozen wherever the scrub bar last left them. Fixed
via `VideoPreviewPlayer.onPositionTick`; see "Built (second pass)"
above for the details, including the boundary-race guard it needed.

## Not done (fair to leave for later)

- **Bundled/custom fonts**: the four presets are generic family names
  (`serif`, `monospace`, `cursive`, platform default), not real bundled
  fonts — Android's Skia matcher resolves these directly, iOS falls back
  to the system font gracefully if a name isn't installed. Good enough
  to ship styling that *works*, not a real type system. Swapping in
  actual bundled fonts (same pattern as Phase 5's bundled audio assets)
  is a follow-up, not a rewrite — only `textFontPresets` and the
  `pubspec.yaml` assets/fonts block would change.
- **Burning text into the exported video** — this pass is preview-only,
  same as every other timeline edit so far; compositing (video + trims +
  audio mix + now text) all happens at export, which is Phase 8's job
  per the existing convention (`splitClip`'s doc comment says the same
  thing about trims).
- **Letterboxing for photo clips**: the letterboxing fix (see "Built
  (second pass)") only reports an aspect ratio for videos — photo
  clips still map overlay positions to the full preview canvas.
  Getting a photo's intrinsic size needs a decode step
  (`onAspectRatioKnown` currently only fires from
  `VideoPlayerController.initialize()`); a small, contained follow-up,
  not a rewrite.
- **Continuous cross-clip playback**: playback still only loops
  *within* whichever clip is currently open (`_enforceTrimBounds`); it
  doesn't auto-advance to the next clip. This pass's playhead-sync fix
  makes that within-clip playback correctly drive the playhead (and
  overlays) — it doesn't add cross-clip advancing, which is the same
  broader gap `PHASE_4_PROGRESS.md`/`PHASE_5_PROGRESS.md` already
  flagged for video and music, essentially a mini version of what
  Phase 8's export compositor does, and out of scope for a
  text-overlays phase specifically.
