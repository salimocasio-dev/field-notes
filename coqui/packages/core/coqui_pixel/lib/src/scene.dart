// The scene-facing names are kept exactly as in juego.js and kit.js, Spanish ones and capitals
// included, so a scene ports line for line (page 12, section 4). This is the one place Dart code is
// not renamed, so the lint on names is off in this file.
// ignore_for_file: non_constant_identifier_names

import 'package:coqui_pixel/src/ctx.dart';
import 'package:coqui_pixel/src/pp_build.dart';
import 'package:coqui_pixel/src/pp_engine.dart';
import 'package:coqui_pixel/src/scene_host.dart';

/// A thing that can be touched (kit.js: one entry of `cosas`).
class Thing {
  Thing({
    required this.id,
    this.box,
    this.world,
    this.si,
    this.hand,
    this.m,
    this.z = false,
    this.hintBox,
  });

  String id;

  /// [x, y, w, h] on screen, or a function of W: from the sheet.
  dynamic box;

  /// x0, y0, z0, x1, y1, z1 when it is part of the set.
  List<double>? world;

  /// Whether it is shown in W (kit.js: `si`); null: always.
  bool Function(Map<String, dynamic> W)? si;

  /// Where the big hand points: [x, y], or a function of W (kit.js: `hand`); null: the box's middle.
  dynamic hand;

  /// The touch slack around the box (kit.js: `m`; 3 when null).
  num? m;

  /// In front of the frog: it takes a touch before him (kit.js: `z:1`).
  bool z;

  /// Where its hint frame and its twinkle are drawn, [x, y, w, h], when not round its [box] (El camino's big tree, whose
  /// box runs off the picture: the sheet's `things.<id>.hintBox`, order 33b); null: round its box. Touches answer in
  /// [box] either way.
  List<num>? hintBox;
}

/// What KIT.escena() takes and returns (kit.js, function escena), and what juego.js reads from a scene (`E`).
abstract class Scene {
  // DECISION(order 02): the old scenes reach the game through globals (W, wait, hopTo, SFX, ...). Here a
  // scene reaches them through [host], set by whoever runs the scene before its first call.
  late SceneHost host;

  String get id;

  /// The scene's picture size (juego.js, arranca: `SW=E.SW;SH=E.SH`). 240 × 216 in every scene today.
  int get SW;
  int get SH;

  Map<String, List<num>> get CAM;
  List<num> get heartAt;

  /// Spots where the frog stands: [x, y, scale].
  Map<String, List<num>> get lugar;
  List<Thing> get cosas;
  Map<String, dynamic> fresh(Map<String, dynamic> story);
  String setKey(Map<String, dynamic> W); // which baked set this state needs

  /// Port of the set reference.
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W);
  List<num> remap(List<num> xy); // a position written in a story or pair file -> today's place (from the sheet)
  void draw(Ctx c, Map<String, dynamic> W, int a); // the sprite layer only

  /// Drawn on the display picture after the view (juego.js, draw: `E.hud(dc,W,a)`). A scene without one draws nothing.
  // DECISION(order 02): the members juego.js calls only when a scene has them (hud, poke, talkAt, respIcon,
  // estado) do what the old code does when they are missing.
  void hud(Ctx c, Map<String, dynamic> W, int a) {}

  /// A touch that is not an answer (juego.js, poke: `E.poke(what,p)`; the scenes read only `what`).
  dynamic poke(String what) => null;

  Map<String, Future<void> Function(Map<String, dynamic> o)> get acts;

  /// A wrong answer costs a step of the thing at stake (juego.js: `E.stake(W.lost,S.stake.steps,en)`; async in every scene).
  Future<void> stake(int lost, int max, String en);

  /// Where a person's speech bubble points (juego.js, donde: `E.talkAt(quien,W)`). Null: not seen.
  List<num>? talkAt(String who, Map<String, dynamic> W) => null;

  /// What is drawn inside a picture answer's bubble (juego.js, respDraw: `E.respIcon(g,k,x,y,w,h,a)`).
  dynamic respIcon(Ctx c, String k, num x, num y, num w, num h, int a) => null;

  /// The scene's state as one line, for checks (juego.js: `Story.scene()`, `E.estado(W)`; "" without one).
  String estado(Map<String, dynamic> W) => '';

  // Given by the kit for every scene, and by El frente itself (juego.js reads E.box, E.hit, E.handAt).

  /// A thing's box [x, y, w, h] in W, or null when the scene has no such thing.
  List<num>? box(String k, Map<String, dynamic> W);

  /// The id of what is at (x, y): a thing, "pajaro", "coqui", or null.
  String? hit(num x, num y, Map<String, dynamic> W);

  /// Where the big hand points for a thing, or null.
  List<num>? handAt(String k);
}
