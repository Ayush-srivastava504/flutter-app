import 'package:flutter/material.dart';

import '../models/media_asset.dart';
import '../router/app_router.dart';
import '../services/media_import_service.dart';
import '../widgets/video_preview_player.dart';

/// Editor screen. Phase 2 wired up navigation/layout; Phase 3 (first
/// half) adds media import + single-clip preview, replacing the
/// placeholder preview box. The timeline (Phase 4), audio/text tools
/// (Phase 5–6), and transitions/filters (Phase 7) are still stubs.
class EditorScreen extends StatefulWidget {
  final String? projectId;

  const EditorScreen({super.key, required this.projectId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final MediaImportService _importService = MediaImportService();

  /// The clip currently shown in the preview. In Phase 3 this is just
  /// "whatever was imported most recently" — Phase 4 replaces this
  /// with "whatever the timeline playhead is over".
  MediaAsset? _previewAsset;
  bool _isImporting = false;
  String? _importError;

  Future<void> _importVideo() => _runImport(_importService.pickVideo);

  Future<void> _importPhoto() => _runImport(_importService.pickPhoto);

  Future<void> _runImport(Future<MediaAsset?> Function() pick) async {
    setState(() {
      _isImporting = true;
      _importError = null;
    });
    try {
      final asset = await pick();
      if (asset != null) {
        setState(() => _previewAsset = asset);
      }
    } catch (e) {
      setState(() => _importError = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: [
          TextButton(
            onPressed: widget.projectId == null
                ? null
                : () => Navigator.pushNamed(
                      context,
                      AppRouter.export,
                      arguments: widget.projectId,
                    ),
            child: const Text('Export'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: _buildPreviewArea(),
            ),
          ),
          // Phase 4: horizontal, zoomable, scrubbable timeline goes here.
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[900],
              alignment: Alignment.center,
              child: const Text(
                'Timeline (Phase 4)',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          // Phase 5–7: audio / text / transitions / filters toolbar.
          SafeArea(
            top: false,
            child: Container(
              height: 56,
              color: Colors.grey[850],
              alignment: Alignment.center,
              child: const Text(
                'Tools: Audio · Text · Transitions · Filters',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
        ],
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

  Widget _buildPreviewArea() {
    if (_importError != null) {
      return Text(
        _importError!,
        style: const TextStyle(color: Colors.redAccent),
        textAlign: TextAlign.center,
      );
    }

    final asset = _previewAsset;
    if (asset == null) {
      return const Text(
        'Tap + to import a clip or photo',
        style: TextStyle(color: Colors.white54),
      );
    }

    return VideoPreviewPlayer(asset: asset);
  }
}
