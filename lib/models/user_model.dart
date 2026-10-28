enum SubscriptionTier {
  free,
  sub500,
  sub1000,
  sub3000;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.sub500:
        return 'Commander (¥500)';
      case SubscriptionTier.sub1000:
        return 'General (¥1,000)';
      case SubscriptionTier.sub3000:
        return 'Warlord (¥3,000)';
    }
  }

  static SubscriptionTier fromString(String value) {
    switch (value) {
      case 'sub500':
        return SubscriptionTier.sub500;
      case 'sub1000':
        return SubscriptionTier.sub1000;
      case 'sub3000':
        return SubscriptionTier.sub3000;
      default:
        return SubscriptionTier.free;
    }
  }
}

class UserModel {
  final String uid;
  final String displayName;
  final int ticketCount;
  final SubscriptionTier subscriptionTier;
  final DateTime lastLoginAt;
  final DateTime createdAt;
  final bool isBossEnabled;
  final int totalWins;
  final int totalLosses;
  final DateTime? lastDailyRewardAt;

  /// The scenario pack (古代バトルパック) is owned (set by validatePurchase).
  final bool scenarioPack1Unlocked;

  /// The scenarios chosen with the pack (saved by chooseScenarioPack, final).
  /// Empty until the player chooses.
  final List<String> packScenarioIds;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.ticketCount,
    required this.subscriptionTier,
    required this.lastLoginAt,
    required this.createdAt,
    required this.isBossEnabled,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.lastDailyRewardAt,
    this.scenarioPack1Unlocked = false,
    this.packScenarioIds = const [],
  });

  /// The pack is owned and its scenarios are still to be chosen.
  bool get canChoosePackScenarios => scenarioPack1Unlocked && packScenarioIds.isEmpty;

  /// The scenarios the pack unlocks for this account (none if the pack has
  /// moved to another account or been refunded).
  Set<String> get packUnlockedScenarioIds =>
      scenarioPack1Unlocked ? packScenarioIds.toSet() : const <String>{};

  /// What older server code stored as every guest's name, in English.
  static const legacyGuestName = 'Anonymous Commander';

  /// The player's own name, or null for a guest (nothing stored, or the old
  /// English placeholder), so screens show the translated anonymousCommander.
  String? get nameOrNull {
    final name = displayName.trim();
    return name.isEmpty || name == legacyGuestName ? null : name;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return fallback;
    }

    return UserModel(
      uid: json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      ticketCount: asInt(json['ticketCount']),
      subscriptionTier: SubscriptionTier.fromString(
        json['subscriptionTier'] as String? ?? 'free',
      ),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(asInt(json['lastLoginAt']))
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(asInt(json['createdAt']))
          : DateTime.now(),
      isBossEnabled: json['isBossEnabled'] as bool? ?? false,
      totalWins: asInt(json['totalWins']),
      totalLosses: asInt(json['totalLosses']),
      lastDailyRewardAt: json['lastDailyRewardAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(asInt(json['lastDailyRewardAt']))
          : null,
      scenarioPack1Unlocked: json['scenarioPack1Unlocked'] as bool? ?? false,
      packScenarioIds: json['scenarioPack1Picks'] is List
          ? List<String>.unmodifiable((json['scenarioPack1Picks'] as List).whereType<String>())
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'ticketCount': ticketCount,
      'subscriptionTier': subscriptionTier.name,
      'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isBossEnabled': isBossEnabled,
      'totalWins': totalWins,
      'totalLosses': totalLosses,
      if (lastDailyRewardAt != null)
        'lastDailyRewardAt': lastDailyRewardAt!.millisecondsSinceEpoch,
      'scenarioPack1Unlocked': scenarioPack1Unlocked,
      if (packScenarioIds.isNotEmpty) 'scenarioPack1Picks': packScenarioIds,
    };
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    int? ticketCount,
    SubscriptionTier? subscriptionTier,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    bool? isBossEnabled,
    int? totalWins,
    int? totalLosses,
    DateTime? lastDailyRewardAt,
    bool? scenarioPack1Unlocked,
    List<String>? packScenarioIds,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      ticketCount: ticketCount ?? this.ticketCount,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      isBossEnabled: isBossEnabled ?? this.isBossEnabled,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      lastDailyRewardAt: lastDailyRewardAt ?? this.lastDailyRewardAt,
      scenarioPack1Unlocked: scenarioPack1Unlocked ?? this.scenarioPack1Unlocked,
      packScenarioIds: packScenarioIds ?? this.packScenarioIds,
    );
  }

  factory UserModel.empty(String uid) {
    return UserModel(
      uid: uid,
      displayName: '',
      ticketCount: 3,
      subscriptionTier: SubscriptionTier.free,
      lastLoginAt: DateTime.now(),
      createdAt: DateTime.now(),
      isBossEnabled: false,
      totalWins: 0,
      totalLosses: 0,
    );
  }
}
