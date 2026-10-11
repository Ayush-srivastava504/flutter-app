# Phase 7 Progress — Transitions & Filters

Two passes. The first pass (below, "Built (first pass)") shipped live
per-clip filters and a real transition picker at the clip boundary, as
a checkpoint — deliberately stopping short of rendering
transitions/filters at a boundary and of "apply globally". This second
pass ("Built (second pass)") closes out both, so Phase 7 is now a
finished phase rather than a checkpoint. What's left (true two-video
frame-level crossfade, baking any of this into an exported file) is
genuinely Phase 8 / the standing Phase 4 cross-clip gap, not Phase 7
specifically — see "Not done" at the bottom.

## Built (first pass)

- **Schema**: `Clips.brightness/contrast/saturation` already existed
  (declared ahead of this phase, unused). Added `Clips.filterPreset`
  (nullable text — schema v4 → v5, migration added) so `FilterPanel`
  can highlight which bundled preset, if any, a clip's current numbers
  match. The three numeric columns stay the actual source of truth;
  `filterPreset` is a UI convenience only.
- **Color-matrix math** (`models/color_filter_x.dart`): pure,
  dependency-free functions turning brightness/contrast/saturation
  (each -1.0..1.0, 0 = unchanged) into the flat 4x5 matrix
  `ColorFilter.matrix` expects — composed from three classic per-effect
  matrices (brightness offset, contrast scale-from-mid-gray, saturation
  blend-to/from Rec.601 luma) multiplied together, rather than one
  hand-derived combined formula. Also holds the bundled preset catalog
  — Original, Vivid, Warm, Cool, B&W, Vintage (5 beyond the no-op,
  within the spec's 3–5) — and `isNeutralFilter` so unedited clips skip
  wrapping the preview in a filter at all. Unit-tested directly in
  `test/color_filter_matrix_test.dart` (non-UI logic, same rationale as
  `text_overlay_layer_math_test.dart`).
- **Live filter preview**: `VideoPreviewPlayer` gained
  `brightness`/`contrast`/`saturation` params and wraps its content in
  a `ColorFiltered` built from the matrix above — applies to the photo
  branch too, not just video. `EditorScreen` feeds it straight from the
  selected clip's row, so a slider drag or preset tap in `FilterPanel`
  shows up on the preview immediately, no separate render step.
- **`FilterPanel`** (`widgets/timeline/filter_panel.dart`): brightness/
  contrast/saturation sliders (-1.0..1.0, centered on 0) plus a
  horizontally-scrolling row of preset chips. Tapping a preset sets all
  three values and stamps `filterPreset`; dragging a slider clears
  `filterPreset` back to null ("Custom") since its exact numbers no
  longer match any chip. Same commit-on-release pattern as `TrimPanel`'s
  volume slider.
- **Trim/Filters tab switch**: `EditorScreen`'s bottom panel now shows
  a small `_ClipPanelTabBar` above whichever of `TrimPanel`/
  `FilterPanel` is active for the selected clip, instead of jumping
  straight to trim controls. Screen-level state, not per-clip — staying
  on "Filters" while tapping through several clips in a row is the more
  likely intent than resetting to "Trim" every tap.
- **Transition picker at the clip boundary**: `TimelineClipTile` gained
  a small tappable badge at its trailing edge (every clip but the last)
  showing `Clip.transitionOut`'s current icon — cut (scissors, dim),
  fade (gradient), or cross-dissolve (blur) — colored to match the
  existing "this clip has a transition" indicator it replaces. Tapping
  it opens a bottom sheet (`TimelineStrip._pickTransition`) to change
  it, persisted via the existing `transitionOut` column. This is the UI
  control the spec's item 1 asks for; previously the column existed and
  the tile even had a colored bar hinting at it, but nothing could
  actually set it.

## Built (second pass — closing out Phase 7)

- **Boundary transition rendering** (`models/transition_x.dart` +
  `EditorScreen._buildPreviewArea`): picking Fade or Cross-dissolve now
  actually shows something as the playhead nears that clip's trimmed
  end, both while scrubbing and while playing (position comes from the
  same `playheadMs` `VideoPreviewPlayer.onPositionTick` already drives).
  `transitionPreviewAt` is a pure function (unit-tested in
  `test/transition_preview_test.dart`) mapping playhead-to-boundary
  distance into two opacities: `dissolve` is a straight linear
  crossfade over the last 600ms; `fade` fades the current clip to black
  over the window's first half, then fades in from black over the
  second — visibly distinct from a dissolve. `EditorScreen` composes
  this as a `Stack`: a black backdrop, the live `VideoPreviewPlayer` at
  `currentOpacity`, and the *next* clip's cached thumbnail at
  `nextOpacity` on top. Deliberately thumbnail-based rather than a true
  second `VideoPlayerController` seeked to the next clip's start — see
  "Not done" below for why that's the right scope line, not a shortcut
  taken by accident. Skips the `Stack`/`Opacity` wrapping entirely
  outside the transition window (the common case) so unedited playback
  isn't paying for it.
- **"Apply globally"** (the rest of spec item 3):
  `ProjectDatabase.applyFilterToAllClips` bulk-writes the same
  brightness/contrast/saturation/filterPreset to every clip in a
  project inside one transaction. `FilterPanel` gained a "This clip" /
  "All clips" `ChoiceChip` toggle above the preset row; both the preset
  taps and the slider `onChangeEnd` route through the same `_persist`
  call, which picks the single-clip or bulk write based on that toggle
  — no separate global-filter storage or composition model, "globally"
  here means literally setting every clip's own columns at once, which
  keeps it consistent with how per-clip filters already render (both
  live-preview and, eventually, export read the exact same three
  columns either way).

## Not done

- **True two-video frame-level crossfade.** The boundary preview above
  blends toward a *thumbnail*, not the next clip's actual playing video
  — because `VideoPreviewPlayer` previews one clip's
  `VideoPlayerController` at a time and still doesn't auto-advance
  across a boundary (the gap flagged since Phase 4 — see
  PHASE_4_PROGRESS.md). Standing up a second live controller
  pre-seeked to the next clip's trim-start just for the transition
  window, torn down again after, would work but is real state-
  management surface area worth building deliberately alongside
  whatever finally closes the Phase 4 gap, not bolted onto this pass's
  thumbnail approach as an afterthought.
- **Baking any of this into an exported file** is Phase 8 scope — the
  export pipeline doesn't exist yet, so nothing here has anywhere to
  render *to* besides the live preview.
- Transition *duration* is still a fixed 600ms (`transitionWindowMs`),
  not user-configurable — the spec only asks for the transition types
  themselves to be selectable, so a duration control was left for
  whichever pass makes duration matter to export timing too.

## Next step

Phase 8: an export pipeline. Per the top-level sequencing notes,
worth validating early even as a stub (trim + concatenate) rather than
attempting trims + filters + transitions + text + audio all at once —
the trim-only stub is also exactly where "does compositing this many
tracks together even work on this device" gets answered before more
phases are built on top of an unvalidated assumption.

