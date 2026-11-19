// The scene-facing names are kept as in the old code (page 12, section 4).
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:coqui_pixel/coqui_pixel.dart';

import 'rec_player.dart';

Map<String, dynamic> copyJson(Map<String, dynamic> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

/// The calls that reach the host, as the reference records them: `[name, args...]`.
typedef CallLog = List<List<Object?>>;

/// The names of `Sfx` the kit's acts call, recorded as `['SFX', name]`; the rest do what [Sfx] does, on a player.
class _RecSfx extends Sfx {
  _RecSfx(this.log) : super(RecPlayer());

  final CallLog log;

  @override
  void coqui() => log.add(['SFX', 'coqui']);
  @override
  void win() => log.add(['SFX', 'win']);
  @override
  void swoop() => log.add(['SFX', 'swoop']);
}

/// A [SceneHost] with what kit.js's acts and hit reach: W, cam, S, F, TICK, SFX, lib, frogBox, hopTo, bounce, fx, wait.
/// Every other member throws. Each call is logged the way tool/make_kit_ref.mjs logs the old stubs.
class TestHost implements SceneHost {
  TestHost({required this.W, List<num>? cam, this.F = 0})
    : cam = cam ?? [22, 0, 196, 216];

  final CallLog log = [];

  @override
  Map<String, dynamic> W;
  @override
  List<num> cam;
  @override
  int F;
  @override
  final Map<String, dynamic> S = {
    'stake': {'steps': 3},
  };
  @override
  int get TICK => 70;
  @override
  final SpriteLib lib = SpriteLib();
  @override
  Map<String, List<String>> BUBL = newBUBL();
  @override
  String? TALK;
  @override
  late final Sfx SFX = _RecSfx(log);

  @override
  ({num x, num y, num w, num h}) frogBox(Map<String, dynamic> q) =>
      frogBoxOf(q);

  @override
  Future<void> hopTo(num x, num y, int hops, [num? s1]) async =>
      log.add(['hopTo', x, y, hops, s1]);
  @override
  void bounce([num? h]) => log.add(['bounce', h]);
  @override
  void fx(Map<String, dynamic> e) => log.add(['fx', copyJson(e)]);
  @override
  Future<void> wait(num ms) async => log.add(['wait', ms]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('TestHost.${invocation.memberName}');
}

/// `frogBox` of coqui_pixel (the top-level function), under a name a host's own `frogBox` method does not hide.
({num x, num y, num w, num h}) frogBoxOf(Map<String, dynamic> q) => frogBox(q);

/// The made-up scene of tool/make_kit_ref.mjs, written again: keep the two the same. [own] gives it its own `ir` and an
/// `abre` act and a `heartAt`, as the first scene there has; without, it is the plain one.
class Maqueta extends Escena {
  Maqueta({this.own = false});

  final bool own;

  Future<void> ownIr(Map<String, dynamic> o) async {
    final a = o['a'];
    (host as TestHost).log.add(['own ir', a]);
  }

  @override
  String get id => own ? 'maqueta' : 'plana';
  @override
  Map<String, List<num>> get CAM => {
    'wide': [22, 0, 196, 216],
  };
  @override
  List<num> get heartAt => own ? [110, 30] : super.heartAt;
  @override
  Map<String, List<num>> get lugar => {
    'puerta': [165, 150, .9],
    'banco': [70, 150, 1],
    'origen': [150, 178, 1],
  };

  @override
  late final List<Thing> cosas = [
    Thing(id: 'cartel', box: [10, 20, 40, 30], z: true),
    Thing(
      id: 'arbol',
      box: (Map<String, dynamic> w) => [
        100.5,
        40 + ((w['dy'] as num?) ?? 0),
        30,
        70,
      ],
      m: 0,
    ),
    Thing(
      id: 'puerta',
      box: [150, 60, 30, 56],
      si: (w) => w['door'] != 2,
      hand: [165, 100],
    ),
    Thing(
      id: 'perilla',
      box: [160, 90, 8, 8],
      si: (w) => w['door'] == 1,
      z: true,
      m: 6,
      hand: (Map<String, dynamic> w) => [164, (w['door'] as num) * 10 + 80],
    ),
    Thing(id: 'banco', box: [40, 120, 60, 20], m: 5),
    Thing(id: 'suelo', box: [0, 150, 240, 66]),
    Thing(id: 'fuera', box: (Map<String, dynamic> w) => [300, 300, 10, 10]),
  ];

  @override
  Map<String, Act> get ownActs => own
      ? {
          'ir': ownIr,
          'abre': (o) async => (host as TestHost).log.add(['abre']),
        }
      : {};

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {};
  @override
  String setKey(Map<String, dynamic> W) => 'maqueta';
  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) {}
  @override
  List<num> remap(List<num> xy) => xy;
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {}
  @override
  Future<void> stake(int lost, int max, String en) async {}
}
