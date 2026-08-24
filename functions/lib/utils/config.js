"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.EPIC_MAX_TOKENS = exports.REPORT_MAX_TOKENS = exports.CLAUDE_HAIKU = exports.GEMINI_FLASH = exports.GEMINI_FLASH_LITE = exports.TICKET_COSTS = exports.APPLE_SHARED_SECRET = exports.GOOGLE_PLAY_SERVICE_ACCOUNT = exports.CLAUDE_API_KEY = exports.GEMINI_API_KEY = void 0;
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
// Output budget for AI-written reports.
//
// The 2.5 models are thinking models: their reasoning tokens are drawn from the
// same maxOutputTokens allowance as the visible answer. The prompts ask for a
// report of 1000+ Japanese characters, which is roughly 1000-1500 tokens on its
// own, so a small ceiling leaves nothing for the report.
//
// These were 1024 / 2048. At 1024 the model spent nearly the whole budget
// thinking and returned two or three lines that stopped mid-sentence - before
// the trailing VICTORY / DEFEAT / STALEMATE keyword the prompts ask it to end
// on. parseOutcome then found no verdict and fell through to "draw", so battles
// the player had plainly won were scored as draws.
//
// Why this was not visible until recently: functions/lib is compiled output but
// is committed, and the tracked build had gone stale. Its callGemini took no
// maxTokens and set no generationConfig at all, so Gemini ran with the model's
// own (much larger) default. firebase.json rebuilds lib from src on every
// deploy, so the first deploy after that drift shipped the 1024 ceiling to
// production for the first time. The Claude path always passed it, so only
// Gemini changed behaviour - and Gemini is the default model.
//
// The ceiling is kept rather than removed, because an explicit bound is what the
// original author intended; it is simply raised to fit thinking plus the report.
// The proper fix is to stop thinking from competing with the answer at all
// (thinkingConfig.thinkingBudget), which @google/generative-ai 0.21 does not
// expose - it needs the newer @google/genai SDK.
exports.REPORT_MAX_TOKENS = 8192;
exports.EPIC_MAX_TOKENS = 16384;
//# sourceMappingURL=config.js.map