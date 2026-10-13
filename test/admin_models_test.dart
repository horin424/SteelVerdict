import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/features/admin/screens/admin_costs_editor.dart';

/// The admin's AI models (B25): a removed model must be settable again, and
/// emptying one must really remove it.
void main() {
  test('the server\'s three models are always listed, even when none is stored', () {
    expect(modelKeysToList({}), ['gemini_flash_lite', 'gemini_flash', 'claude']);
  });

  test('other stored keys are listed after them', () {
    expect(modelKeysToList({'claude': 'x', 'custom': 'y'}),
        ['gemini_flash_lite', 'gemini_flash', 'claude', 'custom']);
  });

  test('typed models are set, trimmed; emptied ones are removed', () {
    final changes = modelChanges({
      'gemini_flash_lite': 'gemini-2.5-flash-lite',
      'gemini_flash': '  gemini-2.5-pro ',
      'claude': '',
    });
    expect(changes.set, {'gemini_flash_lite': 'gemini-2.5-flash-lite', 'gemini_flash': 'gemini-2.5-pro'});
    expect(changes.remove, {'claude'});
  });

  test('the defaults shown are the server\'s', () {
    final config = File('functions/src/utils/config.ts').readAsStringSync();
    String serverConst(String name) =>
        RegExp('export const $name\\s*=\\s*"([^"]+)"').firstMatch(config)!.group(1)!;
    expect(serverModelDefaults['gemini_flash_lite'], serverConst('GEMINI_FLASH_LITE'));
    expect(serverModelDefaults['gemini_flash'], serverConst('GEMINI_FLASH'));
    expect(serverModelDefaults['claude'], serverConst('CLAUDE_HAIKU'));
  });
}
