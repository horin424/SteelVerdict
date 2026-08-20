"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CLAUDE_HAIKU = exports.GEMINI_FLASH = exports.GEMINI_FLASH_LITE = exports.TICKET_COSTS = exports.APPLE_SHARED_SECRET = exports.GOOGLE_PLAY_SERVICE_ACCOUNT = exports.CLAUDE_API_KEY = exports.GEMINI_API_KEY = void 0;
const params_1 = require("firebase-functions/params");
// Store API keys as Firebase Secrets (never in code)
// Set via: firebase functions:secrets:set GEMINI_API_KEY
exports.GEMINI_API_KEY = (0, params_1.defineSecret)("GEMINI_API_KEY");
exports.CLAUDE_API_KEY = (0, params_1.defineSecret)("CLAUDE_API_KEY");
// Google Play / Apple shared secret for receipt validation
exports.GOOGLE_PLAY_SERVICE_ACCOUNT = (0, params_1.defineSecret)("GOOGLE_PLAY_SERVICE_ACCOUNT");
exports.APPLE_SHARED_SECRET = (0, params_1.defineSecret)("APPLE_SHARED_SECRET");
// Ticket costs per model (can be overridden via Remote Config on client)
exports.TICKET_COSTS = {
    gemini: 1,
    claude: 3,
    practice: 0,
    tabletop: 0, // ad covers it; skip costs 1 — handled client-side
    pvp: 1, // fixed Gemini Flash for fairness
};
// Model IDs
exports.GEMINI_FLASH_LITE = "gemini-2.5-flash-lite";
exports.GEMINI_FLASH = "gemini-2.5-flash";
exports.CLAUDE_HAIKU = "claude-haiku-4-5-20251001";
//# sourceMappingURL=config.js.map