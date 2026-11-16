# ClipForge — instructions for Claude (read this first, every session)

ClipForge is a CapCut-style **Flutter mobile video editor** (Android first; package `com.ayushstudio.clipforge`).
Projects live in a local SQLite database (Drift); export is one FFmpeg command run through FFmpegKit.
The app is **offline** (no network code, no analytics, no ads — see `docs/FACTS.md` F-30..F-32).

## 0. Session protocol (do this before writing code)
1. Read this file, then `docs/FACTS.md` (verified facts + known bugs + things nobody has verified).
2. Read the docs for the *kind* of work (table in section 6).
3. Say in 2–3 lines what you will change and which docs/facts it touches. Then build.
4. Finish with the **Final report** (section 5). No report = not done.

## 1. Anti-hallucination rules (hard rules)
- **Facts beat memory.** If a statement is in `docs/FACTS.md` or `docs/DEPENDENCIES.md`, trust it over your training data. If you need a fact that is in neither file, either read the code/lockfile or say "unverified" — never guess.
- **Package APIs:** use only the versions in `pubspec.lock` (table in `docs/DEPENDENCIES.md`). Before using an API you are not 100% sure exists in that version, open the package source (`~/.pub-cache/hosted/pub.dev/<pkg>-<version>/lib/`) or search pub.dev. Do **not** write Riverpod 3, Drift 3, or `ffmpeg_kit_flutter` (the retired original) syntax.
- **FFmpeg:** only use filters/options that are in `docs/FFMPEG_COOKBOOK.md` or that you have run through `tools/verify_export_graph.py`. The phone build has **no libx264**; the fallback encoder is `mpeg4`.
- **Never claim something works unless you ran it.** You usually cannot run Flutter or a phone. Say exactly which commands you ran and which you could not (e.g. "`flutter test` not run: no SDK in this environment").
- **No invented files, tables, columns or functions.** Before referencing one, `grep` for it.
- **Never edit `*.g.dart`.** Change `lib/data/project_database.dart`, then run `scripts/dev.sh gen`.
- **No new dependency** without asking the owner (APK size, licence, 16 KB-page support all matter — `docs/LAUNCH_CHECKLIST.md`).
- **Do not "fix" things outside the requested scope.** If you notice a bug, add it to the final report under "Noticed, not changed".

## 2. Non-negotiable architecture rules
- The **database is the source of truth**; widgets read streams, they do not hold clip lists.
- **Non-destructive editing:** original media is never modified; edits are metadata.
- **Preview ≠ export.** Anything that changes how video/audio looks or sounds must be built in both the Flutter preview *and* the FFmpeg export, and mirrored in `tools/graph_prototype.py`. Say in one line what differs between them.
- **Duration maths lives in 5 places** (timeline layout, `exportClipsFrom`, `_boundaryAfter`, `exportDurationMs`, text/music remap). A feature that changes clip length updates all five.
- **Schema change = bump `schemaVersion`, write the `onUpgrade` step, add a migration test, run `gen`.** A new table must also be added to `ProjectSnapshot` + `restoreProject`, or undo/redo will silently ignore it.
- Keep logic in **pure functions** with unit tests; keep FFmpeg **execution** confined to `lib/export/export_engine.dart` (read-only FFprobe probing also lives in `lib/services/media_metadata_service.dart` and `audio_metadata_service.dart`).

## 3. Performance rules (details: `docs/PERFORMANCE.md`)
- Never `ref.watch(playheadMsProvider)` in a large widget; put it in a small leaf `Consumer`.
- No per-frame/per-tick database writes; no `await` loops of single-row updates when a batch/transaction works.
- Decode images with `cacheWidth`/`cacheHeight`; dispose every controller/player/subscription/timer.
- Any feature that adds an FFmpeg filter must state its expected cost and be timed on a real phone (protocol in `docs/PERFORMANCE.md` §5).

## 4. Commands
| Command | Purpose |
|---|---|
| `scripts/dev.sh check` | `flutter analyze && flutter test` — must be green |
| `scripts/dev.sh gen` | regenerate Drift code after table edits |
| `scripts/dev.sh graph` | render the Python copy of the export graph through real FFmpeg |
| `scripts/dev.sh run` | debug run on a connected arm64 phone |
| `bash tools/check_16kb.sh <file.aab>` | Play 16 KB page-size check on a built bundle |

## 5. Final report (copy this template at the end of every session)
```
Feature/Task:
Files changed:            (every file, one line each)
Schema version:           (old → new, or "unchanged")
Preview does: …  / Export does: …   (or "UI-only")
Commands run + result:    (exact; say "not run" when not run)
NOT verified (test on phone): (bullet list — be specific)
Docs updated:             (FACTS.md / DEPENDENCIES.md / COOKBOOK / PERFORMANCE — or "none needed")
Noticed, not changed:
```

## 6. Doc index — what to read for what
| Doc | Read when |
|---|---|
| `docs/FACTS.md` | **always** — verified facts, known bugs, unknowns |
| `docs/APP_GUIDE.md` | architecture, data model, flows, feature recipe (§10) |
| `docs/MASTER_PLAN.md` | the big picture: Photo + Video Studio phases, IDs (P*, V*, X*), owner decisions D1–D7, phone FFmpeg capability map |
| `docs/FEATURE_PLAN_25.md` | building feature F1…F25 (one feature = one session) |
| `docs/DEPENDENCIES.md` | before using any package API or adding a package |
| `docs/FFMPEG_COOKBOOK.md` | any export/filter change |
| `docs/PERFORMANCE.md` | any change to editor screen, preview, history, export, assets, startup |
| `docs/TESTING.md` | writing tests; the manual test matrix |
| `docs/LAUNCH_CHECKLIST.md` | release builds, Play Console, permissions, signing |
| `docs/legal/` | privacy policy, third-party notices |
| `docs/history/` | old phase notes — **context only, may be stale; `FACTS.md` wins** |

## 7. Keeping docs true
If your change makes a line in `docs/FACTS.md`, `docs/DEPENDENCIES.md` or `docs/FFMPEG_COOKBOOK.md` false, fix that line **in the same change** and add the date. Stale docs are how hallucinations start.
