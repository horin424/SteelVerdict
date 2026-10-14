import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/core/l10n/app_localizations.dart';
import 'package:strategy_game/core/utils/date_utils.dart';

/// The daily reward's day is the date in Japan, as on the server
/// (functions/scripts/verify-japan-day.js checks the same moments there).
void main() {
  DateTime utc(String s) => DateTime.parse(s);

  test('23:59:59 in Japan is still the 13th', () {
    expect(GameDateUtils.japanDate(utc('2026-10-13T14:59:59Z')), DateTime.utc(2026, 10, 13));
  });
  test('0:00 in Japan is the 14th (15:00 UTC the day before)', () {
    expect(GameDateUtils.japanDate(utc('2026-10-13T15:00:00Z')), DateTime.utc(2026, 10, 14));
  });
  test('8:59 in Japan is the 14th, though UTC is still the 13th', () {
    expect(GameDateUtils.japanDate(utc('2026-10-13T23:59:00Z')), DateTime.utc(2026, 10, 14));
  });
  test('year end and leap day', () {
    expect(GameDateUtils.japanDate(utc('2026-12-31T15:00:00Z')), DateTime.utc(2027, 1, 1));
    expect(GameDateUtils.japanDate(utc('2028-02-28T15:00:00Z')), DateTime.utc(2028, 2, 29));
  });
  test('a local time on the phone gives the same game day', () {
    final moment = utc('2026-10-13T15:10:00Z');
    expect(GameDateUtils.japanDate(moment.toLocal()), GameDateUtils.japanDate(moment));
  });

  group('daily reward available again', () {
    final claimedAt = utc('2026-10-13T14:30:00Z'); // 23:30 in Japan

    test('not before midnight Japan time', () {
      expect(GameDateUtils.isTodayInJapan(claimedAt, now: utc('2026-10-13T14:59:00Z')), isTrue);
    });
    test('from 0:00 Japan time, while UTC is still the same day', () {
      expect(GameDateUtils.isTodayInJapan(claimedAt, now: utc('2026-10-13T15:10:00Z')), isFalse);
    });
    test('a claim at 1:00 Japan time is not available again at 8:00', () {
      final early = utc('2026-10-13T16:00:00Z'); // 1:00 on the 14th in Japan
      expect(GameDateUtils.isTodayInJapan(early, now: utc('2026-10-13T23:00:00Z')), isTrue);
    });
  });

  group("relative times in the app's language", () {
    final now = utc('2026-10-14T10:00:00Z');
    final ja = lookupAppLocalizations(const Locale('ja'));
    final en = lookupAppLocalizations(const Locale('en'));

    test('Japanese', () {
      expect(GameDateUtils.timeAgo(now.subtract(const Duration(seconds: 30)), ja, now: now), 'たった今');
      expect(GameDateUtils.timeAgo(now.subtract(const Duration(minutes: 5)), ja, now: now), '5分前');
      expect(GameDateUtils.timeAgo(now.subtract(const Duration(hours: 3)), ja, now: now), '3時間前');
      expect(GameDateUtils.timeAgo(now.subtract(const Duration(days: 2)), ja, now: now), '2日前');
    });
    test('English, singular and plural', () {
      expect(GameDateUtils.timeAgo(now.subtract(const Duration(minutes: 1)), en, now: now), '1 minute ago');
      expect(GameDateUtils.timeAgo(now.subtract(const Duration(minutes: 5)), en, now: now), '5 minutes ago');
      expect(GameDateUtils.timeAgo(now.subtract(const Duration(days: 1)), en, now: now), '1 day ago');
    });
    test("a week or more shows the date in the language's format", () {
      final old = DateTime(2026, 3, 10, 14, 30);
      expect(GameDateUtils.timeAgo(old, ja, now: now), '2026/03/10 14:30');
      expect(GameDateUtils.timeAgo(old, en, now: now), 'Mar 10, 2026 14:30');
    });
  });
}
