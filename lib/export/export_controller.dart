import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/database_provider.dart';
import 'export_models.dart';
import 'export_notifier.dart';
import 'export_service.dart';
import 'gallery_share_service.dart';

enum ExportPhase { idle, running, done, failed }

class ExportState {
  final ExportPhase phase;
  final double progress;
  final String? outputPath;
  final bool savedToGallery;
  final String? saveError; // gallery save failed but the file exists
  final ExportFailure? failure;

  const ExportState({
    this.phase = ExportPhase.idle,
    this.progress = 0,
    this.outputPath,
    this.savedToGallery = false,
    this.saveError,
    this.failure,
  });

  ExportState copyWith({
    ExportPhase? phase,
    double? progress,
    String? outputPath,
    bool? savedToGallery,
    String? saveError,
    bool clearSaveError = false,
    ExportFailure? failure,
    bool clearFailure = false,
  }) =>
      ExportState(
        phase: phase ?? this.phase,
        progress: progress ?? this.progress,
        outputPath: outputPath ?? this.outputPath,
        savedToGallery: savedToGallery ?? this.savedToGallery,
        saveError: clearSaveError ? null : (saveError ?? this.saveError),
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

class ExportController extends StateNotifier<ExportState> {
  final ExportService _service;
  final ExportNotifier _notifier;
  final GalleryShareService _gallery;
  final String projectId;

  ExportController(this._service, this._notifier, this._gallery, this.projectId) : super(const ExportState());

  Future<void> start(ExportQuality quality) async {
    if (state.phase == ExportPhase.running) return;
    state = const ExportState(phase: ExportPhase.running);
    await _notifier.init();
    await WakelockPlus.enable(); // a locked screen can pause long renders on some devices
    try {
      final file = await _service.export(
        projectId: projectId,
        quality: quality,
        onProgress: (v) {
          if (!mounted) return;
          state = state.copyWith(progress: v);
          _notifier.progress(v);
        },
      );
      state = state.copyWith(phase: ExportPhase.done, progress: 1, outputPath: file.path);
      await _saveToGallery(); // deliverable: saved automatically, share offered next
      await _notifier.finished(success: true);
    } on ExportFailure catch (f) {
      if (!mounted) return;
      state = ExportState(phase: ExportPhase.failed, failure: f);
      await _notifier.finished(success: false, message: f.message);
    } catch (e) {
      if (!mounted) return;
      final f = ExportFailure(ExportFailureKind.unknown, failureMessage(ExportFailureKind.unknown), detail: '$e');
      state = ExportState(phase: ExportPhase.failed, failure: f);
      await _notifier.finished(success: false);
    } finally {
      await WakelockPlus.disable();
    }
  }

  Future<void> cancel() async {
    await _service.cancel();
    await _notifier.clear();
  }

  Future<void> saveToGallery() => _saveToGallery();

  Future<void> _saveToGallery() async {
    final path = state.outputPath;
    if (path == null) return;
    try {
      await _gallery.saveToGallery(path);
      if (mounted) state = state.copyWith(savedToGallery: true, clearSaveError: true);
    } on ExportFailure catch (f) {
      if (mounted) state = state.copyWith(saveError: f.message);
    }
  }

  Future<void> share() async {
    final path = state.outputPath;
    if (path != null) await _gallery.share(path);
  }

  void reset() => state = const ExportState();
}

final exportNotifierProvider = Provider<ExportNotifier>((ref) => ExportNotifier());
final galleryShareProvider = Provider<GalleryShareService>((ref) => GalleryShareService());

/// Not autoDispose: leaving the Export screen must not kill a running export.
final exportControllerProvider = StateNotifierProvider.family<ExportController, ExportState, String>(
  (ref, projectId) => ExportController(
    ExportService(db: ref.watch(projectDatabaseProvider)),
    ref.watch(exportNotifierProvider),
    ref.watch(galleryShareProvider),
    projectId,
  ),
);
