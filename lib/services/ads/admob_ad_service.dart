import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../remote_config/remote_config_service.dart';
import 'ad_service.dart';

class AdMobAdService implements AdService {
  final RemoteConfigService _remoteConfigService;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isRewardedLoaded = false;
  bool _isInterstitialLoaded = false;

  AdMobAdService({required RemoteConfigService remoteConfigService})
      : _remoteConfigService = remoteConfigService {
    MobileAds.instance.initialize();
  }

  String get _rewardedAdUnitId {
    final id = _remoteConfigService.getAdUnitId('rewarded');
    if (id.isNotEmpty) return id;
    // Test ad unit IDs
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  String get _interstitialAdUnitId {
    final id = _remoteConfigService.getAdUnitId('interstitial');
    if (id.isNotEmpty) return id;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return 'ca-app-pub-3940256099942544/1033173712';
  }

  @override
  Future<void> loadRewardedAd() async {
    if (_isRewardedLoaded) return; // Already loaded
    final completer = _AsyncCompleter<void>();
    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedLoaded = true;
            debugPrint('Rewarded ad loaded');
            completer.complete(null);
          },
          onAdFailedToLoad: (error) {
            _isRewardedLoaded = false;
            debugPrint('Rewarded ad failed to load: $error');
            completer.complete(null);
          },
        ),
      );
      await completer.future;
    } catch (e) {
      debugPrint('loadRewardedAd error: $e');
    }
  }

  @override
  Future<bool> showRewardedAd({RewardCallback? onRewarded}) async {
    if (_rewardedAd == null || !_isRewardedLoaded) {
      debugPrint('Rewarded ad not loaded');
      await loadRewardedAd();
      return false;
    }

    bool rewarded = false;
    final completer = _AsyncCompleter<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedLoaded = false;
        completer.complete(rewarded);
        loadRewardedAd(); // Pre-load next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedLoaded = false;
        completer.complete(false);
        loadRewardedAd();
      },
    );

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewarded = true;
          onRewarded?.call(reward.amount.toInt(), reward.type);
        },
      );
      return completer.future;
    } catch (e) {
      debugPrint('showRewardedAd error: $e');
      return false;
    }
  }

  @override
  Future<void> loadInterstitialAd() async {
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialLoaded = true;
            debugPrint('Interstitial ad loaded');
          },
          onAdFailedToLoad: (error) {
            _isInterstitialLoaded = false;
            debugPrint('Interstitial ad failed to load: $error');
          },
        ),
      );
    } catch (e) {
      debugPrint('loadInterstitialAd error: $e');
    }
  }

  @override
  Future<void> showInterstitialAd() async {
    if (_interstitialAd == null || !_isInterstitialLoaded) {
      debugPrint('Interstitial ad not loaded');
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        loadInterstitialAd(); // Pre-load next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        loadInterstitialAd();
      },
    );

    try {
      await _interstitialAd!.show();
    } catch (e) {
      debugPrint('showInterstitialAd error: $e');
    }
  }

  @override
  bool get isRewardedAdLoaded => _isRewardedLoaded;

  @override
  bool get isInterstitialAdLoaded => _isInterstitialLoaded;

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
  }
}

/// Simple async completer helper to avoid importing dart:async directly.
class _AsyncCompleter<T> {
  T? _value;
  bool _isCompleted = false;
  final List<void Function(T)> _listeners = [];

  void complete(T value) {
    _value = value;
    _isCompleted = true;
    for (final l in _listeners) {
      l(value);
    }
  }

  Future<T> get future async {
    if (_isCompleted) return _value as T;
    // Simple polling approach
    while (!_isCompleted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return _value as T;
  }
}
