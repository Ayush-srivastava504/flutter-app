import 'dart:async' show unawaited;
import 'dart:io';
import 'dart:ui' as ui show Clip, ImageFilter;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../data/project_database.dart';
import '../models/fit_mode_x.dart';
import '../models/media_asset.dart';
import '../models/look_x.dart' show ScaledLook;
import '../models/chroma_key.dart';
import 'chroma_keyed.dart';
import 'look_filtered.dart';

/// Full-screen-ish preview of a single [MediaAsset].
///
/// Phase 3 scope was one clip, play/pause, a scrub bar tied to that
/// clip's own duration. Phase 4 adds [trimStartMs]/[trimEndMs]: when
/// set, playback is clamped to that range within the source file — the
/// controller seeks to [trimStartMs] on load and loops back to it once
/// playback reaches [trimEndMs], so the preview always reflects what the
/// timeline's non-destructive trim currently says, never the full
/// source. (Auto-advancing to the *next* clip across a boundary during
/// continuous playback is intentionally out of scope here — see
/// PHASE_4_PROGRESS.md.)
///
/// Phase 5 (second half) adds the audio mix: [clipVolume]/[muted] set
/// this clip's own audio level via `video_player`'s controller volume,
/// and — when [audioTrack] is attached — a `just_audio` player runs
/// alongside it, kept in step with the video controller's playhead
/// (mapped through [timelineStartMs] into the audio track's
/// offset/trim) so the background music plays in sync with whatever
/// part of the timeline is on screen. This still previews one clip at a
/// time — like the trim-loop behavior above, it doesn't follow the
/// playhead across a clip boundary onto the *next* clip, so the music
/// only stays in sync within the clip currently open here. Continuous
/// cross-clip playback (video or audio) is the same standing gap
/// PHASE_4_PROGRESS.md already flagged, not something this pass takes
/// on. See PHASE_5_PROGRESS.md for the rest of this design.
///
/// Phase 6 adds two small outward-facing hooks rather than new
/// playback behavior: [onPositionTick] reports this clip's position
/// mapped onto the timeline (same mapping [_syncMusic] already used
/// internally for the music track) so `EditorScreen` can keep
/// `playheadMsProvider` advancing during live playback — previously
/// only the scrub bar ever wrote to it, so `TextOverlayLayer` (and
/// anything else reading the playhead) froze the moment you pressed
/// play. [onAspectRatioKnown] reports the decoded video's aspect ratio
/// once known, so overlay positions can be mapped onto the actual
/// letterboxed frame instead of the full preview canvas. Both are
/// no-ops (null) by default.
///
/// Phase 7 (first half) adds [brightness]/[contrast]/[saturation]: a
/// live `ColorFiltered` wrap driven by `models/color_filter_x.dart`'s
/// pure matrix math, so a slider drag or preset tap in `FilterPanel`
/// shows up on this same preview immediately — no separate "preview
/// render" step. Applies to the photo branch too, not just video.
/// Baking the filter into the actual exported frames is Phase 8 work
/// (the export pipeline doesn't exist yet); this only ever affects
/// what's drawn on screen here.
class VideoPreviewPlayer extends StatefulWidget {
  final MediaAsset asset;
  final int? trimStartMs;
  final int? trimEndMs;

  /// Live color-adjustment values, each in [-1.0, 1.0] with 0 ==
  /// unchanged — same semantics/range as the `Clips` columns they're
  /// normally read from. See the class doc comment above.
  final double brightness;
  final double contrast;
  final double saturation;

  /// F7: which named look (see `models/look_x.dart`) is layered on top
  /// of [brightness]/[contrast]/[saturation], or null for none.
  final String? look;

  /// How strongly [look] is applied, 0..1.
  final double lookStrength;

  /// Before/after divider position (0..1), or null when not comparing.
  final double? compareSplit;

  /// F10: quarter-turns clockwise (0–3) plus horizontal/vertical flip,
  /// applied on top of whatever `video_player` already auto-rotates
  /// from the file's own container metadata — this is a separate,
  /// deliberate user edit, not a second application of that metadata.
  final int turns;
  final bool flipH;
  final bool flipV;

  /// F11: constant playback speed, 1.0 = unchanged. No-op for photos
  /// (nothing to speed up) — see `Clips.speed`'s doc comment for why
  /// this is scoped to 0.5–2.0.
  final double speed;

  /// F15: 'fit' | 'fill' | 'blur' (`models/fit_mode_x.dart`). `blur`
  /// previews as `fit`; only the export renders the blurred background.
  final String fitMode;

  /// This clip's own audio level (0.0–1.0), applied whenever [muted] is
  /// false.
  final double clipVolume;

  /// Hard override for this clip's own audio, independent of
  /// [clipVolume] — flipping it back off doesn't lose the level.
  final bool muted;

  /// The project's background-music track, or null if none is attached.
  final AudioTrack? audioTrack;

  /// v11: voice-overs on the timeline, played in sync like [audioTrack].
  /// The preview plays them as recorded; "enhance" is heard in the export.
  final List<VoiceOver> voiceOvers;

  /// v11: a stylise effect (`effectStyle`), drawn after the look — same
  /// order as the export. Motion effects are applied by the editor around
  /// this widget.
  final ScaledLook? effectStyle;

  /// v12: background removal, drawn on the framed clip before the look —
  /// same order as the export.
  final ChromaKeySpec? chromaKey;

  /// Where this clip sits on the overall (trimmed) video timeline, in
  /// ms — i.e. `TimelinePosition.startMs` for this clip. Needed to map
  /// the video controller's *local* playback position into the *timeline*
  /// position that [audioTrack]'s offset/trim are expressed in.
  final int timelineStartMs;

  /// Called on every controller position tick with this clip's current
  /// position mapped onto the overall timeline (same units/origin as
  /// `playheadMsProvider`). Lets a caller keep that provider advancing
  /// during live playback instead of only on scrub. See the class doc
  /// comment for why this exists.
  final ValueChanged<int>? onPositionTick;

  /// Called once this clip's video has decoded enough to report its
  /// aspect ratio (width / height). Not called for photos.
  final ValueChanged<double>? onAspectRatioKnown;

  const VideoPreviewPlayer({
    super.key,
    required this.asset,
    this.trimStartMs,
    this.trimEndMs,
    this.clipVolume = 1.0,
    this.muted = false,
    this.audioTrack,
    this.voiceOvers = const [],
    this.effectStyle,
    this.chromaKey,
    this.timelineStartMs = 0,
    this.onPositionTick,
    this.onAspectRatioKnown,
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.look,
    this.lookStrength = 1.0,
    this.compareSplit,
    this.turns = 0,
    this.flipH = false,
    this.flipV = false,
    this.speed = 1.0,
    this.fitMode = fitModeFit,
  });

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  VideoPlayerController? _controller;
  AudioPlayer? _musicPlayer;
  final Map<String, AudioPlayer> _voicePlayers = {};
  bool _isReady = false;
  bool _hasError = false;

  /// How far the music player's position is allowed to drift from where
  /// it "should" be (per the video playhead) before we bother reseeking
  /// it. `video_player`'s position listener doesn't fire every frame, so
  /// some slack avoids constantly re-seeking on tiny, harmless gaps.
  static const int _syncToleranceMs = 180;

  /// Source-file offset from the trim start -> offset on the timeline.
  /// At 2x a clip covers its source twice as fast, so 1000 ms of source is
  /// 500 ms of timeline (F11). Must match `ClipTiming.sourceToTimelineOffsetMs`.
  int _toTimelineMs(int sourceOffsetMs) {
    final s = widget.speed <= 0 ? 1.0 : widget.speed;
    return s == 1.0 ? sourceOffsetMs : (sourceOffsetMs / s).round();
  }

  double get _effectiveClipVolume =>
      widget.muted ? 0.0 : widget.clipVolume.clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _setUp();
  }

  @override
  void didUpdateWidget(VideoPreviewPlayer old) {
    super.didUpdateWidget(old);
    if (old.asset.uri != widget.asset.uri) {
      _controller?.removeListener(_onControllerTick);
      _controller?.dispose();
      _controller = null;
      _isReady = false;
      _hasError = false;
      _disposeMusic();
      _disposeVoices();
      _setUp();
      return;
    }

    String files(List<VoiceOver> l) => l.map((v) => '${v.id}|${v.sourceUri}').join(',');
    if (files(old.voiceOvers) != files(widget.voiceOvers)) {
      _setUpVoices();
    } else if (!listEquals(old.voiceOvers, widget.voiceOvers) || old.timelineStartMs != widget.timelineStartMs) {
      _syncVoices(force: true);
    }

    if (old.trimStartMs != widget.trimStartMs ||
        old.trimEndMs != widget.trimEndMs) {
      // Same source, new trim points (user dragged a handle) — reseek if
      // playback has drifted outside the new range.
      _enforceTrimBounds();
    }

    if (old.muted != widget.muted || old.clipVolume != widget.clipVolume) {
      _controller?.setVolume(_effectiveClipVolume);
    }

    if (old.speed != widget.speed) {
      _controller?.setPlaybackSpeed(widget.speed);
    }

    final oldTrack = old.audioTrack;
    final newTrack = widget.audioTrack;
    if (oldTrack?.sourceUri != newTrack?.sourceUri) {
      // Track attached, removed, or swapped for a different file —
      // (re)build the player from scratch.
      _setUpMusic();
    } else if (oldTrack != null && newTrack != null) {
      if (oldTrack.volume != newTrack.volume) {
        _musicPlayer?.setVolume(newTrack.volume.clamp(0.0, 1.0));
      }
      if (oldTrack.trimStartMs != newTrack.trimStartMs ||
          oldTrack.trimEndMs != newTrack.trimEndMs ||
          oldTrack.offsetMs != newTrack.offsetMs ||
          old.timelineStartMs != widget.timelineStartMs) {
        // Trim/align edited, or this clip's timeline position shifted
        // (e.g. an earlier clip was trimmed/deleted) — force a reseek
        // rather than waiting for drift to cross the tolerance.
        _syncMusic(force: true);
      }
    }
  }

  Future<void> _setUp() async {
    if (!widget.asset.isVideo) return; // photos have nothing to init
    final controller = VideoPlayerController.file(File(widget.asset.uri));
    _controller = controller;
    try {
      await controller.initialize();
      if (widget.trimStartMs != null) {
        await controller.seekTo(Duration(milliseconds: widget.trimStartMs!));
      }
      await controller.setVolume(_effectiveClipVolume);
      await controller.setPlaybackSpeed(widget.speed);
      controller.addListener(_onControllerTick);
      if (!mounted) return;
      setState(() => _isReady = true);
      widget.onAspectRatioKnown?.call(controller.value.aspectRatio);
      unawaited(_setUpMusic());
      unawaited(_setUpVoices());
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  /// Builds (or rebuilds) the background-music player for
  /// [VideoPreviewPlayer.audioTrack]. A no-op with the old player torn
  /// down if there's no track attached.
  Future<void> _setUpMusic() async {
    _disposeMusic();
    final track = widget.audioTrack;
    if (track == null) return;

    final player = AudioPlayer();
    try {
      await player.setFilePath(track.sourceUri);
      await player.setVolume(track.volume.clamp(0.0, 1.0));
      if (!mounted) {
        await player.dispose();
        return;
      }
      _musicPlayer = player;
      _syncMusic(force: true);
    } catch (_) {
      // A missing/corrupt music file shouldn't block the video preview
      // — the clip still plays silently-on-the-music-side; the broken
      // file surfaces when the user opens AudioTrackPanel instead.
      await player.dispose();
    }
  }

  void _disposeMusic() {
    _musicPlayer?.dispose();
    _musicPlayer = null;
  }

  Future<void> _setUpVoices() async {
    _disposeVoices();
    for (final v in widget.voiceOvers) {
      final player = AudioPlayer();
      try {
        await player.setFilePath(v.sourceUri);
        if (!mounted) {
          await player.dispose();
          return;
        }
        _voicePlayers[v.id] = player;
      } catch (_) {
        await player.dispose(); // a missing file just stays silent here
      }
    }
    _syncVoices(force: true);
  }

  void _disposeVoices() {
    for (final p in _voicePlayers.values) {
      p.dispose();
    }
    _voicePlayers.clear();
  }

  /// Same timeline mapping as [_syncMusic], once per voice-over.
  void _syncVoices({bool force = false}) {
    final controller = _controller;
    if (_voicePlayers.isEmpty || controller == null) return;
    final value = controller.value;
    if (!value.isInitialized) return;
    final trimStartMs = widget.trimStartMs ?? 0;
    final sourceOffsetMs = value.position.inMilliseconds - trimStartMs;
    final timelineMs = widget.timelineStartMs + _toTimelineMs(sourceOffsetMs < 0 ? 0 : sourceOffsetMs);
    for (final v in widget.voiceOvers) {
      final player = _voicePlayers[v.id];
      if (player == null) continue;
      final local = timelineMs - v.startMs;
      if (local < 0 || local >= v.durationMs) {
        if (player.playing) player.pause();
        continue;
      }
      if (force || (local - player.position.inMilliseconds).abs() > _syncToleranceMs) {
        player.seek(Duration(milliseconds: local));
      }
      player.setVolume(v.volume.clamp(0.0, 1.0));
      if (value.isPlaying && !player.playing) {
        player.play();
      } else if (!value.isPlaying && player.playing) {
        player.pause();
      }
    }
  }

  void _onControllerTick() {
    _enforceTrimBounds();
    _syncMusic();
    _syncVoices();
    _reportPosition();
  }

  /// Maps the video controller's current position onto the timeline —
  /// same mapping [_syncMusic] uses for the music track — and reports
  /// it via [VideoPreviewPlayer.onPositionTick].
  ///
  /// Clamps to just under this clip's own end rather than reporting the
  /// exact boundary: [_enforceTrimBounds] seeks back to the trim start
  /// once playback reaches the trim end, but that seek is async and
  /// hasn't necessarily landed by the time this runs on the same tick.
  /// Reporting the raw boundary value could momentarily read as
  /// belonging to the *next* clip (its `startMs` is this clip's
  /// `endMs`), which would flip `EditorScreen`'s selected clip — and
  /// swap `VideoPreviewPlayer`'s key — out from under the controller
  /// that's still actually playing.
  void _reportPosition() {
    final onTick = widget.onPositionTick;
    final controller = _controller;
    if (onTick == null || controller == null) return;
    final value = controller.value;
    if (!value.isInitialized) return;

    final trimStartMs = widget.trimStartMs ?? 0;
    var sourceOffsetMs = value.position.inMilliseconds - trimStartMs;
    if (sourceOffsetMs < 0) sourceOffsetMs = 0;
    var withinClipMs = _toTimelineMs(sourceOffsetMs);

    final trimEndMs = widget.trimEndMs;
    if (trimEndMs != null) {
      final trimmedMs = _toTimelineMs(trimEndMs - trimStartMs);
      if (trimmedMs > 0 && withinClipMs >= trimmedMs) {
        withinClipMs = trimmedMs - 1;
      }
    }

    onTick(widget.timelineStartMs + withinClipMs);
  }

  /// Keeps playback within [trimStartMs, trimEndMs]: loops back to the
  /// trim start once it reaches the trim end, and snaps back in if a
  /// live trim edit leaves the current position outside the new range.
  void _enforceTrimBounds() {
    final controller = _controller;
    final trimEndMs = widget.trimEndMs;
    if (controller == null || !controller.value.isInitialized) return;

    final positionMs = controller.value.position.inMilliseconds;
    final trimStartMs = widget.trimStartMs ?? 0;

    if (trimEndMs != null && positionMs >= trimEndMs) {
      controller.seekTo(Duration(milliseconds: trimStartMs));
      if (!controller.value.isPlaying) return;
      controller.pause();
      controller.play();
    } else if (positionMs < trimStartMs) {
      controller.seekTo(Duration(milliseconds: trimStartMs));
    }
  }

  /// Maps the video controller's current position onto the timeline,
  /// then onto the music track's own file position, and keeps the music
  /// player's play/pause + position in step with it. Silent (paused) for
  /// any part of the timeline outside the music's aligned window —
  /// `AudioTrackPanel`'s offset lets music start after the video, or run
  /// out before it ends.
  void _syncMusic({bool force = false}) {
    final track = widget.audioTrack;
    final player = _musicPlayer;
    final controller = _controller;
    if (track == null || player == null || controller == null) return;

    final value = controller.value;
    if (!value.isInitialized) return;

    final trimStartMs = widget.trimStartMs ?? 0;
    final sourceOffsetMs = value.position.inMilliseconds - trimStartMs;
    final timelineMs = widget.timelineStartMs +
        _toTimelineMs(sourceOffsetMs < 0 ? 0 : sourceOffsetMs);

    final musicTrimmedMs = track.trimEndMs - track.trimStartMs;
    final activeStartMs = track.offsetMs;
    final activeEndMs = track.offsetMs + musicTrimmedMs;

    if (musicTrimmedMs <= 0 ||
        timelineMs < activeStartMs ||
        timelineMs >= activeEndMs) {
      if (player.playing) player.pause();
      return;
    }

    final targetMs = track.trimStartMs + (timelineMs - activeStartMs);
    final currentMs = player.position.inMilliseconds;
    if (force || (targetMs - currentMs).abs() > _syncToleranceMs) {
      player.seek(Duration(milliseconds: targetMs));
    }

    // F9: approximate the export's `afade` with a live linear ramp —
    // see `_musicFadeMultiplier`'s doc comment for why this is only an
    // approximation, not a frame-accurate match to the export.
    player.setVolume(
      (track.volume.clamp(0.0, 1.0) * _musicFadeMultiplier(track, targetMs))
          .clamp(0.0, 1.0),
    );

    if (value.isPlaying && !player.playing) {
      player.play();
    } else if (!value.isPlaying && player.playing) {
      player.pause();
    }
  }

  /// F9 preview approximation of the music's fade-in/out: a linear ramp
  /// over [AudioTrack.fadeInMs]/[AudioTrack.fadeOutMs], measured from
  /// the *trimmed window's own* start/end — the same axis [positionMs]
  /// (the music file's own position, from [_syncMusic]'s `targetMs`) is
  /// already in, not the timeline. Export instead uses FFmpeg's `afade`,
  /// which is frame-accurate; this is a plain linear ramp recomputed
  /// every controller tick, close enough for a live preview but not
  /// meant to match the export exactly (same preview/export split as
  /// `AudioTrackPanel`'s doc comment already notes for trim/offset/volume).
  double _musicFadeMultiplier(AudioTrack track, int positionMs) {
    var mult = 1.0;
    final sinceStart = positionMs - track.trimStartMs;
    if (track.fadeInMs > 0 && sinceStart < track.fadeInMs) {
      mult = (sinceStart / track.fadeInMs).clamp(0.0, 1.0);
    }
    final untilEnd = track.trimEndMs - positionMs;
    if (track.fadeOutMs > 0 && untilEnd < track.fadeOutMs) {
      final outMult = (untilEnd / track.fadeOutMs).clamp(0.0, 1.0);
      if (outMult < mult) mult = outMult;
    }
    return mult;
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerTick);
    _controller?.dispose();
    _disposeMusic();
    _disposeVoices();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
    // Don't wait for the next position tick — start/stop the music the
    // moment the user taps, same as the video does.
    _syncMusic(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.effectStyle;
    final looked = LookFiltered(
      brightness: widget.brightness,
      contrast: widget.contrast,
      saturation: widget.saturation,
      look: widget.look,
      strength: widget.lookStrength,
      compareSplit: widget.compareSplit,
      child: ChromaKeyed(spec: widget.chromaKey, child: _buildContent(context)),
    );
    return LookFiltered(spec: style?.spec, strength: style?.strength ?? 0, child: looked);
  }

  Widget _buildContent(BuildContext context) {
    if (!widget.asset.isVideo) {
      return _RotateFlip(
        turns: widget.turns,
        flipH: widget.flipH,
        flipV: widget.flipV,
        child: _PhotoPreview(asset: widget.asset, fitMode: widget.fitMode),
      );
    }

    if (_hasError) {
      return const _PreviewMessage(
        icon: Icons.error_outline,
        text: 'Couldn\'t load this clip.',
      );
    }

    if (!_isReady || _controller == null) {
      return _LoadingPreview(thumbnailUri: widget.asset.thumbnailUri, fitMode: widget.fitMode);
    }

    final controller = _controller!;
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: _RotateFlip(
              turns: widget.turns,
              flipH: widget.flipH,
              flipV: widget.flipV,
              // Scales the video's natural size to the canvas exactly like
              // the export: fit letterboxes, fill crops, blur fits over a
              // blurred cover copy (one decoder — the texture is drawn twice).
              child: FitFrame(
                fitMode: widget.fitMode,
                builder: (fit) => FittedBox(
                  fit: fit,
                  clipBehavior: ui.Clip.hardEdge,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            ),
          ),
          _PlayPauseGlyph(controller: controller),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: const EdgeInsets.all(8),
              colors: VideoProgressColors(
                playedColor: Theme.of(context).colorScheme.primary,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// F10: wraps [child] in [turns] quarter-turns clockwise (via
/// `RotatedBox`, which — unlike `Transform.rotate` — swaps the layout's
/// width/height for odd turn counts, so a landscape clip rotated 90°
/// actually lays out portrait-shaped instead of just painting sideways
/// inside its original landscape box) plus an optional horizontal/
/// vertical mirror, applied *before* the rotation (flip the unrotated
/// frame, then rotate the result) — the same order
/// `export_command_builder.dart`'s filter chain applies them in, so the
/// preview matches what export produces.
class _RotateFlip extends StatelessWidget {
  final int turns;
  final bool flipH;
  final bool flipV;
  final Widget child;

  const _RotateFlip({
    required this.turns,
    required this.flipH,
    required this.flipV,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    var content = child;
    if (flipH || flipV) {
      content = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0),
        child: content,
      );
    }
    final normalizedTurns = turns % 4;
    if (normalizedTurns != 0) {
      content = RotatedBox(quarterTurns: normalizedTurns, child: content);
    }
    return content;
  }
}

/// Briefly shows a play/pause glyph on tap, then fades — cheap
/// "did that tap register" feedback without extra state plumbing.
class _PlayPauseGlyph extends StatelessWidget {
  final VideoPlayerController controller;

  const _PlayPauseGlyph({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return AnimatedOpacity(
          opacity: value.isPlaying ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: Icon(
            Icons.play_arrow,
            size: 56,
            color: Colors.white.withOpacity(0.85),
          ),
        );
      },
    );
  }
}

/// Shown while the [VideoPlayerController] initializes. Uses the cached
/// thumbnail (Phase 3, second half) as a backdrop when one is available
/// instead of a bare spinner on black — mostly noticeable on larger or
/// slower-to-decode clips, where initialize() can take a moment.
class _LoadingPreview extends StatelessWidget {
  final String? thumbnailUri;
  final String fitMode;

  const _LoadingPreview({required this.thumbnailUri, required this.fitMode});

  @override
  Widget build(BuildContext context) {
    final thumbnailUri = this.thumbnailUri;
    if (thumbnailUri == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        // Same framing as the player that replaces it, so nothing jumps.
        FitFrame(
          fitMode: fitMode,
          builder: (fit) => Image.file(
            File(thumbnailUri),
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: 720,
            // If the cached thumbnail file has gone missing, fall back
            // silently to the plain black backdrop underneath.
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        Container(color: Colors.black38),
        const CircularProgressIndicator(strokeWidth: 2),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final MediaAsset asset;
  final String fitMode;

  const _PhotoPreview({required this.asset, required this.fitMode});

  @override
  Widget build(BuildContext context) {
    return FitFrame(
      fitMode: fitMode,
      // Both copies share one decode (same file + cacheWidth = same cache key).
      builder: (fit) => Image.file(
        File(asset.uri),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: 1440, // a 12MP photo would otherwise decode to ~48MB for a 3s clip
        errorBuilder: (_, __, ___) => const _PreviewMessage(
          icon: Icons.error_outline,
          text: 'Couldn\'t load this photo.',
        ),
      ),
    );
  }
}

/// F15 in the preview, matching `export_command_builder.dart`:
///  * fit  → whole picture, letterboxed (`contain`);
///  * fill → covers the frame, cropped (`cover`);
///  * blur → whole picture over a blurred, cropped copy of itself.
/// [builder] is called once per layer with the [BoxFit] to use; it must
/// scale its content to the incoming constraints with that fit.
class FitFrame extends StatelessWidget {
  final String fitMode;
  final Widget Function(BoxFit fit) builder;

  const FitFrame({super.key, required this.fitMode, required this.builder});

  /// Blur radius as a fraction of the frame width. The export blurs a
  /// quarter-size copy with `gblur=sigma=6` (≈ 24 px at full size), i.e.
  /// 2–3 % of the width depending on resolution.
  static const blurFraction = 0.033;

  @override
  Widget build(BuildContext context) {
    final mode = normalizeFitMode(fitMode);
    if (mode == fitModeFill) return ClipRect(child: builder(BoxFit.cover));
    if (mode != fitModeBlur) return builder(BoxFit.contain);
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth.isFinite ? box.maxWidth : 360.0;
      final sigma = width * blurFraction;
      return Stack(fit: StackFit.expand, children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.clamp),
            child: builder(BoxFit.cover),
          ),
        ),
        builder(BoxFit.contain),
      ]);
    });
  }
}

class _PreviewMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PreviewMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 32),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
