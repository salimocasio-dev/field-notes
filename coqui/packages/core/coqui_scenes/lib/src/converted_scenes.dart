/// The scenes that are converted: each has its sheet among this package's assets and its real scene in the registry.
/// Until a scene is here, its pictures are the old ones (`assets/old_pictures/<id>/`, made by
/// tool/make_old_pictures.dart); adding it here and running that tool removes them.
///
/// This file imports nothing, so the tools under `tool/` (plain Dart) read the same list the app does.
const Set<String> convertedScenes = {
  'frente',
  'balcon',
  'sala',
  'patio',
  'camino',
  'campo',
  'lago',
  'banco',
  'mesa',
  'estufa',
};
