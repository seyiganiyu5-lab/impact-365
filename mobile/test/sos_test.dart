import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/data/models.dart';
import 'package:impact365/features/sos/community_needs_screen.dart';
import 'package:impact365/features/sos/my_help_requests_screen.dart';
import 'package:impact365/features/sos/sos_hub_screen.dart';
import 'package:impact365/features/sos/sos_request_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

List<HelpNeed> needs() => [
  HelpNeed(
    id: 'n1',
    category: HelpCategory.health,
    description: 'Ma mère est malade, j\'ai besoin de prières et de soutien.',
    status: 'open',
    createdAt: DateTime.now(),
    authorName: 'Jean',
    offerCount: 2,
  ),
  HelpNeed(
    id: 'n2',
    category: HelpCategory.financial,
    description: 'Je cherche de l\'aide pour payer mon loyer ce mois-ci.',
    status: 'in_progress',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

List<MyHelpRequest> mine() => [
  MyHelpRequest(
    id: 'r1',
    category: HelpCategory.studiesWork,
    description: 'Je passe un examen important vendredi.',
    status: 'in_progress',
    createdAt: DateTime.now(),
    staffNote: 'Nous prions pour toi, courage !',
    offers: [
      HelpOffer(
        id: 'o1',
        message: 'Je peux t\'aider à réviser.',
        createdAt: DateTime.now(),
      ),
    ],
  ),
];

Widget sosApp(String lang, Widget home) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      for (final path in ['/sos/new', '/sos/needs', '/sos/mine', '/home'])
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

Widget page(Widget body) => Scaffold(
  backgroundColor: AppColors.warmWhite,
  body: SafeArea(child: body),
);

void main() {
  setUpAll(() async {
    final inter = FontLoader('Inter');
    for (final w in ['Regular', 'Italic', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
    }
    await inter.load();
  });

  void small(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 1800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  for (final lang in ['fr', 'en', 'yo']) {
    final screens = <String, Widget>{
      'hub': const SosHubScreen(),
      'form': SosRequestScreen(submit: _noSubmit),
      'needs': page(CommunityNeedsBody(needs: needs(), onOffer: _noOffer)),
      'needs empty': page(
        CommunityNeedsBody(needs: const [], onOffer: _noOffer),
      ),
      'mine': page(
        MyHelpRequestsBody(
          requests: mine(),
          onResolve: _noResolve,
          onNew: () {},
        ),
      ),
      'mine empty': page(
        MyHelpRequestsBody(
          requests: const [],
          onResolve: _noResolve,
          onNew: () {},
        ),
      ),
    };
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('Holy SOS $name fits a small phone ($lang)', (tester) async {
        small(tester);
        await tester.pumpWidget(sosApp(lang, screen));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final (label, path) in [
    ("J'ai besoin d'aide", '/sos/new'),
    ('Je veux aider', '/sos/needs'),
    ('Mes demandes', '/sos/mine'),
  ]) {
    testWidgets('hub: "$label" opens $path', (tester) async {
      small(tester);
      await tester.pumpWidget(sosApp('fr', const SosHubScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text('PAGE $path'), findsOneWidget);
    });
  }

  testWidgets('form: empty description is refused, then sends', (tester) async {
    small(tester);
    Map<String, Object>? sent;
    await tester.pumpWidget(
      sosApp(
        'fr',
        SosRequestScreen(
          submit:
              ({
                required category,
                required description,
                required anonymous,
                required leadersOnly,
              }) async {
                sent = {
                  'category': category,
                  'description': description,
                  'anonymous': anonymous,
                  'leadersOnly': leadersOnly,
                };
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envoyer ma demande'));
    await tester.pump();
    expect(find.text('Écris quelques mots sur ton besoin.'), findsOneWidget);
    expect(sent, isNull);

    await tester.tap(find.text('Santé'));
    await tester.enterText(find.byType(TextField), 'Besoin de prière');
    await tester.tap(find.text('Seulement les responsables'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envoyer ma demande'));
    await tester.pumpAndSettle();
    expect(sent, {
      'category': HelpCategory.health,
      'description': 'Besoin de prière',
      'anonymous': true,
      'leadersOnly': true,
    });
    expect(find.text('Demande envoyée 🙏'), findsOneWidget);
    await tester.tap(find.text('Voir mes demandes'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE /sos/mine'), findsOneWidget);
  });

  testWidgets('needs: filter by category and offer help', (tester) async {
    small(tester);
    String? offeredTo;
    await tester.pumpWidget(
      sosApp(
        'fr',
        page(
          CommunityNeedsBody(
            needs: needs(),
            onOffer: (id, msg) async => offeredTo = '$id:$msg',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('loyer'), findsOneWidget);
    await tester.tap(find.text('🩺 Santé'));
    await tester.pumpAndSettle();
    expect(find.textContaining('loyer'), findsNothing);

    await tester.tap(find.text('Proposer mon aide'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Je prie pour toi');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(offeredTo, 'n1:Je prie pour toi');
    expect(find.text('Aide proposée'), findsOneWidget);
  });

  testWidgets('mine: leader reply, offers and "Mon besoin est comblé"', (
    tester,
  ) async {
    small(tester);
    String? resolved;
    await tester.pumpWidget(
      sosApp(
        'fr',
        page(
          MyHelpRequestsBody(
            requests: mine(),
            onResolve: (id) async => resolved = id,
            onNew: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Réponse d\'un responsable'), findsOneWidget);
    expect(find.textContaining('Un frère / une sœur'), findsOneWidget);
    await tester.tap(find.text('Mon besoin est comblé'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Mon besoin est comblé'),
    );
    await tester.pumpAndSettle();
    expect(resolved, 'r1');
  });
}

Future<void> _noSubmit({
  required HelpCategory category,
  required String description,
  required bool anonymous,
  required bool leadersOnly,
}) async {}

Future<void> _noOffer(String id, String message) async {}

Future<void> _noResolve(String id) async {}
