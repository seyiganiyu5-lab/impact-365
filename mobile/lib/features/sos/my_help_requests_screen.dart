import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import 'sos_widgets.dart';

/// My Holy SOS requests with leader notes and offers of help.
class MyHelpRequestsScreen extends StatefulWidget {
  const MyHelpRequestsScreen({super.key});

  @override
  State<MyHelpRequestsScreen> createState() => _MyHelpRequestsScreenState();
}

class _MyHelpRequestsScreenState extends State<MyHelpRequestsScreen> {
  late Future<List<MyHelpRequest>> _future = Repo.myHelpRequests();

  void _refresh() => setState(() => _future = Repo.myHelpRequests());

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.sosMyRequests)),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: AsyncView<List<MyHelpRequest>>(
          future: _future,
          onRetry: _refresh,
          builder: (context, list) {
            if (list.isEmpty) {
              return ListView(children: [EmptyState(message: l.sosMyEmpty)]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final r = list[i];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            categoryIcon(r.category),
                            color: AppColors.purple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              categoryLabel(context, r.category),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          StatusChip(status: r.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(r.description),
                      if (r.staffNote != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lavender,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 18,
                                color: AppColors.purple,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.chatLeader,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(r.staffNote!),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (r.offers.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          l.sosOffers(r.offers.length),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        for (final o in r.offers)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              '${o.helperName ?? l.anonymous}: ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(text: o.message),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        formatDay(context, r.createdAt.toLocal()),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
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
