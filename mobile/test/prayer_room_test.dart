import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/data/models.dart';
import 'package:impact365/features/prayer/prayer_room_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

PrayerRoomData sample({bool withCommunity = true}) =>
    PrayerRoomData(UserStats(prayersOpen: 3, prayersAnswered: 2), [
      if (withCommunity) ...[
        CommunityPrayer(
          id: 'p1',
          title: 'Pour la guérison de ma mère',
          details: 'Elle est hospitalisée depuis une semaine, priez avec nous.',
          authorName: 'Jean',
          intercessionCount: 12,
          createdAt: DateTime.now(),
        ),
        CommunityPrayer(
          id: 'p2',
          title: 'Un nouvel emploi',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          iPrayed: true,
          intercessionCount: 4,
        ),
      ],
    ]);

Widget prayerApp(String lang, PrayerRoomData data) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          backgroundColor: AppColors.warmWhite,
          body: SafeArea(
            child: PrayerRoomBody(data: data, onChanged: () {}),
          ),
        ),
      ),
      for (final path in [
        '/prayers/mine',
        '/prayers/answered',
        '/prayers/community',
        '/journal',
        '/sos',
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
    final inter = FontLoader('Inter');
    for (final w in ['Regular', 'Italic', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
    }
    await inter.load();
  });

  for (final lang in ['fr', 'en', 'yo']) {
    for (final community in [true, false]) {
      testWidgets('Prière fits a small phone ($lang, community: $community)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 1600) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          prayerApp(lang, sample(withCommunity: community)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('shows counts and the community preview', (tester) async {
    tester.view.physicalSize = const Size(393, 1600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(prayerApp('fr', sample()));
    await tester.pumpAndSettle();
    expect(find.text('Ma Prayer Room'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Pour la guérison de ma mère'), findsOneWidget);
    expect(find.text('12 personnes ont prié'), findsOneWidget);
    expect(find.text('Anonyme'), findsOneWidget);
  });

  for (final (label, path) in [
    ('Mes prières', '/prayers/mine'),
    ('Voir tout', '/prayers/community'),
    ('Mon journal', '/journal'),
    ('Holy SOS', '/sos'),
  ]) {
    testWidgets('"$label" opens $path', (tester) async {
      tester.view.physicalSize = const Size(393, 1600) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(prayerApp('fr', sample()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text('PAGE $path'), findsOneWidget);
    });
  }
}
