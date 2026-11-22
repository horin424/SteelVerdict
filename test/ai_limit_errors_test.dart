// The daily AI limits (functions/src/limits): the server refuses a battle or a
// chronicle with "DAILY_FREE_LIMIT:30", "DAILY_AI_LIMIT:100" or
// "APP_AI_LIMIT:3000", the limit that was reached and its number. The app must
// show each as its own message, in Japanese and English, with that number,
// rather than "battle failed, try again".
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/core/l10n/app_localizations.dart';
import 'package:strategy_game/core/utils/error_messages.dart';
import 'package:strategy_game/features/auth/auth_providers.dart';
import 'package:strategy_game/features/battle/battle_providers.dart';
import 'package:strategy_game/features/game_mode_selection/game_mode_providers.dart';
import 'package:strategy_game/features/settings/settings_providers.dart';
import 'package:strategy_game/features/world_setting/world_setting_providers.dart';
import 'package:strategy_game/models/race_model.dart';
import 'package:strategy_game/services/battle_api/battle_api_service.dart';

/// The server, refusing every battle with [message].
class _RefusingApi implements BattleApiService {
  _RefusingApi(this.message);
  final String message;
  int calls = 0;

  @override
  Future<BattleResponse> submitBattle(BattleRequest request) async {
    calls++;
    // ignore: invalid_use_of_protected_member
    throw FirebaseFunctionsException(code: 'resource-exhausted', message: message);
  }
}

/// The chosen world, without Hive.
class _World extends SelectedWorldviewNotifier {
  @override
  String build() => '1830_fantasy';
}

void main() {
  group('aiLimitError', () {
    test('each limit becomes its code, with the number', () {
      expect(aiLimitError('DAILY_FREE_LIMIT:30'), 'err_ai_free_limit:30');
      expect(aiLimitError('DAILY_AI_LIMIT:100'), 'err_ai_daily_limit:100');
      expect(aiLimitError('APP_AI_LIMIT:3000'), 'err_ai_app_limit');
      expect(aiLimitError('DAILY_FREE_LIMIT:0'), 'err_ai_free_limit:0');
    });

    test('any other message is not a limit', () {
      expect(aiLimitError(null), isNull);
      expect(aiLimitError(''), isNull);
      expect(aiLimitError('Not enough tickets. Need 3, have 1.'), isNull);
      expect(aiLimitError('MODE_LOCKED'), isNull);
      expect(aiLimitError('REPORT_LIMIT'), isNull);
      expect(aiLimitError('DAILY_FREE_LIMIT'), isNull);
      expect(aiLimitError('DAILY_FREE_LIMIT:many'), isNull);
    });
  });

  group('the messages', () {
    late AppLocalizations ja;
    late AppLocalizations en;
    setUpAll(() async {
      ja = await AppLocalizations.delegate.load(const Locale('ja'));
      en = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('in Japanese', () {
      expect(localizedError('err_ai_free_limit:30', ja),
          'チケット不要のモードは、本日の上限（30回）に達しました。日本時間0時にリセットされます。');
      expect(localizedError('err_ai_daily_limit:100', ja),
          '本日のAIの利用回数が上限（100回）に達しました。日本時間0時にリセットされます。');
      expect(localizedError('err_ai_app_limit', ja),
          'ただいまAIをご利用いただけません。日本時間0時以降にもう一度お試しください。');
    });

    test('in English', () {
      expect(localizedError('err_ai_free_limit:30', en),
          "You've reached today's limit of 30 plays in the modes that need no tickets. It resets at midnight Japan time.");
      expect(localizedError('err_ai_daily_limit:100', en),
          "You've reached today's limit of 100 AI uses. It resets at midnight Japan time.");
      expect(localizedError('err_ai_app_limit', en),
          "The AI isn't available right now. Please try again after midnight Japan time.");
    });

    test('the number is the one the server sent (a limit changed in the admin)', () {
      expect(localizedError(aiLimitError('DAILY_FREE_LIMIT:12')!, ja), contains('（12回）'));
      expect(localizedError(aiLimitError('DAILY_AI_LIMIT:250')!, en), contains('250 AI uses'));
    });
  });

  group('a battle the server refuses', () {
    late _RefusingApi api;

    Future<String?> errorAfter(String serverMessage) async {
      api = _RefusingApi(serverMessage);
      final container = ProviderContainer(overrides: [
        battleApiServiceProvider.overrideWithValue(api),
        currentRaceProvider.overrideWithValue(RaceModel(
          id: 'r1',
          raceName: '鉄の軍団',
          worldviewKey: '1830_fantasy',
          stats: const {'strength': 5},
          createdAt: DateTime(2026, 11, 22),
        )),
        effectiveTicketCostProvider.overrideWithValue(0),
        selectedWorldviewKeyProvider.overrideWith(_World.new),
        localeProvider.overrideWith((ref) => const Locale('ja')),
      ]);
      addTearDown(container.dispose);
      // The controller is autoDispose: keep it alive across the await.
      final sub = container.listen(battleControllerProvider, (_, _) {});
      addTearDown(sub.close);

      final result = await container.read(battleControllerProvider.notifier).submitBattle(
            scenarioId: 's1',
            gameMode: 'practice',
            strategy: 'Hold the ridge and wait for dawn.',
          );
      expect(result, isNull);
      return container.read(battleControllerProvider).errorMessage;
    }

    test('the free limit: its own message', () async {
      expect(await errorAfter('DAILY_FREE_LIMIT:30'), 'err_ai_free_limit:30');
      expect(api.calls, 1);
    });

    test('the limit for all AI uses: its own message', () async {
      expect(await errorAfter('DAILY_AI_LIMIT:100'), 'err_ai_daily_limit:100');
    });

    test("the app's limit: its own message", () async {
      expect(await errorAfter('APP_AI_LIMIT:3000'), 'err_ai_app_limit');
    });

    test('any other failure still says the battle failed', () async {
      expect(await errorAfter('AI service error. Please try again.'), 'battle_failed_retry');
    });
  });
}
