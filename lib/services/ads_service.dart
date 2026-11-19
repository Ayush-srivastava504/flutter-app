import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob: a banner on Home and a rewarded ad that unlocks a 4K export.
///
/// * **Consent first.** [init] runs Google's UMP flow (the GDPR / US-state
///   message configured in AdMob → Privacy & messaging) and only starts the
///   Mobile Ads SDK when `canRequestAds()` allows it. Settings offers the
///   privacy-options form again when UMP says it is required.
/// * **IDs.** Ad unit IDs come from `--dart-define=ADMOB_BANNER_ID=…` and
///   `ADMOB_REWARDED_ID=…`; without them Google's public *test* units are
///   used (they always fill and never earn). The App ID lives in the
///   manifest, from `android/admob.properties` (see build.gradle.kts).
/// * **Never blocks the app.** No consent, no network or no fill ⇒ no
///   banner, and the 4K export is simply allowed (see [unlockWithRewardedAd]).
class Ads {
  Ads._();
  static final Ads instance = Ads._();

  static const _testBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const bannerUnitId = String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: _testBanner);
  static const rewardedUnitId = String.fromEnvironment('ADMOB_REWARDED_ID', defaultValue: _testRewarded);
  static bool get usingTestIds => bannerUnitId == _testBanner || rewardedUnitId == _testRewarded;

  /// True once consent allows ads and the SDK has started.
  final ValueNotifier<bool> ready = ValueNotifier(false);

  /// True when the user must be offered a way to change their consent.
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier(false);

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  Future<void>? _init;
  RewardedAd? _rewarded;
  bool _loadingRewarded = false;

  /// Call once the first screen is showing (the consent form needs it).
  Future<void> init() => _init ??= _doInit();

  Future<void> _doInit() async {
    if (!_supported) return;
    try {
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => ConsentForm.loadAndShowConsentFormIfRequired((err) {
          if (err != null) debugPrint('[ads] consent form: ${err.message}');
          if (!done.isCompleted) done.complete();
        }),
        (err) {
          debugPrint('[ads] consent update failed: ${err.message}');
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future;
      privacyOptionsRequired.value = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      // A previous session's consent still counts if this update failed.
      if (!await ConsentInformation.instance.canRequestAds()) {
        debugPrint('[ads] no consent to request ads');
        return;
      }
      await MobileAds.instance.initialize();
      ready.value = true;
      _loadRewarded();
    } catch (e) {
      debugPrint('[ads] init failed: $e');
    }
  }

  /// Settings → "Ad privacy choices".
  Future<void> showPrivacyOptions() async {
    final done = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((err) {
      if (err != null) debugPrint('[ads] privacy options: ${err.message}');
      done.complete();
    });
    await done.future;
    final can = await ConsentInformation.instance.canRequestAds();
    if (can && !ready.value) {
      _init = null;
      await init();
    }
  }

  void _loadRewarded() {
    if (!ready.value || _rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewarded = ad;
        },
        onAdFailedToLoad: (err) {
          _loadingRewarded = false;
          debugPrint('[ads] rewarded failed to load: ${err.message}');
        },
      ),
    );
  }

  /// Whether a rewarded ad can be shown right now.
  bool get rewardedAvailable => _rewarded != null;

  /// Shows the rewarded ad. Returns [RewardOutcome.earned] when the user
  /// watched it, [RewardOutcome.skipped] when they closed it early, and
  /// [RewardOutcome.unavailable] when no ad could be shown (callers then
  /// let the user continue — an empty ad inventory must not lock features).
  Future<RewardOutcome> unlockWithRewardedAd() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return RewardOutcome.unavailable;
    }
    _rewarded = null;
    final result = Completer<RewardOutcome>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(earned ? RewardOutcome.earned : RewardOutcome.skipped);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint('[ads] rewarded failed to show: ${err.message}');
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(RewardOutcome.unavailable);
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return result.future;
  }
}

enum RewardOutcome { earned, skipped, unavailable }
