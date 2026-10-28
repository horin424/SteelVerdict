import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import { Product, Tier, productFor } from "./products";
import { PACK_PICKED_AT_FIELD, PACK_PICKS_FIELD } from "./scenarioPack";
import { VerifiedPurchase, androidLedgerId } from "./stores";

/**
 * The purchase ledger: purchases/{id}, one row per purchase, server only.
 *
 * The row is written in the same transaction as what it grants, so a purchase
 * sent twice finds its row and grants nothing more (A5a). The row also records
 * whose purchase it is, so it can't be claimed by another account (A5b).
 */
const PURCHASES = "purchases";
const USERS = "users";

export type ClaimStatus = "granted" | "already_granted" | "refused" | "pending";

export interface ClaimResult {
  status: ClaimStatus;
  reason?: string;
  /**
   * What the purchase gives. Also what the app before this change checks: it
   * finishes a purchase when `granted` is present, so a granted or already
   * granted purchase must carry it, and a refused one must not.
   */
  granted?: "subscription" | "tickets" | "scenario_pack";
  tier?: Tier | "free";
  amount?: number;
  /** The purchase moved here from a guest or deleted account (restore after a reinstall). */
  moved?: boolean;
}

/** Whether the store's account ID says the purchase is the caller's. */
export type AccountMatch = "mine" | "other" | "unknown";

export const refused = (reason: string): ClaimResult => ({ status: "refused", reason });

export async function claimPurchase(
  uid: string,
  p: VerifiedPurchase,
  product: Product,
  accountMatch: AccountMatch,
): Promise<ClaimResult> {
  const db = admin.firestore();
  const rowRef = db.collection(PURCHASES).doc(p.ledgerId);
  const userRef = db.collection(USERS).doc(uid);

  // Who holds it now. Taking a subscription or the scenario pack over from
  // another account needs an Auth lookup, which can't run in the transaction.
  const before = await rowRef.get();
  const holder = before.exists ? (before.data()?.uid as string | undefined) : undefined;
  if (!holder && accountMatch === "other") {
    // Bought from another account that has never claimed it: only that
    // account can.
    return refused("other_account");
  }
  let mayMove = false;
  if (holder && holder !== uid && product.kind !== "consumable") {
    // The store says it's the caller's, or its holder can't use it any more:
    // a guest (a reinstall gives the same person a new guest account) or a
    // deleted account. Ticket packs are never moved: they were used up.
    mayMove = accountMatch === "mine" || await holderIsGone(holder);
  }

  const live = p.state === "active" || p.state === "grace";
  if (!live && product.kind !== "subscription") {
    return refused(p.state === "refunded" || p.state === "revoked" ? "refunded" : "not_active");
  }

  const result = await db.runTransaction(async (tx): Promise<ClaimResult> => {
    const linkedRef = p.linkedPurchaseToken
      ? db.collection(PURCHASES).doc(androidLedgerId(p.linkedPurchaseToken))
      : undefined;
    const holderUserRef = holder && holder !== uid ? db.collection(USERS).doc(holder) : undefined;
    const refs = [rowRef, userRef, ...(linkedRef ? [linkedRef] : []), ...(holderUserRef ? [holderUserRef] : [])];
    const snaps = await tx.getAll(...refs);
    const [rowSnap, userSnap] = snaps;
    const linkedSnap = linkedRef ? snaps[2] : undefined;
    const holderUserSnap = holderUserRef ? snaps[refs.length - 1] : undefined;

    if (!userSnap.exists) throw new HttpsError("not-found", "User document not found.");
    const row = rowSnap.exists ? rowSnap.data() : undefined;
    if ((row?.uid as string | undefined) !== holder) {
      // Claimed by someone else between the lookup and now: let the app retry.
      throw new HttpsError("aborted", "The purchase changed hands; try again.");
    }

    const now = Date.now();
    const fields = withoutUndefined({
      platform: p.platform,
      productId: p.productId,
      kind: product.kind,
      state: p.state,
      expiresAt: p.expiresAt,
      test: p.test,
      environment: p.environment,
      transactionId: p.transactionId,
      originalTransactionId: p.originalTransactionId,
      purchaseToken: p.purchaseToken,
      orderId: p.orderId,
      linkedPurchaseToken: p.linkedPurchaseToken,
      accountId: p.accountId,
      updatedAt: now,
    });

    switch (product.kind) {
    case "consumable": {
      if (!row) {
        tx.set(rowRef, { ...fields, uid, ticketsGranted: product.tickets, createdAt: now });
        tx.update(userRef, { ticketCount: admin.firestore.FieldValue.increment(product.tickets) });
        return { status: "granted", granted: "tickets", amount: product.tickets };
      }
      if (row.uid === uid) {
        return { status: "already_granted", granted: "tickets", amount: Number(row.ticketsGranted ?? product.tickets) };
      }
      return refused("claimed_by_other_account");
    }

    case "non_consumable": {
      const unlock = { [product.unlockField]: true, scenarioPack1UnlockedAt: now };
      if (!row) {
        tx.set(rowRef, { ...fields, uid, createdAt: now });
        tx.update(userRef, unlock);
        return { status: "granted", granted: "scenario_pack" };
      }
      if (row.uid === uid) {
        tx.update(rowRef, fields);
        tx.update(userRef, unlock);
        return { status: "already_granted", granted: "scenario_pack" };
      }
      if (mayMove) {
        tx.update(rowRef, { ...fields, uid, movedFrom: row.uid });
        // The scenarios picked with the pack move with it: they are final, so
        // a restore must not offer a new choice.
        const picks = holderUserSnap?.exists ? holderUserSnap.get(PACK_PICKS_FIELD) : undefined;
        const hasOwnPicks = Array.isArray(userSnap.get(PACK_PICKS_FIELD)) && userSnap.get(PACK_PICKS_FIELD).length > 0;
        const carried = Array.isArray(picks) && picks.length > 0 && !hasOwnPicks
          ? { [PACK_PICKS_FIELD]: picks, [PACK_PICKED_AT_FIELD]: holderUserSnap!.get(PACK_PICKED_AT_FIELD) ?? now }
          : {};
        tx.update(userRef, { ...unlock, ...carried });
        if (holderUserSnap?.exists) tx.update(holderUserRef!, { [product.unlockField]: false });
        return { status: "granted", granted: "scenario_pack", moved: true };
      }
      return refused("claimed_by_other_account");
    }

    case "subscription": {
      let moved = false;
      if (!row) {
        tx.set(rowRef, { ...fields, uid, createdAt: now });
      } else if (row.uid === uid) {
        tx.update(rowRef, fields);
      } else if (mayMove) {
        tx.update(rowRef, { ...fields, uid, movedFrom: row.uid });
        moved = true;
      } else {
        return refused("claimed_by_other_account");
      }
      // Android plan change: the new purchase names the one it replaces.
      if (linkedSnap?.exists && linkedSnap.data()?.uid === uid) {
        tx.update(linkedRef!, { state: "replaced", updatedAt: now });
      }
      if (!live) return refused(p.state === "refunded" || p.state === "revoked" ? "refunded" : "expired");
      const wasLive = !!row && row.uid === uid && isLive(row, now);
      return { status: wasLive ? "already_granted" : "granted", granted: "subscription", moved };
    }
    }
  });

  if (product.kind === "subscription") {
    // The tier always comes from the ledger, so a plan change, a second store
    // or a move can't leave a wrong tier behind.
    result.tier = await recomputeEntitlement(uid);
    if (result.moved && holder) await recomputeEntitlement(holder);
  }
  return result;
}

/**
 * Sets subscriptionTier, isBossEnabled and subscriptionExpiresAt from the
 * user's ledger: the highest-ranked subscription that is active or in grace
 * and not past its end. Runs after every subscription claim, and later after
 * store notifications and the daily check.
 */
export async function recomputeEntitlement(uid: string): Promise<Tier | "free"> {
  const db = admin.firestore();
  const rows = await db.collection(PURCHASES)
    .where("uid", "==", uid)
    .where("kind", "==", "subscription")
    .get();
  const now = Date.now();
  let best: { tier: Tier; rank: number; expiresAt?: number } | undefined;
  for (const doc of rows.docs) {
    const r = doc.data();
    const product = productFor(String(r.productId));
    if (!product || product.kind !== "subscription" || !isLive(r, now)) continue;
    if (!best || product.rank > best.rank) {
      best = { tier: product.tier, rank: product.rank, expiresAt: r.expiresAt as number | undefined };
    }
  }
  const tier = best?.tier ?? "free";
  try {
    await db.collection(USERS).doc(uid).update({
      subscriptionTier: tier,
      // Boss battles are a Warlord (sub3000) perk.
      isBossEnabled: tier === "sub3000",
      subscriptionExpiresAt: best?.expiresAt ?? null,
      subscriptionUpdatedAt: now,
    });
  } catch (e) {
    // NOT_FOUND: the account was deleted. Nothing to update.
    if ((e as { code?: number }).code !== 5) throw e;
  }
  return tier;
}

function isLive(row: FirebaseFirestore.DocumentData, now: number): boolean {
  if (row.state !== "active" && row.state !== "grace") return false;
  return typeof row.expiresAt !== "number" || row.expiresAt > now;
}

/** True when the account is a guest (no sign-in method) or no longer exists. */
async function holderIsGone(uid: string): Promise<boolean> {
  try {
    const user = await admin.auth().getUser(uid);
    return user.providerData.length === 0;
  } catch (e) {
    if ((e as { code?: string }).code === "auth/user-not-found") return true;
    throw e;
  }
}

function withoutUndefined<T extends Record<string, unknown>>(o: T): Partial<T> {
  return Object.fromEntries(Object.entries(o).filter(([, v]) => v !== undefined)) as Partial<T>;
}
