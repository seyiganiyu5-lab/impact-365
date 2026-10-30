import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/locale_controller.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

class _ProfileData {
  _ProfileData(this.profile, this.stats);
  final Profile profile;
  final UserStats stats;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _future = _load();

  Future<_ProfileData> _load() async {
    final r = await Future.wait([Repo.myProfile(), Repo.myStats()]);
    return _ProfileData(r[0] as Profile, r[1] as UserStats);
  }

  void _refresh() => setState(() {
    _future = _load();
  });

  Future<void> _open(String path) async {
    await context.push(path);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: AsyncView<_ProfileData>(
          future: _future,
          onRetry: _refresh,
          builder: (context, data) {
            final p = data.profile;
            final s = data.stats;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                ScreenTitle(title: l.profileTitle, subtitle: l.profileSubtitle),
                const SizedBox(height: 20),
                AppCard(
                  gradient: AppColors.purpleGradient,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: p.avatarUrl == null
                            ? null
                            : NetworkImage(p.avatarUrl!),
                        child: p.avatarUrl == null
                            ? const BrandMark(size: 50)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.fullName ?? l.homeGreetingDefault,
                              style: AppText.titleLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.profileImpacterSince(s.daysSinceJoin),
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.gold,
                              ),
                            ),
                            const Divider(color: Colors.white24, height: 20),
                            Text.rich(
                              TextSpan(
                                style: AppText.bodySmall.copyWith(
                                  color: Colors.white,
                                ),
                                children: [
                                  TextSpan(
                                    text: l.profileVerse,
                                    style: AppText.scripture.copyWith(
                                      fontSize: 14,
                                      height: 20 / 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ${l.profileVerseRef}',
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppCard(
                  child: Row(
                    children: [
                      _Stat(
                        Icons.local_fire_department_rounded,
                        s.streak,
                        l.profileStreak,
                      ),
                      _Stat(
                        Icons.track_changes_rounded,
                        s.challengesCompleted,
                        l.profileImpacts,
                      ),
                      _Stat(
                        Icons.menu_book_rounded,
                        s.devotionsCompleted,
                        l.profileDevotions,
                      ),
                      _Stat(
                        Icons.emoji_events_outlined,
                        s.prayersAnswered,
                        l.profileAnswered,
                      ),
                    ],
                  ),
                ),
                MenuTile(
                  icon: Icons.person_outline,
                  title: l.profilePersonalInfo,
                  subtitle: l.profilePersonalInfoSub,
                  onTap: () => _open('/profile/edit'),
                ),
                MenuTile(
                  icon: Icons.translate_rounded,
                  title: l.profileLanguage,
                  subtitle: LocaleController.displayName(
                    LocaleController.instance.languageCode,
                  ),
                  onTap: () => _open('/profile/language'),
                ),
                MenuTile(
                  icon: Icons.lock_outline_rounded,
                  title: l.profilePassword,
                  subtitle: l.profilePasswordSub,
                  onTap: () => _open('/profile/password'),
                ),
                MenuTile(
                  icon: Icons.chat_bubble_outline,
                  title: l.profileMessages,
                  subtitle: l.profileMessagesSub,
                  onTap: () => _open('/inbox'),
                ),
                MenuTile(
                  icon: Icons.favorite_border,
                  title: l.profileSos,
                  subtitle: l.profileSosSub,
                  badge: l.newBadge,
                  onTap: () => _open('/sos'),
                ),
                MenuTile(
                  icon: Icons.slideshow_outlined,
                  title: l.onbReplay,
                  onTap: () => context.go('/onboarding'),
                ),
                MenuTile(
                  icon: Icons.info_outline,
                  title: l.profileAbout,
                  subtitle: l.profileAboutSub,
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Impact-365',
                    applicationVersion: '1.0.0',
                    applicationIcon: const BrandMark(size: 40),
                    children: [Text(l.profileAboutText)],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    backgroundColor: AppColors.beige,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Supabase.instance.client.auth.signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(l.profileSignOut),
                ),
                const SizedBox(height: 12),
                // Required by Apple and Google: members can delete their
                // account from the app.
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () => showDeleteAccountDialog(context),
                  child: Text(
                    l.profileDeleteAccount,
                    style: AppText.bodySmall.copyWith(
                      decoration: TextDecoration.underline,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label);

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          IconBubble(icon: icon, light: true, size: 40),
          const SizedBox(height: 8),
          Text('$value', style: AppText.titleLarge),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// "Supprimer mon compte": explains what is erased, then asks the member to
/// type a word (SUPPRIMER / DELETE) so it cannot happen by accident.
Future<void> showDeleteAccountDialog(BuildContext context) async {
  final deleted = await showDialog<bool>(
    context: context,
    builder: (_) => const _DeleteAccountDialog(),
  );
  if (deleted == true && context.mounted) {
    context.toast(context.l10n.deleteDone);
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _word = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _word.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Repo.deleteMyAccount();
      // The account no longer exists: clear the session on this phone.
      try {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is PostgrestException && e.message == 'last_admin'
            ? context.l10n.deleteErrLastAdmin
            : context.errorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ready = _word.text.trim().toUpperCase() == l.deleteWord;
    return AlertDialog(
      backgroundColor: AppColors.warmWhite,
      title: Text(
        l.deleteTitle,
        style: AppText.titleLarge.copyWith(color: AppColors.danger),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.deleteText,
              style: AppText.bodyMedium.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 16),
            Text(
              l.deleteTypeToConfirm(l.deleteWord),
              style: AppText.bodySmall.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _word,
              enabled: !_busy,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(hintText: l.deleteWord),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppText.bodySmall.copyWith(color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: ready && !_busy ? _delete : null,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l.deleteConfirm),
        ),
      ],
    );
  }
}
