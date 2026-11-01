import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public pages on the website (no sign-in needed).
abstract final class LegalLinks {
  static const _site = 'https://admin.impact365jours.com';

  /// Privacy policy in the app language (French page, else English).
  static Uri privacy(String languageCode) => Uri.parse(
    '$_site/${languageCode == 'fr' ? 'confidentialite' : 'privacy'}',
  );

  /// How to delete an account (the app has the button itself).
  static Uri deleteAccount(String languageCode) => Uri.parse(
    '$_site/${languageCode == 'fr' ? 'suppression-compte' : 'delete-account'}',
  );
}

/// Opens [uri] in an in-app browser tab; false if it could not open.
Future<bool> openWebPage(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (e) {
    debugPrint('openWebPage: $e');
    return false;
  }
}
