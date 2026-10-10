import 'package:flutter/material.dart';

import '../app/launch_gate.dart';
import '../screens/editor_screen.dart';
import '../screens/export_screen.dart';

/// Centralized navigation: Home/Projects -> Editor -> Export.
/// Kept as a plain Navigator (no go_router) for v1 simplicity;
/// swap for go_router later if deep-linking becomes a requirement.
class AppRouter {
  static const String home = '/';
  static const String editor = '/editor';
  static const String export = '/export';

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

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
