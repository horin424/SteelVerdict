import { createPublicKey, KeyObject, verify } from "crypto";

/**
 * Ad tickets from AdMob's server-side verification (SSV).
 *
 * When a player watches a rewarded ad to the end, AdMob calls
 * admobRewardCallback with the reward, signed by Google, and only then are
 * the tickets added. Before, the app's own word was enough (earnAdTickets):
 * any signed-in caller could take the tickets 20 times a day without an ad.
 *
 * Google's description: https://developers.google.com/admob/android/ssv
 * This file has no Firebase in it, so scripts/verify-ad-reward.js can check
 * it offline.
 */

export const TICKETS_PER_AD = 2;
export const MAX_AD_TICKET_CLAIMS_PER_DAY = 20;

/**
 * What the app's ticket button sets as custom_data. The scenario unlock shows
 * the same ad unit with another value, and its ads add no tickets.
 */
export const TICKETS_PURPOSE = "tickets";

/**
 * The rewarded ad units whose rewards add tickets (Remote Config
 * ad_unit_rewarded). AdMob's example sends only the number after the "/" as
 * ad_unit; both forms are accepted. A new ad unit must be added here.
 */
export const REWARDED_AD_UNITS: readonly string[] = ["ca-app-pub-1628452493399507/9303443517"];

/** Google's public keys for the signatures; AdMob says to keep them no longer than 24 hours. */
export const VERIFIER_KEYS_URL = "https://www.gstatic.com/admob/reward/verifier-keys.json";

const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;

/** An older reward is refused, so its record in ad_rewards may expire after REWARD_RECORD_DAYS. */
export const MAX_REWARD_AGE_MS = 7 * DAY_MS;
/** How far a reward's time may be ahead of the server's clock. */
const MAX_CLOCK_AHEAD_MS = HOUR_MS;
/** ad_rewards records carry expireAt this far ahead (for a Firestore TTL policy, if one is set up). */
export const REWARD_RECORD_DAYS = 30;

const KEYS_MAX_AGE_MS = 12 * HOUR_MS;
/** An unknown key_id makes the keys load again, but at most this often. */
const KEYS_RETRY_MS = 60 * 1000;

// ─── The callback's query string ─────────────────────────────────────────────

export interface SignedQuery {
  /** Everything before "&signature=", exactly as sent: what Google signed. */
  message: string;
  signature: Buffer;
  keyId: string;
}

function decoded(value: string): string | null {
  try {
    return decodeURIComponent(value);
  } catch {
    return null;
  }
}

function nameAndValue(pair: string): [string, string] {
  const at = pair.indexOf("=");
  return at < 0 ? [pair, ""] : [pair.slice(0, at), pair.slice(at + 1)];
}

/**
 * Splits AdMob's query string (without the "?"). Google signs everything
 * before "&signature=", and signature and key_id are always the last two
 * parameters, in that order. Null when the query isn't shaped like that.
 */
export function splitSignedQuery(rawQuery: string): SignedQuery | null {
  const at = rawQuery.indexOf("&signature=");
  if (at <= 0) return null;
  const tail = rawQuery.slice(at + 1).split("&").map(nameAndValue);
  if (tail.length !== 2 || tail[0][0] !== "signature" || tail[1][0] !== "key_id") return null;
  const signature = decoded(tail[0][1]);
  const keyId = decoded(tail[1][1]);
  if (!signature || !/^[A-Za-z0-9_\-+/]+=*$/.test(signature)) return null;
  if (!keyId || !/^\d{1,20}$/.test(keyId)) return null;
  // URL-safe base64; Node's "base64url" also reads the standard alphabet.
  const bytes = Buffer.from(signature, "base64url");
  if (bytes.length === 0) return null;
  return { message: rawQuery.slice(0, at), signature: bytes, keyId };
}

/** ECDSA with SHA-256 over the message, the signature in DER. */
export function signatureValid(message: string, signature: Buffer, key: KeyObject): boolean {
  try {
    return verify("sha256", Buffer.from(message, "utf8"), { key, dsaEncoding: "der" }, signature);
  } catch {
    return false;
  }
}

// ─── The reward ──────────────────────────────────────────────────────────────

export interface AdReward {
  adUnit: string;
  customData: string;
  /** The player's Firebase uid, set by the app. */
  userId: string;
  transactionId: string;
  /** When the player was rewarded, epoch milliseconds. */
  rewardedAt: number;
}

/** The reward's values from the signed part (custom_data arrives percent-escaped). */
export function readReward(message: string): AdReward {
  const params = new URLSearchParams(message);
  const timestamp = params.get("timestamp");
  return {
    adUnit: params.get("ad_unit") ?? "",
    customData: params.get("custom_data") ?? "",
    userId: params.get("user_id") ?? "",
    transactionId: params.get("transaction_id") ?? "",
    rewardedAt: timestamp && /^\d{1,16}$/.test(timestamp) ? Number(timestamp) : NaN,
  };
}

export function isRewardedAdUnit(adUnit: string, units: readonly string[] = REWARDED_AD_UNITS): boolean {
  return units.some((id) => adUnit === id || adUnit === id.slice(id.lastIndexOf("/") + 1));
}

export type RewardRefusal =
  | "unknown_ad_unit" | "not_tickets" | "bad_user" | "bad_transaction" | "bad_time" | "too_old";

/** Why a correctly signed reward adds no tickets, or null when it does. */
export function rewardRefusal(
  reward: AdReward, now: number, units: readonly string[] = REWARDED_AD_UNITS,
): RewardRefusal | null {
  if (!isRewardedAdUnit(reward.adUnit, units)) return "unknown_ad_unit";
  if (reward.customData !== TICKETS_PURPOSE) return "not_tickets";
  // Both become Firestore document ids: letters and digits only.
  if (!/^[A-Za-z0-9]{1,128}$/.test(reward.userId)) return "bad_user";
  if (!/^[A-Za-z0-9]{1,128}$/.test(reward.transactionId)) return "bad_transaction";
  if (!Number.isFinite(reward.rewardedAt) || reward.rewardedAt > now + MAX_CLOCK_AHEAD_MS) return "bad_time";
  if (reward.rewardedAt < now - MAX_REWARD_AGE_MS) return "too_old";
  return null;
}

// ─── The tickets ─────────────────────────────────────────────────────────────

/** The user document's fields that the ad tickets use. */
export interface AdTicketFields {
  ticketCount?: number;
  adTicketClaimsDate?: string;
  adTicketClaimsCount?: number;
}

export type AdTicketDecision =
  | { granted: true; update: { ticketCount: number; adTicketClaimsDate: string; adTicketClaimsCount: number } }
  | { granted: false };

/** +2 tickets, at most 20 times per day in Japan ([today] from japanDateString), like earnAdTickets. */
export function adTicketDecision(user: AdTicketFields, today: string): AdTicketDecision {
  const count = user.adTicketClaimsDate === today ? (user.adTicketClaimsCount ?? 0) : 0;
  if (count >= MAX_AD_TICKET_CLAIMS_PER_DAY) return { granted: false };
  return {
    granted: true,
    update: {
      ticketCount: (user.ticketCount ?? 0) + TICKETS_PER_AD,
      adTicketClaimsDate: today,
      adTicketClaimsCount: count + 1,
    },
  };
}

// ─── Google's public keys ────────────────────────────────────────────────────

export interface VerifierKey {
  keyId: number | string;
  pem: string;
}

export interface KeyStore {
  get(keyId: string): Promise<KeyObject | undefined>;
}

/** Google's current keys. Throws when they can't be loaded. */
export async function fetchVerifierKeys(): Promise<VerifierKey[]> {
  const res = await fetch(VERIFIER_KEYS_URL, { signal: AbortSignal.timeout(5000) });
  if (!res.ok) throw new Error(`AdMob verifier keys: HTTP ${res.status}`);
  const body = (await res.json()) as { keys?: unknown };
  return (Array.isArray(body.keys) ? body.keys : []).filter(
    (k): k is VerifierKey =>
      !!k && (typeof k.keyId === "number" || typeof k.keyId === "string") && typeof k.pem === "string",
  );
}

/**
 * Keeps Google's keys for up to 12 hours. An unknown key_id loads them again
 * (at most once a minute), as Google may have rotated them. If loading fails
 * while older keys are at hand, those are used and the failure is logged;
 * with no keys at all, get() throws (the callback answers 500 and AdMob tries
 * again).
 */
export function createKeyStore(
  fetchKeys: () => Promise<VerifierKey[]>, now: () => number = Date.now,
): KeyStore {
  let keys = new Map<string, KeyObject>();
  let loadedAt = -Infinity;
  let triedAt = -Infinity;
  let loading: Promise<void> | null = null;

  async function load(): Promise<void> {
    triedAt = now();
    try {
      const next = new Map<string, KeyObject>();
      for (const key of await fetchKeys()) {
        try {
          next.set(String(key.keyId), createPublicKey(key.pem));
        } catch {
          console.error(`AdMob verifier key ${key.keyId}: not a public key, skipped`);
        }
      }
      if (next.size === 0) throw new Error("AdMob verifier keys: none usable");
      keys = next;
      loadedAt = now();
    } catch (err) {
      if (keys.size === 0) throw err;
      console.error("AdMob verifier keys: loading failed, using the previous ones", err);
    }
  }

  function loadOnce(): Promise<void> {
    if (!loading) loading = load().finally(() => { loading = null; });
    return loading;
  }

  return {
    async get(keyId: string) {
      const stale = now() - loadedAt > KEYS_MAX_AGE_MS;
      const mayRetry = now() - triedAt > KEYS_RETRY_MS;
      if ((stale && (keys.size === 0 || mayRetry)) || (!keys.has(keyId) && mayRetry)) await loadOnce();
      return keys.get(keyId);
    },
  };
}
