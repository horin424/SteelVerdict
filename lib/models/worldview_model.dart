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
  /// "battle" (default) or "survival" (e.g. Last Breath — days survived).
  final String resultType;

  const WorldviewModel({
    required this.worldviewKey,
    required this.title,
    this.titleJa,
    required this.stats,
    required this.statDescriptions,
    required this.commonJudgment,
    required this.worldviewDescription,
    this.worldviewDescriptionJa,
    this.resultType = 'battle',
  });

  bool get isSurvivalMode => resultType == 'survival';

  String localizedTitle(String locale) =>
      (locale == 'ja' && titleJa != null && titleJa!.isNotEmpty) ? titleJa! : title;

  String localizedDescription(String locale) =>
      (locale == 'ja' && worldviewDescriptionJa != null && worldviewDescriptionJa!.isNotEmpty)
          ? worldviewDescriptionJa!
          : worldviewDescription;

  factory WorldviewModel.fromJson(Map<String, dynamic> json, {String? keyFallback}) {
    final rawStats = json['stats'];
    final statsList = rawStats is List
        ? rawStats.map((e) => e.toString()).toList()
        : <String>[];

    // Support camelCase (admin panel) and snake_case (manual Firebase / seed).
    final rawDescs = json['statDescriptions'] ?? json['stat_descriptions'];
    final statDescriptions = <String, Map<String, String>>{};
    if (rawDescs is Map) {
      for (final entry in rawDescs.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          statDescriptions[key] =
              value.map((k, v) => MapEntry(k.toString(), v.toString()));
        } else if (value != null) {
          // Spec sample uses plain strings: { "芸術": "工兵・築城…" }
          final text = value.toString();
          statDescriptions[key] = {'en': text, 'ja': text};
        }
      }
    }

    final keyFromJson = json['worldviewKey'] as String?;
    final worldviewKey = (keyFromJson != null && keyFromJson.isNotEmpty)
        ? keyFromJson
        : (keyFallback ?? '');

    final rawResultType =
        (json['resultType'] ?? json['result_type']) as String?;
    final resultType =
        (rawResultType != null && rawResultType.isNotEmpty) ? rawResultType : 'battle';

    return WorldviewModel(
      worldviewKey: worldviewKey,
      title: json['title'] as String? ?? '',
      titleJa: json['titleJa'] as String? ?? json['title_ja'] as String?,
      stats: statsList,
      statDescriptions: statDescriptions,
      commonJudgment: (json['commonJudgment'] ?? json['common_judgment'] ?? '')
          as String,
      worldviewDescription:
          (json['worldviewDescription'] ?? json['worldview_description'] ?? '')
              as String,
      worldviewDescriptionJa: json['worldviewDescriptionJa'] as String? ??
          json['worldview_description_ja'] as String?,
      resultType: resultType,
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
      if (worldviewDescriptionJa != null)
        'worldviewDescriptionJa': worldviewDescriptionJa,
      'resultType': resultType,
    };
  }

  /// Returns the description of a stat in the given locale.
  String getStatDescription(String statKey, String locale) {
    final desc = statDescriptions[statKey];
    if (desc == null) return statKey;
    return desc[locale] ?? desc['en'] ?? desc['ja'] ?? statKey;
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
      resultType: 'battle',
    );
  }
}
