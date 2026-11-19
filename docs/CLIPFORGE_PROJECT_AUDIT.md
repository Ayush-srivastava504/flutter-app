# ClipForge — Project audit (2026-11-17/18)

Scope: structure, features, dependencies, Android configuration, and gaps, verified by reading the code and running the tools listed. Device results are in the other reports in `docs/`.

## 1. Stack
| Item | Value (verified) |
|---|---|
| Framework | Flutter 3.47.2 (stable, 2026-08-26), Dart ≥3.3 |
| State | Riverpod 2 (`flutter_riverpod ^2.5.1`) |
| Storage | Drift/SQLite, `schemaVersion` 13 (`lib/data/project_database.dart:306`) |
| Media engine | `ffmpeg_kit_flutter_new_full` 2.5.7 (non-GPL: no libx264; encoders tried in order: `h264_mediacodec` high → `h264_mediacodec` default → `mpeg4`) |
| Preview | `video_player`, `just_audio`, fragment shaders (`shaders/look.frag`, `adjust.frag`, `key.frag`) |
| Code size | 24,139 lines of Dart in `lib/` (excluding `*.g.dart`) |
| Tests | 42 unit/widget test files; 460 tests pass (2026-11-18). Integration tests: `integration_test/templates_test.dart`, `integration_test/looks_effects_test.dart` |

## 2. Screens (`lib/router/app_router.dart`)
| Route | Screen | Lines |
|---|---|---|
| `/` | Home: mode cards, Discover templates, projects, photo/audio entry, banner ad | 784 |
| `/editor` | Video editor: preview, timeline, tool dock, panels | 1356 |
| `/export` | Export: resolution (720p/1080p/4K), fps (24/30/60), enhance, FCPXML | 315 |
| `/photo` | Photo editor: Auto, Crop, Looks, Tune, undo/redo, save/share | 510 |
| `/audio` | Audio studio | 854 |
| `/compose` | Beat composer | 428 |
| `/settings` | AI keys, account, privacy, licences | 490 |

## 3. Feature inventory
- **Templates (Discover):** 20 templates, 10 categories, 4 tabs (`lib/models/video_template.dart`). Templates are pure data; a template builds a normal, editable project (`TemplateService.create`). Cards are drawn in code (gradient + storyboard); **there are no thumbnail images, no preview videos, no search and no filters** — those checklist items do not apply.
- **Video editor:** import (system picker), timeline, trim, split, duplicate, reorder, delete, speed, rotate/flip, crop/fit, background for letterboxed clips, 26 transitions, 33 looks (filters), 16 effects (6 motion, 8 stylise, 2 glow), chroma key, text overlays (fonts, box, outline, timing), SRT import, music library + SFX, voice-over, ducking, auto-cut (silence/beat), YouTube chapters, AI assistant (on-device rules), AI image/video generation (user's own key), undo/redo, safe-zone guides, modes (Quick/Insta/YouTube).
- **Photo editor:** auto-enhance, crop, looks, 16 tune sliders, undo/redo, save/share.
- **Audio studio / composer:** audio editing and a beat composer.
- **Export:** single FFmpeg command, hardware H.264 with fallback, progress, cancel, gallery save (`gal`), share, FCPXML.
- **Added 2026-11-18:** AdMob (Home banner, rewarded ad for a 4K export, UMP consent), optional Google sign-in with in-app account deletion.
- **Not present:** subscriptions / in-app purchases / premium entitlements (the "PRO" badge marks YouTube mode only); cloud sync; stickers as a separate feature.

## 4. Android configuration
| Item | Value |
|---|---|
| applicationId | `com.ayushstudio.clipforge` |
| minSdk / target | max(24, Flutter default) / Flutter default |
| Version | `0.1.0` (pubspec has no `+build`, so versionCode = 1) |
| Release signing | **Was the debug key.** Now an upload keystore (`android/app/upload-keystore.jks`, `android/key.properties`, both gitignored); falls back to debug with a warning if missing. |
| Shrinking | Flutter default R8 for release; FFmpegKit ships consumer keep rules |
| Permissions | READ_MEDIA_VIDEO/IMAGES/AUDIO, READ/WRITE_EXTERNAL_STORAGE (old APIs), RECORD_AUDIO, POST_NOTIFICATIONS, INTERNET; AdMob merges AD_ID + network state |
| Firebase | Optional: plugins applied only when `android/app/google-services.json` exists (it does not yet) |

## 5. Issues found in the audit
| # | Severity | Issue | Status |
|---|---|---|---|
| A1 | Critical (release) | Release builds signed with the debug key | Fixed: upload keystore |
| A2 | Critical (release) | `build.gradle.kts` used `java.util.Properties` inside `android {}` → script compile error | Fixed (import) |
| A3 | High | Cancelled/failed export left a partial MP4 in cache (up to a day) | Fixed + 3 unit tests |
| A4 | High (security) | A Firebase **Admin SDK** service-account key exists on the dev PC (Downloads) | Not in repo or git history (searched); must never be bundled; rotate if it was ever shared |
| A5 | Medium | Docs claimed "offline, no analytics/ads" | Fixed: FACTS F-30..F-32, CLAUDE.md, privacy policy |
| A6 | Info | Release build downloads NDK r27 on first run; Gradle daemon was killed under memory pressure (8 GB PC) | Run builds one at a time |

Open owner decisions from the 2026-11-13 phone test still stand (`docs/PHONE_TEST_RESULTS_2026-11-13.md`).
