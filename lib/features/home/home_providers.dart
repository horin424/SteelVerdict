import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_providers.dart';
import 'ad_tickets.dart';
import '../../services/ads/ad_service.dart';
import '../../services/ads/admob_ad_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../core/constants/app_constants.dart';
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
  return !GameDateUtils.isTodayInJapan(userModel.lastDailyRewardAt!);
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

  /// Claims today's tickets; returns how many the server added (it depends on
  /// the plan: 1, 10, 15 or 50), or null if nothing was added.
  Future<int?> claimDailyReward() async {
    state = state.copyWith(isClaimingReward: true);
    try {
      // Must go through Cloud Function — Firestore rules block direct ticket writes
      final callable = FirebaseFunctions.instance.httpsCallable('claimDailyReward');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);
      final ticketsAdded = (data['ticketsAdded'] as num?)?.toInt() ??
          AppConstants.dailyTicketsFree;

      final analytics = _ref.read(analyticsServiceProvider);
      await analytics.logTicketEarned(ticketsAdded, 'daily_reward');

      _ref.invalidate(currentUserModelProvider);
      state = state.copyWith(
        isClaimingReward: false,
        message: 'Claimed $ticketsAdded daily tickets!',
      );
      return ticketsAdded;
    } on FirebaseFunctionsException catch (e) {
      final msg = e.code == 'already-exists'
          ? 'Already claimed today!'
          : 'Failed to claim reward.';
      state = state.copyWith(isClaimingReward: false, message: msg);
      return null;
    } catch (e) {
      state = state.copyWith(
        isClaimingReward: false,
        message: 'Failed to claim reward.',
      );
      return null;
    }
  }

  /// Shows a rewarded ad for tickets. The server adds them when Google
  /// confirms the ad was watched to the end (see AdTickets); this waits for
  /// them to show in the user document.
  Future<AdTicketOutcome> watchAdForTickets() async {
    state = state.copyWith(isWatchingAd: true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return AdTicketOutcome.failed;
      final firestore = _ref.read(firestoreServiceProvider);
      final before = await firestore.getUserData(uid);
      if (before == null) return AdTicketOutcome.failed;
      // Don't play an ad that can't add tickets any more today.
      if (AdTickets.adsLeftToday(before) == 0) return AdTicketOutcome.dailyLimit;

      final adService = _ref.read(adServiceProvider);
      await adService.loadRewardedAd();
      final rewarded = await adService.showRewardedAd(
        serverUserId: uid,
        serverCustomData: AdTickets.purpose,
      );
      if (!rewarded) return AdTicketOutcome.notWatched;

      final analytics = _ref.read(analyticsServiceProvider);
      await analytics.logAdWatched('rewarded');
      final arrived = await AdTickets.waitForGrant(firestore.watchUser(uid), before);
      _ref.invalidate(currentUserModelProvider);
      if (!arrived) return AdTicketOutcome.pending;
      await analytics.logTicketEarned(AdTickets.perAd, 'ad_reward');
      return AdTicketOutcome.granted;
    } catch (e) {
      return AdTicketOutcome.failed;
    } finally {
      state = state.copyWith(isWatchingAd: false, message: null);
    }
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeControllerState>((ref) {
  return HomeController(ref);
});
