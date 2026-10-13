import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../app/launch_gate.dart' show appPrefsProvider;
import '../data/database_provider.dart';
import '../data/project_database.dart';
import '../models/audio_asset.dart';
import '../models/bundled_track.dart';
import '../models/clip_x.dart';
import '../models/media_asset.dart';
import '../models/transition_x.dart';
import '../providers/audio_providers.dart';
import '../providers/text_overlay_providers.dart';
import '../providers/timeline_providers.dart';
import '../router/app_router.dart';
import '../services/audio_import_service.dart';
import '../services/media_import_service.dart';
import '../widgets/common/state_views.dart';
import '../widgets/history_actions.dart';
import '../widgets/text_overlay_layer.dart';
import '../widgets/timeline/audio_track_lane.dart';
import '../widgets/timeline/audio_track_panel.dart';
import '../widgets/timeline/filter_panel.dart';
import '../widgets/timeline/playhead_controls.dart';
import '../widgets/timeline/text_overlay_panel.dart';
import '../widgets/timeline/text_overlay_strip.dart';
import '../widgets/timeline/timeline_scrub_bar.dart';
import '../widgets/timeline/timeline_strip.dart';
import '../widgets/timeline/trim_panel.dart';
import '../widgets/video_preview_player.dart';

/// Editor screen. Phase 2 wired up navigation/layout; Phase 3 added
/// media import + single-clip preview. Phase 4 replaces the placeholder
/// timeline with the real thing: a clip strip, a scrub bar that drives
/// the playhead, and trim/split/delete for the selected clip. Phase 5
/// adds the background-music track end to end: import from device
/// storage or the bundled library, trim + align it against the video
/// timeline, independent volume for the music and for each clip's
/// original audio (plus per-clip mute), and — via `VideoPreviewPlayer`
/// — actually mixing that into what plays back in the preview. Phase 6
/// adds text overlays: tap-to-add, drag-to-position on the canvas
/// (`TextOverlayLayer`), font/size/color/alignment/timing
/// (`TextOverlayPanel`), a timeline lane showing every overlay's timing
/// at a glance (`TextOverlayStrip`), and — the second pass — keeps
/// `playheadMsProvider` advancing during live playback (not just scrub)
/// via `VideoPreviewPlayer.onPositionTick`, and maps overlay positions
/// onto the actual letterboxed video frame via `onAspectRatioKnown`.
/// Phase 7 adds transitions + filters, in two passes. First pass: a
/// transition badge at each clip's trailing edge on the timeline strip
/// (opens a cut/fade/dissolve picker, persisted to
/// `Clip.transitionOut`), and a `FilterPanel`/`TrimPanel` tab switch in
/// the bottom panel so a selected clip's brightness/contrast/saturation
/// (plus bundled presets) can be dialed in with a live preview via
/// `VideoPreviewPlayer`. Second pass: `_buildPreviewArea` actually
/// renders the chosen transition as the playhead nears a clip boundary
/// (see `models/transition_x.dart`), and `FilterPanel` gained a "This
/// clip"/"All clips" toggle so filters can be applied project-wide, not
/// just per-clip. See PHASE_5_PROGRESS.md / PHASE_6_PROGRESS.md /
/// PHASE_7_PROGRESS.md for what each phase still leaves open — notably,
/// baking any of this into exported frames is Phase 8 (the export
/// pipeline doesn't exist yet).
class EditorScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const EditorScreen({super.key, required this.projectId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  @override
  void initState() {
    super.initState();
    // Remember what the user was editing so Home can offer "Resume".
    final id = widget.projectId;
    if (id != null) ref.read(appPrefsProvider).setLastProjectId(id);
  }

  final MediaImportService _importService = MediaImportService();
  final AudioImportService _audioImportService = AudioImportService();

  bool _isImporting = false;
  String? _importError;
  bool _isImportingAudio = false;

  /// Which tab the bottom panel shows for a selected clip — trim/split/
  /// delete/volume (`TrimPanel`, Phase 4/5) or the Phase 7
  /// brightness/contrast/saturation controls (`FilterPanel`). A plain
  /// screen-level toggle rather than per-clip state: which tab you were
  /// just looking at is more likely to be what you want to keep looking
  /// at on the next clip than a reset back to "Trim" every tap.
  _ClipPanelTab _clipPanelTab = _ClipPanelTab.trim;

  /// Aspect ratio (width / height) of each clip's video, keyed by clip
  /// id, as reported by `VideoPreviewPlayer` once its controller
  /// initializes — used to map text-overlay positions onto the actual
  /// letterboxed video frame rather than the full preview canvas (see
  /// PHASE_6_PROGRESS.md's letterboxing note). Photos don't report one
  /// yet, so overlays on a photo-only project still map to the full
  /// canvas — a smaller, documented follow-up rather than this pass's
  /// main fix.
  final Map<String, double> _clipAspectRatios = {};

  void _onAspectRatioKnown(String clipId, double ratio) {
    if (_clipAspectRatios[clipId] == ratio) return;
    setState(() => _clipAspectRatios[clipId] = ratio);
  }

  /// Photos have no intrinsic duration; give them a fixed slot on the
  /// timeline like most basic editors do (matches the note left in
  /// MediaImportService back in Phase 3).
  static const int _photoDurationMs = 3000;

  Future<void> _importVideo() => _runImport(_importService.pickVideo);

  Future<void> _importPhoto() => _runImport(_importService.pickPhoto);

  Future<void> _runImport(Future<MediaAsset?> Function() pick) async {
    final projectId = widget.projectId;
    if (projectId == null) return;

    setState(() {
      _isImporting = true;
      _importError = null;
    });
    try {
      final asset = await pick();
      if (asset != null) {
        await ref.read(projectDatabaseProvider).appendClip(
              id: asset.id,
              projectId: projectId,
              sourceUri: asset.uri,
              durationMs: asset.isVideo
                  ? (asset.duration?.inMilliseconds ?? 0)
                  : _photoDurationMs,
              rotationDegrees: asset.rotationDegrees,
              thumbnailUri: asset.thumbnailUri,
            );
        ref.read(selectedClipIdProvider.notifier).state = asset.id;
      }
    } catch (e) {
      setState(() => _importError = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _importAudioFromDevice() =>
      _attachAudio(_audioImportService.pickFromDevice);

  Future<void> _importAudioFromLibrary(BundledTrack track) =>
      _attachAudio(() => _audioImportService.pickFromLibrary(track));

  /// Shared plumbing for both audio-import paths: run [pick], and if it
  /// returns something, attach it as the project's background-music
  /// track and open [AudioTrackPanel] on it. `pickFromLibrary` never
  /// returns null (there's nothing to "cancel" picking a fixed catalog
  /// entry the way there is with the device file picker), so this stays
  /// generic over both rather than duplicating the attach/open logic.
  Future<void> _attachAudio(Future<AudioAsset?> Function() pick) async {
    final projectId = widget.projectId;
    if (projectId == null || _isImportingAudio) return;

    setState(() => _isImportingAudio = true);
    try {
      final asset = await pick();
      if (asset != null) {
        await ref.read(projectDatabaseProvider).setAudioTrack(
              id: const Uuid().v4(),
              projectId: projectId,
              sourceUri: asset.uri,
              durationMs: asset.duration.inMilliseconds,
            );
        ref.read(selectedClipIdProvider.notifier).state = null;
        ref.read(audioPanelOpenProvider.notifier).state = true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImportingAudio = false);
    }
  }

  /// Entry point for adding music (tapped from the empty `AudioTrackLane`):
  /// device file, or the bundled royalty-free library.
  void _showAudioImportSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Import from device'),
              onTap: () {
                Navigator.pop(sheetContext);
                _importAudioFromDevice();
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_music_outlined),
              title: const Text('Choose from library'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showBundledLibrarySheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// The bundled royalty-free catalog (Phase 5, second half — the rest
  /// of item 1). A flat list is fine at three tracks; if the library
  /// grows, this is the spot to add search/categories.
  void _showBundledLibrarySheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Royalty-free library',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            for (final track in bundledAudioLibrary)
              ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(track.title),
                trailing: Text(
                  '${(track.durationMs / 1000).toStringAsFixed(0)}s',
                  style: const TextStyle(color: Colors.white54),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _importAudioFromLibrary(track);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Creates a new overlay centered on the canvas, starting at the
  /// current playhead and running 3s (clamped to the timeline's end so
  /// it never gets created already-expired), then opens
  /// `TextOverlayPanel` on it. Multiple overlays — simultaneous or
  /// sequential — are just more rows with their own `startMs`/`endMs`;
  /// nothing here needs to know about ones that already exist.
  Future<void> _addTextOverlay(String projectId, int totalMs) async {
    final playheadMs = ref.read(playheadMsProvider);
    final spanMs = totalMs > 0 ? totalMs : 5000;
    var startMs = totalMs > 0 ? playheadMs.clamp(0, spanMs).toInt() : 0;
    if (startMs > spanMs - 100) startMs = spanMs - 100 < 0 ? 0 : spanMs - 100;
    final endMs = (startMs + 3000) > spanMs ? spanMs : startMs + 3000;

    final id = const Uuid().v4();
    await ref.read(projectDatabaseProvider).insertTextOverlay(
          TextOverlaysCompanion.insert(
            id: id,
            projectId: projectId,
            content: 'Tap to edit',
            startMs: Value(startMs),
            endMs: endMs,
          ),
        );
    ref.read(selectedTextOverlayIdProvider.notifier).state = id;
    ref.read(textPanelOpenProvider.notifier).state = true;
    ref.read(audioPanelOpenProvider.notifier).state = false;
    ref.read(selectedClipIdProvider.notifier).state = null;
  }

  void _showImportSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Import video'),
              onTap: () {
                Navigator.pop(sheetContext);
                _importVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Import photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _importPhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectId = widget.projectId;
    final clipsAsync =
        projectId == null ? null : ref.watch(clipsProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: [
          if (projectId != null) HistoryActions(projectId: projectId),
          TextButton(
            onPressed: projectId == null
                ? null
                : () => Navigator.pushNamed(
                      context,
                      AppRouter.export,
                      arguments: projectId,
                    ),
            child: const Text('Export'),
          ),
        ],
      ),
      body: clipsAsync == null
          ? const Center(child: Text('No project selected.'))
          : clipsAsync.when(
              loading: () => const LoadingStateView(message: 'Opening project…'),
              error: (e, _) => ErrorStateView(
                message: 'Couldn\'t load this project: $e',
                onRetry: () => ref.invalidate(clipsProvider(projectId!)),
              ),
              data: (clips) => _buildBody(projectId!, clips),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isImporting ? null : _showImportSheet,
        tooltip: 'Import media',
        child: _isImporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
      ),
    );
  }

  Widget _buildBody(String projectId, List<Clip> clips) {
    final layout = layoutTimeline(clips);
    final totalMs = layout.isEmpty ? 0 : layout.last.endMs;
    final playheadMs = ref.watch(playheadMsProvider);
    final currentPos = positionAt(layout, playheadMs);

    final selectedId = ref.watch(selectedClipIdProvider);
    final selectedClip = selectedId == null
        ? null
        : clips.where((c) => c.id == selectedId).firstOrNull;

    final audioTrack = ref.watch(audioTrackProvider(projectId)).value;
    final audioPanelOpen = ref.watch(audioPanelOpenProvider);

    final textOverlays = ref.watch(textOverlaysProvider(projectId)).value ?? [];
    final textPanelOpen = ref.watch(textPanelOpenProvider);
    final selectedTextOverlayId = ref.watch(selectedTextOverlayIdProvider);
    final selectedTextOverlay = selectedTextOverlayId == null
        ? null
        : textOverlays.where((t) => t.id == selectedTextOverlayId).firstOrNull;

    final frameAspectRatio =
        currentPos == null ? null : _clipAspectRatios[currentPos.clip.id];

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: RepaintBoundary(
            child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                Center(
                  child: _buildPreviewArea(
                    currentPos,
                    layout,
                    playheadMs,
                    audioTrack,
                  ),
                ),
                TextOverlayLayer(
                  overlays: textOverlays,
                  playheadMs: playheadMs,
                  frameAspectRatio: frameAspectRatio,
                ),
              ],
            ),
          ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.grey[900],
            child: RepaintBoundary(
              child: TimelineStrip(projectId: projectId, clips: clips),
            ),
          ),
        ),
        AudioTrackLane(
          track: audioTrack,
          totalMs: totalMs,
          onImport: _showAudioImportSheet,
        ),
        TextOverlayStrip(overlays: textOverlays, totalMs: totalMs),
        TimelineScrubBar(
          layout: layout,
          totalMs: totalMs,
          playheadMs: playheadMs,
          snapEnabled: ref.watch(snapScrubProvider),
          onScrub: (ms) => seekTimeline(ref, layout, ms),
        ),
        PlayheadControls(clips: clips),
        if (textPanelOpen && selectedTextOverlay != null)
          TextOverlayPanel(overlay: selectedTextOverlay, totalTimelineMs: totalMs)
        else if (audioPanelOpen && audioTrack != null)
          AudioTrackPanel(track: audioTrack, totalTimelineMs: totalMs)
        else if (selectedClip != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ClipPanelTabBar(
                selected: _clipPanelTab,
                onChanged: (tab) => setState(() => _clipPanelTab = tab),
              ),
              if (_clipPanelTab == _ClipPanelTab.trim)
                TrimPanel(clip: selectedClip, allClips: clips)
              else
                FilterPanel(clip: selectedClip),
            ],
          )
        else
          SafeArea(
            top: false,
            child: Container(
              height: 56,
              color: Colors.grey[850],
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _addTextOverlay(projectId, totalMs),
                    icon: const Icon(Icons.title, color: Colors.white70, size: 18),
                    label: Text(
                      textOverlays.isEmpty
                          ? 'Add text'
                          : 'Add text (${textOverlays.length})',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Tap a clip to trim/filter · ⚬ for transitions',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewArea(
    TimelinePosition? currentPos,
    List<TimelinePosition> layout,
    int playheadMs,
    AudioTrack? audioTrack,
  ) {
    if (_importError != null) {
      return Text(
        _importError!,
        style: const TextStyle(color: Colors.redAccent),
        textAlign: TextAlign.center,
      );
    }

    if (currentPos == null) {
      return const Text(
        'Tap + to import a clip or photo',
        style: TextStyle(color: Colors.white54),
      );
    }

    final clip = currentPos.clip;
    // The Clips table doesn't store media type (Phase 4 kept the schema
    // change minimal) — infer photo-vs-video from the source file's
    // extension, same set image_picker's gallery photo path can produce.
    const photoExtensions = {'.jpg', '.jpeg', '.png', '.heic', '.webp', '.gif'};
    final isPhoto =
        photoExtensions.contains(p.extension(clip.sourceUri).toLowerCase());

    final asset = MediaAsset(
      id: clip.id,
      uri: clip.sourceUri,
      type: isPhoto ? MediaAssetType.photo : MediaAssetType.video,
      duration: Duration(milliseconds: clip.durationMs),
      width: 0,
      height: 0,
      rotationDegrees: clip.rotationDegrees,
      thumbnailUri: clip.thumbnailUri,
    );

    // Phase 7 (second half): as the playhead nears this clip's trimmed
    // end, blend toward the next clip's thumbnail per
    // `transitionPreviewAt` — see `models/transition_x.dart` for why
    // this is thumbnail-based rather than a true two-video crossfade.
    final currentIndex = layout.indexWhere((pos) => pos.clip.id == clip.id);
    final hasNext = currentIndex >= 0 && currentIndex < layout.length - 1;
    final preview = hasNext
        ? transitionPreviewAt(
            transitionOut: clip.transitionOut,
            playheadMs: playheadMs,
            boundaryMs: currentPos.endMs,
          )
        : TransitionPreview.none;
    final nextThumbnailUri =
        hasNext ? layout[currentIndex + 1].clip.thumbnailUri : null;

    final player = VideoPreviewPlayer(
      key: ValueKey(clip.id),
      asset: asset,
      trimStartMs: isPhoto ? null : clip.trimStartMs,
      trimEndMs: isPhoto ? null : clip.trimEndMs,
      clipVolume: clip.volume,
      muted: clip.muted,
      audioTrack: audioTrack,
      timelineStartMs: currentPos.startMs,
      onPositionTick: (ms) =>
          ref.read(playheadMsProvider.notifier).state = ms,
      onAspectRatioKnown: (ratio) => _onAspectRatioKnown(clip.id, ratio),
      brightness: clip.brightness,
      contrast: clip.contrast,
      saturation: clip.saturation,
    );

    if (preview.nextOpacity == 0 && preview.currentOpacity == 1) {
      // No transition in effect right now — skip the Stack/Opacity
      // wrapping entirely for the common case.
      return player;
    }

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        // Solid black backdrop so a 'fade' transition's fade-through-
        // black is actually visible between the two Opacity layers,
        // rather than showing whatever was behind the Stack.
        Container(color: Colors.black),
        Opacity(opacity: preview.currentOpacity, child: player),
        if (preview.nextOpacity > 0 && nextThumbnailUri != null)
          Opacity(
            opacity: preview.nextOpacity,
            child: Image.file(
              File(nextThumbnailUri),
              fit: BoxFit.contain,
              cacheWidth: 720,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}

/// Which sub-panel `EditorScreen` shows for a selected clip. See
/// `_EditorScreenState._clipPanelTab`'s doc comment.
enum _ClipPanelTab { trim, filters }

/// Small two-way switch above the selected-clip panel. Deliberately
/// plain (`TextButton`s, not a full `TabBar`) to match the weight of
/// everything else docked in this bottom strip — a `TabBar` would read
/// as a bigger piece of chrome than a two-option toggle warrants here.
class _ClipPanelTabBar extends StatelessWidget {
  final _ClipPanelTab selected;
  final ValueChanged<_ClipPanelTab> onChanged;

  const _ClipPanelTabBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    Widget tab(_ClipPanelTab tab, String label) {
      final isActive = tab == selected;
      return TextButton(
        onPressed: () => onChanged(tab),
        style: TextButton.styleFrom(
          foregroundColor: isActive ? accent : Colors.white54,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[850],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          tab(_ClipPanelTab.trim, 'Trim'),
          tab(_ClipPanelTab.filters, 'Filters'),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
