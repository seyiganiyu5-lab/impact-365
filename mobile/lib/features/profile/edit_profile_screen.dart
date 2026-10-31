import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/page_top_bar.dart';
import 'avatar_picker.dart';
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
          onChangePhoto: (camera) =>
              pickAndUploadAvatar(context, camera: camera),
          onRemovePhoto: Repo.removeAvatar,
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
    required this.onChangePhoto,
    required this.onRemovePhoto,
  });

  final Profile profile;
  final String? email;

  /// How the member signs in: 'email', 'google' or 'apple'.
  final String provider;
  final Future<void> Function({required String fullName, required String phone})
  onSave;

  /// Picks (camera or gallery) and uploads a photo; returns its URL, or
  /// null when cancelled.
  final Future<String?> Function(bool camera) onChangePhoto;
  final Future<void> Function() onRemovePhoto;

  @override
  State<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<PersonalInfoView> {
  late final _name = TextEditingController(text: widget.profile.fullName);
  late String? _avatarUrl = widget.profile.avatarUrl;
  bool _photoBusy = false;
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

  Future<void> _photoMenu() async {
    final l = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.warmWhite,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Text(
                  l.photoChange,
                  style: AppText.titleMedium.copyWith(
                    color: AppColors.deepPurple,
                  ),
                ),
              ),
              _SheetAction(
                icon: Icons.photo_camera_outlined,
                label: l.photoCamera,
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              _SheetAction(
                icon: Icons.photo_library_outlined,
                label: l.photoGallery,
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              if (_avatarUrl != null)
                _SheetAction(
                  icon: Icons.delete_outline_rounded,
                  label: l.photoRemove,
                  danger: true,
                  onTap: () => Navigator.pop(ctx, 'remove'),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    setState(() {
      _photoBusy = true;
    });
    try {
      if (choice == 'remove') {
        await widget.onRemovePhoto();
        if (!mounted) return;
        setState(() {
          _avatarUrl = null;
        });
        context.toast(l.photoRemoved);
      } else {
        final url = await widget.onChangePhoto(choice == 'camera');
        if (url == null || !mounted) return;
        setState(() {
          _avatarUrl = url;
        });
        context.toast(l.photoUpdated);
      }
    } catch (e) {
      if (!mounted) return;
      context.toast(switch (e) {
        AvatarPickError(:final message) => message,
        StorageException(statusCode: '413') => l.photoTooBig,
        StorageException(statusCode: '415') => l.photoUnsupported,
        _ => context.errorText(e),
      });
    } finally {
      if (mounted) {
        setState(() {
          _photoBusy = false;
        });
      }
    }
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
                    child: _EditableAvatar(
                      name: shownName,
                      url: _avatarUrl,
                      busy: _photoBusy,
                      onTap: _photoBusy ? null : _photoMenu,
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

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.name,
    required this.url,
    required this.busy,
    required this.onTap,
  });

  final String name;
  final String? url;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.photoChange,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 100,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ProfileAvatar(name: name, url: url, size: 92),
              if (busy)
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.deepPurple,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.warmWhite, width: 3),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.deepPurple;
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: danger
              ? AppColors.danger.withValues(alpha: 0.1)
              : AppColors.lavender,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(
        label,
        style: AppText.bodyStrong.copyWith(
          color: danger ? AppColors.danger : AppColors.ink,
        ),
      ),
    );
  }
}
