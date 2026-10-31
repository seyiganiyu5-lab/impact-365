import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/data/models.dart';
import 'package:impact365/features/profile/edit_profile_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

Profile profile({String role = 'member'}) => Profile(
  id: 'u1',
  fullName: 'Grace Adébáyọ̀',
  phone: '+229 01 97 00 00 00',
  role: role,
  createdAt: DateTime(2026, 9, 14),
);

typedef Save =
    Future<void> Function({required String fullName, required String phone});

Widget view({
  String provider = 'email',
  String role = 'member',
  Save? onSave,
}) => Scaffold(
  backgroundColor: AppColors.warmWhite,
  body: PersonalInfoView(
    profile: profile(role: role),
    email: 'grace@example.com',
    provider: provider,
    onSave: onSave ?? ({required fullName, required phone}) async {},
  ),
);

Widget app(String lang, Widget home, {String initial = '/'}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/prev',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/'),
            child: const Text('OPEN'),
          ),
        ),
      ),
      GoRoute(
        path: '/profile/password',
        builder: (_, _) => const Text('PAGE password'),
      ),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
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
  );
}

void main() {
  setUpAll(() async {
    final inter = FontLoader('Inter');
    for (final w in ['Regular', 'Italic', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
    }
    await inter.load();
  });

  void small(WidgetTester tester, {double height = 740}) {
    tester.view.physicalSize = Size(360, height) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  test('phone check', () {
    expect(isValidPhone(''), isTrue);
    expect(isValidPhone('+229 01 97 00 00 00'), isTrue);
    expect(isValidPhone('(06) 12-34.56.78'), isTrue);
    expect(isValidPhone('12345'), isFalse);
    expect(isValidPhone('+33 abc'), isFalse);
    expect(isValidPhone('1234567890123456'), isFalse);
  });

  for (final lang in ['fr', 'en', 'yo']) {
    for (final (provider, role) in [
      ('email', 'member'),
      ('google', 'pastor'),
    ]) {
      testWidgets('Personal info fits a small phone ($lang, $provider)', (
        tester,
      ) async {
        small(tester);
        await tester.pumpWidget(
          app(lang, view(provider: provider, role: role)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('shows sign-in details; password only for email', (tester) async {
    small(tester, height: 1200);
    await tester.pumpWidget(app('fr', view()));
    await tester.pumpAndSettle();
    expect(find.text('grace@example.com'), findsOneWidget);
    expect(find.text('E-mail et mot de passe'), findsOneWidget);
    expect(find.text('Membre'), findsNothing);
    expect(find.textContaining('Membre depuis'), findsOneWidget);
    await tester.tap(find.text('Mot de passe'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE password'), findsOneWidget);

    await tester.pumpWidget(
      app('fr', view(provider: 'google', role: 'pastor')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Pasteur'), findsOneWidget);
    expect(find.text('Mot de passe'), findsNothing);
  });

  testWidgets('save: off until a change, checks fields, then saves', (
    tester,
  ) async {
    small(tester, height: 1200);
    String? saved;
    await tester.pumpWidget(
      app(
        'fr',
        view(
          onSave: ({required fullName, required phone}) async =>
              saved = '$fullName|$phone',
        ),
      ),
    );
    await tester.pumpAndSettle();
    FilledButton button() => tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Enregistrer'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(button().onPressed, isNull);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '  ');
    await tester.enterText(fields.at(1), '12');
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Indique ton nom.'), findsOneWidget);
    expect(find.text('Ce numéro ne semble pas valide.'), findsOneWidget);
    expect(saved, isNull);

    await tester.enterText(fields.at(0), 'Grace A.');
    await tester.enterText(fields.at(1), '');
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(saved, 'Grace A.|');
    expect(find.text('Profil mis à jour'), findsOneWidget);
    // Header follows the new name; nothing left to save.
    expect(find.text('Grace A.'), findsWidgets);
    expect(button().onPressed, isNull);
  });

  testWidgets('asks before leaving with unsaved changes', (tester) async {
    small(tester);
    await tester.pumpWidget(app('fr', view(), initial: '/prev'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Autre nom');
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Quitter sans enregistrer ?'), findsOneWidget);
    await tester.tap(find.text('Quitter'));
    await tester.pumpAndSettle();
    expect(find.text('OPEN'), findsOneWidget);
  });
}
