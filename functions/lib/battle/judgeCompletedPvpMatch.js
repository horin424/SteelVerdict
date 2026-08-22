"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.judgeCompletedPvpMatch = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const config_1 = require("../utils/config");
const judgePvpMatch_1 = require("./judgePvpMatch");
/**
 * Firestore trigger — judges a PvP match once both players have submitted.
 *
 * The previous version fired only on the status transition into "active":
 *
 *   if (before.status === "active" || after.status !== "active") return;
 *   if (!after.playerAStrategy || !after.playerBStrategy) return;
 *
 * findOrCreatePvpMatch sets status to "active" the moment player B *joins*,
 * before either strategy exists — so at the only instant the first guard let
 * through, the second guard always returned. Every later strategy write had
 * before.status === "active" and was rejected by the first. The result: the
 * judge never ran, matches sat until the 24h sweep, and the sweep then told two
 * players who had both submitted that neither of them had.
 *
 * Now the condition is what it should always have been: fire on the update that
 * completes the pair of strategies, whatever the status was doing.
 */
exports.judgeCompletedPvpMatch = (0, firestore_1.onDocumentUpdated)({ document: "pvp_matches/{matchId}", secrets: [config_1.GEMINI_API_KEY] }, async (event) => {
    var _a, _b;
    const after = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after.data();
    const before = (_b = event.data) === null || _b === void 0 ? void 0 : _b.before.data();
    if (!after || !before)
        return;
    const bothNow = !!after.playerAStrategy && !!after.playerBStrategy;
    const bothBefore = !!before.playerAStrategy && !!before.playerBStrategy;
    // Only the update that completes the pair. bothBefore also stops this
    // trigger re-entering on its own result write.
    if (!bothNow || bothBefore)
        return;
    // Already settled (e.g. by the deserter sweep) — leave it alone.
    if (after.status === "resolved" || after.status === "timeout")
        return;
    const matchId = event.params.matchId;
    console.log(`Judging PvP match ${matchId}`);
    try {
        await (0, judgePvpMatch_1.judgePvpMatch)(matchId, after, config_1.GEMINI_API_KEY.value());
    }
    catch (err) {
        // Don't rethrow — a retry would re-run the AI call and double the cost.
        // checkDeserters picks up anything left unresolved at the deadline.
        console.error(`Failed to judge match ${matchId}:`, err);
    }
});
//# sourceMappingURL=judgeCompletedPvpMatch.js.map