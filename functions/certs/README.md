# Apple root certificate

`validatePurchase` accepts an iOS purchase only if its signed transaction chains up to a
certificate in this folder (`src/purchase/appleVerifier.ts`, with Apple's
`SignedDataVerifier`). Every `.cer` file here is trusted, so add nothing else.

| File | Source | Subject | Valid until | SHA-256 |
|---|---|---|---|---|
| `AppleRootCA-G3.cer` | https://www.apple.com/certificateauthority/AppleRootCA-G3.cer | Apple Root CA - G3 | 30 Apr 2039 | `63343ABFB89A6A03EBB57E9B3F5FA7BE7C4F5C756F3017B3A8C488C3653E9179` |

StoreKit 2 transactions and App Store Server Notifications are signed by Apple Worldwide
Developer Relations CA G6, which chains to this root. Downloaded on 8 Oct 2026.
