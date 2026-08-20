import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as https from "https";
import { JWT } from "google-auth-library";
import { GOOGLE_PLAY_SERVICE_ACCOUNT, APPLE_SHARED_SECRET } from "../utils/config";

interface ValidatePurchaseRequest {
  platform: "android" | "ios";
  productId: string;
  purchaseToken?: string;  // Android
  receiptData?: string;    // iOS (base64)
  isSubscription: boolean;
}

// Map product IDs to subscription tiers — must match iap_purchase_service.dart
const SUBSCRIPTION_TIERS: Record<string, string> = {
  "strategy_sub_500":  "sub500",
  "strategy_sub_1000": "sub1000",
  "strategy_sub_3000": "sub3000",
};

// Ticket pack amounts — must match iap_purchase_service.dart
const TICKET_PACKS: Record<string, number> = {
  "strategy_tickets_10":  10,
  "strategy_tickets_30":  30,
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
export const validatePurchase = onCall(
  { secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT, APPLE_SHARED_SECRET] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const data = request.data as ValidatePurchaseRequest;

    if (!data.platform || !data.productId) {
      throw new HttpsError("invalid-argument", "platform and productId are required.");
    }

    // Validate with platform
    let isValid = false;
    try {
      if (data.platform === "android") {
        isValid = await validateAndroid(
          data.productId,
          data.purchaseToken ?? "",
          data.isSubscription,
          GOOGLE_PLAY_SERVICE_ACCOUNT.value(),
        );
      } else {
        isValid = await validateApple(
          data.receiptData ?? "",
          APPLE_SHARED_SECRET.value(),
        );
      }
    } catch (err) {
      console.error("Receipt validation error:", err);
      throw new HttpsError("internal", "Receipt validation failed.");
    }

    if (!isValid) {
      throw new HttpsError("permission-denied", "Invalid receipt.");
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
        const snap = await tx.get(userRef);
        if (!snap.exists) throw new HttpsError("not-found", "User not found.");
        const current = (snap.data()?.ticketCount as number) ?? 0;
        tx.update(userRef, { ticketCount: current + amount });
      });
      return { granted: "tickets", amount };
    }

    throw new HttpsError("invalid-argument", `Unknown productId: ${data.productId}`);
  },
);

// ─── Android validation ───────────────────────────────────────────────────────

async function validateAndroid(
  productId: string,
  purchaseToken: string,
  isSubscription: boolean,
  serviceAccountJson: string,
): Promise<boolean> {
  if (!purchaseToken) return false;

  // For production: use googleapis library with service account
  // This is a simplified implementation — see README for full setup
  const serviceAccount = JSON.parse(serviceAccountJson) as { client_email: string; private_key: string };

  // Get access token via JWT
  const accessToken = await getGoogleAccessToken(serviceAccount);

  const packageName = "com.example.strategy_game"; // Update with your actual package name
  const type = isSubscription ? "subscriptions" : "products";
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/${type}/${productId}/tokens/${purchaseToken}`;

  const responseBody = await httpsGet(url, { Authorization: `Bearer ${accessToken}` });
  const parsed = JSON.parse(responseBody) as Record<string, unknown>;

  if (isSubscription) {
    // Check paymentState: 1 = paid, 2 = free trial
    const paymentState = parsed["paymentState"] as number;
    return paymentState === 1 || paymentState === 2;
  } else {
    // Check purchaseState: 0 = purchased
    return (parsed["purchaseState"] as number) === 0;
  }
}

// ─── Apple validation ─────────────────────────────────────────────────────────

async function validateApple(
  receiptData: string,
  sharedSecret: string,
): Promise<boolean> {
  if (!receiptData) return false;

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
    const parsed = JSON.parse(response) as { status: number };
    if (parsed.status === 0) return true;
    if (parsed.status === 21007) continue; // Sandbox receipt on production — retry
    break;
  }

  return false;
}

// ─── HTTP helpers ─────────────────────────────────────────────────────────────

function httpsGet(url: string, headers: Record<string, string>): Promise<string> {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { headers }, (res) => {
      let data = "";
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => resolve(data));
    });
    req.on("error", reject);
  });
}

function httpsPost(url: string, body: string): Promise<string> {
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

async function getGoogleAccessToken(serviceAccount: { client_email: string; private_key: string }): Promise<string> {
  const jwtClient = new JWT({
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
