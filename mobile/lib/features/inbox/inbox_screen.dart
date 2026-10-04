import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../sos/sos_widgets.dart';

/// "Messages & Notifications": private chats with leaders + announcements.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late Future<List<Conversation>> _conversations = Repo.myConversations();
  late final Future<List<Announcement>> _announcements = Repo.announcements();

  void _refresh() => setState(() => _conversations = Repo.myConversations());

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.inboxTitle),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.ink,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    iconMargin: EdgeInsets.zero,
                    text: l.inboxMessages,
                    height: 48,
                  ),
                  Tab(
                    icon: const Icon(Icons.notifications_none, size: 18),
                    iconMargin: EdgeInsets.zero,
                    text: l.inboxNotifications,
                    height: 48,
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.edit_outlined, color: AppColors.gold),
          label: Text(l.inboxNewConversation),
          onPressed: () async {
            await context.push('/inbox/new');
            _refresh();
          },
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: AsyncView<List<Conversation>>(
                future: _conversations,
                onRetry: _refresh,
                builder: (context, list) {
                  if (list.isEmpty) {
                    return ListView(
                      children: [
                        EmptyState(
                          message: l.inboxEmpty,
                          icon: Icons.forum_outlined,
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: list.length,
                    itemBuilder: (context, i) =>
                        _ConversationTile(c: list[i], onReturn: _refresh),
                  );
                },
              ),
            ),
            AsyncView<List<Announcement>>(
              future: _announcements,
              builder: (context, list) {
                if (list.isEmpty) {
                  return EmptyState(
                    message: l.notificationsEmpty,
                    icon: Icons.notifications_none,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final a = list[i];
                    return AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const IconBubble(
                            icon: Icons.campaign_outlined,
                            light: true,
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatShortDate(context, a.createdAt),
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  a.body,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.c, required this.onReturn});

  final Conversation c;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () async {
        await context.push('/inbox/${c.id}');
        onReturn();
      },
      child: Row(
        children: [
          const BrandMark(size: 44),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      formatShortDate(context, c.lastMessageAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.lastMessage ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (c.unread > 0)
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: AppColors.purple,
                        child: Text(
                          '${c.unread}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else if (!c.isOpen)
                      StatusChip(status: c.status),
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
