/// The AI model choice for battle judging.
enum ModelChoice {
  gemini,
  claude;

  String get displayName {
    switch (this) {
      case ModelChoice.gemini:
        return 'Gemini';
      case ModelChoice.claude:
        return 'Claude';
    }
  }
}

/// Request payload for the battle API.
class BattleRequest {
  final String playerStrategy;
  final Map<String, int> raceStats;
  final String scenarioId;
  final String gameMode;
  final ModelChoice modelChoice;
  final String? raceName;
  final String? worldviewKey;
  final String? locale;

  const BattleRequest({
    required this.playerStrategy,
    required this.raceStats,
    required this.scenarioId,
    required this.gameMode,
    required this.modelChoice,
    this.raceName,
    this.worldviewKey,
    this.locale,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerStrategy': playerStrategy,
      'raceStats': raceStats,
      'scenarioId': scenarioId,
      'gameMode': gameMode,
      'modelChoice': modelChoice.name,
      if (raceName != null) 'raceName': raceName,
      if (worldviewKey != null) 'worldviewKey': worldviewKey,
      if (locale != null) 'locale': locale,
    };
  }
}

/// Response from the battle API.
class BattleResponse {
  final String reportText;
  final String outcome; // 'win', 'loss', 'draw'
  final String shortSummary;
  final int ticketsConsumed;
  final Map<String, dynamic>? extraData;

  const BattleResponse({
    required this.reportText,
    required this.outcome,
    required this.shortSummary,
    required this.ticketsConsumed,
    this.extraData,
  });

  factory BattleResponse.fromJson(Map<String, dynamic> json) {
    return BattleResponse(
      reportText: json['reportText'] as String? ?? '',
      outcome: json['outcome'] as String? ?? 'draw',
      shortSummary: json['shortSummary'] as String? ?? '',
      ticketsConsumed: json['ticketsConsumed'] as int? ?? 1,
      extraData: json['extraData'] as Map<String, dynamic>?,
    );
  }
}

abstract class BattleApiService {
  /// Submit a battle request and get an AI-judged result.
  Future<BattleResponse> submitBattle(BattleRequest request);
}
