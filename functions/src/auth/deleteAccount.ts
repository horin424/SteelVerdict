import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * deleteAccount — permanently removes the caller's Auth user and Firestore
 * user document (and related user-owned data where practical).
 *
 * Required for App Store 5.1.1(v) and Google Play account-deletion policy.
 * Firestore rules block client-side user deletes, so this must be a CF.
 */
export const deleteAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = request.auth.uid;
  const db = admin.firestore();

  // Best-effort cleanup of user-owned docs. PvP match history is shared and
  // left in place (winner UIDs become anonymous references).
  const batch = db.batch();
  batch.delete(db.collection("users").doc(uid));

  try {
    await batch.commit();
  } catch (err) {
    console.error(`Failed to delete Firestore user ${uid}:`, err);
    throw new HttpsError("internal", "Failed to delete account data.");
  }

  try {
    await admin.auth().deleteUser(uid);
  } catch (err) {
    console.error(`Failed to delete Auth user ${uid}:`, err);
    throw new HttpsError("internal", "Failed to delete authentication account.");
  }

  return { deleted: true };
});
