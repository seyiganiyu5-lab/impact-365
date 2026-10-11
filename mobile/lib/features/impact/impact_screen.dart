import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

class _ImpactData {
  _ImpactData(this.challenge, this.stats);
  final Challenge? challenge;
  final UserStats stats;
}

/// "Ton impact du jour" — the daily challenge.
class ImpactScreen extends StatefulWidget {
  const ImpactScreen({super.key});

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> {
  late Future<_ImpactData> _future = _load();

  Future<_ImpactData> _load() async {
    final r = await Future.wait([Repo.todayChallenge(), Repo.myStats()]);
    return _ImpactData(r[0] as Challenge?, r[1] as UserStats);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _accept(Challenge c) async {
    final l = context.l10n;
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c.title),
        content: TextField(
          controller: note,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(hintText: l.impactNotePrompt),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.commonSubmit),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Repo.completeChallenge(c.id, note: note.text);
      await _refresh();
    } catch (e) {
      if (mounted) context.toast(context.errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: AsyncView<_ImpactData>(
            future: _future,
            onRetry: _refresh,
            builder: (context, data) {
              final c = data.challenge;
              final s = data.stats;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  ScreenTitle(title: l.impactTitle, subtitle: l.impactSubtitle),
                  const SizedBox(height: 20),
                  if (c == null)
                    AppCard(
                      child: EmptyState(
                        message: l.impactNoChallenge,
                        icon: Icons.track_changes_rounded,
                      ),
                    )
                  else
                    _ChallengeCard(
                      challenge: c,
                      onAccept: c.completed ? null : () => _accept(c),
                    ),
                  _WeekProgress(days: s.weekChallengeDays),
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.impactStreak, style: AppText.titleSmall),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: AppColors.gold,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l.daysCount(s.streak),
                                    style: AppText.titleLarge,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.show_chart_rounded,
                          color: AppColors.gold,
                          size: 56,
                        ),
                      ],
                    ),
                  ),
                  MenuTile(
                    icon: Icons.emoji_events_outlined,
                    title: l.impactTotal,
                    subtitle: l.impactTotalSub,
                    count: s.challengesCompleted,
                    trailing: const SizedBox.shrink(),
                  ),
                  if (c?.verseText != null)
                    VerseBanner(
                      text: c!.verseText!,
                      reference: c.verseReference ?? '',
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge, required this.onAccept});

  final Challenge challenge;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        gradient: challenge.imageUrl == null
            ? const LinearGradient(
                colors: [Colors.white, Color(0xFFF8F0D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: challenge.imageUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(challenge.imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.6),
                  BlendMode.lighten,
                ),
              ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBubble(icon: Icons.track_changes_rounded, size: 56),
          const SizedBox(height: 12),
          Text(
            l.impactChallenge,
            style: AppText.scriptureRef.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 6),
          Text(challenge.title, style: AppText.titleLarge),
          if (challenge.description != null) ...[
            const SizedBox(height: 8),
            Text(
              challenge.description!,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 18),
          GoldButton(
            label: challenge.completed ? l.impactDone : l.impactAccept,
            icon: challenge.completed
                ? Icons.check_rounded
                : Icons.chevron_right_rounded,
            onPressed: onAccept,
          ),
        ],
      ),
    );
  }
}

class _WeekProgress extends StatelessWidget {
  const _WeekProgress({required this.days});

  final Set<int> days;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final names = l.weekdaysShort.split(',');
    final today = DateTime.now().weekday;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.impactWeek, style: AppText.titleSmall),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 1; i <= 7; i++)
                Column(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: days.contains(i)
                          ? (i == today ? AppColors.gold : AppColors.purple)
                          : AppColors.border,
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: days.contains(i)
                            ? Colors.white
                            : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      names[i - 1],
                      style: AppText.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
