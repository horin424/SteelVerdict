import 'worldview_model.dart';
import 'scenario_model.dart';

class GameConfigModel {
  final Map<String, WorldviewModel> worldviews;
  final Map<String, ScenarioModel> scenarios;
  final Map<String, String> modeAddons;
  final Map<String, int> ticketCosts;
  final Map<String, String> modelConfig;
  final List<String> devUids;
  final String? fallbackPrompt;
  final String adUnitRewarded;
  final String adUnitInterstitial;

  const GameConfigModel({
    required this.worldviews,
    required this.scenarios,
    required this.modeAddons,
    required this.ticketCosts,
    this.modelConfig = const {},
    this.devUids = const [],
    this.fallbackPrompt,
    required this.adUnitRewarded,
    required this.adUnitInterstitial,
  });

  factory GameConfigModel.fromJson(Map<String, dynamic> json) {
    // Parse worldviews
    final worldviewsRaw = json['worldviews'];
    final worldviews = <String, WorldviewModel>{};
    if (worldviewsRaw is Map) {
      for (final entry in worldviewsRaw.entries) {
        final key = entry.key.toString();
        try {
          worldviews[key] = WorldviewModel.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        } catch (e) {
          // skip malformed entries
        }
      }
    }
    // If empty, add default; otherwise supplement missing JA fields from defaults
    final defaultWorldview = WorldviewModel.defaultWorldview();
    if (worldviews.isEmpty) {
      worldviews[defaultWorldview.worldviewKey] = defaultWorldview;
    } else {
      for (final key in worldviews.keys.toList()) {
        if (key == defaultWorldview.worldviewKey) {
          final wv = worldviews[key]!;
          if (wv.titleJa == null || wv.worldviewDescriptionJa == null) {
            worldviews[key] = WorldviewModel(
              worldviewKey: wv.worldviewKey,
              title: wv.title,
              titleJa: wv.titleJa ?? defaultWorldview.titleJa,
              stats: wv.stats.isNotEmpty ? wv.stats : defaultWorldview.stats,
              statDescriptions: wv.statDescriptions.isNotEmpty
                  ? wv.statDescriptions
                  : defaultWorldview.statDescriptions,
              commonJudgment: wv.commonJudgment,
              worldviewDescription: wv.worldviewDescription,
              worldviewDescriptionJa:
                  wv.worldviewDescriptionJa ?? defaultWorldview.worldviewDescriptionJa,
            );
          }
        }
      }
    }

    // Parse scenarios
    final scenariosRaw = json['scenarios'];
    final scenarios = <String, ScenarioModel>{};
    if (scenariosRaw is Map) {
      for (final entry in scenariosRaw.entries) {
        final key = entry.key.toString();
        try {
          scenarios[key] = ScenarioModel.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        } catch (e) {
          // skip malformed entries
        }
      }
    }
    // If empty, add defaults; otherwise supplement missing JA fields from defaults
    final defaultScenarioMap = {
      for (final s in ScenarioModel.defaults()) s.scenarioId: s
    };
    if (scenarios.isEmpty) {
      for (final s in ScenarioModel.defaults()) {
        scenarios[s.scenarioId] = s;
      }
    } else {
      for (final key in scenarios.keys.toList()) {
        final s = scenarios[key]!;
        final def = defaultScenarioMap[s.scenarioId];
        if (def != null &&
            (s.titleJa == null || s.enemyNameJa == null || s.commanderDefinitionJa == null)) {
          scenarios[key] = s.copyWith(
            titleJa: s.titleJa ?? def.titleJa,
            enemyNameJa: s.enemyNameJa ?? def.enemyNameJa,
            commanderDefinitionJa: s.commanderDefinitionJa ?? def.commanderDefinitionJa,
          );
        }
      }
    }

    // Parse mode addons (support both camelCase and snake_case keys from Firestore)
    final modeAddonsRaw = json['modeAddons'] ?? json['mode_addons'];
    final modeAddons = modeAddonsRaw is Map
        ? modeAddonsRaw.map((k, v) => MapEntry(k.toString(), v.toString()))
        : <String, String>{};

    // Parse ticket costs (support both camelCase and snake_case)
    final ticketCostsRaw = json['ticketCosts'] ?? json['ticket_costs'];
    final ticketCosts = ticketCostsRaw is Map
        ? ticketCostsRaw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()))
        : {
            'normal': 1,
            'tabletop': 2,
            'epic': 3,
            'boss': 5,
            'practice': 0,
            'pvp': 1,
            'claude': 3,
          };

    // Parse model config
    final modelConfigRaw = json['modelConfig'] ?? json['model_config'];
    final modelConfig = modelConfigRaw is Map
        ? modelConfigRaw.map((k, v) => MapEntry(k.toString(), v.toString()))
        : <String, String>{};

    // Parse dev UIDs
    final devUidsRaw = json['devUids'] ?? json['dev_uids'];
    final devUids = devUidsRaw is List
        ? devUidsRaw.map((e) => e.toString()).toList()
        : <String>[];

    // Fallback prompt
    final fallbackPrompt = (json['fallbackPrompt'] ?? json['fallback_prompt']) as String?;

    return GameConfigModel(
      worldviews: worldviews,
      scenarios: scenarios,
      modeAddons: Map<String, String>.from(modeAddons),
      ticketCosts: Map<String, int>.from(ticketCosts),
      modelConfig: Map<String, String>.from(modelConfig),
      devUids: devUids,
      fallbackPrompt: fallbackPrompt,
      adUnitRewarded: json['adUnitRewarded'] as String? ??
          'ca-app-pub-3940256099942544/5224354917',
      adUnitInterstitial: json['adUnitInterstitial'] as String? ??
          'ca-app-pub-3940256099942544/1033173712',
    );
  }

  factory GameConfigModel.defaults() {
    final dw = WorldviewModel.defaultWorldview();
    final worldviews = {dw.worldviewKey: dw};
    final scenarios = <String, ScenarioModel>{};
    for (final s in ScenarioModel.defaults()) {
      scenarios[s.scenarioId] = s;
    }
    return GameConfigModel(
      worldviews: worldviews,
      scenarios: scenarios,
      modeAddons: {},
      ticketCosts: {
        'normal': 1,
        'tabletop': 2,
        'epic': 3,
        'boss': 5,
        'practice': 0,
        'pvp': 1,
        'claude': 3,
      },
      adUnitRewarded: 'ca-app-pub-3940256099942544/5224354917',
      adUnitInterstitial: 'ca-app-pub-3940256099942544/1033173712',
    );
  }
}
