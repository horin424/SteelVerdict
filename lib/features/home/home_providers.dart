import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_providers.dart';
import '../../services/ads/ad_service.dart';
import '../../services/ads/admob_ad_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../core/utils/date_utils.dart';
import '../splash/splash_providers.dart';

// Analytics service provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// Ad service provider
final adServiceProvider = Provider<AdService>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return AdMobAdService(remoteConfigService: remoteConfig);
});

// Ticket count provider (from user model)
final ticketCountProvider = FutureProvider<int>((ref) async {
  final userModel = await ref.watch(currentUserModelProvider.future);
  return userModel?.ticketCount ?? 0;
});

// Daily reward provider - checks if daily reward is available
final dailyRewardAvailableProvider = FutureProvider<bool>((ref) async {
  final userModel = await ref.watch(currentUserModelProvider.future);
  if (userModel == null) return false;
  // lastDailyRewardAt is null = never claimed = available
  if (userModel.lastDailyRewardAt == null) return true;
  return !GameDateUtils.isToday(userModel.lastDailyRewardAt!);
});

// Home controller state
class HomeControllerState {
  final bool isClaimingReward;
  final bool isWatchingAd;
  final String? message;

  const HomeControllerState({
    this.isClaimingReward = false,
    this.isWatchingAd = false,
    this.message,
  });

  HomeControllerState copyWith({
    bool? isClaimingReward,
    bool? isWatchingAd,
    String? message,
  }) {
    return HomeControllerState(
      isClaimingReward: isClaimingReward ?? this.isClaimingReward,
      isWatchingAd: isWatchingAd ?? this.isWatchingAd,
      message: message,
    );
  }
}

class HomeController extends StateNotifier<HomeControllerState> {
  final Ref _ref;

  HomeController(this._ref) : super(const HomeControllerState());

  Future<bool> claimDailyReward() async {
    state = state.copyWith(isClaimingReward: true);
    try {
      // Must go through Cloud Function — Firestore rules block direct ticket writes
      final callable = FirebaseFunctions.instance.httpsCallable('claimDailyReward');
      final result = await callable.call();
      final data = result.data as Map<String, dynamic>;
      final ticketsAdded = (data['ticketsAdded'] as num?)?.toInt() ?? 3;

      final analytics = _ref.read(analyticsServiceProvider);
      await analytics.logTicketEarned(ticketsAdded, 'daily_reward');

      _ref.invalidate(currentUserModelProvider);
      state = state.copyWith(
        isClaimingReward: false,
        message: 'Claimed $ticketsAdded daily tickets!',
      );
      return true;
    } on FirebaseFunctionsException catch (e) {
      final msg = e.code == 'already-exists'
          ? 'Already claimed today!'
          : 'Failed to claim reward.';
      state = state.copyWith(isClaimingReward: false, message: msg);
      return false;
    } catch (e) {
      state = state.copyWith(
        isClaimingReward: false,
        message: 'Failed to claim reward.',
      );
      return false;
    }
  }

  Future<bool> watchAdForTickets() async {
    state = state.copyWith(isWatchingAd: true);
    try {
      final adService = _ref.read(adServiceProvider);
      await adService.loadRewardedAd();
      final rewarded = await adService.showRewardedAd();

      if (rewarded) {
        // Must go through Cloud Function — Firestore rules block direct ticket writes
        final callable = FirebaseFunctions.instance.httpsCallable('earnAdTickets');
        await callable.call();

        final analytics = _ref.read(analyticsServiceProvider);
        await analytics.logAdWatched('rewarded');
        await analytics.logTicketEarned(2, 'ad_reward');

        _ref.invalidate(currentUserModelProvider);
        state = state.copyWith(isWatchingAd: false, message: 'Earned 2 tickets!');
        return true;
      } else {
        state = state.copyWith(isWatchingAd: false, message: null);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isWatchingAd: false, message: 'Ad failed: $e');
      return false;
    }
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeControllerState>((ref) {
  return HomeController(ref);
});
