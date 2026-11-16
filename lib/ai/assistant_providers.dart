import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../export/export_engine.dart';
import 'command_planner.dart';
import 'media_analysis.dart';

/// The planner behind the assistant sheet. Override this provider to swap
/// in a different [AssistantPlanner] (e.g. a language-model one) without
/// touching the UI or the executor.
final assistantPlannerProvider = Provider<AssistantPlanner>((ref) => const LocalCommandPlanner());

/// FFmpeg-backed analysis for the smart tools (silences, scenes, loudness).
final mediaAnalyzerProvider = Provider<MediaAnalyzer>((ref) => FfmpegKitEngine());
