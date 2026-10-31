import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/data/models.dart';
import 'package:impact365/features/prayer/add_prayer_sheet.dart';
import 'package:impact365/features/prayer/community_prayers_screen.dart';
import 'package:impact365/features/prayer/my_prayers_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

final _now = DateTime.now();

List<PrayerRequest> ongoing() => [
  PrayerRequest(
    id: 'p1',
    title: 'Un nouveau travail',
    details: 'Seigneur, ouvre-moi les bonnes portes cette année.',
    createdAt: _now,
    isShared: true,
  ),
  PrayerRequest(
    id: 'p2',
    title: 'La santé de ma mère',
    createdAt: _now.subtract(const Duration(days: 4)),
  ),
];

List<PrayerRequest> answered() => [
  PrayerRequest(
    id: 'p3',
    title: 'Réussir mon examen',
    details: 'Le concours d\'entrée.',
    isAnswered: true,
    testimony: 'J\'ai été admis ! Gloire à Dieu.',
    createdAt: _now.subtract(const Duration(days: 30)),
    answeredAt: _now.subtract(const Duration(days: 2)),
  ),
];

List<CommunityPrayer> community() => [
  CommunityPrayer(
    id: 'c1',
    title: 'Pour mon mariage',
    details: 'Que Dieu bénisse notre union.',
    authorName: 'Grace',
    intercessionCount: 4,
    createdAt: _now,
  ),
  CommunityPrayer(
    id: 'c2',
    title: 'Guérison',
    intercessionCount: 0,
    createdAt: _now.subtract(const Duration(days: 1)),
  ),
];

Widget app(String lang, Widget home) => MaterialApp(
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

Widget page(Widget body) => Scaffold(
  backgroundColor: AppColors.warmWhite,
  body: SafeArea(child: body),
);

Widget body({
  List<PrayerRequest>? on,
  List<PrayerRequest>? ans,
  int tab = 0,
  Future<bool> Function()? onAdd,
  Future<void> Function(String, String?)? onAnswered,
  Future<void> Function(String)? onDelete,
}) => page(
  MyPrayersBody(
    ongoing: on ?? ongoing(),
    answered: ans ?? answered(),
    initialTab: tab,
    onRefresh: () async {},
    onAdd: onAdd ?? () async => false,
    onAnswered: onAnswered ?? (_, _) async {},
    onDelete: onDelete ?? (_) async {},
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

  void small(WidgetTester tester, {double height = 740}) {
    tester.view.physicalSize = Size(360, height) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  for (final lang in ['fr', 'en', 'yo']) {
    final screens = <String, Widget Function()>{
      'ongoing': () => body(),
      'answered': () => body(tab: 1),
      'empty': () => body(on: const [], ans: const []),
      'answered empty': () => body(on: const [], ans: const [], tab: 1),
      'community': () => page(CommunityPrayersBody(prayers: community())),
      'community empty': () => page(const CommunityPrayersBody(prayers: [])),
      'add sheet': () => page(
        AddPrayerSheet(
          save:
              ({
                required title,
                details,
                required shared,
                required anonymous,
              }) async {},
        ),
      ),
    };
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('Mes prières $name fits a small phone ($lang)', (
        tester,
      ) async {
        small(tester);
        await tester.pumpWidget(app(lang, screen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('tabs show counts and switch', (tester) async {
    small(tester);
    await tester.pumpWidget(app('fr', body()));
    await tester.pumpAndSettle();
    expect(find.text('Un nouveau travail'), findsOneWidget);
    expect(find.text('Partagée'), findsOneWidget);
    expect(find.text('Privée'), findsOneWidget);
    await tester.tap(find.text('Exaucées'));
    await tester.pumpAndSettle();
    expect(find.text('Réussir mon examen'), findsOneWidget);
    expect(find.textContaining('Gloire à Dieu.'), findsOneWidget);
    expect(find.textContaining('Exaucée le'), findsOneWidget);
  });

  testWidgets('"Dieu a exaucé !" moves the prayer with the testimony', (
    tester,
  ) async {
    small(tester);
    String? done;
    await tester.pumpWidget(
      app('fr', body(onAnswered: (id, t) async => done = '$id:$t')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('✨ Dieu a exaucé !').first);
    await tester.pumpAndSettle();
    expect(find.text('Gloire à Dieu ! 🙌'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Embauché lundi !');
    await tester.tap(find.widgetWithText(FilledButton, '✨ Dieu a exaucé !'));
    await tester.pumpAndSettle();
    expect(done, 'p1:Embauché lundi !');
    // Now on the "Exaucées" tab, with the testimony.
    expect(find.text('Un nouveau travail'), findsOneWidget);
    expect(find.text('Embauché lundi !'), findsOneWidget);
    expect(find.text('Ajoutée à tes prières exaucées ✨'), findsOneWidget);
  });

  testWidgets('delete asks first, then removes', (tester) async {
    small(tester);
    String? deleted;
    await tester.pumpWidget(
      app('fr', body(onDelete: (id) async => deleted = id)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer ce sujet de prière ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(deleted, isNull);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(deleted, 'p2');
    expect(find.text('La santé de ma mère'), findsNothing);
  });

  testWidgets('add sheet: title required, then saves privacy choice', (
    tester,
  ) async {
    small(tester, height: 1200);
    Map<String, Object?>? saved;
    await tester.pumpWidget(
      app(
        'fr',
        page(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showAddPrayerSheet(
                  context,
                  save:
                      ({
                        required title,
                        details,
                        required shared,
                        required anonymous,
                      }) async {
                        saved = {
                          'title': title,
                          'details': details,
                          'shared': shared,
                          'anonymous': anonymous,
                        };
                      },
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Écris ton sujet de prière.'), findsOneWidget);
    expect(saved, isNull);

    await tester.enterText(find.byType(TextField).first, 'Ma famille');
    await tester.tap(find.text('La communauté'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rester anonyme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(saved, {
      'title': 'Ma famille',
      'details': null,
      'shared': true,
      'anonymous': true,
    });
    expect(find.text('Valider'), findsNothing);
  });

  testWidgets('community: "J\'ai prié" updates the count', (tester) async {
    small(tester);
    final calls = <String>[];
    await tester.pumpWidget(
      app(
        'fr',
        page(
          CommunityPrayersBody(
            prayers: community(),
            onToggle: (id, prayed) async => calls.add('$id:$prayed'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('4 personnes ont prié'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    await tester.tap(find.text("J'ai prié").first);
    await tester.pumpAndSettle();
    expect(calls, ['c1:true']);
    expect(find.text('5 personnes ont prié'), findsOneWidget);
  });
}
