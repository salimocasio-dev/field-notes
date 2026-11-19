import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';

import 'fixtures/preview_fixture.dart';

/// The 12 review pairs of cual-frente, as the content gives them (word, and each side's state and view), from the cases
/// of the preview comparison (tool/preview_shots.mjs reads them from historia/cuentos/cual-frente.json).
List<ReviewPair> frentePairs() {
  final cases = (jsonDecode(previewCases) as List)
      .cast<Map<String, dynamic>>()
      .where(
        (c) => c['kind'] == 'pair' && (c['id'] as String).startsWith('pair.'),
      );
  final byWord = <String, Map<String, PictureSpec>>{};
  for (final c in cases) {
    (byWord[c['word'] as String] ??= {})[c['side'] as String] = PictureSpec(
      set: c['set'] as Map<String, dynamic>?,
      cam: (c['cam'] as List).cast<num>(),
    );
  }
  return [
    for (final e in byWord.entries)
      ReviewPair(
        word: e.key,
        say: e.key,
        scene: 'frente',
        yes: e.value['si']!,
        no: e.value['no']!,
      ),
  ];
}
