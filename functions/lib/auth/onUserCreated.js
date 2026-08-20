"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserCreated = void 0;
const v1_1 = require("firebase-functions/v1");
const firestore_1 = require("../utils/firestore");
/**
 * Auth trigger — runs when a new Firebase Auth user is created.
 * Creates the corresponding Firestore user document with starter tickets.
 */
exports.onUserCreated = v1_1.auth.user().onCreate(async (user) => {
    var _a;
    const displayName = user.displayName || ((_a = user.email) === null || _a === void 0 ? void 0 : _a.split("@")[0]) || "Anonymous Commander";
    console.log(`Creating user doc for uid=${user.uid}`);
    await (0, firestore_1.createUserDoc)(user.uid, displayName);
});
//# sourceMappingURL=onUserCreated.js.map