import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/features/game_mode_selection/game_mode_providers.dart';
import 'package:strategy_game/services/battle_api/battle_api_service.dart';

/// The cost shown on the mode screen must be what submitBattle charges (B22).
void main() {
  // The live config's keys (2 Oct): no 'claude' key, so Claude falls back to 3.
  const liveCosts = {'practice': 0, 'tabletop': 0, 'normal': 1, 'epic': 3, 'boss': 5};

  int costFor(String mode, ModelChoice model, [Map<String, int> costs = liveCosts]) {
    final container = ProviderContainer(overrides: [
      ticketCostsProvider.overrideWithValue(costs),
    ]);
    addTearDown(container.dispose);
    container.read(selectedGameModeProvider.notifier).state = mode;
    container.read(selectedModelProvider.notifier).state = model;
    return container.read(effectiveTicketCostProvider);
  }

  test('Tabletop with Claude picked is free, as the server runs it', () {
    expect(costFor('tabletop', ModelChoice.claude), 0);
  });
  test('Tabletop with Gemini is free', () {
    expect(costFor('tabletop', ModelChoice.gemini), 0);
  });
  test('Practice is free whatever the model', () {
    expect(costFor('practice', ModelChoice.claude), 0);
  });
  test('History Puzzle is free', () {
    expect(costFor('history_puzzle', ModelChoice.gemini), 0);
  });
  test('the free modes follow the Practice price, as the server does', () {
    expect(costFor('tabletop', ModelChoice.claude, {...liveCosts, 'practice': 1}), 1);
  });
  test('Normal with Gemini costs the Normal price', () {
    expect(costFor('normal', ModelChoice.gemini), 1);
  });
  test('Normal with Claude costs Claude\'s price', () {
    expect(costFor('normal', ModelChoice.claude), 3);
  });
  test('Epic with Gemini costs the Epic price', () {
    expect(costFor('epic', ModelChoice.gemini), 3);
  });
  test('the model picker is locked for Practice and Tabletop only', () {
    expect(geminiOnlyModes, {'practice', 'tabletop'});
  });
}
