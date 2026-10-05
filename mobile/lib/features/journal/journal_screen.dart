import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

/// "Mon Journal" — private reflections, one entry per day.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _q1 = TextEditingController();
  final _q2 = TextEditingController();
  final _q3 = TextEditingController();
  final _gratitude = TextEditingController();
  DateTime _day = DateTime.now();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_q1, _q2, _q3, _gratitude]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final e = await Repo.journalFor(_day);
      _q1.text = e.godShows;
      _q2.text = e.mustChange;
      _q3.text = e.prayFor;
      _gratitude.text = e.gratitude;
    } catch (_) {
      if (mounted) context.toast(context.l10n.commonError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Repo.saveJournal(
        _day,
        JournalEntry(
          godShows: _q1.text.trim(),
          mustChange: _q2.text.trim(),
          prayFor: _q3.text.trim(),
          gratitude: _gratitude.text.trim(),
        ),
      );
      if (mounted) context.toast(context.l10n.journalSaved);
    } catch (_) {
      if (mounted) context.toast(context.l10n.commonError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _day = picked);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(l.journalTitle),
            Text(
              formatDay(context, _day),
              style: AppText.bodySmall.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.purple,
        foregroundColor: AppColors.gold,
        onPressed: _saving || _loading ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.check_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                Text(
                  l.journalSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                AppCard(
                  color: AppColors.beige,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        color: AppColors.purple,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.journalVerse, style: AppText.scripture),
                            const SizedBox(height: 6),
                            Text(
                              l.journalVerseRef,
                              style: AppText.scriptureRef.copyWith(
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _Question(
                  icon: Icons.lightbulb_outline_rounded,
                  title: l.journalQ1,
                  hint: l.journalQ1Hint,
                  controller: _q1,
                ),
                _Question(
                  icon: Icons.autorenew_rounded,
                  title: l.journalQ2,
                  hint: l.journalQ2Hint,
                  controller: _q2,
                ),
                _Question(
                  icon: Icons.volunteer_activism_rounded,
                  title: l.journalQ3,
                  hint: l.journalQ3Hint,
                  controller: _q3,
                ),
                AppCard(
                  gradient: AppColors.purpleGradient,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_border_rounded,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.journalGratitude,
                            style: AppText.titleSmall.copyWith(
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.journalGratitudeHint,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      CountedField(
                        controller: _gratitude,
                        hint: l.journalWriteHere,
                        minLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.icon,
    required this.title,
    required this.hint,
    required this.controller,
  });

  final IconData icon;
  final String title;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBubble(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.titleSmall.copyWith(
                        color: AppColors.purple,
                      ),
                    ),
                    const SizedBox(height: 4),
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
          CountedField(
            controller: controller,
            hint: context.l10n.journalWriteHere,
          ),
        ],
      ),
    );
  }
}
