@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const nocheScreenFiles = [
    'lib/src/motion.dart',
    'lib/src/wording.dart',
    'lib/src/screen/story_bubble.dart',
    'lib/src/screen/story_end.dart',
    'lib/src/screen/story_header.dart',
    'lib/src/screen/story_mic.dart',
    'lib/src/screen/story_not_ready.dart',
    'lib/src/screen/story_picture.dart',
    'lib/src/screen/story_screen.dart',
  ];

  const motionCheckedFiles = [
    'lib/src/wording.dart',
    'lib/src/screen/story_bubble.dart',
    'lib/src/screen/story_end.dart',
    'lib/src/screen/story_header.dart',
    'lib/src/screen/story_mic.dart',
    'lib/src/screen/story_not_ready.dart',
    'lib/src/screen/story_picture.dart',
    'lib/src/screen/story_screen.dart',
  ];

  const toolFiles = ['tool/dev_main.dart'];

  test(
    'no raw hex Color or fontFamily literals in Noche screen files or dev_main',
    () {
      final colorRe = RegExp(r'Color\s*\(\s*0x');
      final fontRe = RegExp(r'\bfontFamily\b');
      for (final path in [...nocheScreenFiles, ...toolFiles]) {
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

  test(
    'no package:flutter/material.dart imports in feature_story lib/ or tool/',
    () {
      for (final path in [...nocheScreenFiles, ...toolFiles]) {
        final content = File(path).readAsStringSync();
        expect(
          content.contains('package:flutter/material.dart'),
          isFalse,
          reason: '$path imports package:flutter/material.dart',
        );
      }
    },
  );

  test('no legacy CoquiColors/CoquiText/LessonFrame/LessonButton in Noche screen files', () {
    final legacyRe = RegExp(
      r'\b(CoquiColors|CoquiText|CoquiShadows|CoquiIcon|CoquiIcons|LessonFrame|LessonButton|LessonStartButton|LessonCloseButton|LessonSoundButton|LessonProgressDashes)\b',
    );
    for (final path in nocheScreenFiles) {
      final code = File(path)
          .readAsLinesSync()
          .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
          .join('\n');
      expect(
        legacyRe.allMatches(code).map((m) => m.group(0)).toList(),
        isEmpty,
        reason: '$path references legacy v=39 UI token or widget',
      );
    }
  });

  test('no non-directional left/right layout APIs in Noche screen files', () {
    final apiRe = RegExp(
      r'EdgeInsets\.fromLTRB|EdgeInsets\.only\([^)]*\b(left|right)\b|'
      r'Alignment\.(topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight)|'
      r'TextAlign\.(left|right)|'
      r'Positioned\([^)]*\b(left|right)\b',
    );
    for (final path in nocheScreenFiles) {
      final code = File(path)
          .readAsLinesSync()
          .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
          .join('\n');
      expect(
        apiRe.allMatches(code).map((m) => m.group(0)).toList(),
        isEmpty,
        reason: '$path uses non-directional left/right layout API',
      );
    }
  });

  test('no Spanish or Arabic UI string literals in Noche screen files', () {
    final nonEnglishUiRe = RegExp(
      r'''(['"])([^'"]*(?:¿|¡|á|é|í|ó|ú|ñ|Micrófono|Escucha|Otra vez|Toca y habla|Te escucho|Un momento|[\u0600-\u06FF])[^'"]*)\1''',
    );
    for (final path in nocheScreenFiles) {
      final code = File(path)
          .readAsLinesSync()
          .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
          .join('\n');
      expect(
        nonEnglishUiRe.allMatches(code).map((m) => m.group(0)).toList(),
        isEmpty,
        reason: '$path contains a hardcoded Spanish or Arabic UI string',
      );
    }
  });

  test('no raw Duration(, Curves., Cubic(, or NocheMotion.ms( in Noche screen files outside motion.dart', () {
    final motionRe = RegExp(
      r'\b(Duration\s*\(|Curves\.|Cubic\s*\(|NocheMotion\.ms\s*\()',
    );
    for (final path in motionCheckedFiles) {
      final code = File(path)
          .readAsLinesSync()
          .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
          .join('\n');
      expect(
        motionRe.allMatches(code).map((m) => m.group(0)).toList(),
        isEmpty,
        reason: '$path contains a forbidden raw motion token or NocheMotion.ms',
      );
    }
  });
}
