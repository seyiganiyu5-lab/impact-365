import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/page_top_bar.dart';
import 'journal_screen.dart';

/// One journal page (one day): 3 questions + 3 thanks.
class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key, required this.day});

  final DateTime day;

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  late Future<JournalEntry> _future = Repo.journalFor(widget.day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: AsyncView<JournalEntry>(
        future: _future,
        onRetry: () => setState(() {
          _future = Repo.journalFor(widget.day);
        }),
        builder: (context, entry) => JournalEntryView(
          day: widget.day,
          initial: entry,
          onSave: (e) => Repo.saveJournal(widget.day, e),
        ),
      ),
    );
  }
}

/// Splits the saved gratitude text into the 3 lines.
List<String> splitThanks(String text) {
  final lines = text
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return [
    lines.isNotEmpty ? lines[0] : '',
    lines.length > 1 ? lines[1] : '',
    lines.length > 2 ? lines.sublist(2).join(' ') : '',
  ];
}

class JournalEntryView extends StatefulWidget {
  const JournalEntryView({
    super.key,
    required this.day,
    required this.initial,
    required this.onSave,
  });

  final DateTime day;
  final JournalEntry initial;
  final Future<void> Function(JournalEntry entry) onSave;

  @override
  State<JournalEntryView> createState() => _JournalEntryViewState();
}

class _JournalEntryViewState extends State<JournalEntryView> {
  late final _q1 = TextEditingController(text: widget.initial.godShows);
  late final _q2 = TextEditingController(text: widget.initial.mustChange);
  late final _q3 = TextEditingController(text: widget.initial.prayFor);
  late final List<TextEditingController> _thanks = [
    for (final t in splitThanks(widget.initial.gratitude))
      TextEditingController(text: t),
  ];
  late final String _start = _snapshot();
  bool _saving = false;

  List<TextEditingController> get _all => [_q1, _q2, _q3, ..._thanks];

  @override
  void initState() {
    super.initState();
    for (final c in _all) {
      c.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  String _snapshot() => _all.map((c) => c.text.trim()).join('\u0000');

  bool get _dirty => _snapshot() != _start;

  JournalEntry get _entry => JournalEntry(
    godShows: _q1.text.trim(),
    mustChange: _q2.text.trim(),
    prayFor: _q3.text.trim(),
    gratitude: _thanks
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .join('\n'),
  );

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
    });
    try {
      await widget.onSave(_entry);
      if (!mounted) return;
      context.toast(context.l10n.journalSaved);
      if (context.canPop()) {
        context.pop(true);
      } else {
        setState(() {
          _saving = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      context.toast(context.errorText(e));
    }
  }

  Future<bool> _confirmLeave() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.warmWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l.journalUnsaved,
          style: AppText.titleMedium.copyWith(color: AppColors.deepPurple),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l.journalLeave),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deepPurple,
              minimumSize: const Size(0, 44),
            ),
            child: Text(l.commonCancel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _back() async {
    if (_dirty && !await _confirmLeave()) return;
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/journal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final isToday =
        widget.day.year == now.year &&
        widget.day.month == now.month &&
        widget.day.day == now.day;
    String stripNumber(String s) => s.replaceFirst(RegExp(r'^\d+\.\s*'), '');

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.warmWhite,
        body: SafeArea(
          child: Column(
            children: [
              PageTopBar(
                title: isToday ? l.commonToday : formatDay(context, widget.day),
                onBack: _back,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Center(child: JournalProgress(count: _entry.filledCount)),
                    const SizedBox(height: 16),
                    _QuestionCard(
                      number: 1,
                      title: stripNumber(l.journalQ1),
                      hint: l.journalQ1Hint,
                      controller: _q1,
                    ),
                    const SizedBox(height: 12),
                    _QuestionCard(
                      number: 2,
                      title: stripNumber(l.journalQ2),
                      hint: l.journalQ2Hint,
                      controller: _q2,
                    ),
                    const SizedBox(height: 12),
                    _QuestionCard(
                      number: 3,
                      title: stripNumber(l.journalQ3),
                      hint: l.journalQ3Hint,
                      controller: _q3,
                    ),
                    const SizedBox(height: 12),
                    _GratitudeCard(controllers: _thanks),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
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
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 22),
                    label: Text(l.journalSave, style: AppText.labelLarge),
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.title,
    required this.hint,
    required this.controller,
  });

  final int number;
  final String title;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final done = controller.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? AppColors.gold : AppColors.lavender,
                  shape: BoxShape.circle,
                ),
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 17,
                      )
                    : Text(
                        '$number',
                        style: AppText.labelMedium.copyWith(
                          color: AppColors.deepPurple,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.titleSmall.copyWith(
                        color: AppColors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hint,
                      style: AppText.bodySmall.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 8,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: context.l10n.journalWriteHere,
              filled: true,
              fillColor: AppColors.warmWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _GratitudeCard extends StatelessWidget {
  const _GratitudeCard({required this.controllers});

  final List<TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.journalGratitude,
                  style: AppText.titleSmall.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.journalGratitudeHint,
            style: AppText.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < controllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppText.labelSmall.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controllers[i],
                      maxLength: 160,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppText.bodyMedium.copyWith(color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: l.journalThanksHint,
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.gold,
                            width: 1.5,
                          ),
                        ),
                      ),
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
