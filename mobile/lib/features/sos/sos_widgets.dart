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

String categoryEmoji(HelpCategory c) => switch (c) {
  HelpCategory.prayer => '🙏',
  HelpCategory.financial => '💰',
  HelpCategory.health => '🩺',
  HelpCategory.emotional => '💜',
  HelpCategory.studiesWork => '🎓',
  HelpCategory.other => '✨',
};

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
      'resolved' || 'closed' => const Color(0xFF2E7D4F),
      'in_progress' => AppColors.goldDark,
      _ => AppColors.deepPurple,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel(context, status),
        style: AppText.labelSmall.copyWith(color: color),
      ),
    );
  }
}

/// Emoji in a soft circle, for a help category.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category, this.size = 40});

  final HelpCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.lavender,
        shape: BoxShape.circle,
      ),
      child: Text(
        categoryEmoji(category),
        style: TextStyle(fontSize: size * 0.48),
      ),
    );
  }
}

/// Purple "Dieu voit. La famille agit." card.
class SosBanner extends StatelessWidget {
  const SosBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 18),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l.sosBannerTitle,
                  style: AppText.titleLarge.copyWith(color: AppColors.gold),
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.sosBannerText,
            style: AppText.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.goldLight,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l.sosBannerTags,
                    style: AppText.labelSmall.copyWith(
                      color: AppColors.goldLight,
                    ),
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

/// Matthieu 6:8, framed, at the bottom of the Holy SOS pages.
class SosVerse extends StatelessWidget {
  const SosVerse({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.lavender.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: AppColors.gold, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.sosVerse,
            style: AppText.scripture.copyWith(
              color: AppColors.deepPurple,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.sosVerseRef,
            style: AppText.scriptureRef.copyWith(color: AppColors.goldDark),
          ),
        ],
      ),
    );
  }
}
