import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_links.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// "Connexion en cours…": shown while a Google / Apple sign-in finishes.
///
/// The router sends the app here whenever a sign-in is in progress
/// ([AuthFlow.oauthPending]), including when Android restarts the app on
/// the way back from Google. When the session arrives, the router opens the
/// home screen. If the person closed Google's page instead, we go back to
/// the sign-in page after a few seconds (or right away with "Annuler").
class SigningInScreen extends StatefulWidget {
  const SigningInScreen({super.key});

  /// How long to wait for the session once the person is back in the app.
  static const giveUpAfter = Duration(seconds: 10);

  @override
  State<SigningInScreen> createState() => _SigningInScreenState();
}

class _SigningInScreenState extends State<SigningInScreen>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Restarted by Android on the way back: the person is already here,
    // start waiting now. Otherwise (Google's page is opening on top of the
    // app) wait until they come back, so a slow account choice is fine.
    _startTimer(
      AuthFlow.oauthOpenedThisRun
          ? const Duration(minutes: 3)
          : SigningInScreen.giveUpAfter,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer(SigningInScreen.giveUpAfter);
    }
  }

  void _startTimer(Duration after) {
    _timer?.cancel();
    _timer = Timer(after, () {
      final signedIn = Supabase.instance.client.auth.currentSession != null;
      if (mounted && !signedIn) _cancel();
    });
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    await AuthFlow.clearOAuth();
    if (!mounted) return;
    // Back to the welcome page with the sign-in page on top, so the back
    // button still works as before.
    context.go('/welcome');
    context.push('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 64),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: AppColors.deepPurple,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l.authSigningIn,
                  textAlign: TextAlign.center,
                  style: AppText.titleMedium.copyWith(
                    color: AppColors.deepPurple,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _cancel,
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                  child: Text(l.commonCancel, style: AppText.labelMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
