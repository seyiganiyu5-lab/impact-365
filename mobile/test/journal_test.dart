import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/data/models.dart';
import 'package:impact365/features/journal/journal_entry_screen.dart';
import 'package:impact365/features/journal/journal_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

final today = DateTime(2026, 10, 31); // a Saturday

List<JournalEntry> entries() => [
  JournalEntry(
    date: today,
    godShows: 'Dieu me rappelle que je ne suis pas seul.',
    gratitude: 'Ma famille\nMa santé',
  ),
  JournalEntry(
    date: DateTime(2026, 10, 30),
    godShows: 'Être patient avec mes collègues.',
    mustChange: 'Moins me plaindre.',
    prayFor: 'Maman, Paul',
    gratitude: 'Le travail',
  ),
  JournalEntry(date: DateTime(2026, 10, 27), prayFor: 'Les malades'),
];

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

Widget page(Widget body) => Scaffold(
  backgroundColor: AppColors.warmWhite,
  body: SafeArea(child: body),
);

Widget home({List<JournalEntry>? list, ValueChanged<DateTime>? onOpen}) => page(
  JournalHomeBody(
    entries: list ?? entries(),
    onOpen: onOpen ?? (_) {},
    today: today,
  ),
);

Widget editor({
  JournalEntry? initial,
  Future<void> Function(JournalEntry)? onSave,
}) => JournalEntryView(
  day: DateTime(2026, 10, 30),
  initial: initial ?? JournalEntry(),
  onSave: onSave ?? (_) async {},
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

  test('streak counts days in a row up to today or yesterday', () {
    expect(journalStreak([today, DateTime(2026, 10, 30)], today: today), 2);
    expect(journalStreak([DateTime(2026, 10, 30)], today: today), 1);
    expect(journalStreak([DateTime(2026, 10, 29)], today: today), 0);
    expect(journalStreak([], today: today), 0);
  });

  test('gratitude text splits into 3 lines', () {
    expect(splitThanks(''), ['', '', '']);
    expect(splitThanks('A\n\nB'), ['A', 'B', '']);
    expect(splitThanks('A\nB\nC\nD'), ['A', 'B', 'C D']);
  });

  for (final lang in ['fr', 'en', 'yo']) {
    final screens = <String, Widget Function()>{
      'home': () => home(),
      'home empty': () => home(list: const []),
      'editor empty': () => editor(),
      'editor filled': () => editor(initial: entries()[1]),
    };
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('Journal $name fits a small phone ($lang)', (tester) async {
        small(tester);
        await tester.pumpWidget(app(lang, screen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('home: today card, streak, week and pages open', (tester) async {
    small(tester, height: 1600);
    final opened = <DateTime>[];
    await tester.pumpWidget(app('fr', home(onOpen: opened.add)));
    await tester.pumpAndSettle();
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('🔥 2 jours d\'affilée'), findsOneWidget);
    expect(find.text('2/4 complétés'), findsNWidgets(2));
    expect(find.text('4/4 complétés'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    // Wednesday 28 in the week strip (nothing written).
    await tester.tap(find.text('28'));
    await tester.tap(find.text('Être patient avec mes collègues.'));
    expect(opened, [today, DateTime(2026, 10, 28), DateTime(2026, 10, 30)]);
  });

  testWidgets('home: nothing written yet', (tester) async {
    small(tester);
    await tester.pumpWidget(app('fr', home(list: const [])));
    await tester.pumpAndSettle();
    expect(find.text('Écrire'), findsOneWidget);
    expect(find.textContaining('🔥'), findsNothing);
  });

  testWidgets('editor: saves the 4 sections, gratitude as lines', (
    tester,
  ) async {
    small(tester, height: 1800);
    JournalEntry? saved;
    await tester.pumpWidget(app('fr', editor(onSave: (e) async => saved = e)));
    await tester.pumpAndSettle();
    expect(find.text('0/4 complétés'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Sa paix');
    await tester.enterText(fields.at(3), 'Ma famille');
    await tester.enterText(fields.at(5), 'Mon église');
    await tester.pump();
    expect(find.text('2/4 complétés'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(saved!.godShows, 'Sa paix');
    expect(saved!.mustChange, '');
    expect(saved!.gratitude, 'Ma famille\nMon église');
    expect(find.text('Journal enregistré'), findsOneWidget);
  });

  testWidgets('editor: asks before leaving with unsaved writing', (
    tester,
  ) async {
    small(tester);
    await tester.pumpWidget(app('fr', editor(), initial: '/prev'));
    await tester.pumpAndSettle();

    // Nothing written: leaves at once.
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('OPEN'), findsOneWidget);

    // Something written: asks first.
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Une pensée');
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Quitter sans enregistrer ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Une pensée'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitter'));
    await tester.pumpAndSettle();
    expect(find.text('OPEN'), findsOneWidget);
  });
}
