import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_provider.dart';
import '../screens/home_screen.dart';
import '../services/media_repair_service.dart';
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

  @override
  void initState() {
    super.initState();
    // P1 (`docs/FEATURE_PLAN_25.md` §1): once per launch, sweep every
    // clip/audio track still pointing at the OS-clearable cache dir
    // (pre-P1 imports, or an install upgrading from before P1) into the
    // documents dir. Fire-and-forget: it must never delay showing
    // onboarding/Home, and a failure here must never stop the app from
    // launching — see `MediaRepairService`.
    unawaited(_repairCachedMedia());
  }

  Future<void> _repairCachedMedia() async {
    try {
      final result = await MediaRepairService(ref.read(projectDatabaseProvider))
          .repairCachedMedia();
      developer.log('$result', name: 'MediaRepairService');
    } catch (_) {
      // Best-effort only; rows that didn't get repaired are exactly as
      // reliable (or not) as they were before P1 shipped.
    }
  }

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
