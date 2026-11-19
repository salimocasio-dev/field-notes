// The scene's own names are kept as in the old code (page 12, section 4).
// ignore_for_file: non_constant_identifier_names

import 'dart:collection';

import 'package:coqui_pixel/coqui_pixel.dart';

/// A stand-in scene for tests and for the no-screen player: things at known boxes, acts that do what a test says, and a record of what the story
/// asked of it.
class StandInScene extends Escena {
  StandInScene({
    Map<String, Act>? acts,
    List<Thing>? things,
    Map<String, List<num>>? cam,
    Map<String, dynamic>? fresh,
    Map<String, List<num>>? talk,
    this.sceneId = 'prueba',
    bool lenient = true,
  }) : _acts = lenient ? _Lenient(acts ?? {}) : (acts ?? {}),
       _things =
           things ??
           [
             Thing(id: 'puerta', box: [150, 60, 30, 50]),
             Thing(id: 'ventana', box: [60, 60, 40, 30]),
             Thing(id: 'casa', box: [40, 20, 150, 100]),
             Thing(
               id: 'sol',
               box: [200, 10, 20, 20],
               si: (W) => W['storm'] != true,
             ),
           ],
       _cam =
           cam ??
           {
             'wide': [0, 0, 196, 216],
             'close': [10, 10, 98, 108],
             'side': [44, 0, 196, 216],
           },
       _fresh = fresh ?? {},
       _talk = talk ?? {};

  final String sceneId;
  final Map<String, Act> _acts;
  final List<Thing> _things;
  final Map<String, List<num>> _cam;
  final Map<String, dynamic> _fresh;
  final Map<String, List<num>> _talk;

  /// Every `stake` call: `[lost, max, en]`.
  final List<List<Object?>> stakes = [];

  /// Every `poke`: what was touched.
  final List<String> pokes = [];

  /// How many frames were drawn.
  int draws = 0;

  /// What a stake does besides noting the call (the thing at stake taking a step).
  Future<void> Function(int lost, int max, String en)? onStake;

  @override
  String get id => sceneId;

  @override
  Map<String, List<num>> get CAM => _cam;

  @override
  List<Thing> get cosas => _things;

  @override
  Map<String, List<num>> get lugar => {
    'puerta': [150, 120, 1],
    'centro': [100, 150, 1],
  };

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => Map.of(_fresh);

  @override
  String setKey(Map<String, dynamic> W) => 'k';

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) {}

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    draws++;
    host.frog(c, W['cq'] as Map<String, dynamic>, a);
  }

  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {}

  @override
  Map<String, Act> get acts => _acts;

  @override
  Future<void> stake(int lost, int max, String en) async {
    stakes.add([lost, max, en]);
    await onStake?.call(lost, max, en);
  }

  @override
  dynamic poke(String what) {
    pokes.add(what);
    return null;
  }

  @override
  List<num>? talkAt(String who, Map<String, dynamic> W) => _talk[who];
}

/// Acts that are not given do nothing, so a story can name any act.
class _Lenient extends MapBase<String, Act> {
  _Lenient(this._m);

  final Map<String, Act> _m;

  static Future<void> _noop(Map<String, dynamic> o) async {}

  @override
  Act? operator [](Object? key) => _m[key] ?? _noop;

  @override
  void operator []=(String key, Act value) => _m[key] = value;

  @override
  void clear() => _m.clear();

  @override
  Iterable<String> get keys => _m.keys;

  @override
  Act? remove(Object? key) => _m.remove(key);
}
