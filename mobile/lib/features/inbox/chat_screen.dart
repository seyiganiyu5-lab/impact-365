import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../features/auth/auth_widgets.dart';
import '../../widgets/common.dart';
import 'inbox_screen.dart';

/// Live private chat between a member and the church leaders.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final Future<Conversation> _conversation = Repo.conversation(
    widget.conversationId,
  );
  late final Stream<List<ChatMessage>> _messages = Repo.messagesStream(
    widget.conversationId,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Conversation>(
      future: _conversation,
      builder: (context, convSnap) {
        return StreamBuilder<List<ChatMessage>>(
          stream: _messages,
          builder: (context, snap) {
            final msgs = snap.data;
            if (msgs != null &&
                msgs.any((m) => m.isFromStaff && m.readAt == null)) {
              Repo.markStaffMessagesRead(widget.conversationId).ignore();
            }
            return ChatView(
              subject: convSnap.data?.subject ?? '',
              isOpen: convSnap.data?.isOpen ?? true,
              messages: msgs,
              myId: Repo.currentUserId,
              onSend: (text) => Repo.sendMessage(widget.conversationId, text),
            );
          },
        );
      },
    );
  }
}

/// The chat page itself. [messages] is null while loading.
class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.subject,
    required this.isOpen,
    required this.messages,
    required this.myId,
    required this.onSend,
  });

  final String subject;
  final bool isOpen;
  final List<ChatMessage>? messages;
  final String myId;
  final Future<void> Function(String text) onSend;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
    });
    try {
      await widget.onSend(text);
      _input.clear();
    } catch (e) {
      if (mounted) context.toast(context.errorText(e));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final msgs = widget.messages;
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(subject: widget.subject),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: msgs == null
                  ? const Center(child: CircularProgressIndicator())
                  : _MessageList(messages: msgs, myId: widget.myId),
            ),
            if (!widget.isOpen)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.beige,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_clock_outlined,
                      color: AppColors.goldDark,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.chatClosed,
                        style: AppText.bodySmall.copyWith(color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              )
            else
              _Composer(
                controller: _input,
                sending: _sending,
                canSend: _input.text.trim().isNotEmpty,
                onSend: _send,
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.subject});

  final String subject;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/inbox'),
          ),
          const SizedBox(width: 10),
          const LeadersAvatar(size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.titleSmall.copyWith(
                    color: AppColors.deepPurple,
                  ),
                ),
                Text(
                  l.chatLeadersSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.myId});

  final List<ChatMessage> messages;
  final String myId;

  static DateTime _day(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  @override
  Widget build(BuildContext context) {
    // Newest at the bottom: the list is reversed, index 0 = newest.
    final items = <Widget>[];
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      final mine = m.senderId == myId && !m.isFromStaff;
      // Group consecutive messages from the same side.
      final next = i + 1 < messages.length ? messages[i + 1] : null;
      final lastOfGroup =
          next == null ||
          (next.senderId == myId && !next.isFromStaff) != mine ||
          _day(next.createdAt) != _day(m.createdAt);
      items.add(_Bubble(message: m, mine: mine, tail: lastOfGroup));
      final prev = i > 0 ? messages[i - 1] : null;
      if (prev == null || _day(prev.createdAt) != _day(m.createdAt)) {
        items.add(_DaySeparator(day: _day(m.createdAt)));
      }
    }
    // The privacy note sits at the very top of the conversation.
    items.add(const _PrivacyPill());

    return ListView(
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      children: items,
    );
  }
}

class _PrivacyPill extends StatelessWidget {
  const _PrivacyPill();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.beige,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 14, color: AppColors.goldDark),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.l10n.chatPrivateNotice,
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    final label = diff == 0
        ? l.chatToday
        : diff == 1
        ? l.commonYesterday
        : formatDay(context, day);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.lavender,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppText.caption.copyWith(
            color: AppColors.deepPurple,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.tail,
  });

  final ChatMessage message;
  final bool mine;

  /// Last message of a group: pointed corner + more space below.
  final bool tail;

  @override
  Widget build(BuildContext context) {
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(message.createdAt.toLocal()),
      alwaysUse24HourFormat: true,
    );
    const r = Radius.circular(18);
    const small = Radius.circular(5);
    return Padding(
      padding: EdgeInsets.only(bottom: tail ? 10 : 3),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          padding: const EdgeInsets.fromLTRB(14, 9, 12, 7),
          decoration: BoxDecoration(
            color: mine ? AppColors.deepPurple : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: r,
              topRight: r,
              bottomLeft: mine || !tail ? r : small,
              bottomRight: mine && tail ? small : r,
            ),
            border: mine ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.isFromStaff)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    context.l10n.chatLeader,
                    style: AppText.labelSmall.copyWith(
                      color: AppColors.goldDark,
                    ),
                  ),
                ),
              Text(
                message.body,
                style: AppText.bodyMedium.copyWith(
                  color: mine ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.bottomRight,
                widthFactor: 1,
                child: Text(
                  time,
                  style: AppText.caption.copyWith(
                    fontSize: 11,
                    color: mine ? Colors.white70 : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              maxLength: 4000,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.bodyMedium.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: l.chatTypeMessage,
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.deepPurple),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: canSend
                ? AppColors.gold
                : AppColors.gold.withValues(alpha: 0.45),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: canSend && !sending ? onSend : null,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                          semanticLabel: l.chatSend,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
