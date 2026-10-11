#!/usr/bin/env bash
# ClipForge dev helper. macOS / Linux / WSL / Git-Bash.  Usage: scripts/dev.sh <command>
#
#   run     Debug-run on a connected ARM phone, ARM64 only (much faster than the default,
#           which builds FFmpegKit's native libraries for 4-5 CPU architectures).
#   emu     Same, but for an x86_64 emulator.
#   check   flutter analyze + flutter test  (seconds, no phone needed). Run before every commit.
#   gen     Regenerate Drift code (*.g.dart) once. Needed after editing tables in project_database.dart.
#   watch   Same as gen, but keeps running and regenerates on save.
#   graph   Render the export filter graph through the real ffmpeg on this computer (needs ffmpeg + python3).
#   logs    Show only the export logs from a connected Android phone.
#   clean   Last resort when builds act haunted (slow next build).
set -euo pipefail
cd "$(dirname "$0")/.."

case "${1:-help}" in
  run)   flutter run --target-platform android-arm64 ;;
  emu)   flutter run --target-platform android-x64 ;;
  check) flutter analyze && flutter test ;;
  gen)   dart run build_runner build --delete-conflicting-outputs ;;
  watch) dart run build_runner watch --delete-conflicting-outputs ;;
  graph) python3 tools/verify_export_graph.py ;;
  logs)  adb logcat -c; adb logcat | grep --line-buffered -i -E "flutter.*\[export\]|ffmpeg" ;;
  clean) flutter clean && flutter pub get ;;
  *)     sed -n '2,13p' "$0" ;;
esac
