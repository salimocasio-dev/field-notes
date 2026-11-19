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

/// The level-check items that have a picture of El frente (historia/datos/nivel.json: `w`, `s`, `p`), as the content has
/// them. The test that reads the real file (vm) checks this copy against it.
const String frenteLevelJson = r'''[
 {"w": "abuela", "s": 1, "p": [["abuela", "si", 166], ["mamá", "si"], ["papá", "si"], ["hermana", "si"]]},
 {"w": "puerta", "s": 1, "p": [["puerta", "si", 166], ["ventana", "si", 112], ["silla", "si"], ["sol", "si"]]},
 {"w": "abre", "s": 2, "p": [["abre", "si", 112], ["abre", "no", 112], ["puerta", "si", 166], ["jugo", "si"]]},
 {"w": "hola", "s": 2, "p": [["hola", "si", 160], ["adiós", "si", 160], ["se sienta", "si", 80], ["juega", "si", 130]]},
 {"w": "silla", "s": 4, "p": [["silla", "si"], ["silla", "no"], ["jugo", "si"], ["ventana", "si", 112]]}
]''';

/// [frenteLevelJson] as items.
List<LevelItem> frenteLevelItems() => [
  for (final q in jsonDecode(frenteLevelJson) as List)
    LevelItem.fromJson(q as Map<String, dynamic>),
];
