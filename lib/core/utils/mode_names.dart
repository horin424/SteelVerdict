import '../l10n/app_localizations.dart';
import 'stat_names.dart' show prettifyStatKey;

/// Display names for game-mode and ticket-cost keys.
///
/// The admin panel renders these keys straight from Remote Config — the mode
/// instruction editor lists `practice` / `normal` / `tabletop`…, and the costs
/// editor lists whatever keys the live config holds. Both showed the raw key,
/// so the Japanese admin panel was full of English.
///
/// Reuses the strings players already see wherever one exists, so an operator
/// reading 「ノーマル」 in the costs editor sees the same word the player saw on
/// the mode screen.
String localizedModeName(String key, AppLocalizations l10n) {
  switch (key) {
    case 'practice':
      return l10n.gameModePractice;
    case 'normal':
      return l10n.gameModeNormal;
    case 'tabletop':
      return l10n.gameModeTabletop;
    case 'epic':
      return l10n.gameModeEpic;
    case 'boss':
      return l10n.gameModeBoss;
    case 'history_puzzle':
      return l10n.gameModeHistoryPuzzle;
    case 'war_history':
      return l10n.warHistoryTitle;

    // Cost-only keys. These have no mode screen of their own, so they get their
    // own strings. Claude and Gemini stay in Latin script deliberately: they are
    // product names, and an operator picking a model needs to recognise them.
    case 'pvp':
      return l10n.modePvp;
    case 'pvp_detail':
      return l10n.modePvpDetail;
    case 'normal_claude':
      return l10n.modeNormalClaude;
    case 'normal_gemini':
      return l10n.modeNormalGemini;

    default:
      // Remote Config can hold any key an operator invents. Prettify rather
      // than showing a raw `some_new_mode`, and accept that a brand-new key
      // reads in English until someone adds a string for it.
      return prettifyStatKey(key);
  }
}
