typedef RewardCallback = void Function(int amount, String type);

abstract class AdService {
  /// Load a rewarded ad.
  Future<void> loadRewardedAd();

  /// Show the loaded rewarded ad. Returns true if reward was granted.
  Future<bool> showRewardedAd({RewardCallback? onRewarded});

  /// Load an interstitial ad.
  Future<void> loadInterstitialAd();

  /// Show the loaded interstitial ad.
  Future<void> showInterstitialAd();

  /// Whether a rewarded ad is loaded and ready.
  bool get isRewardedAdLoaded;

  /// Whether an interstitial ad is loaded and ready.
  bool get isInterstitialAdLoaded;

  /// Dispose of all ads.
  void dispose();
}
