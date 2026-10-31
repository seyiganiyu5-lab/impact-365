import 'package:shared_preferences/shared_preferences.dart';

/// Links used in Supabase emails so they open the app directly.
///
/// These must also be added in Supabase → Authentication → URL Configuration
/// → Redirect URLs (add `impact365://**`). The `impact365` scheme is
/// registered in AndroidManifest.xml and ios/Runner/Info.plist.
class AuthLinks {
  static const scheme = 'impact365';

  /// Opened from the "confirm your email" message after sign-up.
  static const emailConfirmed = 'impact365://login-callback';

  /// Opened from the "reset your password" message.
  static const resetPassword = 'impact365://reset-password';
}

/// App-wide auth state that the router needs but Supabase does not keep.
class AuthFlow {
  /// True after the user opened a password-reset link: we must show the
  /// "choose a new password" screen before anything else.
  static bool recoveryPending = false;

  // ------------------------------------------------- Google / Apple sign-in
  //
  // While the person is on Google's or Apple's page, Android may close the
  // app in the background and restart it when they come back. We write down
  // that a sign-in is in progress, so the restarted app opens on
  // "Connexion en cours…" instead of flashing the welcome / sign-in page.

  static const _oauthKey = 'oauth_started_at';
  static DateTime? _oauthStartedAt;

  /// True when this run of the app opened the provider page itself (as
  /// opposed to being restarted by Android on the way back).
  static bool oauthOpenedThisRun = false;

  /// A Google / Apple sign-in was started less than 5 minutes ago and has
  /// not finished yet.
  static bool get oauthPending {
    final started = _oauthStartedAt;
    return started != null &&
        DateTime.now().difference(started) < const Duration(minutes: 5);
  }

  /// Call once at startup, before the router runs.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_oauthKey);
      _oauthStartedAt = ms == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      _oauthStartedAt = null;
    }
  }

  static Future<void> startOAuth() async {
    _oauthStartedAt = DateTime.now();
    oauthOpenedThisRun = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_oauthKey, _oauthStartedAt!.millisecondsSinceEpoch);
    } catch (_) {}
  }

  static Future<void> clearOAuth() async {
    _oauthStartedAt = null;
    oauthOpenedThisRun = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_oauthKey);
    } catch (_) {}
  }
}
