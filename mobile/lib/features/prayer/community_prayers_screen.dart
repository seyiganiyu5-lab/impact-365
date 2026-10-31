import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/page_top_bar.dart';
import 'prayer_widgets.dart';

/// "Prier pour les autres": intercede for prayer points others shared.
class CommunityPrayersScreen extends StatefulWidget {
  const CommunityPrayersScreen({super.key});

  @override
  State<CommunityPrayersScreen> createState() => _CommunityPrayersScreenState();
}

class _CommunityPrayersScreenState extends State<CommunityPrayersScreen> {
  late Future<List<CommunityPrayer>> _future = Repo.communityPrayers();

  Future<void> _refresh() async {
    setState(() {
      _future = Repo.communityPrayers();
    });
    try {
      await _future;
    } catch (_) {
      // Shown by AsyncView with a "Réessayer" button.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            PageTopBar(title: l.prayerCommunityTitle),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: AsyncView<List<CommunityPrayer>>(
                  future: _future,
                  onRetry: _refresh,
                  builder: (context, list) =>
                      CommunityPrayersBody(prayers: list),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityPrayersBody extends StatelessWidget {
  const CommunityPrayersBody({super.key, required this.prayers, this.onToggle});

  final List<CommunityPrayer> prayers;

  /// Saves "I prayed". Tests pass their own.
  final Future<void> Function(String prayerId, bool prayed)? onToggle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // Verse + invitation.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.deepPurple,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Text('🤲', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.prayerCommunityVerse,
                      style: AppText.titleSmall.copyWith(color: AppColors.gold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.prayerCommunityIntro,
                      style: AppText.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (prayers.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
            child: Column(
              children: [
                const Text('🕊️', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 12),
                Text(
                  l.prayerCommunityEmpty,
                  textAlign: TextAlign.center,
                  style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          )
        else
          for (final p in prayers) ...[
            CommunityPrayerCard(
              key: ValueKey(p.id),
              prayer: p,
              onToggle: onToggle,
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
