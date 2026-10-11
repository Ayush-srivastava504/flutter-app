# ClipForge — FFmpeg cookbook (tested snippets only)

**What "tested" means here.** Every snippet below was executed on **desktop FFmpeg 6.1.1** (Ubuntu build, which includes libx264) against synthetic `testsrc`/`sine` inputs on 2026-10-11, and produced a non-empty output without errors. That proves the *syntax and filter availability on FFmpeg 6.1.1*.
It does **not** prove: the look is right, it works inside FFmpegKit 2.5.7's FFmpeg build, or it is fast on a phone. The last column says so honestly. Before shipping a feature that uses a snippet, run it on a phone (`docs/TESTING.md`).

Rules for Claude:
1. Only use snippets from this file, or snippets you ran through `tools/verify_export_graph.py` (extend `tools/graph_prototype.py` first), or snippets taken from existing, working code in `export_command_builder.dart`.
2. If a filter is not listed: say "untested", test it with desktop `ffmpeg` if available, and add it here with the date.
3. The phone build has **no libx264**. Never put `libx264`/`libx265` in app code. Encoders in the app: `h264_mediacodec`, `h264_videotoolbox`, `mpeg4` (FACTS F-61).
4. Args are passed to FFmpegKit as a **list** (`executeWithArgumentsAsync`), so there is no shell: do not add shell quoting around the filtergraph; use FFmpeg's own `'single quotes'` only *inside* filter option values, as the builder does.

## 1. The existing export graph (read from `export_command_builder.dart`)
Per clip: `trim → setpts → fps=30 → scale(decrease) → pad → setsar=1 → eq (only if sliders ≠ 0) → format=yuv420p → fade in/out (fade transitions) → settb=AVTB`.
Audio per clip: `atrim → asetpts → aresample=44100 → aformat(fltp, stereo) → volume` (or `anullsrc` for photos/silent clips).
Join: `concat` (cut/fade) or `xfade=transition=fade` + `acrossfade` (dissolve; output shortens by the overlap).
Then: `drawtext` per text overlay → music `atrim/…/adelay` → `amix=inputs=2:duration=first:normalize=0` → `alimiter=limit=0.97`.
Input order: **all clips first, music last** → music is `[<clipCount>:a]`. Any feature that adds an input must change this deliberately and have a test (FEATURE_PLAN §6).

## 2. Snippets (desktop FFmpeg 6.1.1)
Legend — Desktop: ✅ ran OK. Phone: ⚠️ not run on a phone / FFmpegKit build.

| Feature | Snippet (video chain unless stated) | Desktop | Phone | Notes |
|---|---|---|---|---|
| F7 sepia | `colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131:0` | ✅ | ⚠️ | Put after `eq`. |
| F7 black & white | `hue=s=0` | ✅ | ⚠️ | |
| F7 vignette | `vignette` | ✅ | ⚠️ | Default strength; tune after seeing it. |
| F7 cool/warm | `colorbalance=rs=.2:bs=-.2` | ✅ | ⚠️ | Values are an example, tune visually. |
| F7 warm/cool alt. | `colortemperature=temperature=4500` | ✅ | ⚠️ | Filter exists in 6.1.1; **may not exist in an older FFmpegKit build** — prefer `colorbalance` unless proven. |
| F10 rotate 90° | `transpose=1` | ✅ | ⚠️ | Insert **before** scale/pad. Container rotation is auto-applied by FFmpeg already (don't double-rotate; builder header comment). |
| F10 flip | `hflip,vflip` | ✅ | ⚠️ | |
| F11 speed 2× | video `setpts=(PTS-STARTPTS)/2` + audio `atempo=2` | ✅ | ⚠️ | Rendered length = source length / speed. |
| F11 speed 4× | video `setpts=(PTS-STARTPTS)/4` + audio `atempo=2,atempo=2` | ✅ | ⚠️ | Chain `atempo` to reach values outside 0.5–2 (tested 0.25× as `atempo=0.5,atempo=0.5` ✅). |
| F9 music fades | audio `afade=t=in:st=0:d=0.5,afade=t=out:st=2.5:d=0.5` | ✅ | ⚠️ | Fade-out `st` = trimmed length − fade. Put before `adelay`. |
| F14 crop/zoom | `crop=iw/2:ih/2:iw/4:ih/4,scale=320:240` | ✅ | ⚠️ | Crop **before** the existing scale/pad. |
| F14 Ken Burns (photo) | `scale=1280:960,zoompan=z='min(zoom+0.0015,1.5)':d=60:s=320x240:fps=30` | ✅ | ⚠️ | Slow + jittery on small photos; scale source up first; photos only in v1. |
| F15 fill | `scale=W:H:force_original_aspect_ratio=increase,crop=W:H` | ✅ | ⚠️ | |
| F15 blurred background | `split[a][b];[a]scale=W:H:force_original_aspect_ratio=increase,crop=W:H,boxblur=20:2[bg];[b]scale=W:H:force_original_aspect_ratio=decrease[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2` | ✅ | ⚠️ | Heavy: time it; may push export onto the slow fallback encoder. |
| F16 image overlay | `[2:v]scale=100:-1,format=rgba,colorchannelmixer=aa=0.5[img];[0:v][img]overlay=10:10:enable='between(t,0.5,2)'` | ✅ | ⚠️ | Extra `-i` shifts input indexes. Use `-loop 1` for stills. |
| F17 reverse | video `reverse` + audio `areverse` | ✅ | ⚠️ | `reverse` buffers the whole clip in RAM → cap source length (plan says 10 s). |
| F8 text box/outline | `drawtext=…:box=1:boxcolor=black@0.5:boxborderw=8:borderw=2:bordercolor=black` | ✅ | ⚠️ | Tested with the bundled `DejaVuSans.ttf`. |
| F23 keyframe-style expression | `drawtext=…:x='if(lt(t,1),10,if(lt(t,2),10+(t-1)*100,110))'` | ✅ | ⚠️ | Commas inside the quoted expression are fine when the whole filtergraph is one argument. |
| F25 chroma key | `chromakey=color=0x00FF00:similarity=0.15:blend=0.1,format=yuva420p` | ✅ | ⚠️ | Looks not judged (synthetic input). |
| F19 ducking | `[0:a]asplit=2[sc][mix];[1:a][sc]sidechaincompress=threshold=0.05:ratio=8[duck];[duck][mix]amix=inputs=2:normalize=0` | ✅ | ⚠️ | Tested with two sine inputs (a first attempt with a malformed graph of mine failed; this version passed). Threshold/ratio untuned. |
| F5 60 fps | `fps=60` | ✅ | ⚠️ | Also change `-r` and the `-framerate` for photos. Hardware encoder at 1080p60 may fail on weak phones → fallback. |
| F13 transitions | `xfade=transition=<name>` for `slideleft`, `wipeleft`, `circleopen`, `zoomin`, `fadeblack`, `dissolve` | ✅ all 6 | ⚠️ | Existing code uses `transition=fade`. Unknown names must fall back to `fade` (never fail the export). |

## 3. Known export limits (from code, FACTS §6)
- Text alignment is ignored in export (always centred on `positionX`).
- Text font size is scaled by `outputWidth / 360` (`previewReferenceWidth`).
- A dissolve shortens the timeline; text/music times are remapped with `_Timeline.remap`.
- `fade` is a dip-to-black on both sides of the cut, timeline length unchanged.
- HEIC photos often cannot be decoded by FFmpeg → `unsupportedCodec` failure message.

## 4. How to add a snippet to this file
1. Run it with desktop `ffmpeg` on synthetic inputs (as above), or through `tools/verify_export_graph.py`.
2. Add a row with the date, FFmpeg version, and what was *not* proven.
3. After it has run on a phone, change the Phone column to ✅ with the device + Android version.
