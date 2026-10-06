import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import 'sos_widgets.dart';

/// "Je veux aider" — needs shared by other members.
class CommunityNeedsScreen extends StatefulWidget {
  const CommunityNeedsScreen({super.key});

  @override
  State<CommunityNeedsScreen> createState() => _CommunityNeedsScreenState();
}

class _CommunityNeedsScreenState extends State<CommunityNeedsScreen> {
  late Future<List<HelpNeed>> _future = Repo.communityNeeds();

  void _refresh() => setState(() => _future = Repo.communityNeeds());

  Future<void> _offer(HelpNeed need) async {
    final l = context.l10n;
    final controller = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.sosOffer, style: AppText.titleLarge),
            const SizedBox(height: 12),
            CountedField(
              controller: controller,
              hint: l.sosOfferHint,
              minLines: 4,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.commonSubmit),
            ),
          ],
        ),
      ),
    );
    if (ok != true || controller.text.trim().isEmpty) return;
    try {
      await Repo.offerHelp(need.id, controller.text.trim());
      if (mounted) context.toast(l.sosOfferSent);
      _refresh();
    } catch (e) {
      if (mounted) context.toast(context.errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.sosWantHelp)),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: AsyncView<List<HelpNeed>>(
          future: _future,
          onRetry: _refresh,
          builder: (context, needs) {
            if (needs.isEmpty) {
              return ListView(children: [EmptyState(message: l.sosEmpty)]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: needs.length,
              itemBuilder: (context, i) {
                final n = needs[i];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconBubble(icon: categoryIcon(n.category), size: 36),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryLabel(context, n.category),
                                  style: AppText.titleSmall,
                                ),
                                Text(
                                  n.authorName ?? l.anonymous,
                                  style: AppText.bodySmall.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(status: n.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(n.description, style: AppText.bodyMedium),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.sosOffers(n.offerCount),
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                            onPressed: () => _offer(n),
                            icon: const Icon(Icons.handshake_outlined),
                            label: Text(l.sosOffer),
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
