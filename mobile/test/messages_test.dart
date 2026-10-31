import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/data/models.dart';
import 'package:impact365/features/inbox/chat_screen.dart';
import 'package:impact365/features/inbox/inbox_screen.dart';
import 'package:impact365/features/inbox/new_conversation_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';

final _now = DateTime.now();

List<Conversation> convs() => [
  Conversation(
    id: 'c1',
    subject: "J'ai besoin d'un conseil",
    status: 'open',
    lastMessageAt: _now,
    lastMessage: 'Bien sûr, nous prions pour toi. Peux-tu nous en dire plus ?',
    lastFromStaff: true,
    unread: 2,
  ),
  Conversation(
    id: 'c2',
    subject: 'Demande de prière pour ma famille',
    status: 'closed',
    lastMessageAt: _now.subtract(const Duration(days: 3)),
    lastMessage: 'Merci beaucoup !',
  ),
];

List<Announcement> announcements() => [
  Announcement(
    id: 'a1',
    title: 'Culte spécial dimanche',
    body: 'Rejoins-nous à 10h pour un temps de louange et de prière.',
    createdAt: _now,
  ),
];

List<ChatMessage> msgs() => [
  ChatMessage(
    id: 'm1',
    body: "Bonjour, j'ai besoin d'un conseil pour mon travail.",
    senderId: 'me',
    isFromStaff: false,
    createdAt: _now.subtract(const Duration(days: 1, hours: 2)),
  ),
  ChatMessage(
    id: 'm2',
    body: 'Bonjour ! Nous sommes là pour toi. Raconte-nous.',
    senderId: 'pastor',
    isFromStaff: true,
    createdAt: _now.subtract(const Duration(days: 1, hours: 1)),
  ),
  ChatMessage(
    id: 'm3',
    body: 'Merci, je vous explique ce soir.',
    senderId: 'me',
    isFromStaff: false,
    createdAt: _now.subtract(const Duration(minutes: 5)),
  ),
];

Widget msgApp(String lang, Widget home) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/inbox/new',
        builder: (_, _) => const Text('PAGE /inbox/new'),
      ),
      GoRoute(
        path: '/inbox/:id',
        builder: (_, s) => Text('PAGE /inbox/${s.pathParameters['id']}'),
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

Future<void> _noRefresh() async {}
Future<void> _noSend(String text) async {}

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
      'inbox': () => page(
        InboxBody(
          conversations: convs(),
          announcements: announcements(),
          onRefresh: _noRefresh,
        ),
      ),
      'inbox empty': () => page(
        InboxBody(
          conversations: const [],
          announcements: const [],
          onRefresh: _noRefresh,
        ),
      ),
      'chat': () => ChatView(
        subject: "J'ai besoin d'un conseil pour mon travail",
        isOpen: true,
        messages: msgs(),
        myId: 'me',
        onSend: _noSend,
      ),
      'chat closed': () => ChatView(
        subject: 'Demande de prière',
        isOpen: false,
        messages: msgs(),
        myId: 'me',
        onSend: _noSend,
      ),
      'new conversation': () => const NewConversationScreen(),
    };
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('Messages $name fits a small phone ($lang)', (tester) async {
        small(tester);
        await tester.pumpWidget(msgApp(lang, screen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('inbox: unread badge, tabs, open chat and new', (tester) async {
    small(tester);
    await tester.pumpWidget(
      msgApp(
        'fr',
        page(
          InboxBody(
            conversations: convs(),
            announcements: announcements(),
            onRefresh: _noRefresh,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2'), findsWidgets);
    expect(find.text('Clôturée'), findsOneWidget);
    expect(find.textContaining('Toi'), findsOneWidget);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Culte spécial dimanche'), findsOneWidget);

    await tester.tap(find.text('Messages').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text("J'ai besoin d'un conseil"));
    await tester.pumpAndSettle();
    expect(find.text('PAGE /inbox/c1'), findsOneWidget);
  });

  testWidgets('inbox: "Parler à un responsable" opens the form', (
    tester,
  ) async {
    small(tester);
    await tester.pumpWidget(
      msgApp(
        'fr',
        page(
          InboxBody(
            conversations: const [],
            announcements: const [],
            onRefresh: _noRefresh,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parler à un responsable'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE /inbox/new'), findsOneWidget);
  });

  testWidgets('chat: day separators, leader label and sending', (tester) async {
    small(tester);
    final sent = <String>[];
    await tester.pumpWidget(
      msgApp(
        'fr',
        ChatView(
          subject: 'Conseil',
          isOpen: true,
          messages: msgs(),
          myId: 'me',
          onSend: (t) async => sent.add(t),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('Hier'), findsOneWidget);
    expect(find.text('Responsable'), findsOneWidget);
    expect(find.text('Pasteurs & responsables'), findsOneWidget);

    // Empty message is not sent.
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    expect(sent, isEmpty);

    await tester.enterText(find.byType(TextField), '  Merci !  ');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(sent, ['Merci !']);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('chat: closed conversation has no input', (tester) async {
    small(tester);
    await tester.pumpWidget(
      msgApp(
        'fr',
        ChatView(
          subject: 'Conseil',
          isOpen: false,
          messages: msgs(),
          myId: 'me',
          onSend: _noSend,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(
      find.text('Cette conversation a été clôturée par les responsables.'),
      findsOneWidget,
    );
  });

  testWidgets('new conversation: validation, topic chip, then opens chat', (
    tester,
  ) async {
    small(tester, height: 1400);
    String? started;
    await tester.pumpWidget(
      msgApp(
        'fr',
        NewConversationScreen(
          start: (subject, body) async {
            started = '$subject|$body';
            return 'c9';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(find.text('Indique un sujet.'), findsOneWidget);
    expect(find.text('Écris ton message.'), findsOneWidget);
    expect(started, isNull);

    await tester.tap(find.text('🙏 Demande de prière'));
    await tester.pumpAndSettle();
    expect(find.text('Indique un sujet.'), findsNothing);
    await tester.enterText(find.byType(TextField).last, 'Pour ma santé');
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(started, 'Demande de prière|Pour ma santé');
    expect(find.text('PAGE /inbox/c9'), findsOneWidget);
  });
}
