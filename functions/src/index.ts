import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK (must be first)
admin.initializeApp();

// ─── Auth ─────────────────────────────────────────────────────────────────────
export { onUserCreated } from "./auth/onUserCreated";

// ─── Battle ───────────────────────────────────────────────────────────────────
export { submitBattle } from "./battle/submitBattle";
export { judgeCompletedPvpMatch } from "./battle/judgeCompletedPvpMatch";

// ─── Tickets ──────────────────────────────────────────────────────────────────
export { claimDailyReward, earnAdTickets } from "./tickets/claimDailyReward";
export { claimXShareReward } from "./tickets/claimXShareReward";
export { skipAd } from "./tickets/skipAd";

// ─── PvP ──────────────────────────────────────────────────────────────────────
export { findOrCreatePvpMatch } from "./pvp/findOrCreatePvpMatch";
export { checkDeserters } from "./pvp/checkDeserters";

// ─── War History ──────────────────────────────────────────────────────────────
export { generateWarHistory } from "./history/generateWarHistory";

// ─── Purchases ────────────────────────────────────────────────────────────────
export { validatePurchase } from "./purchase/validatePurchase";
