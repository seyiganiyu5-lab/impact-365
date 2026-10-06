import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impact365/core/theme.dart';
import 'package:impact365/features/auth/auth_widgets.dart';

void main() {
  Future<String?> typeCode(WidgetTester tester, String input) async {
    final controller = TextEditingController();
    String? completed;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: CodeInput(
              controller: controller,
              onCompleted: (v) => completed = v,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('code-field')), input);
    await tester.pump();
    return completed;
  }

  testWidgets('fills the boxes and completes at 6 digits', (tester) async {
    expect(await typeCode(tester, '123'), isNull);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(await typeCode(tester, '482913'), '482913');
    for (final d in ['4', '8', '2', '9', '1', '3']) {
      expect(find.text(d), findsWidgets);
    }
  });

  testWidgets('keeps only digits (pasted text)', (tester) async {
    expect(await typeCode(tester, 'ab 12-34x56'), '123456');
  });

  testWidgets('fits a small phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await typeCode(tester, '123456');
    expect(tester.takeException(), isNull);
  });
}
