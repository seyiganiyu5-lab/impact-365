import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'sos_widgets.dart';

/// Holy SOS entry point: ask for help, help someone, or follow my requests.
class SosHubScreen extends StatelessWidget {
  const SosHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.sosTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            l.sosSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          const SosBanner(),
          MenuTile(
            icon: Icons.front_hand_outlined,
            title: l.sosNeedHelp,
            subtitle: l.sosNeedHelpSub,
            onTap: () => context.push('/sos/new'),
          ),
          MenuTile(
            icon: Icons.handshake_outlined,
            title: l.sosWantHelp,
            subtitle: l.sosWantHelpSub,
            onTap: () => context.push('/sos/needs'),
          ),
          MenuTile(
            icon: Icons.inbox_outlined,
            title: l.sosMyRequests,
            subtitle: l.sosMyRequestsSub,
            onTap: () => context.push('/sos/mine'),
          ),
          const SizedBox(height: 8),
          AppCard(
            color: AppColors.beige,
            child: Row(
              children: [
                const IconBubble(icon: Icons.verified_user_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.sosConfidential, style: AppText.titleSmall),
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
          ),
        ],
      ),
    );
  }
}
