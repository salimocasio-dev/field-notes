// The scene-facing names are kept as in the old code (page 12, section 4).
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

import 'compare.dart';
import 'fixtures/ref_signs.dart';
import 'kit_scene.dart';

Uint8List _file(String name) {
  final pieces = refSignsFixture[name];
  if (pieces == null) throw StateError('$name is not in the signs reference');
  return base64Decode(pieces.join());
}

/// `"#RRGGBB"` as 0xFFBBGGRR.
int colour(String h) =>
    0xFF000000 |
    (int.parse(h.substring(5, 7), radix: 16) << 16) |
    (int.parse(h.substring(3, 5), radix: 16) << 8) |
    int.parse(h.substring(1, 3), radix: 16);

/// One case of tool/make_signs_ref.mjs: a call of an old function and the state it reads.
class SignCase {
  SignCase(this.json, this.background);

  final Map<String, dynamic> json;
  final String background;

  int get n => json['n'] as int;
  String get kind => json['kind'] as String;
  List<int>? get size =>
      (json['size'] as List<dynamic>?)?.map((v) => v as int).toList();
  List<dynamic> get args => json['args'] as List<dynamic>;
  Map<String, dynamic> get state => json['state'] as Map<String, dynamic>;
  Object? get value => json['value'];

  String get label =>
      '$n $kind(${jsonEncode(args)}) F=${state['F']} cam=${state['cam']}';
}

List<SignCase> loadSignCases() {
  final doc =
      jsonDecode(utf8.decode(_file('cases.json'))) as Map<String, dynamic>;
  return [
    for (final c in doc['cases'] as List<dynamic>)
      SignCase(c as Map<String, dynamic>, doc['background'] as String),
  ];
}

/// The picture Chrome drew.
Uint32List signReference(SignCase c) =>
    readU32(_file('px/${c.n.toString().padLeft(3, '0')}.bin'));

/// A baked set that is one flat picture: no ground, no tufts, no leaves.
BakedSet flatBaked(Uint32List pix, {Float32List? zb}) {
  final n = pix.length;
  return BakedSet(
    pix: pix,
    zb: zb ?? Float32List(n),
    ground: Uint8List(n),
    groundZ: Float32List(n),
    kinds: Uint8List(n),
    staticShadow: Uint8List(n),
  );
}

/// What the scene `E` of a case says (its boxes, its hand points, its heart, whether it draws inside a picture
/// answer): a [Scene] that answers from the case's tables.
class SignScene extends Scene {
  SignScene(Map<String, dynamic> e, this.SW, this.SH)
    : boxes = (e['box'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, [for (final n in v as List<dynamic>) n as num]),
      ),
      hands = (e['handAt'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, [for (final n in v as List<dynamic>) n as num]),
      ),
      heart = [for (final n in e['heartAt'] as List<dynamic>) n as num],
      icon = e['icon'] == true;

  final Map<String, List<num>> boxes, hands;
  final List<num> heart;
  final bool icon;

  @override
  final int SW, SH;
  @override
  String get id => 'signs';
  @override
  Map<String, List<num>> get CAM => {};
  @override
  List<num> get heartAt => heart;
  @override
  Map<String, List<num>> get lugar => {};
  @override
  List<Thing> get cosas => [];
  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {};
  @override
  String setKey(Map<String, dynamic> W) => 'signs';
  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) {}
  @override
  List<num> remap(List<num> xy) => xy;
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {}
  @override
  Map<String, Future<void> Function(Map<String, dynamic> o)> get acts => {};
  @override
  Future<void> stake(int lost, int max, String en) async {}
  @override
  List<num>? box(String k, Map<String, dynamic> W) => boxes[k];
  @override
  String? hit(num x, num y, Map<String, dynamic> W) => null;
  @override
  List<num>? handAt(String k) => hands[k];

  // the case's picture answer: a filled square (tool/make_signs_ref.mjs: `fr(g, x + 4, y + 4, w - 8, h - 8, "#C86A10")`)
  @override
  dynamic respIcon(Ctx c, String k, num x, num y, num w, num h, int a) {
    if (icon) fr(c, x + 4, y + 4, w - 8, h - 8, 0xFF106AC8);
  }
}

/// What a case gave: its picture (when it draws one) and its value (when it measures one).
class SignResult {
  SignResult(this.px, this.value);

  final Uint32List? px;
  final Object? value;
}

/// The state of a case as a host: W (a copy), cam, F, TALK.
TestHost signHost(SignCase c) {
  final st = c.state;
  final host = TestHost(
    W: copyJson((st['W'] as Map<String, dynamic>?) ?? {'fx': []}),
    cam: [for (final v in st['cam'] as List<dynamic>) v as num],
    F: st['F'] as int,
  )..TALK = st['TALK'] as String?;
  return host;
}

/// Makes the case's call on `Ctx`, the way the page made it on the old code.
SignResult replaySign(SignCase c) {
  final st = c.state;
  final host = signHost(c);
  final scene = SignScene(
    st['E'] as Map<String, dynamic>,
    st['SW'] as int,
    st['SH'] as int,
  );
  final signs = Signs(host: host, scene: scene);
  final a = c.args;
  final size = c.size;
  List<num> list(Object? v) => [for (final n in v as List<dynamic>) n as num];
  if (size == null) {
    switch (c.kind) {
      case 'frogBox':
        final b = frogBox(a[0] as Map<String, dynamic>);
        return SignResult(null, {'x': b.x, 'y': b.y, 'w': b.w, 'h': b.h});
      case 'respBox':
        return SignResult(null, signs.respBox(a[0] as String));
      case 'bx':
        return SignResult(null, signs.bx(a[0] as String));
    }
    throw StateError('no kind ${c.kind}');
  }
  final px = Uint32List(size[0] * size[1]);
  final g = Ctx(px, size[0], size[1]);
  g.fillStyle = colour(c.kind == 'handSign' ? '#0E1A24' : c.background);
  g.fillRect(0, 0, size[0], size[1]);
  Object? value;
  switch (c.kind) {
    case 'hand':
      hand(g, a[0] as num, a[1] as num, a[2] as bool, a[3] as num);
    case 'heart':
      heart(g, a[0] as num, a[1] as num, a[2] as num);
    case 'star':
      star(g, a[0] as num, a[1] as num, a[2] as num, a[3] as bool);
    case 'spot':
      spot(g, list(a[0]), a[1] as int, scene.SW, scene.SH);
    case 'twinkle':
      signs.twinkle(g, list(a[0]));
    case 'bub':
      signs.bub(g, a[0] as String, a[1] as num, a[2] as num, a[3] as int);
    case 'bang':
      bang(g, a[0] as num, a[1] as num, a[2] as num);
    case 'frog':
      signs.frog(g, copyJson(a[0] as Map<String, dynamic>), a[1] as int);
    case 'respDraw':
      signs.respDraw(g, a[0] as int);
    case 'drawAve':
      final v = copyJson(a[0] as Map<String, dynamic>);
      (Maqueta()..host = host).drawAve(g, v);
    case 'drawSigns':
      signs.drawSigns(g, host.F >> 1);
      value = {'fx': host.W['fx']};
    case 'handSign':
      // the frame draws the hand after cropping the view: a picture that is the display's own colour, a 1 x 1 hud
      final engine = PpEngine(w: 240, h: 216, s: 26);
      final baked = Uint32List(240 * 216)..fillRange(0, 240 * 216, 0xFF241A0E);
      drawFrame(
        engine: engine,
        baked: flatBaked(baked),
        scene: scene,
        W: host.W,
        F: host.F,
        tick: 70,
        cam: host.cam,
        shadows: const [],
        c: Ctx(engine.pix, 240, 216),
        display: px,
        dc: g,
        signs: (c, a) {},
        handPoint: signs.handPoint(),
      );
    default:
      throw StateError('no kind ${c.kind}');
  }
  return SignResult(px, value);
}
