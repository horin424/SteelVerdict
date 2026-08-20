import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/battle_record_model.dart';
import '../../models/war_history_model.dart';
import '../../models/race_model.dart';
import '../../core/constants/app_constants.dart';
import 'local_storage_service.dart';

class HiveStorageService implements LocalStorageService {
  Box<BattleRecordModel>? _battleRecordsBox;
  Box<WarHistoryModel>? _warHistoriesBox;
  Box<dynamic>? _raceBox;
  Box<dynamic>? _strategiesBox;
  Box<dynamic>? _settingsBox;

  Future<void> initialize() async {
    try {
      _battleRecordsBox = Hive.isBoxOpen(AppConstants.hiveBoxBattleRecords)
          ? Hive.box<BattleRecordModel>(AppConstants.hiveBoxBattleRecords)
          : await Hive.openBox<BattleRecordModel>(AppConstants.hiveBoxBattleRecords);

      _warHistoriesBox = Hive.isBoxOpen(AppConstants.hiveBoxWarHistories)
          ? Hive.box<WarHistoryModel>(AppConstants.hiveBoxWarHistories)
          : await Hive.openBox<WarHistoryModel>(AppConstants.hiveBoxWarHistories);

      _raceBox = Hive.isBoxOpen(AppConstants.hiveBoxRace)
          ? Hive.box(AppConstants.hiveBoxRace)
          : await Hive.openBox(AppConstants.hiveBoxRace);

      _strategiesBox = Hive.isBoxOpen(AppConstants.hiveBoxStrategies)
          ? Hive.box(AppConstants.hiveBoxStrategies)
          : await Hive.openBox(AppConstants.hiveBoxStrategies);

      _settingsBox = Hive.isBoxOpen(AppConstants.hiveBoxSettings)
          ? Hive.box(AppConstants.hiveBoxSettings)
          : await Hive.openBox(AppConstants.hiveBoxSettings);
    } catch (e) {
      debugPrint('HiveStorageService.initialize error: $e');
    }
  }

  Box<BattleRecordModel> get _battles {
    if (_battleRecordsBox == null || !_battleRecordsBox!.isOpen) {
      if (Hive.isBoxOpen(AppConstants.hiveBoxBattleRecords)) {
        _battleRecordsBox = Hive.box<BattleRecordModel>(AppConstants.hiveBoxBattleRecords);
      } else {
        throw StateError('Battle records box not open. Call initialize() first.');
      }
    }
    return _battleRecordsBox!;
  }

  Box<WarHistoryModel> get _histories {
    if (_warHistoriesBox == null || !_warHistoriesBox!.isOpen) {
      if (Hive.isBoxOpen(AppConstants.hiveBoxWarHistories)) {
        _warHistoriesBox = Hive.box<WarHistoryModel>(AppConstants.hiveBoxWarHistories);
      } else {
        throw StateError('War histories box not open. Call initialize() first.');
      }
    }
    return _warHistoriesBox!;
  }

  Box<dynamic> get _race {
    if (_raceBox == null || !_raceBox!.isOpen) {
      if (Hive.isBoxOpen(AppConstants.hiveBoxRace)) {
        _raceBox = Hive.box(AppConstants.hiveBoxRace);
      } else {
        throw StateError('Race box not open. Call initialize() first.');
      }
    }
    return _raceBox!;
  }

  Box<dynamic> get _strategies {
    if (_strategiesBox == null || !_strategiesBox!.isOpen) {
      if (Hive.isBoxOpen(AppConstants.hiveBoxStrategies)) {
        _strategiesBox = Hive.box(AppConstants.hiveBoxStrategies);
      } else {
        throw StateError('Strategies box not open. Call initialize() first.');
      }
    }
    return _strategiesBox!;
  }

  Box<dynamic> get _settings {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      if (Hive.isBoxOpen(AppConstants.hiveBoxSettings)) {
        _settingsBox = Hive.box(AppConstants.hiveBoxSettings);
      } else {
        throw StateError('Settings box not open. Call initialize() first.');
      }
    }
    return _settingsBox!;
  }

  @override
  Future<void> saveBattleRecord(BattleRecordModel record) async {
    try {
      await _battles.put(record.id, record);
    } catch (e) {
      debugPrint('saveBattleRecord error: $e');
    }
  }

  @override
  List<BattleRecordModel> getBattleRecords() {
    try {
      final records = _battles.values.toList();
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (e) {
      debugPrint('getBattleRecords error: $e');
      return [];
    }
  }

  @override
  Future<void> deleteBattleRecord(String id) async {
    try {
      await _battles.delete(id);
    } catch (e) {
      debugPrint('deleteBattleRecord error: $e');
    }
  }

  @override
  Future<void> updateBattleRecord(BattleRecordModel record) async {
    try {
      await _battles.put(record.id, record);
    } catch (e) {
      debugPrint('updateBattleRecord error: $e');
    }
  }

  @override
  Future<void> saveWarHistory(WarHistoryModel history) async {
    try {
      await _histories.put(history.id, history);
    } catch (e) {
      debugPrint('saveWarHistory error: $e');
    }
  }

  @override
  List<WarHistoryModel> getWarHistories() {
    try {
      final histories = _histories.values.toList();
      histories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return histories;
    } catch (e) {
      debugPrint('getWarHistories error: $e');
      return [];
    }
  }

  @override
  Future<void> deleteWarHistory(String id) async {
    try {
      await _histories.delete(id);
    } catch (e) {
      debugPrint('deleteWarHistory error: $e');
    }
  }

  @override
  Future<void> saveRace(RaceModel race) async {
    try {
      await _race.put('current_race', jsonEncode(race.toJson()));
    } catch (e) {
      debugPrint('saveRace error: $e');
    }
  }

  @override
  RaceModel? getRace() {
    try {
      final raw = _race.get('current_race');
      if (raw == null) return null;
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      return RaceModel.fromJson(json);
    } catch (e) {
      debugPrint('getRace error: $e');
      return null;
    }
  }

  @override
  Future<void> deleteRace() async {
    try {
      await _race.delete('current_race');
    } catch (e) {
      debugPrint('deleteRace error: $e');
    }
  }

  @override
  Future<void> saveStrategy(String name, String text) async {
    try {
      await _strategies.put(name, text);
    } catch (e) {
      debugPrint('saveStrategy error: $e');
    }
  }

  @override
  List<MapEntry<String, String>> getStrategies() {
    try {
      return _strategies.toMap().entries
          .map((e) => MapEntry(e.key.toString(), e.value.toString()))
          .toList();
    } catch (e) {
      debugPrint('getStrategies error: $e');
      return [];
    }
  }

  @override
  Future<void> deleteStrategy(String name) async {
    try {
      await _strategies.delete(name);
    } catch (e) {
      debugPrint('deleteStrategy error: $e');
    }
  }

  @override
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settings.put(key, value);
    } catch (e) {
      debugPrint('saveSetting error: $e');
    }
  }

  @override
  dynamic getSetting(String key, {dynamic defaultValue}) {
    try {
      return _settings.get(key, defaultValue: defaultValue);
    } catch (e) {
      debugPrint('getSetting error: $e');
      return defaultValue;
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _battles.clear();
      await _histories.clear();
      await _race.clear();
      await _strategies.clear();
      await _settings.clear();
    } catch (e) {
      debugPrint('clearAll error: $e');
    }
  }
}
