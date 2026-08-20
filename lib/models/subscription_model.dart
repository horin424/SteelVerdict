import 'user_model.dart';

class SubscriptionModel {
  final SubscriptionTier tier;
  final int dailyTickets;
  final bool isEpicEnabled;
  final bool isUnlimitedHistory;
  final int maxSavedStrategies;
  final DateTime? expiresAt;

  const SubscriptionModel({
    required this.tier,
    required this.dailyTickets,
    required this.isEpicEnabled,
    required this.isUnlimitedHistory,
    required this.maxSavedStrategies,
    this.expiresAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      tier: SubscriptionTier.fromString(json['tier'] as String? ?? 'free'),
      dailyTickets: json['dailyTickets'] as int? ?? 3,
      isEpicEnabled: json['isEpicEnabled'] as bool? ?? false,
      isUnlimitedHistory: json['isUnlimitedHistory'] as bool? ?? false,
      maxSavedStrategies: json['maxSavedStrategies'] as int? ?? 5,
      expiresAt: json['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier.name,
      'dailyTickets': dailyTickets,
      'isEpicEnabled': isEpicEnabled,
      'isUnlimitedHistory': isUnlimitedHistory,
      'maxSavedStrategies': maxSavedStrategies,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
    };
  }

  SubscriptionModel copyWith({
    SubscriptionTier? tier,
    int? dailyTickets,
    bool? isEpicEnabled,
    bool? isUnlimitedHistory,
    int? maxSavedStrategies,
    DateTime? expiresAt,
  }) {
    return SubscriptionModel(
      tier: tier ?? this.tier,
      dailyTickets: dailyTickets ?? this.dailyTickets,
      isEpicEnabled: isEpicEnabled ?? this.isEpicEnabled,
      isUnlimitedHistory: isUnlimitedHistory ?? this.isUnlimitedHistory,
      maxSavedStrategies: maxSavedStrategies ?? this.maxSavedStrategies,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isActive {
    if (tier == SubscriptionTier.free) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!);
  }

  static SubscriptionModel forTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return const SubscriptionModel(
          tier: SubscriptionTier.free,
          dailyTickets: 3,
          isEpicEnabled: false,
          isUnlimitedHistory: false,
          maxSavedStrategies: 5,
        );
      case SubscriptionTier.sub500:
        return const SubscriptionModel(
          tier: SubscriptionTier.sub500,
          dailyTickets: 10,
          isEpicEnabled: false,
          isUnlimitedHistory: false,
          maxSavedStrategies: 20,
        );
      case SubscriptionTier.sub1000:
        return const SubscriptionModel(
          tier: SubscriptionTier.sub1000,
          dailyTickets: 20,
          isEpicEnabled: true,
          isUnlimitedHistory: true,
          maxSavedStrategies: 50,
        );
      case SubscriptionTier.sub3000:
        return const SubscriptionModel(
          tier: SubscriptionTier.sub3000,
          dailyTickets: 50,
          isEpicEnabled: true,
          isUnlimitedHistory: true,
          maxSavedStrategies: 999,
        );
    }
  }
}
