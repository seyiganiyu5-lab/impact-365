import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/locale_controller.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

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
        final res = await auth.signUp(
          email: email,
          password: _password.text,
          data: {
            'full_name': _name.text.trim(),
            'preferred_language': LocaleController.instance.languageCode,
          },
        );
        // No session yet = email confirmation is switched on in Supabase.
        if (res.session == null && mounted) {
          setState(() => _confirmationSentTo = email);
        }
      } else {
        await auth.signInWithPassword(email: email, password: _password.text);
      }
      // With a session, the router moves to /home automatically.
    } on AuthException catch (e) {
      setState(() => _error = _messageFor(e));
    } on SocketException {
      setState(() => _error = context.l10n.authErrNetwork);
    } catch (_) {
      setState(() => _error = context.l10n.commonError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(AuthException e) {
    final l = context.l10n;
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();
    if (e is AuthRetryableFetchException) return l.authErrNetwork;
    if (code == 'invalid_credentials' || msg.contains('invalid login')) {
      return l.authErrInvalidCredentials;
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        msg.contains('already registered')) {
      return l.authErrEmailTaken;
    }
    if (code == 'email_not_confirmed' || msg.contains('not confirmed')) {
      return l.authErrNotConfirmed;
    }
    return e.message;
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
              _RoundIconButton(
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
                    _Field(
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
                  _Field(
                    label: l.authEmail,
                    controller: _email,
                    hint: l.authEmailHint,
                    icon: Icons.mail_outline_rounded,
                    validator: _validEmail,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 18),
                  _PasswordField(
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
                    _PasswordField(
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

            _PrimaryButton(
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

/// Label above + text field.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.labelMedium.copyWith(color: AppColors.ink)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          autocorrect: false,
          autofillHints: autofillHints,
          textInputAction: TextInputAction.next,
          style: AppText.bodyLarge.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.hint,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppText.labelMedium.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _hidden,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: widget.autofillHints,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          style: AppText.bodyLarge.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hidden = !_hidden),
              icon: Icon(
                _hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(label, style: AppText.labelLarge),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.ink, size: 22),
        ),
      ),
    );
  }
}

/// Shown after sign-up when the account must be confirmed by email.
class _CheckEmailView extends StatelessWidget {
  const _CheckEmailView({required this.email, required this.onBack});

  final String email;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
            l.authCheckEmailText(email),
            textAlign: TextAlign.center,
            style: AppText.bodyMedium.copyWith(color: AppColors.muted),
          ),
          const Spacer(flex: 2),
          _PrimaryButton(
            label: l.authBackToSignIn,
            color: AppColors.deepPurple,
            busy: false,
            onPressed: onBack,
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
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _email.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = context.l10n.authErrNetwork);
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
            _Field(
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
            _PrimaryButton(
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
