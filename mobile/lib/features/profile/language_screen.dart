import 'package:flutter/material.dart';

import '../../core/locale_controller.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/page_top_bar.dart';

/// Choose Français / English / Yorùbá. Also changes which devotion
/// translation is loaded from Supabase.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LocaleController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => LanguageView(
        current: controller.languageCode,
        onSelect: (code) async {
          await controller.setLocale(Locale(code));
          Repo.savePreferredLanguage(code).ignore();
        },
      ),
    );
  }
}

/// A blessing written in each language, shown under its name.
const _blessings = {
  'fr': 'Que Dieu te bénisse',
  'en': 'May God bless you',
  'yo': 'Kí Ọlọ́run bùkún ọ',
};

class LanguageView extends StatelessWidget {
  const LanguageView({
    super.key,
    required this.current,
    required this.onSelect,
  });

  /// Language code in use: 'fr', 'en' or 'yo'.
  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String nameHere(String code) => switch (code) {
      'fr' => l.langFrench,
      'en' => l.langEnglish,
      _ => l.langYoruba,
    };

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            PageTopBar(title: l.profileLanguage),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.lavender,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.translate_rounded,
                        color: AppColors.deepPurple,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.languageIntro,
                    textAlign: TextAlign.center,
                    style: AppText.bodyMedium.copyWith(
                      color: AppColors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 22),
                  for (final loc in LocaleController.supported) ...[
                    _LanguageCard(
                      code: loc.languageCode,
                      nativeName: LocaleController.displayName(
                        loc.languageCode,
                      ),
                      nameHere: nameHere(loc.languageCode),
                      blessing: _blessings[loc.languageCode] ?? '',
                      selected: loc.languageCode == current,
                      onTap: () => onSelect(loc.languageCode),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: AppColors.beige,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 18,
                          color: AppColors.goldDark,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.languageNote,
                            style: AppText.bodySmall.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
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

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.code,
    required this.nativeName,
    required this.nameHere,
    required this.blessing,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String nativeName;
  final String nameHere;
  final String blessing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.ink;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.deepPurple : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.gold : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.14)
                        : AppColors.lavender,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    code.toUpperCase(),
                    style: AppText.labelLarge.copyWith(
                      color: selected ? AppColors.gold : AppColors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nativeName,
                        style: AppText.titleMedium.copyWith(color: fg),
                      ),
                      if (nameHere != nativeName)
                        Text(
                          nameHere,
                          style: AppText.caption.copyWith(
                            color: selected ? Colors.white70 : AppColors.muted,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        blessing,
                        style: AppText.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: selected ? AppColors.gold : AppColors.goldDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.gold : Colors.transparent,
                    shape: BoxShape.circle,
                    border: selected
                        ? null
                        : Border.all(color: AppColors.border, width: 1.6),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 17,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
