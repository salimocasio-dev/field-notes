import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';

import 'fixtures/balcon_preview_fixture.dart';
import 'fixtures/banco_preview_fixture.dart';
import 'fixtures/camino_preview_fixture.dart';
import 'fixtures/campo_preview_fixture.dart';
import 'fixtures/estufa_preview_fixture.dart';
import 'fixtures/lago_preview_fixture.dart';
import 'fixtures/nevera_preview_fixture.dart';
import 'fixtures/patio_preview_fixture.dart';
import 'fixtures/preview_fixture.dart';
import 'fixtures/sala_preview_fixture.dart';

/// The 12 review pairs of cual-frente, as the content gives them (word, and each side's state and view), from the cases
/// of the preview comparison (tool/preview_shots.mjs reads them from historia/cuentos/cual-frente.json).
List<ReviewPair> frentePairs() => _pairsOf('frente', previewCases);

/// The 10 review pairs of cual-balcon, as [frentePairs] reads El frente's (tool/preview_shots.mjs --scene balcon reads
/// them from historia/cuentos/cual-balcon.json).
List<ReviewPair> balconPairs() => _pairsOf('balcon', balconPreviewCases);

/// The 11 review pairs of cual-sala, as [frentePairs] reads El frente's (tool/preview_shots.mjs --scene sala reads them
/// from historia/cuentos/cual-sala.json).
List<ReviewPair> salaPairs() => _pairsOf('sala', salaPreviewCases);

/// The 12 review pairs of cual-patio, as [frentePairs] reads El frente's (tool/preview_shots.mjs --scene patio reads them
/// from historia/cuentos/cual-patio.json; cual-camino's parque, whose "no" side is a picture of the yard, is not one of
/// them: [patioParqueNo]).
List<ReviewPair> patioPairs() =>
    _pairsOf('patio', patioPreviewCases, only: (c) => c['cual'] == null);

/// cual-camino's parque.no, the picture of the yard in El camino's pair (its state and view), from the same cases.
PictureSpec patioParqueNo() {
  final c = (jsonDecode(patioPreviewCases) as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((c) => c['id'] == 'pair.parque.no');
  return PictureSpec(
    scene: 'patio',
    set: c['set'] as Map<String, dynamic>?,
    cam: (c['cam'] as List).cast<num>(),
  );
}

/// The 13 review pairs of cual-camino, as [frentePairs] reads El frente's (tool/preview_shots.mjs --scene camino reads
/// them from historia/cuentos/cual-camino.json): the pair parque's "no" side is a picture of the yard, El patio's
/// ([patioParqueNo]), its "si" side the park's.
List<ReviewPair> caminoPairs() => _pairsOf(
  'camino',
  caminoPreviewCases,
  otherNo: {'parque': patioParqueNo()},
);

/// The 11 review pairs of cual-campo, as [frentePairs] reads El frente's (tool/preview_shots.mjs --scene campo reads them
/// from historia/cuentos/cual-campo.json).
List<ReviewPair> campoPairs() => _pairsOf('campo', campoPreviewCases);

/// The 11 review pairs of cual-lago, as [frentePairs] reads El frente's (tool/preview_shots.mjs --scene lago reads them
/// from historia/cuentos/cual-lago.json).
List<ReviewPair> lagoPairs() => _pairsOf('lago', lagoPreviewCases);

/// The 12 review pairs of cual-banco, as [frentePairs] reads El frente's (tool/preview_shots.mjs --scene banco reads them
/// from historia/cuentos/cual-banco.json).
List<ReviewPair> bancoPairs() => _pairsOf('banco', bancoPreviewCases);

/// The 12 review pairs of cual-estufa, as [frentePairs] reads El frente's (tool/preview_shots.mjs --scene estufa reads
/// them from historia/cuentos/cual-estufa.json).
List<ReviewPair> estufaPairs() => _pairsOf('estufa', estufaPreviewCases);

/// The 12 review pairs of cual-nevera, as [frentePairs] reads El frente's (tool/preview_shots.mjs --scene nevera reads
/// them from historia/cuentos/cual-nevera.json).
List<ReviewPair> neveraPairs() => _pairsOf('nevera', neveraPreviewCases);

List<ReviewPair> _pairsOf(
  String scene,
  String json, {
  bool Function(Map<String, dynamic> c)? only,
  Map<String, PictureSpec> otherNo = const {},
}) {
  final cases = (jsonDecode(json) as List).cast<Map<String, dynamic>>().where(
    (c) =>
        c['kind'] == 'pair' &&
        (c['id'] as String).startsWith('pair.') &&
        (only == null || only(c)),
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
        scene: scene,
        yes: e.value['si']!,
        no: e.value['no'] ?? otherNo[e.key]!,
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
