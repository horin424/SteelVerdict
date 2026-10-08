import 'package:uuid/uuid.dart';

/// Namespace of the purchase account IDs. Never change it: every purchase made
/// in the app carries an ID derived from it, and a different namespace would
/// make those purchases look like someone else's.
const String purchaseAccountNamespace = '980297ff-5601-45b9-9a30-ab6f00476788';

/// The account ID attached to every purchase: Apple's appAccountToken, Google's
/// obfuscatedExternalAccountId. The server checks that it is the caller's, so a
/// purchase can't be claimed by another account.
///
/// A UUID v5 of the Firebase uid, so the app and the server compute the same
/// value and nothing has to be stored. Apple accepts only a UUID here.
///
/// Same value as functions/src/purchase/accountId.ts. Mind the argument order,
/// which differs: Dart is Uuid().v5(namespace, name), Node is v5(name,
/// namespace). Both sides pin "test-uid-123" to
/// 6c038dfe-22ce-5098-b65d-42d915deaa7a.
String purchaseAccountId(String uid) =>
    const Uuid().v5(purchaseAccountNamespace, uid);
