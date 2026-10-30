/// Supabase credentials are passed at build time so they never live in git:
///
///   flutter run --dart-define-from-file=env.json
///
/// See `env.example.json` at the root of the mobile project.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Shows the "Apple" sign-in button. Turn it on in env.json once Sign in
  /// with Apple is set up in Supabase (needs an Apple Developer account).
  static const appleSignIn = bool.fromEnvironment('ENABLE_APPLE_SIGN_IN');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
