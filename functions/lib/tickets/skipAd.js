"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.skipAd = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("../utils/firestore");
/**
 * skipAd — deducts 1 ticket so the user can skip an interstitial ad.
 * Used in Practice mode (every 3rd play) and Tabletop mode overlay.
 */
exports.skipAd = (0, https_1.onCall)(async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    try {
        const newCount = await (0, firestore_1.deductTickets)(uid, 1);
        return { ticketsDeducted: 1, newTicketCount: newCount };
    }
    catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        if (msg.includes("Not enough tickets")) {
            throw new https_1.HttpsError("failed-precondition", "Not enough tickets to skip.");
        }
        throw new https_1.HttpsError("internal", "Failed to skip ad.");
    }
});
//# sourceMappingURL=skipAd.js.map