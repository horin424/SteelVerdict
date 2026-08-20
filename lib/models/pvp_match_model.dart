enum PvpMatchStatus {
  waiting,
  active,
  resolved,
  timeout;

  static PvpMatchStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return PvpMatchStatus.active;
      case 'resolved':
        return PvpMatchStatus.resolved;
      case 'timeout':
        return PvpMatchStatus.timeout;
      default:
        return PvpMatchStatus.waiting;
    }
  }

  String get displayName {
    switch (this) {
      case PvpMatchStatus.waiting:
        return 'Waiting';
      case PvpMatchStatus.active:
        return 'Active';
      case PvpMatchStatus.resolved:
        return 'Resolved';
      case PvpMatchStatus.timeout:
        return 'Timed Out';
    }
  }
}

class PvpMatchModel {
  final String matchId;
  final String playerAUid;
  final String playerBUid;
  final String playerARaceName;
  final String playerBRaceName;
  final Map<String, int> playerAStats;
  final Map<String, int> playerBStats;
  final String playerAStrategy;
  final String playerBStrategy;
  final String shortReport;
  final String winner; // uid of winner, or 'draw', or ''
  final PvpMatchStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  const PvpMatchModel({
    required this.matchId,
    required this.playerAUid,
    required this.playerBUid,
    required this.playerARaceName,
    required this.playerBRaceName,
    required this.playerAStats,
    required this.playerBStats,
    required this.playerAStrategy,
    required this.playerBStrategy,
    required this.shortReport,
    required this.winner,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  factory PvpMatchModel.fromJson(Map<String, dynamic> json) {
    return PvpMatchModel(
      matchId: json['matchId'] as String? ?? '',
      playerAUid: json['playerAUid'] as String? ?? '',
      playerBUid: json['playerBUid'] as String? ?? '',
      playerARaceName: json['playerARaceName'] as String? ?? '',
      playerBRaceName: json['playerBRaceName'] as String? ?? '',
      playerAStats: (json['playerAStats'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          {},
      playerBStats: (json['playerBStats'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          {},
      playerAStrategy: json['playerAStrategy'] as String? ?? '',
      playerBStrategy: json['playerBStrategy'] as String? ?? '',
      shortReport: json['shortReport'] as String? ?? '',
      winner: json['winner'] as String? ?? '',
      status: PvpMatchStatus.fromString(json['status'] as String? ?? 'waiting'),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int)
          : DateTime.now().add(const Duration(hours: 24)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'playerAUid': playerAUid,
      'playerBUid': playerBUid,
      'playerARaceName': playerARaceName,
      'playerBRaceName': playerBRaceName,
      'playerAStats': playerAStats,
      'playerBStats': playerBStats,
      'playerAStrategy': playerAStrategy,
      'playerBStrategy': playerBStrategy,
      'shortReport': shortReport,
      'winner': winner,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    };
  }

  PvpMatchModel copyWith({
    String? matchId,
    String? playerAUid,
    String? playerBUid,
    String? playerARaceName,
    String? playerBRaceName,
    Map<String, int>? playerAStats,
    Map<String, int>? playerBStats,
    String? playerAStrategy,
    String? playerBStrategy,
    String? shortReport,
    String? winner,
    PvpMatchStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return PvpMatchModel(
      matchId: matchId ?? this.matchId,
      playerAUid: playerAUid ?? this.playerAUid,
      playerBUid: playerBUid ?? this.playerBUid,
      playerARaceName: playerARaceName ?? this.playerARaceName,
      playerBRaceName: playerBRaceName ?? this.playerBRaceName,
      playerAStats: playerAStats ?? this.playerAStats,
      playerBStats: playerBStats ?? this.playerBStats,
      playerAStrategy: playerAStrategy ?? this.playerAStrategy,
      playerBStrategy: playerBStrategy ?? this.playerBStrategy,
      shortReport: shortReport ?? this.shortReport,
      winner: winner ?? this.winner,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool hasPlayerSubmitted(String uid) {
    if (uid == playerAUid) return playerAStrategy.isNotEmpty;
    if (uid == playerBUid) return playerBStrategy.isNotEmpty;
    return false;
  }
}
