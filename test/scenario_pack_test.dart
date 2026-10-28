// The scenario pack (古代バトルパック): after buying it the player chooses 5
// locked scenarios, saved to the account and final (the client agreed, 28 Oct
// 2026). Also: PvP is hidden in version 1.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:strategy_game/core/constants/app_constants.dart';
import 'package:strategy_game/core/l10n/app_localizations.dart';
import 'package:strategy_game/core/router/app_router.dart';
import 'package:strategy_game/features/auth/auth_providers.dart';
import 'package:strategy_game/features/scenario_selection/scenario_providers.dart';
import 'package:strategy_game/features/shop/screens/shop_screen.dart';
import 'package:strategy_game/features/shop/shop_providers.dart';
import 'package:strategy_game/features/shop/widgets/one_time_purchase_tile.dart';
import 'package:strategy_game/features/splash/splash_providers.dart';
import 'package:strategy_game/models/game_config_model.dart';
import 'package:strategy_game/models/user_model.dart';
import 'package:strategy_game/services/game_config/game_config_providers.dart';
import 'package:strategy_game/services/local_storage/hive_storage_service.dart';
import 'package:strategy_game/services/purchase/iap_purchase_service.dart';

/// Settings in memory instead of Hive.
class _Storage extends HiveStorageService {
  final Map<String, dynamic> settings;
  _Storage(this.settings);

  @override
  dynamic getSetting(String key, {dynamic defaultValue}) => settings[key] ?? defaultValue;
}

UserModel _user({bool pack = false, List<String> picks = const []}) => UserModel.fromJson({
      'uid': 'u1',
      'scenarioPack1Unlocked': pack,
      if (picks.isNotEmpty) 'scenarioPack1Picks': picks,
    });

final _config = GameConfigModel.fromJson({
  'scenarios': {
    't_free': {'title': 'Free', 'worldviewKey': 'w_b', 'difficulty': 1, 'isFree': true, 'isUnlocked': true},
    't_open': {'title': 'Open', 'worldviewKey': 'w_b', 'difficulty': 3, 'isFree': false, 'isUnlocked': true},
    't_b5': {'title': 'B5', 'worldviewKey': 'w_b', 'difficulty': 5, 'isFree': false, 'isUnlocked': false},
    't_b2': {'title': 'B2', 'worldviewKey': 'w_b', 'difficulty': 2, 'isFree': false, 'isUnlocked': false},
    't_a4': {'title': 'A4', 'worldviewKey': 'w_a', 'difficulty': 4, 'isFree': false, 'isUnlocked': false},
  },
});

ProviderContainer _container({UserModel? user, List<String> adUnlocked = const []}) {
  final c = ProviderContainer(overrides: [
    gameConfigProvider.overrideWithValue(_config),
    hiveStorageServiceProvider.overrideWithValue(
      _Storage({'unlocked_scenarios': '[${adUnlocked.map((id) => '"$id"').join(',')}]'}),
    ),
    currentUserModelProvider.overrideWith((ref) async => user),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('the account', () {
    test('owning the pack with nothing chosen: can choose', () {
      final u = _user(pack: true);
      expect(u.canChoosePackScenarios, isTrue);
      expect(u.packUnlockedScenarioIds, isEmpty);
    });

    test('chosen: the 5 are unlocked and there is nothing more to choose', () {
      final u = _user(pack: true, picks: ['a', 'b', 'c', 'd', 'e']);
      expect(u.canChoosePackScenarios, isFalse);
      expect(u.packUnlockedScenarioIds, {'a', 'b', 'c', 'd', 'e'});
    });

    test('the pack moved to another account (or was refunded): its picks unlock nothing', () {
      final u = _user(pack: false, picks: ['a', 'b']);
      expect(u.packUnlockedScenarioIds, isEmpty);
      expect(u.canChoosePackScenarios, isFalse);
    });

    test('no pack fields at all (older accounts)', () {
      final u = UserModel.fromJson({'uid': 'u1'});
      expect(u.scenarioPack1Unlocked, isFalse);
      expect(u.packScenarioIds, isEmpty);
    });
  });

  group('what the pack chooses from', () {
    test('every scenario the config locks, by world then difficulty', () async {
      final c = _container(user: _user());
      final choices = c.read(packChoicesProvider);
      expect(choices.map((x) => x.scenario.scenarioId), ['t_a4', 't_b2', 't_b5']);
    });

    test('a scenario unlocked with an ad stays a choice (only the pack keeps it after a reinstall)', () {
      final c = _container(user: _user(), adUnlocked: ['t_b2']);
      final b2 = c.read(packChoicesProvider).firstWhere((x) => x.scenario.scenarioId == 't_b2');
      expect(b2.unlockedHere, isTrue);
    });

    test('the choice is 5, or all of them when fewer are locked', () {
      expect(packChoiceCount(7), 5);
      expect(packChoiceCount(5), 5);
      expect(packChoiceCount(3), 3);
      expect(packChoiceCount(0), 0);
    });

    test('the server refusals the player sees', () {
      expect(packChoiceError('already-exists'), 'err_pack_already_chosen');
      expect(packChoiceError('failed-precondition'), 'err_pack_not_owned');
      expect(packChoiceError('invalid-argument'), 'err_pack_choice_failed');
    });
  });

  group('the scenario list', () {
    Future<Set<String>> unlocked(ProviderContainer c) async {
      await c.read(currentUserModelProvider.future);
      return c.read(scenariosProvider).where((s) => s.isUnlocked || s.isFree).map((s) => s.scenarioId).toSet();
    }

    test('the pack\'s picks are unlocked on any phone', () async {
      final c = _container(user: _user(pack: true, picks: ['t_b5', 't_a4']));
      expect(await unlocked(c), {'t_free', 't_open', 't_b5', 't_a4'});
    });

    test('ad unlocks on this phone still count', () async {
      final c = _container(user: _user(), adUnlocked: ['t_b2']);
      expect(await unlocked(c), {'t_free', 't_open', 't_b2'});
    });

    test('picks of a pack the account no longer owns unlock nothing', () async {
      final c = _container(user: _user(pack: false, picks: ['t_b5']));
      expect(await unlocked(c), {'t_free', 't_open'});
    });
  });

  group('the shop tile', () {
    Future<void> pumpShop(WidgetTester tester, UserModel user) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          productsProvider.overrideWith((ref) async => <ProductDetails>[]),
          currentUserModelProvider.overrideWith((ref) async => user),
        ],
        child: const MaterialApp(
          locale: Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShopScreen(),
        ),
      ));
      await tester.pumpAndSettle();
    }

    Finder packTile() => find.byWidgetPredicate(
        (w) => w is OneTimePurchaseTile && w.productId == ProductIds.scenarioPack1);
    Finder tappable(Finder tile) => find.descendant(
        of: tile, matching: find.byWidgetPredicate((w) => w is InkWell && w.onTap != null));

    testWidgets('bought, nothing chosen: "選ぶ", and it can be tapped without a store price', (tester) async {
      await pumpShop(tester, _user(pack: true));
      expect(find.descendant(of: packTile(), matching: find.text('選ぶ')), findsOneWidget);
      expect(tappable(packTile()), findsOneWidget);
    });

    testWidgets('chosen: "購入済み", how many were unlocked, and nothing to tap', (tester) async {
      await pumpShop(tester, _user(pack: true, picks: ['a', 'b', 'c', 'd', 'e']));
      expect(find.descendant(of: packTile(), matching: find.text('購入済み')), findsOneWidget);
      expect(find.text('5つのシナリオを解放済み'), findsOneWidget);
      expect(tappable(packTile()), findsNothing);
    });

    testWidgets('not bought: the store\'s price (none here, so "—" and disabled)', (tester) async {
      await pumpShop(tester, _user());
      expect(find.descendant(of: packTile(), matching: find.text('—')), findsOneWidget);
      expect(tappable(packTile()), findsNothing);
    });
  });

  group('PvP in version 1', () {
    test('is hidden', () => expect(AppConstants.pvpEnabled, isFalse));

    test('its screens are recognised for the redirect home', () {
      expect(isPvpLocation('/pvp-lobby'), isTrue);
      expect(isPvpLocation('/pvp-battle'), isTrue);
      expect(isPvpLocation('/home'), isFalse);
      expect(isPvpLocation('/game-hub'), isFalse);
    });
  });
}
