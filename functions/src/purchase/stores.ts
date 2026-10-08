import * as crypto from "crypto";
import * as https from "https";
import { JWT } from "google-auth-library";
import { Product } from "./products";
import { AppleTransaction, decodeAppleTransaction } from "./appleVerifier";
import { StoreRefusal } from "./refusal";

// Defined apart so appleVerifier.ts can throw it too, without importing this file.
export { StoreRefusal };

/** Must match android/app/build.gradle.kts applicationId. */
export const ANDROID_PACKAGE_NAME = "app.steelverdict.game";

export type PurchaseState =
  | "active" | "grace" | "on_hold" | "expired" | "refunded" | "revoked" | "pending";

/**
 * A purchase as the store itself reports it. Everything here comes from the
 * store's answer, never from the app's request (A3, A5b).
 */
export interface VerifiedPurchase {
  platform: "ios" | "android";
  productId: string;
  ledgerId: string;
  /** appAccountToken (Apple) / obfuscatedExternalAccountId (Google), if the app set it. */
  accountId?: string;
  state: PurchaseState;
  /** Subscriptions: end of the paid period, in ms. */
  expiresAt?: number;
  /** Sandbox, TestFlight, Play license tester. */
  test: boolean;
  environment?: string;
  transactionId?: string;
  originalTransactionId?: string;
  purchaseToken?: string;
  orderId?: string;
  linkedPurchaseToken?: string;
}

// ─── Google Play ─────────────────────────────────────────────────────────────

/** Ledger row ID of an Android purchase. Tokens are long and opaque, so hashed. */
export function androidLedgerId(purchaseToken: string): string {
  return `android_${crypto.createHash("sha256").update(purchaseToken).digest("hex")}`;
}

export async function verifyGooglePlay(
  productId: string,
  product: Product,
  purchaseToken: string,
  serviceAccountJson: string,
): Promise<VerifiedPurchase> {
  if (!purchaseToken) throw new StoreRefusal("missing_token");
  const ledgerId = androidLedgerId(purchaseToken);
  const accessToken = await googleAccessToken(serviceAccountJson);
  const base =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${ANDROID_PACKAGE_NAME}/purchases`;

  if (product.kind === "subscription") {
    // subscriptionsv2 replaces the old paymentState check: it reports the real
    // state, the product, the expiry and the buyer's account ID.
    const sub = await playGet(`${base}/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`, accessToken);
    const items = (sub.lineItems as Array<Record<string, unknown>> | undefined) ?? [];
    const item = items.find((i) => i.productId === productId) ?? items[0];
    const expiresAt = item?.expiryTime ? Date.parse(String(item.expiryTime)) : undefined;
    const ids = (sub.externalAccountIdentifiers as Record<string, unknown> | undefined) ?? {};
    return {
      platform: "android",
      productId: String(item?.productId ?? ""),
      ledgerId,
      accountId: optionalString(ids.obfuscatedExternalAccountId),
      state: playSubscriptionState(String(sub.subscriptionState ?? ""), expiresAt),
      expiresAt,
      test: sub.testPurchase !== undefined,
      purchaseToken,
      orderId: optionalString(sub.latestOrderId),
      linkedPurchaseToken: optionalString(sub.linkedPurchaseToken),
    };
  }

  // One-time products: ticket packs and the scenario pack.
  const p = await playGet(
    `${base}/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`, accessToken);
  // purchaseState: 0 purchased, 1 cancelled, 2 pending.
  const purchaseState = Number(p.purchaseState);
  return {
    platform: "android",
    // products.get is asked about one product, so a token for another product
    // is refused by Play itself; the answer's productId, when present, must agree.
    productId: optionalString(p.productId) ?? productId,
    ledgerId,
    accountId: optionalString(p.obfuscatedExternalAccountId),
    state: purchaseState === 0 ? "active" : purchaseState === 2 ? "pending" : "refunded",
    test: Number(p.purchaseType) === 0,
    purchaseToken,
    orderId: optionalString(p.orderId),
  };
}

function playSubscriptionState(state: string, expiresAt?: number): PurchaseState {
  const now = Date.now();
  switch (state) {
  case "SUBSCRIPTION_STATE_ACTIVE":
    return "active";
  case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
    return "grace";
  case "SUBSCRIPTION_STATE_ON_HOLD":
  case "SUBSCRIPTION_STATE_PAUSED":
    return "on_hold";
  case "SUBSCRIPTION_STATE_CANCELED":
    // Auto-renew is off, but the paid period runs to its end.
    return expiresAt !== undefined && expiresAt > now ? "active" : "expired";
  case "SUBSCRIPTION_STATE_PENDING":
    return "pending";
  default:
    // EXPIRED, PENDING_PURCHASE_CANCELED, and anything new: nothing to grant.
    return "expired";
  }
}

async function playGet(url: string, accessToken: string): Promise<Record<string, unknown>> {
  const { status, body } = await httpsGet(url, { Authorization: `Bearer ${accessToken}` });
  if (status === 200) return JSON.parse(body) as Record<string, unknown>;
  // 400/404/410: Play doesn't know this purchase (forged, wrong product, or
  // gone). 401/403 and 5xx are our setup or Play's outage: retry, don't refuse.
  if (status === 400 || status === 404 || status === 410) throw new StoreRefusal("store_unknown_purchase");
  throw new Error(`Play API answered ${status}: ${body.slice(0, 300)}`);
}

async function googleAccessToken(serviceAccountJson: string): Promise<string> {
  const serviceAccount = JSON.parse(serviceAccountJson) as { client_email: string; private_key: string };
  const client = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const tokens = await client.authorize();
  if (!tokens.access_token) throw new Error("Failed to obtain a Google access token.");
  return tokens.access_token;
}

function httpsGet(url: string, headers: Record<string, string>): Promise<{ status: number; body: string }> {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { headers }, (res) => {
      let body = "";
      res.on("data", (chunk) => {
        body += chunk;
      });
      res.on("end", () => resolve({ status: res.statusCode ?? 0, body }));
    });
    req.on("error", reject);
    req.setTimeout(20000, () => req.destroy(new Error("Play API timed out")));
  });
}

// ─── Apple ───────────────────────────────────────────────────────────────────

/**
 * On iOS the app sends the signed transaction (JWS) that StoreKit 2 gave it.
 * Its signature, bundle ID, App Apple ID and environment are checked in
 * appleVerifier.ts; this maps the decoded transaction.
 */
export async function verifyApple(jws: string, product: Product): Promise<VerifiedPurchase> {
  if (!jws) throw new StoreRefusal("missing_transaction");
  const t: AppleTransaction = await decodeAppleTransaction(jws);
  const now = Date.now();
  let state: PurchaseState = "active";
  if (t.revocationDate !== undefined) state = "refunded";
  else if (product.kind === "subscription" && (t.expiresDate === undefined || t.expiresDate <= now)) state = "expired";
  return {
    platform: "ios",
    productId: t.productId,
    // A consumable is one transaction. A subscription or the scenario pack keeps
    // its original transaction ID across renewals and restores, so it is one row.
    ledgerId: product.kind === "consumable"
      ? `ios_${t.transactionId}`
      : `ios_${t.originalTransactionId}`,
    accountId: t.appAccountToken?.toLowerCase(),
    state,
    expiresAt: t.expiresDate,
    test: t.environment !== "Production",
    environment: t.environment,
    transactionId: t.transactionId,
    originalTransactionId: t.originalTransactionId,
  };
}

function optionalString(v: unknown): string | undefined {
  return typeof v === "string" && v.length > 0 ? v : undefined;
}
