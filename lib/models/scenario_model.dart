/// The top-level battle category this scenario belongs to.
/// "standard" → Practice / Normal / Tabletop / Epic sub-modes
/// "boss"     → Boss Battle (fixed boss mode, no sub-mode picker)
/// "history"  → History Puzzle (fixed history_puzzle mode, fixed stats)
enum BattleType { standard, boss, history }

class ScenarioModel {
  final String scenarioId;
  final String worldviewKey;
  final String title;
  final String? titleJa;
  final int difficulty; // 1-5
  final String enemyName;
  final String? enemyNameJa;
  final Map<String, int> enemyStats;
  final String commanderDefinition;
  final String? commanderDefinitionJa;
  final bool isUnlocked;
  final bool isFree;
  final BattleType battleType;

  const ScenarioModel({
    required this.scenarioId,
    required this.worldviewKey,
    required this.title,
    this.titleJa,
    required this.difficulty,
    required this.enemyName,
    this.enemyNameJa,
    required this.enemyStats,
    required this.commanderDefinition,
    this.commanderDefinitionJa,
    required this.isUnlocked,
    required this.isFree,
    this.battleType = BattleType.standard,
  });

  String localizedTitle(String languageCode) =>
      languageCode == 'ja' && titleJa != null ? titleJa! : title;

  String localizedEnemyName(String languageCode) =>
      languageCode == 'ja' && enemyNameJa != null ? enemyNameJa! : enemyName;

  String localizedCommanderDefinition(String languageCode) =>
      languageCode == 'ja' && commanderDefinitionJa != null
          ? commanderDefinitionJa!
          : commanderDefinition;

  factory ScenarioModel.fromJson(Map<String, dynamic> json) {
    return ScenarioModel(
      scenarioId: json['scenarioId'] as String? ?? '',
      worldviewKey: json['worldviewKey'] as String? ?? '1830_fantasy',
      title: json['title'] as String? ?? 'Unknown Scenario',
      titleJa: json['titleJa'] as String?,
      difficulty: json['difficulty'] as int? ?? 1,
      enemyName: json['enemyName'] as String? ?? 'Unknown Enemy',
      enemyNameJa: json['enemyNameJa'] as String?,
      enemyStats: (json['enemyStats'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          {},
      commanderDefinition: json['commanderDefinition'] as String? ?? '',
      commanderDefinitionJa: json['commanderDefinitionJa'] as String?,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isFree: json['isFree'] as bool? ?? false,
      battleType: _parseBattleType(json['battleType'] as String?),
    );
  }

  static BattleType _parseBattleType(String? raw) {
    switch (raw) {
      case 'boss': return BattleType.boss;
      case 'history': return BattleType.history;
      default: return BattleType.standard;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'scenarioId': scenarioId,
      'worldviewKey': worldviewKey,
      'title': title,
      if (titleJa != null) 'titleJa': titleJa,
      'difficulty': difficulty,
      'enemyName': enemyName,
      if (enemyNameJa != null) 'enemyNameJa': enemyNameJa,
      'enemyStats': enemyStats,
      'commanderDefinition': commanderDefinition,
      if (commanderDefinitionJa != null) 'commanderDefinitionJa': commanderDefinitionJa,
      'isUnlocked': isUnlocked,
      'isFree': isFree,
      'battleType': battleType.name,
    };
  }

  ScenarioModel copyWith({
    String? scenarioId,
    String? worldviewKey,
    String? title,
    String? titleJa,
    int? difficulty,
    String? enemyName,
    String? enemyNameJa,
    Map<String, int>? enemyStats,
    String? commanderDefinition,
    String? commanderDefinitionJa,
    bool? isUnlocked,
    bool? isFree,
    BattleType? battleType,
  }) {
    return ScenarioModel(
      scenarioId: scenarioId ?? this.scenarioId,
      worldviewKey: worldviewKey ?? this.worldviewKey,
      title: title ?? this.title,
      titleJa: titleJa ?? this.titleJa,
      difficulty: difficulty ?? this.difficulty,
      enemyName: enemyName ?? this.enemyName,
      enemyNameJa: enemyNameJa ?? this.enemyNameJa,
      enemyStats: enemyStats ?? this.enemyStats,
      commanderDefinition: commanderDefinition ?? this.commanderDefinition,
      commanderDefinitionJa: commanderDefinitionJa ?? this.commanderDefinitionJa,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isFree: isFree ?? this.isFree,
      battleType: battleType ?? this.battleType,
    );
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 1:
        return 'Novice';
      case 2:
        return 'Soldier';
      case 3:
        return 'Captain';
      case 4:
        return 'General';
      case 5:
        return 'Warlord';
      default:
        return 'Unknown';
    }
  }

  /// Returns default sample scenarios for offline/fallback mode.
  static List<ScenarioModel> defaults() {
    return [
      ScenarioModel(
        scenarioId: 'scenario_001',
        worldviewKey: '1830_fantasy',
        title: 'The Border Skirmish',
        titleJa: '国境の小競り合い',
        difficulty: 1,
        enemyName: 'Bandit Horde',
        enemyNameJa: '盗賊の大群',
        enemyStats: {
          'attack': 3,
          'defense': 2,
          'speed': 4,
          'morale': 2,
          'magic': 0,
          'leadership': 2,
        },
        commanderDefinition: 'A disorganized bandit force threatening the western border.',
        commanderDefinitionJa: '西の国境を脅かす統率のとれていない盗賊集団。',
        isUnlocked: true,
        isFree: true,
      ),
      ScenarioModel(
        scenarioId: 'scenario_002',
        worldviewKey: '1830_fantasy',
        title: 'Siege of Iron Keep',
        titleJa: '鉄の砦の包囲戦',
        difficulty: 3,
        enemyName: 'Imperial Garrison',
        enemyNameJa: '帝国の守備隊',
        enemyStats: {
          'attack': 5,
          'defense': 8,
          'speed': 2,
          'morale': 6,
          'magic': 1,
          'leadership': 5,
        },
        commanderDefinition: 'A fortified imperial stronghold with seasoned defenders.',
        commanderDefinitionJa: '歴戦の守備兵を擁する帝国の要塞。',
        isUnlocked: false,
        isFree: false,
      ),
      ScenarioModel(
        scenarioId: 'scenario_003',
        worldviewKey: '1830_fantasy',
        title: 'Dragon Valley Assault',
        titleJa: 'ドラゴン谷の強襲',
        difficulty: 5,
        enemyName: 'Dragon Cult Army',
        enemyNameJa: 'ドラゴン教団軍',
        enemyStats: {
          'attack': 9,
          'defense': 6,
          'speed': 5,
          'morale': 8,
          'magic': 10,
          'leadership': 7,
        },
        commanderDefinition: 'A fanatical army empowered by dragon magic.',
        commanderDefinitionJa: 'ドラゴンの魔力で強化された狂信的な軍隊。',
        isUnlocked: false,
        isFree: false,
      ),
    ];
  }
}
