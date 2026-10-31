import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/page_top_bar.dart';
import 'sos_widgets.dart';

/// Holy SOS home: ask for help, help someone, or follow my requests.
class SosHubScreen extends StatelessWidget {
  const SosHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            PageTopBar(title: l.sosTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    l.sosSubtitle,
                    textAlign: TextAlign.center,
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SosBanner(),
                  const SizedBox(height: 16),

                  // The two main actions, side by side.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ActionCard(
                            emoji: '🙋',
                            title: l.sosNeedHelp,
                            subtitle: l.sosNeedHelpSub,
                            background: AppColors.gold,
                            foreground: Colors.white,
                            onTap: () => context.push('/sos/new'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            emoji: '🤝',
                            title: l.sosWantHelp,
                            subtitle: l.sosWantHelpSub,
                            background: AppColors.deepPurple,
                            foreground: Colors.white,
                            onTap: () => context.push('/sos/needs'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // My requests.
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => context.push('/sos/mine'),
                      child: Ink(
                        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.lavender,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.inbox_outlined,
                                color: AppColors.deepPurple,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.sosMyRequests,
                                    style: AppText.titleSmall.copyWith(
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    l.sosMyRequestsSub,
                                    style: AppText.bodySmall.copyWith(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confidentiality.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.goldDark,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.sosConfidential,
                              style: AppText.titleSmall.copyWith(
                                color: AppColors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l.sosConfidentialText,
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SosVerse(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppText.titleSmall.copyWith(color: foreground),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppText.caption.copyWith(
                  color: foreground.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: foreground,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
