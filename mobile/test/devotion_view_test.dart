import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/data/models.dart';
import 'package:impact365/features/devotion/devotion_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

Devotion sampleDevotion({String? audio}) => Devotion(
  id: 'd1',
  date: DateTime(2026, 9, 3),
  slot: DevotionSlot.morning,
  verseReference: 'Matthieu 6:33',
  verseText:
      'Cherchez premièrement le royaume et la justice de Dieu ; et toutes '
      'ces choses vous seront données par-dessus.',
  godSays:
      'Cherchez premièrement le royaume et la justice de Dieu et toutes ces '
      'choses vous seront données par-dessus.',
  iUnderstand:
      "Si je cherche d'abord Dieu, Il pourvoira à tout le reste. Ce n'est pas "
      "une promesse pour demain, c'est un principe pour aujourd'hui.",
  iDo:
      "Aujourd'hui, je choisis de prioriser Dieu dans mes décisions, mes "
      'pensées et mon temps.',
  audioUrl: audio,
);

Widget devotionApp(String lang, Devotion d) => MaterialApp(
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
    body: DevotionView(devotion: d),
  ),
);

void main() {
  setUpAll(() async {
    final inter = FontLoader('Inter');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
    }
    await inter.load();
  });

  for (final lang in ['fr', 'en', 'yo']) {
    testWidgets('devotion page fits a small phone ($lang)', (tester) async {
      tester.view.physicalSize = const Size(360, 1600) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(devotionApp(lang, sampleDevotion()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows verse, date badge, the three sections and buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 1600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(devotionApp('fr', sampleDevotion()));
    await tester.pump();
    for (final t in [
      '5 MINUTES AVEC DIEU',
      'Matthieu 6:33',
      'JEUDI',
      '03',
      'SEPT',
      'CE QUE DIEU DIT',
      'CE QUE JE COMPRENDS',
      'CE QUE JE FAIS',
      "J'AI COMPRIS",
      'AUDIO BIENTÔT DISPONIBLE',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('audio button is active when the devotion has audio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 1600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      devotionApp('fr', sampleDevotion(audio: 'https://x.test/a.mp3')),
    );
    await tester.pump();
    expect(find.text('ÉCOUTER EN AUDIO'), findsOneWidget);
  });
}
