import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_links.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';

/// "Choose a new password" — opened from the password-reset email link.
/// Supabase has already signed the user in with a temporary recovery
/// session; we only need to set the new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: _password.text))
          .withAuthTimeout();
      AuthFlow.recoveryPending = false;
      if (!mounted) return;
      context.toast(context.l10n.newPasswordDone);
      context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Leave without changing the password: sign out of the recovery session.
  Future<void> _cancel() async {
    AuthFlow.recoveryPending = false;
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoundIconButton(icon: Icons.close_rounded, onPressed: _cancel),
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
                  l.newPasswordTitle,
                  style: AppText.headline.copyWith(color: AppColors.deepPurple),
                ),
                const SizedBox(height: 8),
                Text(
                  l.newPasswordSubtitle,
                  style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 32),
                PasswordField(
                  label: l.newPasswordLabel,
                  controller: _password,
                  hint: l.authPasswordHint,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) {
                    if (v == null || v.isEmpty) return l.authErrRequired;
                    return v.length < 6 ? l.authErrPasswordShort : null;
                  },
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
                    return v == _password.text ? null : l.authErrPasswordMatch;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: AppText.bodySmall.copyWith(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 28),
                AuthButton(
                  label: l.newPasswordSave,
                  color: AppColors.deepPurple,
                  busy: _busy,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
