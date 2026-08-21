import '../../models/battle_record_model.dart';
import '../../models/war_history_model.dart';
import '../../models/race_model.dart';

abstract class LocalStorageService {
  // Battle Records
  Future<void> saveBattleRecord(BattleRecordModel record);
  List<BattleRecordModel> getBattleRecords();
  Future<void> deleteBattleRecord(String id);
  Future<void> updateBattleRecord(BattleRecordModel record);

  // War Histories
  Future<void> saveWarHistory(WarHistoryModel history);
  List<WarHistoryModel> getWarHistories();
  Future<void> deleteWarHistory(String id);

  // Race — a race belongs to a worldview, because each worldview defines its
  // own stats. A player can hold one race per worldview.
  Future<void> saveRace(RaceModel race);
  RaceModel? getRace(String worldviewKey);
  Future<void> deleteRace(String worldviewKey);

  // Strategies
  Future<void> saveStrategy(String name, String text);
  List<MapEntry<String, String>> getStrategies();
  Future<void> deleteStrategy(String name);

  // Settings
  Future<void> saveSetting(String key, dynamic value);
  dynamic getSetting(String key, {dynamic defaultValue});

  // Clear all data
  Future<void> clearAll();
}
