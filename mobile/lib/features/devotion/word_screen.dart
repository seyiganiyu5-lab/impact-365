import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

/// "Parole" tab: the three devotions of the day (Matin / Midi / Soir).
class WordScreen extends StatefulWidget {
  const WordScreen({super.key});

  @override
  State<WordScreen> createState() => _WordScreenState();
}

class _WordScreenState extends State<WordScreen> {
  late Future<List<Devotion>> _future = Repo.recentDevotions();

  Future<void> _refresh() async {
    setState(() {
      _future = Repo.recentDevotions();
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
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: AsyncView<List<Devotion>>(
            future: _future,
            onRetry: _refresh,
            builder: (context, all) =>
                WordBody(devotions: all, onReturn: _refresh),
          ),
        ),
      ),
    );
  }
}

/// The page itself (public so tests can render it with sample data).
class WordBody extends StatelessWidget {
  const WordBody({super.key, required this.devotions, required this.onReturn});

  /// Today's and recent devotions.
  final List<Devotion> devotions;
  final VoidCallback onReturn;

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = devotions.where((d) => _isToday(d.date)).toList();
    final past = devotions.where((d) => !_isToday(d.date)).toList();
    final now = DevotionSlot.current();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // Title, centred, with the info button on the right.
        Row(
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                l.wordTitle,
                textAlign: TextAlign.center,
                style: AppText.titleLarge.copyWith(
                  color: AppColors.deepPurple,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: l.wordInfoTooltip,
              onPressed: () => _showInfo(context),
              icon: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.deepPurple,
                size: 32,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            l.wordVerse,
            textAlign: TextAlign.center,
            style: AppText.bodySmall.copyWith(color: AppColors.deepPurple),
          ),
        ),
        const SizedBox(height: 28),
        for (final slot in DevotionSlot.values) ...[
          _SlotCard(
            slot: slot,
            devotion: today.where((d) => d.slot == slot).firstOrNull,
            isNow: slot == now,
            onReturn: onReturn,
          ),
          const SizedBox(height: 14),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () => _showHistory(context, past),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.deepPurple,
              ),
              icon: const Icon(Icons.history_rounded, size: 20),
              label: Text(l.wordHistory, style: AppText.labelMedium),
            ),
          ),
        ],
      ],
    );
  }

  void _showInfo(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.wordInfoTitle,
                style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
              ),
              const SizedBox(height: 10),
              Text(
                l.wordInfoText,
                style: AppText.bodyMedium.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              for (final slot in DevotionSlot.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(slotIcon(slot), color: AppColors.gold, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        wordSlotTitle(context, slot),
                        style: AppText.titleSmall,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          wordSlotText(context, slot),
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory(BuildContext context, List<Devotion> past) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.warmWhite,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              l.wordHistory,
              style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
            ),
            const SizedBox(height: 12),
            for (final d in past)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(slotIcon(d.slot), color: AppColors.gold),
                title: Text(
                  '${formatDay(context, d.date)} · ${wordSlotTitle(context, d.slot)}',
                  style: AppText.bodyStrong,
                ),
                subtitle: Text(
                  d.theme?.isNotEmpty ?? false ? d.theme! : d.verseReference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySmall.copyWith(color: AppColors.muted),
                ),
                trailing: d.completed
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.gold,
                      )
                    : const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await context.push('/devotion/${d.id}');
                  onReturn();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// "Matin" / "Midi" / "Soir" as written on the Parole page.
String wordSlotTitle(BuildContext context, DevotionSlot slot) => switch (slot) {
  DevotionSlot.morning => context.l10n.wordMorning,
  DevotionSlot.afternoon => context.l10n.wordMidday,
  DevotionSlot.night => context.l10n.wordEvening,
};

String wordSlotText(BuildContext context, DevotionSlot slot) => switch (slot) {
  DevotionSlot.morning => context.l10n.wordMorningText,
  DevotionSlot.afternoon => context.l10n.wordMiddayText,
  DevotionSlot.night => context.l10n.wordEveningText,
};

String slotLabel(BuildContext context, DevotionSlot slot) => switch (slot) {
  DevotionSlot.morning => context.l10n.slotMorning,
  DevotionSlot.afternoon => context.l10n.slotAfternoon,
  DevotionSlot.night => context.l10n.slotNight,
};

IconData slotIcon(DevotionSlot slot) => switch (slot) {
  DevotionSlot.morning => Icons.wb_twilight_rounded,
  DevotionSlot.afternoon => Icons.wb_sunny_rounded,
  DevotionSlot.night => Icons.nightlight_round,
};

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.devotion,
    required this.isNow,
    required this.onReturn,
  });

  final DevotionSlot slot;

  /// Today's devotion for this moment, or null if not published yet.
  final Devotion? devotion;

  /// This is the current moment of the day (gold outline).
  final bool isNow;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = devotion;
    final available = d != null;

    return Opacity(
      opacity: available ? 1 : 0.75,
      child: Material(
        color: AppColors.deepPurple,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            if (d == null) {
              context.toast(l.wordNotYet);
              return;
            }
            await context.push('/devotion/${d.id}');
            onReturn();
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: isNow && available
                  ? Border.all(color: AppColors.gold, width: 1.5)
                  : null,
            ),
            padding: const EdgeInsets.fromLTRB(18, 22, 12, 22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            wordSlotTitle(context, slot),
                            style: AppText.titleLarge.copyWith(
                              color: AppColors.gold,
                              fontSize: 24,
                            ),
                          ),
                          if (isNow && available) ...[
                            const SizedBox(width: 10),
                            _Pill(label: l.wordNow),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        wordSlotText(context, slot),
                        style: AppText.bodySmall.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (d?.completed ?? false)
                  Tooltip(
                    message: l.wordDone,
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.gold,
                      size: 22,
                    ),
                  ),
                Icon(
                  available
                      ? Icons.chevron_right_rounded
                      : Icons.schedule_rounded,
                  color: Colors.white,
                  size: available ? 30 : 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppText.labelSmall.copyWith(color: AppColors.goldLight),
      ),
    );
  }
}
