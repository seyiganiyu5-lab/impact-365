import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

/// A prayer shared by a member, with the "J'ai prié" button.
class CommunityPrayerCard extends StatefulWidget {
  const CommunityPrayerCard({super.key, required this.prayer, this.onToggle});

  final CommunityPrayer prayer;

  /// Saves "I prayed" (prayer id, prayed). Tests pass their own.
  final Future<void> Function(String prayerId, bool prayed)? onToggle;

  @override
  State<CommunityPrayerCard> createState() => CommunityPrayerCardState();
}

class CommunityPrayerCardState extends State<CommunityPrayerCard> {
  late bool _prayed = widget.prayer.iPrayed;
  late int _count = widget.prayer.intercessionCount;
  bool _saving = false;

  Future<void> _toggle() async {
    if (_saving) return;
    final next = !_prayed;
    setState(() {
      _prayed = next;
      _count += next ? 1 : -1;
      _saving = true;
    });
    try {
      await (widget.onToggle ?? Repo.setIPrayed)(widget.prayer.id, next);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _prayed = !next;
        _count += next ? -1 : 1;
      });
      context.toast(context.errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.prayer;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.authorName == null
                      ? AppColors.beige
                      : AppColors.lavender,
                  shape: BoxShape.circle,
                ),
                child: p.authorName == null
                    ? const Icon(
                        Icons.visibility_off_outlined,
                        size: 14,
                        color: AppColors.goldDark,
                      )
                    : Text(
                        p.authorName!.trim().isEmpty
                            ? '?'
                            : p.authorName!.trim()[0].toUpperCase(),
                        style: AppText.labelSmall.copyWith(
                          color: AppColors.deepPurple,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.authorName ?? l.anonymous,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ),
              Text(
                formatDay(context, p.createdAt),
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p.title,
            style: AppText.titleSmall.copyWith(color: AppColors.ink),
          ),
          if ((p.details ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              p.details!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodySmall.copyWith(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.prayerPrayedCount(_count),
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ),
              _PrayedButton(
                prayed: _prayed,
                label: l.prayerIPrayed,
                onTap: _toggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrayedButton extends StatelessWidget {
  const _PrayedButton({
    required this.prayed,
    required this.label,
    required this.onTap,
  });

  final bool prayed;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: prayed ? AppColors.gold : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: prayed ? AppColors.gold : AppColors.deepPurple),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(prayed ? '🙏' : '🤲', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.labelSmall.copyWith(
                  fontSize: 12,
                  color: prayed ? Colors.white : AppColors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
