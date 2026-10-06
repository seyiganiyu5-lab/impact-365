import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_links.dart';
import '../../core/locale_controller.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';

/// Sign in / create account. Opened from the welcome page.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.signUp = false});

  /// Open directly on "Create my account" instead of "Sign in".
  final bool signUp;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  late bool _signUp = widget.signUp;
  bool _busy = false;
  String? _error;

  /// Set after sign-up when Supabase requires email confirmation.
  String? _confirmationSentTo;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleMode() {
    _formKey.currentState?.reset();
    setState(() {
      _signUp = !_signUp;
      _error = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = Supabase.instance.client.auth;
    final email = _email.text.trim();
    try {
      if (_signUp) {
        final res = await auth
            .signUp(
              email: email,
              password: _password.text,
              // The confirmation email's link opens the app (see AuthLinks).
              emailRedirectTo: AuthLinks.emailConfirmed,
              data: {
                'full_name': _name.text.trim(),
                'preferred_language': LocaleController.instance.languageCode,
              },
            )
            .withAuthTimeout();
        // With email confirmation on, Supabase answers "success" with no
        // identities when the address is already registered.
        if (res.user?.identities?.isEmpty ?? false) {
          setState(() => _error = context.l10n.authErrEmailTaken);
        } else if (res.session == null && mounted) {
          // No session yet = the user must confirm their email first.
          setState(() => _confirmationSentTo = email);
        }
      } else {
        await auth
            .signInWithPassword(email: email, password: _password.text)
            .withAuthTimeout();
      }
      // With a session, the router moves to /home automatically.
    } catch (e) {
      if (!mounted) return;
      if (isEmailNotConfirmed(e)) {
        // Show the "check your inbox" view, with a button to resend.
        setState(() => _confirmationSentTo = email);
      } else {
        setState(() => _error = authErrorMessage(context, e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------ validators

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.l10n.authErrRequired : null;

  String? _validEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return context.l10n.authErrRequired;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : context.l10n.authErrEmail;
  }

  String? _validPassword(String? v) {
    if (v == null || v.isEmpty) return context.l10n.authErrRequired;
    return v.length < 6 ? context.l10n.authErrPasswordShort : null;
  }

  String? _matchesPassword(String? v) {
    if (v == null || v.isEmpty) return context.l10n.authErrRequired;
    return v == _password.text ? null : context.l10n.authErrPasswordMatch;
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: Stack(
        children: [
          // Same soft circle as the welcome page.
          Positioned(
            top: -size.width * 0.25,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF3F1EB),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _confirmationSentTo != null
                  ? _CheckEmailView(
                      email: _confirmationSentTo!,
                      onBack: () => setState(() {
                        _confirmationSentTo = null;
                        _signUp = false;
                      }),
                    )
                  : _buildForm(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final l = context.l10n;
    final accent = _signUp ? AppColors.gold : AppColors.deepPurple;

    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Navigator.canPop(context))
              RoundIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () {
                  // Close the keyboard first so the previous page doesn't
                  // have to re-layout while it slides away.
                  FocusScope.of(context).unfocus();
                  Navigator.maybePop(context);
                },
              )
            else
              const SizedBox(height: 44),
            const SizedBox(height: 28),
            const BrandMark(size: 52),
            const SizedBox(height: 20),

            // Title (Bold) + subtitle (Regular, muted).
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, ?current],
              ),
              child: Column(
                key: ValueKey(_signUp),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _signUp ? l.signUpTitle : l.signInTitle,
                    style: AppText.headline.copyWith(
                      color: AppColors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _signUp ? l.signUpSubtitle : l.signInSubtitle,
                    style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Fields
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  if (_signUp) ...[
                    AuthField(
                      label: l.authFullName,
                      controller: _name,
                      hint: l.authFullNameHint,
                      icon: Icons.person_outline_rounded,
                      validator: _required,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                    ),
                    const SizedBox(height: 18),
                  ],
                  AuthField(
                    label: l.authEmail,
                    controller: _email,
                    hint: l.authEmailHint,
                    icon: Icons.mail_outline_rounded,
                    validator: _validEmail,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 18),
                  PasswordField(
                    label: l.authPassword,
                    controller: _password,
                    hint: l.authPasswordHint,
                    validator: _validPassword,
                    textInputAction: _signUp
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onSubmitted: _signUp ? null : (_) => _submit(),
                    autofillHints: [
                      _signUp
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                  ),
                  if (_signUp) ...[
                    const SizedBox(height: 18),
                    PasswordField(
                      label: l.authConfirmPassword,
                      controller: _confirm,
                      hint: l.authConfirmPasswordHint,
                      validator: _matchesPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                ],
              ),
            ),

            if (!_signUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showResetSheet(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                  ),
                  child: Text(l.authForgot, style: AppText.labelMedium),
                ),
              )
            else
              const SizedBox(height: 16),

            // Error from Supabase (wrong password, email taken, ...)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),

            AuthButton(
              label: _signUp ? l.authSignUp : l.authSignIn,
              color: accent,
              busy: _busy,
              onPressed: _submit,
            ),

            if (_signUp) ...[
              const SizedBox(height: 14),
              Text(
                l.authTerms,
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 28),

            // Switch between sign in and sign up: one centred sentence,
            // the link part is tappable.
            _SwitchModeLink(
              question: _signUp ? l.authHaveAccountQ : l.authNoAccountQ,
              action: _signUp ? l.welcomeSignIn : l.welcomeSignUp,
              onTap: _busy ? null : _toggleMode,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResetSheet(BuildContext context) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.warmWhite,
      builder: (_) => _ResetPasswordSheet(initialEmail: _email.text.trim()),
    );
    if (sent == true && context.mounted) {
      context.toast(context.l10n.authResetSent);
    }
  }
}

// ---------------------------------------------------------------- widgets

/// Shown after sign-up (or when signing in to an unconfirmed account): the
/// account must be confirmed by email. Lets the user resend the email.
class _CheckEmailView extends StatefulWidget {
  const _CheckEmailView({required this.email, required this.onBack});

  final String email;
  final VoidCallback onBack;

  @override
  State<_CheckEmailView> createState() => _CheckEmailViewState();
}

class _CheckEmailViewState extends State<_CheckEmailView> {
  static const _cooldown = 60;

  /// Seconds before "Resend" is allowed again (Supabase rate-limits emails).
  int _wait = _cooldown;
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _wait = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_wait <= 1) t.cancel();
      if (mounted) setState(() => _wait--);
    });
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.auth
          .resend(
            type: OtpType.signup,
            email: widget.email,
            emailRedirectTo: AuthLinks.emailConfirmed,
          )
          .withAuthTimeout();
      if (!mounted) return;
      context.toast(context.l10n.authResent);
      _startCooldown();
    } catch (e) {
      if (mounted) context.toast(authErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canResend = _wait <= 0 && !_sending;
    return Padding(
      key: const ValueKey('check-email'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.deepPurple,
              size: 44,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l.authCheckEmailTitle,
            textAlign: TextAlign.center,
            style: AppText.headline.copyWith(color: AppColors.deepPurple),
          ),
          const SizedBox(height: 12),
          Text(
            l.authCheckEmailText(widget.email),
            textAlign: TextAlign.center,
            style: AppText.bodyMedium.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            l.authCheckSpam,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
          const Spacer(flex: 2),
          AuthButton(
            label: l.authBackToSignIn,
            color: AppColors.deepPurple,
            busy: false,
            onPressed: widget.onBack,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: canResend ? _resend : null,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.deepPurple,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(
              _wait > 0 ? l.authResendIn(_wait) : l.authResend,
              style: AppText.labelMedium.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetPasswordSheet extends StatefulWidget {
  const _ResetPasswordSheet({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<_ResetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(
            _email.text.trim(),
            // The email's link opens the app on the "new password" screen.
            redirectTo: AuthLinks.resetPassword,
          )
          .withAuthTimeout();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.authResetTitle,
              style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
            ),
            const SizedBox(height: 8),
            Text(
              l.authResetText,
              style: AppText.bodyMedium.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            AuthField(
              label: l.authEmail,
              controller: _email,
              hint: l.authEmailHint,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return l.authErrRequired;
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
                    ? null
                    : l.authErrEmail;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: AppText.bodySmall.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 24),
            AuthButton(
              label: l.authResetSend,
              color: AppColors.deepPurple,
              busy: _busy,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Pas encore de compte ? Créer un compte" as one paragraph.
class _SwitchModeLink extends StatefulWidget {
  const _SwitchModeLink({
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback? onTap;

  @override
  State<_SwitchModeLink> createState() => _SwitchModeLinkState();
}

class _SwitchModeLinkState extends State<_SwitchModeLink> {
  final _recognizer = TapGestureRecognizer();

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _recognizer.onTap = widget.onTap;
    return Container(
      width: double.infinity,
      // Comfortable tap area around the sentence.
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text.rich(
        TextSpan(
          style: AppText.bodyMedium.copyWith(color: AppColors.muted),
          children: [
            TextSpan(text: '${widget.question} '),
            TextSpan(
              text: widget.action,
              recognizer: _recognizer,
              style: AppText.bodyStrong.copyWith(color: AppColors.deepPurple),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
