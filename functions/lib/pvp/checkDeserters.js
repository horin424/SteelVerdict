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
exports.checkDeserters = void 0;
const admin = __importStar(require("firebase-admin"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
const config_1 = require("../utils/config");
const judgePvpMatch_1 = require("../battle/judgePvpMatch");
/**
 * checkDeserters — runs every hour via Cloud Scheduler.
 *
 * Finds all "waiting" or "active" matches past their expiresAt timestamp.
 * - "waiting" (no opponent joined): mark as timeout, no winner.
 * - "active", one strategy missing: the player who submitted wins; the
 *   non-submitter deserted.
 * - "active", BOTH strategies present: judge it properly.
 *
 * That last case used to fall through to the default branch and write
 * winner: "draw" with the report "Both players failed to submit. Draw." — shown
 * to two players who had both, in fact, submitted. It happened to every single
 * match, because the judging trigger never fired (see judgeCompletedPvpMatch).
 * The trigger is fixed now, so reaching this branch should be rare; it stays as
 * a safety net for matches whose AI call failed.
 */
exports.checkDeserters = (0, scheduler_1.onSchedule)({ schedule: "every 60 minutes", secrets: [config_1.GEMINI_API_KEY] }, async () => {
    const db = admin.firestore();
    const now = Date.now();
    const expiredQuery = await db
        .collection("pvp_matches")
        .where("status", "in", ["waiting", "active"])
        .where("expiresAt", "<", now)
        .get();
    if (expiredQuery.empty) {
        console.log("checkDeserters: no expired matches found.");
        return;
    }
    const batch = db.batch();
    let batched = 0;
    let judged = 0;
    const toJudge = [];
    for (const doc of expiredQuery.docs) {
        const match = doc.data();
        if (match.status === "waiting") {
            batch.update(doc.ref, {
                status: "timeout",
                shortReport: "Match timed out — no opponent found.",
                resolvedAt: now,
            });
            batched++;
            continue;
        }
        const aSubmitted = !!match.playerAStrategy;
        const bSubmitted = !!match.playerBStrategy;
        if (aSubmitted && bSubmitted) {
            // Both played. Judge it rather than declaring a false draw.
            toJudge.push({ id: doc.id, data: match });
            continue;
        }
        let winner = "draw";
        let report = "Neither player submitted a strategy. No result.";
        if (aSubmitted && !bSubmitted) {
            winner = match.playerAUid;
            report = "Player B failed to submit a strategy. Player A wins by desertion.";
        }
        else if (!aSubmitted && bSubmitted) {
            winner = match.playerBUid;
            report = "Player A failed to submit a strategy. Player B wins by desertion.";
        }
        batch.update(doc.ref, {
            status: "resolved",
            winner,
            shortReport: report,
            resolvedAt: now,
        });
        batched++;
    }
    if (batched > 0) {
        await batch.commit();
    }
    // Judged one at a time: each is an AI call, and one failure must not stop
    // the rest from being settled.
    for (const m of toJudge) {
        try {
            await (0, judgePvpMatch_1.judgePvpMatch)(m.id, m.data, config_1.GEMINI_API_KEY.value());
            judged++;
        }
        catch (err) {
            console.error(`checkDeserters: failed to judge ${m.id}:`, err);
        }
    }
    console.log(`checkDeserters: ${batched} settled without judging, ${judged} judged, ` +
        `${toJudge.length - judged} failed.`);
});
//# sourceMappingURL=checkDeserters.js.map