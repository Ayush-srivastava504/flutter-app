/// A music file the user picked from device storage, with just enough
/// metadata to attach it to the project as a background `AudioTrack`.
///
/// Mirrors [MediaAsset]'s split between "the source file" and "how it's
/// used on the timeline": this only describes the file itself — trim,
/// offset, and volume live on the `AudioTracks` row once it's attached
/// (see `ProjectDatabase.setAudioTrack`).
class AudioAsset {
  final String uri;
  final Duration duration;
  final String displayName;

  const AudioAsset({
    required this.uri,
    required this.duration,
    required this.displayName,
  });
}
