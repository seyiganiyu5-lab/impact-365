import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../features/auth/auth_widgets.dart';

/// Back arrow + centred title for pages opened on top of the tabs
/// (Holy SOS, Messages...).
class PageTopBar extends StatelessWidget {
  const PageTopBar({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          Expanded(
            // Long titles shrink a little instead of being cut.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: AppText.titleLarge.copyWith(color: AppColors.deepPurple),
              ),
            ),
          ),
          SizedBox(width: 44, child: trailing),
        ],
      ),
    );
  }
}
