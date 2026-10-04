import 'package:material_ui/material_ui.dart';

import '../../data/repository.dart';
import '../../widgets/common.dart';

/// Bottom sheet to add a prayer point. Returns true when one was saved.
Future<bool> showAddPrayerSheet(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AddPrayerSheet(),
  );
  return saved ?? false;
}

class _AddPrayerSheet extends StatefulWidget {
  const _AddPrayerSheet();

  @override
  State<_AddPrayerSheet> createState() => _AddPrayerSheetState();
}

class _AddPrayerSheetState extends State<_AddPrayerSheet> {
  final _title = TextEditingController();
  final _details = TextEditingController();
  bool _shared = false;
  bool _anonymous = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await Repo.addPrayer(
        title: _title.text.trim(),
        details: _details.text.trim().isEmpty ? null : _details.text.trim(),
        shared: _shared,
        anonymous: _shared && _anonymous,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        context.toast(context.l10n.commonError);
        setState(() => _saving = false);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.prayerAdd,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            maxLength: 120,
            autofocus: true,
            decoration: InputDecoration(hintText: l.prayerTitleField),
          ),
          TextField(
            controller: _details,
            maxLength: 1000,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(hintText: l.prayerDetailsField),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _shared,
            onChanged: (v) => setState(() => _shared = v),
            title: Text(l.prayerShare),
          ),
          if (_shared)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v),
              title: Text(l.prayerAnonymous),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l.commonSubmit),
          ),
        ],
      ),
    );
  }
}
