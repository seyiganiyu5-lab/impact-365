import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/features/welcome/welcome_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

/// The welcome page must never overflow (the yellow/black stripe), on small
/// phones or while a keyboard is still closing after leaving the sign-in page.
void main() {
  for (final (name, size, keyboard) in [
    ('small phone', const Size(360, 640), 0.0),
    ('keyboard still open', const Size(393, 851), 300.0),
    ('small phone + keyboard', const Size(360, 640), 280.0),
  ]) {
    for (final lang in ['fr', 'en', 'yo']) {
      testWidgets('welcome fits: $name ($lang)', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(),
            locale: Locale(lang),
            supportedLocales: const [Locale('fr'), Locale('en'), Locale('yo')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              YoMaterialLocalizationsDelegate(),
              YoCupertinoLocalizationsDelegate(),
              YoWidgetsLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const WelcomeScreen(),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
