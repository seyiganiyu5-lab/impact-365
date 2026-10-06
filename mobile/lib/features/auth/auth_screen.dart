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

  /// Email a 6-digit code was sent to: after sign-up (confirm the account)
  /// or after "forgot password" ([_codeForRecovery]).
  String? _codeSentTo;
  bool _codeForRecovery = false;

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
          setState(() {
            _codeSentTo = email;
            _codeForRecovery = false;
          });
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
        // Show the code view; the user can ask for a new code there.
        setState(() {
          _codeSentTo = email;
          _codeForRecovery = false;
        });
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
              child: _codeSentTo != null
                  ? _VerifyCodeView(
                      key: ValueKey('code-$_codeForRecovery'),
                      email: _codeSentTo!,
                      recovery: _codeForRecovery,
                      onBack: () => setState(() {
                        _codeSentTo = null;
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
    final sentTo = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.warmWhite,
      builder: (_) => _ResetPasswordSheet(initialEmail: _email.text.trim()),
    );
    if (sentTo != null && context.mounted) {
      context.toast(context.l10n.authResetSent);
      setState(() {
        _error = null;
        _codeSentTo = sentTo;
        _codeForRecovery = true;
      });
    }
  }
}

// ---------------------------------------------------------------- widgets

/// Enter the 6-digit code received by email.
///
/// - Sign-up ([recovery] false): confirms the account and signs the user in;
///   the router then opens the home screen.
/// - Forgot password ([recovery] true): signs the user in with a recovery
///   session; the router then opens "Nouveau mot de passe".
class _VerifyCodeView extends StatefulWidget {
  const _VerifyCodeView({
    super.key,
    required this.email,
    required this.recovery,
    required this.onBack,
  });

  final String email;
  final bool recovery;
  final VoidCallback onBack;

  @override
  State<_VerifyCodeView> createState() => _VerifyCodeViewState();
}

class _VerifyCodeViewState extends State<_VerifyCodeView> {
  static const _cooldown = 60;

  final _code = TextEditingController();

  /// Seconds before "Resend" is allowed again (Supabase rate-limits emails).
  int _wait = _cooldown;
  Timer? _timer;
  bool _sending = false;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
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

  Future<void> _verify() async {
    final token = _code.text;
    if (token.length != authCodeLength || _verifying) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _error = null;
    });
    // Set before verifying so the router sends the new recovery session to
    // "Nouveau mot de passe" rather than to the home screen.
    if (widget.recovery) AuthFlow.recoveryPending = true;
    try {
      await Supabase.instance.client.auth
          .verifyOTP(
            type: widget.recovery ? OtpType.recovery : OtpType.signup,
            email: widget.email,
            token: token,
          )
          .withAuthTimeout();
      // Signed in: the router moves on by itself.
    } catch (e) {
      AuthFlow.recoveryPending = false;
      if (!mounted) return;
      final wrongCode =
          e is AuthException &&
          (e.code == 'otp_expired' ||
              e.code == 'invalid_otp' ||
              e.message.toLowerCase().contains('token'));
      setState(() {
        _error = wrongCode
            ? context.l10n.authErrCodeInvalid
            : authErrorMessage(context, e);
        _code.clear();
      });
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    final auth = Supabase.instance.client.auth;
    try {
      if (widget.recovery) {
        await auth
            .resetPasswordForEmail(
              widget.email,
              redirectTo: AuthLinks.resetPassword,
            )
            .withAuthTimeout();
      } else {
        await auth
            .resend(
              type: OtpType.signup,
              email: widget.email,
              emailRedirectTo: AuthLinks.emailConfirmed,
            )
            .withAuthTimeout();
      }
      if (!mounted) return;
      context.toast(context.l10n.authResent);
      setState(() {
        _error = null;
        _code.clear();
      });
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
    final canResend = _wait <= 0 && !_sending && !_verifying;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: widget.onBack,
          ),
          const SizedBox(height: 28),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.recovery
                  ? Icons.lock_reset_rounded
                  : Icons.mark_email_read_outlined,
              color: AppColors.deepPurple,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.recovery ? l.authCodeResetTitle : l.authCheckEmailTitle,
            style: AppText.headline.copyWith(color: AppColors.deepPurple),
          ),
          const SizedBox(height: 8),
          Text(
            widget.recovery
                ? l.authCodeResetText(widget.email)
                : l.authCheckEmailText(widget.email),
            style: AppText.bodyMedium.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 32),
          CodeInput(
            controller: _code,
            hasError: _error != null,
            enabled: !_verifying,
            onCompleted: (_) => _verify(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: AppText.bodySmall.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l.authCheckSpam,
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          AuthButton(
            label: l.authCodeVerify,
            color: AppColors.deepPurple,
            busy: _verifying,
            onPressed: _verify,
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
      final email = _email.text.trim();
      await Supabase.instance.client.auth
          .resetPasswordForEmail(email, redirectTo: AuthLinks.resetPassword)
          .withAuthTimeout();
      if (mounted) Navigator.pop(context, email);
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
