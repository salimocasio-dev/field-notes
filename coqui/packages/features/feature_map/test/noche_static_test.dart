@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<String> _allLibDartFiles() {
  final files =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.path.replaceAll('\\', '/'))
          .toList()
        ..sort();
  return files;
}

String _stripLineComments(String source) => source
    .split('\n')
    .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
    .join('\n');

void main() {
  const uiFiles = [
    'lib/src/map_screen.dart',
    'lib/src/map_perf.dart',
    'lib/src/module.dart',
    'lib/src/motion.dart',
    'lib/src/place_screen.dart',
    'lib/src/scene_window.dart',
    'lib/src/wording.dart',
  ];

  test('no left/right layout APIs in UI files', () {
    final wordRe = RegExp(r'\b(left|right)\b', caseSensitive: false);
    final apiRe = RegExp(
      r'fromLTRB|topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight',
    );
    for (final path in uiFiles) {
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
      for (final path in [
        ..._allLibDartFiles(),
        'test/support/map_dev_app.dart',
      ]) {
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
    for (final path in _allLibDartFiles()) {
      final code = _stripLineComments(File(path).readAsStringSync());
      expect(
        spanishRe.allMatches(code).map((m) => m.group(0)).toList(),
        isEmpty,
        reason: '$path contains a Spanish string literal',
      );
    }
  });

  test(
    'no Duration(, Curves., or Cubic( literals anywhere under feature_map lib/',
    () {
      final forbidden = RegExp(r'\bDuration\s*\(|\bCurves\.|\bCubic\s*\(');
      for (final path in _allLibDartFiles()) {
        final code = _stripLineComments(File(path).readAsStringSync());
        expect(
          forbidden.allMatches(code).map((m) => m.group(0)).toList(),
          isEmpty,
          reason: '$path contains a raw motion literal',
        );
      }
    },
  );

  test('NocheMotion.ms( appears only in lib/src/motion.dart', () {
    final msRe = RegExp(r'\bNocheMotion\.ms\s*\(');
    for (final path in _allLibDartFiles()) {
      final code = _stripLineComments(File(path).readAsStringSync());
      if (path == 'lib/src/motion.dart') {
        expect(
          msRe.allMatches(code),
          isNotEmpty,
          reason: 'lib/src/motion.dart should declare screen-local waits',
        );
      } else {
        expect(
          msRe.allMatches(code).map((m) => m.group(0)).toList(),
          isEmpty,
          reason: '$path must not call NocheMotion.ms(',
        );
      }
    }
  });

  test('no AllowAllEntitlements anywhere under feature_map lib/', () {
    final allowAllRe = RegExp(r'\bAllowAllEntitlements\b');
    for (final path in _allLibDartFiles()) {
      final code = _stripLineComments(File(path).readAsStringSync());
      expect(
        allowAllRe.allMatches(code),
        isEmpty,
        reason: '$path must not reference AllowAllEntitlements',
      );
    }
  });
}
