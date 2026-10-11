import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

/// Everything the home page shows (public so tests can render it).
class HomeData {
  HomeData(this.profile, this.stats, this.devotions, this.bookmarked);
  final Profile profile;
  final UserStats stats;
  final List<Devotion> devotions;

  /// Ids of today's devotions the member saved (changes when they tap the
  /// bookmark).
  final Set<String> bookmarked;

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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Future<HomeData> _future = _load();
  bool _lastLoadFailed = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // If loading failed because the connection dropped, try again by
    // itself once the login session is refreshed (connection is back).
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (_lastLoadFailed &&
          (state.event == AuthChangeEvent.tokenRefreshed ||
              state.event == AuthChangeEvent.signedIn)) {
        _refresh();
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    super.dispose();
  }

  // ...and when the user comes back to the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _lastLoadFailed) _refresh();
  }

  Future<HomeData> _load() async {
    try {
      final results = await Future.wait([
        Repo.myProfile(),
        Repo.myStats(),
        Repo.todayDevotions(),
      ]);
      final devotions = results[2] as List<Devotion>;
      Set<String> bookmarked;
      try {
        bookmarked = await Repo.bookmarkedDevotionIds(
          devotions.map((d) => d.id).toList(),
        );
      } catch (_) {
        // Bookmarks are optional (e.g. the home migration isn't run yet).
        bookmarked = {};
      }
      _lastLoadFailed = false;
      return HomeData(
        results[0] as Profile,
        results[1] as UserStats,
        devotions,
        bookmarked,
      );
    } catch (_) {
      _lastLoadFailed = true;
      rethrow;
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _future = _load());
    try {
      await _future;
    } catch (_) {
      // Shown by AsyncView with a "Réessayer" button.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.deepPurple,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.deepPurple,
            backgroundColor: AppColors.gold,
            onRefresh: _refresh,
            child: AsyncView<HomeData>(
              future: _future,
              onRetry: _refresh,
              onDark: true,
              builder: (context, data) =>
                  HomeBody(data: data, onReturn: _refresh),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeBody extends StatelessWidget {
  const HomeBody({super.key, required this.data, required this.onReturn});

  final HomeData data;
  final VoidCallback onReturn;

  /// Day of the member's 365-day journey (starts again after a year).
  int get _journeyDay => ((data.stats.daysSinceJoin - 1) % 365) + 1;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = data.profile.firstName.isEmpty
        ? l.homeGreetingDefault
        : data.profile.firstName;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // The page scrolls behind the floating bar; the last cards still
      // end above it.
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        // Streak · logo · notifications
        Row(
          children: [
            _StreakChip(streak: data.stats.streak),
            const Spacer(),
            IconButton(
              onPressed: () => context.push('/inbox'),
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const _HomeLogo(),
        const SizedBox(height: 24),

        // Greeting: subtitle regular, tagline bold.
        Text(
          l.homeHello(name),
          style: AppText.bodyLarge.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          l.homeTagline,
          style: AppText.headline.copyWith(color: Colors.white, height: 1.2),
        ),
        const SizedBox(height: 18),
        _JourneyProgress(day: _journeyDay),
        const SizedBox(height: 20),

        _DevotionHero(
          devotion: data.current,
          initiallySaved:
              data.current != null &&
              data.bookmarked.contains(data.current!.id),
          onSavedChanged: (id, saved) =>
              saved ? data.bookmarked.add(id) : data.bookmarked.remove(id),
          onReturn: onReturn,
        ),
        const SizedBox(height: 16),
        _FaithJourneyCard(stats: data.stats),
        const SizedBox(height: 24),

        Text(
          l.homeToday,
          style: AppText.titleMedium.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TodayCard(
                emoji: '📖',
                label: l.homeYourWord,
                onTap: () => context.go('/word'),
              ),
              const SizedBox(width: 10),
              _TodayCard(
                emoji: '🙏',
                label: l.homeYourPrayer,
                onTap: () => context.go('/prayer'),
              ),
              const SizedBox(width: 10),
              _TodayCard(
                emoji: '🤝',
                label: l.homeYourImpact,
                onTap: () => context.go('/impact'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- header

class _HomeLogo extends StatelessWidget {
  const _HomeLogo();

  @override
  Widget build(BuildContext context) {
    // Shrinks instead of overflowing on very narrow phones / large text.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const BrandMark(size: 44),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'IMPACT-365',
                style: AppText.headline.copyWith(
                  color: Colors.white,
                  fontSize: 26,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '— ${context.l10n.appTagline} —',
                style: AppText.bodySmall.copyWith(color: AppColors.gold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final lit = streak > 0;
    return Tooltip(
      message: context.l10n.homeStreakTooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _showStreakSheet(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 22,
                  color: lit ? AppColors.gold : Colors.white54,
                ),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: AppText.labelLarge.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStreakSheet(BuildContext context) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.warmWhite,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.goldLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 46,
                  color: streak > 0 ? AppColors.goldDark : AppColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.homeStreakTitle(streak),
                textAlign: TextAlign.center,
                style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
              ),
              const SizedBox(height: 8),
              Text(
                l.homeStreakText,
                textAlign: TextAlign.center,
                style: AppText.bodyMedium.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyProgress extends StatelessWidget {
  const _JourneyProgress({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 20,
              color: AppColors.gold,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.homeDayCounter(day),
                style: AppText.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
            Text(
              l.homeToday,
              style: AppText.caption.copyWith(color: Colors.white54),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: day / 365,
            minHeight: 6,
            color: AppColors.gold,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------- devotion card

class _DevotionHero extends StatefulWidget {
  const _DevotionHero({
    required this.devotion,
    required this.initiallySaved,
    required this.onSavedChanged,
    required this.onReturn,
  });

  final Devotion? devotion;
  final bool initiallySaved;
  final void Function(String id, bool saved) onSavedChanged;
  final VoidCallback onReturn;

  @override
  State<_DevotionHero> createState() => _DevotionHeroState();
}

class _DevotionHeroState extends State<_DevotionHero> {
  late bool _saved = widget.initiallySaved;
  bool _saving = false;

  @override
  void didUpdateWidget(_DevotionHero old) {
    super.didUpdateWidget(old);
    if (old.devotion?.id != widget.devotion?.id) {
      _saved = widget.initiallySaved;
    }
  }

  Future<void> _toggleSaved() async {
    final devotion = widget.devotion;
    if (devotion == null || _saving) return;
    final next = !_saved;
    setState(() {
      _saved = next;
      _saving = true;
    });
    try {
      await Repo.setDevotionBookmark(devotion.id, next);
      widget.onSavedChanged(devotion.id, next);
      if (mounted) {
        context.toast(
          next
              ? context.l10n.homeBookmarkAdded
              : context.l10n.homeBookmarkRemoved,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saved = !next);
        context.toast(context.errorText(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _slotLabel(BuildContext context, DevotionSlot slot) {
    final l = context.l10n;
    return switch (slot) {
      DevotionSlot.morning => l.slotMorning,
      DevotionSlot.afternoon => l.slotAfternoon,
      DevotionSlot.night => l.slotNight,
    };
  }

  IconData _slotIcon(DevotionSlot slot) => switch (slot) {
    DevotionSlot.morning => Icons.wb_twilight_rounded,
    DevotionSlot.afternoon => Icons.wb_sunny_rounded,
    DevotionSlot.night => Icons.nightlight_round,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final devotion = widget.devotion;
    const fallback = AssetImage('assets/images/home_hero.jpg');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: AspectRatio(
          aspectRatio: 1.6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image chosen by the admin, or the default sunrise.
              if (devotion?.imageUrl != null)
                FadeInImage(
                  placeholder: fallback,
                  image: NetworkImage(devotion!.imageUrl!),
                  fit: BoxFit.cover,
                  imageErrorBuilder: (_, _, _) =>
                      const Image(image: fallback, fit: BoxFit.cover),
                )
              else
                const Image(image: fallback, fit: BoxFit.cover),
              // Darker at the bottom so the button always stands out.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x8C1A0B3D)],
                    stops: [0.45, 1],
                  ),
                ),
              ),
              if (devotion != null)
                Positioned(
                  top: 14,
                  left: 14,
                  child: _GlassChip(
                    icon: _slotIcon(devotion.slot),
                    label: _slotLabel(context, devotion.slot),
                  ),
                ),
              if (devotion != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Tooltip(
                    message: l.homeBookmarkTooltip,
                    child: Material(
                      color: AppColors.deepPurple.withValues(alpha: 0.55),
                      shape: CircleBorder(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _toggleSaved,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            _saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: _saved ? AppColors.gold : Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: devotion == null
                      ? _GlassChip(
                          icon: Icons.schedule_rounded,
                          label: l.homeDevotionSoon,
                        )
                      : _StartButton(
                          label: devotion.completed
                              ? l.homeReadAgain
                              : l.homeStartDevotion,
                          done: devotion.completed,
                          onPressed: () async {
                            await context.push('/devotion/${devotion.id}');
                            widget.onReturn();
                          },
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

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.label,
    required this.done,
    required this.onPressed,
  });

  final String label;
  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gold,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: const Color(0x66000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 13, 12, 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelMedium.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.deepPurple.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.labelSmall.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------- faith journey card

class _FaithJourneyCard extends StatelessWidget {
  const _FaithJourneyCard({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final letters = l.weekdaysShort
        .split(',')
        .map((d) => d.characters.first.toUpperCase())
        .toList();
    final today = DateTime.now().weekday; // 1 = Monday
    final active = stats.activeDaysThisWeek;
    final busiest = math.max(1, stats.weekActivity.reduce(math.max));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          // Ring ("6/7 Jours") + title and encouragement.
          Row(
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: CustomPaint(
                  painter: _WeekRingPainter(active: active),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$active/7',
                          style: AppText.titleMedium.copyWith(
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          l.homeWeekDays,
                          style: AppText.caption.copyWith(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.homeFaithJourney,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 12),

          // This week, Monday → Sunday: one bar per day, today in gold.
          SizedBox(
            height: 82,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _DayBar(
                      letter: letters[i],
                      count: stats.weekActivity[i],
                      fraction: stats.weekActivity[i] / busiest,
                      isToday: i + 1 == today,
                      isFuture: i + 1 > today,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.letter,
    required this.count,
    required this.fraction,
    required this.isToday,
    required this.isFuture,
  });

  final String letter;
  final int count;
  final double fraction;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    // Empty days keep a short stub so the week always reads as 7 days.
    const minHeight = 8.0;
    const maxHeight = 48.0;
    final height = count == 0
        ? minHeight
        : minHeight + (maxHeight - minHeight) * fraction;
    final color = isToday
        ? AppColors.gold
        : count > 0
        ? AppColors.lavender
        : Colors.white.withValues(alpha: isFuture ? 0.08 : 0.18);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          width: 16,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          letter,
          style: (isToday ? AppText.labelSmall : AppText.caption).copyWith(
            color: isToday ? AppColors.gold : Colors.white60,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        // Small dot under today.
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isToday ? AppColors.gold : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _WeekRingPainter extends CustomPainter {
  _WeekRingPainter({required this.active});

  final int active;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final ring = (Offset.zero & size).deflate(stroke / 2);
    const gap = 0.16;
    const sweep = 2 * math.pi / 7;
    for (var i = 0; i < 7; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = i < active
            ? AppColors.gold
            : Colors.white.withValues(alpha: 0.18);
      canvas.drawArc(
        ring,
        -math.pi / 2 + i * sweep + gap / 2,
        sweep - gap,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WeekRingPainter old) => old.active != active;
}

// -------------------------------------------------------------- today cards

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 40)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      // Shrinks slightly instead of cutting the word on
                      // small phones ("Ton impact").
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
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
        ),
      ),
    );
  }
}
