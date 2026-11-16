import 'package:flutter/material.dart';

import '../app/launch_gate.dart';
import '../screens/audio_editor_screen.dart';
import '../screens/composer_screen.dart';
import '../screens/editor_screen.dart';
import '../screens/export_screen.dart';
import '../screens/photo_editor_screen.dart';
import '../screens/settings_screen.dart';

/// Centralized navigation: Home/Projects -> Editor -> Export.
/// Kept as a plain Navigator (no go_router) for v1 simplicity;
/// swap for go_router later if deep-linking becomes a requirement.
class AppRouter {
  static const String home = '/';
  static const String editor = '/editor';
  static const String export = '/export';
  static const String photo = '/photo';
  static const String audio = '/audio';
  static const String compose = '/compose';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const LaunchGate());

      case editor:
        final projectId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => EditorScreen(projectId: projectId),
        );

      case export:
        final projectId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ExportScreen(projectId: projectId),
        );

      case audio:
        return MaterialPageRoute(builder: (_) => AudioEditorScreen(audioId: settings.arguments as String));

      case compose:
        return MaterialPageRoute(builder: (_) => ComposerScreen(audioId: settings.arguments as String));

      case AppRouter.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case photo:
        final photoId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => PhotoEditorScreen(photoId: photoId));

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
