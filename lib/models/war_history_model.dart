import 'package:hive/hive.dart';

part 'war_history_model.g.dart';

@HiveType(typeId: 1)
class WarHistoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sourceRecordId;

  @HiveField(2)
  final String longNarrative;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  bool sharedToX;

  @HiveField(5)
  final String title;

  WarHistoryModel({
    required this.id,
    required this.sourceRecordId,
    required this.longNarrative,
    required this.createdAt,
    required this.sharedToX,
    required this.title,
  });

  factory WarHistoryModel.fromJson(Map<String, dynamic> json) {
    return WarHistoryModel(
      id: json['id'] as String? ?? '',
      sourceRecordId: json['sourceRecordId'] as String? ?? '',
      longNarrative: json['longNarrative'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
      sharedToX: json['sharedToX'] as bool? ?? false,
      title: json['title'] as String? ?? 'War Chronicle',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceRecordId': sourceRecordId,
      'longNarrative': longNarrative,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'sharedToX': sharedToX,
      'title': title,
    };
  }

  WarHistoryModel copyWith({
    String? id,
    String? sourceRecordId,
    String? longNarrative,
    DateTime? createdAt,
    bool? sharedToX,
    String? title,
  }) {
    return WarHistoryModel(
      id: id ?? this.id,
      sourceRecordId: sourceRecordId ?? this.sourceRecordId,
      longNarrative: longNarrative ?? this.longNarrative,
      createdAt: createdAt ?? this.createdAt,
      sharedToX: sharedToX ?? this.sharedToX,
      title: title ?? this.title,
    );
  }
}
