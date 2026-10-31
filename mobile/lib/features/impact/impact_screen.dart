import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

/// What the Impact tab shows (public so tests can render it).
class ImpactData {
  ImpactData(this.challenge, this.stats);
  final Challenge? challenge;
  final UserStats stats;
}

/// "Ton impact du jour": the daily challenge.
class ImpactScreen extends StatefulWidget {
  const ImpactScreen({super.key});

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> {
  late Future<ImpactData> _future = _load();

  Future<ImpactData> _load() async {
    final r = await Future.wait([Repo.todayChallenge(), Repo.myStats()]);
    return ImpactData(r[0] as Challenge?, r[1] as UserStats);
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

  Future<void> _complete(Challenge c, String note) async {
    await Repo.completeChallenge(c.id, note: note);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: AsyncView<ImpactData>(
            future: _future,
            onRetry: _refresh,
            builder: (context, data) =>
                ImpactBody(data: data, onComplete: _complete),
          ),
        ),
      ),
    );
  }
}

class ImpactBody extends StatelessWidget {
  const ImpactBody({super.key, required this.data, required this.onComplete});

  final ImpactData data;

  /// Saves the challenge as done (with the optional note).
  final Future<void> Function(Challenge challenge, String note) onComplete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = data.challenge;
    final s = data.stats;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SizedBox(height: 12),
        Text(
          l.impactTitle,
          textAlign: TextAlign.center,
          style: AppText.titleLarge.copyWith(
            color: AppColors.deepPurple,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.impactSubtitle,
          textAlign: TextAlign.center,
          style: AppText.bodySmall.copyWith(color: AppColors.deepPurple),
        ),
        const SizedBox(height: 24),

        if (c == null)
          const _NoChallengeCard()
        else
          _ChallengeCard(
            challenge: c,
            onAccept: c.completed
                ? null
                : () => _showCompleteSheet(context, c, onComplete),
          ),
        const SizedBox(height: 16),

        // Three counters.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  emoji: '🔥',
                  value: '${s.streak}',
                  label: l.impactStreakLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  emoji: '🏆',
                  value: '${s.challengesCompleted}',
                  label: l.impactTotalLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  emoji: '📅',
                  value: '${s.weekChallengeDays.length}/7',
                  label: l.impactWeekLabel,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _WeekCard(days: s.weekChallengeDays),
      ],
    );
  }
}

// ------------------------------------------------------------ challenge card

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge, required this.onAccept});

  final Challenge challenge;

  /// Null once the challenge is done.
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = challenge;
    final done = c.completed;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(26),
        border: done ? Border.all(color: AppColors.gold, width: 1.5) : null,
        image: c.imageUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(c.imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  AppColors.purpleDark.withValues(alpha: 0.72),
                  BlendMode.darken,
                ),
              ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l.impactChallenge.toUpperCase(),
                  style: AppText.labelSmall.copyWith(
                    color: AppColors.goldLight,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              if (done)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.gold,
                  size: 28,
                )
              else
                const Text('🎯', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            c.title,
            style: AppText.titleLarge.copyWith(color: Colors.white),
          ),
          if ((c.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              c.description!,
              style: AppText.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.45,
              ),
            ),
          ],
          if ((c.verseText ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.9),
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.verseText!,
                    style: AppText.scripture.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  if ((c.verseReference ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      c.verseReference!,
                      style: AppText.scriptureRef.copyWith(
                        color: AppColors.goldLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.14),
                disabledForegroundColor: AppColors.goldLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (done) ...[
                    const Icon(Icons.check_rounded, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      done ? l.impactDone : l.impactAccept,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.labelLarge.copyWith(letterSpacing: 0.4),
                    ),
                  ),
                  if (!done) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, size: 22),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoChallengeCard extends StatelessWidget {
  const _NoChallengeCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            l.impactNoChallengeTitle,
            textAlign: TextAlign.center,
            style: AppText.titleMedium.copyWith(color: AppColors.deepPurple),
          ),
          const SizedBox(height: 6),
          Text(
            l.impactNoChallengeText,
            textAlign: TextAlign.center,
            style: AppText.bodySmall.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => context.push('/prayers/community'),
            style: TextButton.styleFrom(foregroundColor: AppColors.deepPurple),
            icon: const Icon(Icons.volunteer_activism_outlined, size: 20),
            label: Text(l.prayerForSomeone, style: AppText.labelMedium),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ stats + week

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
          ),
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

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.days});

  /// ISO weekdays (1 = Monday) with a challenge done.
  final Set<int> days;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final letters = l.weekdaysShort
        .split(',')
        .map((d) => d.characters.first.toUpperCase())
        .toList();
    final today = DateTime.now().weekday;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.impactMyWeek,
            style: AppText.titleSmall.copyWith(color: AppColors.deepPurple),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var d = 1; d <= 7; d++)
                Expanded(
                  child: Column(
                    children: [
                      _DayCircle(
                        done: days.contains(d),
                        today: d == today,
                        future: d > today,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        letters[d - 1],
                        style:
                            (d == today ? AppText.labelSmall : AppText.caption)
                                .copyWith(
                                  color: d == today
                                      ? AppColors.deepPurple
                                      : AppColors.muted,
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

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.done,
    required this.today,
    required this.future,
  });

  final bool done;
  final bool today;
  final bool future;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? AppColors.gold
            : future
            ? AppColors.beige
            : AppColors.lavender,
        border: today
            ? Border.all(color: AppColors.deepPurple, width: 2)
            : null,
      ),
      child: done
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : null,
    );
  }
}

// ------------------------------------------------------- complete + bravo

Future<void> _showCompleteSheet(
  BuildContext context,
  Challenge challenge,
  Future<void> Function(Challenge, String) onComplete,
) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.warmWhite,
    builder: (_) =>
        _CompleteSheet(challenge: challenge, onComplete: onComplete),
  );
  if (done == true && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (_) => const _BravoDialog(),
    );
  }
}

class _CompleteSheet extends StatefulWidget {
  const _CompleteSheet({required this.challenge, required this.onComplete});

  final Challenge challenge;
  final Future<void> Function(Challenge, String) onComplete;

  @override
  State<_CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends State<_CompleteSheet> {
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await widget.onComplete(widget.challenge, _note.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      context.toast(context.errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.impactConfirmTitle,
            style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
          ),
          const SizedBox(height: 6),
          Text(
            widget.challenge.title,
            style: AppText.bodyMedium.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _note,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.impactNotePrompt),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l.impactConfirmDone,
                      style: AppText.labelLarge.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BravoDialog extends StatelessWidget {
  const _BravoDialog();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Dialog(
      backgroundColor: AppColors.warmWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.goldLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🎉', style: TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 16),
            Text(
              l.impactBravoTitle,
              style: AppText.headline.copyWith(color: AppColors.deepPurple),
            ),
            const SizedBox(height: 8),
            Text(
              l.impactBravoText,
              textAlign: TextAlign.center,
              style: AppText.bodyMedium.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.deepPurple,
              ),
              child: Text(
                MaterialLocalizations.of(context).okButtonLabel,
                style: AppText.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
