import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

/// Start a private conversation with the pastors / leaders.
class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key, this.initialSubject});

  final String? initialSubject;

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  late final _subject = TextEditingController(text: widget.initialSubject);
  final _body = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_subject.text.trim().isEmpty || _body.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final id = await Repo.startConversation(
        _subject.text.trim(),
        _body.text.trim(),
      );
      if (mounted) context.pushReplacement('/inbox/$id');
    } catch (_) {
      if (mounted) {
        context.toast(context.l10n.commonError);
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.inboxNewConversation)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            color: AppColors.lavender,
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.purple),
                const SizedBox(width: 10),
                Expanded(child: Text(l.chatPrivateNotice)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.chatSubject,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _subject,
            maxLength: 150,
            decoration: InputDecoration(hintText: l.chatSubjectHint),
          ),
          const SizedBox(height: 8),
          Text(
            l.chatFirstMessage,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _body,
            minLines: 6,
            maxLines: 12,
            maxLength: 4000,
            decoration: InputDecoration(hintText: l.chatFirstMessageHint),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.send_rounded, color: AppColors.gold),
            label: Text(l.chatStart),
          ),
        ],
      ),
    );
  }
}
