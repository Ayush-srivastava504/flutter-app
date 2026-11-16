import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_provider.dart';
import '../data/project_database.dart';

/// Live voice-overs of a project, by start time (v11).
final voiceOversProvider = StreamProvider.family<List<VoiceOver>, String>((ref, projectId) {
  return ref.watch(projectDatabaseProvider).watchVoiceOvers(projectId);
});

/// The voice-over whose panel is open, or null.
final selectedVoiceOverIdProvider = StateProvider<String?>((ref) => null);
