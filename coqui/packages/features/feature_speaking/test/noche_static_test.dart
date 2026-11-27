@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const uiFiles = [
    'lib/src/hablar_tab.dart',
    'lib/src/hablar_model.dart',
    'lib/src/module.dart',
    'lib/src/wording.dart',
    'lib/src/call_look.dart',
    'lib/src/call_mic.dart',
    'lib/src/call_screen.dart',
    'lib/src/motion.dart',
    'lib/src/voice_test_screen.dart',
  ];

  const strictLeftRightFiles = [
    'lib/src/hablar_tab.dart',
    'lib/src/hablar_model.dart',
  ];

  test('legacy entitlements_hook.dart is removed', () {
    expect(File('lib/src/entitlements_hook.dart').existsSync(), isFalse);
  });

  String stripComments(String path) =>
      File(path)
          .readAsLinesSync()
          .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
          .join('\n');

  test(
    'no raw Color literals or fontFamily literals in feature_speaking UI files',
    () {
      final colorRe = RegExp(r'Color\s*\(\s*0x|Color\.from\w+\s*\(');
      final fontRe = RegExp(r'\bfontFamily\b');
      for (final path in uiFiles) {
        final content = File(path).readAsStringSync();
        expect(
          colorRe.allMatches(content),
          isEmpty,
          reason: '$path contains a raw Color literal',
        );
        expect(
          fontRe.allMatches(content),
          isEmpty,
          reason: '$path contains fontFamily',
        );
      }
    },
  );

  test('no legacy Coqui UI tokens or widgets in feature_speaking UI files', () {
    final legacyRe = RegExp(
      r'\b(CoquiColors|CoquiText|CoquiShadows|CoquiIcon|CoquiIcons|LessonButton|LessonCloseButton)\b',
    );
    for (final path in uiFiles) {
      final code = stripComments(path);
      expect(
        legacyRe.allMatches(code).map((m) => m.group(0)).toList(),
        isEmpty,
        reason: '$path references a legacy Coqui UI symbol',
      );
    }
  });

  test(
    'no package:flutter/material.dart imports in feature_speaking UI files',
    () {
      for (final path in uiFiles) {
        final content = File(path).readAsStringSync();
        expect(
          content.contains('package:flutter/material.dart'),
          isFalse,
          reason: '$path imports package:flutter/material.dart',
        );
      }
    },
  );

  test('no non-directional layout APIs in feature_speaking UI files', () {
    final wordRe = RegExp(r'\b(left|right)\b', caseSensitive: false);
    final apiRe = RegExp(
      r'\bEdgeInsets\.(?:fromLTRB|only|symmetric|all)\b|'
      r'\bAlignment\.(?:topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight)\b|'
      r'\bPositioned\s*\(|'
      r'\bTextAlign\.(?:left|right)\b|'
      r'\b(?:fromLTRB|topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight)\b',
    );
    for (final path in uiFiles) {
      final code = stripComments(path);
      expect(
        apiRe.allMatches(code).map((m) => m.group(0)).toList(),
        isEmpty,
        reason: '$path contains non-directional layout API',
      );
    }
    for (final path in strictLeftRightFiles) {
      final code = stripComments(path);
      expect(
        wordRe.allMatches(code).map((m) => m.group(0)).toList(),
        isEmpty,
        reason: '$path contains left/right',
      );
    }
  });

  test(
    'no hardcoded Spanish UI string literals in feature_speaking UI files',
    () {
      final stringRe = RegExp(r'''(['"])([^'"\r\n]*)\1''');
      final spanishRe = RegExp(
        r'¿|¡|á|é|í|ó|ú|ñ|\b(?:Mapa|Palabras|Biblioteca|Hablar|Repaso|Cuál)\b',
      );
      for (final path in uiFiles) {
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
    },
  );

  test('no pet names in feature_speaking UI files', () {
    final petNameRe = RegExp(r'\b(mi amor|nene)\b', caseSensitive: false);
    for (final path in uiFiles) {
      final content = File(path).readAsStringSync();
      expect(
        petNameRe.allMatches(content).map((m) => m.group(0)).toList(),
        isEmpty,
        reason: '$path contains a disallowed pet name',
      );
    }
  });

  test('no raw Curves., Cubic(, Duration(, or NocheMotion.ms( in feature_speaking UI files outside lib/src/motion.dart', () {
    final rawMotionRe = RegExp(
      r'\bCurves\.|\bCubic\s*\(|\bDuration\s*\(|\bNocheMotion\.ms\s*\(',
    );
    for (final path in uiFiles) {
      if (path == 'lib/src/motion.dart') continue;
      final code = stripComments(path);
      expect(
        rawMotionRe.allMatches(code).map((m) => m.group(0)).toList(),
        isEmpty,
        reason: '$path contains raw motion literals outside motion.dart',
      );
    }
  });
}
