import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/page_top_bar.dart';
import '../../widgets/segmented_switch.dart';

/// "Messages & Notifications": private chats with leaders + announcements.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late Future<(List<Conversation>, List<Announcement>)> _future = _load();

  Future<(List<Conversation>, List<Announcement>)> _load() async {
    final r = await Future.wait([Repo.myConversations(), Repo.announcements()]);
    return (r[0] as List<Conversation>, r[1] as List<Announcement>);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    try {
      await _future;
    } catch (_) {
      // Shown by AsyncView with a "Réessayer" button.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: AsyncView<(List<Conversation>, List<Announcement>)>(
          future: _future,
          onRetry: _refresh,
          builder: (context, data) => InboxBody(
            conversations: data.$1,
            announcements: data.$2,
            onRefresh: _refresh,
          ),
        ),
      ),
    );
  }
}

class InboxBody extends StatefulWidget {
  const InboxBody({
    super.key,
    required this.conversations,
    required this.announcements,
    required this.onRefresh,
  });

  final List<Conversation> conversations;
  final List<Announcement> announcements;
  final Future<void> Function() onRefresh;

  @override
  State<InboxBody> createState() => _InboxBodyState();
}

class _InboxBodyState extends State<InboxBody> {
  int _tab = 0;

  Future<void> _open(String path) async {
    await context.push(path);
    await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final unread = widget.conversations.fold<int>(0, (n, c) => n + c.unread);

    return Column(
      children: [
        PageTopBar(title: l.inboxTitle),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: SegmentedSwitch(
            index: _tab,
            labels: [l.inboxMessages, l.inboxNotifications],
            badges: [unread, 0],
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: _tab == 0
                ? _ConversationList(
                    conversations: widget.conversations,
                    onOpen: (c) => _open('/inbox/${c.id}'),
                    onNew: () => _open('/inbox/new'),
                  )
                : _AnnouncementList(announcements: widget.announcements),
          ),
        ),
        if (_tab == 0)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () => _open('/inbox/new'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: Text(
                    l.inboxNewConversation,
                    style: AppText.labelLarge,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Messages | Notifications" switch with an unread badge.
// ------------------------------------------------------------ conversations

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.conversations,
    required this.onOpen,
    required this.onNew,
  });

  final List<Conversation> conversations;
  final ValueChanged<Conversation> onOpen;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (conversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 56, 32, 24),
        children: [
          const Center(child: Text('💬', style: TextStyle(fontSize: 48))),
          const SizedBox(height: 14),
          Text(
            l.inboxEmptyTitle,
            textAlign: TextAlign.center,
            style: AppText.titleMedium.copyWith(color: AppColors.deepPurple),
          ),
          const SizedBox(height: 6),
          Text(
            l.inboxEmpty,
            textAlign: TextAlign.center,
            style: AppText.bodySmall.copyWith(color: AppColors.muted),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: conversations.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 84, color: AppColors.border),
      itemBuilder: (context, i) => _ConversationRow(
        conversation: conversations[i],
        onTap: () => onOpen(conversations[i]),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = conversation;
    final unread = c.unread > 0;
    final preview = c.lastMessage == null
        ? ''
        : c.lastFromStaff
        ? c.lastMessage!
        : '${l.chatYou} : ${c.lastMessage}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            const LeadersAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.titleSmall.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatShortDate(context, c.lastMessageAt),
                        style: AppText.caption.copyWith(
                          color: unread ? AppColors.goldDark : AppColors.muted,
                          fontWeight: unread ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySmall.copyWith(
                            color: unread ? AppColors.ink : AppColors.muted,
                            fontWeight: unread ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        CountBadge(count: c.unread),
                      ] else if (!c.isOpen) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.beige,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l.chatClosedChip,
                            style: AppText.caption.copyWith(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round church logo standing for "the leaders".
class LeadersAvatar extends StatelessWidget {
  const LeadersAvatar({super.key, this.size = 52, this.ring = false});

  final double size;

  /// Gold ring, for when the avatar sits on a purple background.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: AppColors.deepPurple,
        shape: BoxShape.circle,
        border: ring ? Border.all(color: AppColors.gold, width: 2) : null,
      ),
      child: BrandMark(size: size * 0.68, light: true),
    );
  }
}

// ------------------------------------------------------------ announcements

class _AnnouncementList extends StatelessWidget {
  const _AnnouncementList({required this.announcements});

  final List<Announcement> announcements;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (announcements.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 56, 32, 24),
        children: [
          const Center(child: Text('🔔', style: TextStyle(fontSize: 48))),
          const SizedBox(height: 14),
          Text(
            l.notificationsEmpty,
            textAlign: TextAlign.center,
            style: AppText.bodyMedium.copyWith(color: AppColors.muted),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: announcements.length,
      itemBuilder: (context, i) {
        final a = announcements[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.goldLight,
                  shape: BoxShape.circle,
                ),
                child: const Text('📣', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.title,
                            style: AppText.titleSmall.copyWith(
                              color: AppColors.deepPurple,
                            ),
                          ),
                        ),
                        Text(
                          formatShortDate(context, a.createdAt),
                          style: AppText.caption.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.body,
                      style: AppText.bodySmall.copyWith(color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
