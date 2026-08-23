import '../l10n/app_localizations.dart';

/// Turns an internal error code into something a player can read.
///
/// Controllers store a sentinel like `err_create_race_first` rather than a
/// sentence, so the wording lives in the .arb files and follows the app's
/// language. Before this, controllers stored English sentences — often with a
/// raw `$e` spliced in — and the display layer passed them through untouched,
/// so a Japanese player got English plus a Dart or Firebase exception blob.
///
/// Anything unrecognised is returned as-is. That keeps older call sites working
/// and means a genuinely unexpected string still reaches the screen rather than
/// vanishing, but it also means a new raw English message would leak: add a
/// code here when you add one.
String localizedError(String raw, AppLocalizations l10n) {
  // Carries a value: err_not_enough_tickets:3
  if (raw.startsWith('err_not_enough_tickets:')) {
    final count = raw.split(':').last;
    return l10n.errNotEnoughTicketsNeed(count);
  }

  switch (raw) {
    case 'err_not_signed_in':
      return l10n.errNotSignedIn;
    case 'err_create_race_first':
      return l10n.errCreateRaceFirst;
    case 'err_matchmaking_failed':
      return l10n.errMatchmakingFailed;
    case 'err_submit_failed':
      return l10n.errSubmitFailed;
    case 'err_ad_not_completed':
      return l10n.errAdNotCompleted;
    case 'err_unlock_failed':
      return l10n.errUnlockFailed;
    case 'err_purchase_failed':
      return l10n.errPurchaseFailed;
    case 'err_chronicle_failed':
      return l10n.errChronicleFailed;
    case 'err_race_save_failed':
      return l10n.errRaceSaveFailed;
    case 'err_no_race_found':
      return l10n.errNoRaceFound;
    case 'err_skip_no_tickets':
      return l10n.skipAdNoTickets;

    // Codes that already existed before this helper.
    case 'content_filter_blocked':
      return l10n.contentFilterBlocked;
    case 'battle_failed_retry':
      return l10n.battleFailedRetry;
    case 'battle_sign_in_required':
      return l10n.battleSignInRequired;

    default:
      return raw;
  }
}
