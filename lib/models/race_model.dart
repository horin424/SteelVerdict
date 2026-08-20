import 'package:uuid/uuid.dart';

class RaceModel {
  final String id;
  final String raceName;
  final String worldviewKey;
  final Map<String, int> stats;
  final String overview;
  final DateTime createdAt;

  const RaceModel({
    required this.id,
    required this.raceName,
    required this.worldviewKey,
    required this.stats,
    this.overview = '',
    required this.createdAt,
  });

  factory RaceModel.create({
    required String raceName,
    required String worldviewKey,
    required Map<String, int> stats,
    String overview = '',
  }) {
    return RaceModel(
      id: const Uuid().v4(),
      raceName: raceName,
      worldviewKey: worldviewKey,
      stats: stats,
      overview: overview,
      createdAt: DateTime.now(),
    );
  }

  factory RaceModel.fromJson(Map<String, dynamic> json) {
    return RaceModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      raceName: json['raceName'] as String? ?? '',
      worldviewKey: json['worldviewKey'] as String? ?? '1830_fantasy',
      stats: (json['stats'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          {},
      overview: json['overview'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'raceName': raceName,
      'worldviewKey': worldviewKey,
      'stats': stats,
      'overview': overview,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  RaceModel copyWith({
    String? id,
    String? raceName,
    String? worldviewKey,
    Map<String, int>? stats,
    String? overview,
    DateTime? createdAt,
  }) {
    return RaceModel(
      id: id ?? this.id,
      raceName: raceName ?? this.raceName,
      worldviewKey: worldviewKey ?? this.worldviewKey,
      stats: stats ?? this.stats,
      overview: overview ?? this.overview,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get totalStatPoints => stats.values.fold(0, (sum, v) => sum + v);
}
