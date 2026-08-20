import 'package:hive/hive.dart';
import '../models/battle_record_model.dart';
import '../models/war_history_model.dart';

/// Registers all Hive TypeAdapters.
/// Call this before opening any boxes.
void registerHiveAdapters() {
  // Register BattleRecordModel adapter (typeId: 0)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BattleRecordModelAdapter());
  }

  // Register WarHistoryModel adapter (typeId: 1)
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(WarHistoryModelAdapter());
  }
}
