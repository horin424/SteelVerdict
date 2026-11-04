// The phone's game data (races, battle records, chronicles, saved strategies)
// belongs to the signed-in account: a second account on the same phone must not
// see the first one's, and data saved before this version goes to the account
// that is signed in first. Real Hive boxes in a temp folder.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:strategy_game/bootstrap/hive_adapters.dart';
import 'package:strategy_game/core/constants/app_constants.dart';
import 'package:strategy_game/core/l10n/app_localizations.dart';
import 'package:strategy_game/features/auth/auth_providers.dart';
import 'package:strategy_game/features/splash/splash_providers.dart';
import 'package:strategy_game/models/battle_record_model.dart';
import 'package:strategy_game/models/race_model.dart';
import 'package:strategy_game/models/war_history_model.dart';
import 'package:strategy_game/services/local_storage/hive_storage_service.dart';

const _world = AppConstants.defaultWorldviewKey;

RaceModel _race(String name) => RaceModel(
      id: 'race-$name',
      raceName: name,
      worldviewKey: _world,
      stats: const {'strength': 10, 'wisdom': 10, 'magic': 10},
      createdAt: DateTime(2026, 11, 4),
    );

BattleRecordModel _record(String id, {String report = 'report'}) => BattleRecordModel(
      id: id,
      scenarioId: 'scenario_001',
      gameMode: 'normal',
      playerStrategy: 'flank them',
      aiReport: report,
      playerStats: const {'strength': 10},
      outcome: 'win',
      createdAt: DateTime(2026, 11, 4, 12),
      isFavorite: false,
      scenarioTitle: '国境の小競り合い',
      worldviewKey: _world,
    );

WarHistoryModel _history(String id) => WarHistoryModel(
      id: id,
      sourceRecordId: 'r1',
      longNarrative: 'the chronicle',
      createdAt: DateTime(2026, 11, 4, 13),
      sharedToX: false,
      title: 'chronicle',
    );

void main() {
  late Directory dir;
  String? uid;
  late HiveStorageService storage;

  Box<dynamic> box(String name) => Hive.box(name);
  // Typed boxes must be fetched with their type.
  Iterable<dynamic> keysOf(String name) => switch (name) {
        AppConstants.hiveBoxBattleRecords => Hive.box<BattleRecordModel>(name).keys,
        AppConstants.hiveBoxWarHistories => Hive.box<WarHistoryModel>(name).keys,
        _ => Hive.box(name).keys,
      };
  List<String> unowned(String name) => keysOf(name)
      .whereType<String>()
      .where((k) => !LocalDataKeys.owned.hasMatch(k))
      .toList();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sv_local_data_');
    Hive.init(dir.path);
    registerHiveAdapters();
    await Hive.openBox<BattleRecordModel>(AppConstants.hiveBoxBattleRecords);
    await Hive.openBox<WarHistoryModel>(AppConstants.hiveBoxWarHistories);
    await Hive.openBox(AppConstants.hiveBoxRace);
    await Hive.openBox(AppConstants.hiveBoxStrategies);
    await Hive.openBox(AppConstants.hiveBoxSettings);
    uid = null;
    storage = HiveStorageService(currentUid: () => uid);
    await storage.initialize();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> saveEverything(String raceName, {String recordId = 'r1'}) async {
    await storage.saveRace(_race(raceName));
    await storage.saveStrategy('plan', 'strategy of $raceName');
    await storage.saveBattleRecord(_record(recordId, report: 'report of $raceName'));
    await storage.saveWarHistory(_history('h-$raceName'));
  }

  test('a second account on the same phone sees none of the first one\'s data', () async {
    uid = 'uidAlice';
    await saveEverything('Alice');
    expect(storage.getRace(_world)?.raceName, 'Alice');
    expect(storage.getStrategies().single.key, 'plan');
    expect(storage.getBattleRecords().single.aiReport, 'report of Alice');
    expect(storage.getWarHistories().single.id, 'h-Alice');

    uid = 'uidBob';
    expect(storage.getRace(_world), isNull);
    expect(storage.getStrategies(), isEmpty);
    expect(storage.getBattleRecords(), isEmpty);
    expect(storage.getWarHistories(), isEmpty);

    // Bob's own data, even under the same ids, doesn't touch Alice's.
    await saveEverything('Bob');
    expect(storage.getRace(_world)?.raceName, 'Bob');
    expect(storage.getBattleRecords().single.aiReport, 'report of Bob');

    uid = 'uidAlice';
    expect(storage.getRace(_world)?.raceName, 'Alice');
    expect(storage.getStrategies().single.value, 'strategy of Alice');
    expect(storage.getBattleRecords().single.aiReport, 'report of Alice');
    expect(storage.getWarHistories().single.id, 'h-Alice');
  });

  test('updating and deleting act on the signed-in account\'s entry only', () async {
    uid = 'uidAlice';
    await saveEverything('Alice');
    uid = 'uidBob';
    await saveEverything('Bob');

    await storage.updateBattleRecord(storage.getBattleRecords().single.copyWith(isFavorite: true));
    await storage.deleteRace(_world);
    await storage.deleteStrategy('plan');
    await storage.deleteWarHistory('h-Bob');
    expect(storage.getBattleRecords().single.isFavorite, isTrue);
    expect(storage.getRace(_world), isNull);
    expect(storage.getStrategies(), isEmpty);
    expect(storage.getWarHistories(), isEmpty);

    uid = 'uidAlice';
    expect(storage.getBattleRecords().single.isFavorite, isFalse);
    expect(storage.getRace(_world)?.raceName, 'Alice');
    expect(storage.getStrategies(), hasLength(1));
    expect(storage.getWarHistories(), hasLength(1));

    await storage.deleteBattleRecord('r1');
    expect(storage.getBattleRecords(), isEmpty);
    uid = 'uidBob';
    expect(storage.getBattleRecords(), hasLength(1));
  });

  group('data saved before this version (no owner in the key)', () {
    Future<void> putLegacy() async {
      await box(AppConstants.hiveBoxRace).put('race_$_world', jsonEncode(_race('Old').toJson()));
      await box(AppConstants.hiveBoxStrategies).put('昔の作戦', 'old strategy');
      await Hive.box<BattleRecordModel>(AppConstants.hiveBoxBattleRecords).put('r-old', _record('r-old'));
      await Hive.box<WarHistoryModel>(AppConstants.hiveBoxWarHistories).put('h-old', _history('h-old'));
    }

    test('goes to the first account that signs in, and only to it', () async {
      await putLegacy();
      uid = null;
      expect(storage.getRace(_world), isNull, reason: 'nobody signed in');

      expect(await storage.adoptUnownedData('uidAlice'), 4);
      for (final name in [
        AppConstants.hiveBoxRace,
        AppConstants.hiveBoxStrategies,
        AppConstants.hiveBoxBattleRecords,
        AppConstants.hiveBoxWarHistories,
      ]) {
        expect(unowned(name), isEmpty, reason: name);
      }

      uid = 'uidAlice';
      expect(storage.getRace(_world)?.raceName, 'Old');
      expect(storage.getStrategies().single, isA<MapEntry<String, String>>()
          .having((e) => e.key, 'name', '昔の作戦')
          .having((e) => e.value, 'text', 'old strategy'));
      expect(storage.getBattleRecords().single.id, 'r-old');
      expect(storage.getWarHistories().single.id, 'h-old');

      // A later account gets nothing, and running again moves nothing.
      expect(await storage.adoptUnownedData('uidBob'), 0);
      uid = 'uidBob';
      expect(storage.getRace(_world), isNull);
      expect(storage.getBattleRecords(), isEmpty);
    });

    test('initialize() hands it to the account already signed in at start-up', () async {
      await putLegacy();
      uid = 'uidAlice';
      await HiveStorageService(currentUid: () => uid).initialize();
      expect(storage.getRace(_world)?.raceName, 'Old');
      expect(storage.getBattleRecords().single.id, 'r-old');
      expect(storage.getWarHistories().single.id, 'h-old');
      expect(storage.getStrategies().single.key, '昔の作戦');
    });

    test('an entry the account already has is kept, the old one removed', () async {
      uid = 'uidAlice';
      await storage.saveRace(_race('New'));
      await putLegacy();
      await storage.adoptUnownedData('uidAlice');
      expect(storage.getRace(_world)?.raceName, 'New');
      expect(unowned(AppConstants.hiveBoxRace), isEmpty);
    });
  });

  test('clearAll removes the signed-in account\'s data and the settings, not the others\'', () async {
    uid = 'uidAlice';
    await saveEverything('Alice');
    uid = 'uidBob';
    await saveEverything('Bob');
    await storage.saveSetting('language', 'ja');

    await storage.clearAll();
    expect(storage.getRace(_world), isNull);
    expect(storage.getBattleRecords(), isEmpty);
    expect(storage.getWarHistories(), isEmpty);
    expect(storage.getStrategies(), isEmpty);
    expect(storage.getSetting('language'), isNull);

    uid = 'uidAlice';
    expect(storage.getRace(_world)?.raceName, 'Alice');
    expect(storage.getBattleRecords(), hasLength(1));
  });

  test('signed out: nothing is read or written', () async {
    uid = 'uidAlice';
    await saveEverything('Alice');
    uid = null;
    expect(storage.getRace(_world), isNull);
    expect(storage.getStrategies(), isEmpty);
    expect(storage.getBattleRecords(), isEmpty);
    await storage.saveRace(_race('Nobody'));
    await storage.saveStrategy('x', 'y');
    expect(box(AppConstants.hiveBoxRace).length, 1);
    expect(box(AppConstants.hiveBoxStrategies).length, 1);
  });

  test('a long strategy name still fits Hive\'s 255-byte key', () async {
    uid = 'GsoiRGYMH3TKHkTNR2JY08vIPJl2'; // a real-length Firebase uid
    final longName = '長い作戦名' * 40; // 200 characters, 600 bytes
    await storage.saveStrategy(longName, 'text');
    final key = box(AppConstants.hiveBoxStrategies).keys.single as String;
    expect(utf8.encode(key).length, lessThanOrEqualTo(LocalDataKeys.maxKeyBytes));
    final saved = storage.getStrategies().single;
    expect(longName.startsWith(saved.key), isTrue);
    await storage.deleteStrategy(saved.key);
    expect(storage.getStrategies(), isEmpty);
    expect(LocalDataKeys.of(uid!, 'plan'), 'u:$uid|plan');
  });

  test('the race shown follows the signed-in account', () async {
    final signedIn = StateProvider<String?>((ref) => 'uidAlice');
    final container = ProviderContainer(overrides: [
      hiveStorageServiceProvider.overrideWithValue(storage),
      localDataUidProvider.overrideWith((ref) => ref.watch(signedIn)),
    ]);
    addTearDown(container.dispose);

    uid = 'uidAlice';
    await storage.saveRace(_race('Alice'));
    uid = 'uidBob';
    await storage.saveRace(_race('Bob'));

    uid = 'uidAlice';
    expect(container.read(currentRaceProvider)?.raceName, 'Alice');
    uid = 'uidBob';
    container.read(signedIn.notifier).state = 'uidBob';
    expect(container.read(currentRaceProvider)?.raceName, 'Bob');
  });

  test('the daily reward message shows the tickets the server added', () async {
    final ja = await AppLocalizations.delegate.load(const Locale('ja'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(ja.homeDailySuccess(1), 'デイリー報酬を受け取りました！+1チケット');
    expect(ja.homeDailySuccess(15), contains('+15チケット'));
    expect(en.homeDailySuccess(10), 'Daily reward claimed! +10 tickets');
  });

  test('the guest texts promise only what the account keeps', () async {
    final ja = await AppLocalizations.delegate.load(const Locale('ja'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    // Tickets, plan and the pack are on the server; races, war history and
    // saved strategies stay on the phone, even after linking an email.
    for (final text in [
      ja.homeLinkAccountBanner,
      ja.authGuestProgressWarning,
      ja.authLinkSubtitle,
    ]) {
      expect(text, isNot(anyOf(contains('同期'), contains('永久'), contains('進捗'))));
    }
    for (final text in [
      en.homeLinkAccountBanner,
      en.authGuestProgressWarning,
      en.authLinkSubtitle,
    ]) {
      expect(
        text.toLowerCase(),
        isNot(anyOf(contains('sync'), contains('permanent'), contains('progress'),
            contains('across devices'))),
      );
    }
    expect(ja.authLinkSubtitle, contains('この端末に保存されます'));
    expect(en.authLinkSubtitle, contains('saved on this phone'));
  });
}
