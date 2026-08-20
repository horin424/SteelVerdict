import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'battle_api_service.dart';

class CloudFunctionsBattleService implements BattleApiService {
  final FirebaseFunctions _functions;

  CloudFunctionsBattleService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<BattleResponse> submitBattle(BattleRequest request) async {
    try {
      final callable = _functions.httpsCallable(
        'submitBattle',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 90),
        ),
      );

      final result = await callable.call(request.toJson());
      final data = result.data as Map<String, dynamic>;

      return BattleResponse.fromJson(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Functions error: ${e.code} - ${e.message}');
      // Return a mock response so the app doesn't crash without Firebase
      if (e.code == 'not-found' || e.code == 'unavailable') {
        return _mockResponse(request);
      }
      rethrow;
    } catch (e) {
      debugPrint('submitBattle error: $e');
      // Fallback mock for development
      return _mockResponse(request);
    }
  }

  BattleResponse _mockResponse(BattleRequest request) {
    final totalStats = request.raceStats.values.fold(0, (a, b) => a + b);
    final outcome = totalStats >= 18 ? 'win' : totalStats >= 12 ? 'draw' : 'loss';

    return BattleResponse(
      reportText: '''
**Battle Report — ${request.scenarioId}**

The forces engaged at dawn, the air thick with tension. Your commander rallied the troops with a bold strategy: "${request.playerStrategy.substring(0, request.playerStrategy.length.clamp(0, 100))}..."

The battle unfolded with fierce intensity. Your race's strengths were tested against the enemy's resolute defense.

${_outcomeText(outcome)}

*[This is a mock report. Configure Firebase Cloud Functions to enable AI battle judging.]*
''',
      outcome: outcome,
      shortSummary: _outcomeText(outcome),
      ticketsConsumed: 1,
    );
  }

  String _outcomeText(String outcome) {
    switch (outcome) {
      case 'win':
        return 'Victory was yours. The enemy routed and fled before your superior tactics.';
      case 'loss':
        return 'The battle was lost. Your forces were overwhelmed by the enemy\'s resolve.';
      default:
        return 'The battle ended in a stalemate. Both sides withdrew to lick their wounds.';
    }
  }
}
