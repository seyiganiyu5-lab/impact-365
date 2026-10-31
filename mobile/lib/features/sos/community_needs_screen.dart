import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/page_top_bar.dart';
import 'sos_widgets.dart';

/// "Je veux aider": needs shared by other members.
class CommunityNeedsScreen extends StatefulWidget {
  const CommunityNeedsScreen({super.key});

  @override
  State<CommunityNeedsScreen> createState() => _CommunityNeedsScreenState();
}

class _CommunityNeedsScreenState extends State<CommunityNeedsScreen> {
  late Future<List<HelpNeed>> _future = Repo.communityNeeds();

  Future<void> _refresh() async {
    setState(() {
      _future = Repo.communityNeeds();
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
            PageTopBar(title: l.sosWantHelp),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: AsyncView<List<HelpNeed>>(
                  future: _future,
                  onRetry: _refresh,
                  builder: (context, needs) =>
                      CommunityNeedsBody(needs: needs, onOffer: Repo.offerHelp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityNeedsBody extends StatefulWidget {
  const CommunityNeedsBody({
    super.key,
    required this.needs,
    required this.onOffer,
  });

  final List<HelpNeed> needs;

  /// Sends the offer of help (request id, message).
  final Future<void> Function(String requestId, String message) onOffer;

  @override
  State<CommunityNeedsBody> createState() => _CommunityNeedsBodyState();
}

class _CommunityNeedsBodyState extends State<CommunityNeedsBody> {
  HelpCategory? _filter;

  /// Needs I offered to help with in this visit.
  final _offered = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final shown = _filter == null
        ? widget.needs
        : widget.needs.where((n) => n.category == _filter).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Category filter.
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            children: [
              _FilterChip(
                label: l.sosFilterAll,
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              for (final c in HelpCategory.values)
                _FilterChip(
                  label: '${categoryEmoji(c)} ${categoryLabel(context, c)}',
                  selected: _filter == c,
                  onTap: () => setState(() => _filter = c),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
            child: Column(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 12),
                Text(
                  l.sosEmpty,
                  textAlign: TextAlign.center,
                  style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          )
        else
          for (final n in shown)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _NeedCard(
                need: n,
                offered: _offered.contains(n.id),
                onOffer: () => _openOfferSheet(n),
              ),
            ),
      ],
    );
  }

  Future<void> _openOfferSheet(HelpNeed need) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.warmWhite,
      builder: (_) => _OfferSheet(need: need, onOffer: widget.onOffer),
    );
    if (sent == true && mounted) {
      setState(() => _offered.add(need.id));
      context.toast(context.l10n.sosOfferSent);
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.deepPurple : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.deepPurple : AppColors.border,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: AppText.labelSmall.copyWith(
                fontSize: 12.5,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NeedCard extends StatelessWidget {
  const _NeedCard({
    required this.need,
    required this.offered,
    required this.onOffer,
  });

  final HelpNeed need;
  final bool offered;
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final n = need;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
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
              CategoryBadge(category: n.category),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryLabel(context, n.category),
                      style: AppText.titleSmall.copyWith(
                        color: AppColors.deepPurple,
                      ),
                    ),
                    Text(
                      '${n.authorName ?? l.anonymous} · '
                      '${formatDay(context, n.createdAt.toLocal())}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusChip(status: n.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            n.description,
            style: AppText.bodyMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.sosOffers(n.offerCount + (offered ? 1 : 0)),
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ),
              if (offered)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l.sosOffered,
                      style: AppText.labelSmall.copyWith(
                        color: AppColors.goldDark,
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: onOffer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepPurple,
                    side: const BorderSide(color: AppColors.deepPurple),
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.handshake_outlined, size: 18),
                  label: Text(
                    l.sosOffer,
                    style: AppText.labelSmall.copyWith(fontSize: 12.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferSheet extends StatefulWidget {
  const _OfferSheet({required this.need, required this.onOffer});

  final HelpNeed need;
  final Future<void> Function(String requestId, String message) onOffer;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  final _message = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) {
      setState(() => _error = context.l10n.sosOfferRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onOffer(widget.need.id, text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      context.toast(context.errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.sosOffer,
            style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
          ),
          const SizedBox(height: 6),
          Text(
            widget.need.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodySmall.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          CountedField(controller: _message, hint: l.sosOfferHint, minLines: 4),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: AppText.bodySmall.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _busy ? null : _send,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(l.commonSubmit, style: AppText.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}
