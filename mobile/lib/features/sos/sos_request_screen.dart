import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import 'sos_widgets.dart';

/// Holy SOS form: type of need, description, anonymity.
class SosRequestScreen extends StatefulWidget {
  const SosRequestScreen({super.key});

  @override
  State<SosRequestScreen> createState() => _SosRequestScreenState();
}

class _SosRequestScreenState extends State<SosRequestScreen> {
  final _description = TextEditingController();
  HelpCategory _category = HelpCategory.prayer;
  bool _anonymous = true;
  bool _leadersOnly = false;
  bool _sending = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _description.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await Repo.submitHelpRequest(
        category: _category,
        description: text,
        anonymous: _anonymous,
        leadersOnly: _leadersOnly,
      );
      if (!mounted) return;
      context.toast(context.l10n.sosSent);
      Navigator.pop(context);
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
    const sectionStyle = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
    return Scaffold(
      appBar: AppBar(title: Text(l.sosTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const SosBanner(),
          const SizedBox(height: 8),
          Text(l.sosQ1, style: sectionStyle),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              for (final c in HelpCategory.values)
                _CategoryTile(
                  category: c,
                  selected: c == _category,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(l.sosQ2, style: sectionStyle),
          const SizedBox(height: 10),
          CountedField(
            controller: _description,
            hint: l.sosQ2Hint,
            minLines: 4,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.sosQ3, style: sectionStyle),
                    Text(
                      l.sosQ3Sub,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.purple,
            value: _leadersOnly,
            onChanged: (v) => setState(() => _leadersOnly = v ?? false),
            title: Text(l.sosLeadersOnly),
          ),
          const SizedBox(height: 12),
          AppCard(
            color: AppColors.lavender,
            child: Row(
              children: [
                const IconBubble(icon: Icons.shield_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.sosVerseRef,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        l.sosVerse,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.send_rounded, color: AppColors.gold),
            label: Text(l.sosSend),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final HelpCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.purple : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.purple : AppColors.border,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                categoryIcon(category),
                size: 32,
                color: selected ? AppColors.gold : AppColors.purple,
              ),
              const SizedBox(height: 8),
              Text(
                categoryLabel(context, category),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
