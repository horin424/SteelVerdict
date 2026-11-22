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
  // The daily AI limits carry the limit: err_ai_free_limit:30
  if (raw.startsWith('err_ai_free_limit:')) {
    return l10n.errAiFreeLimit(raw.split(':').last);
  }
  if (raw.startsWith('err_ai_daily_limit:')) {
    return l10n.errAiDailyLimit(raw.split(':').last);
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
    case 'err_pack_already_chosen':
      return l10n.errPackAlreadyChosen;
    case 'err_pack_not_owned':
      return l10n.errPackNotOwned;
    case 'err_pack_choice_failed':
      return l10n.errPackChoiceFailed;
    case 'err_chronicle_failed':
      return l10n.errChronicleFailed;
    case 'err_race_save_failed':
      return l10n.errRaceSaveFailed;
    case 'err_no_race_found':
      return l10n.errNoRaceFound;
    case 'err_race_incomplete':
      return l10n.errRaceIncomplete;
    case 'err_skip_no_tickets':
      return l10n.skipAdNoTickets;
    case 'err_ai_app_limit':
      return l10n.errAiAppLimit;

    // Codes that already existed before this helper.
    case 'content_filter_blocked':
      return l10n.contentFilterBlocked;
    case 'battle_failed_retry':
      return l10n.battleFailedRetry;
    case 'mode_locked_epic':
      return l10n.gameModeEpicRequires;
    case 'mode_locked_boss':
      return l10n.gameModeBossRequires;
    case 'battle_sign_in_required':
      return l10n.battleSignInRequired;

    default:
      return raw;
  }
}

/// The server's daily AI limits (functions/src/limits) refuse a battle or a
/// chronicle with a message like "DAILY_FREE_LIMIT:30": the limit that was
/// reached, and its number. Returns the code [localizedError] shows for it
/// ("err_ai_free_limit:30"), or null when the message is not one of them.
String? aiLimitError(String? serverMessage) {
  final match = RegExp(r'\b(DAILY_FREE_LIMIT|DAILY_AI_LIMIT|APP_AI_LIMIT):(\d+)')
      .firstMatch(serverMessage ?? '');
  if (match == null) return null;
  final count = match.group(2)!;
  switch (match.group(1)) {
    case 'DAILY_FREE_LIMIT':
      return 'err_ai_free_limit:$count';
    case 'DAILY_AI_LIMIT':
      return 'err_ai_daily_limit:$count';
    default:
      return 'err_ai_app_limit';
  }
}
