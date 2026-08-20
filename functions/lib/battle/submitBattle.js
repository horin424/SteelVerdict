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
exports.submitBattle = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const config_1 = require("../utils/config");
const ai_1 = require("../utils/ai");
const prompt_1 = require("../utils/prompt");
const firestore_1 = require("../utils/firestore");
/**
 * submitBattle — the core AI battle judging function.
 *
 * Prompt construction order (spec-compliant):
 *   [System prompt]
 *   1. common_judgment          — worldview judgment rules (Remote Config)
 *   2. worldview_description    — setting/era description (Remote Config)
 *   3. mode_addons              — mode-specific instructions (Remote Config)
 *   4. commander_definition     — enemy general character (Remote Config, if applicable)
 *   [User message]
 *   5. player_stats             — race name + stat values
 *   6. player_strategy          — the player's submitted strategy text
 *
 * Flow:
 *   1. Verify auth
 *   2. Validate input + content filter
 *   3. Calculate ticket cost
 *   4. Deduct tickets (atomic transaction — prevents fraud)
 *   5. Assemble system prompt from Remote Config (parts 1-4)
 *   6. Format user message (parts 5-6)
 *   7. Call AI model
 *   8. On AI failure → REFUND tickets, throw error
 *   9. Parse outcome from response
 *   10. Return BattleResponse
 */
exports.submitBattle = (0, https_1.onCall)({ secrets: [config_1.GEMINI_API_KEY, config_1.CLAUDE_API_KEY], timeoutSeconds: 120 }, async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m;
    // 1. Auth check
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const data = request.data;
    // 2. Input validation
    if (!data.playerStrategy || data.playerStrategy.trim().length === 0) {
        throw new https_1.HttpsError("invalid-argument", "Strategy is required.");
    }
    if (!data.scenarioId || !data.gameMode) {
        throw new https_1.HttpsError("invalid-argument", "scenarioId and gameMode are required.");
    }
    // 2b. Content filter — blacklist check
    if (containsInappropriateContent(data.playerStrategy)) {
        throw new https_1.HttpsError("invalid-argument", "CONTENT_FILTER_BLOCKED");
    }
    if (data.raceName && containsInappropriateContent(data.raceName)) {
        throw new https_1.HttpsError("invalid-argument", "CONTENT_FILTER_BLOCKED");
    }
    const gameMode = data.gameMode;
    const isPractice = gameMode === "practice" || gameMode === "tabletop" || gameMode === "history_puzzle";
    const modelChoice = isPractice ? "gemini" : ((_a = data.modelChoice) !== null && _a !== void 0 ? _a : "gemini");
    // 3. Ticket cost — prefer Remote Config, fall back to hardcoded defaults
    const rcData = await (0, prompt_1.fetchRemoteConfigData)();
    const rcCosts = (_b = rcData.ticket_costs) !== null && _b !== void 0 ? _b : {};
    const cost = isPractice
        ? ((_c = rcCosts["practice"]) !== null && _c !== void 0 ? _c : config_1.TICKET_COSTS.practice)
        : modelChoice === "claude"
            ? ((_d = rcCosts["claude"]) !== null && _d !== void 0 ? _d : config_1.TICKET_COSTS.claude)
            : ((_e = rcCosts["gemini"]) !== null && _e !== void 0 ? _e : config_1.TICKET_COSTS.gemini);
    // 4. Deduct tickets (skipped for practice and dev UIDs)
    const devUids = (_f = rcData.dev_uids) !== null && _f !== void 0 ? _f : [];
    const isDevUser = devUids.includes(uid);
    if (cost > 0 && !isDevUser) {
        await (0, firestore_1.deductTickets)(uid, cost);
    }
    // 5. Assemble prompt
    const worldviewKey = (_g = data.worldviewKey) !== null && _g !== void 0 ? _g : "1830_fantasy";
    const basePrompt = await (0, prompt_1.assemblePrompt)(worldviewKey, data.scenarioId, gameMode);
    const systemPrompt = data.locale === "ja"
        ? `${basePrompt}\n\n必ず日本語で回答してください。`
        : basePrompt;
    const userMessage = (0, prompt_1.formatBattleUserMessage)(data.playerStrategy, data.raceStats, data.raceName);
    // 7. Call AI — refund tickets if the API fails
    let reportText;
    try {
        if (modelChoice === "claude") {
            const rcModels = (_h = rcData.model_config) !== null && _h !== void 0 ? _h : {};
            const claudeModel = (_j = rcModels["claude"]) !== null && _j !== void 0 ? _j : undefined;
            const maxTokens = gameMode === "epic" ? 2048 : 1024;
            reportText = await (0, ai_1.callClaude)(config_1.CLAUDE_API_KEY.value(), systemPrompt, userMessage, claudeModel, maxTokens);
        }
        else {
            const rcModels = (_k = rcData.model_config) !== null && _k !== void 0 ? _k : {};
            const modelId = isPractice
                ? ((_l = rcModels["gemini_flash_lite"]) !== null && _l !== void 0 ? _l : config_1.GEMINI_FLASH_LITE)
                : ((_m = rcModels["gemini_flash"]) !== null && _m !== void 0 ? _m : config_1.GEMINI_FLASH);
            reportText = await (0, ai_1.callGemini)(config_1.GEMINI_API_KEY.value(), systemPrompt, userMessage, modelId);
        }
    }
    catch (err) {
        console.error("AI call failed:", err);
        // Refund tickets — spec: "If the API fails → ticket must be refunded"
        if (cost > 0 && !isDevUser) {
            try {
                await (0, firestore_1.addTickets)(uid, cost);
                console.log(`Refunded ${cost} ticket(s) to ${uid} after AI failure.`);
            }
            catch (refundErr) {
                console.error("Ticket refund failed:", refundErr);
            }
        }
        throw new https_1.HttpsError("internal", "AI service error. Please try again.");
    }
    // 7. Parse outcome keyword from the AI response
    const outcome = parseOutcome(reportText);
    // 8. Short summary (first sentence or first 120 chars)
    const shortSummary = extractShortSummary(reportText, gameMode);
    // Update lastLoginAt for PvP matching priority (fire-and-forget)
    updateLastLogin(uid);
    return {
        reportText,
        outcome,
        shortSummary,
        ticketsConsumed: cost,
    };
});
// ─── Content filter ───────────────────────────────────────────────────────────
const BLACKLIST = [
    "fuck", "shit", "bitch", "nigger", "nigga", "faggot", "retard",
    "kike", "spic", "chink", "whore", "cunt", "bastard", "asshole",
    // Japanese
    "バカ", "死ね", "クソ", "うざい", "殺す", "ファック",
];
function containsInappropriateContent(text) {
    const lower = text.toLowerCase();
    return BLACKLIST.some((word) => lower.includes(word));
}
// ─── Outcome parsing ──────────────────────────────────────────────────────────
function parseOutcome(text) {
    const upper = text.toUpperCase();
    if (upper.includes("VICTORY") || upper.includes("WIN") || upper.includes("VICTORIOUS")) {
        return "win";
    }
    if (upper.includes("DEFEAT") || upper.includes("LOSS") || upper.includes("LOST") || upper.includes("ROUTED")) {
        return "loss";
    }
    return "draw";
}
function extractShortSummary(text, gameMode) {
    if (gameMode === "tabletop") {
        // For tabletop, the whole response IS the win rate (~20 chars)
        return text.trim().substring(0, 60);
    }
    // First sentence up to 120 chars
    const firstSentence = text.split(/[.!？。]/)[0].trim();
    return firstSentence.substring(0, 120);
}
async function updateLastLogin(uid) {
    try {
        await admin.firestore()
            .collection("users")
            .doc(uid)
            .update({ lastLoginAt: Date.now() });
    }
    catch (_a) {
        // Non-critical — ignore
    }
}
//# sourceMappingURL=submitBattle.js.map