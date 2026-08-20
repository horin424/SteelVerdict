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
exports.getUser = getUser;
exports.createUserDoc = createUserDoc;
exports.deductTickets = deductTickets;
exports.addTickets = addTickets;
exports.getPvpMatch = getPvpMatch;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const db = () => admin.firestore();
// Collection names — must match app_constants.dart
const USERS = "users";
const PVP_MATCHES = "pvp_matches";
// ─── User helpers ────────────────────────────────────────────────────────────
async function getUser(uid) {
    const doc = await db().collection(USERS).doc(uid).get();
    if (!doc.exists)
        throw new https_1.HttpsError("not-found", "User document not found.");
    return doc.data();
}
async function createUserDoc(uid, displayName) {
    const now = Date.now();
    const user = {
        uid,
        displayName: displayName || "Anonymous Commander",
        ticketCount: 3, // Starting tickets
        subscriptionTier: "free",
        lastLoginAt: now,
        createdAt: now,
        isBossEnabled: false,
        lastDailyRewardAt: 0,
    };
    await db().collection(USERS).doc(uid).set(user);
    return user;
}
/**
 * Atomically deduct tickets. Throws if insufficient balance.
 * Returns the new ticket count.
 */
async function deductTickets(uid, cost) {
    if (cost <= 0)
        return -1; // Nothing to deduct
    const ref = db().collection(USERS).doc(uid);
    let newCount = 0;
    await db().runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists)
            throw new https_1.HttpsError("not-found", "User not found.");
        const data = snap.data();
        if (data.ticketCount < cost) {
            throw new https_1.HttpsError("resource-exhausted", `Not enough tickets. Need ${cost}, have ${data.ticketCount}.`);
        }
        newCount = data.ticketCount - cost;
        tx.update(ref, { ticketCount: newCount });
    });
    return newCount;
}
/**
 * Atomically add tickets.
 */
async function addTickets(uid, amount) {
    const ref = db().collection(USERS).doc(uid);
    let newCount = 0;
    await db().runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists)
            throw new https_1.HttpsError("not-found", "User not found.");
        const data = snap.data();
        newCount = data.ticketCount + amount;
        tx.update(ref, { ticketCount: newCount });
    });
    return newCount;
}
// ─── PvP helpers ─────────────────────────────────────────────────────────────
async function getPvpMatch(matchId) {
    const doc = await db().collection(PVP_MATCHES).doc(matchId).get();
    if (!doc.exists)
        throw new https_1.HttpsError("not-found", "Match not found.");
    return doc.data();
}
//# sourceMappingURL=firestore.js.map