// La entrada's frames at every act's end, on a still host (a dev tool, for looking): each story's steps walked as
// test/entrada_acts_test.dart walks them, and after each act the display picture (196 x 216); all of a story's frames
// on one contact sheet, 1x, six to a row.
//
//   COQUI_OUT=DIR [COQUI_PICK=0|1] flutter test tool/entrada_frames_test.dart      (in this package)
//
// writes DIR/<story>-pick<pick>.png.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart' show jsTruthy;
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/entrada/entrada.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/entrada_acts_test.dart' show entradaVars;
import '../test/support/png.dart';
import '../test/support/sheet_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final out = Platform.environment['COQUI_OUT'] ?? '';
  final pick = int.tryParse(Platform.environment['COQUI_PICK'] ?? '') ?? 0;
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('entrada');
  });
  test('the frames of La entrada at every act', () async {
    if (out.isEmpty) return;
    Directory(out).createSync(recursive: true);
    for (final id in const ['bienvenidos', 'esta-libre', 'con-y-sin']) {
      final story = jsonDecode(
        File('test/support/fixtures/entrada/$id.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final scene = createEntrada() as Entrada;
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
      final v = {...entradaVars(id, pick)};
      final shots = <Uint32List>[];
      Object? sub(Object? s) => s is String
          ? s.replaceAllMapped(
              RegExp(r'\$([a-z0-9]+)'),
              (m) => v[m[1]!] ?? m[0]!,
            )
          : s;
      bool evalCond(String cond) {
        if (cond == 'ok') return true;
        final eq = cond.indexOf('=');
        if (eq < 0) return false;
        final lhs = cond.substring(0, eq);
        final rhs = cond.substring(eq + 1);
        if (lhs == 'lost') return '${host.W['lost']}' == rhs;
        return v[lhs] == rhs;
      }

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
          } else if (st['cost'] is num) {
            host.W['lost'] =
                (host.W['lost'] as int) + (st['cost'] as num).toInt();
          } else if (st['act'] is String) {
            final o = {for (final e in st.entries) e.key: sub(e.value)};
            await scene.acts[st['act']]!(o);
            host.F += 3;
            if (!jsTruthy(o['suelto']) && st['act'] != 'ya') shot();
          } else if (st['ask'] is String) {
            await walk(st['lead']);
            await walk(st['after']);
            await walk(st['then']);
          } else if (st['decide'] is String) {
            await walk(st['lead']);
            final pk = sub(st['pick']) as String;
            v['x'] = [for (final o in st['options'] as List) sub(o) as String]
                .firstWhere((o) => o != pk);
            await walk(st['wrong']);
            await walk(st['right']);
          } else if (st['calc'] is String) {
            final ok = evalCond(st['cond'] as String);
            v[st['calc'] as String] =
                sub(ok ? st['then'] : st['else']) as String;
          } else if (st['if'] is String) {
            if (evalCond(st['if'] as String)) {
              await walk(st['then']);
            } else {
              await walk(st['else']);
            }
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
      writePng('$out/$id-pick$pick.png', sheet, cols * w, rows * h, scale: 1);
    }
  });
}
