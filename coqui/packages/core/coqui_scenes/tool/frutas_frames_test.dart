// Las frutas' frames at every act's end, on a still host (a dev tool, for looking): each story's steps walked as
// test/frutas_acts_test.dart walks them (both branches of each decision and `if`, one value of each draw), and after each
// act the display picture (196 x 216: the view, the boards, the signs) written as a PNG at 3x.
//
//   COQUI_OUT=DIR flutter test tool/frutas_frames_test.dart      (in this package)
//
// writes DIR/<story>-<n>-<act>.png.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/frutas/frutas.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/png.dart';
import '../test/support/sheet_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final out = Platform.environment['COQUI_OUT'] ?? '';
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('frutas');
  });
  test('the frames of Las frutas at every act', () async {
    if (out.isEmpty) return;
    Directory(out).createSync(recursive: true);
    for (final id in const ['la-sopa-de-abuela', 'esta-bueno', 'una-libra']) {
      final story = jsonDecode(
        File('test/support/fixtures/frutas/$id.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final scene = createFrutas() as Frutas;
      final frame = StillFrame(scene);
      final host = frame.host;
      host.S = story;
      host.W = {
        ...host.W,
        'lost': 0,
        'resp': null,
        'twinkle': null,
        ...scene.fresh(story),
      };
      final v = <String, String>{
        'ka': 'papas',
        'kb': 'platanos',
        'ga': 'fruta_a',
        'ha': 'fruta_b',
        'gb': 'fruta_b',
        'hb': 'fruta_a',
        'la': 'a',
        'oa': 'b',
        'lb': 'b',
        'ob': 'a',
        'pa': 'cajon_a',
        'pb': 'cajon_a',
        'wa': 'fresco',
        'wb': 'malo',
        'ua': 'una',
        'ub': 'una',
      };
      var n = 0;
      Object? sub(Object? s) => s is String
          ? s.replaceAllMapped(RegExp(r'\$([a-z]+)'), (m) => v[m[1]!] ?? m[0]!)
          : s;
      void shot(String what) {
        frame.draw(host.W, F: host.F, cam: scene.CAM['wide']!);
        writePng(
          '$out/$id-${(n++).toString().padLeft(2, '0')}-$what.png',
          frame.display,
          196,
          216,
          scale: 3,
        );
      }

      Future<void> walk(Object? steps) async {
        if (steps is! List) return;
        for (final st in steps) {
          if (st is! Map<String, dynamic>) continue;
          if (st['set'] is Map) {
            host.W.addAll((st['set'] as Map).cast<String, dynamic>());
          } else if (st['act'] is String) {
            final o = {for (final e in st.entries) e.key: sub(e.value)};
            await scene.acts[st['act']]!(o);
            host.F += 3;
            shot(st['act'] as String);
          } else if (st['ask'] is String) {
            await walk(st['after']);
            await walk(st['then']);
          } else if (st['decide'] is String) {
            // $x: what he touched on the wrong way, the other option than the right one
            final pick = sub(st['pick']);
            v['x'] =
                (st['options'] as List).firstWhere((o) => o != pick) as String;
            await walk(st['wrong']);
            await walk(st['right']);
          } else if (st['if'] is String) {
            await walk(st['then']);
            await walk(st['else']);
          }
        }
      }

      shot('start');
      await walk(story['beats']);
      await walk(story['final']);
    }
  });

  // La mesa's review picture cocina.no (mesa-sheet.json pictures.cocina.no: "abuela outside at a fruit stall"), drawn
  // from this scene: the state "manana-open-0-frutas" (frutas-set.html?surtido=frutas, the page's defaults), abuela
  // alone at abuela.delante facing left (cual-mesa.json's dir -1), no needle, no frog, no goat; the picture cut at
  // [22, 112, 196, 104], zoom 1.
  test('La mesa\'s cocina.no, from Las frutas', () async {
    if (out.isEmpty) return;
    Directory(out).createSync(recursive: true);
    final scene = createFrutas() as Frutas;
    final frame = StillFrame(scene);
    final w = scene.places.world('abuela.delante');
    final W = <String, dynamic>{
      ...frame.host.W,
      'hora': 'manana',
      'puerta': 'open',
      'surtido': 'frutas',
      'gente': {
        'abuela': {
          'x': w[0],
          'y': w[1],
          'z': w[2],
          'spot': 'abuela.delante',
          'vis': 1,
          'dir': -1,
          'pose': 'idle',
          'dy': 0,
        },
      },
      'cosas': <dynamic>[],
      'cq': {'x': 0, 'y': 0, 's': 1, 'vis': 0, 'z': 0},
    };
    frame.draw(W, F: 0, cam: scene.CAM['wide']!, allSigns: false);
    expect(scene.setKey(W), 'manana-open-0-frutas');
    final crop = Uint32List(196 * 104);
    for (var y = 0; y < 104; y++) {
      for (var x = 0; x < 196; x++) {
        crop[y * 196 + x] = frame.picture[(112 + y) * 240 + 22 + x];
      }
    }
    writePng('$out/mesa-cocina-no.png', crop, 196, 104, scale: 3);
  });
}
