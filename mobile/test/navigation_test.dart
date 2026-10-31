import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:impact365/core/auth_links.dart';
import 'package:impact365/core/transitions.dart';
import 'package:impact365/features/auth/google_native_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Google / Apple sign-in in progress', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('is remembered across an app restart', () async {
      await AuthFlow.startOAuth();
      expect(AuthFlow.oauthPending, isTrue);
      // "Restart": a fresh load from storage.
      await AuthFlow.load();
      expect(AuthFlow.oauthPending, isTrue);
      await AuthFlow.clearOAuth();
      await AuthFlow.load();
      expect(AuthFlow.oauthPending, isFalse);
    });

    test('an old, unfinished attempt is ignored after 5 minutes', () async {
      SharedPreferences.setMockInitialValues({
        'oauth_started_at': DateTime.now()
            .subtract(const Duration(minutes: 6))
            .millisecondsSinceEpoch,
      });
      await AuthFlow.load();
      expect(AuthFlow.oauthPending, isFalse);
    });
  });

  testWidgets('pages slide in quickly (WhatsApp-like)', (tester) async {
    late Page<void> page;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, s) => page = appPage(s, const SizedBox()),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    // Tests run as Android by default.
    expect(page, isA<CustomTransitionPage<void>>());
    final custom = page as CustomTransitionPage<void>;
    expect(custom.transitionDuration.inMilliseconds, lessThanOrEqualTo(250));
    expect(
      custom.reverseTransitionDuration.inMilliseconds,
      lessThanOrEqualTo(200),
    );
  });

  test('without the Google client IDs, Google uses the web page', () {
    // Tests run without env.json: no GOOGLE_WEB_CLIENT_ID.
    expect(GoogleNativeSignIn.available, isFalse);
  });
}
