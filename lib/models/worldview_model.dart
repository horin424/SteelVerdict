class WorldviewModel {
  final String worldviewKey;
  final String title;
  final String? titleJa;
  final List<String> stats;
  // statDescriptions['statKey']['en'] or ['ja']
  final Map<String, Map<String, String>> statDescriptions;
  final String commonJudgment;
  final String worldviewDescription;
  final String? worldviewDescriptionJa;

  const WorldviewModel({
    required this.worldviewKey,
    required this.title,
    this.titleJa,
    required this.stats,
    required this.statDescriptions,
    required this.commonJudgment,
    required this.worldviewDescription,
    this.worldviewDescriptionJa,
  });

  String localizedTitle(String locale) =>
      (locale == 'ja' && titleJa != null && titleJa!.isNotEmpty) ? titleJa! : title;

  String localizedDescription(String locale) =>
      (locale == 'ja' && worldviewDescriptionJa != null && worldviewDescriptionJa!.isNotEmpty)
          ? worldviewDescriptionJa!
          : worldviewDescription;

  factory WorldviewModel.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'];
    final statsList = rawStats is List
        ? rawStats.map((e) => e.toString()).toList()
        : <String>[];

    final rawDescs = json['statDescriptions'] as Map<dynamic, dynamic>?;
    final statDescriptions = <String, Map<String, String>>{};
    if (rawDescs != null) {
      for (final entry in rawDescs.entries) {
        final key = entry.key.toString();
        final inner = entry.value as Map<dynamic, dynamic>?;
        if (inner != null) {
          statDescriptions[key] =
              inner.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      }
    }

    return WorldviewModel(
      worldviewKey: json['worldviewKey'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleJa: json['titleJa'] as String?,
      stats: statsList,
      statDescriptions: statDescriptions,
      commonJudgment: json['commonJudgment'] as String? ?? '',
      worldviewDescription: json['worldviewDescription'] as String? ?? '',
      worldviewDescriptionJa: json['worldviewDescriptionJa'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'worldviewKey': worldviewKey,
      'title': title,
      if (titleJa != null) 'titleJa': titleJa,
      'stats': stats,
      'statDescriptions': statDescriptions,
      'commonJudgment': commonJudgment,
      'worldviewDescription': worldviewDescription,
      if (worldviewDescriptionJa != null) 'worldviewDescriptionJa': worldviewDescriptionJa,
    };
  }

  /// Returns the description of a stat in the given locale.
  String getStatDescription(String statKey, String locale) {
    final desc = statDescriptions[statKey];
    if (desc == null) return statKey;
    return desc[locale] ?? desc['en'] ?? statKey;
  }

  /// Default worldview for fallback.
  static WorldviewModel defaultWorldview() {
    return WorldviewModel(
      worldviewKey: '1830_fantasy',
      title: '1830 Fantasy World',
      titleJa: '1830年 ファンタジーワールド',
      stats: ['strength', 'intellect', 'skill', 'magic', 'art', 'life'],
      statDescriptions: {
        'strength': {
          'en': 'Raw physical power and combat prowess',
          'ja': '生の肉体的な力と戦闘能力',
        },
        'intellect': {
          'en': 'Strategic thinking and decision-making ability',
          'ja': '戦略的思考と意思決定能力',
        },
        'skill': {
          'en': 'Combat technique and tactical precision',
          'ja': '戦闘技術と戦術的精度',
        },
        'magic': {
          'en': 'Magical power and spell capacity',
          'ja': '魔力と呪文の使用能力',
        },
        'art': {
          'en': 'Engineering, fortification, and construction skill',
          'ja': '工学・築城・建設の技術',
        },
        'life': {
          'en': 'Endurance, healing, and troop morale',
          'ja': '持久力・回復力・部隊士気',
        },
      },
      commonJudgment:
          'Battles in this world are decided by a combination of military prowess, tactical genius, and the favor of the ancient powers.',
      worldviewDescription:
          'An early 19th century world where magic and gunpowder coexist. Great empires clash over vast territories.',
      worldviewDescriptionJa:
          '魔法と火薬が共存する19世紀初頭の世界。大帝国が広大な領土をめぐって激突する。',
    );
  }
}
