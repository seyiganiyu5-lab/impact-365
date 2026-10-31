import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models.dart';
import '../widgets/common.dart';
import 'auth_links.dart';
import 'transitions.dart';
import 'locale_controller.dart';

import '../features/auth/auth_screen.dart';
import '../features/auth/google_native_sign_in.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/signing_in_screen.dart';
import '../features/devotion/devotion_screen.dart';
import '../features/devotion/word_screen.dart';
import '../features/home/home_screen.dart';
import '../features/impact/impact_screen.dart';
import '../features/inbox/chat_screen.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/inbox/new_conversation_screen.dart';
import '../features/journal/journal_entry_screen.dart';
import '../features/journal/journal_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/prayer/community_prayers_screen.dart';
import '../features/prayer/my_prayers_screen.dart';
import '../features/prayer/prayer_room_screen.dart';
import '../features/profile/change_password_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/language_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/sos/community_needs_screen.dart';
import '../features/sos/my_help_requests_screen.dart';
import '../features/sos/sos_hub_screen.dart';
import '../features/sos/sos_request_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/welcome/welcome_screen.dart';

/// Re-runs the router redirect whenever the auth state changes, and
/// remembers when a password-reset link was opened.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (state) {
        if (state.event == AuthChangeEvent.signedIn) {
          unawaited(_rememberLanguage());
          unawaited(AuthFlow.clearOAuth());
        }
        if (state.event == AuthChangeEvent.passwordRecovery) {
          AuthFlow.recoveryPending = true;
        } else if (state.event == AuthChangeEvent.signedOut) {
          AuthFlow.recoveryPending = false;
          unawaited(GoogleNativeSignIn.signOutQuietly());
        }
        notifyListeners();
      },
      // The stream also reports background problems, such as a failed
      // session refresh while offline. Only an email link that is expired
      // or already used deserves a message here.
      onError: (Object error) {
        final context = _rootKey.currentContext;
        if (AuthFlow.oauthPending) {
          // Google / Apple refused or the sign-in link failed.
          unawaited(AuthFlow.clearOAuth());
          notifyListeners();
          if (context != null && context.mounted) {
            context.toast(context.l10n.authErrOAuth);
          }
        } else if (_isExpiredLinkError(error) &&
            context != null &&
            context.mounted) {
          context.toast(context.l10n.authErrLinkExpired);
        } else {
          debugPrint('Auth stream error (no message shown): $error');
        }
      },
    );
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

bool _isExpiredLinkError(Object error) =>
    error is AuthPKCEGrantCodeExchangeError ||
    (error is AuthException &&
        const {
          'otp_expired',
          'flow_state_expired',
          'flow_state_not_found',
          'bad_code_verifier',
        }.contains(error.code));

/// Google / Apple accounts arrive without the language picked in the app:
/// save it once so the app and the emails use it.
Future<void> _rememberLanguage() async {
  final auth = Supabase.instance.client.auth;
  final user = auth.currentUser;
  if (user == null || user.userMetadata?['preferred_language'] != null) return;
  final code = LocaleController.instance.languageCode;
  try {
    await auth.updateUser(UserAttributes(data: {'preferred_language': code}));
    await Supabase.instance.client
        .from('profiles')
        .update({'preferred_language': code})
        .eq('id', user.id);
  } catch (_) {
    // Not important enough to bother the user; they can change it in Profil.
  }
}

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/splash',
  refreshListenable: _AuthListenable(),
  redirect: (context, state) {
    final signedIn = Supabase.instance.client.auth.currentSession != null;
    final location = state.matchedLocation;
    // The splash animation decides by itself when to move on.
    if (location == '/splash') return null;
    // Opened a password-reset link: choose a new password first.
    if (AuthFlow.recoveryPending && signedIn) {
      return location == '/reset-password' ? null : '/reset-password';
    }
    if (location == '/reset-password' && !signedIn) return '/welcome';
    // Google / Apple sign-in in progress: "Connexion en cours…", never the
    // welcome or sign-in page (also after Android restarts the app).
    if (!signedIn && AuthFlow.oauthPending) {
      return location == '/signing-in' ? null : '/signing-in';
    }
    if (location == '/signing-in') return signedIn ? '/home' : '/welcome';
    // Pages a signed-out visitor is allowed to see.
    const publicPages = {'/welcome', '/auth', '/onboarding'};
    final isPublic = publicPages.contains(state.matchedLocation);
    if (!signedIn && !isPublic) return '/welcome';
    if (signedIn &&
        (state.matchedLocation == '/auth' ||
            state.matchedLocation == '/welcome')) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (_, s) => instantPage(s, const SplashScreen()),
    ),
    GoRoute(
      path: '/signing-in',
      pageBuilder: (_, s) => fadePage(s, const SigningInScreen()),
    ),
    GoRoute(
      path: '/reset-password',
      pageBuilder: (_, s) => appPage(s, const ResetPasswordScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (_, s) => fadePage(s, const OnboardingScreen()),
    ),
    GoRoute(
      path: '/welcome',
      pageBuilder: (_, s) => fadePage(s, const WelcomeScreen()),
    ),
    GoRoute(
      path: '/auth',
      pageBuilder: (_, state) => appPage(
        state,
        AuthScreen(signUp: state.uri.queryParameters['mode'] == 'signup'),
      ),
    ),

    // Bottom navigation: Accueil / Parole / Prière / Impact / Profil
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (_, s) => instantPage(s, const HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/word',
              pageBuilder: (_, s) => instantPage(s, const WordScreen()),
              routes: [
                // Inside the Parole tab, so the bottom bar stays visible.
                GoRoute(
                  path: 'devotion/:id',
                  pageBuilder: (_, s) => appPage(
                    s,
                    DevotionScreen(
                      id: s.pathParameters['id']!,
                      // Opened from Parole: shown at once, no loading.
                      initial: s.extra is Devotion ? s.extra as Devotion : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/prayer',
              pageBuilder: (_, s) => instantPage(s, const PrayerRoomScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/impact',
              pageBuilder: (_, s) => instantPage(s, const ImpactScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (_, s) => instantPage(s, const ProfileScreen()),
            ),
          ],
        ),
      ],
    ),

    // Full-screen pages pushed on top of the tabs
    // Old address, kept so existing links still work.
    GoRoute(
      path: '/devotion/:id',
      redirect: (_, s) => '/word/devotion/${s.pathParameters['id']}',
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/journal',
      pageBuilder: (_, s) => appPage(s, const JournalScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/journal/:date',
      pageBuilder: (_, s) {
        final today = DateTime.now();
        final parsed = DateTime.tryParse(s.pathParameters['date'] ?? '');
        // Never a future day.
        final day = parsed == null || parsed.isAfter(today) ? today : parsed;
        return appPage(
          s,
          JournalEntryScreen(day: DateTime(day.year, day.month, day.day)),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/prayers/mine',
      pageBuilder: (_, s) => appPage(s, const MyPrayersScreen(answered: false)),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/prayers/answered',
      pageBuilder: (_, s) => appPage(s, const MyPrayersScreen(answered: true)),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/prayers/community',
      pageBuilder: (_, s) => appPage(s, const CommunityPrayersScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/sos',
      pageBuilder: (_, s) => appPage(s, const SosHubScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/sos/new',
      pageBuilder: (_, s) => appPage(s, const SosRequestScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/sos/needs',
      pageBuilder: (_, s) => appPage(s, const CommunityNeedsScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/sos/mine',
      pageBuilder: (_, s) => appPage(s, const MyHelpRequestsScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/inbox',
      pageBuilder: (_, s) => appPage(s, const InboxScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/inbox/new',
      pageBuilder: (_, s) => appPage(
        s,
        NewConversationScreen(initialSubject: s.uri.queryParameters['subject']),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/inbox/:id',
      pageBuilder: (_, s) =>
          appPage(s, ChatScreen(conversationId: s.pathParameters['id']!)),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/profile/password',
      pageBuilder: (_, s) => appPage(s, const ChangePasswordScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/profile/edit',
      pageBuilder: (_, s) => appPage(s, const EditProfileScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/profile/language',
      pageBuilder: (_, s) => appPage(s, const LanguageScreen()),
    ),
  ],
);
