typedef RewardCallback = void Function(int amount, String type);

abstract class AdService {
  /// Load a rewarded ad.
  Future<void> loadRewardedAd();

  /// Show the loaded rewarded ad. Returns true if reward was granted.
  ///
  /// With [serverUserId], Google also tells the server about the reward
  /// (AdMob server-side verification, admobRewardCallback), with that uid
  /// and [serverCustomData]. The ad tickets come only that way.
  Future<bool> showRewardedAd({
    RewardCallback? onRewarded,
    String? serverUserId,
    String? serverCustomData,
  });

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
