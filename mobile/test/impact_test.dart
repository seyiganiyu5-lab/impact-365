import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/data/models.dart';
import 'package:impact365/features/impact/impact_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

Challenge challenge({bool done = false}) => Challenge(
  id: 'c1',
  date: DateTime.now(),
  title: 'Appelle quelqu\'un que tu n\'as pas vu depuis longtemps',
  description:
      'Prends 5 minutes pour lui dire que tu penses à lui et que tu pries '
      'pour lui.',
  verseText: 'Portez les fardeaux les uns des autres.',
  verseReference: 'Galates 6:2',
  completed: done,
);

ImpactData sample({Challenge? c}) => ImpactData(
  c,
  UserStats(
    streak: 4,
    challengesCompleted: 12,
    weekChallengeDays: const {1, 2, 4},
  ),
);

Widget impactApp(
  String lang,
  ImpactData data, {
  Future<void> Function(Challenge, String)? onComplete,
}) => MaterialApp(
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
  home: Scaffold(
    backgroundColor: AppColors.warmWhite,
    body: SafeArea(
      child: ImpactBody(data: data, onComplete: onComplete ?? (_, _) async {}),
    ),
  ),
);

void main() {
  setUpAll(() async {
    final inter = FontLoader('Inter');
    for (final w in ['Regular', 'Italic', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
    }
    await inter.load();
  });

  for (final lang in ['fr', 'en', 'yo']) {
    for (final (name, c) in [
      ('to do', challenge()),
      ('done', challenge(done: true)),
      ('none', null),
    ]) {
      testWidgets('Impact fits a small phone ($lang, $name)', (tester) async {
        tester.view.physicalSize = const Size(360, 1600) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(impactApp(lang, sample(c: c)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('shows the challenge, verse and counters', (tester) async {
    tester.view.physicalSize = const Size(393, 1600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(impactApp('fr', sample(c: challenge())));
    await tester.pumpAndSettle();
    expect(find.text('DÉFI DU JOUR'), findsOneWidget);
    expect(find.text('Galates 6:2'), findsOneWidget);
    expect(find.text('JE RELÈVE LE DÉFI'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3/7'), findsOneWidget);
  });

  testWidgets('completing: note, "C\'est fait !", then "Bravo !"', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 1600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    String? savedNote;
    await tester.pumpWidget(
      impactApp(
        'fr',
        sample(c: challenge()),
        onComplete: (_, note) async => savedNote = note,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('JE RELÈVE LE DÉFI'));
    await tester.pumpAndSettle();
    expect(find.text('Défi relevé ?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Mon ami était ravi');
    await tester.tap(find.text("C'EST FAIT !"));
    await tester.pumpAndSettle();
    expect(savedNote, 'Mon ami était ravi');
    expect(find.text('Bravo !'), findsOneWidget);
  });

  testWidgets('a completed challenge cannot be done twice', (tester) async {
    tester.view.physicalSize = const Size(393, 1600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(impactApp('fr', sample(c: challenge(done: true))));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('DÉFI RELEVÉ'), findsOneWidget);
  });
}
