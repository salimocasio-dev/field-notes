// The scene-facing names are kept exactly as in juego.js, Spanish ones and capitals included, so a
// scene ports line for line (page 12, section 4). The lint on names is off in this file for that.
// ignore_for_file: non_constant_identifier_names

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/src/ctx.dart';
import 'package:coqui_pixel/src/sprite.dart';

/// What a scene may call. Every name is used by today's scenes or kit (page 12 gives the count of uses).
/// Each member has the parameters it has in juego.js. feature_story implements it for play; coqui_scenes
/// has a still one for pictures (waits return at once, sound is silent).
abstract class SceneHost {
  // ---------- state ----------

  /// The scene's world, a JSON-shaped map (juego.js: `W`).
  Map<String, dynamic> get W;

  /// The story's variables (juego.js: `V`): draws, `as`, `mem_*`, `elegido`, `ok`, `x`.
  Map<String, dynamic> get V;

  /// The story file, raw (juego.js: `S`).
  Map<String, dynamic> get S;

  /// The frame count, one a tick (juego.js: `F`).
  int get F;

  /// The view [x, y, w, h] over the scene's picture (juego.js: `cam`).
  List<num> get cam;

  /// Ms a tick (juego.js: `TICK`, 70).
  int get TICK;

  /// How much faster time runs for checks (juego.js: `FAST`, ?fast=, 1 in play).
  num get FAST;

  /// The scene's picture size (juego.js: `SW`, `SH`, from the scene).
  int get SW;
  int get SH;

  /// The display picture size (juego.js: `DW`, `DH`: 196 × 216).
  int get DW;
  int get DH;

  /// Goes up at every new play and at the X; a wait from an older play throws (juego.js: `runId`).
  int get runId;

  /// The clips playing now (juego.js: `live`, a set of audio sources).
  // DECISION(order 02): the old set holds browser audio sources; here it is a set of whatever the player
  // hands out, typed Object.
  Set<Object> get live;

  /// Who is talking now: "coqui", a person's id, or null (juego.js: `TALK`).
  String? get TALK;

  /// The answer bubbles' icons by key (juego.js: `BUBL`).
  Map<String, List<String>> get BUBL;

  /// The game's one sprite cache (engine.js: `spr`, `SP`, `GL`, `GC`).
  // ADDED(order 12): the old scenes and kit.js call the global `spr`, which here is a field of [SpriteLib]; a scene
  // reaches the game's one through its host, as it reaches every other global. Additive: nothing else changes.
  SpriteLib get lib;

  // ---------- time ----------

  /// juego.js: `wait(ms)`: sleeps ms / FAST, then throws "stop" when the play was left meanwhile.
  Future<void> wait(num ms);

  /// juego.js: `sleep(ms)`.
  Future<void> sleep(num ms);

  /// juego.js: `espera(liveSet, lead, line, o)`: waits for a touch on one of [liveSet]. The result is the
  /// old `me` object (got, ms, p, hablado, okP, ...).
  // DECISION(order 02): `me` stays a JSON-shaped map, as W does; the runner (order 15) fills it.
  Future<Map<String, dynamic>> espera(
    List<String> liveSet,
    List<Object?>? lead,
    String? line, [
    Map<String, dynamic>? o,
  ]);

  // ---------- sound ----------

  /// The sound effects juego.js defines (juego.js: `SFX`).
  Sfx get SFX;

  /// juego.js: `tone(f0, at, dur, type, vol, f1)`.
  void tone(num f0, num at, num dur, [String? type, num? vol, num? f1]);

  /// juego.js: `say(id, gap)`: a line, then [gap] ms (420 when null).
  Future<void> say(String id, [num? gap]);

  // ---------- the frog ----------

  /// juego.js: `frog(g, q, a)`: draws the frog [q] (W.cq) with its shadow.
  void frog(Ctx g, Map<String, dynamic> q, int a);

  /// juego.js: `frogBox(q)`: {x, y, w, h}.
  // DECISION(order 02): the old object {x, y, w, h} is a record with those names, so `b.x` ports as it is.
  ({num x, num y, num w, num h}) frogBox(Map<String, dynamic> q);

  /// juego.js: `hopTo(x, y, hops, s1)`.
  Future<void> hopTo(num x, num y, int hops, [num? s1]);

  /// juego.js: `bounce(h)` (6 when null).
  void bounce([num? h]);

  /// juego.js: `foot(a, b, c, d)`: which buttons the end of a story shows (next, again, map, the outline map).
  void foot(bool a, bool b, bool c, [bool d = false]);

  /// juego.js: `at(k)`: the view is at CAM[k].
  bool at(String k);

  // ---------- signs and effects ----------

  /// juego.js: `fx(e)`: an effect {t, n, pts | x, y}; its start frame is set here.
  void fx(Map<String, dynamic> e);

  /// juego.js: `star(g, x, y, s, hot)`.
  void star(Ctx g, num x, num y, num s, [bool hot = false]);

  /// juego.js: `hand(g, x, y, down, k)`.
  void hand(Ctx g, num x, num y, bool down, num k);

  /// juego.js: `heart(g, x, y, s)`.
  void heart(Ctx g, num x, num y, num s);

  /// juego.js: `spot(g, b, a)`: the big "touch this" sign round box [b].
  void spot(Ctx g, List<num> b, int a);

  /// juego.js: `bub(g, k, tx, ty, a)`: a picture bubble.
  void bub(Ctx g, String k, num tx, num ty, int a);

  /// juego.js: `bx(k)`: an answer bubble's box, else the scene's box, else the frog's.
  List<num> bx(String k);

  /// juego.js: `muestra(id)`: shows a line's words (caption or bubble).
  void muestra(String id);

  // ---------- the story ----------

  /// juego.js: `pasos(list)`.
  Future<void> pasos(List<Object?>? list);

  /// juego.js: `paso(st)`: one step, a string (a line) or a map (its key names its kind).
  Future<void> paso(Object? st);

  /// juego.js: `bien(id)`: "¡Muy bien!" or the story's own line.
  Future<void> bien([String? id]);

  /// juego.js: `estado(s, nopic)`: the lesson screen's state, "start", "play" or "end".
  void estado(String s, [bool nopic = false]);

  /// juego.js: `donde(quien)`: where the bubble of who is talking points, or null.
  List<num>? donde(String? quien);

  /// juego.js: `baraja(a)`: a shuffled copy.
  List<T> baraja<T>(List<T> a);

  /// juego.js: `camGo(k, n)`: slides the view to CAM[k] in n frames (9 when null).
  Future<void> camGo(String k, [int? n]);

  /// juego.js: `poke(what, p)`: a touch that is not an answer, at p.
  void poke(String what, ({int x, int y}) p);

  /// juego.js: `draw()`: one frame.
  void draw();

  /// juego.js: `fresh()`: a new world for a new play.
  void fresh();
}

/// juego.js: `SFX`, every effect it defines (18: right, toc, blip, creak, hop, coqui, win, luz, drop,
/// trueno, lluvia, calla, then suave, pio, slam, bonk, munch, swoop). Each calls [ClipPlayer.tone],
/// [ClipPlayer.noiseBurst] or [ClipPlayer.loop] with today's numbers.
class Sfx {
  Sfx(this.player);

  final ClipPlayer player;

  // juego.js: tone(f0, at, dur, type, vol, f1)
  void _t(
    double f0,
    double at,
    double dur,
    String type,
    double vol, [
    double? f1,
  ]) => player.tone(f0, at: at, dur: dur, wave: type, vol: vol, toHz: f1);

  void right() {
    _t(784, 0, .1, 'triangle', .14);
    _t(1047, .09, .1, 'triangle', .14);
    _t(1319, .18, .26, 'triangle', .14);
  }

  void toc() {
    _t(950, 0, .07, 'sine', .22, 480);
    _t(950, .17, .07, 'sine', .22, 480);
  }

  void blip() => _t(520, 0, .06, 'sine', .07, 640);

  void creak() {
    _t(210, 0, .5, 'sawtooth', .025, 120);
    _t(330, .05, .4, 'sawtooth', .012, 170);
  }

  void hop() => _t(320, 0, .07, 'square', .025, 520);

  void coqui() {
    _t(1500, 0, .11, 'sine', .09);
    _t(2300, .17, .2, 'sine', .09, 2750);
  }

  void win() {
    const fs = [523.0, 659.0, 784.0, 1047.0];
    for (var i = 0; i < fs.length; i++) {
      _t(fs[i], i * .11, .2, 'square', .04);
    }
  }

  void luz() {
    _t(1320, 0, .09, 'sine', .1);
    _t(1760, .08, .22, 'sine', .1);
  }

  void drop() => _t(1400, 0, .05, 'sine', .06, 700);

  /// Thunder. juego.js: `trueno(v)`, the noise at (v||1).
  void trueno([num? v]) =>
      player.noiseBurst(vol: (v == null || v == 0) ? 1 : v.toDouble());

  /// The rain, on until [calla].
  void lluvia() => player.loop('rain', true);

  void calla() => player.loop('rain', false);

  void suave() => _t(330, 0, .16, 'sine', .05, 290);

  void pio() {
    _t(2600, 0, .06, 'sine', .07, 3400);
    _t(2900, .09, .08, 'sine', .07, 3800);
  }

  void slam() {
    _t(140, 0, .12, 'square', .05, 70);
    _t(90, .02, .18, 'sine', .12, 50);
  }

  void bonk() {
    _t(600, 0, .06, 'square', .05, 200);
    _t(300, .06, .2, 'triangle', .08, 120);
  }

  void munch() {
    for (final t in const [0.0, .16, .32]) {
      _t(260, t, .06, 'square', .03, 180);
    }
  }

  void swoop() => _t(1800, 0, .35, 'sine', .04, 600);
}
