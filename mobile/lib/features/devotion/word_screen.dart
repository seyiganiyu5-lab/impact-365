import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

/// "Parole" tab: today's morning / afternoon / night devotions + history.
class WordScreen extends StatefulWidget {
  const WordScreen({super.key});

  @override
  State<WordScreen> createState() => _WordScreenState();
}

class _WordScreenState extends State<WordScreen> {
  late Future<List<Devotion>> _future = Repo.recentDevotions();

  Future<void> _refresh() async {
    setState(() => _future = Repo.recentDevotions());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: AsyncView<List<Devotion>>(
            future: _future,
            onRetry: _refresh,
            builder: (context, all) {
              final now = DateTime.now();
              bool isToday(Devotion d) =>
                  d.date.year == now.year &&
                  d.date.month == now.month &&
                  d.date.day == now.day;
              final today = all.where(isToday).toList();
              final past = all.where((d) => !isToday(d)).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  ScreenTitle(
                    title: l.wordTodayTitle,
                    subtitle: l.devotionTitle,
                  ),
                  const SizedBox(height: 20),
                  for (final slot in DevotionSlot.values)
                    _SlotTile(
                      slot: slot,
                      devotion: today.where((d) => d.slot == slot).firstOrNull,
                      onReturn: _refresh,
                    ),
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      l.wordHistory,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final d in past)
                      _SlotTile(
                        slot: d.slot,
                        devotion: d,
                        onReturn: _refresh,
                        showDate: true,
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

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

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.devotion,
    required this.onReturn,
    this.showDate = false,
  });

  final DevotionSlot slot;
  final Devotion? devotion;
  final VoidCallback onReturn;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final d = devotion;
    final label = slotLabel(context, slot);
    final dateText = d != null && showDate
        ? '${formatDay(context, d.date)} · '
        : '';
    return AppCard(
      onTap: d == null
          ? null
          : () async {
              await context.push('/devotion/${d.id}');
              onReturn();
            },
      child: Row(
        children: [
          IconBubble(icon: slotIcon(slot)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dateText$label',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d?.verseReference ?? context.l10n.wordNotAvailable,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (d?.theme != null)
                  Text(
                    d!.theme!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted),
                  ),
              ],
            ),
          ),
          if (d?.completed ?? false)
            const Icon(Icons.check_circle_rounded, color: AppColors.gold)
          else if (d != null)
            const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
