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
 * Fetch game config from Firestore (system_config/game_config).
 * Results are cached in memory for 5 minutes to avoid a Firestore
 * read on every battle request.
 */
async function fetchRemoteConfigData() {
    var _a, _b, _c, _d, _e, _f;
    const now = Date.now();
    if (_rcCache !== null && now - _rcCacheAt < RC_CACHE_TTL_MS) {
        return _rcCache;
    }
    // Past the TTL and about to refetch, so the assembled prompts built from the
    // old config are stale too.
    //
    // This used to read `if (_promptCacheAt < _rcCacheAt)`, which could never be
    // true: _promptCacheAt was stamped by assemblePrompt *after* _rcCacheAt was
    // stamped here, so it was always the larger of the two. The prompt cache was
    // therefore never cleared for the life of a warm instance, and an edit made in
    // the admin panel could keep serving the old prompt until the instance
    // recycled — which defeats the whole point of editing prompts without a
    // release.
    _promptCache.clear();
    try {
        const doc = await admin.firestore()
            .collection("system_config")
            .doc("game_config")
            .get();
        if (!doc.exists) {
            console.warn("system_config/game_config not found, using stale cache or empty.");
            return _rcCache !== null && _rcCache !== void 0 ? _rcCache : {};
        }
        const data = doc.data();
        _rcCache = {
            worldviews: (_a = data.worldviews) !== null && _a !== void 0 ? _a : {},
            scenarios: (_b = data.scenarios) !== null && _b !== void 0 ? _b : {},
            mode_addons: (_c = data.mode_addons) !== null && _c !== void 0 ? _c : {},
            ticket_costs: (_d = data.ticket_costs) !== null && _d !== void 0 ? _d : {},
            model_config: (_e = data.model_config) !== null && _e !== void 0 ? _e : {},
            dev_uids: (_f = data.dev_uids) !== null && _f !== void 0 ? _f : [],
            fallback_prompt: data.fallback_prompt,
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
    var _a, _b, _c, _d, _e, _f, _g, _h, _j;
    const cacheKey = `${worldviewKey}:${scenarioId}:${gameMode}`;
    if (_promptCache.has(cacheKey)) {
        return _promptCache.get(cacheKey);
    }
    const data = await fetchRemoteConfigData();
    const worldview = (_b = (_a = data.worldviews) === null || _a === void 0 ? void 0 : _a[worldviewKey]) !== null && _b !== void 0 ? _b : {};
    const scenario = (_d = (_c = data.scenarios) === null || _c === void 0 ? void 0 : _c[scenarioId]) !== null && _d !== void 0 ? _d : {};
    const modeAddons = (_e = data.mode_addons) !== null && _e !== void 0 ? _e : {};
    const parts = [];
    // Support both snake_case (legacy) and camelCase (admin panel) keys
    const judgment = (_f = worldview.common_judgment) !== null && _f !== void 0 ? _f : worldview.commonJudgment;
    if (judgment) {
        parts.push(judgment);
    }
    const wvDesc = (_g = worldview.worldview_description) !== null && _g !== void 0 ? _g : worldview.worldviewDescription;
    if (wvDesc) {
        parts.push(wvDesc);
    }
    if (modeAddons[gameMode]) {
        parts.push(modeAddons[gameMode]);
    }
    const cmdDef = (_h = scenario.commander_definition) !== null && _h !== void 0 ? _h : scenario.commanderDefinition;
    if (cmdDef) {
        parts.push(cmdDef);
    }
    // Fallback: use RC fallback_prompt, or hardcoded minimal prompt
    if (parts.length === 0) {
        parts.push((_j = data.fallback_prompt) !== null && _j !== void 0 ? _j : getFallbackPrompt(gameMode));
    }
    const prompt = parts.join("\n\n");
    _promptCache.set(cacheKey, prompt);
    return prompt;
}
/**
 * Fallback system prompt used during development before
 * Firestore config is populated.
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