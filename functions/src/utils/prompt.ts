import * as admin from "firebase-admin";

interface RemoteConfigData {
  worldviews?: Record<string, WorldviewConfig>;
  scenarios?: Record<string, ScenarioConfig>;
  mode_addons?: Record<string, string>;
  ticket_costs?: Record<string, number>;
  model_config?: Record<string, string>;
  dev_uids?: string[];
  fallback_prompt?: string;
}

interface WorldviewConfig {
  common_judgment?: string;
  worldview_description?: string;
  stats?: string[];
  stat_descriptions?: Record<string, string>;
}

interface ScenarioConfig {
  commander_definition?: string;
  enemy_name?: string;
  title?: string;
}

// Module-level cache — persists across warm Cloud Function invocations.
const RC_CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes
let _rcCache: RemoteConfigData | null = null;
let _rcCacheAt = 0;

// Assembled prompt cache keyed by "worldviewKey:scenarioId:gameMode"
const _promptCache = new Map<string, string>();
let _promptCacheAt = 0;

/**
 * Fetch game config from Firestore (system_config/game_config).
 * Results are cached in memory for 5 minutes to avoid a Firestore
 * read on every battle request.
 */
export async function fetchRemoteConfigData(): Promise<RemoteConfigData> {
  const now = Date.now();
  if (_rcCache !== null && now - _rcCacheAt < RC_CACHE_TTL_MS) {
    return _rcCache;
  }

  // Clear assembled prompt cache when config cache expires
  if (_promptCacheAt < _rcCacheAt) {
    _promptCache.clear();
  }

  try {
    const doc = await admin.firestore()
      .collection("system_config")
      .doc("game_config")
      .get();

    if (!doc.exists) {
      console.warn("system_config/game_config not found, using stale cache or empty.");
      return _rcCache ?? {};
    }

    const data = doc.data() as RemoteConfigData;

    _rcCache = {
      worldviews:     data.worldviews ?? {},
      scenarios:      data.scenarios ?? {},
      mode_addons:    data.mode_addons ?? {},
      ticket_costs:   data.ticket_costs ?? {},
      model_config:   data.model_config ?? {},
      dev_uids:       data.dev_uids ?? [],
      fallback_prompt: data.fallback_prompt,
    };
    _rcCacheAt = now;
    return _rcCache;
  } catch (err) {
    console.error("fetchRemoteConfigData error:", err);
    // Return stale cache if available, otherwise empty
    return _rcCache ?? {};
  }
}

export interface PromptParts {
  systemPrompt: string;
  worldviewKey: string;
  scenarioId: string;
}

/**
 * Assemble the system prompt (parts 1-4) in spec order:
 *   1. common_judgment
 *   2. worldview_description
 *   3. mode_addons[gameMode]
 *   4. commander_definition  (only if scenario has one)
 *
 * Parts 5 (player_stats) and 6 (player_strategy) are appended as
 * the user message via formatBattleUserMessage(), maintaining the
 * correct full order while allowing parts 1-4 to be cached server-side.
 */
export async function assemblePrompt(
  worldviewKey: string,
  scenarioId: string,
  gameMode: string,
): Promise<string> {
  const cacheKey = `${worldviewKey}:${scenarioId}:${gameMode}`;
  if (_promptCache.has(cacheKey)) {
    return _promptCache.get(cacheKey)!;
  }

  const data = await fetchRemoteConfigData();

  const worldview = data.worldviews?.[worldviewKey] ?? {} as any;
  const scenario = data.scenarios?.[scenarioId] ?? {} as any;
  const modeAddons = data.mode_addons ?? {};

  const parts: string[] = [];

  // Support both snake_case (legacy) and camelCase (admin panel) keys
  const judgment = worldview.common_judgment ?? worldview.commonJudgment;
  if (judgment) {
    parts.push(judgment);
  }
  const wvDesc = worldview.worldview_description ?? worldview.worldviewDescription;
  if (wvDesc) {
    parts.push(wvDesc);
  }
  if (modeAddons[gameMode]) {
    parts.push(modeAddons[gameMode]);
  }
  const cmdDef = scenario.commander_definition ?? scenario.commanderDefinition;
  if (cmdDef) {
    parts.push(cmdDef);
  }

  // Fallback: use RC fallback_prompt, or hardcoded minimal prompt
  if (parts.length === 0) {
    parts.push(data.fallback_prompt ?? getFallbackPrompt(gameMode));
  }

  const prompt = parts.join("\n\n");
  _promptCache.set(cacheKey, prompt);
  _promptCacheAt = Date.now();
  return prompt;
}

/**
 * Fallback system prompt used during development before
 * Firestore config is populated.
 */
function getFallbackPrompt(gameMode: string): string {
  const base = `You are a strict military battle judge in a fantasy world set around 1830.
The player will describe their battle strategy and provide their race's stats.
Evaluate the strategy objectively based on the stats provided.
Stats: Wisdom, Technology, Magic, Art (engineering/fortification), Life, Strength.
DO NOT play rock-paper-scissors after the fact — react dynamically to the player's actual strategy.
Always end your response with a clear outcome: VICTORY, DEFEAT, or STALEMATE.`;

  const modeInstructions: Record<string, string> = {
    practice: "Output a battle report of 50 characters or less in the player's implied language.",
    tabletop: "Simulate this battle 10 times. Output only the estimated win rate as a percentage in 20 characters or less, e.g. 'Win rate: 70%'",
    normal: "Write a detailed battle report of 1000 characters or more.",
    epic: "Write a rich, epic battle narrative of 1500 characters or more with vivid descriptions.",
    boss: "Write a detailed battle report of 1000 characters or more. The player faces a powerful boss-tier enemy.",
    history_puzzle: "This is a historical puzzle battle using fixed historical forces. Evaluate the player's strategy strictly and objectively. There is no clear stage — focus on how well the strategy performs. Write a detailed battle report of 500 characters or more.",
    pvp: "You are judging a PvP battle. Both strategies are provided. Judge fairly based on stats and strategy quality. Write a short battle report of 40 characters, then state the winner.",
  };

  const modeInstruction = modeInstructions[gameMode] ?? modeInstructions["normal"];
  return `${base}\n\n${modeInstruction}`;
}

/**
 * Format the user message containing stats + strategy.
 */
export function formatBattleUserMessage(
  playerStrategy: string,
  raceStats: Record<string, number>,
  raceName?: string,
): string {
  const statsText = Object.entries(raceStats)
    .map(([k, v]) => `${k}: ${v}`)
    .join(", ");

  const nameText = raceName ? `Race: ${raceName}\n` : "";
  return `${nameText}Stats: ${statsText}\n\nStrategy: ${playerStrategy}`;
}

/**
 * Format user message for PvP with both sides.
 */
export function formatPvpUserMessage(
  playerAStrategy: string,
  playerAStats: Record<string, number>,
  playerARaceName: string,
  playerBStrategy: string,
  playerBStats: Record<string, number>,
  playerBRaceName: string,
): string {
  const statsA = Object.entries(playerAStats).map(([k, v]) => `${k}: ${v}`).join(", ");
  const statsB = Object.entries(playerBStats).map(([k, v]) => `${k}: ${v}`).join(", ");

  return `
=== PLAYER A ===
Race: ${playerARaceName}
Stats: ${statsA}
Strategy: ${playerAStrategy}

=== PLAYER B ===
Race: ${playerBRaceName}
Stats: ${statsB}
Strategy: ${playerBStrategy}

Judge this battle. State the winner (Player A or Player B or Draw) and write a short battle report of 40 characters or less.
Format your response as:
WINNER: [Player A / Player B / Draw]
REPORT: [40 char report]
`.trim();
}
