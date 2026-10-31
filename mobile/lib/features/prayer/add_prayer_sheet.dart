import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

/// Saves a new prayer request.
typedef SavePrayer =
    Future<void> Function({
      required String title,
      String? details,
      required bool shared,
      required bool anonymous,
    });

Future<void> _repoSave({
  required String title,
  String? details,
  required bool shared,
  required bool anonymous,
}) => Repo.addPrayer(
  title: title,
  details: details,
  shared: shared,
  anonymous: anonymous,
);

/// Bottom sheet to add a prayer point. Returns true when one was saved.
Future<bool> showAddPrayerSheet(
  BuildContext context, {
  SavePrayer? save,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.warmWhite,
    builder: (_) => AddPrayerSheet(save: save ?? _repoSave),
  );
  return saved ?? false;
}

class AddPrayerSheet extends StatefulWidget {
  const AddPrayerSheet({super.key, required this.save});

  final SavePrayer save;

  @override
  State<AddPrayerSheet> createState() => _AddPrayerSheetState();
}

class _AddPrayerSheetState extends State<AddPrayerSheet> {
  final _title = TextEditingController();
  final _details = TextEditingController();
  bool _shared = false;
  bool _anonymous = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() {
        _error = context.l10n.prayerTitleRequired;
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final details = _details.text.trim();
    try {
      await widget.save(
        title: title,
        details: details.isEmpty ? null : details,
        shared: _shared,
        anonymous: _shared && _anonymous,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
        });
        context.toast(context.errorText(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('🙏', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.prayerAdd,
                    style: AppText.titleLarge.copyWith(
                      color: AppColors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              maxLength: 120,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l.prayerTitleField,
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() {
                    _error = null;
                  });
                }
              },
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _details,
              maxLength: 1000,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l.prayerDetailsField),
            ),
            const SizedBox(height: 10),
            Text(
              l.prayerWhoPrays,
              style: AppText.titleSmall.copyWith(color: AppColors.deepPurple),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ChoiceCard(
                      emoji: '🔒',
                      title: l.prayerOnlyMe,
                      subtitle: l.prayerOnlyMeSub,
                      selected: !_shared,
                      onTap: () => setState(() {
                        _shared = false;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ChoiceCard(
                      emoji: '🤝',
                      title: l.prayerWithCommunity,
                      subtitle: l.prayerWithCommunitySub,
                      selected: _shared,
                      onTap: () => setState(() {
                        _shared = true;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            if (_shared) ...[
              const SizedBox(height: 6),
              SwitchListTile(
                value: _anonymous,
                onChanged: (v) => setState(() {
                  _anonymous = v;
                }),
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.deepPurple,
                contentPadding: const EdgeInsets.only(left: 4),
                secondary: const Icon(
                  Icons.visibility_off_outlined,
                  color: AppColors.deepPurple,
                ),
                title: Text(l.prayerAnonymous, style: AppText.bodyStrong),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
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
                label: Text(l.commonSubmit, style: AppText.labelLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.deepPurple : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                title,
                style: AppText.titleSmall.copyWith(
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppText.caption.copyWith(
                  color: selected ? Colors.white70 : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
