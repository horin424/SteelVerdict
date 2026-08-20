"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.fetchRemoteConfigData = fetchRemoteConfigData;
exports.assemblePrompt = assemblePrompt;
exports.formatBattleUserMessage = formatBattleUserMessage;
exports.formatPvpUserMessage = formatPvpUserMessage;
const admin = __importStar(require("firebase-admin"));
// Module-level cache — persists across warm Cloud Function invocations.
const RC_CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes
let _rcCache = null;
let _rcCacheAt = 0;
// Assembled prompt cache keyed by "worldviewKey:scenarioId:gameMode"
const _promptCache = new Map();
/**
 * Fetch Remote Config template from Firebase Admin SDK.
 * Results are cached in memory for 5 minutes to avoid an Admin SDK
 * network call on every battle request.
 */
async function fetchRemoteConfigData() {
    var _a, _b, _c, _d, _e, _f, _g;
    const now = Date.now();
    if (_rcCache !== null && now - _rcCacheAt < RC_CACHE_TTL_MS) {
        return _rcCache;
    }
    try {
        const rc = admin.remoteConfig();
        const template = await rc.getTemplate();
        const params = template.parameters;
        const parse = (key) => {
            const param = params[key];
            if (!(param === null || param === void 0 ? void 0 : param.defaultValue) || !("value" in param.defaultValue))
                return {};
            try {
                return JSON.parse(param.defaultValue.value);
            }
            catch (_a) {
                return {};
            }
        };
        const parseString = (key) => {
            const param = params[key];
            if (!(param === null || param === void 0 ? void 0 : param.defaultValue) || !("value" in param.defaultValue))
                return undefined;
            return param.defaultValue.value;
        };
        // New grouped keys (game_prompts, game_scenarios, system_config)
        // with fallback to legacy flat keys for backward compatibility.
        const gamePrompts = parse("game_prompts");
        const gameScenarios = parse("game_scenarios");
        const systemConfig = parse("system_config");
        _rcCache = {
            worldviews: (_a = gamePrompts.worldviews) !== null && _a !== void 0 ? _a : parse("worldviews"),
            scenarios: (_b = gameScenarios.scenarios) !== null && _b !== void 0 ? _b : parse("scenarios"),
            mode_addons: (_c = gamePrompts.mode_addons) !== null && _c !== void 0 ? _c : parse("mode_addons"),
            ticket_costs: (_d = systemConfig.ticket_costs) !== null && _d !== void 0 ? _d : parse("ticket_costs"),
            model_config: (_e = systemConfig.model_config) !== null && _e !== void 0 ? _e : parse("model_config"),
            dev_uids: (_f = systemConfig.dev_uids) !== null && _f !== void 0 ? _f : [],
            fallback_prompt: (_g = gamePrompts.fallback_prompt) !== null && _g !== void 0 ? _g : parseString("fallback_prompt"),
        };
        _rcCacheAt = now;
        return _rcCache;
    }
    catch (err) {
        console.error("fetchRemoteConfigData error:", err);
        // Return stale cache if available, otherwise empty
        return _rcCache !== null && _rcCache !== void 0 ? _rcCache : {};
    }
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
async function assemblePrompt(worldviewKey, scenarioId, gameMode) {
    var _a, _b, _c, _d, _e, _f;
    const cacheKey = `${worldviewKey}:${scenarioId}:${gameMode}`;
    if (_promptCache.has(cacheKey)) {
        return _promptCache.get(cacheKey);
    }
    const data = await fetchRemoteConfigData();
    const worldview = (_b = (_a = data.worldviews) === null || _a === void 0 ? void 0 : _a[worldviewKey]) !== null && _b !== void 0 ? _b : {};
    const scenario = (_d = (_c = data.scenarios) === null || _c === void 0 ? void 0 : _c[scenarioId]) !== null && _d !== void 0 ? _d : {};
    const modeAddons = (_e = data.mode_addons) !== null && _e !== void 0 ? _e : {};
    const parts = [];
    if (worldview.common_judgment) {
        parts.push(worldview.common_judgment);
    }
    if (worldview.worldview_description) {
        parts.push(worldview.worldview_description);
    }
    if (modeAddons[gameMode]) {
        parts.push(modeAddons[gameMode]);
    }
    if (scenario.commander_definition) {
        parts.push(scenario.commander_definition);
    }
    // Fallback: use RC fallback_prompt, or hardcoded minimal prompt
    if (parts.length === 0) {
        parts.push((_f = data.fallback_prompt) !== null && _f !== void 0 ? _f : getFallbackPrompt(gameMode));
    }
    const prompt = parts.join("\n\n");
    _promptCache.set(cacheKey, prompt);
    return prompt;
}
/**
 * Fallback system prompt used during development before
 * Remote Config is populated.
 */
function getFallbackPrompt(gameMode) {
    var _a;
    const base = `You are a strict military battle judge in a fantasy world set around 1830.
The player will describe their battle strategy and provide their race's stats.
Evaluate the strategy objectively based on the stats provided.
Stats: Wisdom, Technology, Magic, Art (engineering/fortification), Life, Strength.
DO NOT play rock-paper-scissors after the fact — react dynamically to the player's actual strategy.
Always end your response with a clear outcome: VICTORY, DEFEAT, or STALEMATE.`;
    const modeInstructions = {
        practice: "Output a battle report of 50 characters or less in the player's implied language.",
        tabletop: "Simulate this battle 10 times. Output only the estimated win rate as a percentage in 20 characters or less, e.g. 'Win rate: 70%'",
        normal: "Write a detailed battle report of 1000 characters or more.",
        epic: "Write a rich, epic battle narrative of 1500 characters or more with vivid descriptions.",
        boss: "Write a detailed battle report of 1000 characters or more. The player faces a powerful boss-tier enemy.",
        history_puzzle: "This is a historical puzzle battle using fixed historical forces. Evaluate the player's strategy strictly and objectively. There is no clear stage — focus on how well the strategy performs. Write a detailed battle report of 500 characters or more.",
        pvp: "You are judging a PvP battle. Both strategies are provided. Judge fairly based on stats and strategy quality. Write a short battle report of 40 characters, then state the winner.",
    };
    const modeInstruction = (_a = modeInstructions[gameMode]) !== null && _a !== void 0 ? _a : modeInstructions["normal"];
    return `${base}\n\n${modeInstruction}`;
}
/**
 * Format the user message containing stats + strategy.
 */
function formatBattleUserMessage(playerStrategy, raceStats, raceName) {
    const statsText = Object.entries(raceStats)
        .map(([k, v]) => `${k}: ${v}`)
        .join(", ");
    const nameText = raceName ? `Race: ${raceName}\n` : "";
    return `${nameText}Stats: ${statsText}\n\nStrategy: ${playerStrategy}`;
}
/**
 * Format user message for PvP with both sides.
 */
function formatPvpUserMessage(playerAStrategy, playerAStats, playerARaceName, playerBStrategy, playerBStats, playerBRaceName) {
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
//# sourceMappingURL=prompt.js.map