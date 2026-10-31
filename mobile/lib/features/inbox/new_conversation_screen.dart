import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/page_top_bar.dart';
import 'inbox_screen.dart';

/// Start a private conversation with the pastors / leaders.
class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key, this.initialSubject, this.start});

  final String? initialSubject;

  /// Creates the conversation and returns its id. Tests pass their own.
  final Future<String> Function(String subject, String body)? start;

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  late final _subject = TextEditingController(text: widget.initialSubject);
  final _body = TextEditingController();
  bool _sending = false;
  String? _subjectError;
  String? _bodyError;

  @override
  void initState() {
    super.initState();
    // Keeps the selected topic chip in sync with the subject field.
    _subject.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final l = context.l10n;
    final subject = _subject.text.trim();
    final body = _body.text.trim();
    setState(() {
      _subjectError = subject.isEmpty ? l.chatSubjectRequired : null;
      _bodyError = body.isEmpty ? l.chatBodyRequired : null;
    });
    if (_subjectError != null || _bodyError != null) return;
    setState(() {
      _sending = true;
    });
    try {
      final id = await (widget.start ?? Repo.startConversation)(subject, body);
      if (mounted) context.pushReplacement('/inbox/$id');
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
        });
        context.toast(context.errorText(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final topics = [
      ('💬', l.topicAdvice),
      ('🙏', l.topicPrayer),
      ('🌧️', l.topicHard),
      ('📖', l.topicFaith),
      ('✨', l.topicTestimony),
    ];
    final current = _subject.text.trim();

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            PageTopBar(title: l.inboxNewConversation),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  // Who will read it.
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.deepPurple,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const LeadersAvatar(size: 46, ring: true),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.chatLeadersSubtitle,
                                style: AppText.titleSmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 1),
                                    child: Icon(
                                      Icons.lock_rounded,
                                      size: 13,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      l.chatPrivateNotice,
                                      style: AppText.caption.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l.newConvTopicsTitle,
                    style: AppText.titleSmall.copyWith(
                      color: AppColors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (emoji, label) in topics)
                        _TopicChip(
                          label: '$emoji $label',
                          selected: current == label,
                          onTap: () {
                            _subject.text = label;
                            _subject.selection = TextSelection.collapsed(
                              offset: label.length,
                            );
                            setState(() {
                              _subjectError = null;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _Label(l.chatSubject),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subject,
                    maxLength: 150,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: l.chatSubjectHint,
                      errorText: _subjectError,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Label(l.chatFirstMessage),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _body,
                    minLines: 5,
                    maxLines: 10,
                    maxLength: 4000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: l.chatFirstMessageHint,
                      errorText: _bodyError,
                    ),
                    onChanged: (_) {
                      if (_bodyError != null) {
                        setState(() {
                          _bodyError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.gold.withValues(
                          alpha: 0.6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 20),
                      label: Text(l.chatStart, style: AppText.labelLarge),
                    ),
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.titleSmall.copyWith(color: AppColors.deepPurple),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: AppText.labelSmall.copyWith(
              fontSize: 12.5,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
