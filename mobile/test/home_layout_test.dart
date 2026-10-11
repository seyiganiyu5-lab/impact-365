import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/data/models.dart';
import 'package:impact365/features/home/home_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

HomeData sampleHome({bool withDevotion = true, bool completed = false}) =>
    HomeData(
      Profile(id: 'u1', fullName: 'Jean Dupont'),
      UserStats(
        streak: 6,
        daysSinceJoin: 182,
        weekActivity: const [1, 2, 1, 3, 2, 2, 4],
      ),
      [
        if (withDevotion)
          Devotion(
            id: 'd1',
            date: DateTime.now(),
            slot: DevotionSlot.current(),
            verseReference: 'Matthieu 6:33',
            verseText: 'Cherchez premièrement le royaume…',
            godSays: '',
            iUnderstand: '',
            iDo: '',
            completed: completed,
          ),
      ],
      {},
    );

Widget homeApp(String lang, HomeData data) => MaterialApp(
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
    backgroundColor: AppColors.deepPurple,
    body: SafeArea(
      child: HomeBody(data: data, onReturn: () {}),
    ),
  ),
);

/// The home page must not overflow in any language, on a small phone or
/// with the longest button label ("relire" once the devotion is done).
Future<void> _loadFonts() async {
  final inter = FontLoader('Inter');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
  }
  await inter.load();
}

void main() {
  setUpAll(_loadFonts);
  for (final lang in ['fr', 'en', 'yo']) {
    for (final (name, data) in [
      ('devotion to start', sampleHome()),
      ('devotion done', sampleHome(completed: true)),
      ('no devotion yet', sampleHome(withDevotion: false)),
    ]) {
      testWidgets('home fits a small phone: $name ($lang)', (tester) async {
        // Tall enough that every card is built (lazy list), but small-phone
        // width.
        tester.view.physicalSize = const Size(360, 1400) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(homeApp(lang, data));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        // Scroll to the bottom: the "Aujourd'hui" cards must fit too.
        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('streak chip opens the explanation', (tester) async {
    await tester.pumpWidget(homeApp('fr', sampleHome()));
    await tester.tap(find.text('6'));
    await tester.pumpAndSettle();
    expect(find.text('6 jours d\'affilée'), findsOneWidget);
  });

  testWidgets('week ring and journey day come from the stats', (tester) async {
    tester.view.physicalSize = const Size(393, 1400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(homeApp('fr', sampleHome()));
    expect(find.text('7/7'), findsOneWidget);
    expect(find.text('Jour 182 / 365'), findsOneWidget);
  });
}
