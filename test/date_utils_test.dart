import 'package:flutter_test/flutter_test.dart';
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

}
