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
exports.findOrCreatePvpMatch = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const uuid_1 = require("uuid");
/**
 * findOrCreatePvpMatch — matchmaking function.
 *
 * Priority: match with players who logged in within the past 3 days first.
 * If no waiting match exists, create a new one (player waits).
 * If a waiting match is found (not your own), join it → status becomes "active".
 *
 * Returns the match document.
 */
exports.findOrCreatePvpMatch = (0, https_1.onCall)(async (request) => {
    var _a, _b;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const data = request.data;
    if (!data.raceName || !data.raceStats) {
        throw new https_1.HttpsError("invalid-argument", "raceName and raceStats are required.");
    }
    const db = admin.firestore();
    const matchesRef = db.collection("pvp_matches");
    // Look for a waiting match (not your own, not expired)
    const now = Date.now();
    const waitingQuery = await matchesRef
        .where("status", "==", "waiting")
        .where("playerBUid", "==", "")
        .orderBy("createdAt", "asc")
        .limit(20)
        .get();
    // Filter: not your own match, not expired
    const candidates = waitingQuery.docs.filter((doc) => {
        const d = doc.data();
        return d.playerAUid !== uid && d.expiresAt > now;
    });
    // Prefer recently-active players (logged in within 3 days)
    // The match document doesn't store lastLogin, so we do a quick user fetch
    // for the top few candidates only to keep costs low.
    let bestMatch = null;
    if (candidates.length > 0) {
        const threeDaysAgo = now - 3 * 24 * 60 * 60 * 1000;
        for (const candidate of candidates.slice(0, 5)) {
            const playerAUid = candidate.data().playerAUid;
            const userSnap = await db.collection("users").doc(playerAUid).get();
            const lastLogin = (_b = (_a = userSnap.data()) === null || _a === void 0 ? void 0 : _a.lastLoginAt) !== null && _b !== void 0 ? _b : 0;
            if (lastLogin >= threeDaysAgo) {
                bestMatch = candidate;
                break;
            }
        }
        // Fall back to any candidate if no recently-active player found
        if (!bestMatch)
            bestMatch = candidates[0];
    }
    if (bestMatch) {
        // Join this match
        const matchData = bestMatch.data();
        const expiresAt = now + 24 * 60 * 60 * 1000;
        await bestMatch.ref.update({
            playerBUid: uid,
            playerBRaceName: data.raceName,
            playerBStats: data.raceStats,
            status: "active",
            expiresAt,
        });
        return {
            matchId: matchData.matchId,
            isNewMatch: false,
            opponentUid: matchData.playerAUid,
            opponentRaceName: matchData.playerARaceName,
            opponentStats: matchData.playerAStats,
            expiresAt,
        };
    }
    // No waiting match — create a new one
    const matchId = (0, uuid_1.v4)();
    const expiresAt = now + 24 * 60 * 60 * 1000;
    const newMatch = {
        matchId,
        playerAUid: uid,
        playerBUid: "",
        playerARaceName: data.raceName,
        playerBRaceName: "",
        playerAStats: data.raceStats,
        playerBStats: {},
        playerAStrategy: "",
        playerBStrategy: "",
        shortReport: "",
        winner: "",
        status: "waiting",
        createdAt: now,
        expiresAt,
    };
    await matchesRef.doc(matchId).set(newMatch);
    return {
        matchId,
        isNewMatch: true,
        opponentUid: null,
        opponentRaceName: null,
        opponentStats: null,
        expiresAt,
    };
});
//# sourceMappingURL=findOrCreatePvpMatch.js.map