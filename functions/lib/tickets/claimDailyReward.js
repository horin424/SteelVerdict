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
exports.earnAdTickets = exports.claimDailyReward = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("../utils/firestore");
// Daily ticket amounts per subscription tier — must match app_constants.dart
// AppConstants.dailyTicketsFree=1, sub500=10, sub1000=15, sub3000=50
const DAILY_TICKETS = {
    free: 1,
    sub500: 10,
    sub1000: 15,
    sub3000: 50,
};
/**
 * claimDailyReward — server-side daily ticket grant.
 *
 * Checks lastDailyRewardAt against current date (UTC).
 * Prevents multiple claims per day regardless of client state.
 */
exports.claimDailyReward = (0, https_1.onCall)(async (request) => {
    var _a, _b;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const user = await (0, firestore_1.getUser)(uid);
    const nowUtc = new Date();
    const todayUtc = toUtcDateString(nowUtc);
    const lastClaimUtc = user.lastDailyRewardAt
        ? toUtcDateString(new Date(user.lastDailyRewardAt))
        : "";
    if (lastClaimUtc === todayUtc) {
        throw new https_1.HttpsError("already-exists", "Daily reward already claimed today.");
    }
    const tier = (_a = user.subscriptionTier) !== null && _a !== void 0 ? _a : "free";
    const amount = (_b = DAILY_TICKETS[tier]) !== null && _b !== void 0 ? _b : DAILY_TICKETS.free;
    // Update lastDailyRewardAt and add tickets atomically
    const ref = admin.firestore().collection("users").doc(uid);
    let newCount = 0;
    await admin.firestore().runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists)
            throw new https_1.HttpsError("not-found", "User not found.");
        const data = snap.data();
        // Double-check inside transaction to be safe
        const lastInTx = data.lastDailyRewardAt
            ? toUtcDateString(new Date(data.lastDailyRewardAt))
            : "";
        if (lastInTx === todayUtc) {
            throw new https_1.HttpsError("already-exists", "Daily reward already claimed today.");
        }
        newCount = data.ticketCount + amount;
        tx.update(ref, {
            ticketCount: newCount,
            lastDailyRewardAt: Date.now(),
        });
    });
    return { ticketsAdded: amount, newTicketCount: newCount };
});
/**
 * earnAdTickets — grant 2 tickets for watching a rewarded ad.
 * No limit per day (spec: "no limit").
 */
exports.earnAdTickets = (0, https_1.onCall)(async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const newCount = await (0, firestore_1.addTickets)(uid, 2);
    return { ticketsAdded: 2, newTicketCount: newCount };
});
function toUtcDateString(date) {
    return date.toISOString().substring(0, 10); // "YYYY-MM-DD"
}
//# sourceMappingURL=claimDailyReward.js.map