import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:impact365/core/locale_controller.dart';
import 'package:impact365/features/onboarding/onboarding_screen.dart';
import 'package:impact365/features/splash/splash_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, _) => const Text('HOME')),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
  // Let the splash animation finish.
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleController.init();
  });

  testWidgets('first launch: splash leads to onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpApp(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('after onboarding: splash goes straight to home', (tester) async {
    SharedPreferences.setMockInitialValues({OnboardingScreen.doneKey: true});
    await _pumpApp(tester);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });
}
