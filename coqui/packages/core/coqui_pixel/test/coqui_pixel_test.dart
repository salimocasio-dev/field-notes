// The scene-facing names are kept as in the old code (page 12, section 4).
// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

/// Records what reaches the audio layer, as [name, args...]. Lists, not strings: the web prints 1.0 as 1.
class _Rec implements ClipPlayer {
  final calls = <List<Object?>>[];
  @override
  bool muted = false;
  @override
  void tone(
    double hz, {
    double at = 0,
    double dur = .1,
    String wave = 'square',
    double vol = .05,
    double? toHz,
  }) => calls.add(['tone', hz, at, dur, wave, vol, toHz]);
  @override
  void noiseBurst({double vol = 1}) => calls.add(['noise', vol]);
  @override
  void loop(String name, bool on) => calls.add(['loop', name, on]);
  @override
  Future<void> unlock() async {}
  @override
  Future<void> preload(Iterable<String> clipIds) async {}
  @override
  Future<bool> play(String clipId, {Duration? limit}) async => true;
  @override
  Future<void> stop() async {}
}

class _Still extends Scene {
  @override
  String get id => 'still';
  @override
  int get SW => 240;
  @override
  int get SH => 216;
  @override
  Map<String, List<num>> get CAM => {
    'wide': [44, 0, 196, 216],
  };
  @override
  List<num> get heartAt => [120, 30];
  @override
  Map<String, List<num>> get lugar => {
    'puerta': [150, 178, 1],
  };
  @override
  List<Thing> get cosas => [
    Thing(id: 'puerta', box: [140, 60, 30, 50]),
  ];
  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) => {'door': 0};
  @override
  String setKey(Map<String, dynamic> W) => 'door=${W['door']}';
  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) {}
  @override
  List<num> remap(List<num> xy) => xy;
  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {}
  @override
  Map<String, Future<void> Function(Map<String, dynamic> o)> get acts => {
    'abre': (o) async {},
  };
  @override
  Future<void> stake(int lost, int max, String en) async {}
  @override
  List<num>? box(String k, Map<String, dynamic> W) =>
      k == 'puerta' ? [140, 60, 30, 50] : null;
  @override
  String? hit(num x, num y, Map<String, dynamic> W) => null;
  @override
  List<num>? handAt(String k) => null;
}

Matcher _unimplemented(String order) => throwsA(
  isA<UnimplementedError>().having((e) => e.message, 'message', order),
);

void main() {
  group('SFX', () {
    final rec = _Rec();
    final sfx = Sfx(rec);
    // name -> what juego.js's SFX.<name>() plays, in its own numbers
    final expected = <String, void Function()>{
      'right': sfx.right,
      'toc': sfx.toc,
      'blip': sfx.blip,
      'creak': sfx.creak,
      'hop': sfx.hop,
      'coqui': sfx.coqui,
      'win': sfx.win,
      'luz': sfx.luz,
      'drop': sfx.drop,
      'trueno': sfx.trueno,
      'lluvia': sfx.lluvia,
      'calla': sfx.calla,
      'suave': sfx.suave,
      'pio': sfx.pio,
      'slam': sfx.slam,
      'bonk': sfx.bonk,
      'munch': sfx.munch,
      'swoop': sfx.swoop,
    };
    test(
      'has the 18 names juego.js defines',
      () => expect(expected, hasLength(18)),
    );
    test('every name reaches the audio layer', () {
      for (final e in expected.entries) {
        rec.calls.clear();
        e.value();
        expect(rec.calls, isNotEmpty, reason: e.key);
      }
    });
    test('with today\'s numbers', () {
      rec.calls.clear();
      sfx.right();
      sfx.hop();
      sfx.trueno();
      sfx.trueno(.6);
      sfx.lluvia();
      sfx.calla();
      expect(rec.calls, [
        ['tone', 784, 0, .1, 'triangle', .14, null],
        ['tone', 1047, .09, .1, 'triangle', .14, null],
        ['tone', 1319, .18, .26, 'triangle', .14, null],
        ['tone', 320, 0, .07, 'square', .025, 520],
        ['noise', 1],
        ['noise', .6],
        ['loop', 'rain', true],
        ['loop', 'rain', false],
      ]);
    });
  });

  group('shells', () {
    test('the engine and its helpers are order 10\'s', () {
      expect(() => PpEngine(w: 240, h: 216, s: 26), _unimplemented('order 10'));
    });
    test('the canvas is order 11\'s', () {
      expect(() => Ctx(Uint32List(4), 2, 2), _unimplemented('order 11'));
    });
    test('a sprite holds its picture', () {
      final s = Sprite(2, 1, Uint32List.fromList([0xFF0000FF, 0]));
      expect([s.w, s.h, s.px.length], [2, 1, 2]);
    });
  });

  group('a scene', () {
    final s = _Still();
    test('what a scene without hud, poke, talkAt, respIcon, estado does', () {
      expect(s.estado({}), '');
      expect(s.talkAt('abuela', {}), isNull);
      expect(s.poke('puerta'), isNull);
    });
    test('a thing\'s defaults are the kit\'s', () {
      final t = s.cosas.single;
      expect(t.z, isFalse);
      expect(t.m, isNull);
      expect(t.si, isNull);
    });
  });
}
