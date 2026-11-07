import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../features/auth/auth_widgets.dart';
import '../../widgets/common.dart';
import '../../widgets/page_top_bar.dart';

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// `2026-10-31`, used in the page address.
String journalDayParam(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Days in a row with a page, ending today (or yesterday if today is empty).
int journalStreak(Iterable<DateTime> days, {DateTime? today}) {
  final set = days.map(_dayOf).toSet();
  var d = _dayOf(today ?? DateTime.now());
  if (!set.contains(d)) d = d.subtract(const Duration(days: 1));
  var n = 0;
  while (set.contains(d)) {
    n++;
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return n;
}

/// "Mon Journal": today's page, this week, and all my pages.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late Future<List<JournalEntry>> _future = Repo.journalEntries();

  Future<void> _refresh() async {
    setState(() {
      _future = Repo.journalEntries();
    });
    try {
      await _future;
    } catch (_) {
      // Shown by AsyncView with a "Réessayer" button.
    }
  }

  Future<void> _open(DateTime day) async {
    await context.push('/journal/${journalDayParam(day)}');
    await _refresh();
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2024),
      lastDate: now,
      helpText: context.l10n.journalPickDay,
    );
    if (picked != null && mounted) await _open(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            PageTopBar(
              title: context.l10n.journalTitle,
              trailing: RoundIconButton(
                icon: Icons.calendar_month_rounded,
                onPressed: _pickDay,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: AsyncView<List<JournalEntry>>(
                  future: _future,
                  onRetry: _refresh,
                  builder: (context, entries) =>
                      JournalHomeBody(entries: entries, onOpen: _open),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JournalHomeBody extends StatelessWidget {
  const JournalHomeBody({
    super.key,
    required this.entries,
    required this.onOpen,
    this.today,
  });

  /// Pages with something written, newest first.
  final List<JournalEntry> entries;
  final ValueChanged<DateTime> onOpen;

  /// For tests; defaults to now.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = _dayOf(today ?? DateTime.now());
    final byDay = {
      for (final e in entries)
        if (e.date != null) _dayOf(e.date!): e,
    };
    final todayEntry = byDay[now];
    final streak = journalStreak(byDay.keys, today: now);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          l.journalSubtitle,
          textAlign: TextAlign.center,
          style: AppText.bodySmall.copyWith(color: AppColors.deepPurple),
        ),
        const SizedBox(height: 16),
        _TodayCard(day: now, entry: todayEntry, onOpen: () => onOpen(now)),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                l.journalThisWeek,
                style: AppText.titleMedium.copyWith(
                  color: AppColors.deepPurple,
                ),
              ),
            ),
            if (streak > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🔥 ${l.journalStreak(streak)}',
                  style: AppText.labelSmall.copyWith(color: AppColors.goldDark),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _WeekStrip(today: now, written: byDay.keys.toSet(), onOpen: onOpen),
        const SizedBox(height: 24),
        Text(
          l.journalPages,
          style: AppText.titleMedium.copyWith(color: AppColors.deepPurple),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Text('📖', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 10),
                Text(
                  l.journalEmpty,
                  textAlign: TextAlign.center,
                  style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          )
        else
          for (final e in entries)
            if (e.date != null) ...[
              _PageCard(entry: e, onTap: () => onOpen(_dayOf(e.date!))),
              const SizedBox(height: 10),
            ],
        const SizedBox(height: 16),
        _VerseCard(),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: AppColors.muted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l.journalPrivate,
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Four little bars: how many sections are written.
class JournalProgress extends StatelessWidget {
  const JournalProgress({super.key, required this.count, this.onDark = false});

  final int count;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    // Wrap: on narrow phones the label goes under the bars.
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 18,
                height: 5,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < count
                      ? AppColors.gold
                      : onDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
        Text(
          context.l10n.journalFilled(count),
          style: AppText.caption.copyWith(
            fontSize: 11,
            color: onDark ? Colors.white70 : AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.day,
    required this.entry,
    required this.onOpen,
  });

  final DateTime day;
  final JournalEntry? entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = entry;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l.commonToday} · ${formatDay(context, day)}',
            style: AppText.labelSmall.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 6),
          Text(
            l.journalTodayPrompt,
            style: AppText.titleLarge.copyWith(color: Colors.white),
          ),
          if (e != null) ...[
            const SizedBox(height: 8),
            Text(
              e.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            JournalProgress(count: e.filledCount, onDark: true),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: onOpen,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(
                e == null ? l.journalStart : l.journalContinue,
                style: AppText.labelLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.today,
    required this.written,
    required this.onOpen,
  });

  final DateTime today;
  final Set<DateTime> written;
  final ValueChanged<DateTime> onOpen;

  @override
  Widget build(BuildContext context) {
    final names = context.l10n.weekdaysShort.split(',');
    final monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: _DayDot(
                name: names[i],
                day: DateTime(monday.year, monday.month, monday.day + i),
                today: today,
                written: written,
                onOpen: onOpen,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.name,
    required this.day,
    required this.today,
    required this.written,
    required this.onOpen,
  });

  final String name;
  final DateTime day;
  final DateTime today;
  final Set<DateTime> written;
  final ValueChanged<DateTime> onOpen;

  @override
  Widget build(BuildContext context) {
    final future = day.isAfter(today);
    final isToday = day == today;
    final done = written.contains(day);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: future ? null : () => onOpen(day),
      child: Column(
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: AppText.caption.copyWith(
              fontSize: 11,
              color: isToday ? AppColors.deepPurple : AppColors.muted,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? AppColors.gold : Colors.transparent,
              shape: BoxShape.circle,
              border: done
                  ? null
                  : Border.all(
                      color: isToday ? AppColors.deepPurple : AppColors.border,
                      width: isToday ? 1.6 : 1,
                    ),
            ),
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    '${day.day}',
                    style: AppText.labelSmall.copyWith(
                      color: future
                          ? AppColors.border
                          : isToday
                          ? AppColors.deepPurple
                          : AppColors.ink,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({required this.entry, required this.onTap});

  final JournalEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = entry.date!;
    final weekday = l.weekdaysShort.split(',')[d.weekday - 1];
    final month = l.monthsShort.split(',')[d.month - 1];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      weekday,
                      maxLines: 1,
                      style: AppText.caption.copyWith(
                        fontSize: 10.5,
                        color: AppColors.deepPurple,
                      ),
                    ),
                    Text(
                      '${d.day}',
                      style: AppText.titleLarge.copyWith(
                        color: AppColors.deepPurple,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      month,
                      maxLines: 1,
                      style: AppText.caption.copyWith(
                        fontSize: 10.5,
                        color: AppColors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyMedium.copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: 8),
                    JournalProgress(count: entry.filledCount),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: AppColors.goldDark,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.journalVerse,
                  style: AppText.scripture.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  l.journalVerseRef,
                  style: AppText.scriptureRef.copyWith(
                    color: AppColors.goldDark,
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
