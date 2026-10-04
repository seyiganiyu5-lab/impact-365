import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app language (fr / en / yo) and remembers the choice on device.
class LocaleController extends ChangeNotifier {
  LocaleController._(this._locale);

  static const supported = [Locale('fr'), Locale('en'), Locale('yo')];
  static const _key = 'app_locale';

  static late final LocaleController instance;

  Locale _locale;
  Locale get locale => _locale;

  /// Language code sent to Supabase to pick devotion translations.
  String get languageCode => _locale.languageCode;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    instance = LocaleController._(Locale(saved ?? 'fr'));
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  static String displayName(String code) => switch (code) {
    'fr' => 'Français',
    'en' => 'English',
    'yo' => 'Yorùbá',
    _ => code,
  };
}
