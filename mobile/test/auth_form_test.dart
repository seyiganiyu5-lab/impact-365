import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/features/auth/auth_screen.dart';
import 'package:impact365/features/auth/reset_password_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
  theme: buildTheme(),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);

void main() {
  testWidgets('sign-in shows required errors and stays put', (tester) async {
    await tester.pumpWidget(_app(const AuthScreen()));
    expect(find.text('Content de te revoir'), findsOneWidget);
    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(find.text('Ce champ est obligatoire'), findsNWidgets(2));
  });

  testWidgets('sign-up validates email, length and matching passwords', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const AuthScreen(signUp: true)));
    expect(find.text('Crée ton compte'), findsOneWidget);
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));
    await tester.enterText(fields.at(0), 'Jean Dupont');
    await tester.enterText(fields.at(1), 'jean@');
    await tester.enterText(fields.at(2), '123');
    await tester.enterText(fields.at(3), '456');
    await tester.ensureVisible(find.text('Créer mon compte'));
    await tester.tap(find.text('Créer mon compte'));
    await tester.pump();
    expect(find.text('Entre une adresse e-mail valide'), findsOneWidget);
    expect(find.text('Au moins 6 caractères'), findsWidgets);
    expect(find.text('Les mots de passe ne correspondent pas'), findsOneWidget);
  });

  testWidgets('switches between sign-in and sign-up', (tester) async {
    await tester.pumpWidget(_app(const AuthScreen()));
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.ensureVisible(
      find.textContaining('Créer un compte', findRichText: true),
    );
    await tester.tapOnText(find.textRange.ofSubstring('Créer un compte'));
    await tester.pumpAndSettle();
    expect(find.text('Crée ton compte'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('footer is one centred sentence, even on narrow phones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const AuthScreen()));
    final footer = find.textContaining(
      'Pas encore de compte ?',
      findRichText: true,
    );
    expect(footer, findsOneWidget);
    final rect = tester.getRect(footer);
    // Spans the content width (24 px side padding) so text is centred.
    expect(rect.left, 24);
    expect(rect.right, 320 - 24);
  });

  testWidgets('new-password screen validates before saving', (tester) async {
    await tester.pumpWidget(_app(const ResetPasswordScreen()));
    expect(find.text('Nouveau mot de passe'), findsWidgets);
    await tester.tap(find.text('Enregistrer mon mot de passe'));
    await tester.pump();
    expect(find.text('Ce champ est obligatoire'), findsNWidgets(2));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'abcdef');
    await tester.enterText(fields.at(1), 'abcdeg');
    await tester.tap(find.text('Enregistrer mon mot de passe'));
    await tester.pump();
    expect(find.text('Les mots de passe ne correspondent pas'), findsOneWidget);
  });
}
