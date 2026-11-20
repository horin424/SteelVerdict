import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/core/utils/date_utils.dart';
import 'package:strategy_game/features/home/ad_tickets.dart';
import 'package:strategy_game/models/user_model.dart';

// Ad tickets come from the server when Google confirms the ad
// (admobRewardCallback); the app checks today's 20 before playing an ad and
// waits for the user document to show the tickets.
void main() {
  UserModel user({String? date, int count = 0, int tickets = 3}) =>
      UserModel.empty('player1').copyWith(
        ticketCount: tickets,
        adTicketClaimsDate: date,
        adTicketClaimsCount: count,
      );

  // 20 Nov 2026 12:00 in Japan.
  final noonInJapan = DateTime.utc(2026, 11, 20, 3);

  group('the Japan date as the server stores it', () {
    test('"YYYY-MM-DD", padded', () {
      expect(GameDateUtils.japanDateString(DateTime.utc(2026, 1, 5, 3)), '2026-01-05');
    });
    test('the day changes at midnight in Japan, 15:00 UTC', () {
      expect(GameDateUtils.japanDateString(DateTime.utc(2026, 11, 20, 14, 59, 59)), '2026-11-20');
      expect(GameDateUtils.japanDateString(DateTime.utc(2026, 11, 20, 15)), '2026-11-21');
    });
  });

  group('ads left today', () {
    test('a player who never watched one: 20', () {
      expect(AdTickets.adsLeftToday(user(), now: noonInJapan), 20);
    });
    test('5 watched today: 15', () {
      expect(AdTickets.adsLeftToday(user(date: '2026-11-20', count: 5), now: noonInJapan), 15);
    });
    test('20 watched today: none', () {
      expect(AdTickets.adsLeftToday(user(date: '2026-11-20', count: 20), now: noonInJapan), 0);
    });
    test('more than 20 counted: none, never negative', () {
      expect(AdTickets.adsLeftToday(user(date: '2026-11-20', count: 25), now: noonInJapan), 0);
    });
    test('20 watched yesterday: 20 again', () {
      expect(AdTickets.adsLeftToday(user(date: '2026-11-19', count: 20), now: noonInJapan), 20);
    });
    test('after midnight in Japan the count starts again', () {
      final full = user(date: '2026-11-20', count: 20);
      expect(AdTickets.adsLeftToday(full, now: DateTime.utc(2026, 11, 20, 14, 59)), 0);
      expect(AdTickets.adsLeftToday(full, now: DateTime.utc(2026, 11, 20, 15, 0, 1)), 20);
    });
  });

  group('the server added the tickets', () {
    final before = user(date: '2026-11-20', count: 3);
    test('one more ad counted: yes', () {
      expect(AdTickets.granted(before, user(date: '2026-11-20', count: 4)), isTrue);
    });
    test('the first ad of a new day: yes', () {
      expect(AdTickets.granted(before, user(date: '2026-11-21', count: 1)), isTrue);
    });
    test('the first ad ever: yes', () {
      expect(AdTickets.granted(user(), user(date: '2026-11-20', count: 1)), isTrue);
    });
    test('only the ticket count changed (spent elsewhere): no', () {
      expect(AdTickets.granted(before, user(date: '2026-11-20', count: 3, tickets: 1)), isFalse);
    });
    test('no document: no', () {
      expect(AdTickets.granted(before, null), isFalse);
    });
  });

  group('waiting for the tickets', () {
    final before = user(date: '2026-11-20', count: 3);
    const short = Duration(milliseconds: 200);

    test('true when the document shows them, and stops listening', () async {
      final doc = StreamController<UserModel?>();
      final wait = AdTickets.waitForGrant(doc.stream, before, timeout: const Duration(seconds: 5));
      doc.add(before);
      doc.add(user(date: '2026-11-20', count: 4));
      expect(await wait, isTrue);
      expect(doc.hasListener, isFalse);
      await doc.close();
    });
    test('true at once when they arrived before the app listened', () async {
      final doc = StreamController<UserModel?>();
      final wait = AdTickets.waitForGrant(doc.stream, before, timeout: const Duration(seconds: 5));
      doc.add(user(date: '2026-11-20', count: 4));
      expect(await wait, isTrue);
      await doc.close();
    });
    test('false after the time limit, and stops listening', () async {
      final doc = StreamController<UserModel?>();
      final wait = AdTickets.waitForGrant(doc.stream, before, timeout: short);
      doc.add(before);
      expect(await wait, isFalse);
      expect(doc.hasListener, isFalse);
      await doc.close();
    });
    test('false when the updates end first', () async {
      final doc = StreamController<UserModel?>();
      final wait = AdTickets.waitForGrant(doc.stream, before, timeout: const Duration(seconds: 5));
      await doc.close();
      expect(await wait, isFalse);
    });
    test('false when the updates fail', () async {
      final doc = StreamController<UserModel?>();
      final wait = AdTickets.waitForGrant(doc.stream, before, timeout: const Duration(seconds: 5));
      doc.addError(Exception('permission-denied'));
      expect(await wait, isFalse);
      await doc.close();
    });
    test('the app waits 20 seconds by default', () {
      expect(AdTickets.grantWait, const Duration(seconds: 20));
    });
  });

  group('the user document', () {
    test('reads the server\'s ad count', () {
      final u = UserModel.fromJson({
        'uid': 'p',
        'adTicketClaimsDate': '2026-11-20',
        'adTicketClaimsCount': 7,
      });
      expect([u.adTicketClaimsDate, u.adTicketClaimsCount], ['2026-11-20', 7]);
    });
    test('missing or odd values: none counted', () {
      final u = UserModel.fromJson({'uid': 'p', 'adTicketClaimsDate': 20261120, 'adTicketClaimsCount': 'x'});
      expect([u.adTicketClaimsDate, u.adTicketClaimsCount], [null, 0]);
    });
    test('never written back by the app', () {
      final json = user(date: '2026-11-20', count: 7).toJson();
      expect(json.containsKey('adTicketClaimsDate') || json.containsKey('adTicketClaimsCount'), isFalse);
    });
  });

  test('2 tickets per ad, 20 ads a day, purpose "tickets" (as the server)', () {
    expect([AdTickets.perAd, AdTickets.maxAdsPerDay, AdTickets.purpose], [2, 20, 'tickets']);
  });
}
