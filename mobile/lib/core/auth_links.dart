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
}
