import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';

String categoryLabel(BuildContext context, HelpCategory c) {
  final l = context.l10n;
  return switch (c) {
    HelpCategory.prayer => l.catPrayer,
    HelpCategory.financial => l.catFinancial,
    HelpCategory.health => l.catHealth,
    HelpCategory.emotional => l.catEmotional,
    HelpCategory.studiesWork => l.catStudiesWork,
    HelpCategory.other => l.catOther,
  };
}

IconData categoryIcon(HelpCategory c) => switch (c) {
  HelpCategory.prayer => Icons.volunteer_activism_rounded,
  HelpCategory.financial => Icons.payments_outlined,
  HelpCategory.health => Icons.monitor_heart_outlined,
  HelpCategory.emotional => Icons.favorite_border_rounded,
  HelpCategory.studiesWork => Icons.school_outlined,
  HelpCategory.other => Icons.more_horiz_rounded,
};

String statusLabel(BuildContext context, String status) {
  final l = context.l10n;
  return switch (status) {
    'open' => l.statusOpen,
    'in_progress' => l.statusInProgress,
    'resolved' => l.statusResolved,
    'closed' => l.statusClosed,
    _ => status,
  };
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'resolved' || 'closed' => Colors.green.shade700,
      'in_progress' => AppColors.gold,
      _ => AppColors.purple,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusLabel(context, status),
        style: AppText.labelSmall.copyWith(color: color),
      ),
    );
  }
}

/// Purple "Dieu voit. La famille agit." banner.
class SosBanner extends StatelessWidget {
  const SosBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      gradient: AppColors.purpleGradient,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.sosBannerTitle,
                  style: AppText.titleMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  l.sosBannerText,
                  style: AppText.bodySmall.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: AppColors.gold,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l.sosBannerTags,
                        style: AppText.bodySmall.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
