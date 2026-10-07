import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/l10n/generated/app_localizations.dart';
import 'package:impact365/widgets/common.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Widget _app(Future<int> future) => _wrap(future..ignore());

Widget _wrap(Future<int> future) => MaterialApp(
  theme: buildTheme(),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: AsyncView<int>(
      future: future,
      onRetry: () {},
      builder: (_, v) => Text('ok $v'),
    ),
  ),
);

void main() {
  testWidgets('no internet → explains the connection problem', (tester) async {
    await tester.pumpWidget(
      _app(Future.error(const SocketException('Failed host lookup'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pas de connexion internet. Réessaie.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('rate limit → "trop souvent"', (tester) async {
    await tester.pumpWidget(
      _app(
        Future.error(
          const PostgrestException(message: 'rate_limit', code: 'PT429'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('trop souvent'), findsOneWidget);
  });

  testWidgets('other errors → generic message', (tester) async {
    await tester.pumpWidget(_app(Future.error(StateError('boom'))));
    await tester.pumpAndSettle();
    expect(find.text('Une erreur est survenue. Réessaie.'), findsOneWidget);
  });

  test('offline detection', () {
    expect(isOfflineError(AuthRetryableFetchException()), isTrue);
    expect(isOfflineError(const SocketException('x')), isTrue);
    expect(isOfflineError(StateError('x')), isFalse);
  });
}
