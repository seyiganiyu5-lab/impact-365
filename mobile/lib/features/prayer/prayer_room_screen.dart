import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import 'add_prayer_sheet.dart';
import 'prayer_widgets.dart';

/// What the Prière tab shows (public so tests can render it).
class PrayerRoomData {
  PrayerRoomData(this.stats, this.community);
  final UserStats stats;

  /// The latest prayers shared by the community (3 at most).
  final List<CommunityPrayer> community;
}

/// "Ma Prayer Room" tab.
class PrayerRoomScreen extends StatefulWidget {
  const PrayerRoomScreen({super.key});

  @override
  State<PrayerRoomScreen> createState() => _PrayerRoomScreenState();
}

class _PrayerRoomScreenState extends State<PrayerRoomScreen> {
  late Future<PrayerRoomData> _future = _load();

  Future<PrayerRoomData> _load() async {
    final r = await Future.wait([
      Repo.myStats(),
      Repo.communityPrayers(limit: 3),
    ]);
    return PrayerRoomData(r[0] as UserStats, r[1] as List<CommunityPrayer>);
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
          child: AsyncView<PrayerRoomData>(
            future: _future,
            onRetry: _refresh,
            builder: (context, data) =>
                PrayerRoomBody(data: data, onChanged: _refresh),
          ),
        ),
      ),
    );
  }
}

class PrayerRoomBody extends StatelessWidget {
  const PrayerRoomBody({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final PrayerRoomData data;

  /// Called after something changed (new prayer, back from a list...).
  final VoidCallback onChanged;

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
        // Title, centred (like Parole).
        const SizedBox(height: 12),
        Text(
          l.prayerRoomTitle,
          textAlign: TextAlign.center,
          style: AppText.titleLarge.copyWith(
            color: AppColors.deepPurple,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.prayerShortVerse,
          textAlign: TextAlign.center,
          style: AppText.bodySmall.copyWith(color: AppColors.deepPurple),
        ),
        const SizedBox(height: 24),

        _PrayHeroCard(
          onAdd: () async {
            if (await showAddPrayerSheet(context)) onChanged();
          },
        ),
        const SizedBox(height: 14),

        // My prayers: one card, both counts, one page (with its two tabs).
        _MyPrayersCard(
          ongoing: s.prayersOpen,
          answered: s.prayersAnswered,
          onTap: () => open('/prayers/mine'),
        ),
        const SizedBox(height: 28),

        // Community wall preview.
        Row(
          children: [
            Expanded(
              child: Text(
                l.prayerCommunityTitle,
                style: AppText.titleMedium.copyWith(
                  color: AppColors.deepPurple,
                ),
              ),
            ),
            TextButton(
              onPressed: () => open('/prayers/community'),
              style: TextButton.styleFrom(foregroundColor: AppColors.goldDark),
              child: Text(l.prayerSeeAll, style: AppText.labelMedium),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (data.community.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              l.prayerCommunityEmpty,
              textAlign: TextAlign.center,
              style: AppText.bodySmall.copyWith(color: AppColors.muted),
            ),
          )
        else
          for (final p in data.community) ...[
            CommunityPrayerCard(prayer: p),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 20),

        // More.
        Text(
          l.prayerAlsoForYou,
          style: AppText.titleMedium.copyWith(color: AppColors.deepPurple),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ShortcutTile(
                  icon: Icons.edit_note_rounded,
                  title: l.prayerJournalShort,
                  subtitle: l.prayerJournalShortSub,
                  onTap: () => open('/journal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShortcutTile(
                  icon: Icons.shield_outlined,
                  title: l.sosTitle,
                  subtitle: l.prayerSosShortSub,
                  onTap: () => open('/sos'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Purple card inviting to pray, with the gold "add" button.
class _PrayHeroCard extends StatelessWidget {
  const _PrayHeroCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l.prayerHeroTitle,
                  style: AppText.titleLarge.copyWith(color: AppColors.gold),
                ),
              ),
              const SizedBox(width: 8),
              const Text('🙏', style: TextStyle(fontSize: 34)),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${l.prayerHeroText} ',
                  style: AppText.bodyMedium.copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextSpan(
                  text: l.prayerHeroRef,
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: Text(l.prayerAdd, style: AppText.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}

/// "3 · En cours" / "2 · Exaucées".
class _MyPrayersCard extends StatelessWidget {
  const _MyPrayersCard({
    required this.ongoing,
    required this.answered,
    required this.onTap,
  });

  final int ongoing;
  final int answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.lavender,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: AppColors.deepPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.prayerMineTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.titleSmall.copyWith(
                        color: AppColors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _Count(
                          icon: Icons.local_fire_department_rounded,
                          color: AppColors.deepPurple,
                          count: ongoing,
                          label: l.prayerOngoing,
                        ),
                        _Count(
                          icon: Icons.emoji_events_rounded,
                          color: AppColors.goldDark,
                          count: answered,
                          label: l.prayerAnsweredShort,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "🔥 3 En cours" inside the "Mes prières" card.
class _Count extends StatelessWidget {
  const _Count({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: AppText.labelLarge.copyWith(color: AppColors.ink),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppText.bodySmall.copyWith(color: AppColors.muted)),
      ],
    );
  }
}

/// One shared prayer with an "J'ai prié" toggle that works right here.
/// Small card: "Mon journal" / "Holy SOS".
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.deepPurple,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.gold, size: 26),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.titleSmall.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppText.caption.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
