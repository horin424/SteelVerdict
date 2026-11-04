import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/battle_record_model.dart';
import '../../models/war_history_model.dart';
import '../../models/race_model.dart';
import '../../core/constants/app_constants.dart';
import 'local_storage_service.dart';

/// Moves a pre-existing single race into the slot for the worldview it was
/// created in, then removes the old key. Idempotent.
///
/// Must run BEFORE runApp, not from HiveStorageService.initialize(): that runs
/// on the splash screen, by which point currentRaceProvider may already have
/// read Hive, found nothing under the new key, and cached null. The visible
/// symptom is "Create your race to begin" on the first launch after updating,
/// with the race reappearing on the second launch — and a player who taps the
/// banner in that window creates a duplicate.
Future<void> migrateLegacyRaceIfNeeded() async {
  const legacyKey = 'current_race';
  try {
    if (!Hive.isBoxOpen(AppConstants.hiveBoxRace)) return;
    final box = Hive.box(AppConstants.hiveBoxRace);

    final raw = box.get(legacyKey);
    if (raw == null) return;

    final json = jsonDecode(raw as String) as Map<String, dynamic>;
    final race = RaceModel.fromJson(json);
    final key = 'race_${race.worldviewKey}';

    // Don't clobber a race already created for that worldview.
    if (box.get(key) == null) {
      await box.put(key, raw);
    }
    await box.delete(legacyKey);
    debugPrint('Migrated legacy race to $key');
  } catch (e) {
    debugPrint('migrateLegacyRaceIfNeeded error: $e');
  }
}

/// Keys of the phone's game data, per account.
///
/// Races, battle records, war chronicles and saved strategies are kept only on
/// the phone. They used to be shared by every account that signed in there, so
/// a second account saw the first one's races, war history and strategies.
/// Each key now starts with the signed-in account's uid: `u:<uid>|<key>`.
/// Settings (language, volume, the selected world) stay shared by the phone.
class LocalDataKeys {
  LocalDataKeys._();

  /// A key that already belongs to an account. Firebase uids are letters and
  /// digits; anything else is data saved before keys had an owner.
  static final RegExp owned = RegExp(r'^u:[A-Za-z0-9_-]{1,128}\|');

  static String prefix(String uid) => 'u:$uid|';

  /// Hive stores a string key's UTF-8 length in one byte (hive 2.2.3,
  /// BinaryWriterImpl.writeKey), so a longer key corrupts the box file.
  static const int maxKeyBytes = 255;

  /// The key for [key] owned by [uid], shortened (from the end, whole
  /// characters) if it would not fit in [maxKeyBytes].
  static String of(String uid, String key) {
    final p = prefix(uid);
    var runes = key.runes.toList();
    while (runes.isNotEmpty &&
        utf8.encode('$p${String.fromCharCodes(runes)}').length > maxKeyBytes) {
      runes = runes.sublist(0, runes.length - 1);
    }
    return '$p${String.fromCharCodes(runes)}';
  }
}

/// Gives every entry that has no owner yet — data saved before this version —
/// to [uid], in each per-account box that is open (not settings). Returns how
/// many moved.
///
/// The phone's data goes to the account that is signed in when the update first
/// runs; if nobody is, to the first account that signs in. Idempotent, and safe
/// to stop half-way: an entry is copied before its old key is removed.
Future<int> adoptUnownedLocalData(String uid) async {
  var moved = 0;
  // The two typed boxes must be fetched with their type (Hive refuses
  // Hive.box('battle_records') once it is open as Box<BattleRecordModel>), and
  // a HiveObject can live under one key only, so they move as copies.
  if (Hive.isBoxOpen(AppConstants.hiveBoxBattleRecords)) {
    moved += await _adoptIn<BattleRecordModel>(
        Hive.box<BattleRecordModel>(AppConstants.hiveBoxBattleRecords), uid, (v) => v.copyWith());
  }
  if (Hive.isBoxOpen(AppConstants.hiveBoxWarHistories)) {
    moved += await _adoptIn<WarHistoryModel>(
        Hive.box<WarHistoryModel>(AppConstants.hiveBoxWarHistories), uid, (v) => v.copyWith());
  }
  for (final name in [AppConstants.hiveBoxRace, AppConstants.hiveBoxStrategies]) {
    if (Hive.isBoxOpen(name)) moved += await _adoptIn<dynamic>(Hive.box(name), uid, (v) => v);
  }
  if (moved > 0) debugPrint('Gave $moved local entries to the signed-in account');
  return moved;
}

Future<int> _adoptIn<E>(Box<E> box, String uid, E Function(E value) copy) async {
  var moved = 0;
  try {
    final unowned = box.keys
        .whereType<String>()
        .where((k) => !LocalDataKeys.owned.hasMatch(k))
        .toList();
    for (final key in unowned) {
      final target = LocalDataKeys.of(uid, key);
      final value = box.get(key);
      if (!box.containsKey(target) && value != null) await box.put(target, copy(value));
      await box.delete(key);
      moved++;
    }
  } catch (e) {
    debugPrint('adoptUnownedLocalData(${box.name}) error: $e');
  }
  return moved;
}

class HiveStorageService implements LocalStorageService {
  /// The signed-in account (its Firebase uid), or null when signed out. Game
  /// data is read and written for this account only.
  final String? Function() _currentUid;

  HiveStorageService({String? Function()? currentUid})
      : _currentUid = currentUid ?? (() => null);

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

      // Existing players have a single race stored under the old key.
      await _migrateLegacyRace();

      // The battle-record and chronicle boxes open here, not in bootstrap, so
      // their data from before per-account keys is handed over here.
      final uid = _currentUid();
      if (uid != null) await adoptUnownedLocalData(uid);
    } catch (e) {
      debugPrint('HiveStorageService.initialize error: $e');
    }
  }

  /// See [adoptUnownedLocalData]; for a sign-in after start-up.
  Future<int> adoptUnownedData(String uid) => adoptUnownedLocalData(uid);

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

  // ── Per-account keys ───────────────────────────────────────────────────────

  /// The signed-in account's key for [key]; null when nobody is signed in.
  String? _key(String key) {
    final uid = _currentUid();
    return uid == null ? null : LocalDataKeys.of(uid, key);
  }

  /// The signed-in account's entries in [box], keyed without the account
  /// prefix. Empty when nobody is signed in.
  Map<String, E> _mine<E>(Box<E> box) {
    final uid = _currentUid();
    if (uid == null) return {};
    final p = LocalDataKeys.prefix(uid);
    return {
      for (final e in box.toMap().entries)
        if (e.key is String && (e.key as String).startsWith(p))
          (e.key as String).substring(p.length): e.value,
    };
  }

  Future<void> _put<E>(Box<E> box, String key, E value, String what) async {
    final k = _key(key);
    if (k == null) {
      debugPrint('$what skipped: nobody is signed in');
      return;
    }
    await box.put(k, value);
  }

  Future<void> _delete<E>(Box<E> box, String key) async {
    final k = _key(key);
    if (k != null) await box.delete(k);
  }

  @override
  Future<void> saveBattleRecord(BattleRecordModel record) async {
    try {
      await _put(_battles, record.id, record, 'saveBattleRecord');
    } catch (e) {
      debugPrint('saveBattleRecord error: $e');
    }
  }

  @override
  List<BattleRecordModel> getBattleRecords() {
    try {
      final records = _mine(_battles).values.toList();
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
      await _delete(_battles, id);
    } catch (e) {
      debugPrint('deleteBattleRecord error: $e');
    }
  }

  @override
  Future<void> updateBattleRecord(BattleRecordModel record) async {
    try {
      await _put(_battles, record.id, record, 'updateBattleRecord');
    } catch (e) {
      debugPrint('updateBattleRecord error: $e');
    }
  }

  @override
  Future<void> saveWarHistory(WarHistoryModel history) async {
    try {
      await _put(_histories, history.id, history, 'saveWarHistory');
    } catch (e) {
      debugPrint('saveWarHistory error: $e');
    }
  }

  @override
  List<WarHistoryModel> getWarHistories() {
    try {
      final histories = _mine(_histories).values.toList();
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
      await _delete(_histories, id);
    } catch (e) {
      debugPrint('deleteWarHistory error: $e');
    }
  }

  // ── Race ───────────────────────────────────────────────────────────────────
  // Each worldview defines its own stats, so a race belongs to one worldview.
  // Stored one per worldview under 'race_<worldviewKey>' (per account).

  static String _raceKey(String worldviewKey) => 'race_$worldviewKey';

  /// Safety net only — the real call happens in bootstrap before runApp.
  /// Idempotent, so running it twice is harmless.
  Future<void> _migrateLegacyRace() => migrateLegacyRaceIfNeeded();

  @override
  Future<void> saveRace(RaceModel race) async {
    try {
      await _put(_race, _raceKey(race.worldviewKey), jsonEncode(race.toJson()), 'saveRace');
    } catch (e) {
      debugPrint('saveRace error: $e');
    }
  }

  @override
  RaceModel? getRace(String worldviewKey) {
    try {
      final k = _key(_raceKey(worldviewKey));
      if (k == null) return null;
      final raw = _race.get(k);
      if (raw == null) return null;
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      return RaceModel.fromJson(json);
    } catch (e) {
      debugPrint('getRace error: $e');
      return null;
    }
  }

  @override
  Future<void> deleteRace(String worldviewKey) async {
    try {
      await _delete(_race, _raceKey(worldviewKey));
    } catch (e) {
      debugPrint('deleteRace error: $e');
    }
  }

  @override
  Future<void> saveStrategy(String name, String text) async {
    try {
      await _put(_strategies, name, text, 'saveStrategy');
    } catch (e) {
      debugPrint('saveStrategy error: $e');
    }
  }

  @override
  List<MapEntry<String, String>> getStrategies() {
    try {
      return _mine(_strategies)
          .entries
          .map((e) => MapEntry(e.key, e.value.toString()))
          .toList();
    } catch (e) {
      debugPrint('getStrategies error: $e');
      return [];
    }
  }

  @override
  Future<void> deleteStrategy(String name) async {
    try {
      await _delete(_strategies, name);
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

  /// Removes the signed-in account's game data on this phone and the phone's
  /// settings. Other accounts' data on the phone stays. With nobody signed in,
  /// removes everything.
  @override
  Future<void> clearAll() async {
    try {
      final uid = _currentUid();
      if (uid == null) {
        await _battles.clear();
        await _histories.clear();
        await _race.clear();
        await _strategies.clear();
      } else {
        final p = LocalDataKeys.prefix(uid);
        bool mine(dynamic k) => k is String && k.startsWith(p);
        await _battles.deleteAll(_battles.keys.where(mine).toList());
        await _histories.deleteAll(_histories.keys.where(mine).toList());
        await _race.deleteAll(_race.keys.where(mine).toList());
        await _strategies.deleteAll(_strategies.keys.where(mine).toList());
      }
      await _settings.clear();
    } catch (e) {
      debugPrint('clearAll error: $e');
    }
  }
}
