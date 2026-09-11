# Phase 5 Progress — Audio

Phase 5 is now feature-complete against the spec. This file originally
tracked a deliberate first-half checkpoint (see "First pass (checkpoint)"
below); this pass finishes the rest — item 1's bundled library, item 3's
per-clip volume, and the piece that made the first checkpoint's controls
inert: actually mixing the music and per-clip volume/mute into preview
playback.

## Built (this pass)

- **Bundled royalty-free library** (rest of item 1): three short
  instrumental loops generated in-house for this project — `Gentle
  Morning` (soft arpeggio, 12s), `Retro Pulse` (upbeat pulse, 10s),
  `Ambient Drift` (slow pad, 14s) — under `assets/audio/`, declared in
  `pubspec.yaml`. Deliberately not silent/fake stubs: they're real,
  audible, and unambiguously royalty-free since nothing third-party was
  pulled in. `lib/models/bundled_track.dart` holds the small catalog
  (id, title, asset path, hardcoded duration — no need to FFprobe a file
  that's shipped fixed with the app). `AudioImportService.pickFromLibrary`
  copies the chosen asset out of the bundle into a real file under app
  storage (`getApplicationDocumentsDirectory()/bundled_audio/`, copied
  once and reused) so `AudioTracks.sourceUri` stays "a real file path"
  for every track regardless of where it came from — same assumption
  `just_audio` and the eventual FFmpeg export pipeline already make.
  `EditorScreen._showAudioImportSheet` now offers "Import from device"
  or "Choose from library" instead of jumping straight to the file
  picker; the library sheet lists the catalog with durations.
- **Original clip audio volume** (rest of item 3): `Clips` gained a
  `volume` column (schema v2 → v3, migration added), same 0.0–1.0 range
  and default (1.0) as `AudioTracks.volume`. `TrimPanel` gained a slider
  next to the existing mute button — dimmed but still draggable while
  muted, since mute (`Clips.muted`) is a separate hard override and the
  level set here is exactly what comes back on unmute, not reset to
  full.
- **Actually hearing all of this during playback** (the biggest
  remaining piece from the checkpoint): `VideoPreviewPlayer` now takes
  `clipVolume`/`muted` (applied via the `video_player` controller's own
  `setVolume`) and an optional `audioTrack` + `timelineStartMs`. Chose
  **`just_audio`** over `audioplayers` for the music engine — its
  position/seek API is precise enough to keep a second player in step
  with the video controller's playhead, which is the crux of this
  piece. On each `video_player` position tick, `_syncMusic` maps the
  controller's local position through `trimStartMs` and
  `timelineStartMs` onto the overall timeline, then onto the music
  file's own position via `AudioTracks.offsetMs`/`trimStartMs`/
  `trimEndMs`; it plays/pauses/reseeks the `just_audio` player to match,
  going silent for any part of the timeline outside the music's aligned
  window. `AudioTracks.volume` is applied directly to the `just_audio`
  player. Editing trim/offset/volume in `AudioTrackPanel` while
  previewing forces an immediate resync rather than waiting for drift to
  cross the tolerance, so dragging a handle is audible right away.

## Known scope boundary (not a gap in item 1–4, called out for clarity)

`VideoPreviewPlayer` still previews **one clip at a time** — trim-looping
within that clip's own range, same as Phase 4 left it. The music-sync
logic above rides on top of that: it keeps the music in step with the
timeline *while the currently-open clip plays*, but doesn't follow the
playhead across a clip boundary onto the next clip, because nothing in
the app does that yet. Making the whole timeline (video + per-clip audio
+ music) play back continuously end-to-end is the same standing gap
`PHASE_4_PROGRESS.md` already flagged for video alone — this pass
doesn't take it on, since it's a preview-architecture change, not
something specific to audio. All four Phase 5 spec items are otherwise
fully built and audible within that scope.

## Not done (unchanged from the checkpoint, still fair to leave for later)

- **Waveform rendering** on the trim handles in `AudioTrackPanel` — same
  "not done" note Phase 4 left for video thumbnails' trim handles.
- **Tests** — still none anywhere in the project. `splitClip`,
  `reorderClips`, `setAudioTrack`, the v2→v3 migration, and now
  `_syncMusic`'s offset/trim/timeline math are all candidates.
- **Continuous cross-clip playback** — see above; tracked as a
  preview-architecture gap, not a Phase 5 item.

## First pass (checkpoint) — original notes, kept for history

<details>
<summary>What the first pass built and deliberately left open</summary>

This pass covered items 1 (partially), 2, and 4, plus half of item 3.
It stopped short of finishing so there was a clean, reviewable
checkpoint rather than a rushed full pass.

- **Data layer**: `AudioTracks` gained a `durationMs` column (schema
  v1 → v2). A project has at most one music track for now — multi-track
  layering is a later extension, still not implemented.
- **Import from device storage** (item 1, half): `AudioImportService`
  used `file_picker`'s built-in `FileType.audio` filter. Duration probed
  via `AudioMetadataService` (FFprobeKit).
- **Trim + align against the timeline** (item 2): `AudioTrackPanel` —
  drag handles over the source file's full duration, plus a second strip
  where dragging the whole block slides `offsetMs` against the video
  timeline's total length.
- **Music volume** (item 3, half): a slider in `AudioTrackPanel` writing
  to `AudioTracks.volume`.
- **Mute/unmute original clip audio** (item 4, complete): `TrimPanel`
  gained a mute toggle writing to `Clips.muted`.
- Left open: the bundled library, per-clip continuous volume, and
  actually mixing any of it into playback — all finished in this pass,
  see above.

</details>
