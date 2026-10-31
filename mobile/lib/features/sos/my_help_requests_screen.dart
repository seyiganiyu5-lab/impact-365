import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import 'sos_widgets.dart';

/// "Mes demandes": my Holy SOS requests, leader replies and offers of help.
class MyHelpRequestsScreen extends StatefulWidget {
  const MyHelpRequestsScreen({super.key});

  @override
  State<MyHelpRequestsScreen> createState() => _MyHelpRequestsScreenState();
}

class _MyHelpRequestsScreenState extends State<MyHelpRequestsScreen> {
  late Future<List<MyHelpRequest>> _future = Repo.myHelpRequests();

  Future<void> _refresh() async {
    setState(() {
      _future = Repo.myHelpRequests();
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
            SosTopBar(
              title: l.sosMyRequests,
              trailing: IconButton(
                tooltip: l.sosNewRequest,
                onPressed: () async {
                  await context.push('/sos/new');
                  _refresh();
                },
                icon: const Icon(
                  Icons.add_circle_rounded,
                  color: AppColors.gold,
                  size: 30,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: AsyncView<List<MyHelpRequest>>(
                  future: _future,
                  onRetry: _refresh,
                  builder: (context, list) => MyHelpRequestsBody(
                    requests: list,
                    onResolve: (id) async {
                      await Repo.resolveMyHelpRequest(id);
                      await _refresh();
                    },
                    onNew: () async {
                      await context.push('/sos/new');
                      _refresh();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHelpRequestsBody extends StatelessWidget {
  const MyHelpRequestsBody({
    super.key,
    required this.requests,
    required this.onResolve,
    required this.onNew,
  });

  final List<MyHelpRequest> requests;
  final Future<void> Function(String id) onResolve;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 64, 32, 24),
        children: [
          const Center(child: Text('🕊️', style: TextStyle(fontSize: 48))),
          const SizedBox(height: 14),
          Text(
            l.sosMyEmpty,
            textAlign: TextAlign.center,
            style: AppText.bodyMedium.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: onNew,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                minimumSize: const Size(0, 48),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(l.sosNeedHelp, style: AppText.labelLarge),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: requests.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _RequestCard(request: requests[i], onResolve: onResolve),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.request, required this.onResolve});

  final MyHelpRequest request;
  final Future<void> Function(String id) onResolve;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _busy = false;

  Future<void> _resolve() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.warmWhite,
        title: Text(
          l.sosResolveTitle,
          style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
        ),
        content: Text(
          l.sosResolveText,
          style: AppText.bodyMedium.copyWith(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deepPurple,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.sosMarkResolved),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onResolve(widget.request.id);
      if (mounted) context.toast(l.sosResolvedToast);
    } catch (e) {
      if (mounted) context.toast(context.errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = widget.request;
    final open = r.status != 'resolved' && r.status != 'closed';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryBadge(category: r.category),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryLabel(context, r.category),
                      style: AppText.titleSmall.copyWith(
                        color: AppColors.deepPurple,
                      ),
                    ),
                    Text(
                      formatDay(context, r.createdAt.toLocal()),
                      style: AppText.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusChip(status: r.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            r.description,
            style: AppText.bodyMedium.copyWith(color: AppColors.ink),
          ),

          // Reply from a leader.
          if ((r.staffNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: AppColors.deepPurple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.sosLeaderReply,
                        style: AppText.labelSmall.copyWith(
                          color: AppColors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.staffNote!,
                    style: AppText.bodySmall.copyWith(color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ],

          // Offers of help.
          if (r.offers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l.sosOffers(r.offers.length),
              style: AppText.labelSmall.copyWith(color: AppColors.goldDark),
            ),
            for (final o in r.offers)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.ink,
                          ),
                          children: [
                            TextSpan(
                              text: '${o.helperName ?? l.sosHelperDefault} : ',
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

          if (open) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _busy ? null : _resolve,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D4F),
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(l.sosMarkResolved, style: AppText.labelSmall),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
