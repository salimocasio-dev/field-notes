// The scene-facing names are kept as in juego.js (page 12, section 4): the lint on names is off in this file.
// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/scene_set.dart';

/// A clip player that plays nothing: a still picture is silent.
class _Silent implements ClipPlayer {
  @override
  bool muted = true;
  @override
  Future<void> unlock() async {}
  @override
  Future<List<String>> preload(Iterable<String> clipIds) async => const [];
  @override
  Future<bool> play(String clipId, {Duration? limit}) async => false;
  @override
  void tone(
    double hz, {
    double at = 0,
    double dur = .1,
    String wave = 'square',
    double vol = .05,
    double? toHz,
  }) {}
  @override
  void noiseBurst({double vol = 1}) {}
  @override
  void loop(String name, bool on) {}
  @override
  Future<void> stop() async {}
}

/// The frog at the spot a sheet's `code` entry for another file's line names (`juego.js:16`, `cual.js:21`).
///
/// A sheet may say the line's place is not used (its `to` is words, not a spot: El balcón's, whose `fresh()` puts the frog
/// at its own spot, and whose pairs place him themselves when they show him). The line then keeps its old numbers,
/// which the entry's `old` gives (`cq x 150 y 178 s 1`): whatever reads them next replaces them.
({int x, int y, num scale}) frogOfCode(Sheet sheet, PpEngine e, String line) {
  final c = sheet.code.firstWhere(
    (c) => c.line == line,
    orElse: () => throw SheetError(
      'the sheet of "${sheet.scene}" has no code entry for $line',
    ),
  );
  final to = c.to;
  if (to is String) {
    final m = RegExp(r'cq x (-?[\d.]+) y (-?[\d.]+) s (-?[\d.]+)')
        .firstMatch(c.old);
    if (m != null) {
      return (
        x: int.parse(m[1]!),
        y: int.parse(m[2]!),
        scale: num.parse(m[3]!.startsWith('.') ? '0${m[3]}' : m[3]!),
      );
    }
  }
  if (to is! Map || to['spot'] is! String) {
    throw SheetError('the code entry for $line is not a spot');
  }
  return sheet.frogAt(to['spot'] as String, e);
}

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

/// The host of a still picture (page 12, section 4: "coqui_scenes has a still one for pictures"): it holds W, the frame
/// counter and the view, and draws the game's signs; waits return at once and sound is silent. It plays no story: the
/// story calls (`espera`, `pasos`, `paso`) are not for it.
class StillHost implements SceneHost {
  StillHost(this.scene) {
    scene.host = this;
    signs = Signs(host: this, scene: scene);
    cam = List<num>.of(scene.CAM['wide']!);
  }

  final SetScene scene;
  late final Signs signs;

  @override
  Map<String, dynamic> W = {'fx': <Map<String, dynamic>>[]};
  @override
  Map<String, dynamic> V = {};
  @override
  Map<String, dynamic> S = {};
  @override
  int F = 0;
  @override
  List<num> cam = const [0, 0, 196, 216];
  @override
  final int TICK = 70;
  @override
  final num FAST = 1;
  @override
  int get SW => scene.SW;
  @override
  int get SH => scene.SH;
  @override
  final int DW = 196, DH = 216;
  @override
  final int runId = 0;
  @override
  final Set<Object> live = {};
  @override
  String? TALK;
  @override
  final Map<String, List<String>> BUBL = newBUBL();
  @override
  final SpriteLib lib = SpriteLib();

  // ---------- time: at once ----------

  @override
  Future<void> wait(num ms) async {}
  @override
  Future<void> sleep(num ms) async {}
  @override
  Future<Map<String, dynamic>> espera(
    List<String> liveSet,
    List<Object?>? lead,
    String? line, [
    Map<String, dynamic>? o,
  ]) => throw UnsupportedError('a still picture waits for no touch');

  // ---------- sound: silent ----------

  @override
  final Sfx SFX = Sfx(_Silent());
  @override
  void tone(num f0, num at, num dur, [String? type, num? vol, num? f1]) {}
  @override
  Future<void> say(String id, [num? gap]) async {}

  // ---------- the frog ----------

  // juego.js: frog. A scene whose sheet casts the frog's shadow in the engine drops the old one (sheet: shadows.dropped)
  @override
  void frog(Ctx g, Map<String, dynamic> q, int a) =>
      signs.frog(g, q, a, shadow: scene.frogShadow);

  // juego.js: frogBox
  @override
  ({num x, num y, num w, num h}) frogBox(Map<String, dynamic> q) =>
      _frogBoxOf(q);

  // juego.js: hopTo, with every wait at once: the frog ends where the old hop ends
  @override
  Future<void> hopTo(num x, num y, int hops, [num? s1]) async {
    final q = W['cq'] as Map<String, dynamic>,
        x0 = q['x'] as num,
        y0 = q['y'] as num,
        s0 = q['s'] as num;
    final s = s1 ?? s0;
    for (var h = 0; h < hops; h++) {
      q['s'] = _round((s0 + (s - s0) * (h + 1) / hops) * 100) / 100;
      const n = 5;
      for (var i = 1; i <= n; i++) {
        final t = (h + i / n) / hops;
        q['x'] = _round(x0 + (x - x0) * t);
        q['y'] = _round(y0 + (y - y0) * t);
        q['dy'] = -7 * math.sin(math.pi * i / n);
      }
      q['dy'] = 0;
    }
  }

  // juego.js: bounce. It ends with the frog on the ground
  @override
  void bounce([num? h]) => (W['cq'] as Map<String, dynamic>)['dy'] = 0;
  @override
  void foot(bool a, bool b, bool c, [bool d = false]) {}
  @override
  bool at(String k) => atView(cam, scene.CAM[k]!);

  // ---------- signs and effects ----------

  // juego.js: fx
  @override
  void fx(Map<String, dynamic> e) {
    e['f0'] = F;
    (W['fx'] as List).add(e);
  }

  @override
  void star(Ctx g, num x, num y, num s, [bool hot = false]) =>
      _star(g, x, y, s, hot);
  @override
  void hand(Ctx g, num x, num y, bool down, num k) => _hand(g, x, y, down, k);
  @override
  void heart(Ctx g, num x, num y, num s) => _heart(g, x, y, s);
  @override
  void spot(Ctx g, List<num> b, int a) => _spot(g, b, a, SW, SH);
  @override
  void bub(Ctx g, String k, num tx, num ty, int a) =>
      signs.bub(g, k, tx, ty, a);
  @override
  List<num> bx(String k) => signs.bx(k);
  @override
  void muestra(String id) {}

  // ---------- the story: a still picture plays none ----------

  @override
  Future<void> pasos(List<Object?>? list) =>
      throw UnsupportedError('a still picture plays no story');
  @override
  Future<void> paso(Object? st) =>
      throw UnsupportedError('a still picture plays no story');
  @override
  Future<void> bien([String? id]) async {}
  @override
  void estado(String s, [bool nopic = false]) {}
  @override
  List<num>? donde(String? quien) =>
      quien == null ? null : scene.talkAt(quien, W);
  @override
  List<T> baraja<T>(List<T> a) => List<T>.of(a);

  // juego.js: camGo, at once
  @override
  Future<void> camGo(String k, [int? n]) async {
    cam = List<num>.of(scene.CAM[k]!);
  }

  @override
  void poke(String what, ({int x, int y}) p) => scene.poke(what);
  @override
  void draw() {}

  /// Where the game puts the frog when a play starts (juego.js, fresh: `cq x 150 y 178 s 1`), as the scene's sheet
  /// gives it (its `code` entry for `juego.js:16`: a spot).
  ({int x, int y, num scale}) startFrog() =>
      frogOfCode(scene.sheet, scene.projection, 'juego.js:16');

  // juego.js: fresh
  @override
  void fresh() {
    final f = startFrog();
    W = {
      'cq': <String, dynamic>{
        'x': f.x,
        'y': f.y,
        's': f.scale,
        'dy': 0,
        'al': 1,
        'vis': 1,
        'bub': null,
      },
      'spot': null,
      'twinkle': null,
      'glow': null,
      'fx': <Map<String, dynamic>>[],
      'heart': 0,
      'lost': 0,
      'resp': null,
      ...scene.fresh(S),
    };
    cam = List<num>.of(scene.CAM['wide']!);
    V = {};
  }
}

({num x, num y, num w, num h}) _frogBoxOf(Map<String, dynamic> q) => frogBox(q);
void _star(Ctx g, num x, num y, num s, bool hot) => star(g, x, y, s, hot);
void _hand(Ctx g, num x, num y, bool down, num k) => hand(g, x, y, down, k);
void _heart(Ctx g, num x, num y, num s) => heart(g, x, y, s);
void _spot(Ctx g, List<num> b, int a, int sw, int sh) => spot(g, b, a, sw, sh);
