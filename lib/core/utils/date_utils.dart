import 'package:intl/intl.dart';

class GameDateUtils {
  GameDateUtils._();

  /// Returns true if the given [dateTime] is today (same calendar date).
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Formats a battle date to a readable string like "Mar 10, 2026 14:30".
  static String formatBattleDate(DateTime dateTime) {
    final formatter = DateFormat('MMM d, yyyy HH:mm');
    return formatter.format(dateTime.toLocal());
  }

  /// Returns the remaining time before a PvP match expires.
  /// Returns Duration.zero if already expired.
  static Duration pvpTimeoutRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return Duration.zero;
    return expiresAt.difference(now);
  }

  /// Returns a human-readable relative time string.
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins minute${mins == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return formatBattleDate(dateTime);
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
