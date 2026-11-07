import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/page_top_bar.dart';
import 'sos_widgets.dart';

/// "J'ai besoin d'aide": type of need, description, who can see it.
class SosRequestScreen extends StatefulWidget {
  const SosRequestScreen({super.key, this.submit});

  /// Sends the request. Tests pass their own; the app uses Supabase.
  final Future<void> Function({
    required HelpCategory category,
    required String description,
    required bool anonymous,
    required bool leadersOnly,
  })?
  submit;

  @override
  State<SosRequestScreen> createState() => _SosRequestScreenState();
}

class _SosRequestScreenState extends State<SosRequestScreen> {
  final _description = TextEditingController();
  HelpCategory _category = HelpCategory.prayer;
  bool _anonymous = true;
  bool _leadersOnly = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final text = _description.text.trim();
    if (text.isEmpty) {
      setState(() => _error = context.l10n.sosDescribeRequired);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await (widget.submit ?? Repo.submitHelpRequest)(
        category: _category,
        description: text,
        anonymous: _anonymous,
        leadersOnly: _leadersOnly,
      );
      if (!mounted) return;
      // Sent: stop the spinner before showing the confirmation.
      setState(() => _sending = false);
      final seeRequests = await showDialog<bool>(
        context: context,
        builder: (_) => const _SentDialog(),
      );
      if (!mounted) return;
      if (seeRequests == true) {
        context.pushReplacement('/sos/mine');
      } else {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        context.toast(context.errorText(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            PageTopBar(title: l.sosNeedHelp),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  _StepTitle(number: 1, text: l.sosStepType),
                  const SizedBox(height: 12),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      // Square-ish tiles that grow with the phone's text
                      // size (emoji + 2-line label always fit).
                      mainAxisExtent: _tileHeight(context),
                    ),
                    children: [
                      for (final c in HelpCategory.values)
                        _CategoryTile(
                          category: c,
                          selected: c == _category,
                          onTap: () => setState(() => _category = c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _StepTitle(number: 2, text: l.sosStepDescribe),
                  const SizedBox(height: 10),
                  CountedField(
                    controller: _description,
                    hint: l.sosQ2Hint,
                    minLines: 4,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _error!,
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _StepTitle(number: 3, text: l.sosStepPrivacy),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _PrivacySwitch(
                          icon: Icons.visibility_off_outlined,
                          title: l.sosAnonymousTitle,
                          subtitle: l.sosAnonymousSub,
                          value: _anonymous,
                          onChanged: (v) => setState(() => _anonymous = v),
                        ),
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.border,
                        ),
                        _PrivacySwitch(
                          icon: Icons.shield_outlined,
                          title: l.sosLeadersOnlyTitle,
                          subtitle: l.sosLeadersOnlySub,
                          value: _leadersOnly,
                          onChanged: (v) => setState(() => _leadersOnly = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SosVerse(),
                  const SizedBox(height: 20),
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
                      label: Text(l.sosSend, style: AppText.labelLarge),
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

/// Category tile height: about square, never shorter than its content.
double _tileHeight(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final tile = (width - 40 - 20) / 3;
  final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
  final content = 12 + 6 + 4 + 38 * scale + 2 * 18 * scale;
  return tile / 1.05 > content ? tile / 1.05 : content;
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
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
            '$number',
            style: AppText.labelMedium.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppText.titleSmall.copyWith(color: AppColors.deepPurple),
          ),
        ),
      ],
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
      color: selected ? AppColors.deepPurple : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                categoryEmoji(category),
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(height: 6),
              Text(
                categoryLabel(context, category),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppText.labelSmall.copyWith(
                  fontSize: 12,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacySwitch extends StatelessWidget {
  const _PrivacySwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.deepPurple,
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 10, 4),
      secondary: Icon(icon, color: AppColors.deepPurple),
      title: Text(title, style: AppText.bodyStrong),
      subtitle: Text(
        subtitle,
        style: AppText.bodySmall.copyWith(color: AppColors.muted),
      ),
    );
  }
}

class _SentDialog extends StatelessWidget {
  const _SentDialog();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Dialog(
      backgroundColor: AppColors.warmWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.lavender,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppColors.deepPurple,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.sosSentTitle,
              textAlign: TextAlign.center,
              style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
            ),
            const SizedBox(height: 8),
            Text(
              l.sosSentText,
              textAlign: TextAlign.center,
              style: AppText.bodyMedium.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(l.sosSeeMyRequests, style: AppText.labelLarge),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: AppColors.muted),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
