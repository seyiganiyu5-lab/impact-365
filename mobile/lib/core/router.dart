import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/auth_screen.dart';
import '../features/devotion/devotion_screen.dart';
import '../features/devotion/word_screen.dart';
import '../features/home/home_screen.dart';
import '../features/impact/impact_screen.dart';
import '../features/inbox/chat_screen.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/inbox/new_conversation_screen.dart';
import '../features/journal/journal_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/prayer/community_prayers_screen.dart';
import '../features/prayer/my_prayers_screen.dart';
import '../features/prayer/prayer_room_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/language_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/sos/community_needs_screen.dart';
import '../features/sos/my_help_requests_screen.dart';
import '../features/sos/sos_hub_screen.dart';
import '../features/sos/sos_request_screen.dart';
import '../features/splash/splash_screen.dart';

/// Re-runs the router redirect whenever the user signs in or out.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/splash',
  refreshListenable: _AuthListenable(),
  redirect: (context, state) {
    final signedIn = Supabase.instance.client.auth.currentSession != null;
    // The splash animation decides by itself when to move on.
    if (state.matchedLocation == '/splash') return null;
    final onAuth = state.matchedLocation == '/auth';
    final onOnboarding = state.matchedLocation == '/onboarding';
    if (!signedIn && !onAuth && !onOnboarding) return '/auth';
    if (signedIn && onAuth) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),

    // Bottom navigation: Accueil / Parole / Prière / Impact / Profil
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/word', builder: (_, _) => const WordScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/prayer',
              builder: (_, _) => const PrayerRoomScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/impact', builder: (_, _) => const ImpactScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ],
        ),
      ],
    ),

    // Full-screen pages pushed on top of the tabs
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/devotion/:id',
      builder: (_, s) => DevotionScreen(id: s.pathParameters['id']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/journal',
      builder: (_, _) => const JournalScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/prayers/mine',
      builder: (_, _) => const MyPrayersScreen(answered: false),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/prayers/answered',
      builder: (_, _) => const MyPrayersScreen(answered: true),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/prayers/community',
      builder: (_, _) => const CommunityPrayersScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/sos',
      builder: (_, _) => const SosHubScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/sos/new',
      builder: (_, _) => const SosRequestScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/sos/needs',
      builder: (_, _) => const CommunityNeedsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/sos/mine',
      builder: (_, _) => const MyHelpRequestsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/inbox',
      builder: (_, _) => const InboxScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/inbox/new',
      builder: (_, s) => NewConversationScreen(
        initialSubject: s.uri.queryParameters['subject'],
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/inbox/:id',
      builder: (_, s) => ChatScreen(conversationId: s.pathParameters['id']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/profile/edit',
      builder: (_, _) => const EditProfileScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/profile/language',
      builder: (_, _) => const LanguageScreen(),
    ),
  ],
);
