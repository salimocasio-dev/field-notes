import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reading_home.dart uses Noche tokens, directional layout, and material_ui only', () {
    final source = File('lib/src/reading_home.dart').readAsStringSync();

    final forbidden = <String, RegExp>{
      'raw hex Color': RegExp(r'Color\(0x'),
      'hardcoded fontFamily': RegExp(r'\bfontFamily\b'),
      'legacy CoquiColors': RegExp(r'\bCoquiColors\b'),
      'legacy CoquiText': RegExp(r'\bCoquiText\b'),
      'legacy CoquiButton': RegExp(r'\bCoquiButton\b'),
      'legacy CoquiCard': RegExp(r'\bCoquiCard\b'),
      'non-directional EdgeInsets.fromLTRB': RegExp(r'EdgeInsets\.fromLTRB'),
      'non-directional left: parameter': RegExp(r'\bleft:'),
      'non-directional right: parameter': RegExp(r'\bright:'),
      'non-directional Alignment.centerLeft': RegExp(r'Alignment\.centerLeft'),
      'non-directional Alignment.centerRight': RegExp(
        r'Alignment\.centerRight',
      ),
      'direct flutter/material import': RegExp(
        r'package:flutter/material\.dart',
      ),
    };

    for (final entry in forbidden.entries) {
      expect(
        entry.value.hasMatch(source),
        isFalse,
        reason: 'reading_home.dart must not contain ${entry.key}',
      );
    }
  });
}
