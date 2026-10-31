import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/page_top_bar.dart';
import '../../widgets/segmented_switch.dart';
import 'add_prayer_sheet.dart';

typedef MyPrayersData = (List<PrayerRequest>, List<PrayerRequest>);

/// "Mes prières": ongoing and answered prayer requests, in two tabs.
class MyPrayersScreen extends StatefulWidget {
  const MyPrayersScreen({super.key, required this.answered});

  /// Opens on the "Exaucées" tab.
  final bool answered;

  @override
  State<MyPrayersScreen> createState() => _MyPrayersScreenState();
}

class _MyPrayersScreenState extends State<MyPrayersScreen> {
  late Future<MyPrayersData> _future = _load();

  Future<MyPrayersData> _load() async {
    final r = await Future.wait([
      Repo.myPrayers(answered: false),
      Repo.myPrayers(answered: true),
    ]);
    return (r[0], r[1]);
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
        child: AsyncView<MyPrayersData>(
          future: _future,
          onRetry: _refresh,
          builder: (context, data) => MyPrayersBody(
            ongoing: data.$1,
            answered: data.$2,
            initialTab: widget.answered ? 1 : 0,
            onRefresh: _refresh,
            onAdd: () => showAddPrayerSheet(context),
            onAnswered: (id, testimony) =>
                Repo.markPrayerAnswered(id, testimony: testimony),
            onDelete: Repo.deletePrayer,
          ),
        ),
      ),
    );
  }
}

class MyPrayersBody extends StatefulWidget {
  const MyPrayersBody({
    super.key,
    required this.ongoing,
    required this.answered,
    required this.onRefresh,
    required this.onAdd,
    required this.onAnswered,
    required this.onDelete,
    this.initialTab = 0,
  });

  final List<PrayerRequest> ongoing;
  final List<PrayerRequest> answered;
  final int initialTab;
  final Future<void> Function() onRefresh;

  /// Opens the "new prayer" form; true when one was saved.
  final Future<bool> Function() onAdd;
  final Future<void> Function(String id, String? testimony) onAnswered;
  final Future<void> Function(String id) onDelete;

  @override
  State<MyPrayersBody> createState() => _MyPrayersBodyState();
}

class _MyPrayersBodyState extends State<MyPrayersBody> {
  late int _tab = widget.initialTab;

  // Local copies so changes show at once.
  late List<PrayerRequest> _ongoing = [...widget.ongoing];
  late List<PrayerRequest> _answered = [...widget.answered];

  @override
  void didUpdateWidget(MyPrayersBody old) {
    super.didUpdateWidget(old);
    if (old.ongoing != widget.ongoing || old.answered != widget.answered) {
      _ongoing = [...widget.ongoing];
      _answered = [...widget.answered];
    }
  }

  Future<void> _add() async {
    if (await widget.onAdd()) {
      if (mounted) {
        setState(() {
          _tab = 0;
        });
      }
      await widget.onRefresh();
    }
  }

  Future<void> _markAnswered(PrayerRequest p) async {
    final testimony = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.warmWhite,
      builder: (_) => _AnsweredSheet(prayer: p),
    );
    if (testimony == null || !mounted) return;
    final text = testimony.trim().isEmpty ? null : testimony.trim();
    try {
      await widget.onAnswered(p.id, text);
      if (!mounted) return;
      setState(() {
        _ongoing.removeWhere((x) => x.id == p.id);
        _answered.insert(
          0,
          PrayerRequest(
            id: p.id,
            title: p.title,
            details: p.details,
            isShared: p.isShared,
            isAnonymous: p.isAnonymous,
            isAnswered: true,
            testimony: text,
            createdAt: p.createdAt,
            answeredAt: DateTime.now(),
          ),
        );
        _tab = 1;
      });
      context.toast(context.l10n.prayerAnsweredDone);
    } catch (e) {
      if (mounted) context.toast(context.errorText(e));
    }
  }

  Future<void> _delete(PrayerRequest p) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.warmWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l.prayerDeleteConfirm,
          style: AppText.titleMedium.copyWith(color: AppColors.deepPurple),
        ),
        content: Text(
          p.title,
          style: AppText.bodyMedium.copyWith(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
            ),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.onDelete(p.id);
      if (!mounted) return;
      setState(() {
        _ongoing.removeWhere((x) => x.id == p.id);
        _answered.removeWhere((x) => x.id == p.id);
      });
    } catch (e) {
      if (mounted) context.toast(context.errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final list = _tab == 0 ? _ongoing : _answered;
    return Column(
      children: [
        PageTopBar(title: l.prayerMineTitle),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: SegmentedSwitch(
            index: _tab,
            labels: [l.prayerOngoing, l.prayerAnsweredShort],
            badges: [_ongoing.length, _answered.length],
            onChanged: (i) => setState(() {
              _tab = i;
            }),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: list.isEmpty
                ? _Empty(answered: _tab == 1)
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _tab == 0
                        ? _OngoingCard(
                            prayer: list[i],
                            onAnswered: () => _markAnswered(list[i]),
                            onDelete: () => _delete(list[i]),
                          )
                        : _AnsweredCard(
                            prayer: list[i],
                            onDelete: () => _delete(list[i]),
                          ),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _add,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: Text(l.prayerAdd, style: AppText.labelLarge),
            ),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.answered});

  final bool answered;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 24),
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Text(
              answered ? '✨' : '🕊️',
              style: const TextStyle(fontSize: 38),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          answered ? l.prayerAnsweredEmptyTitle : l.prayerEmptyTitle,
          textAlign: TextAlign.center,
          style: AppText.titleMedium.copyWith(color: AppColors.deepPurple),
        ),
        const SizedBox(height: 6),
        Text(
          answered ? l.prayerAnsweredEmpty : l.prayerEmpty,
          textAlign: TextAlign.center,
          style: AppText.bodyMedium.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

/// "⋯" menu with "Supprimer".
class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<int>(
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.more_horiz_rounded,
          color: AppColors.muted,
          size: 22,
        ),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (_) => onDelete(),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 0,
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  context.l10n.commonDelete,
                  style: AppText.bodyMedium.copyWith(color: AppColors.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({required this.shared});

  final bool shared;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: shared ? AppColors.lavender : AppColors.beige,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            shared ? Icons.people_alt_outlined : Icons.lock_outline_rounded,
            size: 12,
            color: shared ? AppColors.deepPurple : AppColors.goldDark,
          ),
          const SizedBox(width: 4),
          Text(
            shared ? l.prayerSharedChip : l.prayerPrivate,
            style: AppText.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: shared ? AppColors.deepPurple : AppColors.goldDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _OngoingCard extends StatelessWidget {
  const _OngoingCard({
    required this.prayer,
    required this.onAnswered,
    required this.onDelete,
  });

  final PrayerRequest prayer;
  final VoidCallback onAnswered;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = prayer;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.lavender,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.deepPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: AppText.titleSmall.copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          formatDay(context, p.createdAt.toLocal()),
                          style: AppText.caption.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        _VisibilityChip(shared: p.isShared),
                      ],
                    ),
                  ],
                ),
              ),
              _MoreMenu(onDelete: onDelete),
            ],
          ),
          if ((p.details ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                p.details!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodySmall.copyWith(color: AppColors.muted),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: onAnswered,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.goldDark,
                  side: const BorderSide(color: AppColors.gold, width: 1.3),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '✨ ${l.prayerMarkAnswered}',
                  style: AppText.labelMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnsweredCard extends StatelessWidget {
  const _AnsweredCard({required this.prayer, required this.onDelete});

  final PrayerRequest prayer;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = prayer;
    final when = (p.answeredAt ?? p.createdAt).toLocal();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: AppText.titleSmall.copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l.prayerAnsweredOn(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(when),
                      ),
                      style: AppText.caption.copyWith(
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _MoreMenu(onDelete: onDelete),
            ],
          ),
          if ((p.details ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                p.details!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodySmall.copyWith(color: AppColors.muted),
              ),
            ),
          ],
          if ((p.testimony ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✨ ${l.prayerTestimonyLabel}',
                    style: AppText.labelSmall.copyWith(
                      color: AppColors.goldDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.testimony!,
                    style: AppText.bodyMedium.copyWith(
                      color: AppColors.ink,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Gloire à Dieu !" sheet. Returns the testimony ('' for none), or null
/// when closed.
class _AnsweredSheet extends StatefulWidget {
  const _AnsweredSheet({required this.prayer});

  final PrayerRequest prayer;

  @override
  State<_AnsweredSheet> createState() => _AnsweredSheetState();
}

class _AnsweredSheetState extends State<_AnsweredSheet> {
  final _testimony = TextEditingController();

  @override
  void dispose() {
    _testimony.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Text('🙌', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.prayerAnsweredSheetTitle,
              textAlign: TextAlign.center,
              style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
            ),
            const SizedBox(height: 6),
            Text(
              l.prayerAnsweredSheetText,
              textAlign: TextAlign.center,
              style: AppText.bodySmall.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.prayer.title,
                textAlign: TextAlign.center,
                style: AppText.bodyStrong.copyWith(color: AppColors.deepPurple),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _testimony,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l.prayerTestimony),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _testimony.text),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  '✨ ${l.prayerMarkAnswered}',
                  style: AppText.labelLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
