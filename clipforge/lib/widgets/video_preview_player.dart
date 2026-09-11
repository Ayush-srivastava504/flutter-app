import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/media_asset.dart';

/// Full-screen-ish preview of a single [MediaAsset].
///
/// This is Phase 3 scope only: one clip, play/pause, a scrub bar tied
/// to that one clip's own duration. It does NOT yet sync to a
/// multi-clip timeline playhead — that wiring happens in Phase 4 once
/// the timeline exists to sync against.
class VideoPreviewPlayer extends StatefulWidget {
  final MediaAsset asset;

  const VideoPreviewPlayer({super.key, required this.asset});

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setUp();
  }

  @override
  void didUpdateWidget(VideoPreviewPlayer old) {
    super.didUpdateWidget(old);
    if (old.asset.uri != widget.asset.uri) {
      _controller?.dispose();
      _controller = null;
      _isReady = false;
      _hasError = false;
      _setUp();
    }
  }

  Future<void> _setUp() async {
    if (!widget.asset.isVideo) return; // photos have nothing to init
    final controller = VideoPlayerController.file(File(widget.asset.uri));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _isReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.asset.isVideo) {
      return _PhotoPreview(asset: widget.asset);
    }

    if (_hasError) {
      return const _PreviewMessage(
        icon: Icons.error_outline,
        text: 'Couldn\'t load this clip.',
      );
    }

    if (!_isReady || _controller == null) {
      return _LoadingPreview(thumbnailUri: widget.asset.thumbnailUri);
    }

    final controller = _controller!;
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
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

  const _LoadingPreview({required this.thumbnailUri});

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
        Image.file(
          File(thumbnailUri),
          fit: BoxFit.contain,
          // If the cached thumbnail file has gone missing, fall back
          // silently to the plain black backdrop underneath.
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        Container(color: Colors.black38),
        const CircularProgressIndicator(strokeWidth: 2),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final MediaAsset asset;

  const _PhotoPreview({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(asset.uri),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const _PreviewMessage(
        icon: Icons.error_outline,
        text: 'Couldn\'t load this photo.',
      ),
    );
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
