// GENERATED CODE - Manual TypeAdapter for WarHistoryModel
// Since we cannot run build_runner, this is manually written.

part of 'war_history_model.dart';

class WarHistoryModelAdapter extends TypeAdapter<WarHistoryModel> {
  @override
  final int typeId = 1;

  @override
  WarHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WarHistoryModel(
      id: fields[0] as String,
      sourceRecordId: fields[1] as String,
      longNarrative: fields[2] as String,
      createdAt: fields[3] as DateTime,
      sharedToX: fields[4] as bool,
      title: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WarHistoryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sourceRecordId)
      ..writeByte(2)
      ..write(obj.longNarrative)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.sharedToX)
      ..writeByte(5)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WarHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
