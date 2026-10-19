// Firebase project: steelverdict-81c34
//
// The values match android/app/google-services.json and
// ios/Runner/GoogleService-Info.plist: the Firebase apps "Steel Verdict" for
// app.steelverdict.game, registered on 19 Oct 2026. To fetch them again:
//   firebase apps:sdkconfig ANDROID|IOS <app ID> --project steelverdict-81c34

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions.currentPlatform is not supported for Web. '
        'Configure a web FirebaseOptions value.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ─── Android ──────────────────────────────────────────────────────────────

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCXVA10ciTHyECr_8mqQ2Wriub_JzHUntQ',
    appId: '1:60492504266:android:27f02115994e40d162e833',
    messagingSenderId: '60492504266',
    projectId: 'steelverdict-81c34',
    storageBucket: 'steelverdict-81c34.firebasestorage.app',
  );

  // Get these values from: google-services.json (Firebase Console → Project Settings → Android app)

  // ─── iOS ──────────────────────────────────────────────────────────────────

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAtmGZdtqWyQXv12dRlDSi1z3jm5AjDsQk',
    appId: '1:60492504266:ios:8348c1edfc091e8b62e833',
    messagingSenderId: '60492504266',
    projectId: 'steelverdict-81c34',
    storageBucket: 'steelverdict-81c34.firebasestorage.app',
    iosBundleId: 'app.steelverdict.game',
  );

  // Get these values from: GoogleService-Info.plist (Firebase Console → Project Settings → iOS app)
}