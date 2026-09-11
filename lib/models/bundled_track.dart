/// One entry in the small bundled royalty-free music library (Phase 5,
/// second half — the rest of item 1, which the first pass deliberately
/// left out rather than stub with fake/silent files; see
/// PHASE_5_PROGRESS.md).
///
/// [assetPath] points into `assets/audio/` (declared in `pubspec.yaml`);
/// [durationMs] is hardcoded rather than probed because these are fixed
/// files shipped with the app, not user-picked ones — no need to spend
/// an FFprobeKit round trip on something that never changes. If a track
/// is ever added or re-encoded, update the duration here to match.
class BundledTrack {
  final String id;
  final String title;
  final String assetPath;
  final int durationMs;

  const BundledTrack({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.durationMs,
  });
}

/// The bundled library. Three short, simple instrumental loops covering
/// different moods, generated in-house for this project (so they're
/// unambiguously royalty-free — no third-party licensing to track).
const List<BundledTrack> bundledAudioLibrary = [
  BundledTrack(
    id: 'gentle_morning',
    title: 'Gentle Morning',
    assetPath: 'assets/audio/gentle_morning.wav',
    durationMs: 12000,
  ),
  BundledTrack(
    id: 'retro_pulse',
    title: 'Retro Pulse',
    assetPath: 'assets/audio/retro_pulse.wav',
    durationMs: 10000,
  ),
  BundledTrack(
    id: 'ambient_drift',
    title: 'Ambient Drift',
    assetPath: 'assets/audio/ambient_drift.wav',
    durationMs: 14000,
  ),
];
