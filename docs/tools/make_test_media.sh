#!/usr/bin/env bash
# Generates a small set of synthetic test clips on your COMPUTER (needs desktop ffmpeg), to copy to the phone's gallery.
# Usage: bash tools/make_test_media.sh [output_dir]     (default: ./test_media)
# Tested with desktop FFmpeg 6.1.1. Real phone-camera clips (HEVC, variable frame rate, HDR) are still needed — see docs/TESTING.md §2.
set -euo pipefail
out="${1:-test_media}"; mkdir -p "$out"
enc="-c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 128k"
# 1. portrait 1080x1920, 10 s, with audio (the "normal phone clip")
ffmpeg -v error -y -f lavfi -i "testsrc2=size=1080x1920:rate=30:duration=10" -f lavfi -i "sine=frequency=440:duration=10" $enc -shortest "$out/01_portrait_1080p_audio.mp4"
# 2. landscape 1920x1080, 8 s, with audio (letterboxing in a 9:16 project)
ffmpeg -v error -y -f lavfi -i "testsrc2=size=1920x1080:rate=30:duration=8" -f lavfi -i "sine=frequency=660:duration=8" $enc -shortest "$out/02_landscape_1080p_audio.mp4"
# 3. landscape 4K, 4 s, no audio stream (silent-clip path)
ffmpeg -v error -y -f lavfi -i "testsrc2=size=3840x2160:rate=30:duration=4" -c:v libx264 -pix_fmt yuv420p -an "$out/03_landscape_4k_noaudio.mp4"
# 4. square 1080x1080, 6 s, 24 fps (odd frame rate -> fps=30 conversion)
ffmpeg -v error -y -f lavfi -i "testsrc2=size=1080x1080:rate=24:duration=6" -f lavfi -i "sine=frequency=550:duration=6" $enc -shortest "$out/04_square_24fps_audio.mp4"
# 5. landscape pixels flagged as rotated 90 degrees in the container (rotation-metadata path)
ffmpeg -v error -y -f lavfi -i "testsrc2=size=1920x1080:rate=30:duration=5" -c:v libx264 -pix_fmt yuv420p -an "$out/_tmp_norot.mp4"
ffmpeg -v error -y -display_rotation 90 -i "$out/_tmp_norot.mp4" -c copy "$out/05_rotated90_metadata.mp4" && rm "$out/_tmp_norot.mp4"
# 6. very short clip (0.8 s) -> tests minimum durations / dissolve clamping
ffmpeg -v error -y -f lavfi -i "testsrc2=size=1080x1920:rate=30:duration=0.8" -f lavfi -i "sine=frequency=330:duration=0.8" $enc -shortest "$out/06_tiny_0p8s.mp4"
# 7. photos
ffmpeg -v error -y -f lavfi -i "testsrc2=size=4000x3000" -frames:v 1 "$out/07_photo_12mp.jpg"
ffmpeg -v error -y -f lavfi -i "testsrc2=size=1080x1920" -frames:v 1 "$out/08_photo_portrait.png"
# 9. audio (music import from files)
ffmpeg -v error -y -f lavfi -i "sine=frequency=262:duration=20" -c:a aac -b:a 128k "$out/09_music_20s.m4a"
ffmpeg -v error -y -f lavfi -i "sine=frequency=392:duration=5" "$out/10_music_5s_short.wav"
ls -l "$out"
