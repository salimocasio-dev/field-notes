// Port of historia/escenas/estufa.js: the scene "La estufa", abuela's stove (place 3, La cocina; order 38b). Line for
// line, minus its background function `fondo` and minus what the sheet's `dropped` list says is dropped (the background,
// which the set bakes; the old stool, which is the set's in the state `banco1`); every screen position replaced by what
// the sheet's `code` list gives for its line (estufa_places.dart), and the places the sheet's `moves` list moves, each at
// its line (the moved source's own numbers: EstufaPlaces.to). estufa.js is written on the kit, so this is an `Escena`;
// its set is [EstufaSet].
//
// What La estufa's sheet has that the earlier ones did not, or uses differently, and how it is kept here (as
// estufa-preview.html keeps it, its functions ported pixel for pixel):
// - The family at the window (moves line 134): drawn unclipped, standing outside, then the set's own pixels of the room
//   nearer than their plane (world y = front.parts.ventana.y, behind the recess) drawn again over them, so that they show
//   only through the opening, cut at the chest by the sill ([Estufa.winA], [Estufa.winB]: the preview's PREVIEW.winA,
//   winB); their plates on the sill are drawn after, in the room.
// - The stool is the set's (`banco1`), drawn after the room is baked, with no shadow; at its entry in the sorted list
//   (front.parts.banco, sortY 9999: after everyone) its own pixels are drawn again over each item that owns them (each
//   item owns the pixels it drew last: [Estufa.item]) where that pixel is nearer than the item's plane ([Estufa.front],
//   [Estufa.planeOf]); never over the frog standing on it.
// - `moves` (38) at their lines, `remap` (the pairs' own places: [Estufa.placePair]), `talk` ([Estufa.talkPlace]),
//   `hintBox` (things.cocina), `hops` (all the old counts but saco-servir, walked by no recorded run), `shadows` (whoever
//   stands on the floor: [Estufa.shadows]).
// - **The old fault is kept** (the sheet's `faults`): estufa.js line 122 draws the baby whenever mamá has `p.bebe`, which
//   is also the cup she is handed; line 125 skips the cup for her. Ported as it is.
//
// The old file's names are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart' hide tarjeta;
import 'package:coqui_pixel/coqui_pixel.dart' as kit show tarjeta;
import 'package:coqui_scenes/src/estufa/estufa_places.dart';
import 'package:coqui_scenes/src/estufa/estufa_set.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';

/// The scene "estufa", made from its sheet (the registry's factory: the sheet must be read first, `loadScene`). It
/// draws no random number.
Scene createEstufa() => Estufa(sheetOf('estufa'));

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// JavaScript: Math.round of a number that may be NaN (a place that is not set): NaN stays NaN
num _roundN(num v) => v.isNaN ? double.nan : (v + 0.5).floor();

// JavaScript: `x || 0` for a number of W
num _n(Object? v) => jsTruthy(v) ? v as num : 0;

// JavaScript: `+x` (a number, or a story's string)
num _plus(Object? v) => v is num
    ? v
    : v is String
    ? (num.tryParse(v.trim()) ?? (v.trim().isEmpty ? 0 : double.nan))
    : v == null
    ? double.nan
    : (v == true ? 1 : 0);

// JavaScript: a number of W in arithmetic (a missing one is NaN)
num _num(Object? v) => v is num ? v : _plus(v);

// JavaScript: how `"" + v` writes a value (estado, sprite keys)
String _js(Object? v) => v == null
    ? 'null'
    : v is num
    ? jsNum(v)
    : '$v';

// JavaScript: `"" + v` of a value that may be undefined (a missing field)
String _jsField(Map<String, dynamic> p, String k) =>
    p.containsKey(k) ? _js(p[k]) : 'undefined';

// JavaScript: `p.dir < 0` (a missing dir is not)
bool _left(Map<String, dynamic>? p) =>
    p != null && p['dir'] is num && (p['dir'] as num) < 0;

// "#RRGGBB" colours
List<int> _hs(List<String> l) => [for (final s in l) hexColour(s)];
int _h(String s) => hexColour(s);

final int _white = _h('#FFFFFF'),
    _flame = _h('#F08020'),
    _flameHi = _h('#FFE070'),
    _smoke0 = _h('#2A2A36'),
    _smoke1 = _h('#6A6A7A'),
    _smoke2 = _h('#9494A6'),
    _smell = _h('#8A6A20'),
    _smellHi = _h('#FFE070'),
    _steamCal = _h('#B8B8C8'),
    _star = _h('#F0C020'),
    _cross = _h('#C8401E'),
    _empty = _h('#C8C8D4');

/// One entry of estufa.js's drawing list (`L`): the row it is sorted by, how it is drawn, and what it is (the sheet's
/// front.tags: `id` for a person or the frog, `front` for a part of the set drawn again).
class EstufaItem {
  EstufaItem(this.y, this.d, {this.id, this.front});

  final num y;
  final void Function() d;
  final String? id, front;
}

/// The scene "La estufa" (estufa.js: `KIT.escena({id:"estufa", ...})`). Its set is [EstufaSet]; this is the sprite layer
/// and what can happen here.
class Estufa extends Escena implements SetScene, SetOverSprites, PairPlaces {
  Estufa(this.sheet) {
    _p = EstufaPlaces(sheet, estufaEngine());
    final p = _p;
    // estufa.js:19 PISO, ENC, EST, FX, FY (sheet: code line 19; FX unchanged: the pots keep their x; FY: each burner's
    // own row, FYS on line 20, but where line 306 keeps the old FY); IZQ and DER were the background's only; BANCO the
    // stool's top (spots.banco)
    PISO = p.at(19, 150);
    ENC = p.at(19, 112);
    EST = [p.at(19, 86), p.at(19, 106), p.at(19, 80), p.at(19, 54)];
    FX = [p.at(19, 107), p.at(19, 145)];
    FY = p.at(19, 121);
    BANCO = p.spot('banco');
    // estufa.js:20 (moves line 20): REP, SVX, SVY, ESX, CUBO, SALX, SALY, FYS, BJ
    final l20 = p.to(
      20,
      'const REP=',
      RegExp(
        r'REP=\[(\d+),(\d+)\],SVX=i=>(\d+)\+i\*(\d+),SVY=i=>\[(\d+),(\d+),(\d+)\]\[i\],ESX=EST\[0\]\+(\d+),'
        r'CUBO=\[(\d+),(\d+)\],SALX=EST\[0\]\+(\d+),SALY=(\d+),FYS=\[(\d+),(\d+)\],FYi=i=>FYS\[i\],BJ=(\d+);',
      ),
    );
    REP = [l20[0], l20[1]];
    _svx = [l20[2], l20[3]];
    _svy = [l20[4], l20[5], l20[6]];
    ESX = EST[0] + l20[7];
    CUBO = [l20[8], l20[9]];
    SALX = EST[0] + l20[10];
    SALY = l20[11];
    FYS = [l20[12], l20[13]];
    BJ = l20[14];
    // estufa.js:22 LADO, AYUDA, PUERTA (sheet: spots lado.0, lado.1, ayuda, puerta: unchanged)
    LADO = [p.spot('lado.0'), p.spot('lado.1')];
    AYUDA = p.spot('ayuda');
    PUERTA = p.spot('puerta');
    // estufa.js:23 EN (moves line 23: where each thing stands on a counter takes the row of the top there)
    final en = p.toSource(23, 'const EN=');
    EN = {
      for (final m in RegExp(r'(\w+):\[(\d+),(\d+)\]').allMatches(en))
        m[1]!: [num.parse(m[2]!), num.parse(m[3]!)],
    };
    // estufa.js:96 to :101 (moves): the pot's smoke and steam, the pan's steam at each burner's row
    final l100 = p.to(
      100,
      'if(f.mal)',
      RegExp(
        r'vapor\(c,x,FYi\(i\)-(\d+),1\);else if\(f\.vapor&&f\.llama\)vapor\(c,x,FYi\(i\)-(\d+),0\)',
      ),
    );
    _potSmoke = l100[0];
    _potSteam = l100[1];
    _panSteam = p.to(
      101,
      'else{tenida(c,"sarten"',
      RegExp(r'if\(o\.humo\)vapor\(c,px,FYi\(i\)-(\d+),1\)'),
    )[0];
    // estufa.js:134 (moves): the family at the window, outside, and their plates on the sill
    _ventana = p.to(
      134,
      'if(W.ventana&&W.ventana.length)',
      RegExp(
        r'c\.drawImage\(im,(\d+)\+j\*(\d+)-KIT\.PX\+(\d+),\[(\d+),(\d+),(\d+)\]\[j\]\+\(j%2\)\*(\d+)\).*'
        r'tenida\(c,"plato",(\d+)\+j\*(\d+),\[(\d+),(\d+),(\d+)\]\[j\]\)',
      ),
    );
    // estufa.js:135 (moves): the sack and the jar on the shelf
    _estante = p.to(
      135,
      'if(W.estante)',
      RegExp(r'"saco",(\d+),(\d+),0,0,v\);tenida\(c,"frasco",(\d+),(\d+),'),
    );
    // estufa.js:140 (moves): the sack and the jar Carmen fills the cups from
    _llenando = p.to(
      140,
      'if(I.llenando)',
      RegExp(
        r'EN\.saco\[0\]-(\d+),(\d+)\);tenida\(c,"frasco",EN\.tazon\[0\]\+(\d+),(\d+)\)',
      ),
    );
    // estufa.js:142 (moves): what lies on the tray, BJ - 3
    _bandejaDy = p.to(
      142,
      'if(I.bandeja)',
      RegExp(r'"muslo",36\+i\*8,BJ-(\d+)-'),
    )[0];
    // estufa.js:145 (moves): the nine cups' rows, 3 rows apart
    _tazasDy = p.to(
      145,
      'if(I.jarra)',
      RegExp(r'Math\.floor\(i/3\)\*(\d+)\)'),
    )[0];
    // estufa.js:148 (moves): the pile of plates and the small plate
    _pila = p.to(
      148,
      'for(let i=0;i<(D.pila',
      RegExp(
        r'EN\.platos\[0\]\+(\d+),(\d+)-i\*(\d+)\);if\(D\.platito\)tenida\(c,"platito",EN\.platos\[0\]-(\d+),(\d+)\)',
      ),
    );
    // estufa.js:204, :206 (moves): where the frog and Carmen stand before the cups of rice and of beans
    _echa = p.to(
      204,
      'async echa(o)',
      RegExp(r'e\[0\]\+\(key==="saco"\?(\d+):(\d+)\),(\d+)\)'),
    );
    _carmenecha = p.to(
      206,
      'async carmenecha(o)',
      RegExp(r'e\[0\]\+\(key==="saco"\?(\d+):(\d+)\),AYUDA\[1\]\)'),
    );
    // estufa.js:216 (moves, platos27): abuela and Carmen at the right counter
    _platos27 = p.to(
      216,
      'await Promise.all([mueve("abuela",EN.platos[0]+4',
      RegExp(
        r'mueve\("abuela",EN\.platos\[0\]\+(\d+),LADO\[1\]\[1\]\+(\d+)\),mueve\("luis",EN\.platos\[0\]-(\d+),LADO\[1\]\[1\]\+(\d+)\),'
        r'mueve\("carmen",EN\.platos\[0\]\+(\d+),LADO\[1\]\[1\]\+(\d+)\)',
      ),
    );
    // estufa.js:233 (moves, final27): Carmen with her plate held up
    _final27 = p.to(233, 'mueve("carmen",204,202)');
    // estufa.js:282, :294, :297, :312 (moves, cuidado): Luis's place at the right
    _luis29 = p.to(
      282,
      'async inicio29()',
      RegExp(r'luis:\{x:LADO\[1\]\[0\]-(\d+),y:LADO\[1\]\[1\]-(\d+),'),
    );
    for (final (line, src) in const [
      (294, 'async luisda(o)'),
      (297, 'async luisbebe(o)'),
      (312, 'async luiscome()'),
    ]) {
      final b = p.to(
        line,
        src,
        RegExp(r'mueve\("luis",LADO\[1\]\[0\]-(\d+),LADO\[1\]\[1\]-(\d+)\)'),
      );
      if (b[0] != _luis29[0] || b[1] != _luis29[1]) {
        throw SheetError(
          'estufa.js:$line moves Luis elsewhere than line 282: stop and ask',
        );
      }
    }
    // estufa.js:285 (moves, viene): whoever comes in for a cup, and a second one beside him
    _viene = p.to(
      285,
      'const p=G(o.quien)',
      RegExp(r'x=o\.lugar==2\?(\d+):(\d+),y=o\.lugar==2\?(\d+):(\d+);'),
    );
    // estufa.js:330 LUGAR (sheet: lugar: the frog on the stool, its q), CAM (views.wide), heartAt (points.corazon)
    LUGAR = {
      for (final e in sheet.lugar.entries)
        e.key: <num>[e.value.frog[0], e.value.frog[1], e.value.scale],
    };
    CAM = {for (final k in sheet.views.keys) k: p.view(k)};
    heartAt = [for (final v in p.pt('corazon')) _round(v)];
    // estufa.js:331 (moves): where the answer cards stand
    _respEn = p.to(331, 'fresh:()=>({respEn:');
    _talk = sheet.talk!;
    _ventanaY = (sheet.frontParts['ventana']!.raw['y'] as num).toDouble();
    // estufa.js:108 to :114 COSAS (sheet: code lines 109 to 114, things.<id>.box, hand and hintBox)
    cosas = [
      for (final id in QUIEN.keys) persona(id),
      Thing(
        id: 'olla0',
        si: (w) => _fuegoK(w, 0) == 'olla',
        box: [FX[0] - 17, FYi(0) - 24, 34, 28],
        m: 1,
        z: true,
      ),
      Thing(
        id: 'olla1',
        si: (w) => _fuegoK(w, 1) == 'olla',
        box: [FX[1] - 17, FYi(1) - 24, 34, 28],
        m: 1,
        z: true,
      ),
      Thing(
        id: 'saco',
        si: (w) => jsTruthy((w['izq'] as Map)['saco']),
        box: [EN['saco']![0] - 12, EN['saco']![1] - 16, 24, 18],
        m: 1,
        z: true,
      ),
      Thing(
        id: 'tazon',
        si: (w) => jsTruthy((w['izq'] as Map)['tazon']),
        box: [EN['tazon']![0] - 12, EN['tazon']![1] - 16, 24, 18],
        m: 1,
        z: true,
      ),
      Thing(
        id: 'pzpollo',
        si: (w) => _onPlate(w, 'muslo'),
        box: (Map<String, dynamic> w) => _pieceBox(w, 'muslo'),
        m: 0,
        z: true,
      ),
      Thing(
        id: 'pzhuevo',
        si: (w) => _onPlate(w, 'frito'),
        box: (Map<String, dynamic> w) => _pieceBox(w, 'frito'),
        m: 0,
        z: true,
      ),
      Thing(
        id: 'sarten',
        si: (w) => _fuegoK(w, 0) == 'sarten',
        box: [FX[0] - 17, FYi(0) - 14, 36, 16],
        m: 0,
      ),
      Thing(
        id: 'bandeja',
        si: (w) => jsTruthy((w['izq'] as Map)['bandeja']),
        box: [28, BJ - 15, 46, 16],
        m: 0,
      ),
      Thing(
        id: 'jarra',
        si: (w) => jsTruthy((w['izq'] as Map)['jarra']),
        box: [EN['jarra']![0] - 11, EN['jarra']![1] - 22, 20, 24],
        m: 1,
        z: true,
      ),
      for (final id in const ['estufa', 'cocina'])
        Thing(
          id: id,
          box: p.box(id),
          hand: p.hand(id),
          hintBox: p.hintBox(id),
          m: 0,
        ),
    ];
  }

  @override
  final Sheet sheet;

  late final EstufaPlaces _p;

  @override
  String get id => 'estufa';

  @override
  PpEngine newEngine({bool still = false}) => estufaEngine(still: still);

  @override
  PpEngine get projection => _p.e;

  // the old file's globals, through the host
  Map<String, dynamic> get W => host.W;
  Map<String, dynamic> get V => host.V;
  int get F => host.F;
  Sfx get SFX => host.SFX;
  Future<void> wait(num ms) => host.wait(ms);
  int get TICK => host.TICK;
  ({num x, num y, num w, num h}) frogBox(Map<String, dynamic> q) =>
      host.frogBox(q);
  Future<void> hopTo(num x, num y, int n, [num? s]) => host.hopTo(x, y, n, s);
  Sprite spr(String k, Sprite Function() make) => host.lib.spr(k, make);

  /* ---------- where things are ---------- */

  // estufa.js: PISO, ENC, EST, FX, FY, BANCO
  late final num PISO, ENC, FY;
  late final List<num> EST, FX;
  late final List<int> BANCO;

  // estufa.js: REP, SVX, SVY, ESX, CUBO, SALX, SALY, FYS, FYi, BJ (moves line 20)
  late final List<num> REP, CUBO, FYS, _svx, _svy;
  late final num ESX, SALX, SALY, BJ;
  num SVX(int i) => _svx[0] + i * _svx[1];
  num SVY(int i) => i >= 0 && i < _svy.length ? _svy[i] : double.nan;
  num FYi(int i) => FYS[i];

  // estufa.js: LADO, AYUDA, PUERTA, EN
  late final List<List<int>> LADO;
  late final List<int> AYUDA, PUERTA;
  late final Map<String, List<num>> EN;

  // the moved lines' own numbers (moves 100, 101, 134, 135, 140, 142, 145, 148, 204, 206, 216, 233, 282, 285, 331)
  late final num _potSmoke, _potSteam, _panSteam, _bandejaDy, _tazasDy;
  late final List<num> _ventana, _estante, _llenando, _pila, _echa;
  late final List<num> _carmenecha, _platos27, _final27, _luis29, _viene;
  late final List<num> _respEn;

  // estufa.js: LUGAR
  late final Map<String, List<num>> LUGAR;

  // the window's people stand outside at this world y (front.parts.ventana.y)
  late final double _ventanaY;

  // where a bubble goes (sheet: talk)
  late final SheetTalk _talk;

  @override
  late final Map<String, List<num>> CAM;

  @override
  late final List<num> heartAt;

  @override
  Map<String, List<num>> get lugar => LUGAR;

  // estufa.js: QUIEN (abuela is drawn by mkAbuela: no `who`)
  static final Map<String, Who?> QUIEN = {
    'luis': FAM['hermano'],
    'carmen': FAM['hermana'],
    'abuelo': FAM['abuelo'],
    'mama': FAM['mama'],
    'papa': FAM['papa'],
    'abuela': null,
  };

  /// A piece on abuela's plate (W.plata) is there while it lies on the plate, and its box is the half of the plate it is
  /// drawn in: the left `[plata.x - 24, plata.y - 22, 24, 24]` or the right `[plata.x, …]`. The old file (estufa.js THINGS)
  /// has both while there is a plate and gives the drumstick the left half and the egg the right one always, but draws
  /// the pieces by their order on the plate (`P.x - 11 + j * 22`): once Mamá has the drumstick (`dabebe`) the egg lies
  /// alone on the left half, under the drumstick's box, and the old hint frame, hand and tap of its ask were the empty
  /// right half (el-pollo-y-el-huevo beats.27, every plan), a touch of the egg itself the drumstick. Decided in order
  /// 38b's fix.
  static bool _onPlate(Map<String, dynamic> w, String kind) =>
      jsTruthy(w['plata']) &&
      ((w['plata'] as Map)['items'] as List).any((o) => _kOf(o) == kind);
  static List<num> _pieceBox(Map<String, dynamic> w, String kind) {
    final pl = w['plata'] as Map;
    final j = (pl['items'] as List).indexWhere((o) => _kOf(o) == kind);
    return [
      (pl['x'] as num) - (j == 0 ? 24 : 0),
      (pl['y'] as num) - 22,
      24,
      24,
    ];
  }

  static String? _fuegoK(Map<String, dynamic> w, int i) {
    final f = w['fuegos'];
    if (f is! List || i >= f.length) return null;
    final o = f[i];
    return o is Map ? o['k'] as String? : null;
  }

  /* ---------- the set ---------- */

  // the sheet's setKey table: "banco" + (W.banco ? 1 : 0) (setKey.key; estufa-preview.html PV.keyOf: banco 0 or false is
  // the state without the stool)
  @override
  String setKey(Map<String, dynamic> W) =>
      W['banco'] == 0 || W['banco'] == false ? 'banco0' : 'banco1';

  /// The part that drew each pixel of each baked state (set-kit.js `PART_TAGS`, estufa-set.html `?tags=1`: the
  /// preview's `CUR.tags`), recorded at its first bake. The same on every engine.
  static final Map<String, List<String?>> _tags = {};

  /// Which state's set has the stool (estufa-set.html `SET.banco`), for the surface under a point.
  static bool _bancoOf(String key) => EstufaState.fromKey(key).banco;

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  @override
  void buildSetFor(PpEngine e, PpBuild b, String key) {
    final s = EstufaSet(e, b, EstufaState.fromKey(key));
    // the first bake of a state also records which part drew each pixel (the sheet's front: the stool's, the room's)
    final tag = !_tags.containsKey(key);
    if (tag) s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
    s.buildSet();
    if (tag) _tags[key] = s.k.PART_TAGS!;
  }

  // the tags of [key], baking it once on an engine of its own when no engine of this scene has
  List<String?> _tagsOf(String key) {
    var t = _tags[key];
    if (t == null) {
      final e = estufaEngine();
      buildSetFor(e, PpBuild(e), key);
      t = _tags[key]!;
    }
    return t;
  }

  @override
  bool get frogShadow => !sheet.shadows.containsKey('coqui');

  // estufa-set.html: surfaceAt, in the state of W (the stool's top only where the set has it)
  EstufaSurface surfaceAt(num sx, num sy, Map<String, dynamic> w) =>
      estufaSurfaceAt(_p.e, sx, sy, banco: _bancoOf(setKey(w)));

  // estufa-preview.html: PV.casts (sheet: shadows). The frog (W.cq.vis, not .5 or less faded) at .3 with his radius,
  // from the floor point under (b.x + b.w / 2, q.y + 26), only on the floor (not on the stool); everyone shown, not .5 or
  // less faded, standing on the floor (the surface under (x, y - 1)), at .3, .65, 1, 1.35, 1.7 with their radius (abuela
  // hers, a child the child's, the others the grown-up's)
  @override
  List<ShadowCast> shadows(Map<String, dynamic> W) {
    final out = <ShadowCast>[];
    final SH = sheet.shadows;
    final q = W['cq'] as Map<String, dynamic>?;
    if (q != null && jsTruthy(q['vis']) && !_atMostHalf(q['al'])) {
      final b = frogBox(q),
          s = surfaceAt(b.x + b.w / 2, (q['y'] as num) + 26, W);
      if (s.on == 'suelo') {
        out.add((x: s.w[0], y: s.w[1], z: .3, r: SH['coqui']!.radius));
      }
    }
    final radii = SH['people']!.radii!;
    final G = (W['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in G.entries) {
      final p = en.value as Map<String, dynamic>?;
      if (p == null || p['vis'] == 0 || _atMostHalf(p['al'])) continue;
      final s = surfaceAt(_round(p['x'] as num), _round(p['y'] as num) - 1, W);
      if (s.on != 'suelo') continue;
      final id = en.key;
      final r =
          radii[id] ??
          (QUIEN[id] != null && QUIEN[id]!.nino
              ? radii['nino']!
              : radii['other']!);
      for (final z in const [.3, .65, 1.0, 1.35, 1.7]) {
        out.add((x: s.w[0], y: s.w[1], z: z, r: r));
      }
    }
    return out;
  }

  // JavaScript: `al <= .5` (a missing `al` is not)
  static bool _atMostHalf(Object? al) => al is num && al <= .5;

  /* ---------- the stool and the window in front: the sheet's front ---------- */

  PpEngine? _frameEngine;
  Uint32List? _setFrame;
  Float32List? _setZ;
  List<String?>? _tagsNow;

  // the set as this frame shows it (the shadows cast), before the sprite layer (drawFrame's step 4), its own depth
  // (estufa-preview.html: CUR.img, CUR.z) and its part tags (CUR.tags)
  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    _frameEngine = engine;
    _setFrame = Uint32List.fromList(engine.pix);
    _setZ = baked.zb;
    _tagsNow = _tagsOf(setKey(W));
  }

  static final double _COS = math.sqrt(3) / 2, _T30 = math.tan(math.pi / 6);

  // estufa-preview.html: vOf. The v of the surface point under a screen point (the floor, a top, the stool's top)
  double vOf(num sx, num sy, Map<String, dynamic> w) {
    final s = surfaceAt(sx, sy, w);
    return (s.w[0] + s.w[1]) / math.sqrt2 +
        (s.on == 'suelo' || s.on == 'mueble' ? 0 : .02);
  }

  // estufa-preview.html: PV.planeOf. A list item's plane (the v of the surface under it); the frog on the stool stands on
  // it: nothing of it in front of him (null). Anything but a person or the frog: null (not drawn over)
  double? planeOf(EstufaItem o, Map<String, dynamic> w) {
    if (o.id == 'coqui') {
      final q = w['cq'] as Map<String, dynamic>, b = frogBox(q);
      final s = surfaceAt(b.x + b.w / 2, (q['y'] as num) + 26, w);
      if (s.on == 'banco') return null;
      return (s.w[0] + s.w[1]) / math.sqrt2;
    }
    if (o.id != null) {
      final p =
          (w['gente'] as Map<String, dynamic>)[o.id] as Map<String, dynamic>;
      return vOf(_round(p['x'] as num), _round(p['y'] as num) - 1, w);
    }
    return null;
  }

  // estufa-preview.html: PREVIEW.OWN. Which item of the sorted list drew each pixel last (null: none yet this frame)
  List<EstufaItem?>? _own;

  // estufa-preview.html: PREVIEW.item. Every item of the sorted list owns the pixels it drew last (a pixel whose colour
  // it changed); a front entry is drawn as it is. A frame drawn with no set (a player with no screen) owns nothing
  void item(EstufaItem o) {
    if (o.front != null) return o.d();
    final e = _frameEngine;
    if (e == null) return o.d();
    final own = _own ??= List<EstufaItem?>.filled(e.W * e.H, null);
    final pix = e.pix, before = Uint32List.fromList(pix);
    o.d();
    for (var i = 0; i < pix.length; i++) {
      if ((pix[i] & 0xFFFFFF) != (before[i] & 0xFFFFFF)) own[i] = o;
    }
  }

  // estufa-preview.html: PREVIEW.front (sheet: front.parts.banco). At its entry in the sorted list, the stool's own
  // pixels (its parts' tags) are drawn again where their owner stands behind them: bakedZ[i] > the owner's plane at that
  // row (v / COS - (row + .5 - OY) * tan 30 / S)
  void front(String name) {
    final e = _frameEngine, s = _setFrame, Z = _setZ, T = _tagsNow, O = _own;
    if (e == null || s == null || Z == null || T == null || O == null) return;
    final parts = (sheet.frontParts[name]!.raw['parts'] as List).cast<String>();
    final cache = <EstufaItem, double?>{};
    final pix = e.pix, W0 = e.W;
    for (var i = 0; i < pix.length; i++) {
      final t = T[i], o = O[i];
      if (t == null || o == null || !parts.contains(t)) continue;
      final r = cache.containsKey(o) ? cache[o] : (cache[o] = planeOf(o, W));
      if (r == null) continue;
      final y = i ~/ W0;
      if (!(Z[i] > r / _COS - (y + .5 - e.OY) * _T30 / e.S)) continue;
      pix[i] = 0xFF000000 | (s[i] & 0xFFFFFF);
    }
  }

  // estufa-preview.html: PREVIEW.winA. The picture before the window's people are drawn
  Uint32List? _winA;
  void winA() {
    final e = _frameEngine;
    _winA = e == null ? null : Uint32List.fromList(e.pix);
  }

  // estufa-preview.html: PREVIEW.winB (sheet: front.parts.ventana). What the window's people drew, then the room's own
  // pixels nearer than their plane (world y = front.parts.ventana.y, outside) drawn again over them
  void winB() {
    final e = _frameEngine, a = _winA, s = _setFrame, Z = _setZ, T = _tagsNow;
    if (e == null || a == null || s == null || Z == null || T == null) return;
    final parts = (sheet.frontParts['ventana']!.raw['parts'] as List)
        .cast<String>();
    final pix = e.pix, W0 = e.W;
    for (var i = 0; i < pix.length; i++) {
      if ((a[i] & 0xFFFFFF) == (pix[i] & 0xFFFFFF)) continue;
      final t = T[i];
      if (t == null || !parts.contains(t)) continue;
      final x = i % W0, y = i ~/ W0;
      final v = (x + .5 - e.OX) / e.S + _ventanaY * math.sqrt2;
      if (!(Z[i] > v / _COS - (y + .5 - e.OY) * _T30 / e.S)) continue;
      pix[i] = 0xFF000000 | (s[i] & 0xFFFFFF);
    }
    _winA = null;
  }

  /* ---------- the picture ---------- */

  // estufa.js: COSA. Each thing's sprite, by its kind and its variant (`(COSA[k]||COSA.plato)(c)`)
  static Sprite cosaMake(String k, Object? c) {
    switch (k) {
      // a pot, open at the top: what is in it shows. c: the colours of what is in it, light to dark
      case 'olla':
        {
          final b = Buf(34, 24);
          const C = {
            'agua': ['#58A8E0', '#8CCBF5'],
            'arroz': ['#DCDCE8', '#FFFFFF'],
            'hab': ['#7A2416', '#B84A2E'],
            'choco': ['#4A220C', '#7A3A1A'],
            'vacia': ['#2A2A36', '#3A3A46'],
            'negra': ['#141418', '#2A2420'],
          };
          final col = _hs(C[c] ?? const ['#2A2A36', '#3A3A46']);
          b.rect(4, 8, 26, 14, _h('#8A8A9A'));
          b.rect(4, 8, 5, 14, _h('#B8B8C8'));
          b.rect(4, 19, 26, 3, _h('#5A5A6A'));
          b.rect(1, 10, 3, 4, _h('#3A3A46'));
          b.rect(30, 10, 3, 4, _h('#3A3A46'));
          b.ell(17, 8, 13, 5, _hs(['#5A5A6A', '#9494A6', '#C8C8D4']));
          b.ell(17, 8.4, 11, 3.8, col);
          if (c == 'arroz') {
            for (final q in const [
              [9, 8],
              [13, 6],
              [17, 7],
              [21, 6],
              [24, 8],
              [11, 10],
              [15, 9],
              [19, 10],
              [22, 10],
              [7, 9],
            ]) {
              b.rect(q[0], q[1], 2, 1, _h('#A8A090'));
            }
          }
          if (c == 'hab') {
            for (final q in const [
              [10, 8],
              [15, 7],
              [20, 9],
              [24, 8],
              [13, 10],
              [19, 6],
            ]) {
              b.rect(q[0], q[1], 2, 1, _h('#4A1408'));
            }
          }
          return b.outline().done();
        }
      case 'quemada':
        {
          final b = Buf(34, 24);
          for (final q in const [
            [6, 10, 3, 10],
            [12, 13, 2, 8],
            [20, 11, 4, 10],
            [27, 12, 2, 9],
          ]) {
            b.rect(q[0], q[1], q[2], q[3], _h('#1A1410'));
          }
          return b.done();
        }
      case 'sarten':
        {
          final b = Buf(46, 14);
          b.ell(17, 8, 15, 5, _hs(['#1E1E28', '#3A3A46', '#5A5A6A']));
          b.ell(17, 7.4, 12.6, 3.6, _hs(['#8A6A20', '#C8A040']));
          b.rect(31, 7, 13, 3, _h('#3A2414'));
          b.rect(31, 7, 13, 1, _h('#5A3A1A'));
          return b.outline().done();
        }
      case 'saco':
        {
          final b = Buf(20, 22);
          if (c == 'vacio') {
            b.rect(2, 14, 16, 7, _h('#D8C8A0'));
            b.rect(2, 14, 4, 7, _h('#EADCB8'));
            b.rect(2, 18, 16, 3, _h('#B8A478'));
            b.rect(4, 12, 13, 2, _h('#B8A478'));
            b.rect(12, 10, 6, 2, _h('#D8C8A0'));
            return b.outline().done();
          }
          b.rect(2, 5, 16, 16, _h('#D8C8A0'));
          b.rect(2, 5, 4, 16, _h('#EADCB8'));
          b.rect(2, 18, 16, 3, _h('#B8A478'));
          b.ell(10, 5, 7, 2.6, _hs(['#DCDCE8', '#FFFFFF']));
          for (final q in const [
            [6, 11],
            [10, 13],
            [13, 10],
            [8, 15],
            [12, 16],
          ]) {
            b.rect(q[0], q[1], 2, 1, _h('#FFFFFF'));
          }
          return b.outline().done();
        }
      case 'tazon':
        {
          final b = Buf(22, 14), ar = c == 'arroz';
          b.ell(11, 10, 8, 3.4, _hs(['#C8401E', '#E0603A']));
          b.ell(11, 6, 9.6, 4, _hs(['#C8401E', '#E0603A', '#F08A60']));
          b.ell(
            11,
            5,
            7.8,
            3.4,
            ar ? _hs(['#DCDCE8', '#FFFFFF']) : _hs(['#7A2416', '#B84A2E']),
          );
          b.ell(11, 3.6, 5, 2.2, ar ? _hs(['#FFFFFF']) : _hs(['#B84A2E']));
          for (final q in const [
            [5, 5],
            [8, 3],
            [11, 2],
            [14, 3],
            [16, 5],
            [7, 6],
            [11, 5],
            [14, 6],
            [10, 7],
          ]) {
            b.rect(q[0], q[1], 2, 1, ar ? _h('#A8A090') : _h('#3A0E04'));
          }
          return b.outline().done();
        }
      case 'medida':
        {
          final b = Buf(11, 11);
          b.rect(1, 5, 7, 5, _h('#F0C020'));
          b.rect(1, 5, 2, 5, _h('#FFE070'));
          b.rect(8, 6, 2, 1, _h('#F0C020'));
          b.rect(9, 7, 1, 2, _h('#F0C020'));
          if (c == 'hab') {
            b.ell(4.5, 3.6, 3.6, 2.6, _hs(['#7A2416', '#B84A2E']));
            b.px(3, 3, _h('#4A1408'));
            b.px(6, 4, _h('#4A1408'));
            b.px(4, 2, _h('#4A1408'));
          } else if (c == 'arroz') {
            b.ell(4.5, 3.6, 3.6, 2.6, _hs(['#C8C8D4', '#FFFFFF']));
            b.px(3, 3, _h('#DCDCE8'));
            b.px(6, 4, _h('#DCDCE8'));
          } else {
            b.rect(2, 4, 5, 2, _h('#8A6A10'));
          }
          return b.outline().done();
        }
      case 'basura':
        {
          final b = Buf(24, 13);
          b.ell(12, 9, 9, 3.4, _hs(['#6A6A7A', '#9494A6']));
          b.ell(12, 5, 10.6, 4, _hs(['#6A6A7A', '#9494A6', '#C8C8D4']));
          b.ell(12, 4.8, 8.6, 2.8, _hs(['#3A3A46']));
          return b.outline().done();
        }
      case 'monton':
        {
          final b = Buf(11, 7),
              C = c == 'hab'
                  ? _hs(['#7A2416', '#B84A2E'])
                  : c == 'negro'
                  ? _hs(['#141418', '#3A3028'])
                  : _hs(['#DCDCE8', '#FFFFFF']);
          b.ell(5.5, 4, 4.4, 2.4, C);
          b.px(3, 3, C[0]);
          b.px(7, 5, C[0]);
          return b.outline().done();
        }
      case 'espatula':
        {
          final b = Buf(6, 16);
          b.rect(1, 1, 4, 5, _h('#9494A6'));
          b.rect(2, 6, 2, 9, _h('#3A2414'));
          return b.outline().done();
        }
      case 'espumadera':
        {
          final b = Buf(18, 8);
          b.ell(5, 4, 4, 2.6, _hs(['#9494A6', '#C8C8D4']));
          b.px(4, 4, _h('#5A5A6A'));
          b.px(6, 3, _h('#5A5A6A'));
          b.rect(8, 3, 9, 2, _h('#6A3E1A'));
          return b.outline().done();
        }
      case 'cucharon':
        {
          final b = Buf(6, 18);
          b.rect(2, 1, 2, 12, _h('#B07A3C'));
          b.ell(3, 14, 2.6, 3, _hs(['#8A5A2A', '#B07A3C']));
          return b.outline().done();
        }
      case 'jarra':
        {
          final b = Buf(20, 22);
          b.rect(3, 3, 12, 18, _h('#E4F4FA'));
          b.rect(3, 8, 12, 13, _h('#7A3A1A'));
          b.rect(3, 3, 3, 18, _h('#F8FDFF'));
          for (final q in const [
            [5, 6],
            [10, 7],
            [7, 11],
            [11, 13],
          ]) {
            b.rect(q[0], q[1], 4, 4, _h('#C8F0FF'));
            b.rect(q[0], q[1], 2, 2, _h('#FFFFFF'));
          }
          b.rect(15, 6, 2, 1, _h('#B8D8E8'));
          b.rect(17, 7, 1, 7, _h('#B8D8E8'));
          b.rect(15, 14, 2, 1, _h('#B8D8E8'));
          b.rect(1, 3, 2, 2, _h('#E4F4FA'));
          return b.outline().done();
        }
      case 'taza':
        {
          final b = Buf(12, 12);
          b.rect(1, 4, 7, 7, _h('#F2F2F8'));
          b.rect(1, 4, 2, 7, _h('#FFFFFF'));
          b.rect(1, 10, 7, 1, _h('#C8C8D4'));
          b.rect(8, 5, 2, 1, _h('#F2F2F8'));
          b.rect(10, 6, 1, 3, _h('#F2F2F8'));
          b.rect(8, 9, 2, 1, _h('#F2F2F8'));
          b.rect(2, 4, 5, 2, jsTruthy(c) ? _h('#6A3214') : _h('#C8C8D4'));
          if (c == 'frio') {
            b.rect(1, 1, 3, 4, _h('#A8E4FF'));
            b.px(1, 1, _h('#FFFFFF'));
            b.px(2, 2, _h('#FFFFFF'));
            b.rect(5, 0, 3, 4, _h('#C8F0FF'));
            b.px(5, 0, _h('#FFFFFF'));
            b.px(6, 1, _h('#FFFFFF'));
          }
          if (c == 'cal') {
            b.rect(3, 0, 1, 3, _h('#FFFFFF'));
            b.rect(6, 1, 1, 2, _h('#FFFFFF'));
          }
          return b.outline().done();
        }
      case 'fritura':
        {
          if (c == 'burbujas') {
            final g = Buf(15, 9);
            g.ell(7.5, 5, 6, 3, _hs(['#C8A040', '#E8C860']));
            for (final q in const [
              [3, 4],
              [6, 2],
              [9, 4],
              [11, 6],
              [5, 6],
              [8, 6],
            ]) {
              g.rect(q[0], q[1], 2, 2, _h('#FFF4C0'));
              g.px(q[0], q[1], _h('#FFFFFF'));
            }
            return g.done();
          }
          final b = Buf(13, 8),
              C = c == 'negra'
                  ? _hs(['#141418', '#2A2420', '#3A3028'])
                  : c == 'cruda'
                  ? _hs(['#D8C890', '#F0E4B8', '#FBF4D8'])
                  : _hs(['#B87A20', '#E0A838', '#F8D070']);
          b.ell(6.5, 4, 5, 2.8, C);
          b.px(3, 3, C[0]);
          b.px(9, 5, C[0]);
          b.px(6, 2, C[2]);
          return b.outline().done();
        }
      case 'masa':
        {
          final b = Buf(24, 10);
          b.rect(1, 6, 22, 3, _h('#B07A3C'));
          b.rect(1, 6, 22, 1, _h('#D09A54'));
          b.outline();
          const all = [
            [4, 5],
            [9, 5],
            [14, 5],
            [19, 5],
          ];
          for (final q in _slice(all, c == null ? 4 : _plus(c))) {
            b.ell(
              q[0],
              q[1] - 1,
              2.4,
              2.2,
              _hs(['#D8C890', '#F0E4B8', '#FBF4D8']),
            );
            b.frame(q[0] - 3, q[1] - 4, 6, 6, OUT);
          }
          return b.done();
        }
      case 'fuente':
        {
          final b = Buf(24, 9);
          b.ell(12, 5, 10.6, 3.4, _hs(['#B8B8C8', '#F2F2F8', '#FFFFFF']));
          b.ell(12, 4.6, 7.6, 2, _hs(['#DCDCE8']));
          return b.outline().done();
        }
      case 'pinzas':
        {
          final b = Buf(6, 16);
          b.rect(1, 1, 1, 13, _h('#9494A6'));
          b.rect(4, 1, 1, 13, _h('#C8C8D4'));
          b.rect(1, 0, 4, 2, _h('#5A5A6A'));
          return b.outline().done();
        }
      case 'platito':
        {
          final b = Buf(11, 6);
          b.ell(5.5, 3, 4.6, 2.2, _hs(['#3A70B0', '#F2F2F8', '#FFFFFF']));
          return b.outline().done();
        }
      // a drumstick and a fried egg: raw, golden, black
      case 'muslo':
        {
          final b = Buf(16, 10),
              C = c == 'negro'
                  ? _hs(['#141418', '#2A2420', '#3A3028'])
                  : c == 'crudo'
                  ? _hs(['#D08A78', '#F0B0A0', '#FBD0C4'])
                  : _hs(['#8A4A14', '#C87A28', '#E8A848']);
          final bone = c == 'negro' ? _h('#2A2420') : _h('#F2EAD8');
          b.ell(6, 5, 5, 3.6, C);
          b.rect(10, 4, 4, 2, bone);
          b.ell(14, 4, 1.4, 1.4, [bone]);
          b.ell(14, 6, 1.4, 1.4, [bone]);
          return b.outline().done();
        }
      case 'frito':
        {
          final b = Buf(14, 9),
              W1 = c == 'negro'
                  ? _hs(['#141418', '#2A2420'])
                  : c == 'crudo'
                  ? _hs(['#F2F2F8', '#FFFFFF'])
                  : _hs(['#E8D8A8', '#FFFFFF']);
          b.ell(7, 4.5, 5.6, 3.4, W1);
          b.ell(7, 4, 2.2, 1.8, [
            c == 'negro' ? _h('#3A3028') : _h('#E8A020'),
            c == 'negro' ? _h('#3A3028') : _h('#FFD040'),
          ]);
          if (c == 'dorado') {
            b.px(2, 5, _h('#B87A28'));
            b.px(11, 6, _h('#B87A28'));
            b.px(4, 7, _h('#B87A28'));
          }
          return b.outline().done();
        }
      case 'huevo':
        {
          final b = Buf(8, 9);
          b.ell(4, 4.6, 2.8, 3.6, _hs(['#D8C8A8', '#F2E8D0', '#FFFAEE']));
          return b.outline().done();
        }
      case 'salero':
        {
          final b = Buf(8, 12);
          b.rect(1, 5, 6, 6, _h('#C8E4F0'));
          b.rect(2, 6, 4, 5, _h('#FFFFFF'));
          b.rect(1, 5, 1, 6, _h('#E8F6FC'));
          b.rect(2, 3, 4, 2, _h('#C8E4F0'));
          b.ell(4, 2.4, 2.6, 1.8, _hs(['#6A6A7A', '#9494A6', '#C8C8D4']));
          b.px(3, 2, _h('#2A2A36'));
          b.px(5, 2, _h('#2A2A36'));
          b.px(4, 1, _h('#2A2A36'));
          return b.outline().done();
        }
      case 'mantelito':
        {
          final b = Buf(34, 7);
          b.rect(1, 1, 32, 5, _h('#FFFFFF'));
          for (var x = 1; x < 33; x += 4) {
            b.rect(x, 1, 2, 5, _h('#E0403A'));
          }
          b.rect(1, 3, 32, 1, _h('#FFFFFF'));
          return b.outline().done();
        }
      case 'grano':
        {
          final b = Buf(7, 8);
          const pts = [
            [1, 1],
            [4, 2],
            [2, 4],
            [5, 5],
            [1, 6],
          ];
          for (final q in pts) {
            b.rect(q[0] - 1, q[1] - 1, 3, 3, _h('#6A6A7A'));
          }
          for (final q in pts) {
            b.px(q[0], q[1], _h('#FFFFFF'));
          }
          return b.done();
        }
      case 'monticulo':
        {
          final b = Buf(11, 8);
          b.ell(5.5, 5.4, 4.6, 2.4, _hs(['#C8C8D4', '#FFFFFF']));
          b.ell(5.5, 3.4, 2.6, 2, _hs(['#FFFFFF']));
          b.px(5, 0, _h('#FFFFFF'));
          return b.outline().done();
        }
      case 'bandeja':
        {
          final b = Buf(46, 9);
          b.rect(1, 3, 44, 5, _h('#9494A6'));
          b.rect(1, 3, 44, 1, _h('#C8C8D4'));
          b.rect(2, 4, 42, 3, _h('#6A6A7A'));
          return b.outline().done();
        }
      case 'cubo':
        {
          final b = Buf(22, 20);
          b.rect(3, 5, 16, 14, _h('#5A8A5A'));
          b.rect(3, 5, 4, 14, _h('#7AAA7A'));
          b.rect(3, 16, 16, 3, _h('#3A6A3A'));
          b.ell(11, 5, 8.6, 3, _hs(['#3A6A3A', '#5A8A5A', '#9ACA9A']));
          b.ell(11, 5, 6.6, 2, _hs(['#2A3A2A']));
          return b.outline().done();
        }
      case 'frasco':
        {
          final b = Buf(14, 18);
          b.rect(1, 4, 12, 13, _h('#E4F4FA'));
          b.rect(1, 4, 2, 13, _h('#F8FDFF'));
          if (c != 'vacio') {
            b.rect(2, 7, 10, 10, _h('#B84A2E'));
            for (final q in const [
              [3, 8],
              [7, 9],
              [10, 8],
              [4, 12],
              [8, 13],
              [5, 15],
              [10, 15],
            ]) {
              b.rect(q[0], q[1], 2, 1, _h('#4A1408'));
            }
          }
          b.rect(2, 1, 10, 3, _h('#9494A6'));
          b.rect(2, 1, 10, 1, _h('#C8C8D4'));
          return b.outline().done();
        }
      case 'platoc':
        {
          final b = Buf(15, 9), v = jsTruthy(c) ? _js(c) : '';
          b.ell(7.5, 5.5, 6.6, 2.8, _hs(['#3A70B0', '#5A90D0', '#8CB8E8']));
          if (v.contains('a')) {
            b.ell(
              v.contains('h') ? 5 : 7.5,
              4,
              3,
              2,
              _hs(['#B8B8C8', '#FFFFFF']),
            );
          }
          if (v.contains('h')) {
            b.ell(
              v.contains('a') ? 10 : 7.5,
              4.4,
              3,
              2,
              _hs(['#7A2416', '#B84A2E']),
            );
          }
          return b.outline().done();
        }
      case 'fuentec':
        {
          final b = Buf(24, 12);
          b.ell(12, 8, 10.6, 3.4, _hs(['#B8B8C8', '#F2F2F8', '#FFFFFF']));
          const all = [
            [7, 6],
            [13, 5],
            [17, 7],
            [10, 8],
          ];
          for (final q in _slice(all, c == null ? 3 : _plus(c))) {
            b.ell(q[0], q[1], 3.4, 2, _hs(['#B87A20', '#E0A838', '#F8D070']));
          }
          return b.outline().done();
        }
      case 'platof':
        {
          final b = Buf(13, 9);
          b.ell(6.5, 6, 5.6, 2.4, _hs(['#3A70B0', '#F2F2F8', '#FFFFFF']));
          b.ell(6.5, 4, 3.6, 2, _hs(['#B87A20', '#E0A838', '#F8D070']));
          return b.outline().done();
        }
      case 'granon':
        {
          final b = Buf(7, 8);
          for (final q in const [
            [1, 1],
            [4, 2],
            [2, 4],
            [5, 5],
            [1, 6],
          ]) {
            b.px(q[0], q[1], _h('#20140A'));
          }
          return b.done();
        }
      case 'vasochoco':
        {
          final b = Buf(10, 14);
          b.rect(1, 1, 8, 12, _h('#E8DCD0'));
          b.rect(1, 4, 8, 9, _h('#7A3A1A'));
          b.rect(1, 1, 2, 12, _h('#F6EEE6'));
          b.rect(1, 4, 1, 9, _h('#9A5A34'));
          b.rect(3, 3, 3, 3, _h('#DCF2FA'));
          b.px(3, 3, _h('#FFFFFF'));
          b.rect(5, 6, 3, 3, _h('#C8E8F6'));
          b.px(5, 6, _h('#FFFFFF'));
          return b.outline().done();
        }
      case 'cucharac':
        {
          final b = Buf(9, 8);
          b.ell(2.6, 2.6, 2.2, 2, _hs(['#DCDCE8', '#FFFFFF']));
          b.line(4, 4, 8, 7, _h('#9494A6'));
          b.line(4, 5, 7, 7, _h('#6A6A7A'));
          return b.outline().done();
        }
      case 'espuma':
        {
          final b = Buf(44, 36),
              C = c == 'hab'
                  ? _hs(['#D8A898', '#F0C8B8', '#FFE4DC'])
                  : _hs(['#B8B8C8', '#F2F2F8', '#FFFFFF']);
          for (final q in const [
            [12, 19, 3, 7],
            [21, 20, 4, 9],
            [30, 19, 3, 6],
          ]) {
            b.rect(q[0], q[1], q[2], q[3], C[1]);
            b.ell(q[0] + q[2] / 2, q[1] + q[3], q[2] / 2 + 0.6, 1.8, C);
          }
          for (final q in const [
            [10, 16, 5, 4],
            [16, 13, 6, 5],
            [25, 12, 6, 5],
            [32, 15, 6, 5],
            [21, 17, 10, 4],
          ]) {
            b.ell(q[0], q[1], q[2], q[3], C);
          }
          b.ell(5, 33, 5, 2.2, C);
          b.ell(39, 33, 5, 2.2, C);
          return b.outline().done();
        }
      case 'molinillo':
        {
          final b = Buf(8, 13);
          b.rect(2, 4, 4, 8, _h('#5A3A1A'));
          b.rect(2, 4, 1, 8, _h('#8A5A2A'));
          b.ell(4, 3, 2.6, 2.2, _hs(['#3A2414', '#5A3A1A']));
          b.rect(3, 0, 2, 2, _h('#C8C8D4'));
          return b.outline().done();
        }
      case 'vasoagua':
        {
          final b = Buf(10, 14);
          b.rect(1, 1, 8, 12, _h('#DCF2FA'));
          b.rect(1, 4, 8, 9, _h('#58B4EC'));
          b.rect(1, 1, 2, 12, _h('#F2FBFF'));
          b.rect(3, 3, 3, 3, _h('#FFFFFF'));
          b.rect(5, 6, 3, 3, _h('#E4F6FF'));
          return b.outline().done();
        }
      case 'cuenco':
        {
          final b = Buf(22, 13);
          b.ell(11, 9, 8, 3.4, _hs(['#B84A2E', '#D8704A']));
          b.ell(11, 5, 9.6, 4, _hs(['#B84A2E', '#D8704A', '#F09A70']));
          b.ell(11, 4.6, 7.6, 2.8, _hs(['#D8C890', '#F0E4B8']));
          b.rect(13, 0, 2, 5, _h('#8A5A2A'));
          return b.outline().done();
        }
      case 'banco':
        {
          final b = Buf(26, 20);
          b.rect(2, 1, 22, 4, RP.wood[3]);
          b.rect(2, 1, 22, 1, RP.wood[4]);
          b.rect(4, 5, 3, 14, RP.wood[1]);
          b.rect(19, 5, 3, 14, RP.wood[1]);
          b.rect(5, 11, 16, 2, RP.wood[1]);
          return b.outline().done();
        }
      // plato, and any kind estufa.js does not know
      default:
        {
          final b = Buf(15, 7);
          b.ell(7.5, 3.5, 6.6, 2.8, _hs(['#3A70B0', '#5A90D0', '#8CB8E8']));
          b.ell(7.5, 3.2, 4, 1.5, _hs(['#4A80C0']));
          return b.outline().done();
        }
    }
  }

  // JavaScript: `a.slice(0, n)` with n a number (NaN: none)
  static List<List<int>> _slice(List<List<int>> a, num n) {
    if (n.isNaN) return const [];
    final k = n.truncate();
    return a.sublist(
      0,
      k < 0 ? math.max(0, a.length + k) : math.min(k, a.length),
    );
  }

  // estufa.js: cosa (here cosaSpr: the kit's Escena has a `cosa` of its own, the thing of a key)
  Sprite cosaSpr(String k, [Object? c]) =>
      spr('es$k${c == null ? '' : _js(c)}', () => cosaMake(k, c));

  // estufa.js: tenida
  void tenida(
    Ctx c,
    String k,
    num x,
    num y, [
    Object? ang,
    Object? esc,
    Object? v,
  ]) {
    final im = cosaSpr(k, v);
    if (jsTruthy(ang) || jsTruthy(esc)) {
      c.save();
      c.translate(_round(x).toDouble(), _round(y).toDouble());
      if (jsTruthy(ang)) c.rotate((ang as num).toDouble());
      if (jsTruthy(esc)) {
        final s = (esc as num).toDouble();
        c.scale(s, s);
      }
      c.drawImage(im, -(im.w >> 1), -im.h);
      c.restore();
    } else {
      c.drawImage(im, _round(x) - (im.w >> 1), _round(y) - im.h);
    }
  }

  // estufa.js: llama (moves line 96: a burner's flames at its own row)
  void llama(Ctx c, num x, int a) {
    final t = (F >> 2) % 2;
    const flames = [
      [-13, 4],
      [-7, 6],
      [-1, 5],
      [5, 6],
      [11, 4],
    ];
    final row = FYi(x != FX[0] ? 1 : 0);
    for (var i = 0; i < flames.length; i++) {
      final q = flames[i], h = q[1] + ((i + t) % 2);
      fr(c, x + q[0], row + 4 - h, 3, h, _flame);
      fr(c, x + q[0] + 1, row + 5 - h + 1, 1, h - 2, _flameHi);
    }
  }

  // estufa.js: vapor. Steam over a pot, smoke from a burnt one
  void vapor(Ctx c, num x, num y, int negro) {
    final t = (F >> 2) % 6;
    if (negro != 0) {
      const puffs = [
        [-6, 2, 5],
        [1, -4, 6],
        [6, 1, 4],
        [-2, -10, 5],
      ];
      for (var i = 0; i < puffs.length; i++) {
        final p = puffs[i];
        final yy = y + p[1] - ((t + i * 2) % 6) * 2,
            xx = x + p[0] + ((t + i) % 3) - 1,
            r = p[2];
        fr(c, xx - 1, yy - 1, r + 2, r + 2, _smoke0);
        fr(c, xx, yy, r, r, _smoke1);
        fr(c, xx + 1, yy + 1, r - 3, r - 3, _smoke2);
      }
      return;
    }
    const wisps = [
      [-7, 0],
      [0, -4],
      [6, -1],
    ];
    for (var i = 0; i < wisps.length; i++) {
      final p = wisps[i];
      final yy = y + p[1] - ((t + i * 2) % 6);
      fr(c, x + p[0] + ((t + i) % 3) - 1, yy, 2, 3, _white);
    }
  }

  Map<String, dynamic>? _fuego(int i) {
    final f = W['fuegos'];
    if (f is! List || i < 0 || i >= f.length) return null;
    return f[i] as Map<String, dynamic>?;
  }

  // estufa.js: fuego (moves lines 99 to 101: the pot, its contents, foam, smoke and steam, the pan, at its burner's row)
  void fuego(Ctx c, int i, int a) {
    final f = _fuego(i);
    if (f == null || !jsTruthy(f['k'])) return;
    final x = FX[i], row = FYi(i);
    if (f['k'] == 'olla') {
      final n = f['n'], con = f['con'];
      tenida(
        c,
        'olla',
        x,
        row + 1,
        0,
        0,
        jsTruthy(f['negra']) && !jsTruthy(n)
            ? 'negra'
            : jsTruthy(n)
            ? con
            : (con == 'agua' || con == 'choco' ? con : 'vacia'),
      );
      if (jsTruthy(f['negra'])) {
        c.drawImage(cosaSpr('quemada'), x - 17, row - 23);
      }
      if (jsTruthy(f['mal'])) tenida(c, 'monton', x, row - 13, 0, 0, f['mal']);
      if (jsTruthy(f['espuma'])) {
        tenida(c, 'espuma', x, row + 3, 0, 0, f['espuma']);
        tenida(
          c,
          'monton',
          i != 0 ? x - 21 : x + 21,
          row + 6,
          0,
          0,
          f['espuma'],
        );
      }
      if (jsTruthy(f['humo'])) {
        vapor(c, x, row - _potSmoke, 1);
      } else if (jsTruthy(f['vapor']) && jsTruthy(f['llama'])) {
        vapor(c, x, row - _potSteam, 0);
      }
    } else {
      tenida(c, 'sarten', x + 6, row + 1);
      final cosas = (f['cosas'] as List?) ?? const [];
      for (var j = 0; j < cosas.length; j++) {
        final o = cosas[j] as Map<String, dynamic>;
        final px = x + j * 12 - ((cosas.length - 1) * 6);
        pieza(c, o, px, row - 3);
        if (jsTruthy(o['humo'])) vapor(c, px, row - _panSteam, 1);
      }
      if (jsTruthy(f['humo'])) {
        vapor(c, x, row - _panSteam, 1);
      } else if (jsTruthy(f['vapor'])) {
        vapor(c, x, row - _panSteam, 0);
      }
    }
    if (jsTruthy(f['llama'])) llama(c, x, a);
  }

  // estufa.js: pieza
  void pieza(Ctx c, Map<String, dynamic> o, num x, num y, [num? esc]) {
    tenida(c, o['k'] as String, x, y, 0, esc ?? 0, o['v']);
    final e = jsTruthy(esc) ? esc! : 1;
    if (o['sal'] is num && (o['sal'] as num) >= 2) {
      tenida(c, 'monticulo', x, y - 3 * e, 0, esc ?? 0);
    }
  }

  // estufa.js: alto
  int alto(String id) {
    final w = QUIEN[id];
    return id == 'abuela'
        ? 51
        : w != null && w.nino
        ? 44
        : 56;
  }

  // estufa.js: caja
  List<num>? caja(String id) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return null;
    final h = alto(id);
    return [_round(p['x'] as num) - 11, _round(p['y'] as num) - h, 22, h];
  }

  // estufa.js: persona
  Thing persona(String id) => Thing(
    id: id,
    m: 1,
    si: (w) {
      final g = w['gente'] as Map<String, dynamic>?;
      return g != null && g[id] != null && (g[id] as Map)['vis'] != 0;
    },
    box: (Map<String, dynamic> w) => caja(id),
  );

  // estufa.js: G
  Map<String, dynamic>? G(String id) =>
      (W['gente'] as Map<String, dynamic>?)?[id] as Map<String, dynamic>?;

  // estufa.js: COSAS
  @override
  late final List<Thing> cosas;

  /* ---------- drawing ---------- */

  // JavaScript: `o.k || o` (a thing held: its kind, or the string itself) and `o.v`
  static String _kOf(Object? o) =>
      o is Map ? (jsTruthy(o['k']) ? o['k'] as String : '$o') : '$o';
  static Object? _vOf(Object? o) => o is Map ? o['v'] : null;

  // JavaScript: `v || d` for a number a story gives
  static num _or(Object? v, num d) => jsTruthy(v) ? _plus(v) : d;

  // estufa.js: gente
  void gente(Ctx c, String id, int a) {
    final p = G(id);
    if (p == null || p['vis'] == 0) return;
    final w = QUIEN[id],
        x = _round(p['x'] as num),
        y = _round(p['y'] as num),
        habla = host.TALK == id && a % 2 != 0 ? 1 : 0,
        d = _left(p) ? -1 : 1;
    final paso = jsTruthy(p['paso']) && a % 2 != 0;
    if (id == 'abuela') {
      final ps = jsTruthy(p['pose']) ? p['pose'] as String : 'idle',
          top = y - 50 + (paso ? -1 : 0);
      c.save();
      c.translate(x.toDouble(), top.toDouble());
      if (((ps == 'offer' || ps == 'bless') ? -d : d) < 0) c.scale(-1, 1);
      c.drawImage(spr('ab$ps$habla', () => mkAbuela(ps, habla != 0)), -30, 0);
      c.restore();
      final lleva = p['lleva'];
      if (jsTruthy(lleva)) {
        tenida(c, _kOf(lleva), x + d * 14, y - 17, 0, 0, _vOf(lleva));
      }
      if (jsTruthy(p['bebe'])) {
        tenida(c, 'taza', x + d * 8, y - 24 - (a % 2), 0, 0, p['bebe']);
      }
      final alza = p['alza'];
      if (jsTruthy(alza)) {
        final z = alza as Map;
        tenida(
          c,
          z['k'] as String,
          x + d * _or(z['dx'], 18),
          y - 22 + _n(z['dy']),
          0,
          _or(z['e'], 2),
          z['v'],
        );
      }
      final come = p['come'];
      if (jsTruthy(come)) {
        final m = come as Map;
        tenida(c, m['k'] as String, x + d * 7, y - 30 + (a % 2), 0, 0, m['v']);
      }
      return;
    }
    final pose = jsTruthy(p['pose']) ? p['pose'] as String : 'idle',
        cierra = jsTruthy(p['cierra']),
        w2 = cierra ? w!.copyWith(dormido: true) : w!,
        im = spr(
          'pm$id$pose${habla}0${cierra ? 'c' : ''}',
          () => mkPersona(w2, pose, habla != 0, false),
        ),
        top = y - im.h + 1 + (paso ? -1 : 0) + _n(p['dy']);
    c.save();
    c.translate(x.toDouble(), top.toDouble());
    if ((pose == 'offer' ? -d : d) < 0) c.scale(-1, 1);
    c.drawImage(im, -PX, 0);
    c.restore();
    // estufa.js:122 (the sheet's faults: kept as the old) the baby whenever mamá has p.bebe, which is also the cup she
    // is handed
    final bebe = p['bebe'];
    if (jsTruthy(bebe) && id == 'mama') {
      final e = bebe == 1 ? 'idle' : _js(bebe),
          bi = spr('bb$e${a % 2}', () => mkBebe(e, a % 2 != 0));
      c.drawImage(bi, x + d * 2 - 13 + d * 8, y - 42);
    }
    final lleva = p['lleva'];
    if (jsTruthy(lleva)) {
      tenida(
        c,
        _kOf(lleva),
        x + d * 10,
        top + (w.nino ? 34 : 38),
        0,
        0,
        _vOf(lleva),
      );
    }
    final alza = p['alza'];
    if (jsTruthy(alza)) {
      final az = alza is Map ? alza : const {};
      final ax = x + d * _or(az['dx'], 13),
          ay = top + (w.nino ? 30 : 34) + _n(az['dy']);
      tenida(c, _kOf(alza), ax, ay, 0, _or(az['e'], 2), _vOf(alza));
    }
    // estufa.js:125 the cup, for anyone but mamá (the sheet's faults)
    if (jsTruthy(bebe) && id != 'mama') {
      tenida(
        c,
        'taza',
        x + d * 6,
        top + (w.nino ? 26 : 30) - (a % 2),
        0,
        0,
        bebe,
      );
    }
    final come = p['come'];
    if (jsTruthy(come)) {
      final m = come as Map;
      tenida(c, m['k'] as String, x + d * 6, top + 22 + (a % 2), 0, 0, m['v']);
    }
  }

  // estufa.js: nube2. A thought: a piece, perhaps salted
  void nube2(Ctx g, num x, num y, Map o, Object? sal) {
    fr(g, x - 1, y - 1, 28, 22, OUT);
    fr(g, x, y, 26, 20, _white);
    fr(g, x + 10, y + 20, 4, 4, OUT);
    fr(g, x + 11, y + 21, 2, 2, _white);
    tenida(g, o['k'] as String, x + 13, y + 18, 0, 0, o['v']);
    if (jsTruthy(sal)) tenida(g, 'salero', x + 19, y + 11, 0.6);
  }

  // estufa.js: nube. A thought: a cup
  void nube(Ctx g, num x, num y, Object? v) {
    fr(g, x - 1, y - 1, 22, 20, OUT);
    fr(g, x, y, 20, 18, _white);
    fr(g, x + 8, y + 18, 4, 4, OUT);
    fr(g, x + 9, y + 19, 2, 2, _white);
    tenida(g, 'taza', x + 10, y + 16, 0, 0, v);
    if (v == 'cal') {
      final t = (F >> 3) % 2;
      fr(g, x + 6 + t, y + 1, 1, 3, _steamCal);
      fr(g, x + 10 - t, y, 1, 3, _steamCal);
    }
  }

  // estufa.js: rana
  void rana(Ctx g, Map<String, dynamic> q, int a) {
    final b = frogBox(q),
        bl = (F % 47) < 2 ? 1 : 0,
        op =
            (q['bub'] == 'hola' ||
                    host.TALK == 'coqui' ||
                    jsTruthy(q['hace'])) &&
                a % 2 != 0
            ? 1
            : 0,
        dy = _round(_n(q['dy'])),
        cx = b.x + (b.w.toInt() >> 1);
    final s = q['s'] as num;
    g.globalAlpha = (q['al'] as num).toDouble();
    g.drawImage(
      spr('cq${jsNum(s)}_$bl$op', () => mkCoqui(s, bl, op != 0)),
      b.x,
      b.y + dy,
    );
    g.globalAlpha = 1;
    final en = W['encima'];
    if (jsTruthy(en)) {
      final m = en as Map;
      tenida(g, m['k'] as String, cx, b.y + dy + 3, 0, 0, m['v']);
    }
  }

  // estufa.js: bub2
  void bub2(Ctx c, String k, num tx, num ty, int a) {
    c.save();
    c.translate(tx.toDouble(), ty.toDouble());
    c.scale(2, 2);
    host.bub(c, k, 0, 0, a);
    c.restore();
  }

  // estufa.js: draw
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    final q = W['cq'] as Map<String, dynamic>,
        Gt = (W['gente'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        I = (W['izq'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        D = (W['der'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    // estufa.js:133 c.drawImage(spr("estufa",fondo),0,0) -> the set, for setKey(W) (sheet: dropped)
    // estufa.js:134 (moves): the family at the window, unclipped, outside; then the room's own pixels nearer than them
    // (front.parts.ventana: PREVIEW.winA, winB); their plates on the sill after, in the room
    final ventana = (W['ventana'] as List?) ?? const [];
    final V0 = _ventana;
    winA();
    if (ventana.isNotEmpty) {
      c.save();
      for (var j = 0; j < ventana.length; j++) {
        final id = ventana[j] as String, w = QUIEN[id]!;
        final im = spr(
          'pm${id}idle00',
          () => mkPersona(w, 'idle', false, false),
        );
        c.drawImage(
          im,
          V0[0] + j * V0[1] - PX + V0[2],
          (j < 3 ? V0[3 + j] : double.nan) + (j % 2) * V0[6],
        );
      }
      c.restore();
    }
    winB();
    if (ventana.isNotEmpty && jsTruthy(W['ventanacome'])) {
      for (var j = 0; j < ventana.length; j++) {
        tenida(c, 'plato', V0[7] + j * V0[8], j < 3 ? V0[9 + j] : double.nan);
      }
    }
    // estufa.js:135 (moves): the sack and the jar on the shelf
    if (jsTruthy(W['estante'])) {
      final v = W['estante'] == 2 ? 'vacio' : null;
      tenida(c, 'saco', _estante[0], _estante[1], 0, 0, v);
      tenida(c, 'frasco', _estante[2], _estante[3], 0, 0, v);
    }
    fuego(c, 0, a);
    fuego(c, 1, a);

    final olor = W['olor'];
    if (jsTruthy(olor)) {
      final o = [for (final v in olor as List) v as num];
      final t = (F >> 3) % 2, P = <List<int>>[];
      for (var i = 0; i <= 30; i++) {
        final u = i / 30,
            v = 1 - u,
            mx = (o[0] + o[2]) / 2,
            my = math.min(o[1], o[3]) - 16;
        P.add([
          _round(
            v * v * o[0] +
                2 * v * u * mx +
                u * u * o[2] +
                math.sin(i * 0.8 + t * 1.5) * 1.6,
          ),
          _round(v * v * o[1] + 2 * v * u * my + u * u * o[3]),
        ]);
      }
      for (final q in P) {
        fr(c, q[0] - 1, q[1] - 1, 3, 3, _smell);
      }
      for (final q in P) {
        fr(c, q[0], q[1], 1, 1, _smellHi);
      }
    }
    // the left counter
    // estufa.js:140 (moves): the sack and the jar Carmen fills the cups from, on the left counter's top
    if (jsTruthy(I['llenando'])) {
      tenida(c, 'saco', EN['saco']![0] - _llenando[0], _llenando[1]);
      tenida(c, 'frasco', EN['tazon']![0] + _llenando[2], _llenando[3]);
    }
    for (final e in const [
      ['saco', 'arroz'],
      ['tazon', 'hab'],
    ]) {
      final n = _n(I[e[0]]), q = EN[e[0]]!;
      const ds = [
        [0, -5],
        [-6, 0],
        [6, 0],
      ];
      for (final d in _slice(ds, n)) {
        tenida(c, 'medida', q[0] + d[0], q[1] + d[1], 0, 0, e[1]);
      }
    }
    // estufa.js:142 (moves): the tray on the left counter (BJ), what lies on it with it
    final band = I['bandeja'];
    if (jsTruthy(band)) {
      final t = band as Map;
      tenida(c, 'bandeja', 50, BJ);
      for (var i = 0; i < _num(t['pollo']); i++) {
        tenida(
          c,
          'muslo',
          36 + i * 8,
          BJ - _bandejaDy - (i % 2),
          0,
          0,
          'crudo',
        );
      }
      for (var i = 0; i < _num(t['huevo']); i++) {
        tenida(c, 'huevo', 58 + i * 7, BJ - _bandejaDy - (i % 2));
      }
    }
    // estufa.js:143 (moves line 20: REP)
    if (jsTruthy(W['repisa'])) {
      tenida(c, 'plato', REP[0], REP[1]);
      tenida(c, 'plato', REP[0], REP[1] - 2);
    }
    // estufa.js:144 (moves): the plates served to the children, each at its own row (SVY)
    final servidos = (D['servidos'] as List?) ?? const [];
    for (var i = 0; i < servidos.length; i++) {
      final pl = servidos[i] as Map;
      final x = SVX(i), y = SVY(i);
      tenida(c, 'plato', x, y, 0, 2);
      final items = pl['items'] as List;
      for (var j = 0; j < items.length; j++) {
        final o = items[j] as Map<String, dynamic>;
        pieza(c, o, x - 6 + j * 12, y - 3 - (jsTruthy(o['aparte']) ? 4 : 0));
      }
    }
    // estufa.js:145 (moves): the jug and the nine clean cups, their rows 3 apart
    if (jsTruthy(I['jarra'])) {
      tenida(c, 'jarra', EN['jarra']![0], EN['jarra']![1]);
    }
    for (var i = _n(I['tazas']).toInt() - 1; i >= 0; i--) {
      tenida(
        c,
        'taza',
        EN['tazas']![0] - 3 + (i % 3) * 9,
        EN['tazas']![1] - (i / 3).floor() * _tazasDy,
      );
    }
    // the right counter: plates, the waste bowl and what lies in it
    final platos = (D['platos'] as List?) ?? const [];
    for (var i = 0; i < platos.length; i++) {
      final p = platos[i] as Map;
      final x = EN['platos']![0] - 8 + i * 13, y = EN['platos']![1] + (i % 2);
      tenida(c, 'plato', x, y);
      if (jsTruthy(p['arroz'])) {
        tenida(
          c,
          'monton',
          x - 2,
          y - 2,
          0,
          0,
          p['negro'] == 'arroz' ? 'negro' : 'arroz',
        );
      }
      if (jsTruthy(p['hab'])) {
        tenida(
          c,
          'monton',
          x + 3,
          y - 1,
          0,
          0,
          jsTruthy(p['negrohab']) ? 'negro' : 'hab',
        );
      }
    }
    // estufa.js:148 (moves): the pile of clean plates and the small plate, behind the row of plates
    for (var i = 0; i < _n(D['pila']); i++) {
      tenida(c, 'plato', EN['platos']![0] + _pila[0], _pila[1] - i * _pila[2]);
    }
    if (jsTruthy(D['platito'])) {
      tenida(c, 'platito', EN['platos']![0] - _pila[3], _pila[4]);
    }

    if (D['masa'] != null) {
      tenida(c, 'masa', EN['masa']![0], EN['masa']![1], 0, 0, D['masa']);
    }
    if (jsTruthy(D['fuente'])) {
      tenida(c, 'fuente', EN['fuente']![0], EN['fuente']![1]);
      final fr0 = (D['frituras'] as List?) ?? const [];
      for (var i = 0; i < fr0.length; i++) {
        tenida(
          c,
          'fritura',
          EN['fuente']![0] - 6 + i * 6,
          EN['fuente']![1] - 3 - (i % 2),
          0,
          0,
          fr0[i],
        );
      }
    }

    final L = <EstufaItem>[];
    if (jsTruthy(W['cubo'])) {
      L.add(
        EstufaItem(CUBO[1] + 1, () {
          tenida(c, 'cubo', CUBO[0], CUBO[1]);
          final basura = (W['basura'] as List?) ?? const [];
          for (var i = 0; i < basura.length; i++) {
            final k = basura[i];
            if (k == 'taza') {
              tenida(
                c,
                'taza',
                CUBO[0] - 8 + i * 6,
                CUBO[1] - 10 - i * 2,
                -0.5,
              );
            } else if (k == 'negra') {
              tenida(
                c,
                'fritura',
                CUBO[0] - 4 + i * 5,
                CUBO[1] - 13 - i * 2,
                0,
                0,
                'negra',
              );
            } else {
              tenida(
                c,
                'monton',
                CUBO[0] - 4 + i * 5,
                CUBO[1] - 13 - i * 2,
                0,
                0,
                k,
              );
            }
          }
        }),
      );
    }
    // estufa.js:154, the old stool (W.banco), is dropped (sheet: dropped): the set's (setKey banco1, front.banco)
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p != null && p['vis'] != 0) {
        L.add(EstufaItem(_num(p['y']), () => gente(c, id, a), id: id));
      }
    }
    for (final o0 in (W['cosas'] as List?) ?? const []) {
      final o = o0 as Map<String, dynamic>;
      if (o['vis'] != 0) {
        L.add(
          EstufaItem(o['z'] != null ? o['z'] as num : (o['y'] as num) + 1, () {
            tenida(
              c,
              o['k'] as String,
              o['x'] as num,
              o['y'] as num,
              o['rot'],
              0,
              o['v'],
            );
            if (jsTruthy(o['vapor'])) {
              vapor(c, (o['x'] as num) - 1, (o['y'] as num) - 15, 0);
            }
          }),
        );
      }
    }
    if (jsTruthy(q['vis'])) {
      L.add(EstufaItem((q['y'] as num) + 27, () => rana(c, q, a), id: 'coqui'));
    }
    // the sheet's front: the stool after everyone (front.parts.banco, sortY 9999), drawn again over whoever is behind it
    for (final en in sheet.frontParts.entries) {
      final sortY = en.value.sortY;
      if (sortY == null) continue;
      final name = en.key;
      L.add(EstufaItem(sortY, () => front(name), front: name));
    }
    _own = null;
    // JavaScript's sort is stable: the index breaks a tie
    final byRow = [...L.indexed]
      ..sort((m, n) {
        final d = m.$2.y.compareTo(n.$2.y);
        return d != 0 ? d : m.$1.compareTo(n.$1);
      });
    for (final o in byRow) {
      item(o.$2);
    }
    final plata = W['plata'];
    if (jsTruthy(plata)) {
      final P = plata as Map;
      tenida(c, 'plato', P['x'] as num, P['y'] as num, 0, 3);
      final items = P['items'] as List;
      for (var j = 0; j < items.length; j++) {
        pieza(
          c,
          items[j] as Map<String, dynamic>,
          jsTruthy(P['solo']) ? P['x'] as num : (P['x'] as num) - 11 + j * 22,
          (P['y'] as num) - 6,
          2,
        );
      }
    }
    final mat = W['mat'];
    if (jsTruthy(mat)) {
      final m = mat as Map;
      tenida(c, 'platito', m['x'] as num, m['y'] as num, 0, 2);
      if (jsTruthy(m['o'])) {
        pieza(
          c,
          m['o'] as Map<String, dynamic>,
          (m['x'] as num) + _n(m['dx']),
          (m['y'] as num) - 4,
        );
      }
      if (jsTruthy(m['taza'])) {
        tenida(
          c,
          'taza',
          (m['x'] as num) + 7,
          (m['y'] as num) - 3,
          0,
          0,
          m['taza'],
        );
      }
    }
    // estufa.js:161 (moves): the shaker on the stove's top (SALY)
    if (jsTruthy(W['salero'])) tenida(c, 'salero', SALX, SALY);
    for (final o0 in (W['vuelos'] as List?) ?? const []) {
      final o = o0 as Map<String, dynamic>;
      tenida(
        c,
        o['k'] as String,
        o['x'] as num,
        o['y'] as num,
        o['rot'],
        0,
        o['v'],
      );
    }
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p != null && jsTruthy(p['piensa']) && p['vis'] != 0) {
        final pi = p['piensa'];
        if (pi is Map && jsTruthy(pi['k'])) {
          nube2(
            c,
            _round(p['x'] as num) - 14 + _n(pi['dx']),
            _round(p['y'] as num) - alto(id) - 26,
            pi,
            pi['sal'],
          );
        } else {
          nube(
            c,
            _round(p['x'] as num) - 14 + _n(p['pdx']),
            _round(p['y'] as num) - alto(id) - 24,
            pi,
          );
        }
      }
    }
    // estufa.js:164 a person's bubble, where the sheet's talk puts it
    for (final id in Gt.keys) {
      final p = Gt[id] as Map<String, dynamic>?;
      if (p != null && jsTruthy(p['bub']) && p['vis'] != 0) {
        final t = talkPlace(
          [_round(p['x'] as num), _round(p['y'] as num) - alto(id) - 1],
          6,
          p['bub'],
          W,
        );
        bub2(c, p['bub'] as String, t[0], t[1], a);
      }
    }
    // estufa.js:165 the frog's bubble, where the sheet's talk puts it
    if (jsTruthy(q['vis']) && jsTruthy(q['bub'])) {
      final b = frogBox(q),
          t = talkPlace(
            [b.x + (b.w.toInt() >> 1), b.y + 2],
            b.w.toInt() >> 1,
            q['bub'],
            W,
          );
      bub2(c, q['bub'] as String, t[0], t[1], a);
    }
    // the set as framed is this frame's only (drawFrame gives it again before the next)
    _frameEngine = null;
    _setFrame = null;
    _setZ = null;
    _tagsNow = null;
    _own = null;
  }

  // estufa-preview.html: PV.face (sheet talk.faces). A person's face: [x - 6, top + 6, 12, 10], top = y - height + 1 +
  // dy; abuela's: [x + f * abuelaHead - 6, y - 50 + 6, 12, 10], f = 1 facing right (her pose offer or bless turns her)
  List<num> face(String id, Map<String, dynamic> p) {
    final x = _round(p['x'] as num);
    if (id == 'abuela') {
      final ps = jsTruthy(p['pose']) ? p['pose'] : 'idle',
          f = ((ps == 'offer' || ps == 'bless') ? -1 : 1) * (_left(p) ? -1 : 1);
      return [
        x + f * _talk.abuelaHead! - 6,
        _round(p['y'] as num) - 50 + 6,
        12,
        10,
      ];
    }
    final top =
        _round(p['y'] as num) - _talk.heights[id]! + 1 + _round(_n(p['dy']));
    return [x - 6, top + 6, 12, 10];
  }

  // estufa-preview.html: PV.faces. Every face shown: each person's (not less than half faded in) and the frog's
  List<List<num>> faces(Map<String, dynamic> w) {
    final out = <List<num>>[];
    final gente = (w['gente'] as Map<String, dynamic>?) ?? const {};
    for (final en in gente.entries) {
      final p = en.value as Map<String, dynamic>?;
      if (p == null ||
          p['vis'] == 0 ||
          (p['al'] != null && (p['al'] as num) < .5)) {
        continue;
      }
      out.add(face(en.key, p));
    }
    final cq = w['cq'] as Map<String, dynamic>?;
    if (cq != null &&
        jsTruthy(cq['vis']) &&
        !(cq['al'] is num && (cq['al'] as num) < .5)) {
      final b = frogBox(cq);
      out.add([b.x + 2, b.y + _round(_n(cq['dy'])), b.w - 4, _round(b.h * .6)]);
    }
    return out;
  }

  // estufa-preview.html: PREVIEW.talk (sheet: talk). Where a bubble's tail goes: the first of the sheet's places beside
  // the head [top] (h: the head's half width) whose bubble ([k]'s rectangle, bubbles.rects) is wholly inside the view,
  // clear of the corner card (W.tarjeta: talk.board, + the view's x0) and of every face; if none is, [top] (the old)
  List<num> talkPlace(List<num> top, num h, Object? k, Map<String, dynamic> w) {
    if (!jsTruthy(k) || !sheet.bubbleRects.containsKey(k)) return top;
    final T = _talk, Rc = sheet.bubbleRects[k]!, x0 = host.cam[0];
    final fs = faces(w), boards = <List<num>>[];
    if (jsTruthy(w['tarjeta'])) {
      final b = [...T.boardRect!];
      boards.add([b[0] + x0, b[1], b[2], b[3]]);
    }
    bool meets(List<num> a, List<num> b) =>
        a[0] < b[0] + b[2] &&
        b[0] < a[0] + a[2] &&
        a[1] < b[1] + b[3] &&
        b[1] < a[1] + a[3];
    for (final pl in T.places) {
      final tx = top[0] + pl.side * (h + 16),
          ty = top[1] + pl.dy,
          r = [tx + Rc[0], ty + Rc[1], Rc[2], Rc[3]];
      if (r[0] >= x0 &&
          r[1] >= 0 &&
          r[0] + r[2] <= x0 + 196 &&
          r[1] + r[3] <= 216 &&
          !boards.any((b) => meets(r, b)) &&
          !fs.any((f) => meets(r, f))) {
        return [tx, ty];
      }
    }
    return top;
  }

  // estufa.js: talkAt
  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) {
    final p =
        (W['gente'] as Map<String, dynamic>?)?[who] as Map<String, dynamic>?;
    if (p == null || p['vis'] == 0) return null;
    return [_round(p['x'] as num), _round(p['y'] as num) - alto(who) - 1];
  }

  // estufa.js: respIcon
  @override
  dynamic respIcon(Ctx c, String k, num x, num y, num w, num h, int a) {
    final g = c;
    g.smoothing = false;
    final hw = w.toInt() >> 1, hh = h.toInt() >> 1;
    if (k == 'espera') {
      mano(g, x + hw - 14, y + hh - 9);
      mano(g, x + hw + 1, y + hh - 9);
    } else if (k == 'salpollo' || k == 'salhuevo') {
      tenida(
        g,
        k == 'salpollo' ? 'muslo' : 'frito',
        x + hw - 2,
        y + h - 3,
        0,
        2,
        'dorado',
      );
      tenida(g, 'salero', x + hw + 8, y + h - 14, 0.7, 2);
    } else if (k == 'saca') {
      tenida(g, 'pinzas', x + hw - 4, y + h - 8, 0.5, 2);
      tenida(g, 'fritura', x + hw + 6, y + h - 4, 0, 2, 'dorada');
    }
    return null;
  }

  // estufa.js: hud. The card steps aside while three picture bubbles stand at the top
  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    final g = c;
    if (!jsTruthy(W['tarjeta'])) return;
    kit.tarjeta(g, 3, 3, 66, 24);
    final marcas = W['marcas'] is List ? W['marcas'] as List : const [];
    for (var i = 0; i < marcas.length; i++) {
      final m = marcas[i], x = 10 + i * 20, y = 6;
      if (m == 'ok') {
        const st = [
          '......#......',
          '.....###.....',
          '.....###.....',
          '#############',
          '.###########.',
          '..#########..',
          '...#######...',
          '..#########..',
          '.####...####.',
          '.###.....###.',
          '##.........##',
        ];
        g.fillStyle = OUT;
        for (var j = 0; j < st.length; j++) {
          final rw = st[j];
          for (var ii = 0; ii < rw.length; ii++) {
            if (rw[ii] == '#') g.fillRect(x + ii - 1, y + j + 1, 3, 3);
          }
        }
        g.fillStyle = _star;
        for (var j = 0; j < st.length; j++) {
          final rw = st[j];
          for (var ii = 0; ii < rw.length; ii++) {
            if (rw[ii] == '#') g.fillRect(x + ii, y + j + 2, 1, 1);
          }
        }
      } else if (jsTruthy(m)) {
        g.fillStyle = OUT;
        for (var k = 0; k < 11; k++) {
          g.fillRect(x + k, y + 1 + k, 4, 3);
          g.fillRect(x + 10 - k, y + 1 + k, 4, 3);
        }
        g.fillStyle = _cross;
        for (var k = 0; k < 11; k++) {
          g.fillRect(x + 1 + k, y + 2 + k, 2, 1);
          g.fillRect(x + 11 - k, y + 2 + k, 2, 1);
        }
      } else {
        g.fillStyle = _empty;
        g.fillRect(x + 1, y + 13, 12, 1);
        g.fillRect(x + 1, y + 1, 1, 12);
        g.fillRect(x + 12, y + 1, 1, 12);
        g.fillRect(x + 1, y + 1, 12, 1);
      }
    }
  }

  // estufa.js: marca
  void marca(Object? m) {
    final l = W['marcas'] is List ? W['marcas'] as List : const [];
    final i = l.indexOf(null);
    if (i >= 0) l[i] = m;
  }

  /* ---------- moving things ---------- */

  // estufa.js: mueve
  Future<void> mueve(String id, num x, num y, [num? n0]) async {
    final p = G(id);
    if (p == null) return;
    final x0 = _num(p['x']), y0 = _num(p['y']);
    final dx = x - x0, dy = y - y0;
    final n = n0 != null && n0 != 0
        ? n0
        : math.max(3, _roundN(math.sqrt(dx * dx + dy * dy) / 6));
    p['sent'] = 0;
    p['paso'] = 1;
    if ((x - x0).abs() > 3) p['dir'] = x > x0 ? 1 : -1;
    for (var i = 1; i <= n; i++) {
      p['x'] = x0 + (x - x0) * i / n;
      p['y'] = y0 + (y - y0) * i / n;
      await wait(TICK);
    }
    p['x'] = x;
    p['y'] = y;
    p['paso'] = 0;
  }

  // estufa.js: vuela (the second of its two definitions, the one that runs: an arc 10 px high)
  Future<void> vuela(
    Map<String, dynamic> o,
    num x0,
    num y0,
    num x1,
    num y1, [
    num? n0,
  ]) async {
    final v = <String, dynamic>{'x': x0, 'y': y0, ...o};
    final vuelos = W['vuelos'] as List;
    vuelos.add(v);
    final n = n0 != null && n0 != 0 ? n0 : 5;
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      v['x'] = x0 + (x1 - x0) * t;
      v['y'] = y0 + (y1 - y0) * t - math.sin(t * math.pi) * 10;
      await wait(TICK);
    }
    vuelos.remove(v);
  }

  Map<String, dynamic> get _cq => W['cq'] as Map<String, dynamic>;

  // estufa.js: cx, pies
  num cx() => (_cq['x'] as num) + 16;
  num pies() => (_cq['y'] as num) + 27;

  // estufa.js: ranaA
  Future<void> ranaA(num x, num y, [num? h]) async {
    final q = _cq,
        dx = x - 16 - (q['x'] as num),
        dy = y - 27 - (q['y'] as num),
        d = math.sqrt(dx * dx + dy * dy);
    if (d < 3) return;
    await hopTo(
      _round(x - 16),
      _round(y - 27),
      (h != null && h != 0 ? h : math.max(1, math.min(3, _round(d / 40))))
          .toInt(),
    );
  }

  // estufa.js: cae28. The shaker over a place, salt falling three times
  Future<void> cae28(num x, num y) async {
    final vuelos = W['vuelos'] as List;
    final v = <String, dynamic>{
      'k': 'salero',
      'x': x + 4,
      'y': y - 4,
      'rot': 0.7,
    };
    vuelos.add(v);
    for (var i = 0; i < 3; i++) {
      final g = <String, dynamic>{
        'k': 'grano',
        'x': x - 2 + i * 2,
        'y': y + i * 2,
      };
      vuelos.add(g);
      await wait(110);
      vuelos.remove(g);
    }
    SFX.blip();
    await wait(150);
    vuelos.remove(v);
  }

  // estufa.js: alBanco
  Future<void> alBanco() => ranaA(BANCO[0], BANCO[1]);

  // estufa.js: corre. An act a story lets run on (`suelto`): it goes on while the story does, and `ya` waits for it
  Future<void> corre(Map<String, dynamic>? o, Future<void> pr) {
    if (o != null && jsTruthy(o['suelto'])) {
      W['_mov'] = pr;
      return Future.value();
    }
    return pr;
  }

  // estufa.js: olla. Which burner: by its cook, or by its name
  static int olla(Object? a) {
    if (a == 'abuela') return 1;
    if (a == 'luis') return 0;
    final n = _plus('$a'.replaceFirst('olla', ''));
    return n.isNaN ? -1 : n.toInt();
  }

  // estufa.js: cocinero
  static String cocinero(int i) => i != 0 ? 'abuela' : 'luis';

  // estufa.js: pz
  static String pz(Object? k0) {
    var k = jsTruthy(k0) ? '$k0' : '';
    k = k.replaceFirst(RegExp(r'^di_|^pz|^sal'), '');
    return k == 'pollo' || k == 'muslo' ? 'muslo' : 'frito';
  }

  // estufa.js: clase
  static String clase(Object? k0) {
    var k = jsTruthy(k0) ? '$k0' : '';
    k = k.replaceFirst(RegExp(r'^di_'), '');
    return k == 'saco' || k == 'arroz' ? 'arroz' : 'hab';
  }

  // estufa.js: cae. A cup of rice or of beans goes into a pot. If the pot cooks the other thing, it lies on top and has to
  // come out again
  int cae(int i, String k) {
    final f = _fuego(i)!;
    if (!jsTruthy(f['n']) || f['con'] == k) {
      f['con'] = k;
      f['n'] = math.min(3, _n(f['n']) + 1);
      f['mal'] = null;
      SFX.blip();
      return 0;
    }
    f['mal'] = k;
    SFX.bonk();
    return 1;
  }

  Map<String, dynamic> get _izq => W['izq'] as Map<String, dynamic>;
  Map<String, dynamic> get _der => W['der'] as Map<String, dynamic>;
  List get _basura => W['basura'] as List;

  // JavaScript: `m[k]--` of a count
  void _dec(Map<String, dynamic> m, String k) => m[k] = _num(m[k]) - 1;

  // JavaScript: `a.find(f)` (null: undefined)
  static Map? _find(List l, bool Function(Map m) f) {
    for (final m in l) {
      if (m is Map && f(m)) return m;
    }
    return null;
  }

  // estufa.js: acts
  @override
  late final Map<String, Act> ownActs = {
    'marca': (o) async {
      marca(o['que']);
      SFX.blip();
      await wait(250);
    },
    'ya': (o) async {
      final p = W['_mov'];
      W['_mov'] = null;
      if (p is Future) await p;
    },
    'g': (o) async {
      final p = G(o['quien'] as String);
      if (p == null) return;
      for (final k in o.keys) {
        if (!const ['act', 'quien', 'ms'].contains(k)) {
          p[k] = o[k] == '' ? null : o[k];
        }
      }
      if (jsTruthy(o['ms'])) await wait(_plus(o['ms']));
    },

    /* ----- story 27: Arroz con habichuelas ----- */
    // Three cups of rice and three of beans for three plates: one cup is one plate's worth. W.fuegos[i].n is how many cups
    // are in the pot.
    'inicio27': (o) async {
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{
          'x': LADO[1][0],
          'y': LADO[1][1],
          'dir': -1,
        },
        'luis': <String, dynamic>{'x': LADO[0][0], 'y': LADO[0][1], 'dir': 1},
        'carmen': <String, dynamic>{'x': AYUDA[0], 'y': AYUDA[1], 'dir': 1},
        'abuelo': <String, dynamic>{'vis': 0},
        'mama': <String, dynamic>{'vis': 0},
        'papa': <String, dynamic>{'vis': 0},
      };
      W['fuegos'] = <dynamic>[
        <String, dynamic>{
          'k': 'olla',
          'con': 'agua',
          'n': 0,
          'llama': 1,
          'vapor': 1,
        },
        <String, dynamic>{
          'k': 'olla',
          'con': 'agua',
          'n': 0,
          'llama': 1,
          'vapor': 1,
        },
      ];
      W['izq'] = <String, dynamic>{'saco': 3, 'tazon': 3};
      W['der'] = <String, dynamic>{
        'platos': <dynamic>[],
        'pila': 6,
        'platito': 1,
      };
      W['cubo'] = 1;
      W['basura'] = <dynamic>[];
      W['ventana'] = <dynamic>[];
      W['estante'] = 1;
      V['fa'] = '';
    },
    'nota': (o) async {
      V[o['k'] as String] = o['v'] == null ? '1' : _js(o['v']);
    },
    // the frog tips a cup of rice or of beans into a cook's pot (moves line 204: he still stands where he stood before the
    // cups of rice, EN.saco moved 4 px right)
    'echa': (o) async {
      final k = clase(o['k']), i = olla(o['a']);
      final key = k == 'arroz' ? 'saco' : 'tazon', e = EN[key]!;
      Future<void> run() async {
        await ranaA(e[0] + (key == 'saco' ? _echa[0] : _echa[1]), _echa[2]);
        if (jsTruthy(_izq[key])) _dec(_izq, key);
        W['encima'] = <String, dynamic>{'k': 'medida', 'v': k};
        SFX.blip();
        await ranaA(FX[i], _p.at(204, 190));
        await wait(100);
        W['encima'] = null;
        await vuela(
          {'k': 'medida', 'v': k},
          FX[i],
          _p.at(204, 165),
          FX[i],
          FYi(i) - 18,
          5,
        );
        V['mal'] = cae(i, k) != 0 ? '1' : '';
        await wait(250);
        await alBanco();
      }

      return corre(o, run());
    },
    // Carmen tips one in (moves line 206)
    'carmenecha': (o) async {
      final k = clase(o['k']), i = olla(o['a']), c = G('carmen')!;
      final key = k == 'arroz' ? 'saco' : 'tazon', e = EN[key]!;
      if (!jsTruthy(_izq[key])) return;
      Future<void> run() async {
        await mueve(
          'carmen',
          e[0] + (key == 'saco' ? _carmenecha[0] : _carmenecha[1]),
          AYUDA[1],
        );
        _dec(_izq, key);
        c['lleva'] = <String, dynamic>{'k': 'medida', 'v': k};
        SFX.blip();
        await mueve('carmen', FX[i] - (i != 0 ? 10 : 22), AYUDA[1] + 8);
        await wait(100);
        c['lleva'] = null;
        await vuela(
          {'k': 'medida', 'v': k},
          (c['x'] as num) + 8,
          (c['y'] as num) - 30,
          FX[i],
          FYi(i) - 18,
          5,
        );
        V['mal'] = cae(i, k) != 0 ? '1' : '';
        await wait(250);
        await mueve('carmen', AYUDA[0], AYUDA[1]);
        c['dir'] = 1;
      }

      return corre(o, run());
    },
    // each cook tips in the last cup of his own thing, if one is left (moves line 208)
    'ultimas27': (o) async {
      for (final i in const [0, 1]) {
        final f = _fuego(i)!, key = f['con'] == 'arroz' ? 'saco' : 'tazon';
        while (jsTruthy(f['n']) && (f['n'] as num) < 3 && _num(_izq[key]) > 0) {
          _dec(_izq, key);
          await vuela(
            {'k': 'medida', 'v': f['con']},
            EN[key]![0],
            EN[key]![1] - 8,
            FX[i],
            FYi(i) - 18,
            6,
          );
          cae(i, f['con'] as String);
          await wait(150);
        }
      }
    },
    // the cook shakes his head and lifts out what does not belong in his pot, into the waste bucket (moves line 210)
    'saca': (o) async {
      final i = olla(o['a']), f = _fuego(i)!;
      final k = jsTruthy(f['mal'])
          ? f['mal']
          : (jsTruthy(f['n']) ? f['con'] : null);
      if (!jsTruthy(k)) return;
      final id = cocinero(i), p = G(id)!;
      for (final d in const [-1, 1, -1, 1]) {
        p['dir'] = d;
        await wait(150);
      }
      p['dir'] = i != 0 ? -1 : 1;
      p['lleva'] = 'espumadera';
      await wait(350);
      if (jsTruthy(f['mal'])) {
        f['mal'] = null;
      } else {
        f['n'] = 0;
        f['con'] = 'agua';
      }
      await vuela(
        {'k': 'monton', 'v': k},
        FX[i],
        FYi(i) - 16,
        CUBO[0],
        CUBO[1] - 14,
        9,
      );
      _basura.add(k);
      p['lleva'] = null;
      SFX.bonk();
      await wait(400);
    },
    'cuchara': (o) async {
      final p = G(o['a'] as String)!;
      Future<void> run() async {
        p['lleva'] = 'cucharon';
        await wait(_plus(jsTruthy(o['ms']) ? o['ms'] : 900));
        p['lleva'] = null;
      }

      return corre(o, run());
    },
    // a cook holds an empty cup up: his pot wants more
    'pide': (o) async {
      final p = G(o['a'] as String)!;
      p['alza'] = jsTruthy(o['no'])
          ? null
          : <String, dynamic>{
              'k': 'medida',
              'e': 1,
              'dx': o['a'] == 'abuela' ? 16 : 11,
              'dy': o['a'] == 'abuela' ? -6 : -4,
            };
      if (!jsTruthy(o['no'])) SFX.blip();
      await wait(250);
    },
    // abuela, Luis and Carmen go to the right counter and set three plates out; only the frog is at the stove. vuelve: they
    // come back (moves line 216: abuela and Carmen on clear floor in front of the right counter)
    'platos27': (o) async {
      final ab = G('abuela')!, l = G('luis')!, ca = G('carmen')!;
      if (jsTruthy(o['vuelve'])) {
        await Future.wait([
          mueve('abuela', LADO[1][0], LADO[1][1]),
          mueve('luis', LADO[0][0], LADO[0][1]),
          mueve('carmen', AYUDA[0], AYUDA[1]),
        ]);
        ab['dir'] = -1;
        l['dir'] = 1;
        ca['dir'] = 1;
        return;
      }
      final P = _platos27, ep = EN['platos']![0];
      await Future.wait([
        mueve('abuela', ep + P[0], LADO[1][1] + P[1]),
        mueve('luis', ep - P[2], LADO[1][1] + P[3]),
        mueve('carmen', ep + P[4], LADO[1][1] + P[5]),
      ]);
      ab['dir'] = 1;
      l['dir'] = 1;
      ca['dir'] = -1;
      final platos = _der['platos'] as List;
      while (platos.length < 3 && _num(_der['pila']) > 0) {
        _dec(_der, 'pila');
        platos.add(<String, dynamic>{});
        SFX.blip();
        await wait(180);
      }
    },
    // the flame under a pot goes out, or is lit again; a pot that stays on after it is ready boils over: foam down the
    // stove, its flame out, a cup's worth gone
    'apaga': (o) async {
      _fuego(olla(o['a']))!['llama'] = 0;
      SFX.blip();
      await wait(350);
    },
    'enciende': (o) async {
      _fuego(olla(o['a']))!['llama'] = 1;
      SFX.blip();
      await wait(300);
    },
    'derrama': (o) async {
      final f = _fuego(olla(o['a']))!, q = _cq;
      await wait(400);
      f['espuma'] = f['con'];
      SFX.bonk();
      q['dy'] = 4;
      await wait(700);
      f['n'] = math.max(0, _num(f['n']) - 1);
      await wait(400);
      q['dy'] = 0;
    },
    // one pot of water goes on the stove, at its cook's burner
    'unaolla': (o) async {
      (W['fuegos'] as List)[olla(o['a'])] = <String, dynamic>{
        'k': 'olla',
        'con': 'agua',
        'n': 0,
        'llama': 1,
        'vapor': 1,
      };
      SFX.blip();
      await wait(300);
    },
    // the plates are filled: one cup's worth of each on a plate, as far as the pots go; from a burnt pot the food is black
    // (moves line 225: each helping starts at its pot)
    'sirve27': (o) async {
      final ab = G('abuela')!, P = _der['platos'] as List;
      await ownActs['platos27']!(<String, dynamic>{});
      ab['dir'] = -1;
      ab['lleva'] = 'cucharon';
      for (final i in const [0, 1]) {
        final f = _fuego(i)!;
        if (!jsTruthy(f['n'])) continue;
        final arroz = f['con'] == 'arroz';
        for (final j in (arroz ? const [0, 2, 1] : const [1, 2, 0])) {
          if (!jsTruthy(f['n']) || j >= P.length || P[j] == null) continue;
          f['n'] = _num(f['n']) - 1;
          await vuela(
            {'k': 'monton', 'v': f['con']},
            FX[i],
            FYi(i) - 16,
            EN['platos']![0] - 8 + j * 13,
            EN['platos']![1] - 6,
            4,
          );
          if (arroz) {
            (P[j] as Map)['arroz'] = 1;
          } else {
            (P[j] as Map)['hab'] = 1;
          }
          SFX.blip();
        }
      }
      ab['lleva'] = null;
      ab['dir'] = 1;
      for (final f in W['fuegos'] as List) {
        final m = f as Map<String, dynamic>;
        m['n'] = 0;
        m['con'] = 'vacia';
        m['llama'] = 0;
      }
      await wait(300);
    },
    // the family looks in at the window; Carmen hands the plates out, and they eat there
    'familia27': (o) async {
      W['ventana'] = <dynamic>['abuelo', 'mama', 'papa'];
      SFX.blip();
      await wait(500);
    },
    'ventana27': (o) async {
      final c = G('carmen')!;
      Future<void> run() async {
        await mueve('carmen', EN['platos']![0] - 18, AYUDA[1] + 10);
        c['lleva'] = 'plato';
        _der['platos'] = <dynamic>[];
        SFX.blip();
        await wait(300);
        c['lleva'] = null;
        W['ventanacome'] = 1;
        SFX.blip();
        await wait(1200);
        await mueve('carmen', AYUDA[0], AYUDA[1]);
        c['dir'] = 1;
      }

      return corre(o, run());
    },
    // the pots come off; Carmen fills three cups from the sack of rice and three from the jar of beans
    'otravez27': (o) async {
      W['ventana'] = <dynamic>[];
      W['ventanacome'] = 0;
      await ownActs['platos27']!(<String, dynamic>{'vuelve': 1});
      W['fuegos'] = <dynamic>[<String, dynamic>{}, <String, dynamic>{}];
      final c = G('carmen')!;
      await mueve('carmen', _p.at(231, 46), AYUDA[1] - 2);
      c['pose'] = 'wave0';
      await wait(300);
      W['estante'] = 0;
      _izq['llenando'] = 1;
      c['pose'] = 'idle';
      SFX.blip();
      await wait(400);
      for (final k in const ['saco', 'tazon']) {
        for (var i = 1; i <= 3; i++) {
          _izq[k] = i;
          SFX.blip();
          await wait(160);
        }
      }
      c['pose'] = 'wave0';
      await wait(250);
      _izq['llenando'] = 0;
      W['estante'] = 2;
      c['pose'] = 'idle';
      await mueve('carmen', AYUDA[0], AYUDA[1]);
      c['dir'] = 1;
      await wait(300);
    },
    // the plates are in their hands: Luis's is the left one, abuela's the middle one, Carmen's the right one. Whoever has a
    // short plate looks into it first (moves line 233: Carmen with her plate held up 2 px left)
    'final27': (o) async {
      Future<void> run() async {
        final D = _der, ids = const ['luis', 'abuela', 'carmen'];
        final pl = [...(D['platos'] as List)];
        bool lleno(Object? q) =>
            q is Map && jsTruthy(q['arroz']) && jsTruthy(q['hab']);
        D['platos'] = <dynamic>[];
        await Future.wait([
          mueve('luis', _p.at(233, 155), _p.at(233, 202)),
          mueve('carmen', _final27[0], _final27[1]),
        ]);
        G('luis')!['dir'] = 1;
        G('carmen')!['dir'] = -1;
        G('abuela')!['dir'] = -1;
        Map q(int j) => (j < pl.length ? pl[j] as Map? : null) ?? const {};
        for (var j = 0; j < ids.length; j++) {
          final id = ids[j], qj = q(j);
          G(id)!['alza'] = <String, dynamic>{
            'k': 'platoc',
            'v':
                '${jsTruthy(qj['arroz']) ? 'a' : ''}${jsTruthy(qj['hab']) ? 'h' : ''}',
            'e': 2,
            'dx': id == 'abuela' ? 16 : 4,
            'dy': id == 'abuela' ? 8 : 10,
          };
        }
        SFX.blip();
        await wait(pl.every(lleno) ? 300 : 1100);
        for (var j = 0; j < ids.length; j++) {
          final qj = q(j);
          if (jsTruthy(qj['arroz']) || jsTruthy(qj['hab'])) {
            G(ids[j])!['come'] = <String, dynamic>{
              'k': 'monton',
              'v': jsTruthy(qj['arroz']) ? 'arroz' : 'hab',
            };
          }
        }
        if (!jsTruthy(W['lost'])) {
          D['platito'] = 0;
          final cosas = W['cosas'] as List;
          cosas.add(<String, dynamic>{
            'k': 'platito',
            'x': cx() - 24,
            'y': pies() + 4,
          });
          cosas.add(<String, dynamic>{
            'k': 'monton',
            'v': 'arroz',
            'x': cx() - 26,
            'y': pies() + 2,
          });
          cosas.add(<String, dynamic>{
            'k': 'monton',
            'v': 'hab',
            'x': cx() - 21,
            'y': pies() + 3,
          });
          _cq['hace'] = 'come';
          SFX.blip();
        }
        await wait(1500);
        for (final id in ids) {
          G(id)!['come'] = null;
        }
      }

      return corre(o, run());
    },

    /* ----- story 28: El pollo y el huevo ----- */
    // Abuela and the wide pan are on the left, with the tray; mamá and the baby stand beside her. Luis and Carmen eat at the
    // right counter. Pieces are fried two at a time, a drumstick and an egg. The shaker stands on the edge of the stove.
    'inicio28': (o) async {
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{'x': LADO[0][0], 'y': LADO[0][1], 'dir': 1},
        'mama': <String, dynamic>{'vis': 0, 'bebe': 1},
        'luis': <String, dynamic>{'vis': 0},
        'carmen': <String, dynamic>{'vis': 0},
        'abuelo': <String, dynamic>{'vis': 0},
        'papa': <String, dynamic>{'vis': 0},
      };
      W['fuegos'] = <dynamic>[
        <String, dynamic>{
          'k': 'sarten',
          'llama': 1,
          'cosas': <dynamic>[
            <String, dynamic>{'k': 'muslo', 'v': 'crudo', 'sal': 0},
            <String, dynamic>{'k': 'frito', 'v': 'crudo', 'sal': 0},
          ],
        },
        <String, dynamic>{},
      ];
      W['izq'] = <String, dynamic>{
        'bandeja': <String, dynamic>{'pollo': 3, 'huevo': 3},
      };
      W['der'] = <String, dynamic>{
        'servidos': <dynamic>[
          <String, dynamic>{'de': 'luis', 'items': <dynamic>[]},
          <String, dynamic>{'de': 'carmen', 'items': <dynamic>[]},
        ],
      };
      W['mat'] = <String, dynamic>{
        'x': BANCO[0] + 30,
        'y': BANCO[1] + 24,
        'o': null,
      };
      W['plata'] = null;
      W['salero'] = 1;
      W['repisa'] = 1;
    },
    // the frog takes the shaker, or puts it back (moves line 243: the shaker from its place, SALY)
    'toma28': (o) async {
      Future<void> run() async {
        if (jsTruthy(o['deja'])) {
          W['encima'] = null;
          await vuela({'k': 'salero'}, cx(), pies() - 24, SALX, SALY, 5);
          W['salero'] = 1;
          SFX.blip();
          return;
        }
        W['salero'] = 0;
        await vuela({'k': 'salero'}, SALX, SALY, cx(), pies() - 24, 5);
        W['encima'] = <String, dynamic>{'k': 'salero'};
        SFX.blip();
      }

      return corre(o, run());
    },
    // the frog shakes salt over the drumstick or the egg in the pan (moves line 245: over the pan at burner 0)
    'sala': (o) async {
      final k = pz(o['k']), f = _fuego(0)!, cs = f['cosas'] as List;
      final j = cs.indexWhere((c) => (c as Map)['k'] == k),
          px = FX[0] + j * 12 - 6;
      Future<void> run() async {
        W['encima'] = null;
        await vuela({'k': 'salero'}, cx(), pies() - 24, px + 4, FYi(0) - 18, 5);
        await cae28(px, FYi(0) - 12);
        await cae28(px, FYi(0) - 12);
        final c = cs[j] as Map;
        c['sal'] = _n(c['sal']) + 1;
        W['encima'] = <String, dynamic>{'k': 'salero'};
      }

      return corre(o, run());
    },
    'entramama': (o) async {
      final m = G('mama')!;
      m['vis'] = 1;
      m['x'] = _p.at(246, 20);
      m['y'] = _p.at(246, 204);
      await mueve('mama', AYUDA[0] - 2, _p.at(246, 204));
      m['dir'] = 1;
    },
    // abuela turns to the baby; her back is to the pan
    'mira28': (o) async {
      final ab = G('abuela')!, m = G('mama')!;
      ab['dir'] = -1;
      m['bebe'] = 'clap';
      await wait(400);
    },
    'humo': (o) async {
      final k = pz(o['k']);
      final c = _find(_fuego(0)!['cosas'] as List, (c) => c['k'] == k)!;
      c['humo'] = 1;
      SFX.blip();
      await wait(400);
    },
    // she turns round: by now the smoke hangs over the whole pan. She turns the piece he called: golden if it was the one
    // that smoked, and then the smoke clears
    'voltea': (o) async {
      final ab = G('abuela')!, f = _fuego(0)!;
      final ks = o['k'] == 'los dos' ? const ['muslo', 'frito'] : [pz(o['k'])];
      final cs = f['cosas'] as List;
      if (jsTruthy(o['vuelta'])) {
        ab['dir'] = 1;
        G('mama')!['bebe'] = 1;
        if (cs.any((c) => jsTruthy((c as Map)['humo']))) {
          f['humo'] = 1;
          await wait(350);
        }
      }
      ab['lleva'] = 'espatula';
      for (final k in ks) {
        final c = _find(cs, (c) => c['k'] == k)!;
        await wait(250);
        if (c['v'] != 'negro') c['v'] = 'dorado';
        c['humo'] = 0;
        SFX.blip();
      }
      await wait(250);
      ab['lleva'] = null;
      if (!cs.any((c) => jsTruthy((c as Map)['humo']))) f['humo'] = 0;
    },
    'quema28': (o) async {
      final f = _fuego(0)!,
          c = _find(f['cosas'] as List, (c) => c['k'] == pz(o['k']))!,
          ab = G('abuela')!;
      await wait(500);
      ab['lleva'] = 'espatula';
      await wait(400);
      c['v'] = 'negro';
      c['humo'] = 0;
      f['humo'] = 0;
      SFX.bonk();
      await wait(300);
      ab['lleva'] = null;
      await wait(300);
    },
    // a new pair from the tray goes into the pan, and abuela shakes salt over the pan. sinsal: that piece got none, and
    // nobody can see it (moves lines 254, 255: from the tray, BJ, into the pan at burner 0)
    'par': (o) async {
      final t = _izq['bandeja'] as Map, f = _fuego(0)!, ab = G('abuela')!;
      ab['dir'] = 1;
      G('mama')!['bebe'] = 1;
      f['cosas'] = <dynamic>[];
      t['pollo'] = _num(t['pollo']) - 1;
      await vuela(
        {'k': 'muslo', 'v': 'crudo'},
        _p.at(254, 40),
        BJ - 7,
        FX[0] - 6,
        FYi(0) - 6,
        5,
      );
      (f['cosas'] as List).add(<String, dynamic>{
        'k': 'muslo',
        'v': 'crudo',
        'sal': 0,
      });
      SFX.blip();
      t['huevo'] = _num(t['huevo']) - 1;
      await vuela(
        {'k': 'huevo'},
        _p.at(254, 60),
        BJ - 7,
        FX[0] + 6,
        FYi(0) - 6,
        5,
      );
      (f['cosas'] as List).add(<String, dynamic>{
        'k': 'frito',
        'v': 'crudo',
        'sal': 0,
      });
      SFX.blip();
      await wait(250);
      W['salero'] = 0;
      await vuela({'k': 'salero'}, SALX, SALY, FX[0], FYi(0) - 18, 4);
      await cae28(FX[0] - 4, FYi(0) - 12);
      for (final c in f['cosas'] as List) {
        final m = c as Map;
        m['sal'] = jsTruthy(o['sinsal']) && pz(o['sinsal']) == m['k'] ? 0 : 1;
      }
      await vuela({'k': 'salero'}, FX[0], FYi(0) - 18, SALX, SALY, 4);
      W['salero'] = 1;
      await wait(200);
    },
    // the pair goes onto somebody's plate at the right counter; he eats what is good and leaves what is black or too salty
    // (moves line 257: from the pan to the plate, SVY)
    'sirve28': (o) async {
      final f = _fuego(0)!;
      final its = [
        for (final c in f['cosas'] as List)
          <String, dynamic>{'k': (c as Map)['k'], 'v': c['v'], 'sal': c['sal']},
      ];
      final sv = _der['servidos'] as List;
      final i = sv.indexWhere((s) => (s as Map)['de'] == o['a']);
      f['cosas'] = <dynamic>[];
      await vuela({'k': 'plato'}, FX[0], FYi(0) - 8, SVX(i), SVY(i) - 4, 7);
      (sv[i] as Map)['items'] = its;
      SFX.blip();
      await wait(250);
    },
    'come28': (o) async {
      final p = G(o['a'] as String)!;
      final pl = _find(_der['servidos'] as List, (s) => s['de'] == o['a']);
      if (pl == null) return;
      final items = pl['items'] as List;
      for (final it0 in [...items]) {
        final it = it0 as Map;
        if (it['v'] == 'negro' ||
            (it['sal'] is num && (it['sal'] as num) >= 2)) {
          continue;
        }
        p['come'] = <String, dynamic>{'k': it['k'], 'v': it['v']};
        items.remove(it);
        SFX.blip();
        await wait(600);
        p['come'] = null;
      }
      await wait(200);
    },
    'muerde': (o) async {
      final p = G(o['a'] as String)!;
      for (final k in const ['muslo', 'frito']) {
        p['come'] = <String, dynamic>{'k': k, 'v': 'dorado'};
        await wait(350);
        p['come'] = null;
        await wait(150);
      }
    },
    // the frog salts a piece on somebody's plate: a second helping is a white heap (moves line 261: the shaker from its
    // place to the plate, SVY)
    'salplato': (o) async {
      final k = pz(o['k']), sv = _der['servidos'] as List;
      final i = sv.indexWhere((s) => (s as Map)['de'] == o['a']);
      final items = (sv[i] as Map)['items'] as List;
      final it = _find(items, (c) => c['k'] == k)!;
      final j = items.indexOf(it), px = SVX(i) - 6 + j * 12;
      if (jsTruthy(W['salero'])) {
        W['salero'] = 0;
        await vuela({'k': 'salero'}, SALX, SALY, cx(), pies() - 24, 5);
      }
      W['encima'] = null;
      await vuela({'k': 'salero'}, cx(), pies() - 24, px + 4, SVY(i) - 16, 9);
      await cae28(px, SVY(i) - 8);
      await cae28(px, SVY(i) - 8);
      it['sal'] = _n(it['sal']) + 1;
      await vuela({'k': 'salero'}, px + 4, SVY(i) - 16, SALX, SALY, 8);
      W['salero'] = 1;
    },
    'cara': (o) async {
      final p = G(o['a'] as String)!;
      final pl = _find(_der['servidos'] as List, (s) => s['de'] == o['a']);
      final it = pl == null
          ? null
          : _find(
              pl['items'] as List,
              (c) =>
                  (c['sal'] is num && (c['sal'] as num) >= 2) ||
                  c['v'] == 'negro',
            );
      if (it == null) return;
      await wait(300);
      p['pose'] = 'wave0';
      p['dy'] = -2;
      SFX.bonk();
      await wait(500);
      it['aparte'] = 1;
      await wait(500);
      p['pose'] = 'idle';
      p['dy'] = 0;
    },
    'piensa28': (o) async {
      final k = pz(o['k']),
          p = o['quien'] == 'bebe' ? G('mama')! : G(o['quien'] as String)!;
      p['piensa'] = jsTruthy(o['k'])
          ? <String, dynamic>{
              'k': k,
              'v': 'dorado',
              'sal': o['quien'] != 'bebe',
              'dx': o['quien'] == 'bebe' ? 12 : 0,
            }
          : null;
      if (jsTruthy(o['k'])) SFX.blip();
      await wait(250);
    },
    // Luis and Carmen run in to the right counter
    'entran28': (o) async {
      const ids = ['luis', 'carmen'];
      for (var j = 0; j < ids.length; j++) {
        final p = G(ids[j])!;
        p['vis'] = 1;
        p['x'] = _p.at(265, 236);
        p['y'] = _p.at(265, 198) + j * 8;
      }
      await Future.wait([
        mueve('luis', _p.at(265, 178), _p.at(265, 198)),
        mueve('carmen', _p.at(265, 199), _p.at(265, 206)),
      ]);
      G('luis')!['dir'] = -1;
      G('carmen')!['dir'] = -1;
    },
    // abuela holds both pieces out on a plate; the baby waves its arms at it
    'platobebe': (o) async {
      final f = _fuego(0)!, ab = G('abuela')!;
      ab['dir'] = 1;
      W['repisa'] = 0;
      ab['pose'] = 'offer';
      W['plata'] = <String, dynamic>{
        'x': _p.at(267, 94),
        'y': _p.at(267, 181),
        'items': <dynamic>[
          for (final c in f['cosas'] as List)
            <String, dynamic>{
              'k': (c as Map)['k'],
              'v': c['v'],
              'sal': c['sal'],
            },
        ],
      };
      f['cosas'] = <dynamic>[];
      G('mama')!['bebe'] = 'clap';
      SFX.blip();
      await wait(400);
    },
    // the frog takes a piece from that plate to the baby: it eats it, or throws it on the floor
    'dabebe': (o) async {
      final k = pz(o['k']), P = W['plata'] as Map, m = G('mama')!;
      final items = P['items'] as List;
      final it = _find(items, (c) => c['k'] == k);
      if (it == null) return;
      items.remove(it);
      await vuela(
        {'k': it['k'], 'v': it['v']},
        P['x'] as num,
        (P['y'] as num) - 8,
        (m['x'] as num) + 12,
        (m['y'] as num) - 36,
        7,
      );
      if (jsTruthy(o['tira'])) {
        m['bebe'] = 'llora';
        SFX.bonk();
        await vuela(
          {'k': it['k'], 'v': it['v']},
          (m['x'] as num) + 12,
          (m['y'] as num) - 36,
          (m['x'] as num) + 28,
          (m['y'] as num) + 6,
          6,
        );
        (W['cosas'] as List).add(<String, dynamic>{
          'k': it['k'],
          'v': it['v'],
          'x': (m['x'] as num) + 28,
          'y': (m['y'] as num) + 6,
        });
        await wait(500);
        m['bebe'] = 'clap';
        return;
      }
      m['bebe'] = 'come';
      SFX.blip();
      await wait(800);
      m['bebe'] = items.isNotEmpty ? 'clap' : 1;
    },
    'madrecome': (o) async {
      final m = G('mama')!;
      W['plata'] = null;
      W['repisa'] = 1;
      G('abuela')!['pose'] = 'idle';
      m['bebe'] = 1;
      await wait(300);
    },
    // the tray is empty: she tips it towards us
    'vacia28': (o) async {
      final ab = G('abuela')!;
      ab['dir'] = 1;
      (_izq['bandeja'] as Map)['volcada'] = 1;
      SFX.blip();
      await wait(500);
    },
    'ultimo': (o) async {
      await ownActs['voltea']!(<String, dynamic>{'k': 'los dos'});
      await ownActs['platobebe']!(<String, dynamic>{});
    },
    // the other piece of the last pair is the frog's
    'parami': (o) async {
      final P = W['plata'] as Map;
      Future<void> run() async {
        final items = P['items'] as List;
        final it = items.isNotEmpty ? items[0] as Map? : null;
        if (it != null) {
          P['items'] = <dynamic>[];
          final mat = W['mat'] as Map;
          await vuela(
            {'k': it['k'], 'v': it['v']},
            P['x'] as num,
            (P['y'] as num) - 8,
            mat['x'] as num,
            (mat['y'] as num) - 4,
            6,
          );
          mat['o'] = it;
          SFX.blip();
        }
        W['plata'] = null;
        W['repisa'] = 1;
        G('abuela')!['pose'] = 'idle';
        await wait(300);
      }

      return corre(o, run());
    },
    'final28': (o) async {
      W['plata'] = null;
      W['repisa'] = 1;
      G('abuela')!['pose'] = 'idle';
      G('mama')!['bebe'] = 'come';
      G('abuela')!['dir'] = 1;
      W['encima'] = null;
      if (!jsTruthy(W['lost']) && jsTruthy((W['mat'] as Map)['o'])) {
        _cq['hace'] = 'come';
      }
      SFX.blip();
      await wait(600);
    },

    /* ----- story 29: ¡Cuidado! ----- */
    // Abuela, the pan, the board of batter and the fritter plate are on the left; Luis, the pot of hot chocolate, the jug
    // of cold chocolate and the cups are on the right, where people come in (moves line 282: Luis 10 px left, 6 rows back)
    'inicio29': (o) async {
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{'x': LADO[0][0], 'y': LADO[0][1], 'dir': 1},
        'luis': <String, dynamic>{
          'x': LADO[1][0] - _luis29[0],
          'y': LADO[1][1] - _luis29[1],
          'dir': 1,
        },
        'carmen': <String, dynamic>{'vis': 0},
        'abuelo': <String, dynamic>{'vis': 0},
        'mama': <String, dynamic>{'vis': 0},
        'papa': <String, dynamic>{'vis': 0},
      };
      W['fuegos'] = <dynamic>[
        <String, dynamic>{'k': 'sarten', 'llama': 1, 'cosas': <dynamic>[]},
        <String, dynamic>{
          'k': 'olla',
          'con': 'choco',
          'n': 2,
          'llama': 1,
          'vapor': 1,
        },
      ];
      W['izq'] = <String, dynamic>{'jarra': 1, 'tazas': 9, 'sucias': 0};
      W['der'] = <String, dynamic>{
        'masa': 4,
        'fuente': 1,
        'frituras': <dynamic>[],
      };
      W['cubo'] = 1;
      W['basura'] = <dynamic>[];
    },
    // somebody comes in at the door and stands at the right; lugar 2: a second one beside him (moves line 285: 15 px left
    // and 2 rows further back, the second one beside the first)
    'viene': (o) async {
      final p = G(o['quien'] as String)!;
      final dos = o['lugar'] == 2 || o['lugar'] == '2';
      final x = dos ? _viene[0] : _viene[1], y = dos ? _viene[2] : _viene[3];
      p['bebe'] = null;
      p['piensa'] = null;
      p['pdx'] = dos ? 5 : 4;
      p['vis'] = 1;
      p['x'] = _p.at(285, 236);
      p['y'] = y;
      Future<void> run() async {
        await mueve(o['quien'] as String, x, y);
        p['dir'] = -1;
      }

      return corre(o, run());
    },
    // whoever has his cup goes out with it
    'aparte': (o) async {
      for (final id in '${o['quien']}'.split(',')) {
        final p = G(id)!;
        p['piensa'] = null;
        await wait(300);
        await mueve(id, _p.at(287, 238), p['y'] as num);
        p['vis'] = 0;
        p['bebe'] = null;
      }
    },
    'piensa': (o) async {
      G(o['quien'] as String)!['piensa'] = jsTruthy(o['k']) ? o['k'] : null;
      if (jsTruthy(o['k'])) SFX.blip();
      await wait(250);
    },
    // Luis gives the frog a clean cup; the frog fills it at the pot or at the jug and carries it over
    'copa': (o) async {
      final l = G('luis')!;
      if (jsTruthy(_izq['tazas'])) _dec(_izq, 'tazas');
      l['lleva'] = <String, dynamic>{'k': 'taza'};
      SFX.blip();
      await wait(250);
      l['lleva'] = null;
      await vuela(
        {'k': 'taza'},
        (l['x'] as num) + 8,
        (l['y'] as num) - 24,
        cx(),
        pies() - 24,
        5,
      );
      W['encima'] = <String, dynamic>{'k': 'taza'};
    },
    // (moves line 291: the ladle in the pot at burner 1)
    'ranallena': (o) async {
      final k = const ['olla1', 'cal', 'di_cal'].contains(o['k'])
              ? 'cal'
              : 'frio',
          p = G(o['a'] as String)!;
      Future<void> run() async {
        if (!jsTruthy(W['encima'])) {
          await ownActs['copa']!(<String, dynamic>{});
        }
        if (k == 'cal') {
          await ranaA(FX[1], _p.at(291, 192));
          final cu = <String, dynamic>{
            'k': 'cucharon',
            'x': FX[1] + 9,
            'y': FYi(1) - 5,
            'z': 999,
          };
          final cosas = W['cosas'] as List;
          cosas.add(cu);
          await wait(450);
          cosas.remove(cu);
        } else {
          await ranaA(EN['jarra']![0] - 4, _p.at(291, 192));
          await wait(150);
        }
        W['encima'] = <String, dynamic>{'k': 'taza', 'v': k};
        SFX.blip();
        await wait(250);
        await ranaA((p['x'] as num) - 22, (p['y'] as num) + 8);
        await wait(100);
        W['encima'] = null;
        p['bebe'] = k;
        SFX.blip();
        await wait(200);
        await alBanco();
      }

      return corre(o, run());
    },
    // Luis fills a clean cup himself, and hands it over
    'llena': (o) async {
      final l = G('luis')!,
          k = const ['olla1', 'cal', 'di_cal'].contains(o['k'])
              ? 'cal'
              : 'frio';
      if (jsTruthy(_izq['tazas'])) _dec(_izq, 'tazas');
      l['lleva'] = <String, dynamic>{'k': 'taza', 'v': k};
      SFX.blip();
      await wait(350);
      V['taza'] = k;
    },
    // (moves line 294: where Luis goes back to)
    'luisda': (o) async {
      final l = G('luis')!, p = G(o['a'] as String)!, k = V['taza'];
      Future<void> run() async {
        await mueve('luis', (p['x'] as num) - 20, (p['y'] as num) + 2);
        await wait(100);
        l['lleva'] = null;
        p['bebe'] = k;
        SFX.blip();
        await wait(200);
        if (!jsTruthy(o['queda'])) {
          await mueve('luis', LADO[1][0] - _luis29[0], LADO[1][1] - _luis29[1]);
          l['dir'] = 1;
        }
      }

      return corre(o, run());
    },
    // the cup is not the one he wanted: he shakes his head; Luis takes it, drinks it himself, and lays the empty cup on its
    // side
    'niega': (o) async {
      final p = G(o['a'] as String)!;
      for (final d in const [1, -1, 1, -1]) {
        p['dir'] = d;
        await wait(170);
      }
    },
    // (moves line 297: where Luis goes back to)
    'luisbebe': (o) async {
      final l = G('luis')!, p = G(o['a'] as String)!, k = p['bebe'];
      final dx = (l['x'] as num) - (p['x'] as num),
          dy = (l['y'] as num) - (p['y'] as num);
      if (math.sqrt(dx * dx + dy * dy) > 30) {
        await mueve('luis', (p['x'] as num) - 20, (p['y'] as num) + 2);
      }
      p['bebe'] = null;
      l['bebe'] = k;
      SFX.blip();
      await wait(900);
      l['bebe'] = null;
      l['dir'] = -1;
      await vuela(
        {'k': 'taza'},
        (l['x'] as num) - 6,
        (l['y'] as num) - 26,
        CUBO[0],
        CUBO[1] - 14,
        10,
      );
      _basura.add('taza');
      _izq['sucias'] = _n(_izq['sucias']) + 1;
      SFX.bonk();
      await mueve('luis', LADO[1][0] - _luis29[0], LADO[1][1] - _luis29[1]);
      l['dir'] = 1;
      await wait(300);
    },
    // abuela drops a ball of batter into the pan; the oil bubbles over it, and it fries a moment; she looks in (moves line
    // 299: into the pan at burner 0)
    'frie': (o) async {
      final f = _fuego(0)!, ab = G('abuela')!;
      ab['dir'] = 1;
      if (_num(_der['masa']) > 0) _dec(_der, 'masa');
      await vuela(
        {'k': 'fritura', 'v': 'cruda'},
        EN['masa']![0],
        EN['masa']![1] - 8,
        FX[0],
        FYi(0) - 8,
        5,
      );
      f['cosas'] = <dynamic>[
        <String, dynamic>{'k': 'fritura', 'v': 'cruda'},
      ];
      SFX.blip();
      await wait(350);
      ((f['cosas'] as List)[0] as Map)['v'] = 'burbujas';
      await wait(600);
    },
    'asoma': (o) async {
      final ab = G('abuela')!;
      ab['dir'] = 1;
      ab['paso'] = 1;
      await wait(450);
      ab['paso'] = 0;
      await wait(150);
    },
    // she turns away to wipe the plate, her back to the pan
    'limpia': (o) async {
      G('abuela')!['dir'] = -1;
      await wait(300);
    },
    'dora': (o) async {
      await wait(700);
    },
    // the frog lifts the fritter out, golden, onto the plate; or, too soon, it is pale and soft and falls on the floor
    // beside the stove (line 306 keeps the old FY and PISO; moves line 307: from the pan at burner 0)
    'saca29': (o) async {
      final f = _fuego(0)!;
      _cq['dy'] = -4;
      await wait(120);
      _cq['dy'] = 0;
      f['cosas'] = <dynamic>[];
      if (jsTruthy(o['cae'])) {
        await vuela(
          {'k': 'fritura', 'v': 'cruda'},
          FX[0],
          FY - 10,
          FX[0] - 4,
          PISO + 34,
          7,
        );
        (W['cosas'] as List).add(<String, dynamic>{
          'id': 'caida',
          'k': 'fritura',
          'v': 'cruda',
          'x': FX[0] - 4,
          'y': PISO + 34,
        });
        SFX.bonk();
        await wait(400);
        return;
      }
      await vuela(
        {'k': 'fritura', 'v': 'dorada'},
        FX[0],
        FYi(0) - 10,
        EN['fuente']![0],
        EN['fuente']![1] - 6,
        6,
      );
      (_der['frituras'] as List).add('dorada');
      SFX.blip();
      await wait(250);
    },
    // too long: smoke; abuela turns round and lifts a black fritter out onto the edge of the stove
    'quema29': (o) async {
      final f = _fuego(0)!, ab = G('abuela')!;
      await wait(500);
      f['humo'] = 1;
      SFX.bonk();
      await wait(600);
      ab['dir'] = 1;
      await wait(300);
      f['humo'] = 0;
      f['cosas'] = <dynamic>[];
      ab['lleva'] = <String, dynamic>{'k': 'fritura', 'v': 'negra'};
      await wait(500);
      ab['lleva'] = null;
      await vuela(
        {'k': 'fritura', 'v': 'negra'},
        ab['x'] as num,
        (ab['y'] as num) - 20,
        CUBO[0],
        CUBO[1] - 14,
        8,
      );
      _basura.add('negra');
      SFX.bonk();
      await wait(300);
    },
    'resto29': (o) async {
      G('abuela')!['dir'] = 1;
      while (_num(_der['masa']) > 0) {
        await ownActs['frie']!(<String, dynamic>{});
        await ownActs['saca29']!(<String, dynamic>{});
      }
    },
    // the turn: Luis crosses to the plate, takes the first fritter and eats it (moves line 312: where Luis goes back to)
    'luiscome': (o) async {
      final l = G('luis')!;
      await mueve('luis', EN['fuente']![0] + 18, LADO[0][1] + 16);
      final fr0 = _der['frituras'] as List;
      if (fr0.isNotEmpty) fr0.removeLast();
      l['come'] = <String, dynamic>{'k': 'fritura', 'v': 'dorada'};
      SFX.blip();
      await wait(800);
      l['come'] = null;
      SFX.blip();
      await wait(300);
      await mueve('luis', LADO[1][0] - _luis29[0], LADO[1][1] - _luis29[1]);
      l['dir'] = 1;
    },
    // the ending: Carmen and abuela take a fritter each; the third, if there is one, is the frog's. A clean cup for abuela,
    // and one for the frog, as far as they go
    'final29': (o) async {
      final ab = G('abuela')!, ca = G('carmen')!, D = _der;
      ab['dir'] = 1;
      final fr0 = D['frituras'] as List;
      if (fr0.isNotEmpty) {
        fr0.removeLast();
        ca['come'] = <String, dynamic>{'k': 'fritura', 'v': 'dorada'};
        SFX.blip();
        await wait(250);
      }
      if (fr0.isNotEmpty) {
        fr0.removeLast();
        ab['lleva'] = <String, dynamic>{'k': 'fritura', 'v': 'dorada'};
        SFX.blip();
        await wait(250);
      }
      if (fr0.isNotEmpty) {
        fr0.removeLast();
        W['mat'] = <String, dynamic>{
          'x': cx() - 26,
          'y': pies() + 6,
          'o': <String, dynamic>{'k': 'fritura', 'v': 'dorada'},
          'dx': -4,
        };
        _cq['hace'] = 'come';
        SFX.blip();
        await wait(250);
      }
      if (_num(_izq['tazas']) > 0) {
        _dec(_izq, 'tazas');
        ab['bebe'] = 'cal';
        SFX.blip();
        await wait(250);
      }
      if (_num(_izq['tazas']) > 0) {
        _dec(_izq, 'tazas');
        if (!jsTruthy(W['mat'])) {
          W['mat'] = <String, dynamic>{'x': cx() - 26, 'y': pies() + 6};
        }
        (W['mat'] as Map)['taza'] = 'cal';
        SFX.blip();
      }
      await wait(700);
    },

    // everything at once, to look at the drawing
    'prueba': (o) async {
      final n = _plus(jsTruthy(o['n']) ? o['n'] : 1);
      W['gente'] = <String, dynamic>{
        'abuela': <String, dynamic>{
          'x': LADO[1][0],
          'y': LADO[1][1],
          'dir': -1,
        },
        'luis': <String, dynamic>{'x': LADO[0][0], 'y': LADO[0][1], 'dir': 1},
        'carmen': <String, dynamic>{
          'x': AYUDA[0],
          'y': AYUDA[1],
          'dir': 1,
          'lleva': <String, dynamic>{'k': 'medida', 'v': 'arroz'},
        },
        'papa': <String, dynamic>{
          'x': PUERTA[0],
          'y': PUERTA[1] + 6,
          'dir': -1,
          'vis': n == 2 ? 1 : 0,
        },
      };
      W['fuegos'] = n == 1
          ? <dynamic>[
              <String, dynamic>{
                'k': 'olla',
                'con': 'arroz',
                'n': 2,
                'llama': 1,
                'vapor': 1,
              },
              <String, dynamic>{
                'k': 'olla',
                'con': 'hab',
                'n': 1,
                'llama': 1,
                'humo': 1,
                'negra': 1,
              },
            ]
          : n == 2
          ? <dynamic>[
              <String, dynamic>{
                'k': 'olla',
                'con': 'agua',
                'n': 0,
                'llama': 1,
                'vapor': 1,
              },
              <String, dynamic>{
                'k': 'olla',
                'con': 'vacia',
                'n': 0,
                'llama': 0,
              },
            ]
          : <dynamic>[
              <String, dynamic>{
                'k': 'sarten',
                'llama': 1,
                'cosas': <dynamic>[],
              },
              <String, dynamic>{
                'k': 'olla',
                'con': 'choco',
                'n': 2,
                'llama': 1,
                'vapor': 1,
              },
            ];
      W['izq'] = n == 3
          ? <String, dynamic>{'jarra': 1, 'tazas': 9, 'sucias': 2}
          : <String, dynamic>{'saco': 3, 'tazon': 2};
      W['ventana'] = n == 2 ? <dynamic>['abuelo', 'mama', 'papa'] : <dynamic>[];
      W['ventanacome'] = 1;
      W['der'] = <String, dynamic>{
        'platos': n == 1
            ? <dynamic>[
                <String, dynamic>{'arroz': 1, 'hab': 1},
                <String, dynamic>{'arroz': 1},
                <String, dynamic>{},
              ]
            : <dynamic>[
                <String, dynamic>{},
                <String, dynamic>{},
                <String, dynamic>{},
              ],
        'pila': 3,
        'platito': 1,
        'masa': n == 3 ? 3 : null,
        'fuente': n == 3 ? 1 : 0,
        'frituras': n == 3 ? <dynamic>['dorada', 'dorada'] : <dynamic>[],
      };
      W['basura'] = n == 1 ? <dynamic>['hab', 'arroz'] : <dynamic>[];
      W['cubo'] = 1;
      W['banco'] = 1;
      _cq.addAll({'x': BANCO[0] - 16, 'y': BANCO[1] - 27, 's': 1});
      W['encima'] = n == 2
          ? <String, dynamic>{'k': 'medida', 'v': 'hab'}
          : null;
      W['tarjeta'] = 'rondas';
      W['marcas'] = <dynamic>['ok', 'x', null];
    },
  };

  // estufa.js: stake
  @override
  Future<void> stake(int lost, int max, String en) async {
    await wait(200);
  }

  // estufa.js: poke (nothing)
  @override
  dynamic poke(String what) => null;

  // estufa.js: estado
  @override
  String estado(Map<String, dynamic> W) {
    final g = (W['gente'] as Map<String, dynamic>?) ?? const {};
    final gente = [
      for (final k in g.keys)
        if ((g[k] as Map)['vis'] != 0)
          () {
            final p = g[k] as Map<String, dynamic>;
            return '$k@${jsNum(_roundN(_num(p['x'])))},${jsNum(_roundN(_num(p['y'])))}';
          }(),
    ].join(' ');
    final fuegos = [
      for (final f0 in (W['fuegos'] as List?) ?? const [])
        () {
          final f = f0 as Map<String, dynamic>?;
          if (f == null || !jsTruthy(f['k'])) return '-';
          return '${f['k']}:${jsTruthy(f['con']) ? f['con'] : ''}${_jsField(f, 'n')}'
              '${jsTruthy(f['llama']) ? '*' : ''}${jsTruthy(f['negra']) ? '#' : ''}';
        }(),
    ].join('|');
    final basura = ((W['basura'] as List?) ?? const [])
        .map((m) => m == null ? '' : _js(m))
        .join('+');
    final marcas = ((W['marcas'] as List?) ?? const [])
        .map((m) => m == null ? '' : _js(m))
        .join(',');
    return 'gente=$gente fuegos=$fuegos basura=$basura marcas=$marcas';
  }

  // estufa.js: fresh (moves line 331: where the answer cards stand, respEn)
  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {
    'respEn': <num>[_respEn[0], _respEn[1]],
    'estante': 0,
    'repisa': 0,
    'olor': null,
    'mat': null,
    'plata': null,
    'cubo': 0,
    'salero': 0,
    'gente': <String, dynamic>{},
    'fuegos': <dynamic>[<String, dynamic>{}, <String, dynamic>{}],
    'izq': <String, dynamic>{},
    'der': <String, dynamic>{},
    'basura': <dynamic>[],
    'ventana': <dynamic>[],
    'ventanacome': 0,
    'cola': <dynamic>[],
    'cosas': <dynamic>[],
    'vuelos': <dynamic>[],
    'banco': 1,
    'encima': null,
    'tarjeta': null,
    'marcas': null,
    'cq': <String, dynamic>{
      'x': BANCO[0] - 16,
      'y': BANCO[1] - 27,
      's': 1,
      'dy': 0,
      'al': 1,
      'vis': 1,
      'bub': null,
      'hace': null,
    },
  };

  // remap is not in the old file. Page 12, section 5: every position a story, pair or level file holds goes through
  // the sheet's remap table. A point keeps its screen place (the sheet's `new`; the few the sheet moved: the pairs' cups
  // and pots on the stove, mamá at the stove, abuela in cuidado.si, abuela's plate in pollo); the frog out of a picture is
  // no place (`to.none`) and is given back; a pair rectangle gives the crop of the pictures it was; a level picture's
  // rectangle gives itself back (the level pictures are the sheet's, whole).
  @override
  List<num> remap(List<num> xy) {
    switch (xy.length) {
      case 2:
        final r = sheet.remapPoint(xy[0], xy[1]);
        if (r.now != null) return r.now!;
        final to = r.to;
        if (to.spot != null) return _p.spot(to.spot!);
        if (to.screen != null) return to.screen!;
        if (to.none != null) return xy;
        throw SheetError('the remap of $xy names no place');
      case 4:
        SheetRemap r;
        try {
          r = sheet.remapCam(xy);
        } on SheetError {
          r = sheet.remapCrop(xy);
        }
        final to = r.to;
        if (to.view != null) return sheet.viewOf(to.view!, _p.e);
        if (r.crop != null) return r.crop!;
        final crops = <String, List<int>>{
          for (final c
              in r.crops?.values ??
                  [
                    for (final n in to.pictures ?? const <String>[])
                      (
                        crop: sheet.pictures[n]!.crop,
                        zoom: sheet.pictures[n]!.zoom,
                      ),
                  ])
            '${c.zoom}:${c.crop.join(',')}': c.crop,
        };
        if (crops.length != 1) {
          throw SheetError(
            'the old rectangle $xy is ${to.pictures} in the sheet, which crops them differently: ask for a picture by its name',
          );
        }
        return crops.values.first;
      default:
        throw SheetError('a position is 2 or 4 numbers, not $xy');
    }
  }

  // estufa-preview.html: PV.remapW for a review picture's own W (the pair's file, cual-estufa): each person at a place of
  // a move (who and old) goes to its new one, else at a pair position the sheet moved to its new one (keeping the
  // fraction); each thing of `cosas` and `vuelos` at a moved pair position; the smell's curve (`olor`, a rect) to its
  // moved one. The top-level places (cq, plata, mat) are remapped by ScenePictures, as for every scene.
  @override
  void placePair(Map<String, dynamic> set) {
    final mv = [for (final m in sheet.moves) ...m.places];
    final rm = [
      for (final e in sheet.remapTable)
        if (e.moved &&
            e.kind == 'point' &&
            e.uses.any((u) => u.startsWith('cual-estufa.json')))
          e,
    ];
    List<num>? find(String who, num x, num y) {
      final rx = _round(x), ry = _round(y);
      for (final q in mv) {
        if (q.who == who && q.old[0] == rx && q.old[1] == ry) return q.now;
      }
      for (final e in rm) {
        if (e.old[0] == rx && e.old[1] == ry) return e.now;
      }
      return null;
    }

    final gente = set['gente'];
    if (gente is Map) {
      for (final en in gente.entries) {
        final p = en.value;
        if (p is! Map || p['x'] is! num) continue;
        final x = p['x'] as num, y = p['y'] as num;
        final m = find(en.key as String, x, y);
        if (m != null) {
          p['x'] = m[0] + (x - _round(x));
          p['y'] = m[1] + (y - _round(y));
        }
      }
    }
    for (final k in const ['cosas', 'vuelos']) {
      final l = set[k];
      if (l is! List) continue;
      for (final p in l) {
        if (p is! Map || p['x'] is! num) continue;
        final m = find('cosa', p['x'] as num, p['y'] as num);
        if (m != null) {
          p['x'] = m[0];
          p['y'] = m[1];
        }
      }
    }
    final olor = set['olor'];
    if (olor is List && olor.length == 4) {
      for (final e in sheet.remapTable) {
        if (e.moved &&
            e.kind == 'rect' &&
            e.old.join(',') == olor.join(',') &&
            e.now != null) {
          set['olor'] = [...e.now!];
          break;
        }
      }
    }
  }
}
