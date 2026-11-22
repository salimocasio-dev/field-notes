import 'package:coqui_contracts/coqui_contracts.dart' show Rng;
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/frente/frente.dart';
import 'package:coqui_scenes/src/balcon/balcon.dart';
import 'package:coqui_scenes/src/sala/sala.dart';
import 'package:coqui_scenes/src/patio/patio.dart';
import 'package:coqui_scenes/src/camino/camino.dart';
import 'package:coqui_scenes/src/campo/campo.dart';
import 'package:coqui_scenes/src/lago/lago.dart';
import 'package:coqui_scenes/src/banco/banco.dart';
import 'package:coqui_scenes/src/mesa/mesa.dart';
import 'package:coqui_scenes/src/estufa/estufa.dart';
import 'package:coqui_scenes/src/nevera/nevera.dart';
import 'package:coqui_scenes/src/mostrador/mostrador.dart';
import 'package:coqui_scenes/src/estantes/estantes.dart';
import 'package:coqui_scenes/src/frutas/frutas.dart';
import 'package:coqui_scenes/src/caja/caja.dart';

/// What makes a scene: it is given the game's one random source ([rng]: the story runner's), which a scene that draws
/// random numbers (El balcón's `azar`) draws from, as the old one drew from `Math.random`. A scene that draws none ignores it.
typedef SceneMaker = Scene Function({Rng? rng});

// The factory of a scene that draws no random number: it ignores the source it is given.
SceneMaker _plain(Scene Function() make) =>
    ({Rng? rng}) => make();

/// The eleven scenes, by id, in this order. Each id maps to the factory of its
/// scene. A converted scene's factory needs its sheet read first (`loadScene`);
/// every other factory throws until its scene is converted.
final Map<String, SceneMaker> sceneRegistry = Map.unmodifiable({
  'frente': _plain(createFrente),
  'balcon': createBalcon,
  'sala': createSala,
  'patio': createPatio,
  'camino': createCamino,
  'campo': _plain(createCampo),
  'lago': createLago,
  'banco': _plain(createBanco),
  'mesa': _plain(createMesa),
  'estufa': _plain(createEstufa),
  'nevera': _plain(createNevera),
  'mostrador': _plain(createMostrador),
  'estantes': _plain(createEstantes),
  'frutas': _plain(createFrutas),
  'caja': _plain(createCaja),
});
