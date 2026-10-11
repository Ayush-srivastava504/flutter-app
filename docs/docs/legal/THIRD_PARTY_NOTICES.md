# Third-party notices — ClipForge (TEMPLATE; keep in sync with `docs/DEPENDENCIES.md`)

> Not legal advice. Fill the [BRACKETS]. Show this text (or a link to it) inside the app (e.g. Settings → About → Open-source licences) **and** on your website. Flutter's `showLicensePage` lists Dart/Flutter packages automatically; the native components below must be added by you.

## FFmpeg / FFmpegKit — LGPL-3.0
ClipForge uses **FFmpeg** through the Flutter package `ffmpeg_kit_flutter_new_full` (version 2.5.7, "Full" build without GPL libraries). This software is licensed under the **GNU Lesser General Public License v3.0**. It is used as separate dynamically-linked shared libraries.
- FFmpeg source: https://ffmpeg.org/ (the version bundled in the package — [fill from the package's page])
- FFmpegKit fork source: [repository URL from the package's pub.dev page]
- LGPL-3.0 text: https://www.gnu.org/licenses/lgpl-3.0.html [or include the text file in the app]
- ClipForge does **not** use the GPL-licensed components (x264, x265, …); the app encodes with the Android/iOS hardware H.264 encoder or FFmpeg's `mpeg4` encoder.
[Have a lawyer confirm what notices/source-offer your distribution needs if you monetise.]

## DejaVu fonts — Bitstream Vera licence (+ public-domain DejaVu changes)
Bundled fonts: DejaVu Sans, Sans Mono, Serif, Serif Italic. Full licence text: `assets/fonts/LICENSE-DejaVu.txt`.

## video_thumbnail (patched local copy) — MIT
Copyright (c) 2019 John Zhong. Full text: `third_party/video_thumbnail/LICENSE`.

## Flutter, Dart and pub.dev packages
Listed automatically in the in-app licence page (`showLicensePage`). Main packages: flutter_riverpod, drift, sqlite3_flutter_libs, path_provider, image_picker, file_picker, permission_handler, video_player, just_audio, gal, share_plus, flutter_local_notifications, wakelock_plus, uuid.

## Bundled audio loops — [FILL IN]
`retro_pulse.wav`, `ambient_drift.wav`, `gentle_morning.wav`: [Created by <name> and released with the app / Licensed from <source> under <licence>]. **Do not publish until this line is true** (FACTS F-81).
