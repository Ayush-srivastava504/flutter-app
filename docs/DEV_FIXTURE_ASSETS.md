# Dev fixture assets (P2)

Used only by `lib/services/sample_project_service.dart`, behind the
`kDebugMode`-gated "Load sample project" button on Home
(`home_screen.dart`). Never reachable in a release build, but these
files still ship inside every build (pubspec assets aren't
build-mode-conditional) — keep them tiny.

Synthetic test patterns, generated in-house with `ffmpeg`'s `lavfi`
sources — no footage of anyone/anything, no licence question.

| File | What | Regenerate with |
|---|---|---|
| `sample_clip_1.mp4` | 1.5 s, 360×640, h264/yuv420p test pattern | `ffmpeg -f lavfi -i "testsrc2=size=360x640:rate=24:duration=1.5" -c:v libx264 -preset veryslow -crf 34 -pix_fmt yuv420p -movflags +faststart sample_clip_1.mp4` |
| `sample_clip_2.mp4` | 1.5 s, 360×640, h264/yuv420p gradient pattern | `ffmpeg -f lavfi -i "gradients=size=360x640:rate=24:duration=1.5" -c:v libx264 -preset veryslow -crf 34 -pix_fmt yuv420p -movflags +faststart sample_clip_2.mp4` |
| `sample_photo.jpg` | 540×960 JPEG gradient still | `ffmpeg -f lavfi -i "gradients=size=540x960:rate=1" -frames:v 1 -q:v 7 sample_photo.jpg` |

If you regenerate either clip, re-check its duration (`ffprobe -show_entries format=duration clip.mp4`)
against the hardcoded `_clip1DurationMs`/`_clip2DurationMs` constants in
`sample_project_service.dart` — they're not probed at runtime, same
reasoning as `BundledTrack.durationMs`.

Encoded with desktop `ffmpeg`'s `libx264` (this repo's phone build has
no GPL encoder — see `docs/FACTS.md` F-61/F-83) purely to *produce*
these fixture files; H.264 **decode** is a standard Android/iOS
capability either way, so that doesn't affect playing them back on
device.
