import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class GameDateUtils {
  GameDateUtils._();

  /// The game's day: the date in Japan (UTC+9, no daylight saving), as
  /// midnight UTC of that date. The daily reward resets at midnight Japan time,
  /// the same day the server uses (functions/src/utils/japanDay.ts). The app
  /// used the phone's date and the server UTC, so from 0:00 to 9:00 in Japan
  /// the app offered a reward the server refused.
  static DateTime japanDate(DateTime moment) {
    final inJapan = moment.toUtc().add(const Duration(hours: 9));
    return DateTime.utc(inJapan.year, inJapan.month, inJapan.day);
  }

  /// Returns true if [moment] falls on the current game day (Japan time).
  static bool isTodayInJapan(DateTime moment, {DateTime? now}) =>
      japanDate(moment) == japanDate(now ?? DateTime.now());

  /// Returns true if the given [dateTime] is today (same calendar date).
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Formats a battle date to a readable string like "Mar 10, 2026 14:30",
  /// or "2026/03/10 14:30" in Japanese.
  static String formatBattleDate(DateTime dateTime, {String? localeName}) {
    final formatter = DateFormat(localeName == 'ja' ? 'yyyy/MM/dd HH:mm' : 'MMM d, yyyy HH:mm');
    return formatter.format(dateTime.toLocal());
  }

  /// Returns the remaining time before a PvP match expires.
  /// Returns Duration.zero if already expired.
  static Duration pvpTimeoutRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return Duration.zero;
    return expiresAt.difference(now);
  }

  /// Returns a human-readable relative time string in the app's language
  /// (it was English only, also on the Japanese screens).
  static String timeAgo(DateTime dateTime, AppLocalizations l10n, {DateTime? now}) {
    final difference = (now ?? DateTime.now()).difference(dateTime);

    if (difference.inSeconds < 60) {
      return l10n.timeJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.timeHoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.timeDaysAgo(difference.inDays);
    } else {
      return formatBattleDate(dateTime, localeName: l10n.localeName);
    }
  }

  /// Formats a duration to HH:MM:SS countdown string.
  static String formatCountdown(Duration duration) {
    if (duration <= Duration.zero) return '00:00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
