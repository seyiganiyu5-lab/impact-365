import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/legal_links.dart';
import '../../core/locale_controller.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import 'delete_account_dialog.dart';

/// Version shown at the bottom of Profil (keep in line with pubspec.yaml).
const appVersion = '1.0.0';

/// What the Profil tab shows (public so tests can render it).
class ProfileData {
  ProfileData(this.profile, this.stats, {this.email});
  final Profile profile;
  final UserStats stats;
  final String? email;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileData> _future = _load();

  Future<ProfileData> _load() async {
    final r = await Future.wait([Repo.myProfile(), Repo.myStats()]);
    return ProfileData(
      r[0] as Profile,
      r[1] as UserStats,
      email: Supabase.instance.client.auth.currentUser?.email,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    try {
      await _future;
    } catch (_) {
      // Shown by AsyncView with a "Réessayer" button.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        // Content scrolls under the floating menu bar (like Home).
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: AsyncView<ProfileData>(
            future: _future,
            onRetry: _refresh,
            builder: (context, data) => ProfileBody(
              data: data,
              onChanged: _refresh,
              onSignOut: () => Supabase.instance.client.auth.signOut(),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({
    super.key,
    required this.data,
    required this.onChanged,
    required this.onSignOut,
  });

  final ProfileData data;

  /// Called when coming back from a page that may have changed something.
  final VoidCallback onChanged;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = data.stats;

    Future<void> open(String path) async {
      await context.push(path);
      onChanged();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Room at the end so the last item clears the floating menu bar.
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const SizedBox(height: 12),
        Text(
          l.profileTitle,
          textAlign: TextAlign.center,
          style: AppText.titleLarge.copyWith(
            color: AppColors.deepPurple,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.profileSubtitle,
          textAlign: TextAlign.center,
          style: AppText.bodySmall.copyWith(color: AppColors.deepPurple),
        ),
        const SizedBox(height: 22),

        _IdentityCard(
          profile: data.profile,
          email: data.email,
          days: s.daysSinceJoin,
          onEdit: () => open('/profile/edit'),
        ),
        const SizedBox(height: 14),

        // Four small counters.
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                emoji: '🔥',
                value: s.streak,
                label: l.profileStreak,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                emoji: '📖',
                value: s.devotionsCompleted,
                label: l.profileDevotions,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                emoji: '🎯',
                value: s.challengesCompleted,
                label: l.profileImpacts,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                emoji: '🏆',
                value: s.prayersAnswered,
                label: l.profileAnswered,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _Section(
          title: l.profileSectionAccount,
          rows: [
            _Row(
              icon: Icons.person_outline_rounded,
              label: l.profilePersonalInfo,
              onTap: () => open('/profile/edit'),
            ),
            _Row(
              icon: Icons.lock_outline_rounded,
              label: l.profilePassword,
              onTap: () => open('/profile/password'),
            ),
            _Row(
              icon: Icons.translate_rounded,
              label: l.profileLanguage,
              value: LocaleController.displayName(
                LocaleController.instance.languageCode,
              ),
              onTap: () => open('/profile/language'),
            ),
          ],
        ),
        _Section(
          title: l.profileSectionCommunity,
          rows: [
            _Row(
              icon: Icons.chat_bubble_outline_rounded,
              label: l.profileMessages,
              onTap: () => open('/inbox'),
            ),
            _Row(
              icon: Icons.shield_outlined,
              label: l.sosTitle,
              onTap: () => open('/sos'),
            ),
          ],
        ),
        _Section(
          title: l.profileSectionApp,
          rows: [
            _Row(
              icon: Icons.slideshow_outlined,
              label: l.onbReplay,
              onTap: () => context.go('/onboarding'),
            ),
            _Row(
              icon: Icons.privacy_tip_outlined,
              label: l.profilePrivacy,
              onTap: () async {
                final ok = await openWebPage(
                  LegalLinks.privacy(LocaleController.instance.languageCode),
                );
                if (!ok && context.mounted) context.toast(l.commonError);
              },
            ),
            _Row(
              icon: Icons.info_outline_rounded,
              label: l.profileAbout,
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'IMPACT-365',
                applicationVersion: appVersion,
                applicationIcon: const BrandMark(size: 40),
                children: [Text(l.profileAboutText)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              backgroundColor: Colors.white,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(l.profileSignOut, style: AppText.labelLarge),
          ),
        ),
        const SizedBox(height: 6),
        // Required by Apple and Google: members can delete their account.
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
        Text(
          l.profileVersion(appVersion),
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.warmWhite,
        title: Text(
          l.profileSignOutTitle,
          style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
        ),
        content: Text(
          l.profileSignOutText,
          style: AppText.bodyMedium.copyWith(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.profileSignOut),
          ),
        ],
      ),
    );
    if (ok == true) await onSignOut();
  }
}

// ---------------------------------------------------------------- identity

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.profile,
    required this.email,
    required this.days,
    required this.onEdit,
  });

  final Profile profile;
  final String? email;
  final int days;
  final VoidCallback onEdit;

  String? _roleLabel(BuildContext context) => switch (profile.role) {
    'leader' => context.l10n.roleLeader,
    'pastor' => context.l10n.rolePastor,
    'admin' => context.l10n.roleAdmin,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = (profile.fullName ?? '').trim().isEmpty
        ? l.homeGreetingDefault
        : profile.fullName!.trim();
    final role = _roleLabel(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 18),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(name: name, url: profile.avatarUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.titleLarge.copyWith(color: Colors.white),
                ),
                if ((email ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Pill(
                      text: l.profileImpacterSince(days),
                      color: AppColors.gold,
                    ),
                    if (role != null)
                      _Pill(text: role, color: Colors.white, outlined: true),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l.profileEdit,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Round photo (or initials) with a gold ring.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.url,
    this.size = 68,
  });

  final String name;
  final String? url;
  final double size;

  String get _initials {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.037),
      decoration: const BoxDecoration(
        color: AppColors.gold,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        backgroundColor: AppColors.goldLight,
        foregroundImage: url == null ? null : NetworkImage(url!),
        // Photo can't load (offline, removed): the initials stay visible.
        onForegroundImageError: url == null ? null : (_, _) {},
        child: Text(
          _initials,
          style: AppText.titleLarge.copyWith(
            color: AppColors.deepPurple,
            fontSize: size * 0.32,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.outlined = false});

  final String text;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? null : color.withValues(alpha: 0.18),
        border: outlined
            ? Border.all(color: color.withValues(alpha: 0.6))
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppText.labelSmall.copyWith(
          color: outlined ? color : AppColors.goldLight,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ stats

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: AppText.titleMedium.copyWith(color: AppColors.deepPurple),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                color: AppColors.muted,
                fontSize: 10.5,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------- grouped settings

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: AppText.labelSmall.copyWith(
                color: AppColors.muted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 56,
                      color: AppColors.border,
                    ),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.deepPurple, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppText.bodyMedium.copyWith(color: AppColors.ink),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: AppText.bodySmall.copyWith(color: AppColors.muted),
                ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
