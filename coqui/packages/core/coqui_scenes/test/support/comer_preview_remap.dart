// TEST-ONLY. comer-preview.html's `remapW` and `baseW`: how the preview moves a W written in OLD positions (a recorded
// run's W) to the new ones, so that a moment of a recorded run can be drawn by the Dart scene exactly as the preview draws
// it. The rule is the scene's own (`Comer.remapW`: the places of the sheet's moves and the story positions the sheet
// moved, a person's fraction of a pixel kept, the frog by his feet), which the preview's `PV.remapW` is.
import 'package:coqui_scenes/src/comer/comer.dart';

Object? _copy(Object? v) => v is Map
    ? {for (final e in v.entries) e.key as String: _copy(e.value)}
    : v is List
    ? [for (final e in v) _copy(e)]
    : v;

/// comer-preview.html: `baseW` (juego.js fresh's fields, the scene's fresh, then [over]).
Map<String, dynamic> comerPreviewBaseW(
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

/// comer-preview.html: `PV.remapW` for the story [story] (its id: `PREVIEW.story.id`; null: none).
Map<String, dynamic> comerPreviewRemapW(
  Map<String, dynamic> w0,
  Comer scene, {
  String? story,
}) {
  final w = _copy(w0) as Map<String, dynamic>;
  scene.remapW(w, story);
  return w;
}
