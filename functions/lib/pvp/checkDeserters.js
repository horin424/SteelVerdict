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
/**
 * checkDeserters — runs every hour via Cloud Scheduler.
 *
 * Finds all "waiting" or "active" matches past their expiresAt timestamp.
 * - "waiting" (no opponent joined): mark as timeout, no winner.
 * - "active" (one player didn't submit): the player who submitted wins;
 *   the non-submitter is the deserter and completely loses.
 */
exports.checkDeserters = (0, scheduler_1.onSchedule)("every 60 minutes", async () => {
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
    let count = 0;
    for (const doc of expiredQuery.docs) {
        const match = doc.data();
        if (match.status === "waiting") {
            // Nobody joined — just time out
            batch.update(doc.ref, {
                status: "timeout",
                shortReport: "Match timed out — no opponent found.",
                resolvedAt: now,
            });
        }
        else if (match.status === "active") {
            // Determine deserter: whoever has no strategy submitted
            const aSubmitted = !!match.playerAStrategy;
            const bSubmitted = !!match.playerBStrategy;
            let winner = "draw";
            let report = "Both players failed to submit. Draw.";
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
        }
        count++;
    }
    await batch.commit();
    console.log(`checkDeserters: resolved ${count} expired match(es).`);
});
//# sourceMappingURL=checkDeserters.js.map