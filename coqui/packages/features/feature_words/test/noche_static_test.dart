@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const libFiles = [
    'lib/feature_words.dart',
    'lib/src/add_box.dart',
    'lib/src/module.dart',
    'lib/src/motion.dart',
    'lib/src/text_rules.dart',
    'lib/src/word_sheet.dart',
    'lib/src/wording.dart',
    'lib/src/words_tab.dart',
    'lib/src/words_view.dart',
  ];

  const toolFiles = ['tool/dev_main.dart', 'tool/dev_services.dart'];

  test('no left/right layout APIs in feature_words lib/', () {
    final wordRe = RegExp(r'\b(left|right)\b', caseSensitive: false);
    final apiRe = RegExp(
      r'fromLTRB|topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight',
    );
    for (final path in libFiles) {
      final code = File(path)
          .readAsLinesSync()
          .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
          .join('\n');
      expect(
        wordRe.allMatches(code),
        isEmpty,
        reason: '$path contains left/right',
      );
      expect(
        apiRe.allMatches(code),
        isEmpty,
        reason: '$path contains non-directional layout API',
      );
    }
  });

  test(
    'no raw hex Color or fontFamily literals in feature_words lib/ or tool/',
    () {
      final colorRe = RegExp(r'Color\s*\(\s*0x');
      final fontRe = RegExp(r'\bfontFamily\b');
      for (final path in [...libFiles, ...toolFiles]) {
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

  test('no package:flutter/material.dart imports in lib/ or tool/', () {
    for (final path in [...libFiles, ...toolFiles]) {
      final content = File(path).readAsStringSync();
      expect(
        content.contains('package:flutter/material.dart'),
        isFalse,
        reason: '$path imports package:flutter/material.dart',
      );
    }
  });

  test('no Spanish UI string literals in feature_words lib/', () {
    final spanishRe = RegExp(
      r'''(['"])([^'"]*(?:¿|¡|á|é|í|ó|ú|ñ|Mapa|Palabras|Biblioteca|Hablar|Repaso|Cuál)[^'"]*)\1''',
    );
    for (final path in libFiles) {
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

  test('no raw Duration(, Curves., Cubic(, or stray NocheMotion.ms( in feature_words lib/', () {
    final rawMotionRe = RegExp(r'Duration\s*\(|Curves\.|Cubic\s*\(');
    final msRe = RegExp(r'NocheMotion\.ms\s*\(');
    for (final path in libFiles) {
      final content = File(path).readAsStringSync();
      expect(
        rawMotionRe.allMatches(content),
        isEmpty,
        reason: '$path contains a raw Duration/Curves/Cubic literal',
      );
      if (path != 'lib/src/motion.dart') {
        expect(
          msRe.allMatches(content),
          isEmpty,
          reason: '$path contains NocheMotion.ms( outside lib/src/motion.dart',
        );
      }
    }
  });
}
