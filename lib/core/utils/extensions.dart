import 'package:intl/intl.dart';

extension StringExtensions on String {
  /// Parses a stat map string like "attack:5,defense:3,speed:2" into a Map.
  Map<String, int> toStatMap() {
    final map = <String, int>{};
    if (trim().isEmpty) return map;
    final pairs = split(',');
    for (final pair in pairs) {
      final parts = pair.trim().split(':');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = int.tryParse(parts[1].trim());
        if (key.isNotEmpty && value != null) {
          map[key] = value;
        }
      }
    }
    return map;
  }

  /// Returns the string truncated with ellipsis if it exceeds [maxLength].
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return substring(0, maxLength - ellipsis.length) + ellipsis;
  }

  /// Capitalizes the first letter of the string.
  String get capitalized {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

extension IntExtensions on int {
  /// Formats the ticket count for display. e.g., 1000 → "1,000 tickets".
  String toTicketDisplay() {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(this)} ticket${this == 1 ? '' : 's'}';
  }

  /// Clamps the value between [min] and [max].
  int clampBetween(int min, int max) => clamp(min, max).toInt();

  /// Returns a string with a + prefix for positive numbers.
  String toSignedString() {
    if (this > 0) return '+$this';
    return toString();
  }
}

extension DateTimeExtensions on DateTime {
  /// Returns a human-readable string like "March 10, 2026 at 14:30".
  String toReadableString() {
    final formatter = DateFormat('MMMM d, yyyy \'at\' HH:mm');
    return formatter.format(toLocal());
  }

  /// Returns just the date part as a readable string.
  String toDateString() {
    final formatter = DateFormat('MMM d, yyyy');
    return formatter.format(toLocal());
  }

  /// Returns just the time part as a readable string.
  String toTimeString() {
    final formatter = DateFormat('HH:mm');
    return formatter.format(toLocal());
  }

  /// Returns true if this DateTime is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if this DateTime is in the past.
  bool get isPast => isBefore(DateTime.now());

  /// Returns true if this DateTime is in the future.
  bool get isFuture => isAfter(DateTime.now());
}

extension MapExtensions on Map<String, int> {
  /// Returns the total sum of all values in the map.
  int get totalPoints => values.fold(0, (sum, v) => sum + v);

  /// Converts stat map to display string like "ATK: 5, DEF: 3".
  String toStatDisplay() {
    return entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}
