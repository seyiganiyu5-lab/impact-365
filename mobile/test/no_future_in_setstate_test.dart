import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `setState(() => _x = Repo.something())` returns the Future from the
/// closure, which Flutter rejects at runtime ("setState() callback argument
/// returned a Future"). Use a block body: `setState(() { _x = ...; });`.
void main() {
  test('no setState arrow closure assigns a Future', () {
    final bad = RegExp(r'setState\(\(\)\s*=>\s*_\w+\s*=\s*(Repo\.|_load\b)');
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (bad.hasMatch(lines[i])) offenders.add('${file.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
