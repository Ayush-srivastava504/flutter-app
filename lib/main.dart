import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_prefs.dart';
import 'app/app_theme.dart';
import 'router/app_router.dart';
import 'services/analytics_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: VideoEditorApp()));
  // After the first frame is queued, so startup never waits on Firebase.
  // A no-op until android/app/google-services.json is added.
  AppPrefs().analyticsEnabled.then((on) => Analytics.instance.init(enabled: on));
}

class VideoEditorApp extends StatelessWidget {
  const VideoEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cliper',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.home,
    );
  }
}
