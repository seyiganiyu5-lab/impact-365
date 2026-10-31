import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/features/profile/language_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

/// Like the app: choosing a language switches the whole UI.
class Harness extends StatefulWidget {
  const Harness({super.key, required this.start, this.picked});

  final String start;
  final List<String>? picked;

  @override
  State<Harness> createState() => _HarnessState();
}

class _HarnessState extends State<Harness> {
  late String _lang = widget.start;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(),
      locale: Locale(_lang),
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
      home: LanguageView(
        current: _lang,
        onSelect: (code) {
          widget.picked?.add(code);
          setState(() {
            _lang = code;
          });
        },
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    final inter = FontLoader('Inter');
    for (final w in ['Regular', 'Italic', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
    }
    await inter.load();
  });

  void small(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 740) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  for (final lang in ['fr', 'en', 'yo']) {
    testWidgets('Langue fits a small phone ($lang)', (tester) async {
      small(tester);
      await tester.pumpWidget(Harness(start: lang));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('choosing a language switches the screen at once', (
    tester,
  ) async {
    small(tester);
    final picked = <String>[];
    await tester.pumpWidget(Harness(start: 'fr', picked: picked));
    await tester.pumpAndSettle();
    expect(find.text('Langue'), findsOneWidget);
    expect(find.text('Anglais'), findsOneWidget);
    expect(find.text('May God bless you'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(picked, ['en']);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('French'), findsOneWidget);
    // The chosen one has the gold check.
    final check = find.byIcon(Icons.check_rounded);
    expect(check, findsOneWidget);
    expect(
      find.ancestor(
        of: check,
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.selected == true,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.ancestor(of: check, matching: find.byType(Row)).first,
        matching: find.text('English'),
      ),
      findsOneWidget,
    );
  });
}
