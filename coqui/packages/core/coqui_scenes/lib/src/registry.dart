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

/// The eleven scenes, by id, in this order. Each id maps to the factory of its
/// scene. A converted scene's factory needs its sheet read first (`loadScene`);
/// every other factory throws until its scene is converted.
const Map<String, Scene Function()> sceneRegistry = {
  'frente': createFrente,
  'balcon': createBalcon,
  'sala': createSala,
  'patio': createPatio,
  'camino': createCamino,
  'campo': createCampo,
  'lago': createLago,
  'banco': createBanco,
  'mesa': createMesa,
  'estufa': createEstufa,
  'nevera': createNevera,
};
