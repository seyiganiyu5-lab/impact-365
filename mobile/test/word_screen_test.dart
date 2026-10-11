import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/data/models.dart';
import 'package:impact365/features/devotion/word_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

Devotion devotion(String id, DevotionSlot slot, {int daysAgo = 0}) => Devotion(
  id: id,
  date: DateTime.now().subtract(Duration(days: daysAgo)),
  slot: slot,
  verseReference: 'Psaume 23:1',
  verseText: "L'Éternel est mon berger",
  godSays: '',
  iUnderstand: '',
  iDo: '',
);

/// Morning published, midday not yet, plus one older devotion.
List<Devotion> sample() => [
  devotion('m', DevotionSlot.morning),
  devotion('n', DevotionSlot.night),
  devotion('old', DevotionSlot.morning, daysAgo: 1),
];

Widget wordApp(String lang, List<Devotion> data) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          backgroundColor: AppColors.warmWhite,
          body: SafeArea(
            child: WordBody(devotions: data, onReturn: () {}),
          ),
        ),
      ),
      GoRoute(
        path: '/word/devotion/:id',
        builder: (_, s) => Text('DEVOTION ${s.pathParameters['id']}'),
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
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
    }
    await inter.load();
  });

  for (final lang in ['fr', 'en', 'yo']) {
    testWidgets('Parole fits a small phone ($lang)', (tester) async {
      tester.view.physicalSize = const Size(360, 640) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wordApp(lang, sample()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows the three moments from the design', (tester) async {
    await tester.pumpWidget(wordApp('fr', sample()));
    await tester.pumpAndSettle();
    expect(find.text('La Parole'), findsOneWidget);
    for (final t in [
      'Matin',
      'Midi',
      'Soir',
      'Pain quotidien pour un jour nouveau',
      'La pause auprès des eaux paisibles',
      'Méditations pour une nuit paisible',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('published moment opens its devotion', (tester) async {
    await tester.pumpWidget(wordApp('fr', sample()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matin'));
    await tester.pumpAndSettle();
    expect(find.text('DEVOTION m'), findsOneWidget);
  });

  testWidgets('moment not published yet explains why', (tester) async {
    await tester.pumpWidget(wordApp('fr', sample()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Midi'));
    await tester.pump();
    expect(find.textContaining("pas encore disponible"), findsOneWidget);
  });

  testWidgets('previous days open from the history link', (tester) async {
    await tester.pumpWidget(wordApp('fr', sample()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jours précédents'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('DEVOTION old'), findsOneWidget);
  });
}
