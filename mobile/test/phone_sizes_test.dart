// Every screen on common phone sizes, with normal and larger text (phone
// accessibility setting), in French and Yoruba (the longest texts).
// A screen fails if Flutter reports an overflow ("yellow and black
// stripes") or any other error, at rest or after scrolling to the end.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impact365/core/locale_controller.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/core/yoruba_fallback.dart';
import 'package:impact365/data/models.dart';
import 'package:impact365/features/auth/auth_screen.dart';
import 'package:impact365/features/auth/reset_password_screen.dart';
import 'package:impact365/features/inbox/chat_screen.dart';
import 'package:impact365/features/inbox/inbox_screen.dart';
import 'package:impact365/features/inbox/new_conversation_screen.dart';
import 'package:impact365/features/onboarding/onboarding_screen.dart';
import 'package:impact365/features/prayer/add_prayer_sheet.dart';
import 'package:impact365/features/prayer/community_prayers_screen.dart';
import 'package:impact365/features/profile/change_password_screen.dart';
import 'package:impact365/features/sos/community_needs_screen.dart';
import 'package:impact365/features/sos/my_help_requests_screen.dart';
import 'package:impact365/features/sos/sos_hub_screen.dart';
import 'package:impact365/features/sos/sos_request_screen.dart';
import 'package:impact365/features/welcome/welcome_screen.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'devotion_view_test.dart' as dv;
import 'home_layout_test.dart' as hm;
import 'impact_test.dart' as im;
import 'journal_test.dart' as jn;
import 'language_test.dart' as lg;
import 'messages_test.dart' as ms;
import 'my_prayers_test.dart' as mp;
import 'personal_info_test.dart' as pi;
import 'prayer_room_test.dart' as pr;
import 'profile_test.dart' as pf;
import 'sos_test.dart' as sos;
import 'word_screen_test.dart' as wd;

Widget wrap(String lang, Widget home) => MaterialApp(
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

Future<void> _noSubmit({
  required HelpCategory category,
  required String description,
  required bool anonymous,
  required bool leadersOnly,
}) async {}

final screens = <String, Widget Function(String lang)>{
  'welcome': (l) => wrap(l, const WelcomeScreen()),
  'onboarding': (l) => wrap(l, const OnboardingScreen()),
  'sign in': (l) => wrap(l, const AuthScreen()),
  'sign up': (l) => wrap(l, const AuthScreen(signUp: true)),
  'reset password': (l) => wrap(l, const ResetPasswordScreen()),
  'home': (l) => hm.homeApp(l, hm.sampleHome()),
  'parole': (l) => wd.wordApp(l, wd.sample()),
  'devotion': (l) => dv.devotionApp(l, dv.sampleDevotion(audio: 'x')),
  'prayer room': (l) => pr.prayerApp(l, pr.sample()),
  'my prayers': (l) => mp.app(l, mp.body()),
  'answered prayers': (l) => mp.app(l, mp.body(tab: 1)),
  'community prayers': (l) =>
      mp.app(l, mp.page(CommunityPrayersBody(prayers: mp.community()))),
  'new prayer': (l) => mp.app(
    l,
    mp.page(
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
  ),
  'journal': (l) => jn.app(l, jn.home()),
  'journal page': (l) => jn.app(l, jn.editor(initial: jn.entries()[1])),
  'impact': (l) => im.impactApp(l, im.sample()),
  'profile': (l) => pf.profileApp(l, pf.sample(role: 'pastor')),
  'personal info': (l) => pi.app(l, pi.view()),
  'language': (l) => lg.Harness(start: l),
  'change password': (l) =>
      wrap(l, const ChangePasswordScreen(email: 'jean-baptiste@exemple.com')),
  'sos hub': (l) => sos.sosApp(l, const SosHubScreen()),
  'sos request': (l) => sos.sosApp(l, SosRequestScreen(submit: _noSubmit)),
  'sos needs': (l) => sos.sosApp(
    l,
    sos.page(CommunityNeedsBody(needs: sos.needs(), onOffer: (_, _) async {})),
  ),
  'sos mine': (l) => sos.sosApp(
    l,
    sos.page(
      MyHelpRequestsBody(
        requests: sos.mine(),
        onResolve: (_) async {},
        onNew: () {},
      ),
    ),
  ),
  'inbox': (l) => ms.msgApp(
    l,
    ms.page(
      InboxBody(
        conversations: ms.convs(),
        announcements: ms.announcements(),
        onRefresh: () async {},
      ),
    ),
  ),
  'chat': (l) => ms.msgApp(
    l,
    ChatView(
      subject: "J'ai besoin d'un conseil pour mon travail",
      isOpen: true,
      messages: ms.msgs(),
      myId: 'me',
      onSend: (_) async {},
    ),
  ),
  'new conversation': (l) => ms.msgApp(l, const NewConversationScreen()),
};

/// (name, logical size): from small Android phones to a tablet.
const sizes = [
  ('320x568', Size(320, 568)),
  ('360x640', Size(360, 640)),
  ('375x667', Size(375, 667)),
  ('390x844', Size(390, 844)),
  ('414x896', Size(414, 896)),
  ('430x932', Size(430, 932)),
  ('768x1024', Size(768, 1024)),
];

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleController.init();
    final inter = FontLoader('Inter');
    for (final w in [
      'Regular',
      'Italic',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
    }
    await inter.load();
    final serif = FontLoader('SourceSerif4');
    serif.addFont(rootBundle.load('assets/fonts/SourceSerif4-Italic.ttf'));
    serif.addFont(
      rootBundle.load('assets/fonts/SourceSerif4-SemiBoldItalic.ttf'),
    );
    await serif.load();
  });

  for (final MapEntry(key: name, value: build) in screens.entries) {
    for (final (sizeName, size) in sizes) {
      for (final scale in [1.0, 1.3]) {
        for (final lang in ['fr', 'yo']) {
          testWidgets('$name · $sizeName · text ×$scale · $lang', (
            tester,
          ) async {
            tester.view.physicalSize = size * 3;
            tester.view.devicePixelRatio = 3;
            tester.view.padding = const FakeViewPadding(
              top: 24 * 3,
              bottom: 16 * 3,
            );
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );

            await tester.pumpWidget(build(lang));
            await tester.pump(const Duration(milliseconds: 600));
            await tester.pump(const Duration(milliseconds: 600));
            expect(tester.takeException(), isNull, reason: 'at rest');

            // Scroll to the end of the main scrolling area.
            final scrollables = find.byType(Scrollable);
            if (scrollables.evaluate().isNotEmpty) {
              for (var i = 0; i < 6; i++) {
                await tester.drag(
                  scrollables.first,
                  const Offset(0, -700),
                  warnIfMissed: false,
                );
                await tester.pump(const Duration(milliseconds: 300));
              }
              expect(tester.takeException(), isNull, reason: 'after scrolling');
            }
          });
        }
      }
    }
  }
}
