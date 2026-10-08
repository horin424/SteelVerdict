import * as fs from "fs";
import * as path from "path";
import {
  Environment,
  JWSTransactionDecodedPayload,
  SignedDataVerifier,
  VerificationException,
  VerificationStatus,
} from "@apple/app-store-server-library";
import { APPLE_APP_ID, APPLE_BUNDLE_ID } from "../utils/config";
import { StoreRefusal } from "./refusal";

/** The fields of a StoreKit 2 signed transaction that the server uses. */
export interface AppleTransaction {
  productId: string;
  transactionId: string;
  originalTransactionId: string;
  /** Subscriptions: end of the paid period, ms. */
  expiresDate?: number;
  /** Set when Apple refunded or revoked the transaction, ms. */
  revocationDate?: number;
  /** The account ID the app attached (purchaseAccountId). */
  appAccountToken?: string;
  /** "Production" or "Sandbox" (TestFlight and App Review use Sandbox). */
  environment: string;
}

/**
 * Apple's root certificates: public, from https://www.apple.com/certificateauthority/
 * (see certs/README.md). A signed transaction passes only if its certificate chain
 * ends in one of them.
 */
const CERTS_DIR = path.join(__dirname, "..", "..", "certs");

export interface Verifiers {
  /** Missing until APPLE_APP_ID is set: Apple requires it for Production. */
  production?: SignedDataVerifier;
  sandbox: SignedDataVerifier;
}

let verifiers: Verifiers | undefined;

/** Built on first use, because the params can only be read once the function runs. */
function getVerifiers(): Verifiers {
  if (verifiers) return verifiers;
  const roots = fs.readdirSync(CERTS_DIR)
    .filter((name) => name.endsWith(".cer"))
    .map((name) => fs.readFileSync(path.join(CERTS_DIR, name)));
  if (roots.length === 0) throw new Error(`No Apple root certificates in ${CERTS_DIR}.`);
  const bundleId = APPLE_BUNDLE_ID.value();
  const appAppleId = Number(APPLE_APP_ID.value()) || undefined;
  // true: also ask Apple whether a certificate in the chain was revoked (OCSP).
  verifiers = {
    production: appAppleId === undefined ?
      undefined :
      new SignedDataVerifier(roots, true, Environment.PRODUCTION, bundleId, appAppleId),
    sandbox: new SignedDataVerifier(roots, true, Environment.SANDBOX, bundleId),
  };
  return verifiers;
}

/**
 * Decodes the signed transaction (JWS) that StoreKit 2 gave the app, once Apple's
 * library has checked it: the certificate chain up to Apple's root, the signature,
 * the bundle ID and the environment. Production is tried first. TestFlight and App
 * Review buy in Sandbox, so a transaction for the other environment is checked again
 * there. The library checks the environment last, so that second check only happens
 * for a transaction whose signature is already good.
 *
 * Throws StoreRefusal("invalid_signature") for a transaction that fails the checks.
 * Anything that could be our own setup, or Apple being unreachable, throws a plain
 * Error instead, so the app keeps the purchase open and tries again: a refused
 * purchase is finished in the app, and a buyer must never lose one to a wrong
 * setting.
 */
export async function decodeAppleTransaction(jws: string): Promise<AppleTransaction> {
  return decodeWith(getVerifiers(), jws);
}

/** decodeAppleTransaction with the verifiers given; scripts/verify-apple.js passes its own. */
export async function decodeWith({ production, sandbox }: Verifiers, jws: string): Promise<AppleTransaction> {
  let t: JWSTransactionDecodedPayload;
  try {
    if (production === undefined) {
      t = await sandbox.verifyAndDecodeTransaction(jws);
    } else {
      try {
        t = await production.verifyAndDecodeTransaction(jws);
      } catch (err) {
        if (statusOf(err) !== VerificationStatus.INVALID_ENVIRONMENT) throw err;
        t = await sandbox.verifyAndDecodeTransaction(jws);
      }
    }
  } catch (err) {
    throw failure(err, production !== undefined);
  }
  if (!t.productId || !t.transactionId || !t.originalTransactionId) {
    throw new StoreRefusal("invalid_transaction");
  }
  return {
    productId: t.productId,
    transactionId: t.transactionId,
    originalTransactionId: t.originalTransactionId,
    expiresDate: t.expiresDate,
    revocationDate: t.revocationDate,
    appAccountToken: t.appAccountToken,
    environment: String(t.environment),
  };
}

function statusOf(err: unknown): VerificationStatus | undefined {
  return err instanceof VerificationException ? err.status : undefined;
}

/** What a failed check means for the purchase: refused, or try again later. */
function failure(err: unknown, productionChecked: boolean): Error {
  const status = statusOf(err);
  switch (status) {
  case undefined:
    return err instanceof Error ? err : new Error(String(err));
  case VerificationStatus.RETRYABLE_VERIFICATION_FAILURE:
    return new Error("Apple's certificate status check could not be reached.");
  case VerificationStatus.INVALID_APP_IDENTIFIER:
    // Signed by Apple, but for another bundle ID: most likely APPLE_BUNDLE_ID is wrong.
    console.error("Apple transaction for another bundle ID than APPLE_BUNDLE_ID; check the setting.");
    return new Error("The Apple transaction is for another app.");
  case VerificationStatus.INVALID_ENVIRONMENT:
    if (!productionChecked) {
      // Signed by Apple for Production, which can't be checked until APPLE_APP_ID is set.
      console.error("A Production purchase arrived, but APPLE_APP_ID is not set.");
      return new Error("Production purchases can't be checked yet.");
    }
    break;
  }
  console.warn(`Apple transaction refused: ${VerificationStatus[status]}`);
  return new StoreRefusal("invalid_signature");
}
