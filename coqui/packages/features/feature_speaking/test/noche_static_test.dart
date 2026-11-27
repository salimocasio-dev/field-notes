@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const speakFiles = [
    'lib/src/hablar_tab.dart',
    'lib/src/hablar_model.dart',
    'lib/src/module.dart',
    'lib/src/wording.dart',
  ];

  const layoutFiles = [
    'lib/src/hablar_tab.dart',
    'lib/src/hablar_model.dart',
    'lib/src/wording.dart',
  ];

  test('legacy entitlements_hook.dart is removed', () {
    expect(File('lib/src/entitlements_hook.dart').existsSync(), isFalse);
  });

  String stripComments(String path) =>
      File(path)
          .readAsLinesSync()
          .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
          .join('\n');

  test('no raw hex Color or fontFamily literals in Noche Speak files', () {
    final colorRe = RegExp(r'Color\s*\(\s*0x');
    final fontRe = RegExp(r'\bfontFamily\b');
    for (final path in speakFiles) {
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

  test('no package:flutter/material.dart imports in Noche Speak files', () {
    for (final path in speakFiles) {
      final content = File(path).readAsStringSync();
      expect(
        content.contains('package:flutter/material.dart'),
        isFalse,
        reason: '$path imports package:flutter/material.dart',
      );
    }
  });

  test(
    'no non-directional layout APIs in hablar_tab.dart or hablar_model.dart',
    () {
      final wordRe = RegExp(r'\b(left|right)\b', caseSensitive: false);
      final apiRe = RegExp(
        r'fromLTRB|topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight',
      );
      for (final path in layoutFiles) {
        final code = stripComments(path);
        expect(
          wordRe.allMatches(code).map((m) => m.group(0)).toList(),
          isEmpty,
          reason: '$path contains left/right',
        );
        expect(
          apiRe.allMatches(code).map((m) => m.group(0)).toList(),
          isEmpty,
          reason: '$path contains non-directional layout API',
        );
      }
    },
  );

  test('no hardcoded Spanish UI string literals in Noche Speak files', () {
    final stringRe = RegExp(r'''(['"])([^'"\r\n]*)\1''');
    final spanishRe = RegExp(
      r'¿|¡|á|é|í|ó|ú|ñ|\b(?:Mapa|Palabras|Biblioteca|Hablar|Repaso|Cuál)\b',
    );
    for (final path in speakFiles) {
      final code = stripComments(path);
      final hits = <String>[];
      for (final m in stringRe.allMatches(code)) {
        final raw = m.group(2)!.replaceAll(RegExp(r'\$\{[^}]*\}'), '');
        if (spanishRe.hasMatch(raw)) hits.add(m.group(0)!);
      }
      expect(
        hits,
        isEmpty,
        reason: '$path contains a hardcoded Spanish string literal',
      );
    }
  });

  test('no pet names in Noche Speak files', () {
    final petNameRe = RegExp(r'\b(mi amor|nene)\b', caseSensitive: false);
    for (final path in speakFiles) {
      final content = File(path).readAsStringSync();
      expect(
        petNameRe.allMatches(content).map((m) => m.group(0)).toList(),
        isEmpty,
        reason: '$path contains a disallowed pet name',
      );
    }
  });
}
