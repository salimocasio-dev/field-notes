// TEST-ONLY. mesa-preview.html's `remapW` and `baseW`: how the preview moves a W written in OLD positions (a recorded
// run's W) to the new ones, so that a moment of a recorded run can be drawn by the Dart scene exactly as the preview
// draws it. The kitchen is built round the old picture (the sheet's rules.floor), so nothing moves but the places the
// sheet moves: whoever sits at SILLA[i] to 150 + SD[i]; a person, Canelo, a thing or the shown thing at a moved place
// (`moves`), else at a story move of that story (`storyMoves`, the story file's own first); the jug pouring by its seat;
// the frog at a moved place. The rule is the scene's own (`Mesa.remapW`, which the review pictures use too, PV.pair's).
import 'package:coqui_scenes/src/mesa/mesa.dart';

Object? _copy(Object? v) => v is Map
    ? {for (final e in v.entries) e.key as String: _copy(e.value)}
    : v is List
    ? [for (final e in v) _copy(e)]
    : v;

/// mesa-preview.html: `baseW` (juego.js fresh's fields, the scene's fresh, then [over]).
Map<String, dynamic> mesaPreviewBaseW(
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

/// mesa-preview.html: `remapW` for the story [story] (its id: `PREVIEW.story.id`; null: every story move).
Map<String, dynamic> mesaPreviewRemapW(
  Map<String, dynamic> w0,
  Mesa scene, {
  String? story,
}) {
  final w = _copy(w0) as Map<String, dynamic>;
  scene.remapW(w, story);
  return w;
}
