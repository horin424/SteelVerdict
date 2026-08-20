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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Anonymous Commander',
      ticketCount: json['ticketCount'] as int? ?? 0,
      subscriptionTier: SubscriptionTier.fromString(
        json['subscriptionTier'] as String? ?? 'free',
      ),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastLoginAt'] as int)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
      isBossEnabled: json['isBossEnabled'] as bool? ?? false,
      totalWins: json['totalWins'] as int? ?? 0,
      totalLosses: json['totalLosses'] as int? ?? 0,
      lastDailyRewardAt: json['lastDailyRewardAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastDailyRewardAt'] as int)
          : null,
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
    );
  }

  factory UserModel.empty(String uid) {
    return UserModel(
      uid: uid,
      displayName: 'Anonymous Commander',
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
