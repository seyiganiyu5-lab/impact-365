import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

/// "Supprimer mon compte": explains what is erased, then asks the member to
/// type a word (SUPPRIMER / DELETE) so it cannot happen by accident.
Future<void> showDeleteAccountDialog(BuildContext context) async {
  final deleted = await showDialog<bool>(
    context: context,
    builder: (_) => const _DeleteAccountDialog(),
  );
  if (deleted == true && context.mounted) {
    context.toast(context.l10n.deleteDone);
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _word = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _word.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Repo.deleteMyAccount();
      // The account no longer exists: clear the session on this phone.
      try {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is PostgrestException && e.message == 'last_admin'
            ? context.l10n.deleteErrLastAdmin
            : context.errorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ready = _word.text.trim().toUpperCase() == l.deleteWord;
    return AlertDialog(
      backgroundColor: AppColors.warmWhite,
      title: Text(
        l.deleteTitle,
        style: AppText.titleLarge.copyWith(color: AppColors.danger),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.deleteText,
              style: AppText.bodyMedium.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 16),
            Text(
              l.deleteTypeToConfirm(l.deleteWord),
              style: AppText.bodySmall.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _word,
              enabled: !_busy,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(hintText: l.deleteWord),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppText.bodySmall.copyWith(color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: ready && !_busy ? _delete : null,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l.deleteConfirm),
        ),
      ],
    );
  }
}
