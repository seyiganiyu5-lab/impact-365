import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/locale_controller.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/yoruba_fallback.dart';
import 'l10n/generated/app_localizations.dart';

class ImpactApp extends StatelessWidget {
  const ImpactApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = LocaleController.instance;
    return ListenableBuilder(
      listenable: locale,
      builder: (context, _) => MaterialApp.router(
        title: 'Impact-365',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: appRouter,
        locale: locale.locale,
        supportedLocales: LocaleController.supported,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          YoMaterialLocalizationsDelegate(),
          YoCupertinoLocalizationsDelegate(),
          YoWidgetsLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
      ),
    );
  }
}
