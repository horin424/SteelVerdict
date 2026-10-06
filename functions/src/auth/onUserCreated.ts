import { auth } from "firebase-functions/v1";
import { createUserDoc } from "../utils/firestore";

/**
 * Auth trigger — runs when a new Firebase Auth user is created.
 * Creates the corresponding Firestore user document with starter tickets.
 */
export const onUserCreated = auth.user().onCreate(async (user) => {
  // Guests get no name: the app shows its translated default (匿名司令官).
  const displayName = user.displayName || user.email?.split("@")[0] || "";
  console.log(`Creating user doc for uid=${user.uid}`);
  await createUserDoc(user.uid, displayName);
});
