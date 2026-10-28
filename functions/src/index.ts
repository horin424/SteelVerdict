import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK (must be first)
admin.initializeApp();

// ─── Auth ─────────────────────────────────────────────────────────────────────
export { onUserCreated } from "./auth/onUserCreated";
export { deleteAccount } from "./auth/deleteAccount";

// ─── Battle ───────────────────────────────────────────────────────────────────
export { submitBattle } from "./battle/submitBattle";
export { judgeCompletedPvpMatch } from "./battle/judgeCompletedPvpMatch";

// ─── Tickets ──────────────────────────────────────────────────────────────────
export { claimDailyReward, earnAdTickets } from "./tickets/claimDailyReward";
export { claimXShareReward } from "./tickets/claimXShareReward";
export { skipAd } from "./tickets/skipAd";

// ─── PvP ──────────────────────────────────────────────────────────────────────
export { findOrCreatePvpMatch } from "./pvp/findOrCreatePvpMatch";
export { submitPvpStrategy } from "./pvp/submitPvpStrategy";
// Deployed as checkDesertersHourly: since the project was deleted and restored (Sept 2026), Cloud
// Scheduler holds a job under the old name that it can neither show nor replace (get says 404,
// create says 409), so a function named checkDeserters can't be given its schedule.
export { checkDeserters as checkDesertersHourly } from "./pvp/checkDeserters";

// ─── War History ──────────────────────────────────────────────────────────────
export { generateWarHistory } from "./history/generateWarHistory";

// ─── Purchases ────────────────────────────────────────────────────────────────
export { validatePurchase } from "./purchase/validatePurchase";
export { chooseScenarioPack } from "./purchase/scenarioPack";
