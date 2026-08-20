import 'package:hive/hive.dart';

part 'battle_record_model.g.dart';

enum GameMode {
  normal,
  tabletop,
  epic,
  boss,
  practice;

  String get displayName {
    switch (this) {
      case GameMode.normal:
        return 'Normal';
      case GameMode.tabletop:
        return 'Tabletop';
      case GameMode.epic:
        return 'Epic';
      case GameMode.boss:
        return 'Boss';
      case GameMode.practice:
        return 'Practice';
    }
  }

  static GameMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'tabletop':
        return GameMode.tabletop;
      case 'epic':
        return GameMode.epic;
      case 'boss':
        return GameMode.boss;
      case 'practice':
        return GameMode.practice;
      default:
        return GameMode.normal;
    }
  }
}

enum BattleOutcome {
  win,
  loss,
  draw;

  String get displayName {
    switch (this) {
      case BattleOutcome.win:
        return 'Victory';
      case BattleOutcome.loss:
        return 'Defeat';
      case BattleOutcome.draw:
        return 'Draw';
    }
  }

  static BattleOutcome fromString(String value) {
    switch (value.toLowerCase()) {
      case 'win':
      case 'victory':
        return BattleOutcome.win;
      case 'loss':
      case 'defeat':
        return BattleOutcome.loss;
      default:
        return BattleOutcome.draw;
    }
  }
}

@HiveType(typeId: 0)
class BattleRecordModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String scenarioId;

  @HiveField(2)
  final String gameMode;

  @HiveField(3)
  final String playerStrategy;

  @HiveField(4)
  final String aiReport;

  @HiveField(5)
  final Map<String, int> playerStats;

  @HiveField(6)
  final String outcome;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  bool isFavorite;

  @HiveField(9)
  final String scenarioTitle;

  BattleRecordModel({
    required this.id,
    required this.scenarioId,
    required this.gameMode,
    required this.playerStrategy,
    required this.aiReport,
    required this.playerStats,
    required this.outcome,
    required this.createdAt,
    required this.isFavorite,
    required this.scenarioTitle,
  });

  GameMode get gameModeEnum => GameMode.fromString(gameMode);
  BattleOutcome get outcomeEnum => BattleOutcome.fromString(outcome);

  factory BattleRecordModel.fromJson(Map<String, dynamic> json) {
    return BattleRecordModel(
      id: json['id'] as String? ?? '',
      scenarioId: json['scenarioId'] as String? ?? '',
      gameMode: json['gameMode'] as String? ?? 'normal',
      playerStrategy: json['playerStrategy'] as String? ?? '',
      aiReport: json['aiReport'] as String? ?? '',
      playerStats: (json['playerStats'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          {},
      outcome: json['outcome'] as String? ?? 'draw',
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      scenarioTitle: json['scenarioTitle'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenarioId': scenarioId,
      'gameMode': gameMode,
      'playerStrategy': playerStrategy,
      'aiReport': aiReport,
      'playerStats': playerStats,
      'outcome': outcome,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isFavorite': isFavorite,
      'scenarioTitle': scenarioTitle,
    };
  }

  BattleRecordModel copyWith({
    String? id,
    String? scenarioId,
    String? gameMode,
    String? playerStrategy,
    String? aiReport,
    Map<String, int>? playerStats,
    String? outcome,
    DateTime? createdAt,
    bool? isFavorite,
    String? scenarioTitle,
  }) {
    return BattleRecordModel(
      id: id ?? this.id,
      scenarioId: scenarioId ?? this.scenarioId,
      gameMode: gameMode ?? this.gameMode,
      playerStrategy: playerStrategy ?? this.playerStrategy,
      aiReport: aiReport ?? this.aiReport,
      playerStats: playerStats ?? this.playerStats,
      outcome: outcome ?? this.outcome,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      scenarioTitle: scenarioTitle ?? this.scenarioTitle,
    );
  }
}
