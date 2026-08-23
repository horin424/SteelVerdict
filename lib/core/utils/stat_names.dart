import '../l10n/app_localizations.dart';

/// Display names for worldview stat keys.
///
/// A worldview defines its own stat set, and the admin panel has no field for
/// stat *names* — only descriptions carry en/ja. So the app translates the keys
/// themselves. Keys the app knows get a proper translation; anything else is
/// prettified, because showing a raw `climb_rate` looks broken.
///
/// Lives here rather than in race_creation_screen because the admin scenario
/// editor renders the same keys in its enemy-stats section, and the two were
/// drifting: race creation translated six of them, the admin panel none.
String localizedStatName(String stat, AppLocalizations l10n) {
  switch (stat) {
    case 'strength':
      return l10n.statStrength;
    case 'intellect':
      return l10n.statIntellect;
    case 'skill':
      return l10n.statSkill;
    case 'magic':
      return l10n.statMagic;
    case 'art':
      return l10n.statArt;
    case 'life':
      return l10n.statLife;

    // Keys the live worldviews actually use. These previously fell through to
    // the prettifier, so the Japanese build showed WISDOM / TECHNOLOGY /
    // ARTISTRY in English next to 筋力 / 魔力 / 生命.
    //
    // They get their own keys rather than being mapped onto statIntellect /
    // statSkill / statArt. That mapping was tried and reverted (77d50b9): it
    // fixed Japanese but renamed the client's own stats in English — WISDOM
    // became INTELLECT — beside descriptions that still read "Tactical
    // planning…". Separate keys keep English exactly as the client wrote it.
    case 'wisdom':
      return l10n.statWisdom;
    case 'technology':
      return l10n.statTechnology;
    case 'artistry':
      return l10n.statArtistry;

    // Keys the aviation worldview (aces_high) defines. Without these the
    // Japanese build showed Durability / Maneuverability / Max Speed / Firepower
    // / Max Altitude / Acceleration in Latin beside 筋力 and 魔力 on other
    // worlds. 火力 / 最大高度 / 加速 follow the wording the client's own AI
    // output already uses.
    case 'durability':
      return l10n.statDurability;
    case 'maneuverability':
      return l10n.statManeuverability;
    case 'max_speed':
    case 'maxSpeed':
      return l10n.statMaxSpeed;
    case 'firepower':
      return l10n.statFirepower;
    case 'max_altitude':
    case 'maxAltitude':
      return l10n.statMaxAltitude;
    case 'acceleration':
      return l10n.statAcceleration;
    case 'luck':
      return l10n.statLuck;

    // legacy keys
    case 'attack':
      return l10n.statAttack;
    case 'defense':
      return l10n.statDefense;
    case 'speed':
      return l10n.statSpeed;
    case 'morale':
      return l10n.statMorale;
    case 'leadership':
      return l10n.statLeadership;

    default:
      // A worldview added from the admin panel can define any stat key it likes
      // (climb_rate, hullStrength, luck…). There is no translation for those,
      // but showing "climb_rate" raw looks broken — present it as "Climb Rate".
      //
      // Such a key still renders in English on the Japanese build. The only
      // real fix for that is for a worldview to carry localised stat names the
      // way it already carries localised descriptions, which is a data-model
      // change plus an admin field.
      return prettifyStatKey(stat);
  }
}

/// Turns an arbitrary stat key into something readable:
/// `climb_rate` and `climbRate` both become `Climb Rate`.
String prettifyStatKey(String key) {
  if (key.isEmpty) return key;
  final spaced = key
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (_) => ' ')
      .trim();
  return spaced
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
