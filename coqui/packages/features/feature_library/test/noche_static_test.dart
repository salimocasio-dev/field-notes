import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const files = [
    'lib/src/reading_home.dart',
    'lib/src/text_reader.dart',
    'lib/src/reader_model.dart',
    'lib/src/reader_pagination.dart',
    'lib/src/reader_page.dart',
    'lib/src/reader_settings_sheet.dart',
    'lib/src/book_coverage.dart',
    'lib/src/wording.dart',
    'lib/src/book_importer.dart',
    'lib/src/import_screen.dart',
    'lib/src/reading.dart',
    'lib/src/story_generator.dart',
    'lib/src/write_story_sheet.dart',
    'lib/src/motion.dart',
    'lib/src/module.dart',
  ];

  final forbidden = <String, RegExp>{
    'raw hex Color': RegExp(r'Color\(0x'),
    'raw Color.fromRGBO/fromARGB': RegExp(r'Color\.from(?:RGBO|ARGB)\('),
    'hardcoded fontFamily': RegExp(r'\bfontFamily\b'),
    'legacy CoquiColors': RegExp(r'\bCoquiColors\b'),
    'legacy CoquiText': RegExp(r'\bCoquiText\b'),
    'legacy CoquiButton': RegExp(r'\bCoquiButton\b'),
    'legacy CoquiCard': RegExp(r'\bCoquiCard\b'),
    'non-directional EdgeInsets.fromLTRB': RegExp(r'EdgeInsets\.fromLTRB'),
    'non-directional left: parameter': RegExp(r'\bleft:'),
    'non-directional right: parameter': RegExp(r'\bright:'),
    'non-directional Alignment.centerLeft': RegExp(r'Alignment\.centerLeft'),
    'non-directional Alignment.centerRight': RegExp(r'Alignment\.centerRight'),
    'TextAlign.justify': RegExp(r'TextAlign\.justify'),
    'direct flutter/material import': RegExp(r'package:flutter/material\.dart'),
    'Spanish literal CAPÍTULO': RegExp(r'CAPÍTULO', caseSensitive: false),
    'Duration literal (Page 24 Part 1.2)': RegExp(r'\bDuration\('),
    'Curves literal (Page 24 Part 1.2)': RegExp(r'\bCurves\.'),
    'Cubic literal (Page 24 Part 1.2)': RegExp(r'\bCubic\('),
  };

  for (final path in files) {
    test(
      '$path uses Noche tokens, motion rules, directional layout, and material_ui only',
      () {
        final source = File(path).readAsStringSync();
        for (final entry in forbidden.entries) {
          expect(
            entry.value.hasMatch(source),
            isFalse,
            reason: '$path must not contain ${entry.key}',
          );
        }
        if (path != 'lib/src/motion.dart') {
          expect(
            RegExp(r'NocheMotion\.ms\(').hasMatch(source),
            isFalse,
            reason: '$path must not call NocheMotion.ms( outside motion.dart',
          );
        }
      },
    );
  }
}
