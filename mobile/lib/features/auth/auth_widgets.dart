import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';

/// Building blocks shared by the sign-in, sign-up and new-password screens.

/// Label above + text field.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
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

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
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
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
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

class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
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

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

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

/// Turns a Supabase / network error into a short message for the user.
String authErrorMessage(BuildContext context, Object error) {
  final l = context.l10n;
  if (error is SocketException || error is AuthRetryableFetchException) {
    return l.authErrNetwork;
  }
  if (error is TimeoutException) return l.authErrTimeout;
  if (error is! AuthException) return l.commonError;
  final code = error.code ?? '';
  final msg = error.message.toLowerCase();
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
  if (code == 'same_password') return l.authErrSamePassword;
  if (code == 'weak_password') return l.authErrPasswordShort;
  if (code.startsWith('over_') || error.statusCode == '429') {
    return l.authErrRateLimit;
  }
  // Supabase could not send the email (usually wrong SMTP settings).
  if (msg.contains('sending') && msg.contains('email')) {
    return l.authErrEmailSend;
  }
  if (code == 'otp_expired' || code == 'flow_state_expired') {
    return l.authErrLinkExpired;
  }
  return error.message;
}

/// True when the error means "this email address is not confirmed yet".
bool isEmailNotConfirmed(Object error) =>
    error is AuthException &&
    (error.code == 'email_not_confirmed' ||
        error.message.toLowerCase().contains('not confirmed'));

/// Never let the spinner run forever: give up after 20 seconds.
extension AuthTimeout<T> on Future<T> {
  Future<T> withAuthTimeout() => timeout(const Duration(seconds: 20));
}

/// Number of digits in the email codes. Must match Supabase →
/// Authentication → Sign In / Providers → Email → "Email OTP Length".
const authCodeLength = 6;

/// Six boxes for the email code. One hidden text field receives the input,
/// so typing, deleting, pasting and the keyboard's code suggestion all work.
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.hasError = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final bool hasError;
  final bool enabled;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(CodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    return Stack(
      children: [
        Row(
          children: [
            for (var i = 0; i < authCodeLength; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _box(i, code)),
            ],
          ],
        ),
        // Invisible field covering the boxes: tapping anywhere focuses it.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              key: const ValueKey('code-field'),
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: authCodeLength,
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onChanged: (v) {
                if (v.length == authCodeLength) widget.onCompleted(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _box(int i, String code) {
    final filled = i < code.length;
    final active =
        _focus.hasFocus &&
        (i == code.length ||
            (i == authCodeLength - 1 && code.length == authCodeLength));
    final borderColor = widget.hasError
        ? AppColors.danger
        : active
        ? AppColors.deepPurple
        : filled
        ? AppColors.gold
        : AppColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: active ? 2 : 1.4),
      ),
      child: Text(
        filled ? code[i] : '',
        style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
      ),
    );
  }
}
