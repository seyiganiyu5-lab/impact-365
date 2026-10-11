import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import 'add_prayer_sheet.dart';

/// "Mes sujets de prière" (answered: false) or "Mes prières exaucées" (true).
class MyPrayersScreen extends StatefulWidget {
  const MyPrayersScreen({super.key, required this.answered});

  final bool answered;

  @override
  State<MyPrayersScreen> createState() => _MyPrayersScreenState();
}

class _MyPrayersScreenState extends State<MyPrayersScreen> {
  late Future<List<PrayerRequest>> _future = _load();

  Future<List<PrayerRequest>> _load() =>
      Repo.myPrayers(answered: widget.answered);

  void _refresh() => setState(() {
    _future = _load();
  });

  Future<void> _markAnswered(PrayerRequest p) async {
    final l = context.l10n;
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.prayerMarkAnswered),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(hintText: l.prayerTestimony),
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
      await Repo.markPrayerAnswered(
        p.id,
        testimony: controller.text.trim().isEmpty
            ? null
            : controller.text.trim(),
      );
      _refresh();
    } catch (e) {
      if (mounted) context.toast(context.errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.answered ? l.prayerAnswered : l.prayerMyTopics),
      ),
      floatingActionButton: widget.answered
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.purple,
              foregroundColor: AppColors.gold,
              onPressed: () async {
                if (await showAddPrayerSheet(context)) _refresh();
              },
              child: const Icon(Icons.add_rounded),
            ),
      body: AsyncView<List<PrayerRequest>>(
        future: _future,
        onRetry: _refresh,
        builder: (context, prayers) {
          if (prayers.isEmpty) {
            return EmptyState(
              message: widget.answered ? l.prayerAnsweredEmpty : l.prayerEmpty,
              icon: Icons.volunteer_activism_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: prayers.length,
            itemBuilder: (context, i) {
              final p = prayers[i];
              return Dismissible(
                key: ValueKey(p.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                ),
                onDismissed: (_) => Repo.deletePrayer(p.id),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.title, style: AppText.titleSmall),
                          ),
                          if (p.isShared)
                            const Icon(
                              Icons.people_outline,
                              size: 18,
                              color: AppColors.muted,
                            ),
                        ],
                      ),
                      if (p.details != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          p.details!,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                      if (p.testimony != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.beige,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: AppColors.gold,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(p.testimony!)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            formatDay(context, p.createdAt.toLocal()),
                            style: AppText.bodySmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          const Spacer(),
                          if (!widget.answered)
                            TextButton.icon(
                              onPressed: () => _markAnswered(p),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: AppColors.gold,
                              ),
                              label: Text(l.prayerMarkAnswered),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
