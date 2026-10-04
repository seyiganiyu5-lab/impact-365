import 'package:flutter/material.dart';

import '../../core/locale_controller.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

/// Choose Français / English / Yorùbá. Also changes which devotion
/// translation is loaded from Supabase.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LocaleController.instance;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileLanguage)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final loc in LocaleController.supported)
              AppCard(
                onTap: () async {
                  await controller.setLocale(loc);
                  Repo.savePreferredLanguage(loc.languageCode).ignore();
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        LocaleController.displayName(loc.languageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (controller.languageCode == loc.languageCode)
                      const Icon(Icons.check_circle, color: AppColors.gold),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
