import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

/// "Prier pour quelqu'un" — intercede for prayer points others shared.
class CommunityPrayersScreen extends StatefulWidget {
  const CommunityPrayersScreen({super.key});

  @override
  State<CommunityPrayersScreen> createState() => _CommunityPrayersScreenState();
}

class _CommunityPrayersScreenState extends State<CommunityPrayersScreen> {
  late Future<List<CommunityPrayer>> _future = Repo.communityPrayers();

  /// Local overrides so the button reacts instantly.
  final Map<String, bool> _prayed = {};

  void _refresh() => setState(() {
    _prayed.clear();
    _future = Repo.communityPrayers();
  });

  Future<void> _toggle(CommunityPrayer p) async {
    final now = !(_prayed[p.id] ?? p.iPrayed);
    setState(() => _prayed[p.id] = now);
    try {
      await Repo.setIPrayed(p.id, now);
    } catch (_) {
      if (mounted) {
        setState(() => _prayed[p.id] = !now);
        context.toast(context.l10n.commonError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.prayerForSomeone)),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: AsyncView<List<CommunityPrayer>>(
          future: _future,
          onRetry: _refresh,
          builder: (context, list) {
            if (list.isEmpty) {
              return ListView(
                children: [EmptyState(message: l.prayerCommunityEmpty)],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final p = list[i];
                final prayed = _prayed[p.id] ?? p.iPrayed;
                final count =
                    p.intercessionCount +
                    (prayed == p.iPrayed ? 0 : (prayed ? 1 : -1));
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 18,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.authorName ?? l.anonymous,
                            style: AppText.bodySmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatShortDate(context, p.createdAt),
                            style: AppText.bodySmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(p.title, style: AppText.titleSmall),
                      if (p.details != null) ...[
                        const SizedBox(height: 4),
                        Text(p.details!),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.prayerPrayedCount(count),
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          prayed
                              ? FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                  ),
                                  onPressed: () => _toggle(p),
                                  icon: const Icon(
                                    Icons.check,
                                    color: AppColors.gold,
                                  ),
                                  label: Text(l.prayerIPrayed),
                                )
                              : OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                  ),
                                  onPressed: () => _toggle(p),
                                  icon: const Icon(
                                    Icons.volunteer_activism_outlined,
                                  ),
                                  label: Text(l.prayerIPrayed),
                                ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
