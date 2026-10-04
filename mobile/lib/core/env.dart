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

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
