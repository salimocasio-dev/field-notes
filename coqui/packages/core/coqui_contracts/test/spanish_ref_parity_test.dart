@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:test/test.dart';

/// Today's token regex copied verbatim from `feature_words/lib/src/text_rules.dart`.
final RegExp _oldTokenRegex = RegExp(r'[\p{L}\p{N}]+', unicode: true);

void _collectStrings(Object? node, Set<String> out) {
  if (node is String) {
    out.add(node);
  } else if (node is List) {
    for (final item in node) {
      _collectStrings(item, out);
    }
  } else if (node is Map) {
    for (final value in node.values) {
      _collectStrings(value, out);
    }
  }
}

void main() {
  final refDir = Directory('../../../ref');

  group('Spanish rules match old global over coqui/ref/', () {
    test('every line of coqui/ref/ story, pair and screen data matches', () {
      expect(
        refDir.existsSync(),
        isTrue,
        reason: 'coqui/ref/ must exist relative to coqui_contracts',
      );

      final lines = <String>{};
      var fileCount = 0;

      for (final sub in ['trazas', 'escenas', 'pantallas']) {
        final dir = Directory('${refDir.path}/$sub');
        if (!dir.existsSync()) continue;
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.json')) continue;
          fileCount++;
          _collectStrings(jsonDecode(entity.readAsStringSync()), lines);
        }
      }

      // Sanity floor: ref/ has hundreds of JSON files and thousands of lines.
      expect(fileCount, greaterThan(150));
      expect(lines.length, greaterThan(1500));

      for (final line in lines) {
        expect(
          Language.spanish.normalize(line),
          normalize(line),
          reason: 'normalize mismatch for ${jsonEncode(line)}',
        );
        final expectedTokens = [
          for (final m in _oldTokenRegex.allMatches(line))
            WordToken(m[0]!, m.start, m.end),
        ];
        expect(
          Language.spanish.tokens(line),
          expectedTokens,
          reason: 'tokens mismatch for ${jsonEncode(line)}',
        );
      }
    });

    test('every string case in coqui/ref/progress/*/16-norm.json matches JS PAL.norm', () {
      final progressDir = Directory('${refDir.path}/progress');
      expect(progressDir.existsSync(), isTrue);

      var checked = 0;
      for (final entity in progressDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('16-norm.json')) continue;
        final doc =
            jsonDecode(entity.readAsStringSync()) as Map<String, dynamic>;
        final steps = doc['steps'] as List;
        for (final rawStep in steps) {
          final step = rawStep as Map<String, dynamic>;
          final args = step['args'] as List;
          final arg = args.isEmpty ? null : args.first;
          if (arg != null && arg is! String) continue;
          final expected = step['returns'] as String;
          expect(
            Language.spanish.normalize(arg as String?),
            expected,
            reason: '16-norm step ${step['i']} (${jsonEncode(arg)})',
          );
          expect(normalize(arg), expected);
          checked++;
        }
      }
      expect(checked, greaterThan(10));
    });
  });
}
