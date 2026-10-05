import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

class _HomeData {
  _HomeData(this.profile, this.stats, this.devotions);
  final Profile profile;
  final UserStats stats;
  final List<Devotion> devotions;

  /// The devotion for the current time of day, or the latest one available.
  Devotion? get current {
    if (devotions.isEmpty) return null;
    final slot = DevotionSlot.current();
    return devotions.where((d) => d.slot == slot).firstOrNull ?? devotions.last;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future = _load();

  Future<_HomeData> _load() async {
    final results = await Future.wait([
      Repo.myProfile(),
      Repo.myStats(),
      Repo.todayDevotions(),
    ]);
    return _HomeData(
      results[0] as Profile,
      results[1] as UserStats,
      results[2] as List<Devotion>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: AsyncView<_HomeData>(
            future: _future,
            onRetry: _refresh,
            builder: (context, data) =>
                _HomeBody(data: data, onReturn: _refresh),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.data, required this.onReturn});

  final _HomeData data;
  final VoidCallback onReturn;

  int get _dayOfYear {
    final now = DateTime.now();
    return now.difference(DateTime(now.year)).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final devotion = data.current;
    final name = data.profile.firstName.isEmpty
        ? l.homeGreetingDefault
        : data.profile.firstName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(child: Center(child: BrandLogo())),
            IconButton(
              onPressed: () => context.push('/inbox'),
              icon: const Icon(Icons.notifications_none_rounded, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(l.homeGreeting(name), style: AppText.headline),
        const SizedBox(height: 6),
        Text(
          l.homeSubtitle,
          style: AppText.bodyLarge.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  Text(l.homeDayCounter(_dayOfYear), style: AppText.titleSmall),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 36, color: AppColors.border),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.homeCurrentStreak,
                  style: AppText.bodySmall.copyWith(color: AppColors.muted),
                ),
                Text(l.daysCount(data.stats.streak), style: AppText.titleSmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (devotion == null)
          AppCard(child: EmptyState(message: l.homeNoDevotion))
        else ...[
          _VerseCard(devotion: devotion, onReturn: onReturn),
          if ((devotion.theme ?? '').isNotEmpty)
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.homeThemeOfDay,
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          devotion.theme!,
                          style: AppText.titleMedium.copyWith(
                            color: AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.flag_rounded,
                    color: AppColors.gold,
                    size: 40,
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 8),
        Text(l.homeToday, style: AppText.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickCard(
              icon: Icons.menu_book_rounded,
              title: l.homeYourWord,
              subtitle: l.homeDiscover,
              onTap: () => context.go('/word'),
            ),
            const SizedBox(width: 10),
            _QuickCard(
              icon: Icons.volunteer_activism_rounded,
              title: l.homeYourPrayer,
              subtitle: l.homePray,
              onTap: () => context.go('/prayer'),
            ),
            const SizedBox(width: 10),
            _QuickCard(
              icon: Icons.track_changes_rounded,
              title: l.homeYourImpact,
              subtitle: l.homeAct,
              onTap: () => context.go('/impact'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _FaithJourneyCard(stats: data.stats),
      ],
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.devotion, required this.onReturn});

  final Devotion devotion;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppColors.purpleGradient,
        image: devotion.imageUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(devotion.imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  AppColors.purpleDark.withValues(alpha: 0.55),
                  BlendMode.darken,
                ),
              ),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.homeVerseOfDay,
                  style: AppText.titleSmall.copyWith(color: AppColors.gold),
                ),
              ),
              const Icon(Icons.wb_sunny_rounded, color: AppColors.goldLight),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            devotion.verseText,
            style: AppText.scriptureLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            devotion.verseReference,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          GoldButton(
            label: l.homeStartDevotion,
            onPressed: () async {
              await context.push('/devotion/${devotion.id}');
              onReturn();
            },
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
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
    return Expanded(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Icon(icon, size: 40, color: AppColors.purple)),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.labelMedium,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: AppText.labelSmall.copyWith(color: AppColors.muted),
                  ),
                ),
                const Icon(
                  Icons.arrow_circle_right_outlined,
                  color: AppColors.gold,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FaithJourneyCard extends StatelessWidget {
  const _FaithJourneyCard({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final days = l.weekdaysShort.split(',');
    final today = DateTime.now().weekday; // 1 = Monday
    return AppCard(
      gradient: AppColors.purpleGradient,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (stats.streak % 30) / 30,
                  strokeWidth: 5,
                  color: AppColors.gold,
                  backgroundColor: Colors.white24,
                ),
                Text(
                  '${stats.streak}',
                  style: AppText.titleLarge.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.homeFaithJourney,
                  style: AppText.titleSmall.copyWith(color: AppColors.gold),
                ),
                const SizedBox(height: 4),
                Text(
                  l.homeFaithJourneyText,
                  style: AppText.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 1; i <= 7; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 10.0 + i * 4,
                        decoration: BoxDecoration(
                          color: i == today
                              ? AppColors.gold
                              : i < today
                              ? AppColors.purpleLight
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        days[i - 1].characters.first,
                        style: AppText.labelSmall.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
