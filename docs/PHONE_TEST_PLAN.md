# ClipForge — full phone test plan (v13, 2026-11-13)

Phone: Samsung SM-A366E (Android 16). Run: `flutter run -d RZGYC13J23J` (debug first, release at the end).
**Nothing built after v10 has run on a phone yet.** Expect bugs; that's what this is for.

How to report a failure to Claude: `ID · what you did · what you expected · what happened` + screenshot/screen recording.
For export failures: Export screen → **Copy error details** and paste it.

Mark each line: `[x]` pass · `[!]` bug · `[-]` skipped.

---

## Test media to have on the phone first
- [ ] 2–3 normal portrait camera videos (10–30 s, with sound)
- [ ] 1 landscape video
- [ ] 1 long video (≥ 3–5 min) — for AutoCut, scene split, remove silences, export time
- [ ] 1 video of you talking (speech, some pauses) — for Enhance speech / Remove silences / subtitles
- [ ] 1 green-screen or plain-background video — for Remove background
- [ ] 1 screen recording (variable frame rate)
- [ ] 3–5 photos (one 12 MP+, one HEIC if the camera makes them, one portrait of a person)
- [ ] 1–2 MP3/M4A songs in Downloads/Files (one with a clear beat)
- [ ] 1 `.srt` subtitle file
- [ ] Optional junk: a 0-byte / corrupt file renamed `.mp4`

---

## P0 — Blockers (test first; if these fail, stop and send to Claude)
| ID | Steps | Expected |
|---|---|---|
| P0-1 | Install, open app | Opens, no crash, no white/black screen |
| P0-2 | Create project → add 1 video → Export 720p | Finishes; video in Gallery album "ClipForge" plays **with sound** |
| P0-3 | 3 clips + a transition + text + music → Export 1080p | Finishes; text, music and transition are where they were in the preview |
| P0-4 | Close the app (swipe away) and reopen | Project is still there with all edits |
| P0-5 | 🐛 debug icon on Home → Load sample project → Export | Finishes |

---

## A. First run, Home, app shell
| ID | Steps | Expected |
|---|---|---|
| A1 | Fresh install (uninstall first) | Onboarding shows once; Skip and Get started both reach Home; next launch skips it |
| A2 | Watch for permission popups | Note which ones appear and when (media, mic, notifications) |
| A3 | Deny every permission, then try to import | Import still works through the picker, or a clear message — no crash |
| A4 | Rotate phone on Home, in editor, in export | No crash, no yellow/black overflow stripes |
| A5 | Switch phone dark/light mode | Text readable in both |
| A6 | Home: new project, resume card ("Edited …") | Resume card opens the last project |
| A7 | Project ⋮ menu → Rename / Duplicate / Delete | Rename sticks; duplicate edits independently; delete asks first and removes the card |
| A8 | Delete the project the resume card points to | Resume card disappears, no crash |
| A9 | Home: "One video" / "One photo" / "Videos & photos" start options | Each opens the right mode/editor |
| A10 | Templates section → pick a template → "Pick N clips" | Asks for the right number of clips and builds the edit |
| A11 | Audio Studio start + audio projects row on Home | Opens; saved audio projects listed |
| A12 | Android back button / back gesture on every screen | Goes back one screen; no accidental exit losing work |
| A13 | Font size to largest in phone settings | Nothing cut off or overflowing badly |
| A14 | "PRO" label | Note where it shows (there is no paywall — just check it doesn't block anything) |

## B. Import
| ID | Steps | Expected |
|---|---|---|
| B1 | Add portrait video | Tile + thumbnail; correct duration; preview plays |
| B2 | Add landscape video to a 9:16 project | Fit (bars) not stretched |
| B3 | "+" tile → multi-pick 5 items | All added in the picked order |
| B4 | Add 12 MP photo | Shows as a ~3 s clip, no crash/out-of-memory |
| B5 | Add HEIC photo | Works, or clear error — **no crash** |
| B6 | Open picker then cancel | No stuck spinner |
| B7 | Add corrupt / 0-byte file | Clear error, no crash |
| B8 | Add screen recording (VFR) | Plays; exports with audio in sync |
| B9 | Add 10+ clips | UI still smooth; timeline scrolls |
| B10 | "Import from device" for music; "Choose from library" | Both add a music track |

## C. Core editing (timeline)
| ID | Steps | Expected |
|---|---|---|
| C1 | Tap clip → panel opens; tap again → deselects; Done closes | As described |
| C2 | Trim start/end | Preview stays inside trim |
| C3 | Split at playhead, play both halves | Both halves keep volume, filter, look, speed |
| C4 | Split at scene changes (long video) | Splits at real cuts; "can take a while" doesn't freeze the UI |
| C5 | Duplicate clip | Copy appears right after the original |
| C6 | Delete clip (middle) | Others close the gap |
| C7 | Drag to reorder | Order stays after leaving and reopening |
| C8 | Playhead tools: back/forward 1 frame, previous/next clip, move to playhead | Each jumps correctly |
| C9 | Scrub bar drag + pinch/zoom timeline (if any) | Smooth, preview follows |
| C10 | Undo/redo 20 times back and forth (mix of trim, text, filter, delete) | Same result each time, no crash |
| C11 | Kill app mid-edit, reopen | Last edit there |
| C12 | Speed: Slow / Normal / Fast / custom ×  | Preview + export speed match; audio pitch OK |
| C13 | Reverse ("Play it backwards") | Preview and export both reversed |
| C14 | Rotate 90°, Flip horizontal/vertical | Preview + export match |
| C15 | Clip volume / mute | Matches in export |
| C16 | Frame shape / aspect (9:16, 16:9, 1:1 …) | Preview and export same shape |
| C17 | Fit / fill / blurred background (Background panel) | Matches in export |
| C18 | Crop / zoom / pan, Ken Burns on a photo | Matches in export |
| C19 | Photo duration change | Timeline + export length update |
| C20 | Safe-zones overlay toggle | Shows guides, never appears in export |

## D. Look & effects
| ID | Steps | Expected |
|---|---|---|
| D1 | Adjust: brightness / contrast / saturation sliders + reset | Live preview; matches export |
| D2 | Looks gallery (B&W, sepia, vintage, warm, cool, vignette…) | Preview matches export |
| D3 | "Use on every clip" / "Every clip" / "Turn off everywhere" | Applies to all / clears all |
| D4 | Effects panel → Add effects, each effect once | Each previews; each exports (note any that export differently) |
| D5 | Enhance quality | Visible change; exports |
| D6 | Remove background (colour key) on green screen clip | Background gone in preview **and** export; "Remove colour fringe" helps edges |
| D7 | Remove background on a normal (non-green) clip | Note result — expected weak; shouldn't crash |

## E. Transitions (26 of them)
| ID | Steps | Expected |
|---|---|---|
| E1 | Tap the join between 2 clips, cycle through **all 26** transitions | Each previews |
| E2 | Export a project using ~8 different transitions | Export succeeds; each looks like its preview. **Note any that fail** |
| E3 | 3+ transitions in a row (overlapping) | Export succeeds (this was a bug fixed on desktop) |
| E4 | "Use on every cut" | All joins get it |
| E5 | Transition on a very short clip (< 1 s) | No crash; export OK |

## F. Text & subtitles
| ID | Steps | Expected |
|---|---|---|
| F1 | Add text, move, resize, colour | Matches export position/size |
| F2 | Bold, outline, background box | Matches export |
| F3 | Timing strip: change start/end | Text shows only in that range |
| F4 | 3 overlapping texts | All visible, correct order |
| F5 | Delete text, undo | Comes back |
| F6 | Subtitles (.srt) import | Lines appear at right times; export shows them |
| F7 | Speech-to-subtitles / auto captions (if present) | Note accuracy; no crash with no internet |
| F8 | Emoji / Hindi / long text | Renders in preview and export (no boxes ▯) |

## G. Audio in the video editor
| ID | Steps | Expected |
|---|---|---|
| G1 | Add music from bundled library (12 tracks) — play each briefly | All play |
| G2 | Add SFX (16 sounds) | Lane shows them; play at right time |
| G3 | Music volume, trim, offset, fade in/out | Matches export |
| G4 | "Lower music under clip sound" (ducking) | Music dips when clip talks in export |
| G5 | Remove music | Gone from preview and export |
| G6 | Voice-over: Record (mic permission prompt) → stop → play | Recording on its own lane, in sync, in export |
| G7 | Voice-over with mic permission denied | Clear message, no crash |
| G8 | Enhance speech / "Clearer, fuller, more even voice" | Audible change; exports |
| G9 | Remove silences on talking clip | Pauses cut; no clipped words |
| G10 | Loudness for streaming | Export louder/even, no distortion |
| G11 | AutoCut: cut every beat / 2 beats / bar with a beat song | Cuts land on beats; tempo looks sane |
| G12 | Preview playback across several clips with music | Music doesn't jump or restart at each clip |

## H. Photo Studio (One photo mode)
| ID | Steps | Expected |
|---|---|---|
| H1 | Open a photo in Photo editor | Loads fast, no crash on 12 MP |
| H2 | "✨ For this photo" auto enhance | Visible improvement |
| H3 | Adjust, looks, crop/rotate, text on photo | All work |
| H4 | Save to gallery | Saved image matches the screen, full resolution |
| H5 | Share | Share sheet opens with the image |

## I. Audio Studio + Beat composer
| ID | Steps | Expected |
|---|---|---|
| I1 | "Edit an audio file" → open a song | Waveform/player loads |
| I2 | Trim, fades, speed, pitch | Audible, correct |
| I3 | EQ (bass etc.), compressor, denoise, reverb, echo, chorus | Each audible; no crash |
| I4 | 12 voice presets on a voice recording | Each sounds different |
| I5 | "Use the microphone, then add effects" | Records, then effects apply |
| I6 | Save to phone (Music/ClipForge) as MP3, M4A, WAV | Files appear in Files/Music app and play |
| I7 | "Use as music in a video" / "Use as the music of…" | Lands as the music in the chosen project |
| I8 | Delete an audio edit | Asks first, removed |
| I9 | Compose a beat: Major/Minor, melody, bass, tempo | Plays; "Edit the beat" reopens it |
| I10 | Save the beat and use it in a video | Works and exports |

## J. Assistant / smart tools
| ID | Steps | Expected |
|---|---|---|
| J1 | Assistant sheet: type simple commands ("make it black and white", "add fade", "speed up") | Does the right edit, undoable |
| J2 | Nonsense command | Polite "didn't understand", no crash |
| J3 | Auto polish (if offered) | Sensible result |
| J4 | Chapters sheet → "Copy for description" | YouTube-style chapters copied to clipboard |
| J5 | Mode guide / "How it works" sheets | Open, scroll, close |
| J6 | Project options → FCPXML export (if exposed) | File created; no crash |

## K. Export (everything)
| ID | Steps | Expected |
|---|---|---|
| K1 | 480p @ 24 fps | Smaller file, plays |
| K2 | 1080p @ 60 fps | Succeeds or falls back cleanly; note which |
| K3 | 4K (if offered) | Succeeds or clear error |
| K4 | Photo + silent video + video with sound | No audio glitches |
| K5 | Cancel mid-export | Back to idle; no half file in gallery |
| K6 | Lock screen / switch app during a 1-min export | Finishes or clear error |
| K7 | Delete a source video from gallery, then export | "Clip no longer on this device" style message |
| K8 | Notifications denied → export | Still works |
| K9 | Share after export | Share sheet with the MP4 |
| K10 | Reopen export screen | Last quality/fps remembered |
| K11 | Long project (5+ min, many effects) | Note export time + any failure |
| K12 | Export the same project twice | Two files, no overwrite crash |
| K13 | Exported video opened in WhatsApp/Instagram/YouTube upload | Accepted, plays |

## L. Data, upgrade, storage
| ID | Steps | Expected |
|---|---|---|
| L1 | Install new build **over** an old one that has projects | Old projects open and export |
| L2 | Reboot phone, open project | All clips found |
| L3 | Settings → Apps → ClipForge → Clear cache, reopen | Clips still found |
| L4 | Nearly full storage, export | "Not enough storage" message, not a crash |
| L5 | Check app size in Settings → Apps | Note it (audio library adds ~11 MB) |

## M. Performance & stability (the "unnecessary" but useful ones)
| ID | Steps | Expected |
|---|---|---|
| M1 | Use the app 20+ min nonstop | No slowdown, phone not overheating badly |
| M2 | 30 clips in one project | Editor usable |
| M3 | Spam-tap buttons (export twice, double-tap add) | No duplicates/crash |
| M4 | Phone call / alarm during playback and export | Recovers |
| M5 | Airplane mode, use everything | Everything works offline |
| M6 | Split screen / pop-up window | No crash |
| M7 | Battery saver on, export | Works (maybe slower) |
| M8 | Back out of editor during playback | Audio stops |

## N. Release build & store (last)
| ID | Steps | Expected |
|---|---|---|
| N1 | `flutter build apk --release` → install → P0-2 again | Export works in release (R8 didn't break FFmpeg) |
| N2 | Launcher name and icon | "ClipForge", new icon |
| N3 | Settings/About → licences page | FFmpeg LGPL notice present |
| N4 | Signing, target SDK 36, 16 KB check, permissions | See `docs/LAUNCH_CHECKLIST.md` §3 |
