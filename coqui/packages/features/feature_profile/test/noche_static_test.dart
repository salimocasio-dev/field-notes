@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const n210Files = [
    'lib/src/languages_data.dart',
    'lib/src/languages_sheet.dart',
    'lib/src/language_chip.dart',
    'lib/src/module.dart',
  ];

  test('no left/right layout APIs in N2.10 files', () {
    final wordRe = RegExp(r'\b(left|right)\b', caseSensitive: false);
    final apiRe = RegExp(
      r'fromLTRB|topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight',
    );
    for (final path in n210Files) {
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

  test('no raw hex Color or fontFamily literals in N2.10 files', () {
    final colorRe = RegExp(r'Color\s*\(\s*0x');
    final fontRe = RegExp(r'\bfontFamily\b');
    for (final path in n210Files) {
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
  });

  test(
    'no hardcoded sample languages or Spanish UI strings in N2.10 files',
    () {
      final sampleLangRe = RegExp(
        r'''(['"])([^'"]*(?:French|Arabic|Portuguese|Italian|Spanish|Español|العربية)[^'"]*)\1''',
      );
      final spanishRe = RegExp(
        r'''(['"])([^'"]*(?:¿|¡|á|é|í|ó|ú|ñ|Mapa|Palabras|Biblioteca|Hablar|Cuál|Aquí)[^'"]*)\1''',
      );
      for (final path in n210Files) {
        final code = File(path)
            .readAsLinesSync()
            .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
            .join('\n');
        expect(
          sampleLangRe.allMatches(code).map((m) => m.group(0)).toList(),
          isEmpty,
          reason: '$path contains a hardcoded language name',
        );
        expect(
          spanishRe.allMatches(code).map((m) => m.group(0)).toList(),
          isEmpty,
          reason: '$path contains a Spanish string literal',
        );
      }
    },
  );

  test('no deprecated package:flutter/material.dart import in N2.10 files', () {
    for (final path in n210Files) {
      final content = File(path).readAsStringSync();
      expect(
        content.contains('package:flutter/material.dart'),
        isFalse,
        reason: '$path imports package:flutter/material.dart',
      );
    }
  });
}
