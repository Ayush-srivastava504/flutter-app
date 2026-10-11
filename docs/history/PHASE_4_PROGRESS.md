# Phase 4 Progress — Timeline & Core Editing

## Built (this pass)

- **Data layer**: `Clips` table gained `rotationDegrees` and `thumbnailUri`
  columns (carried over from the `MediaAsset` created at import). New
  `ProjectDatabase` methods: `appendClip`, `reorderClips`,
  `deleteClipAndReindex`, `splitClip`, and a generalized `updateClip`
  that accepts either a `Clip` or a `ClipsCompanion`. All four run inside
  transactions so the timeline never observes a half-written state.
- **Import → timeline**: picking a video/photo now inserts a `Clip` row
  directly (via `appendClip`) instead of just holding it in a one-off
  preview variable. Photos get a fixed 3s slot, matching the note left
  in Phase 3.
- **Timeline strip** (`timeline_strip.dart` + `timeline_clip_tile.dart`):
  horizontal, thumbnail-backed, long-press-drag-to-reorder
  (`ReorderableListView`), pinch-to-zoom (10–200 px/sec, clamped).
- **Trim** (`trim_panel.dart`): drag handles over the clip's full source
  duration; edits are non-destructive (`trimStartMs`/`trimEndMs` only,
  source file untouched) and commit to the DB on drag-end.
- **Split**: "split at playhead" button in the trim panel, backed by
  `ProjectDatabase.splitClip` — validates the playhead actually falls
  inside the selected clip first.
- **Delete**: button in the trim panel, backed by
  `deleteClipAndReindex` (keeps `orderIndex` contiguous).
- **Playhead + scrub**: `TimelineScrubBar` is a lightweight full-width
  bar (independent of strip zoom) that sets `playheadMsProvider` on
  drag/tap; tapping/dragging it also selects whichever clip the playhead
  now sits over.
- **Preview sync**: `VideoPreviewPlayer` now accepts `trimStartMs`/
  `trimEndMs`. The editor derives "which clip is the playhead over" via
  `layoutTimeline`/`positionAt` and feeds that clip's trim range in —
  the preview seeks to `trimStartMs` on load and loops back to it at
  `trimEndMs`, so it always reflects the current (non-destructive) trim.

## Not done yet (rest of Phase 4 / near-term follow-up)

- **Continuous cross-clip playback.** Preview currently loops *within*
  the selected/current clip's trim range; it does not yet auto-advance
  to the next clip and keep playing across a boundary. That's real
  playback-engine work (essentially a mini version of what Phase 8's
  export compositor does) — flagging it explicitly rather than faking
  it.
- **Thumbnail strip continuity while zoomed**: pinch-zoom changes tile
  width but there's no min-thumbnail-count-per-clip logic (a long clip
  at low zoom is still one thumbnail, not a filmstrip) — fine for v1,
  worth revisiting.
- Waveform on the trim handles (audio isn't built yet — Phase 5).
- Tests for `layoutTimeline`, `splitClip`, `reorderClips` — none written
  yet; these are the highest-value first tests once Phase 10 starts.

## Decision needed before continuing

None blocking — Phase 5 (audio) or the rest of Phase 4 (cross-clip
playback) can both start from here. Your call on which to do next.
