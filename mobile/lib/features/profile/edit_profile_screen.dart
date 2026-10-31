import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/page_top_bar.dart';
import 'profile_screen.dart';

/// Phone check: optional; digits with spaces, dots, dashes, brackets and
/// an optional leading +; 6 to 15 digits.
bool isValidPhone(String input) {
  final s = input.trim();
  if (s.isEmpty) return true;
  if (!RegExp(r'^\+?[0-9 ().\-]+$').hasMatch(s)) return false;
  final digits = s.replaceAll(RegExp(r'[^0-9]'), '').length;
  return digits >= 6 && digits <= 15;
}

/// "Informations personnelles".
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late Future<Profile> _future = Repo.myProfile();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: AsyncView<Profile>(
        future: _future,
        onRetry: () => setState(() {
          _future = Repo.myProfile();
        }),
        builder: (context, profile) => PersonalInfoView(
          profile: profile,
          email: user?.email,
          provider: user?.appMetadata['provider'] as String? ?? 'email',
          onSave: ({required fullName, required phone}) =>
              Repo.updateProfile(fullName: fullName, phone: phone),
        ),
      ),
    );
  }
}

class PersonalInfoView extends StatefulWidget {
  const PersonalInfoView({
    super.key,
    required this.profile,
    required this.email,
    required this.provider,
    required this.onSave,
  });

  final Profile profile;
  final String? email;

  /// How the member signs in: 'email', 'google' or 'apple'.
  final String provider;
  final Future<void> Function({required String fullName, required String phone})
  onSave;

  @override
  State<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<PersonalInfoView> {
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _phone = TextEditingController(text: widget.profile.phone);
  late String _savedName = _name.text.trim();
  late String _savedPhone = _phone.text.trim();
  String? _nameError;
  String? _phoneError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_changed);
    _phone.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _name.text.trim() != _savedName || _phone.text.trim() != _savedPhone;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final l = context.l10n;
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    setState(() {
      _nameError = name.isEmpty ? l.profileNameRequired : null;
      _phoneError = isValidPhone(phone) ? null : l.profilePhoneInvalid;
    });
    if (_nameError != null || _phoneError != null) return;
    setState(() {
      _saving = true;
    });
    try {
      await widget.onSave(fullName: name, phone: phone);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savedName = name;
        _savedPhone = phone;
      });
      context.toast(l.profileSaved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      context.toast(context.errorText(e));
    }
  }

  Future<void> _back() async {
    if (_dirty) {
      final l = context.l10n;
      final leave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.warmWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            l.journalUnsaved,
            style: AppText.titleMedium.copyWith(color: AppColors.deepPurple),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: Text(l.journalLeave),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepPurple,
                minimumSize: const Size(0, 44),
              ),
              child: Text(l.commonCancel),
            ),
          ],
        ),
      );
      if (leave != true) return;
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  String _roleLabel(BuildContext context) {
    final l = context.l10n;
    return switch (widget.profile.role) {
      'leader' => l.roleLeader,
      'pastor' => l.rolePastor,
      'admin' => l.roleAdmin,
      _ => l.roleMember,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.profile;
    final shownName = _name.text.trim().isEmpty
        ? (p.fullName ?? '')
        : _name.text.trim();
    final since = p.createdAt;
    final (methodIcon, methodLabel) = switch (widget.provider) {
      'google' => (Icons.g_mobiledata_rounded, 'Google'),
      'apple' => (Icons.apple_rounded, 'Apple'),
      _ => (Icons.mail_outline_rounded, l.profileMethodEmail),
    };

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: SafeArea(
        child: Column(
          children: [
            PageTopBar(title: l.profilePersonalInfo, onBack: _back),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  // Who I am.
                  Center(
                    child: ProfileAvatar(
                      name: shownName,
                      url: p.avatarUrl,
                      size: 92,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    shownName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.titleLarge.copyWith(
                      color: AppColors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (p.role != 'member')
                        _Chip(
                          text: _roleLabel(context),
                          color: AppColors.deepPurple,
                          background: AppColors.lavender,
                        ),
                      if (since != null)
                        _Chip(
                          text: l.profileMemberSince(
                            '${l.monthsShort.split(',')[since.toLocal().month - 1]}'
                            ' ${since.toLocal().year}',
                          ),
                          color: AppColors.goldDark,
                          background: AppColors.gold.withValues(alpha: 0.16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _SectionTitle(l.profileSectionIdentity),
                  const SizedBox(height: 10),
                  _Card(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FieldLabel(l.authFullName),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _name,
                          maxLength: 80,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          decoration: InputDecoration(
                            hintText: l.authFullNameHint,
                            counterText: '',
                            errorText: _nameError,
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                            ),
                          ),
                          onChanged: (_) {
                            if (_nameError != null) {
                              setState(() {
                                _nameError = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(l.phoneLabel),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _phone,
                          maxLength: 30,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          decoration: InputDecoration(
                            hintText: l.profilePhoneHint,
                            counterText: '',
                            errorText: _phoneError,
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          onChanged: (_) {
                            if (_phoneError != null) {
                              setState(() {
                                _phoneError = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  _SectionTitle(l.profileSectionSignIn),
                  const SizedBox(height: 10),
                  _Card(
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.alternate_email_rounded,
                          label: l.authEmail,
                          value: widget.email ?? '—',
                          note: l.profileEmailLocked,
                          trailing: const Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: AppColors.muted,
                          ),
                        ),
                        const Divider(height: 24, color: AppColors.border),
                        _InfoRow(
                          icon: methodIcon,
                          label: l.profileSignInMethod,
                          value: methodLabel,
                        ),
                        if (widget.provider == 'email') ...[
                          const Divider(height: 24, color: AppColors.border),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => context.push('/profile/password'),
                            child: _InfoRow(
                              icon: Icons.key_rounded,
                              label: l.profilePassword,
                              value: l.profilePasswordSub,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: AppColors.goldDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.profilePrivacyNote,
                          style: AppText.caption.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _dirty && !_saving ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.gold.withValues(
                      alpha: 0.4,
                    ),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 22),
                  label: Text(l.profileSave, style: AppText.labelLarge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: AppText.labelSmall.copyWith(color: color)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.titleMedium.copyWith(color: AppColors.deepPurple),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.labelMedium.copyWith(color: AppColors.ink),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? note;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.lavender,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.deepPurple, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyStrong.copyWith(color: AppColors.ink),
              ),
              if (note != null)
                Text(
                  note!,
                  style: AppText.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}
