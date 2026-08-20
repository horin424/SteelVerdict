import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  Future<void> logBattleStarted(String mode, String scenarioId) async {
    try {
      await _analytics.logEvent(
        name: 'battle_started',
        parameters: {
          'game_mode': mode,
          'scenario_id': scenarioId,
        },
      );
    } catch (e) {
      debugPrint('Analytics.logBattleStarted error: $e');
    }
  }

  Future<void> logBattleCompleted({
    required String mode,
    required String scenarioId,
    required String outcome,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'battle_completed',
        parameters: {
          'game_mode': mode,
          'scenario_id': scenarioId,
          'outcome': outcome,
        },
      );
    } catch (e) {
      debugPrint('Analytics.logBattleCompleted error: $e');
    }
  }

  Future<void> logTicketConsumed(int count, String reason) async {
    try {
      await _analytics.logEvent(
        name: 'ticket_consumed',
        parameters: {
          'count': count,
          'reason': reason,
        },
      );
    } catch (e) {
      debugPrint('Analytics.logTicketConsumed error: $e');
    }
  }

  Future<void> logTicketEarned(int count, String source) async {
    try {
      await _analytics.logEvent(
        name: 'ticket_earned',
        parameters: {
          'count': count,
          'source': source,
        },
      );
    } catch (e) {
      debugPrint('Analytics.logTicketEarned error: $e');
    }
  }

  Future<void> logAdWatched(String adType) async {
    try {
      await _analytics.logEvent(
        name: 'ad_watched',
        parameters: {'ad_type': adType},
      );
    } catch (e) {
      debugPrint('Analytics.logAdWatched error: $e');
    }
  }

  Future<void> logSubscriptionPurchased(String tier) async {
    try {
      await _analytics.logPurchase(
        currency: 'JPY',
        value: _tierToValue(tier),
        parameters: {'subscription_tier': tier},
      );
    } catch (e) {
      debugPrint('Analytics.logSubscriptionPurchased error: $e');
    }
  }

  double _tierToValue(String tier) {
    switch (tier) {
      case 'sub500':
        return 500;
      case 'sub1000':
        return 1000;
      case 'sub3000':
        return 3000;
      default:
        return 0;
    }
  }

  Future<void> logPvpMatchCreated() async {
    try {
      await _analytics.logEvent(name: 'pvp_match_created');
    } catch (e) {
      debugPrint('Analytics.logPvpMatchCreated error: $e');
    }
  }

  Future<void> logWarHistoryGenerated() async {
    try {
      await _analytics.logEvent(name: 'war_history_generated');
    } catch (e) {
      debugPrint('Analytics.logWarHistoryGenerated error: $e');
    }
  }

  Future<void> logShareToX() async {
    try {
      await _analytics.logShare(
        contentType: 'war_history',
        itemId: 'war_chronicle',
        method: 'x_twitter',
      );
    } catch (e) {
      debugPrint('Analytics.logShareToX error: $e');
    }
  }

  Future<void> setUserId(String uid) async {
    try {
      await _analytics.setUserId(id: uid);
    } catch (e) {
      debugPrint('Analytics.setUserId error: $e');
    }
  }

  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics.setUserProperty error: $e');
    }
  }
}
