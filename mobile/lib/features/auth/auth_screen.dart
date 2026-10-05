import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/locale_controller.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// Sign in / sign up with email + password.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.signUp = false});

  /// Open directly on "Create my account" instead of "Sign in".
  final bool signUp;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _signUp = widget.signUp;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty ||
        password.length < 6 ||
        (_signUp && _name.text.trim().isEmpty)) {
      context.toast(l.authInvalid);
      return;
    }
    setState(() => _busy = true);
    final auth = Supabase.instance.client.auth;
    try {
      if (_signUp) {
        final res = await auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': _name.text.trim(),
            'preferred_language': LocaleController.instance.languageCode,
          },
        );
        // If email confirmation is on, there is no session yet.
        if (res.session == null && mounted) context.toast(l.authCheckEmail);
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
      // The router redirects to /home automatically when a session exists.
    } on AuthException catch (e) {
      if (mounted) context.toast(e.message);
    } catch (_) {
      if (mounted) context.toast(l.commonError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      extendBodyBehindAppBar: true,
      // Back to the welcome page (the sign-in / sign-up designs come next).
      appBar: context.canPop()
          ? AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.sunsetGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const BrandLogo(light: true, size: 56),
                  const SizedBox(height: 32),
                  Text(
                    l.authWelcome,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.authSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (_signUp) ...[
                          TextField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: l.authFullName,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: InputDecoration(
                            hintText: l.authEmail,
                            prefixIcon: const Icon(Icons.mail_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: l.authPassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 20),
                        GoldButton(
                          label: _signUp ? l.authSignUp : l.authSignIn,
                          onPressed: _busy ? null : _submit,
                        ),
                        TextButton(
                          onPressed: () => setState(() => _signUp = !_signUp),
                          child: Text(
                            _signUp ? l.authHaveAccount : l.authNoAccount,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LanguagePicker(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final current = LocaleController.instance.languageCode;
    return Wrap(
      spacing: 8,
      children: [
        for (final loc in LocaleController.supported)
          ChoiceChip(
            label: Text(LocaleController.displayName(loc.languageCode)),
            selected: current == loc.languageCode,
            onSelected: (_) => LocaleController.instance.setLocale(loc),
          ),
      ],
    );
  }
}
