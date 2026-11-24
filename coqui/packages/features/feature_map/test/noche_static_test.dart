@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const n41Files = [
    'lib/src/map_screen.dart',
    'lib/src/map_perf.dart',
    'lib/src/module.dart',
  ];

  const allLibFiles = [
    'lib/feature_map.dart',
    'lib/src/map_layout.dart',
    'lib/src/map_model.dart',
    'lib/src/map_perf.dart',
    'lib/src/map_picture.dart',
    'lib/src/map_places.dart',
    'lib/src/map_screen.dart',
    'lib/src/module.dart',
    'lib/src/place_sheet.dart',
  ];

  test('no left/right layout APIs in N4.1 files', () {
    final wordRe = RegExp(r'\b(left|right)\b', caseSensitive: false);
    final apiRe = RegExp(
      r'fromLTRB|topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight',
    );
    for (final path in n41Files) {
      final content = File(path).readAsStringSync();
      expect(
        wordRe.allMatches(content),
        isEmpty,
        reason: '$path contains left/right',
      );
      expect(
        apiRe.allMatches(content),
        isEmpty,
        reason: '$path contains non-directional layout API',
      );
    }
  });

  test(
    'no raw hex Color or fontFamily literals in feature_map lib/ or dev app',
    () {
      final colorRe = RegExp(r'Color\s*\(\s*0x');
      final fontRe = RegExp(r'\bfontFamily\b');
      for (final path in [...allLibFiles, 'test/support/map_dev_app.dart']) {
        final content = File(path).readAsStringSync();
        expect(
          colorRe.allMatches(content),
          isEmpty,
          reason: '$path contains a raw hex Color literal',
        );
        expect(
          fontRe.allMatches(content),
          isEmpty,
          reason: '$path contains fontFamily',
        );
      }
    },
  );

  test('no Spanish UI strings in feature_map lib/', () {
    final spanishRe = RegExp(
      r'''(['"])([^'"]*(?:¿|¡|á|é|í|ó|ú|ñ|Mapa|Palabras|Biblioteca|Hablar|Cuál|Aquí)[^'"]*)\1''',
    );
    for (final path in allLibFiles) {
      // Strip comments so porting notes (`// app.html: aqui`) are not flagged.
      final code = File(path)
          .readAsLinesSync()
          .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
          .join('\n');
      expect(
        spanishRe.allMatches(code).map((m) => m.group(0)).toList(),
        isEmpty,
        reason: '$path contains a Spanish string literal',
      );
    }
  });
}
