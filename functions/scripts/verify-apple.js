/**
 * Offline verification of A3 on iOS: validatePurchase accepts only transactions
 * that Apple signed.
 *
 * The app sends the signed transaction (JWS) that StoreKit 2 gave it.
 * appleVerifier.ts hands it to Apple's own library (SignedDataVerifier), which
 * checks the certificate chain up to Apple's root certificate in functions/certs.
 * This script makes a fake chain (root, intermediate and leaf, with the marker
 * extensions Apple's certificates carry) and signs transactions with it:
 *
 * - Against Apple's real root, every one of them is refused.
 * - Against verifiers that trust the fake root (online checks off), the same
 *   transactions pass. That shows they are otherwise well formed, so the refusals
 *   above come from the root check. These also test the rest of appleVerifier.ts:
 *   Production first and then Sandbox, the decoded fields, and which failures are
 *   refused and which leave the purchase open in the app to try again.
 *
 * No emulator, no credentials and no network: a chain that doesn't end in a
 * trusted root fails before Apple's revocation check is called.
 *
 * Run: npm run verify:apple
 */
process.env.APPLE_BUNDLE_ID = "app.steelverdict.game";
process.env.APPLE_APP_ID = "1234567890";

const rs = require("jsrsasign");
const { Environment, SignedDataVerifier } = require("@apple/app-store-server-library");
const { decodeAppleTransaction, decodeWith } = require("../lib/purchase/appleVerifier");
const { StoreRefusal } = require("../lib/purchase/refusal");

const BUNDLE = process.env.APPLE_BUNDLE_ID;
const ACCOUNT = "6c038dfe-22ce-5098-b65d-42d915deaa7a"; // purchaseAccountId("test-uid-123")

// appleVerifier.ts logs refusals and setup problems; keep them for the checks.
const logged = [];
console.warn = console.error = (message) => logged.push(String(message));

let fail = 0;

function check(name, actual, expected) {
  const ok = JSON.stringify(actual) === JSON.stringify(expected);
  if (ok) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

// ------------------------------------------------------------ the fake chain
function makeCert(subject, issuer, publicKey, signingKey, extensions) {
  return new rs.KJUR.asn1.x509.Certificate({
    version: 3,
    serial: { int: Math.floor(Math.random() * 1e9) },
    issuer: { str: issuer },
    subject: { str: subject },
    notbefore: "200101000000Z",
    notafter: "491231235959Z",
    sbjpubkey: publicKey,
    ext: extensions,
    sigalg: "SHA256withECDSA",
    cakey: signingKey,
  }).getEncodedHex();
}

const rootKey = rs.KEYUTIL.generateKeypair("EC", "secp256r1");
const interKey = rs.KEYUTIL.generateKeypair("EC", "secp256r1");
const leafKey = rs.KEYUTIL.generateKeypair("EC", "secp256r1");
const ROOT = "/C=US/O=Not Apple/CN=Fake Root CA";
const INTER = "/C=US/O=Not Apple/CN=Fake WWDR CA";
const CA = { extname: "basicConstraints", critical: true, cA: true };
const rootHex = makeCert(ROOT, ROOT, rootKey.pubKeyObj, rootKey.prvKeyObj, [CA]);
// The OIDs Apple's library looks for on its intermediate and leaf certificates.
const interHex = makeCert(INTER, ROOT, interKey.pubKeyObj, rootKey.prvKeyObj,
  [CA, { extname: "1.2.840.113635.100.6.2.1", extn: "0500" }]);
const leafHex = makeCert("/C=US/O=Not Apple/CN=Fake App Store Signing", INTER, leafKey.pubKeyObj,
  interKey.prvKeyObj, [{ extname: "1.2.840.113635.100.6.11.1", extn: "0500" }]);

/** A StoreKit 2 transaction signed by the fake leaf; `fields` override the defaults. */
function sign(fields) {
  const now = Date.now();
  const payload = {
    transactionId: "2000000000000001",
    originalTransactionId: "2000000000000001",
    bundleId: BUNDLE,
    productId: "strategy_game_tickets_30",
    purchaseDate: now,
    signedDate: now,
    environment: "Sandbox",
    type: "Consumable",
    quantity: 1,
    inAppOwnershipType: "PURCHASED",
    appAccountToken: ACCOUNT,
    ...fields,
  };
  const header = { alg: "ES256", x5c: [leafHex, interHex, rootHex].map((hex) => rs.hextob64(hex)) };
  return rs.KJUR.jws.JWS.sign("ES256", JSON.stringify(header), JSON.stringify(payload), leafKey.prvKeyObj);
}

/** Verifiers like appleVerifier.ts builds, but trusting the fake root, with no online checks. */
function trustingFakeRoot({ production }) {
  const roots = [Buffer.from(rootHex, "hex")];
  return {
    production: production ?
      new SignedDataVerifier(roots, false, Environment.PRODUCTION, BUNDLE, 1234567890) :
      undefined,
    sandbox: new SignedDataVerifier(roots, false, Environment.SANDBOX, BUNDLE),
  };
}

async function outcome(decoding) {
  try {
    const t = await decoding;
    return `accepted ${t.environment}`;
  } catch (err) {
    return err instanceof StoreRefusal ? `refused ${err.reason}` : "try again";
  }
}

(async () => {
  console.log("Against Apple's real root certificate (functions/certs)");
  check("not a signed transaction at all: refused",
    await outcome(decodeAppleTransaction("not-a-jws")), "refused invalid_signature");
  check("a well-formed transaction signed by a fake chain: refused",
    await outcome(decodeAppleTransaction(sign({}))), "refused invalid_signature");
  check("the same, claiming Production: refused",
    await outcome(decodeAppleTransaction(sign({ environment: "Production" }))), "refused invalid_signature");

  console.log("Against verifiers that trust the fake root (the control)");
  const both = trustingFakeRoot({ production: true });
  check("Sandbox (TestFlight, App Review): accepted after Production says no",
    await outcome(decodeWith(both, sign({}))), "accepted Sandbox");
  check("Production: accepted",
    await outcome(decodeWith(both, sign({ environment: "Production" }))), "accepted Production");

  const renewal = await decodeWith(both, sign({
    type: "Auto-Renewable Subscription",
    productId: "strategy_game_sub_1000_monthly",
    transactionId: "2000000000000009",
    originalTransactionId: "2000000000000002",
    expiresDate: 1893456000000,
  }));
  check("the decoded fields are the signed ones", renewal, {
    productId: "strategy_game_sub_1000_monthly",
    transactionId: "2000000000000009",
    originalTransactionId: "2000000000000002",
    expiresDate: 1893456000000,
    appAccountToken: ACCOUNT,
    environment: "Sandbox",
  });

  const [header, payload, signature] = sign({}).split(".");
  const upgraded = { ...JSON.parse(rs.b64utoutf8(payload)), productId: "strategy_game_sub_3000_monthly" };
  check("a signed transaction with its product changed: refused",
    await outcome(decodeWith(both, `${header}.${rs.utf8tob64u(JSON.stringify(upgraded))}.${signature}`)),
    "refused invalid_signature");
  check("an Xcode test transaction: refused",
    await outcome(decodeWith(both, sign({ environment: "Xcode" }))), "refused invalid_signature");

  console.log("Setup problems leave the purchase open (the app finishes refused purchases)");
  logged.length = 0;
  check("another bundle ID (most likely a wrong APPLE_BUNDLE_ID): try again",
    await outcome(decodeWith(both, sign({ bundleId: "com.example.other" }))), "try again");
  check("... and the log names APPLE_BUNDLE_ID", logged.some((m) => m.includes("APPLE_BUNDLE_ID")), true);
  const sandboxOnly = trustingFakeRoot({ production: false });
  logged.length = 0;
  check("Production while APPLE_APP_ID is not set: try again",
    await outcome(decodeWith(sandboxOnly, sign({ environment: "Production" }))), "try again");
  check("... and the log names APPLE_APP_ID", logged.some((m) => m.includes("APPLE_APP_ID")), true);
  check("Sandbox while APPLE_APP_ID is not set: accepted",
    await outcome(decodeWith(sandboxOnly, sign({}))), "accepted Sandbox");

  console.log(fail ? `\n${fail} check(s) FAILED\n` : "\nall checks passed\n");
  process.exit(fail ? 1 : 0);
})();
