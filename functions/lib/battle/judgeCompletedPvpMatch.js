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
exports.judgeCompletedPvpMatch = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const config_1 = require("../utils/config");
const ai_1 = require("../utils/ai");
const prompt_1 = require("../utils/prompt");
/**
 * Firestore trigger — fires when a pvp_matches document is updated.
 * When both players have submitted strategies (status becomes "active"),
 * calls Gemini Flash to judge the battle and writes the result.
 *
 * Using Gemini Flash for all PvP (fixed model for fairness — spec requirement).
 */
exports.judgeCompletedPvpMatch = (0, firestore_1.onDocumentUpdated)({ document: "pvp_matches/{matchId}", secrets: [config_1.GEMINI_API_KEY] }, async (event) => {
    var _a, _b;
    const after = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after.data();
    const before = (_b = event.data) === null || _b === void 0 ? void 0 : _b.before.data();
    if (!after || !before)
        return;
    // Only run when status transitions to "active"
    if (before.status === "active" || after.status !== "active")
        return;
    if (!after.playerAStrategy || !after.playerBStrategy)
        return;
    const matchId = event.params.matchId;
    console.log(`Judging PvP match ${matchId}`);
    try {
        // Assemble PvP prompt (no commander_definition for PvP)
        const systemPrompt = await (0, prompt_1.assemblePrompt)("1830_fantasy", "pvp", "pvp");
        const userMessage = (0, prompt_1.formatPvpUserMessage)(after.playerAStrategy, after.playerAStats, after.playerARaceName, after.playerBStrategy, after.playerBStats, after.playerBRaceName);
        const response = await (0, ai_1.callGeminiFlash)(config_1.GEMINI_API_KEY.value(), systemPrompt, userMessage);
        // Parse winner and report from response
        const { winner, shortReport } = parsePvpResponse(response, after.playerAUid, after.playerBUid);
        await admin.firestore()
            .collection("pvp_matches")
            .doc(matchId)
            .update({
            winner,
            shortReport,
            status: "resolved",
            resolvedAt: Date.now(),
        });
        console.log(`Match ${matchId} resolved. Winner: ${winner}`);
    }
    catch (err) {
        console.error(`Failed to judge match ${matchId}:`, err);
        // Don't throw — Firestore triggers don't benefit from rethrowing
    }
});
function parsePvpResponse(text, playerAUid, playerBUid) {
    const upper = text.toUpperCase();
    let winner = "draw";
    if (upper.includes("WINNER: PLAYER A")) {
        winner = playerAUid;
    }
    else if (upper.includes("WINNER: PLAYER B")) {
        winner = playerBUid;
    }
    else if (upper.includes("WINNER: DRAW")) {
        winner = "draw";
    }
    // Extract REPORT: line
    const reportMatch = text.match(/REPORT:\s*(.+)/i);
    const shortReport = reportMatch
        ? reportMatch[1].trim().substring(0, 60)
        : text.trim().substring(0, 60);
    return { winner, shortReport };
}
//# sourceMappingURL=judgeCompletedPvpMatch.js.map