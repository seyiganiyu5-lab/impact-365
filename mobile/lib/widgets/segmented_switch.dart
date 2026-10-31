import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Two (or more) tabs in a white pill; the selected one is purple.
class SegmentedSwitch extends StatelessWidget {
  const SegmentedSwitch({
    super.key,
    required this.index,
    required this.labels,
    required this.badges,
    required this.onChanged,
  });

  final int index;
  final List<String> labels;

  /// Gold count next to each label (0 = hidden).
  final List<int> badges;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 42,
                  decoration: BoxDecoration(
                    color: i == index
                        ? AppColors.deepPurple
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.labelMedium.copyWith(
                            color: i == index ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                      if (badges[i] > 0) ...[
                        const SizedBox(width: 6),
                        CountBadge(count: badges[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small gold count bubble.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppText.labelSmall.copyWith(color: Colors.white, fontSize: 11),
      ),
    );
  }
}
