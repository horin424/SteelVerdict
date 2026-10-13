import { auth } from "firebase-functions/v1";
import { createUserDoc, startingName } from "../utils/firestore";

/**
 * Auth trigger — runs when a new Firebase Auth user is created.
 * Creates the corresponding Firestore user document with starter tickets.
 * If this fails, ensureUserDoc creates it on the account's first call.
 */
export const onUserCreated = auth.user().onCreate(async (user) => {
  console.log(`Creating user doc for uid=${user.uid}`);
  await createUserDoc(user.uid, startingName(user));
});
