import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/core/l10n/app_localizations_en.dart';
import 'package:strategy_game/core/l10n/app_localizations_ja.dart';
import 'package:strategy_game/features/admin/admin_ids.dart';

/// Adding a world or scenario with a taken ID wiped the existing one (B23).
void main() {
  final config = <String, dynamic>{
    'worldviews': {'1830_fantasy': {'title': 'Fantasy'}},
    'scenarios': {'s1': {'title': 'Siege'}},
  };

  test('a taken world ID is found', () {
    expect(configHasId(config, 'worldviews', '1830_fantasy'), isTrue);
  });
  test('a taken scenario ID is found', () {
    expect(configHasId(config, 'scenarios', 's1'), isTrue);
  });
  test('a new ID is free', () {
    expect(configHasId(config, 'worldviews', 'cyberpunk_2099'), isFalse);
  });
  test('an ID is only taken in its own section', () {
    expect(configHasId(config, 'scenarios', '1830_fantasy'), isFalse);
  });
  test('no config, or no section yet: free', () {
    expect(configHasId(null, 'worldviews', 'x'), isFalse);
    expect(configHasId({}, 'scenarios', 'x'), isFalse);
  });
  test('the message names the ID in both languages', () {
    expect(AppLocalizationsEn().adminIdExists('s1'), '"s1" is already in use. Enter a different ID.');
    expect(AppLocalizationsJa().adminIdExists('s1'), '「s1」はすでに使われています。別のIDを入力してください。');
  });
}
