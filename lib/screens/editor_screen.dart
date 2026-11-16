import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../ai/edit_action.dart';
import '../app/app_theme.dart';
import '../app/launch_gate.dart' show appPrefsProvider;
import '../data/database_provider.dart';
import '../data/project_database.dart';
import '../models/audio_asset.dart';
import '../models/bundled_track.dart';
import '../models/clip_x.dart';
import '../models/chroma_key.dart';
import '../models/edit_mode.dart';
import '../models/effect_x.dart';
import '../models/frame_shape.dart';
import '../models/color_filter_x.dart' show isNeutralFilter;
import '../models/media_asset.dart';
import '../models/srt_parser.dart';
import '../models/transition_x.dart';
import '../providers/audio_providers.dart';
import '../providers/text_overlay_providers.dart';
import '../providers/timeline_providers.dart';
import '../providers/voice_providers.dart';
import '../router/app_router.dart';
import '../services/audio_import_service.dart';
import '../services/media_import_service.dart';
import '../widgets/glow_overlay.dart';
import '../widgets/assistant_sheet.dart';
import '../widgets/common/state_views.dart';
import '../widgets/common/ui_kit.dart';
import '../widgets/editor/audio_library_sheet.dart';
import '../widgets/editor/autocut_sheet.dart';
import '../widgets/editor/chapters_sheet.dart';
import '../widgets/editor/mode_guide_sheet.dart';
import '../widgets/editor/safe_zones_overlay.dart';
import '../widgets/editor/tool_dock.dart';
import '../widgets/editor/voice_over.dart';
import '../widgets/timeline/background_panel.dart';
import '../widgets/timeline/effects_panel.dart';
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

/// The editor: a preview canvas in the project's frame shape, the clip
/// strip, the music and text lanes, the scrub bar, and a bottom panel for
/// whatever is selected (clip trim/filters, music, or text).
///
/// It holds no clip data of its own — everything is read from database
/// streams (see docs/APP_GUIDE.md §3), so any edit, undo or assistant action
/// shows up here without this widget being told.
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
    if (id != null) {
      ref.read(appPrefsProvider).setLastProjectId(id);
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowModeGuide(id));
    }
  }

  /// Rule-of-thirds + title-safe guides on the preview (YouTube Studio).
  bool _showGuides = false;

  /// For the non-modal voice-over recorder sheet.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Pro → Enhance speech: this clip, every clip, or off. Export-only.
  Future<void> _enhanceSpeech(String projectId) async {
    final db = ref.read(projectDatabaseProvider);
    final clips = await db.watchClips(projectId).first;
    if (!mounted) return;
    if (clips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a clip first.')));
      return;
    }
    final layout = layoutTimeline(clips);
    final under = positionAt(layout, ref.read(playheadMsProvider))?.clip;
    final onCount = clips.where((c) => c.enhanceSpeech).length;
    final choice = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Row(children: [
              const Icon(Icons.record_voice_over_outlined, color: AppColors.pro),
              const SizedBox(width: 10),
              Text('Enhance speech', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(width: 8),
              const ProBadge(),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Cuts rumble and hiss, reduces background noise, adds presence and evens out loud and quiet '
              'words. You hear it in the exported video; the preview plays the original sound.',
              style: TextStyle(color: AppColors.textDim, height: 1.35),
            ),
          ),
          if (under != null)
            ListTile(
              leading: const Icon(Icons.crop_square_rounded),
              title: Text(under.enhanceSpeech ? 'Turn off for this clip' : 'This clip'),
              subtitle: const Text('The clip under the playhead'),
              onTap: () => Navigator.pop(ctx, 1),
            ),
          ListTile(
            leading: const Icon(Icons.view_week_outlined),
            title: const Text('Every clip'),
            subtitle: Text('$onCount of ${clips.length} clips enhanced now'),
            onTap: () => Navigator.pop(ctx, 2),
          ),
          if (onCount > 0)
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Turn off everywhere'),
              onTap: () => Navigator.pop(ctx, 3),
            ),
          const SizedBox(height: 8),
        ])),
      ),
    );
    if (choice == null || !mounted) return;
    final String msg;
    switch (choice) {
      case 1:
        final on = !under!.enhanceSpeech;
        await db.updateClip(under.copyWith(enhanceSpeech: on));
        msg = on ? 'Speech enhanced on this clip.' : 'Speech enhancement off for this clip.';
      case 2:
        await db.setEnhanceSpeechForAll(projectId, true);
        msg = 'Speech enhanced on every clip.';
      default:
        await db.setEnhanceSpeechForAll(projectId, false);
        msg = 'Speech enhancement off.';
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// The Pro tool currently analysing media, if any.
  SmartTool? _runningTool;

  /// First time a project of each mode is opened, explain the mode.
  Future<void> _maybeShowModeGuide(String projectId) async {
    final project = await ref.read(projectDatabaseProvider).getProject(projectId);
    final prefs = ref.read(appPrefsProvider);
    final mode = EditMode.fromName(project?.mode);
    if (await prefs.hasSeenModeTips(mode.name)) return;
    await prefs.markModeTipsSeen(mode.name);
    if (mounted) await showModeGuide(context, mode);
  }

  /// Runs a Pro smart tool through the assistant executor (undoable) and
  /// reports what it did.
  Future<void> _runSmartTool(String projectId, SmartTool tool, ClipScope scope) async {
    if (_runningTool != null) return;
    setState(() => _runningTool = tool);
    try {
      final results = await runEditActions(ref, projectId, [RunSmartTool(tool, scope)]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(results.map((r) => r.message).join('\n'))),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("That didn't work: $e")));
      }
    } finally {
      if (mounted) setState(() => _runningTool = null);
    }
  }

  /// Jump cuts / scene split: the clip under the playhead, or every clip.
  Future<void> _runOnClipOrAll(String projectId, SmartTool tool, String title) async {
    final scope = await showModalBottomSheet<ClipScope>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.crop_square_rounded),
            title: const Text('This clip'),
            subtitle: const Text('The clip under the playhead'),
            onTap: () => Navigator.pop(ctx, const ClipScope.selected()),
          ),
          ListTile(
            leading: const Icon(Icons.view_week_outlined),
            title: const Text('Every clip'),
            subtitle: const Text('Can take a while on long videos'),
            onTap: () => Navigator.pop(ctx, const ClipScope.all()),
          ),
          const SizedBox(height: 8),
        ])),
      ),
    );
    if (scope != null) await _runSmartTool(projectId, tool, scope);
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

  /// Photos have no intrinsic duration; give them a fixed slot on the
  /// timeline like most basic editors do (matches the note left in
  /// MediaImportService back in Phase 3).
  static const int _photoDurationMs = 3000;

  Future<void> _importVideo() => _runImport(_importService.pickVideo);

  Future<void> _importPhoto() => _runImport(_importService.pickPhoto);

  Future<void> _runImport(Future<MediaAsset?> Function() pick) => _runImportMany(() async {
        final a = await pick();
        return a == null ? const <MediaAsset>[] : [a];
      });

  /// Several videos/photos at once, appended in the order they were picked.
  Future<void> _importMany() => _runImportMany(() => _importService.pickMultipleMedia(limit: 30));

  /// Appends whatever [pick] returns to the end of the timeline. New clips
  /// are not auto-selected, so the tool bar (and its "Media" button) stays
  /// on screen for adding more; tap a clip to edit it.
  Future<void> _runImportMany(Future<List<MediaAsset>> Function() pick) async {
    final projectId = widget.projectId;
    if (projectId == null) return;

    setState(() {
      _isImporting = true;
      _importError = null;
    });
    try {
      final assets = await pick();
      if (assets.isEmpty) return;
      final db = ref.read(projectDatabaseProvider);
      // The first video decides the frame shape (a landscape clip in the
      // default 9:16 frame would be a thin letterboxed strip). Later
      // imports never change it; the frame-shape menu still can. YouTube
      // Studio and Insta Clip projects keep their locked shape.
      final locked = EditMode.fromName((await db.getProject(projectId))?.mode).lockedAspect != null;
      final firstVideo = assets.where((a) => a.isVideo).firstOrNull;
      if (!locked && firstVideo != null && (await db.watchClips(projectId).first).isEmpty) {
        final shape =
            nearestFrameShape(firstVideo.width, firstVideo.height, rotationDegrees: firstVideo.rotationDegrees);
        if (shape != null) await db.setAspectRatio(projectId, shape);
      }
      for (final asset in assets) {
        await db.appendClip(
          id: asset.id,
          projectId: projectId,
          sourceUri: asset.uri,
          durationMs: asset.isVideo ? (asset.duration?.inMilliseconds ?? 0) : _photoDurationMs,
          rotationDegrees: asset.rotationDegrees,
          thumbnailUri: asset.thumbnailUri,
        );
      }
      ref.read(selectedClipIdProvider.notifier).state = null;
      if (mounted && assets.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${assets.length} clips.')));
      }
    } catch (e) {
      if (mounted) setState(() => _importError = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _importAudioFromDevice() => _attachAudio(_audioImportService.pickFromDevice);

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
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
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
        )),
      ),
    );
  }

  /// The bundled royalty-free catalog (Phase 5, second half — the rest
  /// of item 1). A flat list is fine at three tracks; if the library
  /// grows, this is the spot to add search/categories.
  Future<void> _showBundledLibrarySheet() async {
    final track = await showMusicLibrary(context);
    if (track != null) await _importAudioFromLibrary(track);
  }

  /// Sound effects: copied into app storage and placed at the playhead as a
  /// timeline sound (a `VoiceOvers` row with enhance off).
  Future<void> _addSoundEffect(String projectId) async {
    final sound = await showSfxLibrary(context);
    if (sound == null || !mounted) return;
    try {
      final asset = await _audioImportService.pickFromLibrary(sound.asTrack);
      await ref.read(projectDatabaseProvider).insertVoiceOver(VoiceOversCompanion.insert(
            id: const Uuid().v4(),
            projectId: projectId,
            sourceUri: asset.uri,
            startMs: ref.read(playheadMsProvider),
            durationMs: asset.duration.inMilliseconds > 0 ? asset.duration.inMilliseconds : sound.durationMs,
            enhance: const Value(false),
          ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${sound.title}" added at the playhead.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't add that sound: $e")));
    }
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

  /// The assistant, with AI results appended to the timeline like any import.
  Future<void> _openAssistant(String projectId, [AssistantTab tab = AssistantTab.edit]) => showAssistantSheet(
        context,
        projectId,
        initialTab: tab,
        onGenerated: (asset) => _runImportMany(() async => [asset]),
      );

  void _showImportSheet() {
    if (_isImporting) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.video_library_outlined, color: AppColors.ember),
                title: const Text('Videos & photos'),
                subtitle: const Text('Pick one or several — they go to the end of the timeline'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _importMany();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('One video'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _importVideo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('One photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _importPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: AppColors.pro),
                title: const Text('Generate with AI'),
                subtitle: const Text('Make an image or video from a description (your own API key)'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final id = widget.projectId;
                  if (id != null) _openAssistant(id, AssistantTab.create);
                },
              ),
              ListTile(
                leading: const Icon(Icons.subtitles_outlined),
                title: const Text('Subtitles (.srt)'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _importSubtitles();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// F12: picks a `.srt` file, parses it with `parseSrt` (pure, tested
  /// separately in `test/srt_parser_test.dart`), and inserts one
  /// `TextOverlay` per cue in a single transaction via
  /// `insertTextOverlays` — so a large file either lands entirely or
  /// not at all, never half-imported. Cue timestamps are used as-is
  /// (not clamped to the current timeline length): a cue past the end
  /// of the timeline is simply unreachable, not an error, same as any
  /// other overlay a user could in principle create out of range.
  Future<void> _importSubtitles() async {
    final projectId = widget.projectId;
    if (projectId == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt'],
    );
    final path = result?.files.single.path;
    if (path == null) return; // user cancelled the picker

    String text;
    try {
      text = await File(path).readAsString();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't read that subtitle file.")),
      );
      return;
    }

    final entries = parseSrt(text);
    if (entries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subtitle cues found in that file.')),
      );
      return;
    }

    await ref.read(projectDatabaseProvider).insertTextOverlays([
      for (final e in entries)
        TextOverlaysCompanion.insert(
          id: const Uuid().v4(),
          projectId: projectId,
          content: e.text,
          startMs: Value(e.startMs),
          endMs: e.endMs,
        ),
    ]);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Imported ${entries.length} subtitle${entries.length == 1 ? '' : 's'}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectId = widget.projectId;
    final clipsAsync = projectId == null ? null : ref.watch(clipsProvider(projectId));
    final aspectRatio = projectId == null ? 9 / 16 : ref.watch(projectProvider(projectId)).value?.aspectRatio ?? 9 / 16;

    final project = projectId == null ? null : ref.watch(projectProvider(projectId)).value;
    final mode = EditMode.fromName(project?.mode);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(project?.name ?? 'Editor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            // Scales down rather than overflowing when the bar is crowded.
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: ModeChip(mode, dense: true)),
          ],
        ),
        actions: [
          if (projectId != null) ...[
            // Narrow phones (portrait): Assistant and Frame shape move into a
            // "more" menu so the bar never overflows; wide screens show them.
            if (MediaQuery.sizeOf(context).width >= 480) ...[
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: 'Assistant',
                onPressed: () => _openAssistant(projectId),
              ),
              PopupMenuButton<double>(
                icon: const Icon(Icons.aspect_ratio),
                tooltip: 'Frame shape',
                onSelected: (ratio) => ref.read(projectDatabaseProvider).setAspectRatio(projectId, ratio),
                itemBuilder: (context) => [
                  for (final (label, ratio) in frameShapes)
                    CheckedPopupMenuItem(
                      value: ratio,
                      checked: (ratio - aspectRatio).abs() < 0.001,
                      child: Text(label),
                    ),
                ],
              ),
            ],
            HistoryActions(projectId: projectId),
            if (MediaQuery.sizeOf(context).width < 480)
              PopupMenuButton<double>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More',
                padding: EdgeInsets.zero,
                // -1 = Assistant; any other value is a frame shape.
                onSelected: (v) => v < 0
                    ? _openAssistant(projectId)
                    : ref.read(projectDatabaseProvider).setAspectRatio(projectId, v),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: -1,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.auto_awesome),
                      title: Text('Assistant'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    enabled: false,
                    height: 28,
                    child: Text('Frame shape', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                  ),
                  for (final (label, ratio) in frameShapes)
                    CheckedPopupMenuItem(
                      value: ratio,
                      checked: (ratio - aspectRatio).abs() < 0.001,
                      child: Text(label),
                    ),
                ],
              ),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 10),
            // Very narrow phones (or big system text): an icon-only button.
            child: MediaQuery.sizeOf(context).width < 400
                ? IconButton.filled(
                    tooltip: 'Export',
                    onPressed: projectId == null
                        ? null
                        : () => Navigator.pushNamed(context, AppRouter.export, arguments: projectId),
                    icon: const Icon(Icons.ios_share, size: 20),
                  )
                : FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: projectId == null
                        ? null
                        : () => Navigator.pushNamed(context, AppRouter.export, arguments: projectId),
                    child: const Text('Export'),
                  ),
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
              data: (clips) => _buildBody(projectId!, clips, aspectRatio, mode, project),
            ),
    );
  }

  Widget _buildBody(String projectId, List<Clip> clips, double aspectRatio, EditMode mode, Project? project) {
    final layout = layoutTimeline(clips);
    final totalMs = layout.isEmpty ? 0 : layout.last.endMs;

    // Performance (docs/PERFORMANCE.md, FACTS F-71): this body must not
    // rebuild on every playhead tick. It only watches *which clip* is under
    // the playhead; the widgets that need the exact millisecond (text
    // layer, transition blend, scrub bar) watch it in their own small
    // `Consumer`s below.
    final currentClipId = ref.watch(
      playheadMsProvider.select((ms) => positionAt(layout, ms)?.clip.id),
    );
    final currentPos = layout.where((pos) => pos.clip.id == currentClipId).firstOrNull;

    final selectedId = ref.watch(selectedClipIdProvider);
    final selectedClip = selectedId == null ? null : clips.where((c) => c.id == selectedId).firstOrNull;

    final audioTrack = ref.watch(audioTrackProvider(projectId)).value;
    final audioPanelOpen = ref.watch(audioPanelOpenProvider);

    final textOverlays = ref.watch(textOverlaysProvider(projectId)).value ?? [];
    final textPanelOpen = ref.watch(textPanelOpenProvider);
    final selectedTextOverlayId = ref.watch(selectedTextOverlayIdProvider);
    final selectedTextOverlay =
        selectedTextOverlayId == null ? null : textOverlays.where((t) => t.id == selectedTextOverlayId).firstOrNull;

    final voiceOvers = ref.watch(voiceOversProvider(projectId)).value ?? const <VoiceOver>[];
    final selectedVoiceId = ref.watch(selectedVoiceOverIdProvider);
    final selectedVoice = selectedVoiceId == null ? null : voiceOvers.where((v) => v.id == selectedVoiceId).firstOrNull;
    // Opening any other panel closes the voice-over panel.
    ref.listen(selectedClipIdProvider, (_, id) {
      if (id != null) ref.read(selectedVoiceOverIdProvider.notifier).state = null;
    });
    ref.listen(textPanelOpenProvider, (_, open) {
      if (open) ref.read(selectedVoiceOverIdProvider.notifier).state = null;
    });
    ref.listen(audioPanelOpenProvider, (_, open) {
      if (open) ref.read(selectedVoiceOverIdProvider.notifier).state = null;
    });

    // While a clip's trim/filter panel is open the music and text lanes are
    // hidden: they aren't needed for clip edits, and the preview needs the
    // room. (Same condition as the panel switch further down.)
    final clipPanelOpen = selectedVoice == null &&
        !(textPanelOpen && selectedTextOverlay != null) &&
        !(audioPanelOpen && audioTrack != null) &&
        selectedClip != null;

    final preview = RepaintBoundary(
      child: ColoredBox(
        color: AppColors.canvas,
        child: Center(
          // F6: the canvas has the project's frame shape, so what is
          // inside it is what the export renders. Text positions are
          // fractions of this canvas, exactly as `drawtext` treats
          // them as fractions of the output frame.
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRect(
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPreviewArea(currentPos, layout, audioTrack, mode, voiceOvers),
                    Consumer(
                      builder: (context, ref, _) => TextOverlayLayer(
                        overlays: textOverlays,
                        playheadMs: ref.watch(playheadMsProvider),
                      ),
                    ),
                    if (_showGuides) const SafeZonesOverlay(),
                    _CompareControls(clip: currentPos?.clip),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed, compact height: the preview gets the rest of the screen, so
        // looks and edits are big enough to judge.
        SizedBox(
          height: 76,
          child: Container(
            color: AppColors.surface,
            child: RepaintBoundary(
              child: TimelineStrip(projectId: projectId, clips: clips, onAdd: _showImportSheet),
            ),
          ),
        ),
        if (!clipPanelOpen)
          AudioTrackLane(
            track: audioTrack,
            totalMs: totalMs,
            onImport: _showAudioImportSheet,
          ),
        if (!clipPanelOpen) TextOverlayStrip(overlays: textOverlays, totalMs: totalMs),
        if (!clipPanelOpen) VoiceOverLane(voiceOvers: voiceOvers, totalMs: totalMs),
        Consumer(
          builder: (context, ref, _) => TimelineScrubBar(
            layout: layout,
            totalMs: totalMs,
            playheadMs: ref.watch(playheadMsProvider),
            snapEnabled: ref.watch(snapScrubProvider),
            onScrub: (ms) => seekTimeline(ref, layout, ms),
          ),
        ),
        PlayheadControls(clips: clips),
        if (selectedVoice != null)
          _ScrollablePanel(child: VoiceOverPanel(voiceOver: selectedVoice))
        else if (textPanelOpen && selectedTextOverlay != null)
          _ScrollablePanel(
            child: TextOverlayPanel(overlay: selectedTextOverlay, totalTimelineMs: totalMs),
          )
        else if (audioPanelOpen && audioTrack != null)
          _ScrollablePanel(
            child: AudioTrackPanel(track: audioTrack, totalTimelineMs: totalMs),
          )
        else if (selectedClip != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ClipPanelTabBar(
                selected: _clipPanelTab,
                onChanged: (tab) => setState(() => _clipPanelTab = tab),
                onDone: () => ref.read(selectedClipIdProvider.notifier).state = null,
              ),
              _ScrollablePanel(
                child: switch (_clipPanelTab) {
                  _ClipPanelTab.trim => TrimPanel(clip: selectedClip, allClips: clips),
                  _ClipPanelTab.filters => FilterPanel(clip: selectedClip),
                  _ClipPanelTab.effects => EffectsPanel(clip: selectedClip),
                  _ClipPanelTab.background => BackgroundPanel(clip: selectedClip),
                },
              ),
            ],
          )
        else
          ToolDock(
            tools: [
              DockTool(Icons.add_photo_alternate_outlined, 'Media', _isImporting ? null : _showImportSheet,
                  busy: _isImporting),
              DockTool(Icons.title, textOverlays.isEmpty ? 'Text' : 'Text (${textOverlays.length})',
                  () => _addTextOverlay(projectId, totalMs)),
              DockTool(
                Icons.music_note_outlined,
                'Music',
                _isImportingAudio
                    ? null
                    : audioTrack == null
                        ? _showAudioImportSheet
                        : () {
                            ref.read(selectedClipIdProvider.notifier).state = null;
                            ref.read(textPanelOpenProvider.notifier).state = false;
                            ref.read(audioPanelOpenProvider.notifier).state = true;
                          },
                busy: _isImportingAudio,
                active: audioTrack != null,
              ),
              DockTool(Icons.auto_fix_high, 'AutoCut', () async {
                final choice = await showAutoCutSheet(context, projectId);
                if (!mounted || choice == null) return;
                await _runOnClipOrAll(
                  projectId,
                  choice == AutoCutChoice.silences ? SmartTool.removeSilences : SmartTool.splitScenes,
                  choice == AutoCutChoice.silences ? 'Remove silent pauses from…' : 'Split at scene changes in…',
                );
              }),
              DockTool(Icons.surround_sound_outlined, 'SFX', () => _addSoundEffect(projectId)),
              DockTool(Icons.mic_none_rounded, 'Voice', () {
                final scaffold = _scaffoldKey.currentState;
                if (scaffold != null) showVoiceRecorder(scaffold, projectId);
              }),
              DockTool(Icons.subtitles_outlined, 'Captions', _importSubtitles),
              DockTool(Icons.auto_awesome, 'Assistant', () => _openAssistant(projectId)),
              DockTool(Icons.lightbulb_outline, 'Tips', () => showModeGuide(context, mode)),
            ],
            proTools: !mode.isPro
                ? const []
                : [
                    DockTool(
                      Icons.record_voice_over_outlined,
                      'Speech',
                      () => _enhanceSpeech(projectId),
                      active: clips.any((c) => c.enhanceSpeech),
                    ),
                    DockTool(
                      Icons.graphic_eq,
                      'Jump cuts',
                      _runningTool != null
                          ? null
                          : () => _runOnClipOrAll(projectId, SmartTool.removeSilences, 'Remove silent pauses from…'),
                      busy: _runningTool == SmartTool.removeSilences,
                    ),
                    DockTool(
                      Icons.movie_filter_outlined,
                      'Scenes',
                      _runningTool != null
                          ? null
                          : () => _runOnClipOrAll(projectId, SmartTool.splitScenes, 'Split at scene changes in…'),
                      busy: _runningTool == SmartTool.splitScenes,
                    ),
                    DockTool(
                      Icons.equalizer,
                      'Loudness',
                      _runningTool != null
                          ? null
                          : () => _runSmartTool(projectId, SmartTool.balanceLoudness, const ClipScope.all()),
                      busy: _runningTool == SmartTool.balanceLoudness,
                    ),
                    DockTool(
                      Icons.auto_fix_high,
                      'Polish',
                      _runningTool != null
                          ? null
                          : () => _runSmartTool(projectId, SmartTool.autoPolish, const ClipScope.all()),
                      busy: _runningTool == SmartTool.autoPolish,
                    ),
                    DockTool(
                      Icons.format_list_numbered,
                      'Chapters',
                      () => showChaptersSheet(
                        context,
                        clipStartsMs: [for (final p in layout) p.startMs],
                        totalMs: totalMs,
                        titles: [for (final o in textOverlays) (o.startMs, o.content)],
                      ),
                    ),
                    DockTool(
                      Icons.volume_down_outlined,
                      'Ducking',
                      project == null
                          ? null
                          : () async {
                              final on = !project.duckMusic;
                              await ref.read(projectDatabaseProvider).setDuckMusic(projectId, on);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    on ? 'Ducking on: music dips under clip sound in the export.' : 'Ducking off.'),
                              ));
                            },
                      active: project?.duckMusic ?? false,
                    ),
                    DockTool(
                      Icons.grid_on_outlined,
                      'Safe zones',
                      () => setState(() => _showGuides = !_showGuides),
                      active: _showGuides,
                    ),
                  ],
          ),
      ],
    );

    // SafeArea(bottom): Android 15 draws apps edge-to-edge, so without it the
    // last panel row sits under the system navigation bar.
    //
    // The controls under the preview (timeline, lanes, scrub bar, panel or
    // tool dock) can be taller than the screen — always in landscape, and in
    // portrait whenever a panel is open on a short phone. So they live in a
    // scroll view with a height cap, and the preview takes what is left:
    //  * portrait: preview on top (at least ~1/3 of the height), controls below;
    //  * landscape: preview on the left, controls in a column on the right.
    return SafeArea(
      top: false,
      child: LayoutBuilder(builder: (context, box) {
        // Decide from the *screen* shape, not the box: the on-screen keyboard
        // shrinks the box (Scaffold resizes for it), which used to flip a
        // portrait phone into the landscape layout the moment a text field
        // got focus — that rebuild dropped focus, closed the keyboard and
        // made text overlays impossible to type into.
        final screen = MediaQuery.sizeOf(context);
        if (screen.width > screen.height) {
          return Row(children: [
            Expanded(child: preview),
            Container(
              width: math.min(460.0, box.maxWidth * 0.5),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(left: BorderSide(color: AppColors.line)),
              ),
              child: SingleChildScrollView(child: controls),
            ),
          ]);
        }
        return Column(children: [
          Expanded(child: preview),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: box.maxHeight * 0.68),
            child: SingleChildScrollView(child: controls),
          ),
        ]);
      }),
    );
  }

  Widget _buildPreviewArea(
    TimelinePosition? currentPos,
    List<TimelinePosition> layout,
    AudioTrack? audioTrack,
    EditMode mode,
    List<VoiceOver> voiceOvers,
  ) {
    if (_importError != null) {
      return Center(
        child: Text(
          _importError!,
          style: const TextStyle(color: Colors.redAccent),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (currentPos == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(mode.icon, color: mode.color, size: 32),
            const SizedBox(height: 10),
            const Text('Add your first clip',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              mode.lockedAspect == null
                  ? 'Your first video sets the frame shape.'
                  : 'This ${mode.label} project stays ${mode == EditMode.youtube ? '16:9' : '9:16'}.',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _isImporting ? null : _showImportSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add media'),
            ),
          ]),
        ),
      );
    }

    final clip = currentPos.clip;
    final isPhoto = clip.isPhoto;

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

    final currentIndex = layout.indexWhere((pos) => pos.clip.id == clip.id);
    final hasNext = currentIndex >= 0 && currentIndex < layout.length - 1;

    return _TransitionBlend(
      transitionOut: hasNext ? clip.transitionOut : 'cut',
      boundaryMs: currentPos.endMs,
      nextThumbnailUri: hasNext ? layout[currentIndex + 1].clip.thumbnailUri : null,
      child: _MotionLayer(
        effect: clip.effect,
        strength: clip.effectStrength,
        startMs: currentPos.startMs,
        endMs: currentPos.endMs,
        child: Consumer(
          builder: (context, ref, _) => Stack(fit: StackFit.expand, children: [
            VideoPreviewPlayer(
            key: ValueKey(clip.id),
            voiceOvers: voiceOvers,
            effectStyle: effectStyle(clip.effect, clip.effectStrength),
            chromaKey: ChromaKeySpec.tryParse(clip.keyJson),
            compareSplit: ref.watch(compareSplitProvider),
            asset: asset,
            trimStartMs: isPhoto ? null : clip.trimStartMs,
            trimEndMs: isPhoto ? null : clip.trimEndMs,
            clipVolume: clip.volume,
            muted: clip.muted,
            audioTrack: audioTrack,
            timelineStartMs: currentPos.startMs,
            onPositionTick: (ms) => ref.read(playheadMsProvider.notifier).state = ms,
            brightness: clip.brightness,
            contrast: clip.contrast,
            saturation: clip.saturation,
            look: clip.look,
            lookStrength: clip.lookStrength,
            turns: clip.turns,
            flipH: clip.flipH,
            flipV: clip.flipV,
            speed: clip.effectiveSpeed,
            fitMode: clip.fitMode,
          ),
            // Glow sits over the finished picture (after look / stylise),
            // before motion — the export's order.
            GlowOverlay(effectId: clip.effect, strength: clip.effectStrength),
          ]),
        ),
      ),
    );
  }
}

/// Before/after compare controls over the preview: a toggle button (only
/// when the clip under the playhead has a look or colour adjustment) and,
/// while comparing, horizontal drag anywhere on the preview moves the
/// divider.
class _CompareControls extends ConsumerWidget {
  final Clip? clip;
  const _CompareControls({required this.clip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = clip;
    final hasEdit = c != null &&
        ((c.look != null && c.look != 'none') ||
            !isNeutralFilter(brightness: c.brightness, contrast: c.contrast, saturation: c.saturation));
    final split = ref.watch(compareSplitProvider);
    if (!hasEdit) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (split != null)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (d) => ref.read(compareSplitProvider.notifier).state =
                  (d.localPosition.dx / constraints.maxWidth).clamp(0.02, 0.98),
            ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Material(
              color: split != null ? Theme.of(context).colorScheme.primary : Colors.black54,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => ref.read(compareSplitProvider.notifier).state = split == null ? 0.5 : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.compare, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(split == null ? 'Compare' : 'Done',
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Caps a bottom panel at 40% of the screen height and lets its content
/// scroll inside that, so a tall panel (filters, music) can never push the
/// editor column past the bottom of the screen on a short phone.
class _ScrollablePanel extends StatelessWidget {
  final Widget child;
  const _ScrollablePanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Landscape: the whole side column scrolls, so no inner cap is needed.
    if (size.width > size.height) return child;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.4),
      child: SingleChildScrollView(child: child),
    );
  }
}

/// Blends the live preview toward the next clip's thumbnail as the playhead
/// nears a clip boundary (see `models/transition_x.dart` for why this is a
/// thumbnail approximation and not a real two-video transition).
///
/// The tree shape never changes — [child] is always the first child of the
/// same `Stack` — so the player underneath keeps its state (and its video
/// controller) when a transition starts or ends. It is also the only part
/// of the preview that rebuilds per playhead tick.
class _TransitionBlend extends ConsumerWidget {
  final String transitionOut;
  final int boundaryMs;
  final String? nextThumbnailUri;
  final Widget child;

  const _TransitionBlend({
    required this.transitionOut,
    required this.boundaryMs,
    required this.nextThumbnailUri,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(playheadMsProvider.select(
      (ms) => transitionPreviewAt(
        transitionOut: transitionOut,
        playheadMs: ms,
        boundaryMs: boundaryMs,
      ),
    ));
    final next = nextThumbnailUri;
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: preview.currentOpacity, child: child),
        if (preview.nextOpacity > 0 && next != null)
          Opacity(
            opacity: preview.nextOpacity,
            child: Image.file(
              File(next),
              fit: BoxFit.contain,
              cacheWidth: 720,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        // Flash transition: white over both.
        IgnorePointer(
          child: Opacity(
            opacity: preview.white.clamp(0.0, 1.0),
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Which sub-panel `EditorScreen` shows for a selected clip. See
/// `_EditorScreenState._clipPanelTab`'s doc comment.
enum _ClipPanelTab { trim, filters, effects, background }

/// Small two-way switch above the selected-clip panel. Deliberately
/// plain (`TextButton`s, not a full `TabBar`) to match the weight of
/// everything else docked in this bottom strip — a `TabBar` would read
/// as a bigger piece of chrome than a two-option toggle warrants here.
class _ClipPanelTabBar extends StatelessWidget {
  final _ClipPanelTab selected;
  final ValueChanged<_ClipPanelTab> onChanged;

  /// Closes the clip panel and brings the tool bar back.
  final VoidCallback onDone;

  const _ClipPanelTabBar({required this.selected, required this.onChanged, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    Widget tab(_ClipPanelTab tab, String label) {
      final isActive = tab == selected;
      return Expanded(
        child: TextButton(
          onPressed: () => onChanged(tab),
          style: TextButton.styleFrom(
            foregroundColor: isActive ? accent : AppColors.textDim,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: const RoundedRectangleBorder(),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.normal),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2,
              width: isActive ? 18 : 0,
              color: accent,
            ),
          ]),
        ),
      );
    }

    return Container(
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          tab(_ClipPanelTab.trim, 'Edit'),
          tab(_ClipPanelTab.filters, 'Filters'),
          tab(_ClipPanelTab.effects, 'Effects'),
          tab(_ClipPanelTab.background, 'Background'),
          IconButton(
            tooltip: 'Done',
            visualDensity: VisualDensity.compact,
            onPressed: onDone,
            icon: const Icon(Icons.check_rounded, color: AppColors.ember),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Preview of a motion effect (`models/effect_x.dart`): zoom/pan/shake via
/// a `Transform`, flash as a white overlay — the same [motionAt] formula
/// the export turns into `scale`/`crop`/`fade`. The tree shape never
/// changes (identity transform when there is no effect), so the player
/// below keeps its state. Only this small widget rebuilds per playhead tick.
class _MotionLayer extends ConsumerWidget {
  final String? effect;
  final double strength;
  final int startMs;
  final int endMs;
  final Widget child;

  const _MotionLayer({
    required this.effect,
    required this.strength,
    required this.startMs,
    required this.endMs,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = effectById(effect)?.motion;
    var frame = const MotionFrame();
    if (kind != null) {
      final ms = ref.watch(playheadMsProvider);
      frame = motionAt(kind, (ms - startMs) / 1000, (endMs - startMs) / 1000, strength);
    }
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth.isFinite ? c.maxWidth : 0.0;
      final h = c.maxHeight.isFinite ? c.maxHeight : 0.0;
      return Stack(fit: StackFit.expand, children: [
        Transform.translate(
          offset: Offset(-frame.dx * w, -frame.dy * h),
          child: Transform.scale(scale: frame.scale, child: child),
        ),
        IgnorePointer(
          child: Opacity(
            opacity: frame.flash.clamp(0.0, 1.0),
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ]);
    });
  }
}
