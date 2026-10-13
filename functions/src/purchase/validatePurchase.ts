import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GOOGLE_PLAY_SERVICE_ACCOUNT } from "../utils/config";
import { productFor } from "./products";
import { purchaseAccountId } from "./accountId";
import { StoreRefusal, VerifiedPurchase, verifyApple, verifyGooglePlay } from "./stores";
import { AccountMatch, ClaimResult, claimPurchase, refused } from "./ledger";
import { ensureUserDoc } from "../utils/firestore";

interface ValidatePurchaseRequest {
  platform: "android" | "ios";
  productId: string;
  /** Android: the Play purchase token. */
  purchaseToken?: string;
  /** iOS: the StoreKit 2 signed transaction (JWS). */
  receiptData?: string;
}

/**
 * validatePurchase: the app hands over a store purchase; the server checks it
 * with the store, records it in the purchase ledger, and grants it once.
 *
 * 1. Ask the store: Apple's signed transaction, or the Google Play API. The
 *    request only says which purchase to look up (A3).
 * 2. The store's product must be the requested one and in the product table
 *    (A5b).
 * 3. The store's account ID must be the caller's (purchaseAccountId); the
 *    ledger also lets a guest who reinstalled restore a subscription or the
 *    scenario pack (ledger.ts).
 * 4. Ledger row and grant in one transaction (A5a). Subscriptions then
 *    recompute the tier from the ledger.
 *
 * Answers { status: granted | already_granted | refused | pending, reason?,
 * granted?, tier?, amount? }. When the store can't be reached the call fails
 * with "unavailable": the app keeps the purchase open and tries again.
 *
 * Setup: the GOOGLE_PLAY_SERVICE_ACCOUNT secret (Play); APPLE_BUNDLE_ID and
 * APPLE_APP_ID (plain params) and Apple's root certificates in functions/certs
 * (App Store).
 */
export const validatePurchase = onCall(
  { secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT] },
  async (request): Promise<ClaimResult> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const data = (request.data ?? {}) as ValidatePurchaseRequest;
    if ((data.platform !== "android" && data.platform !== "ios") || typeof data.productId !== "string") {
      throw new HttpsError("invalid-argument", "platform and productId are required.");
    }
    const product = productFor(data.productId);
    if (!product) return refused("unknown_product");
    // The grant updates the player's document; without one a paid purchase
    // could never be granted.
    await ensureUserDoc(uid);

    let verified: VerifiedPurchase;
    try {
      verified = data.platform === "android"
        ? await verifyGooglePlay(
          data.productId, product, String(data.purchaseToken ?? ""), GOOGLE_PLAY_SERVICE_ACCOUNT.value())
        : await verifyApple(String(data.receiptData ?? ""), product);
    } catch (err) {
      if (err instanceof StoreRefusal) {
        console.warn(`validatePurchase: ${uid} ${data.productId}: refused by the store (${err.reason})`);
        return refused(err.reason);
      }
      console.error("validatePurchase: store check failed:", err);
      throw new HttpsError("unavailable", "Could not check the purchase with the store. Please try again.");
    }

    // The store's answer, not the request, decides what the purchase is (A5b).
    if (verified.productId !== data.productId) return refused("product_mismatch");
    if (verified.state === "pending") return { status: "pending" };

    const accountMatch: AccountMatch = verified.accountId === undefined
      ? "unknown"
      : verified.accountId === purchaseAccountId(uid) ? "mine" : "other";
    const result = await claimPurchase(uid, verified, product, accountMatch);
    console.log(
      `validatePurchase: ${uid} ${data.productId} ${verified.platform}${verified.test ? " (test)" : ""}` +
      ` -> ${result.status}${result.reason ? ` (${result.reason})` : ""}`);
    return result;
  },
);
