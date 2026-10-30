import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../auth/auth_widgets.dart';

/// Profil → Mot de passe. A signed-in member changes their password:
/// 1. we email them a 6-digit code (Supabase "reauthentication"),
/// 2. they type the code and the new password.
/// The code proves it is really them, even if someone picks up their
/// unlocked phone ("Secure password change" in Supabase).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.email});

  /// Shown in the explanation; defaults to the signed-in account's email.
  final String? email;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const _cooldown = 60;

  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  int _wait = 0;
  Timer? _timer;

  String get _email =>
      widget.email ?? Supabase.instance.client.auth.currentUser?.email ?? '';

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_code, _password, _confirm]) {
      c.dispose();
    }
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

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.reauthenticate().withAuthTimeout();
      if (!mounted) return;
      setState(() => _codeSent = true);
      _startCooldown();
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_code.text.length != authCodeLength) {
      setState(() => _error = context.l10n.authErrCodeInvalid);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth
          .updateUser(
            UserAttributes(password: _password.text, nonce: _code.text),
          )
          .withAuthTimeout();
      if (!mounted) return;
      context.toast(context.l10n.changePwDone);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final wrongCode =
          e is AuthException &&
          (e.code == 'reauthentication_not_valid' ||
              e.code == 'reauthentication_needed' ||
              e.message.toLowerCase().contains('nonce'));
      setState(() {
        _error = wrongCode
            ? context.l10n.authErrCodeInvalid
            : authErrorMessage(context, e);
        if (wrongCode) _code.clear();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.lavender,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.deepPurple,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l.changePwTitle,
                  style: AppText.headline.copyWith(color: AppColors.deepPurple),
                ),
                const SizedBox(height: 8),
                Text(
                  l.changePwIntro(_email),
                  style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 28),
                if (!_codeSent)
                  AuthButton(
                    label: l.changePwSendCode,
                    color: AppColors.deepPurple,
                    busy: _busy,
                    onPressed: _sendCode,
                  )
                else ...[
                  Text(
                    l.changePwCodeLabel,
                    style: AppText.labelMedium.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  CodeInput(
                    controller: _code,
                    enabled: !_busy,
                    hasError: _error == l.authErrCodeInvalid,
                    onCompleted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _wait > 0 || _busy ? null : _sendCode,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.deepPurple,
                      ),
                      child: Text(
                        _wait > 0 ? l.authResendIn(_wait) : l.authResend,
                        style: AppText.labelMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PasswordField(
                    label: l.newPasswordLabel,
                    controller: _password,
                    hint: l.authPasswordHint,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => validateNewPassword(context, v),
                  ),
                  const SizedBox(height: 18),
                  PasswordField(
                    label: l.authConfirmPassword,
                    controller: _confirm,
                    hint: l.authConfirmPasswordHint,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l.authErrRequired;
                      return v == _password.text
                          ? null
                          : l.authErrPasswordMatch;
                    },
                  ),
                  const SizedBox(height: 28),
                  AuthButton(
                    label: l.newPasswordSave,
                    color: AppColors.deepPurple,
                    busy: _busy,
                    onPressed: _save,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: AppText.bodySmall.copyWith(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
