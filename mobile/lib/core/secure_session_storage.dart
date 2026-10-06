import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the Supabase login session in the phone's secure storage
/// (Android Keystore / iOS Keychain) instead of plain app preferences, so
/// the sign-in tokens are encrypted on the device and not copied into
/// phone backups.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({required String supabaseUrl})
    : _key = 'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  final String _key;

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      // Readable only on this device after the first unlock (needed so the
      // token can refresh in the background); never synced to iCloud.
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<void> initialize() async {
    // Move a session saved by an older version of the app (plain
    // preferences) into secure storage, so nobody is signed out.
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getString(_key);
    if (old != null) {
      if (await _storage.read(key: _key) == null) {
        await _storage.write(key: _key, value: old);
      }
      await prefs.remove(_key);
    }
  }

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
}
