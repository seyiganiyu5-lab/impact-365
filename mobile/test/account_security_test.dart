import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/features/profile/change_password_screen.dart';
import 'package:impact365/features/profile/profile_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

Widget _app(String lang, Widget home) => MaterialApp(
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
  home: home,
);

void main() {
  for (final lang in ['fr', 'en', 'yo']) {
    testWidgets('change password screen fits a small phone ($lang)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(lang, const ChangePasswordScreen(email: 'jean@exemple.com')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('jean@exemple.com'), findsOneWidget);
    });
  }

  testWidgets('delete needs the confirmation word', (tester) async {
    await tester.pumpWidget(
      _app(
        'fr',
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showDeleteAccountDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer ton compte ?'), findsOneWidget);

    FilledButton button() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Supprimer définitivement'),
    );
    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'supprim');
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'supprimer');
    await tester.pump();
    expect(button().onPressed, isNotNull);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer ton compte ?'), findsNothing);
  });
}
