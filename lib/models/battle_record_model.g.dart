// GENERATED CODE - Manual TypeAdapter for BattleRecordModel
// Since we cannot run build_runner, this is manually written.

part of 'battle_record_model.dart';

class BattleRecordModelAdapter extends TypeAdapter<BattleRecordModel> {
  @override
  final int typeId = 0;

  @override
  BattleRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BattleRecordModel(
      id: fields[0] as String,
      scenarioId: fields[1] as String,
      gameMode: fields[2] as String,
      playerStrategy: fields[3] as String,
      aiReport: fields[4] as String,
      playerStats: (fields[5] as Map).cast<String, int>(),
      outcome: fields[6] as String,
      createdAt: fields[7] as DateTime,
      isFavorite: fields[8] as bool,
      scenarioTitle: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BattleRecordModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.scenarioId)
      ..writeByte(2)
      ..write(obj.gameMode)
      ..writeByte(3)
      ..write(obj.playerStrategy)
      ..writeByte(4)
      ..write(obj.aiReport)
      ..writeByte(5)
      ..write(obj.playerStats)
      ..writeByte(6)
      ..write(obj.outcome)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.isFavorite)
      ..writeByte(9)
      ..write(obj.scenarioTitle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattleRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
