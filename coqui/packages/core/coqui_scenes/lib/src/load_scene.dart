import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/registry.dart';
import 'package:coqui_scenes/src/sheets.dart';
import 'package:flutter/services.dart';

/// The scenes that are converted: each has its sheet among this package's assets and its real scene in the registry.
const Set<String> convertedScenes = {'frente'};

/// The scene [id], made from its sheet (read from the assets first). A scene that is not converted yet throws
/// `UnimplementedError('not converted yet')`, as its stub in the registry does; an id that is not a scene throws
/// [ArgumentError].
Future<Scene> loadScene(String id, {AssetBundle? bundle}) async {
  final make =
      sceneRegistry[id] ?? (throw ArgumentError.value(id, 'id', 'not a scene'));
  if (convertedScenes.contains(id)) await loadSheet(id, bundle: bundle);
  return make();
}
