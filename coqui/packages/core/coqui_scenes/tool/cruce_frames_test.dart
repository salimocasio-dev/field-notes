// El cruce's frames at every act's end, on a still host (a dev tool, for looking): each story's steps walked as
// test/cruce_acts_test.dart walks them (both branches of each decision and `if`, one value of each draw, the `lead`s),
// and after each act the display picture (196 x 216: the view, the cards, the signs); all of a story's frames on one
// contact sheet, 1x, six to a row.
//
//   COQUI_OUT=DIR [COQUI_PICK=0|1] flutter test tool/cruce_frames_test.dart      (in this package)
//
// writes DIR/<story>.png.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/cruce/cruce.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/cruce_acts_test.dart' show cruceVars;
import '../test/support/png.dart';
import '../test/support/sheet_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final out = Platform.environment['COQUI_OUT'] ?? '';
  final pick = int.tryParse(Platform.environment['COQUI_PICK'] ?? '') ?? 0;
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('cruce');
  });
  test('the frames of El cruce at every act', () async {
    if (out.isEmpty) return;
    Directory(out).createSync(recursive: true);
    for (final id in const [
      'izquierda-o-derecha',
      'sigue-derecho',
      'al-frente-y-detras',
    ]) {
      final story = jsonDecode(
        File('test/support/fixtures/cruce/$id.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final scene = createCruce() as Cruce;
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
      final v = {...cruceVars(id, pick)};
      final shots = <Uint32List>[];
      Object? sub(Object? s) => s is String
          ? s.replaceAllMapped(RegExp(r'\$([a-z]+)'), (m) => v[m[1]!] ?? m[0]!)
          : s;
      void shot() {
        frame.draw(host.W, F: host.F, cam: host.cam);
        shots.add(Uint32List.fromList(frame.display));
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
            if (st['act'] != 'ya') shot();
          } else if (st['ask'] is String) {
            await walk(st['lead']);
            await walk(st['after']);
            await walk(st['then']);
          } else if (st['decide'] is String) {
            await walk(st['lead']);
            final pk = sub(st['pick']);
            v['x'] = [
              for (final o in st['options'] as List) sub(o),
            ].firstWhere((o) => o != pk) as String;
            await walk(st['wrong']);
            await walk(st['right']);
          } else if (st['calc'] is String) {
            final c = (st['cond'] as String).split('=');
            v[st['calc'] as String] =
                (v[c[0]] == c[1] ? st['then'] : st['else']) as String;
          } else if (st['if'] is String) {
            await walk(st['then']);
            await walk(st['else']);
          }
        }
      }

      shot();
      await walk(story['beats']);
      await walk(story['final']);
      const cols = 6, w = 196, h = 216;
      final rows = (shots.length + cols - 1) ~/ cols;
      final sheet = Uint32List(cols * w * rows * h);
      for (var n = 0; n < shots.length; n++) {
        final ox = (n % cols) * w, oy = (n ~/ cols) * h;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            sheet[(oy + y) * cols * w + ox + x] = shots[n][y * w + x];
          }
        }
      }
      writePng('$out/$id.png', sheet, cols * w, rows * h, scale: 1);
    }
  });
}
