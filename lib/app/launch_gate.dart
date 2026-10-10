import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/home_screen.dart';
import '../widgets/common/state_views.dart';
import 'app_prefs.dart';
import 'onboarding_screen.dart';

final appPrefsProvider = Provider<AppPrefs>((ref) => AppPrefs());

/// First screen: shows onboarding once, then the project list.
class LaunchGate extends ConsumerStatefulWidget {
  const LaunchGate({super.key});

  @override
  ConsumerState<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends ConsumerState<LaunchGate> {
  late final Future<bool> _done = ref.read(appPrefsProvider).onboardingDone;
  bool _finishedNow = false;

  Future<void> _finish() async {
    await ref.read(appPrefsProvider).setOnboardingDone();
    if (mounted) setState(() => _finishedNow = true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _done,
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: LoadingStateView());
        if (snap.data! || _finishedNow) return const HomeScreen();
        return OnboardingScreen(onFinished: _finish);
      },
    );
  }
}
