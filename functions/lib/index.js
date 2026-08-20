"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.validatePurchase = exports.generateWarHistory = exports.checkDeserters = exports.findOrCreatePvpMatch = exports.skipAd = exports.claimXShareReward = exports.earnAdTickets = exports.claimDailyReward = exports.judgeCompletedPvpMatch = exports.submitBattle = exports.onUserCreated = void 0;
const admin = __importStar(require("firebase-admin"));
// Initialize Firebase Admin SDK (must be first)
admin.initializeApp();
// ─── Auth ─────────────────────────────────────────────────────────────────────
var onUserCreated_1 = require("./auth/onUserCreated");
Object.defineProperty(exports, "onUserCreated", { enumerable: true, get: function () { return onUserCreated_1.onUserCreated; } });
// ─── Battle ───────────────────────────────────────────────────────────────────
var submitBattle_1 = require("./battle/submitBattle");
Object.defineProperty(exports, "submitBattle", { enumerable: true, get: function () { return submitBattle_1.submitBattle; } });
var judgeCompletedPvpMatch_1 = require("./battle/judgeCompletedPvpMatch");
Object.defineProperty(exports, "judgeCompletedPvpMatch", { enumerable: true, get: function () { return judgeCompletedPvpMatch_1.judgeCompletedPvpMatch; } });
// ─── Tickets ──────────────────────────────────────────────────────────────────
var claimDailyReward_1 = require("./tickets/claimDailyReward");
Object.defineProperty(exports, "claimDailyReward", { enumerable: true, get: function () { return claimDailyReward_1.claimDailyReward; } });
Object.defineProperty(exports, "earnAdTickets", { enumerable: true, get: function () { return claimDailyReward_1.earnAdTickets; } });
var claimXShareReward_1 = require("./tickets/claimXShareReward");
Object.defineProperty(exports, "claimXShareReward", { enumerable: true, get: function () { return claimXShareReward_1.claimXShareReward; } });
var skipAd_1 = require("./tickets/skipAd");
Object.defineProperty(exports, "skipAd", { enumerable: true, get: function () { return skipAd_1.skipAd; } });
// ─── PvP ──────────────────────────────────────────────────────────────────────
var findOrCreatePvpMatch_1 = require("./pvp/findOrCreatePvpMatch");
Object.defineProperty(exports, "findOrCreatePvpMatch", { enumerable: true, get: function () { return findOrCreatePvpMatch_1.findOrCreatePvpMatch; } });
var checkDeserters_1 = require("./pvp/checkDeserters");
Object.defineProperty(exports, "checkDeserters", { enumerable: true, get: function () { return checkDeserters_1.checkDeserters; } });
// ─── War History ──────────────────────────────────────────────────────────────
var generateWarHistory_1 = require("./history/generateWarHistory");
Object.defineProperty(exports, "generateWarHistory", { enumerable: true, get: function () { return generateWarHistory_1.generateWarHistory; } });
// ─── Purchases ────────────────────────────────────────────────────────────────
var validatePurchase_1 = require("./purchase/validatePurchase");
Object.defineProperty(exports, "validatePurchase", { enumerable: true, get: function () { return validatePurchase_1.validatePurchase; } });
//# sourceMappingURL=index.js.map