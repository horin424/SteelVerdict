"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateWarHistory = void 0;
const https_1 = require("firebase-functions/v2/https");
const config_1 = require("../utils/config");
const ai_1 = require("../utils/ai");
const firestore_1 = require("../utils/firestore");
// Cost: 3 tickets (same as Claude) — or free for ¥3000/mo subscribers
const WAR_HISTORY_TICKET_COST = 3;
/**
 * generateWarHistory — creates a 3000-char official war history narrative.
 *
 * Uses Claude Haiku for rich, narrative prose quality.
 * Subscription ¥3000/mo → unlimited (cost = 0).
 * Otherwise costs 3 tickets per generation.
 */
exports.generateWarHistory = (0, https_1.onCall)({ secrets: [config_1.CLAUDE_API_KEY], timeoutSeconds: 120 }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const data = request.data;
    if (!data.playerStrategy || !data.raceName) {
        throw new https_1.HttpsError("invalid-argument", "playerStrategy and raceName are required.");
    }
    // Check subscription tier
    const user = await (0, firestore_1.getUser)(uid);
    const isUnlimited = user.subscriptionTier === "sub3000";
    const cost = isUnlimited ? 0 : WAR_HISTORY_TICKET_COST;
    if (cost > 0) {
        await (0, firestore_1.deductTickets)(uid, cost);
    }
    const statsText = Object.entries(data.raceStats)
        .map(([k, v]) => `${k}: ${v}`)
        .join(", ");
    const outcomeWord = data.outcome === "win" ? "VICTORY"
        : data.outcome === "loss" ? "DEFEAT"
            : "STALEMATE";
    const systemPrompt = `You are a prestigious military historian writing official war chronicles.
Write in a formal, epic narrative style — as if this battle will be remembered for centuries.
Use vivid, dramatic language. Describe the terrain, weather, troop movements, and the turning point of the battle.
The chronicle should be approximately 3000 characters long.
Do NOT use markdown headers or bullet points. Write continuous flowing prose.
End with a paragraph reflecting on the historical significance of this battle.`;
    const userMessage = `Write an official war history chronicle for the following battle:

Title: ${data.battleTitle}
Commander's Race: ${data.raceName}
Race Statistics: ${statsText}
Opponent: ${data.opponentName || "Unknown Enemy"}
Outcome: ${outcomeWord}
Strategy Employed: ${data.playerStrategy}
${data.shortReport ? `Battle Summary: ${data.shortReport}` : ""}

Write the full chronicle now (approximately 3000 characters):`;
    let chronicleText;
    try {
        chronicleText = await (0, ai_1.callClaude)(config_1.CLAUDE_API_KEY.value(), systemPrompt, userMessage, config_1.CLAUDE_HAIKU, 1500);
    }
    catch (err) {
        console.error("generateWarHistory AI error:", err);
        throw new https_1.HttpsError("internal", "Failed to generate war history. Please try again.");
    }
    return {
        chronicleText,
        ticketsConsumed: cost,
    };
});
//# sourceMappingURL=generateWarHistory.js.map