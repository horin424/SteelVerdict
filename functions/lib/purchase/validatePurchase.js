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
exports.validatePurchase = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const https = __importStar(require("https"));
const google_auth_library_1 = require("google-auth-library");
const config_1 = require("../utils/config");
// Map product IDs to subscription tiers — must match iap_purchase_service.dart
const SUBSCRIPTION_TIERS = {
    "strategy_sub_500": "sub500",
    "strategy_sub_1000": "sub1000",
    "strategy_sub_3000": "sub3000",
};
// Ticket pack amounts — must match iap_purchase_service.dart
const TICKET_PACKS = {
    "strategy_tickets_10": 10,
    "strategy_tickets_30": 30,
};
/**
 * validatePurchase — receipt validation + entitlement update.
 *
 * Android: verifies purchase token with Google Play Developer API.
 * iOS: verifies receipt with Apple's App Store validation endpoint.
 *
 * On success:
 *   - Subscription → update subscriptionTier in Firestore
 *   - Ticket pack  → add tickets to user balance
 *
 * Setup required:
 *   - Android: `firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT`
 *     Value: JSON string of your Google Play service account credentials.
 *   - iOS: `firebase functions:secrets:set APPLE_SHARED_SECRET`
 *     Value: your App Store Connect shared secret.
 */
exports.validatePurchase = (0, https_1.onCall)({ secrets: [config_1.GOOGLE_PLAY_SERVICE_ACCOUNT, config_1.APPLE_SHARED_SECRET] }, async (request) => {
    var _a, _b;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const data = request.data;
    if (!data.platform || !data.productId) {
        throw new https_1.HttpsError("invalid-argument", "platform and productId are required.");
    }
    // Validate with platform
    let isValid = false;
    try {
        if (data.platform === "android") {
            isValid = await validateAndroid(data.productId, (_a = data.purchaseToken) !== null && _a !== void 0 ? _a : "", data.isSubscription, config_1.GOOGLE_PLAY_SERVICE_ACCOUNT.value());
        }
        else {
            isValid = await validateApple((_b = data.receiptData) !== null && _b !== void 0 ? _b : "", config_1.APPLE_SHARED_SECRET.value());
        }
    }
    catch (err) {
        console.error("Receipt validation error:", err);
        throw new https_1.HttpsError("internal", "Receipt validation failed.");
    }
    if (!isValid) {
        throw new https_1.HttpsError("permission-denied", "Invalid receipt.");
    }
    // Grant entitlement
    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    if (data.productId in SUBSCRIPTION_TIERS) {
        const tier = SUBSCRIPTION_TIERS[data.productId];
        await userRef.update({
            subscriptionTier: tier,
            subscriptionUpdatedAt: Date.now(),
        });
        return { granted: "subscription", tier };
    }
    if (data.productId in TICKET_PACKS) {
        const amount = TICKET_PACKS[data.productId];
        await admin.firestore().runTransaction(async (tx) => {
            var _a, _b;
            const snap = await tx.get(userRef);
            if (!snap.exists)
                throw new https_1.HttpsError("not-found", "User not found.");
            const current = (_b = (_a = snap.data()) === null || _a === void 0 ? void 0 : _a.ticketCount) !== null && _b !== void 0 ? _b : 0;
            tx.update(userRef, { ticketCount: current + amount });
        });
        return { granted: "tickets", amount };
    }
    throw new https_1.HttpsError("invalid-argument", `Unknown productId: ${data.productId}`);
});
// ─── Android validation ───────────────────────────────────────────────────────
async function validateAndroid(productId, purchaseToken, isSubscription, serviceAccountJson) {
    if (!purchaseToken)
        return false;
    // For production: use googleapis library with service account
    // This is a simplified implementation — see README for full setup
    const serviceAccount = JSON.parse(serviceAccountJson);
    // Get access token via JWT
    const accessToken = await getGoogleAccessToken(serviceAccount);
    const packageName = "com.example.strategy_game"; // Update with your actual package name
    const type = isSubscription ? "subscriptions" : "products";
    const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/${type}/${productId}/tokens/${purchaseToken}`;
    const responseBody = await httpsGet(url, { Authorization: `Bearer ${accessToken}` });
    const parsed = JSON.parse(responseBody);
    if (isSubscription) {
        // Check paymentState: 1 = paid, 2 = free trial
        const paymentState = parsed["paymentState"];
        return paymentState === 1 || paymentState === 2;
    }
    else {
        // Check purchaseState: 0 = purchased
        return parsed["purchaseState"] === 0;
    }
}
// ─── Apple validation ─────────────────────────────────────────────────────────
async function validateApple(receiptData, sharedSecret) {
    if (!receiptData)
        return false;
    const payload = JSON.stringify({
        "receipt-data": receiptData,
        "password": sharedSecret,
        "exclude-old-transactions": true,
    });
    // Try production first, then sandbox
    for (const url of [
        "https://buy.itunes.apple.com/verifyReceipt",
        "https://sandbox.itunes.apple.com/verifyReceipt",
    ]) {
        const response = await httpsPost(url, payload);
        const parsed = JSON.parse(response);
        if (parsed.status === 0)
            return true;
        if (parsed.status === 21007)
            continue; // Sandbox receipt on production — retry
        break;
    }
    return false;
}
// ─── HTTP helpers ─────────────────────────────────────────────────────────────
function httpsGet(url, headers) {
    return new Promise((resolve, reject) => {
        const req = https.get(url, { headers }, (res) => {
            let data = "";
            res.on("data", (chunk) => { data += chunk; });
            res.on("end", () => resolve(data));
        });
        req.on("error", reject);
    });
}
function httpsPost(url, body) {
    return new Promise((resolve, reject) => {
        const urlObj = new URL(url);
        const options = {
            hostname: urlObj.hostname,
            path: urlObj.pathname,
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Content-Length": Buffer.byteLength(body),
            },
        };
        const req = https.request(options, (res) => {
            let data = "";
            res.on("data", (chunk) => { data += chunk; });
            res.on("end", () => resolve(data));
        });
        req.on("error", reject);
        req.write(body);
        req.end();
    });
}
async function getGoogleAccessToken(serviceAccount) {
    const jwtClient = new google_auth_library_1.JWT({
        email: serviceAccount.client_email,
        key: serviceAccount.private_key,
        scopes: ["https://www.googleapis.com/auth/androidpublisher"],
    });
    const tokens = await jwtClient.authorize();
    if (!tokens.access_token) {
        throw new Error("Failed to obtain Google access token.");
    }
    return tokens.access_token;
}
//# sourceMappingURL=validatePurchase.js.map