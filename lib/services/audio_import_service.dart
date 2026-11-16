import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/audio_asset.dart';
import '../models/bundled_track.dart';
import 'audio_metadata_service.dart';
import 'media_storage_service.dart';

/// Turning a music file — from device storage, or from the bundled
/// royalty-free library — into an [AudioAsset] ready to attach to the
/// project as its background `AudioTrack`.
class AudioImportService {
  final AudioMetadataService _metadataService = AudioMetadataService();
  final MediaStorageService _storageService;

  AudioImportService({MediaStorageService? storageService})
      : _storageService = storageService ?? MediaStorageService();

  /// Opens the system file picker filtered to audio files. Returns null
  /// if the user cancels. `file_picker` (a project dependency since
  /// Phase 2) already ships an audio filter, so no new package was
  /// needed for this half.
  ///
  /// P1: some `file_picker` implementations also hand back a path in
  /// the OS-clearable cache dir (`docs/FACTS.md` F-50 covers the
  /// `image_picker` case; `file_picker`'s Android path can land in the
  /// same place), so this copies into documents the same way
  /// `MediaImportService.pickVideo`/`pickPhoto` do.
  Future<AudioAsset?> pickFromDevice() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final picked = result?.files.single;
    final path = picked?.path;
    if (path == null) return null;

    final persistedPath = await _storageService.persistToDocuments(path, consumeCacheSource: true);
    final duration =
        await _metadataService.readDuration(persistedPath) ?? Duration.zero;

    return AudioAsset(
      uri: persistedPath,
      duration: duration,
      displayName: picked!.name,
    );
  }

  /// Copies a bundled asset ([track]) out of the app bundle into a real
  /// file under app storage, and returns it as an [AudioAsset].
  ///
  /// A real on-disk file — not an `asset:`-scheme URI — is what the rest
  /// of the app already expects a `sourceUri` to be: `AudioTracks` rows
  /// get read by `just_audio`'s `setFilePath` and, eventually, the
  /// Phase 8 FFmpeg export pipeline, neither of which knows how to read
  /// out of the Flutter asset bundle directly. The copy only happens
  /// once per track id (skipped if it's already there from a previous
  /// import), so picking the same library track again doesn't churn disk.
  Future<AudioAsset> pickFromLibrary(BundledTrack track) async {
    final dir = await getApplicationDocumentsDirectory();
    final destDir = Directory(p.join(dir.path, 'bundled_audio'));
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final destPath =
        p.join(destDir.path, '${track.id}${p.extension(track.assetPath)}');
    final destFile = File(destPath);
    if (!await destFile.exists()) {
      final bytes = await rootBundle.load(track.assetPath);
      await destFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }

    return AudioAsset(
      uri: destPath,
      duration: Duration(milliseconds: track.durationMs),
      displayName: track.title,
    );
  }
}
