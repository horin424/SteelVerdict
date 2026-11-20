import 'dart:async';

import '../../core/utils/date_utils.dart';
import '../../models/user_model.dart';

/// What happened when the player watched an ad for tickets.
enum AdTicketOutcome {
  /// The server added the tickets.
  granted,

  /// The ad was watched to the end, but the tickets hadn't arrived when the
  /// app stopped waiting; the server still adds them when Google's
  /// confirmation comes.
  pending,

  /// Today's 20 ads were already used, so no ad was shown.
  dailyLimit,

  /// The ad wasn't shown, or was closed before the end.
  notWatched,

  /// Something failed (no sign-in, no network).
  failed,
}

/// Ad tickets: +2 for each rewarded ad watched to the end, at most 20 ads a
/// day (Japan time). The server adds them when Google confirms the ad
/// (functions/src/tickets/admobRewardCallback.ts, AdMob server-side
/// verification). The app only shows the ad with the player's uid and
/// [purpose], then waits for the user document to show the tickets. Before,
/// the app called earnAdTickets after the ad, which anyone could call without
/// one.
class AdTickets {
  AdTickets._();

  static const int perAd = 2;
  static const int maxAdsPerDay = 20;

  /// Sent with the ad as custom_data: the server adds tickets only for this.
  /// The scenario unlock's ads send nothing and add no tickets.
  static const String purpose = 'tickets';

  /// How long the app waits for the server after the ad.
  static const Duration grantWait = Duration(seconds: 20);

  /// Ads that may still add tickets today.
  static int adsLeftToday(UserModel user, {DateTime? now}) {
    final today = GameDateUtils.japanDateString(now ?? DateTime.now());
    final used = user.adTicketClaimsDate == today ? user.adTicketClaimsCount : 0;
    return (maxAdsPerDay - used).clamp(0, maxAdsPerDay);
  }

  /// True once [user] counts an ad more than [before] did: the server added
  /// the tickets (its date or its number of ads changed).
  static bool granted(UserModel before, UserModel? user) =>
      user != null &&
      (user.adTicketClaimsDate != before.adTicketClaimsDate ||
          user.adTicketClaimsCount != before.adTicketClaimsCount);

  /// Waits until [user] (the user document's updates) shows the tickets.
  /// False after [timeout], or if the updates end or fail first. Stops
  /// listening either way.
  static Future<bool> waitForGrant(
    Stream<UserModel?> user,
    UserModel before, {
    Duration timeout = grantWait,
  }) {
    final done = Completer<bool>();
    void finish(bool value) {
      if (!done.isCompleted) done.complete(value);
    }

    final timer = Timer(timeout, () => finish(false));
    final subscription = user.listen(
      (u) {
        if (granted(before, u)) finish(true);
      },
      onError: (Object _) => finish(false),
      onDone: () => finish(false),
    );
    return done.future.whenComplete(() {
      timer.cancel();
      subscription.cancel();
    });
  }
}
