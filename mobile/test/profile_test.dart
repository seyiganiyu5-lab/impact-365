import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:impact365/core/locale_controller.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/data/models.dart';
import 'package:impact365/features/profile/profile_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProfileData sample({String role = 'member'}) => ProfileData(
  Profile(id: 'u1', fullName: 'Jean-Baptiste Adéyẹmí', role: role),
  UserStats(
    streak: 6,
    devotionsCompleted: 42,
    challengesCompleted: 12,
    prayersAnswered: 3,
    daysSinceJoin: 182,
  ),
  email: 'jean.baptiste.adeyemi@exemple.com',
);

Widget profileApp(
  String lang,
  ProfileData data, {
  Future<void> Function()? onSignOut,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          backgroundColor: AppColors.warmWhite,
          body: SafeArea(
            child: ProfileBody(
              data: data,
              onChanged: () {},
              onSignOut: onSignOut ?? () async {},
            ),
          ),
        ),
      ),
      for (final path in [
        '/profile/edit',
        '/profile/password',
        '/profile/language',
        '/inbox',
        '/sos',
        '/onboarding',
      ])
        GoRoute(path: path, builder: (_, _) => Text('PAGE $path')),
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
    SharedPreferences.setMockInitialValues({});
    await LocaleController.init();
    final inter = FontLoader('Inter');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
    }
    await inter.load();
  });

  for (final lang in ['fr', 'en', 'yo']) {
    for (final role in ['member', 'pastor']) {
      testWidgets('Profil fits a small phone ($lang, $role)', (tester) async {
        tester.view.physicalSize = const Size(360, 1700) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(profileApp(lang, sample(role: role)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('identity, initials, role and counters', (tester) async {
    tester.view.physicalSize = const Size(393, 1700) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(profileApp('fr', sample(role: 'pastor')));
    await tester.pumpAndSettle();
    expect(find.text('Jean-Baptiste Adéyẹmí'), findsOneWidget);
    expect(find.text('JA'), findsOneWidget);
    expect(find.text('Pasteur'), findsOneWidget);
    expect(find.text('Impacteur depuis 182 jours'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('IMPACT-365 · version 1.0.0'), findsOneWidget);
  });

  for (final (label, path) in [
    ('Informations personnelles', '/profile/edit'),
    ('Mot de passe', '/profile/password'),
    ('Langue', '/profile/language'),
    ('Messages & Notifications', '/inbox'),
    ('Holy SOS', '/sos'),
  ]) {
    testWidgets('"$label" opens $path', (tester) async {
      tester.view.physicalSize = const Size(393, 1700) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(profileApp('fr', sample()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text('PAGE $path'), findsOneWidget);
    });
  }

  testWidgets('sign out asks for confirmation first', (tester) async {
    tester.view.physicalSize = const Size(393, 1700) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    var signedOut = 0;
    await tester.pumpWidget(
      profileApp('fr', sample(), onSignOut: () async => signedOut++),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Te déconnecter ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(signedOut, 0);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Se déconnecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Se déconnecter'));
    await tester.pumpAndSettle();
    expect(signedOut, 1);
  });
}
