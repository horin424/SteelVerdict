import { v5 as uuidv5 } from "uuid";

/**
 * Namespace of the purchase account IDs. Never change it: every purchase made
 * in the app carries an ID derived from it, and a different namespace would
 * make those purchases look like someone else's.
 */
export const PURCHASE_ACCOUNT_NAMESPACE = "980297ff-5601-45b9-9a30-ab6f00476788";

/**
 * The account ID the app attaches to every purchase: Apple's appAccountToken,
 * Google's obfuscatedExternalAccountId. A UUID v5 of the Firebase uid, so the
 * app and the server compute the same value and nothing has to be stored.
 * Apple accepts only a UUID here; Google takes up to 64 characters.
 *
 * Same value as lib/services/purchase/purchase_account_id.dart. Mind the
 * argument order, which differs: Node is v5(name, namespace), Dart is
 * Uuid().v5(namespace, name). Both sides pin "test-uid-123" to
 * 6c038dfe-22ce-5098-b65d-42d915deaa7a.
 */
export function purchaseAccountId(uid: string): string {
  return uuidv5(uid, PURCHASE_ACCOUNT_NAMESPACE);
}
