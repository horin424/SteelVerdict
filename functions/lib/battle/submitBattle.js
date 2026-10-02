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
const outcome_1 = require("../utils/outcome");
function maxTokensForMode(gameMode) {
    switch (gameMode) {
        case "practice":
            return 1024;
        case "tabletop":
            return 1024;
        case "pvp":
            return 1024;
        case "epic":
            return 16384;
        case "normal":
        case "boss":
        case "history_puzzle":
        default:
            return 8192;
    }
}
/**
 * submitBattle — the core AI battle judging function.
 *
 * Prompt construction order (spec-compliant):
 *   [System prompt]
 *   1. common_judgment
 *   2. worldview_description
 *   3. mode_addons
 *   4. commander_definition
 *   + output contract (anti-leak + [[RESULT:...]] marker)
 *   [User message]
 *   5. player_stats
 *   6. player_strategy
 */
exports.submitBattle = (0, https_1.onCall)({ secrets: [config_1.GEMINI_API_KEY, config_1.CLAUDE_API_KEY], timeoutSeconds: 120 }, async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const data = request.data;
    if (!data.playerStrategy || data.playerStrategy.trim().length === 0) {
        throw new https_1.HttpsError("invalid-argument", "Strategy is required.");
    }
    const strategyLen = data.playerStrategy.trim().length;
    if (strategyLen < 5) {
        throw new https_1.HttpsError("invalid-argument", "Strategy is too short.");
    }
    if (strategyLen > 2000) {
        throw new https_1.HttpsError("invalid-argument", "Strategy exceeds 2000 characters.");
    }
    if (!data.scenarioId || !data.gameMode) {
        throw new https_1.HttpsError("invalid-argument", "scenarioId and gameMode are required.");
    }
    if (containsInappropriateContent(data.playerStrategy)) {
        throw new https_1.HttpsError("invalid-argument", "CONTENT_FILTER_BLOCKED");
    }
    if (data.raceName && containsInappropriateContent(data.raceName)) {
        throw new https_1.HttpsError("invalid-argument", "CONTENT_FILTER_BLOCKED");
    }
    // Soft-validate race stats (30-point budget, 0–10 per stat).
    if (data.raceStats) {
        const values = Object.values(data.raceStats);
        const sum = values.reduce((a, b) => a + (Number(b) || 0), 0);
        if (sum > 30 || values.some((v) => Number(v) < 0 || Number(v) > 10)) {
            throw new https_1.HttpsError("invalid-argument", "Invalid raceStats.");
        }
    }
    const gameMode = data.gameMode;
    // Flash-Lite only for short practice/tabletop. history_puzzle needs a real report.
    const useLiteModel = gameMode === "practice" || gameMode === "tabletop";
    const isFreeMode = useLiteModel || gameMode === "history_puzzle";
    const modelChoice = useLiteModel ? "gemini" : ((_a = data.modelChoice) !== null && _a !== void 0 ? _a : "gemini");
    const rcData = await (0, prompt_1.fetchRemoteConfigData)();
    const rcCosts = (_b = rcData.ticket_costs) !== null && _b !== void 0 ? _b : {};
    // Prefer mode-specific cost (boss/epic/normal/pvp), then model keys, then defaults.
    const cost = isFreeMode
        ? ((_c = rcCosts["practice"]) !== null && _c !== void 0 ? _c : config_1.TICKET_COSTS.practice)
        : modelChoice === "claude"
            ? ((_d = rcCosts["claude"]) !== null && _d !== void 0 ? _d : config_1.TICKET_COSTS.claude)
            : ((_g = (_f = (_e = rcCosts[gameMode]) !== null && _e !== void 0 ? _e : rcCosts["gemini"]) !== null && _f !== void 0 ? _f : config_1.TICKET_COSTS[gameMode]) !== null && _g !== void 0 ? _g : config_1.TICKET_COSTS.gemini);
    const devUids = (_h = rcData.dev_uids) !== null && _h !== void 0 ? _h : [];
    const isDevUser = devUids.includes(uid);
    if (cost > 0 && !isDevUser) {
        await (0, firestore_1.deductTickets)(uid, cost);
    }
    const worldviewKey = (_j = data.worldviewKey) !== null && _j !== void 0 ? _j : "1830_fantasy";
    const basePrompt = await (0, prompt_1.assemblePrompt)(worldviewKey, data.scenarioId, gameMode);
    // Pin the output language at both ends.
    //
    // Only the Japanese branch existed. English players got no language
    // instruction at all, and the assembled prompt is largely worldview text
    // written by the client - which is Japanese even in the English fields.
    // With nothing telling it otherwise the model follows the language of its
    // own system prompt, so an English player got English on one battle and
    // Japanese on the next. Observed on device: an English normal battle came
    // back in English, and the epic chronicle right after it came back in
    // Japanese.
    //
    // This does not make the prompt English. It stops the language of the
    // report from depending on it.
    const systemPrompt = data.locale === "ja"
        ? `${basePrompt}\n\n必ず日本語で回答してください。結果マーカー [[RESULT:...]] はそのまま英語形式で出力してください。`
        : `${basePrompt}\n\nAlways write your entire response in English.`;
    const userMessage = (0, prompt_1.formatBattleUserMessage)(data.playerStrategy, data.raceStats, data.raceName);
    let reportText;
    try {
        const maxTokens = maxTokensForMode(gameMode);
        if (modelChoice === "claude") {
            const rcModels = (_k = rcData.model_config) !== null && _k !== void 0 ? _k : {};
            const claudeModel = (_l = rcModels["claude"]) !== null && _l !== void 0 ? _l : undefined;
            reportText = await (0, ai_1.callClaude)(config_1.CLAUDE_API_KEY.value(), systemPrompt, userMessage, claudeModel, maxTokens);
        }
        else {
            const rcModels = (_m = rcData.model_config) !== null && _m !== void 0 ? _m : {};
            const modelId = useLiteModel
                ? ((_o = rcModels["gemini_flash_lite"]) !== null && _o !== void 0 ? _o : config_1.GEMINI_FLASH_LITE)
                : ((_p = rcModels["gemini_flash"]) !== null && _p !== void 0 ? _p : config_1.GEMINI_FLASH);
            reportText = await (0, ai_1.callGemini)(config_1.GEMINI_API_KEY.value(), systemPrompt, userMessage, modelId, maxTokens);
        }
    }
    catch (err) {
        console.error("AI call failed:", err);
        await refundTickets(uid, cost, isDevUser);
        throw new https_1.HttpsError("internal", "AI service error. Please try again.");
    }
    if (!reportText || !reportText.trim()) {
        console.error("AI returned empty report", { worldviewKey, gameMode, uid });
        await refundTickets(uid, cost, isDevUser);
        throw new https_1.HttpsError("internal", "AI returned an empty report. Please try again.");
    }
    const parsed = (0, outcome_1.parseOutcome)(reportText);
    if (!parsed) {
        console.error("Failed to parse battle outcome. Raw (truncated):", reportText.substring(0, 500));
        await refundTickets(uid, cost, isDevUser);
        throw new https_1.HttpsError("internal", "OUTCOME_PARSE_FAILED: Could not determine battle result. Please try again.");
    }
    // Strip structured markers from all player-facing text.
    const cleanedReport = (0, outcome_1.stripResultMarkers)(reportText);
    const displayReport = gameMode === "tabletop"
        ? cleanedReport.substring(0, 80)
        : cleanedReport;
    if (!displayReport) {
        console.error("Report empty after stripping markers");
        await refundTickets(uid, cost, isDevUser);
        throw new https_1.HttpsError("internal", "AI returned an empty report. Please try again.");
    }
    const shortSummary = extractShortSummary(displayReport, gameMode);
    updateLastLogin(uid);
    void updateWinLoss(uid, parsed.outcome);
    return Object.assign({ reportText: displayReport, outcome: parsed.outcome, shortSummary, ticketsConsumed: cost, worldviewKey }, (parsed.survivalDays !== undefined
        ? { survivalDays: parsed.survivalDays }
        : {}));
});
async function refundTickets(uid, cost, isDevUser) {
    if (cost > 0 && !isDevUser) {
        try {
            await (0, firestore_1.addTickets)(uid, cost);
            console.log(`Refunded ${cost} ticket(s) to ${uid}.`);
        }
        catch (refundErr) {
            console.error("Ticket refund failed:", refundErr);
        }
    }
}
const BLACKLIST_EN = [
    "fuck", "shit", "bitch", "nigger", "nigga", "faggot", "retard",
    "kike", "spic", "chink", "whore", "cunt", "bastard", "asshole",
];
const BLACKLIST_JA = ["バカ", "死ね", "クソ", "うざい", "ファック"];
const EN_PATTERNS = BLACKLIST_EN.map((w) => new RegExp(`\\b${w}\\b`, "iu"));
function containsInappropriateContent(text) {
    if (EN_PATTERNS.some((re) => re.test(text)))
        return true;
    return BLACKLIST_JA.some((word) => text.includes(word));
}
function extractShortSummary(text, gameMode) {
    if (gameMode === "tabletop") {
        return text.trim().substring(0, 60);
    }
    // First sentence, trimmed to 120 characters on a word boundary.
    //
    // This used to cut at exactly 120 characters, which lands mid-word: the
    // result banner read "...but high Life (8) and Streng". Back up to the last
    // space so the summary ends on a whole word. A string with no space in the
    // first 120 characters is a script that does not use them (Japanese), where
    // cutting at the character boundary is already correct.
    const firstSentence = text.split(/[.!？。]/)[0].trim();
    if (firstSentence.length <= 120)
        return firstSentence;
    const clipped = firstSentence.substring(0, 120);
    const lastSpace = clipped.lastIndexOf(" ");
    return (lastSpace > 60 ? clipped.substring(0, lastSpace) : clipped) + "…";
}
async function updateLastLogin(uid) {
    try {
        await admin.firestore()
            .collection("users")
            .doc(uid)
            .update({ lastLoginAt: Date.now() });
    }
    catch (_a) {
        // Non-critical
    }
}
async function updateWinLoss(uid, outcome) {
    try {
        const ref = admin.firestore().collection("users").doc(uid);
        if (outcome === "win") {
            await ref.update({ totalWins: admin.firestore.FieldValue.increment(1) });
        }
        else if (outcome === "loss") {
            await ref.update({ totalLosses: admin.firestore.FieldValue.increment(1) });
        }
    }
    catch (err) {
        console.warn("updateWinLoss failed:", err);
    }
}
//# sourceMappingURL=submitBattle.js.map