// TEST-ONLY. banco-preview.html's `remapW` and `baseW`: how the preview moves a W written in OLD positions (a recorded
// run's W) to the new ones, so that a moment of a recorded run can be drawn by the Dart scene exactly as the preview
// draws it. The corner is built round the old picture (the sheet's rules.floor), so nothing moves but the places the
// sheet moves: whoever sits on a bench at SY(x), a person, a pigeon, a thing or a dog at a moved place (`moves`), else at
// a story position the sheet moved for that story (`remap` entries that moved); the frog at a moved place, beside a dog
// or a sitter that moved; the rolling cart and its man. The rule is the scene's own (`Banco.remapW`, which the review
// pictures use too, PV.pair's), the frog's part included here.
import 'package:coqui_scenes/src/banco/banco.dart';

Object? _copy(Object? v) => v is Map
    ? {for (final e in v.entries) e.key as String: _copy(e.value)}
    : v is List
    ? [for (final e in v) _copy(e)]
    : v;

/// banco-preview.html: `baseW` (juego.js fresh's fields, the scene's fresh, then [over]).
Map<String, dynamic> bancoPreviewBaseW(
  Map<String, dynamic> fresh,
  Map<String, dynamic> over,
) => {
  'spot': null,
  'twinkle': null,
  'glow': null,
  'fx': <Map<String, dynamic>>[],
  'heart': 0,
  'lost': 0,
  'resp': null,
  ...fresh,
  ..._copy(over) as Map<String, dynamic>,
};

/// banco-preview.html: `remapW` for the story [story] (its id: `PREVIEW.story`; null: every moved position).
Map<String, dynamic> bancoPreviewRemapW(
  Map<String, dynamic> w0,
  Banco scene, {
  String? story,
}) {
  final w = _copy(w0) as Map<String, dynamic>;
  scene.remapW(w, story, cq: true);
  return w;
}
