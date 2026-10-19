// Reads system_config/game_config the way the app does.
//
// Ported from lib/models/game_config_model.dart, worldview_model.dart and
// scenario_model.dart. The editors fill their forms from this parsed view and
// save from it, exactly as the in-app panel does, so the two have to agree on
// every fallback: which of camelCase and snake_case wins, what a missing field
// becomes, and which repairs apply (empty stats, missing Japanese). Change one
// and the other together.

export const DEFAULT_WORLDVIEW_KEY = "1830_fantasy";

// The app's built-in stat set (WorldviewModel.defaultWorldview). Legacy: every
// world in the live config uses wisdom/technology/artistry instead.
export const LEGACY_STAT_KEYS = ["strength", "intellect", "skill", "magic", "art", "life"];

export const BUILTIN_DEFAULT_WORLDVIEW = Object.freeze({
  worldviewKey: "1830_fantasy",
  title: "1830 Fantasy World",
  titleJa: "1830年 ファンタジーワールド",
  stats: LEGACY_STAT_KEYS,
  statDescriptions: {
    strength: { en: "Raw physical power and combat prowess", ja: "生の肉体的な力と戦闘能力" },
    intellect: { en: "Strategic thinking and decision-making ability", ja: "戦略的思考と意思決定能力" },
    skill: { en: "Combat technique and tactical precision", ja: "戦闘技術と戦術的精度" },
    magic: { en: "Magical power and spell capacity", ja: "魔力と呪文の使用能力" },
    art: { en: "Engineering, fortification, and construction skill", ja: "工学・築城・建設の技術" },
    life: { en: "Endurance, healing, and troop morale", ja: "持久力・回復力・部隊士気" },
  },
  commonJudgment:
    "Battles in this world are decided by a combination of military prowess, tactical genius, and the favor of the ancient powers.",
  worldviewDescription:
    "An early 19th century world where magic and gunpowder coexist. Great empires clash over vast territories.",
  worldviewDescriptionJa: "魔法と火薬が共存する19世紀初頭の世界。大帝国が広大な領土をめぐって激突する。",
  resultType: "battle",
});

// ScenarioModel.defaults(). Only used when the config holds no scenarios, and
// to fill missing Japanese on these three ids.
const DEFAULT_SCENARIOS = [
  {
    scenarioId: "scenario_001",
    worldviewKey: "1830_fantasy",
    title: "The Border Skirmish",
    titleJa: "国境の小競り合い",
    difficulty: 1,
    enemyName: "Bandit Horde",
    enemyNameJa: "盗賊の大群",
    enemyStats: { attack: 3, defense: 2, speed: 4, morale: 2, magic: 0, leadership: 2 },
    commanderDefinition: "A disorganized bandit force threatening the western border.",
    commanderDefinitionJa: "西の国境を脅かす統率のとれていない盗賊集団。",
    isUnlocked: true,
    isFree: true,
    battleType: "standard",
  },
  {
    scenarioId: "scenario_002",
    worldviewKey: "1830_fantasy",
    title: "Siege of Iron Keep",
    titleJa: "鉄の砦の包囲戦",
    difficulty: 3,
    enemyName: "Imperial Garrison",
    enemyNameJa: "帝国の守備隊",
    enemyStats: { attack: 5, defense: 8, speed: 2, morale: 6, magic: 1, leadership: 5 },
    commanderDefinition: "A fortified imperial stronghold with seasoned defenders.",
    commanderDefinitionJa: "歴戦の守備兵を擁する帝国の要塞。",
    isUnlocked: false,
    isFree: false,
    battleType: "standard",
  },
  {
    scenarioId: "scenario_003",
    worldviewKey: "1830_fantasy",
    title: "Dragon Valley Assault",
    titleJa: "ドラゴン谷の強襲",
    difficulty: 5,
    enemyName: "Dragon Cult Army",
    enemyNameJa: "ドラゴン教団軍",
    enemyStats: { attack: 9, defense: 6, speed: 5, morale: 8, magic: 10, leadership: 7 },
    commanderDefinition: "A fanatical army empowered by dragon magic.",
    commanderDefinitionJa: "ドラゴンの魔力で強化された狂信的な軍隊。",
    isUnlocked: false,
    isFree: false,
    battleType: "standard",
  },
];

export const DEFAULT_TICKET_COSTS = Object.freeze({
  normal: 1,
  tabletop: 2,
  epic: 3,
  boss: 5,
  practice: 0,
  pvp: 1,
  claude: 3,
});

const TEST_AD_REWARDED = "ca-app-pub-3940256099942544/5224354917";
const TEST_AD_INTERSTITIAL = "ca-app-pub-3940256099942544/1033173712";

// ── Dart-compatible casts ────────────────────────────────────────────────────
// `x as String?` throws on a value of the wrong type, and the app's parser
// catches that per entry and skips the entry. These throw the same way so the
// same entries get skipped here.

const isMap = (v) => v !== null && typeof v === "object" && !Array.isArray(v);

function optStr(v) {
  if (v === undefined || v === null) return null;
  if (typeof v !== "string") throw new TypeError("expected a string");
  return v;
}

function castStr(v) {
  if (typeof v !== "string") throw new TypeError("expected a string");
  return v;
}

function optBool(v) {
  if (v === undefined || v === null) return null;
  if (typeof v !== "boolean") throw new TypeError("expected a boolean");
  return v;
}

function toInt(v) {
  if (typeof v !== "number") throw new TypeError("expected a number");
  return Math.trunc(v);
}

// Dart's toString() on a decoded Firestore value.
const dartToString = (v) => (v === null || v === undefined ? "null" : String(v));

// ── Worldviews ───────────────────────────────────────────────────────────────

function parseWorldview(json, keyFallback) {
  const stats = Array.isArray(json.stats) ? json.stats.map(dartToString) : [];

  // camelCase from the admin panel, snake_case from manual edits / seed data.
  const rawDescs = json.statDescriptions ?? json.stat_descriptions;
  const statDescriptions = {};
  if (isMap(rawDescs)) {
    for (const [key, value] of Object.entries(rawDescs)) {
      if (isMap(value)) {
        statDescriptions[key] = Object.fromEntries(
          Object.entries(value).map(([k, v]) => [k, dartToString(v)]),
        );
      } else if (value !== null && value !== undefined) {
        const text = dartToString(value);
        statDescriptions[key] = { en: text, ja: text };
      }
    }
  }

  const keyFromJson = optStr(json.worldviewKey);
  const rawResultType = optStr(json.resultType ?? json.result_type);

  return {
    worldviewKey: keyFromJson ? keyFromJson : keyFallback ?? "",
    title: optStr(json.title) ?? "",
    titleJa: optStr(json.titleJa) ?? optStr(json.title_ja),
    stats,
    statDescriptions,
    commonJudgment: castStr(json.commonJudgment ?? json.common_judgment ?? ""),
    worldviewDescription: castStr(json.worldviewDescription ?? json.worldview_description ?? ""),
    worldviewDescriptionJa: optStr(json.worldviewDescriptionJa) ?? optStr(json.worldview_description_ja),
    resultType: rawResultType ? rawResultType : "battle",
  };
}

// ── Scenarios ────────────────────────────────────────────────────────────────

function difficultyFromLabel(raw) {
  switch (raw.toLowerCase()) {
    case "easy":
      return 1;
    case "normal":
    case "medium":
      return 2;
    case "hard":
      return 3;
    case "very hard":
    case "extreme":
      return 5;
    default:
      return /^[+-]?\d+$/.test(raw) ? parseInt(raw, 10) : 1;
  }
}

function parseBattleType(raw) {
  return raw === "boss" || raw === "history" ? raw : "standard";
}

function parseScenario(json, idFallback) {
  const sid = optStr(json.scenarioId);
  const worldviewKey = optStr(json.worldviewKey) ?? optStr(json.worldview) ?? "";
  const rawEnemyStats = json.enemyStats ?? json.enemy_stats;
  const enemyStats = isMap(rawEnemyStats)
    ? Object.fromEntries(Object.entries(rawEnemyStats).map(([k, v]) => [k, toInt(v)]))
    : {};

  const d = json.difficulty;
  const difficulty =
    typeof d === "number" ? Math.trunc(d) : typeof d === "string" ? difficultyFromLabel(d) : 1;

  return {
    scenarioId: sid ? sid : idFallback ?? "",
    worldviewKey: worldviewKey ? worldviewKey : DEFAULT_WORLDVIEW_KEY,
    title: optStr(json.title) ?? "Unknown Scenario",
    titleJa: optStr(json.titleJa) ?? optStr(json.title_ja),
    difficulty,
    enemyName: castStr(json.enemyName ?? json.enemy_name ?? "Unknown Enemy"),
    enemyNameJa: optStr(json.enemyNameJa) ?? optStr(json.enemy_name_ja),
    enemyStats,
    commanderDefinition: castStr(json.commanderDefinition ?? json.commander_definition ?? ""),
    commanderDefinitionJa: optStr(json.commanderDefinitionJa) ?? optStr(json.commander_definition_ja),
    isUnlocked: optBool(json.isUnlocked) ?? optBool(json.is_unlocked) ?? false,
    isFree: optBool(json.isFree) ?? optBool(json.is_free) ?? false,
    battleType: parseBattleType(optStr(json.battleType ?? json.battle_type)),
  };
}

const clone = (v) => JSON.parse(JSON.stringify(v));

// ── The whole document ───────────────────────────────────────────────────────

/// Parses the game_config document the way GameConfigModel.fromJson does.
///
/// One deliberate difference: where the app gives up, this reports instead.
/// A single non-numeric ticket cost makes the app's parser throw and the whole
/// game fall back to its one-world defaults. Here the bad value is kept and
/// listed in `problems`, so the costs editor can show it and have it fixed.
export function parseConfig(data) {
  const problems = [];

  // Worldviews
  const worldviews = {};
  if (isMap(data.worldviews)) {
    for (const [key, value] of Object.entries(data.worldviews)) {
      try {
        if (!isMap(value)) throw new TypeError("not a map");
        worldviews[key] = parseWorldview(value, key);
      } catch (_) {
        problems.push({ kind: "worldview", key });
      }
    }
  }
  const def = BUILTIN_DEFAULT_WORLDVIEW;
  if (Object.keys(worldviews).length === 0) {
    worldviews[def.worldviewKey] = clone(def);
  } else {
    // Prefer the live default world's stats over the built-in legacy set.
    const liveDefault = worldviews[def.worldviewKey];
    const fallbackStats = liveDefault && liveDefault.stats.length ? liveDefault.stats : def.stats;
    const fallbackDescs =
      liveDefault && Object.keys(liveDefault.statDescriptions).length
        ? liveDefault.statDescriptions
        : def.statDescriptions;
    for (const key of Object.keys(worldviews)) {
      const wv = worldviews[key];
      const needsStats = wv.stats.length === 0;
      const needsJa =
        key === def.worldviewKey && (wv.titleJa == null || wv.worldviewDescriptionJa == null);
      if (!needsStats && !needsJa) continue;
      worldviews[key] = {
        ...wv,
        titleJa: needsJa ? wv.titleJa ?? def.titleJa : wv.titleJa,
        stats: needsStats ? fallbackStats : wv.stats,
        statDescriptions: Object.keys(wv.statDescriptions).length ? wv.statDescriptions : fallbackDescs,
        worldviewDescriptionJa: needsJa
          ? wv.worldviewDescriptionJa ?? def.worldviewDescriptionJa
          : wv.worldviewDescriptionJa,
      };
    }
  }

  // Scenarios
  const scenarios = {};
  if (isMap(data.scenarios)) {
    for (const [key, value] of Object.entries(data.scenarios)) {
      try {
        if (!isMap(value)) throw new TypeError("not a map");
        scenarios[key] = parseScenario(value, key);
      } catch (_) {
        problems.push({ kind: "scenario", key });
      }
    }
  }
  const defaultScenarios = Object.fromEntries(DEFAULT_SCENARIOS.map((s) => [s.scenarioId, s]));
  if (Object.keys(scenarios).length === 0) {
    for (const s of DEFAULT_SCENARIOS) scenarios[s.scenarioId] = clone(s);
  } else {
    for (const key of Object.keys(scenarios)) {
      const s = scenarios[key];
      const d = defaultScenarios[s.scenarioId];
      if (d && (s.titleJa == null || s.enemyNameJa == null || s.commanderDefinitionJa == null)) {
        scenarios[key] = {
          ...s,
          titleJa: s.titleJa ?? d.titleJa,
          enemyNameJa: s.enemyNameJa ?? d.enemyNameJa,
          commanderDefinitionJa: s.commanderDefinitionJa ?? d.commanderDefinitionJa,
        };
      }
    }
  }

  // Mode instructions, costs, models: camelCase first, as the app reads them.
  const addonsRaw = data.modeAddons ?? data.mode_addons;
  const modeAddons = isMap(addonsRaw)
    ? Object.fromEntries(Object.entries(addonsRaw).map(([k, v]) => [k, dartToString(v)]))
    : {};

  const costsRaw = data.ticketCosts ?? data.ticket_costs;
  const ticketCosts = {};
  const invalidTicketCosts = {};
  if (isMap(costsRaw)) {
    for (const [k, v] of Object.entries(costsRaw)) {
      if (typeof v === "number") ticketCosts[k] = Math.trunc(v);
      else {
        invalidTicketCosts[k] = v;
        problems.push({ kind: "ticketCost", key: k });
      }
    }
  } else {
    Object.assign(ticketCosts, DEFAULT_TICKET_COSTS);
  }

  const modelsRaw = data.modelConfig ?? data.model_config;
  const modelConfig = isMap(modelsRaw)
    ? Object.fromEntries(Object.entries(modelsRaw).map(([k, v]) => [k, dartToString(v)]))
    : {};

  const uidsRaw = data.devUids ?? data.dev_uids;
  const devUids = Array.isArray(uidsRaw) ? uidsRaw.map(dartToString) : [];

  let fallbackPrompt = null;
  try {
    fallbackPrompt = optStr(data.fallbackPrompt ?? data.fallback_prompt);
  } catch (_) {
    problems.push({ kind: "fallbackPrompt" });
  }

  let adUnitRewarded = TEST_AD_REWARDED;
  let adUnitInterstitial = TEST_AD_INTERSTITIAL;
  try {
    adUnitRewarded = optStr(data.adUnitRewarded) ?? TEST_AD_REWARDED;
    adUnitInterstitial = optStr(data.adUnitInterstitial) ?? TEST_AD_INTERSTITIAL;
  } catch (_) {
    problems.push({ kind: "adUnit" });
  }

  return {
    worldviews,
    scenarios,
    modeAddons,
    ticketCosts,
    invalidTicketCosts,
    modelConfig,
    devUids,
    fallbackPrompt,
    adUnitRewarded,
    adUnitInterstitial,
    problems,
  };
}

// ── Display helpers (WorldviewModel / ScenarioModel / mode_names / stat_names) ─

export function localizedTitle(item, lang) {
  return lang === "ja" && item.titleJa ? item.titleJa : item.title;
}

/// lib/core/utils/stat_names.dart prettifyStatKey: `climb_rate` and
/// `climbRate` both become `Climb Rate`.
export function prettifyStatKey(key) {
  if (!key) return key;
  return key
    .replace(/[_\-]+/g, " ")
    .replace(/(?<=[a-z0-9])(?=[A-Z])/g, " ")
    .trim()
    .split(/\s+/)
    .map((w) => (w ? w[0].toUpperCase() + w.slice(1) : w))
    .join(" ");
}

const MODE_STRING = {
  practice: "gameModePractice",
  normal: "gameModeNormal",
  tabletop: "gameModeTabletop",
  epic: "gameModeEpic",
  boss: "gameModeBoss",
  history_puzzle: "gameModeHistoryPuzzle",
  war_history: "warHistoryTitle",
  pvp: "modePvp",
  pvp_detail: "modePvpDetail",
  normal_claude: "modeNormalClaude",
  normal_gemini: "modeNormalGemini",
};

/// lib/core/utils/mode_names.dart localizedModeName.
export function modeName(key, t) {
  return MODE_STRING[key] ? t(MODE_STRING[key]) : prettifyStatKey(key);
}

const STAT_STRING = {
  strength: "statStrength",
  intellect: "statIntellect",
  skill: "statSkill",
  magic: "statMagic",
  art: "statArt",
  life: "statLife",
  wisdom: "statWisdom",
  technology: "statTechnology",
  artistry: "statArtistry",
  durability: "statDurability",
  maneuverability: "statManeuverability",
  max_speed: "statMaxSpeed",
  maxSpeed: "statMaxSpeed",
  firepower: "statFirepower",
  max_altitude: "statMaxAltitude",
  maxAltitude: "statMaxAltitude",
  acceleration: "statAcceleration",
  luck: "statLuck",
  attack: "statAttack",
  defense: "statDefense",
  speed: "statSpeed",
  morale: "statMorale",
  leadership: "statLeadership",
};

/// lib/core/utils/stat_names.dart localizedStatName.
export function statName(key, t) {
  return STAT_STRING[key] ? t(STAT_STRING[key]) : prettifyStatKey(key);
}

/// Text as the editors compare it: browsers turn CRLF into LF inside a text box,
/// and the live prompts were stored with CRLF. Comparing raw strings would make
/// every untouched prompt look edited.
export const normalizeText = (s) => (s ?? "").replace(/\r\n?/g, "\n");
