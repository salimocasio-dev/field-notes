@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const nocheFiles = [
    'lib/src/languages_data.dart',
    'lib/src/languages_sheet.dart',
    'lib/src/language_chip.dart',
    'lib/src/me_data.dart',
    'lib/src/motion.dart',
    'lib/src/yo_screen.dart',
    'lib/src/about_sheet.dart',
    'lib/src/install_hint.dart',
    'lib/src/module.dart',
    'lib/src/plans_screen.dart',
    'lib/src/welcome.dart',
    'lib/src/welcome_gate.dart',
  ];

  test('no left/right layout APIs in Noche files', () {
    final wordRe = RegExp(r'\b(left|right)\b', caseSensitive: false);
    final apiRe = RegExp(
      r'fromLTRB|topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight',
    );
    for (final path in nocheFiles) {
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

  test('no raw hex Color or fontFamily literals in Noche files', () {
    final colorRe = RegExp(r'Color\s*\(\s*0x');
    final fontRe = RegExp(r'\bfontFamily\b');
    for (final path in nocheFiles) {
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
    'no hardcoded sample languages or Spanish UI strings in Noche files',
    () {
      final sampleLangRe = RegExp(
        r'''(['"])([^'"]*(?:French|Arabic|Portuguese|Italian|Spanish|Español|العربية)[^'"]*)\1''',
      );
      final spanishRe = RegExp(
        r'''(['"])([^'"]*(?:¿|¡|á|é|í|ó|ú|ñ|Mapa|Palabras|Biblioteca|Hablar|Cuál|Aquí)[^'"]*)\1''',
      );
      for (final path in nocheFiles) {
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

  test('no deprecated package:flutter/material.dart import in Noche files', () {
    for (final path in nocheFiles) {
      final content = File(path).readAsStringSync();
      expect(
        content.contains('package:flutter/material.dart'),
        isFalse,
        reason: '$path imports package:flutter/material.dart',
      );
    }
  });

  test('no Duration(, Curves., or Cubic( anywhere under lib/', () {
    final motionLiteralRe = RegExp(r'Duration\(|Curves\.|Cubic\(');
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      expect(
        motionLiteralRe.allMatches(content),
        isEmpty,
        reason: '${file.path} contains a raw Duration/Curve/Cubic literal',
      );
    }
  });

  test('NocheMotion.ms( appears only in lib/src/motion.dart under lib/', () {
    final msRe = RegExp(r'NocheMotion\.ms\(');
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    var foundInMotion = false;
    for (final file in dartFiles) {
      final normalized = file.path.replaceAll('\\', '/');
      final hasMatch = msRe.hasMatch(file.readAsStringSync());
      if (normalized == 'lib/src/motion.dart') {
        foundInMotion = hasMatch;
      } else {
        expect(
          hasMatch,
          isFalse,
          reason: '$normalized must not call NocheMotion.ms(',
        );
      }
    }
    expect(
      foundInMotion,
      isTrue,
      reason: 'lib/src/motion.dart should declare waits via NocheMotion.ms(',
    );
  });
}
