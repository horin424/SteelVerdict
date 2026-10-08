import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// The pages the shop and the account-deletion dialog link to (Apple 3.1.2:
/// Terms of Use and Privacy Policy next to subscriptions).
///
/// The drafts are in store_site/ (terms.html, privacy.html). They go online with
/// the live project's hosting deploy, which needs Yoshimoto's OK (release_scope
/// 03 §1, item 8). If they are hosted elsewhere, change [_site] only.
class LegalLinks {
  LegalLinks._();

  static const String _site = 'https://steelverdict-81c34.web.app';
  static const String termsOfUse = '$_site/terms.html';
  static const String privacyPolicy = '$_site/privacy.html';

  /// Must match android/app/build.gradle.kts applicationId.
  static const String _androidPackage = 'app.steelverdict.game';

  /// The store's own page for managing and cancelling subscriptions.
  static String get manageSubscriptions => !kIsWeb && Platform.isIOS
      ? 'https://apps.apple.com/account/subscriptions'
      : 'https://play.google.com/store/account/subscriptions?package=$_androidPackage';

  /// Opens [url] outside the app; false when it couldn't be opened.
  static Future<bool> open(String url) async {
    try {
      return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open $url: $e');
      return false;
    }
  }
}
