// The pictures for the fresh readers (order 14), all drawn by the Dart scene. Not part of the package's tests: run it
// on the vm with
//
//   COQUI_OUT=<dir> COQUI_CASES=<preview out>/cases.json flutter test tool/make_pictures_test.dart
//
// COQUI_CASES is the cases.json tool/preview_shots.mjs wrote (every moment at rest of every recorded run). It writes,
// under COQUI_OUT: pairs/ (each pair's two pictures side by side, as ScenePictures draws them, 3x), views/ (each view
// in the first moment at rest of a story that uses it), states/ (the 25 states of the set), story/<story>/ (each
// moment at rest of the story's "right" run, in order), boxes/ (frames with every touch box drawn on them), and
// key.txt (what each file is).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/frente/frente.dart';
import 'package:coqui_scenes/src/frente/frente_set.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/fixtures/set_refs.dart';
import '../test/support/pairs.dart';
import '../test/support/png.dart';
import '../test/support/preview_remap.dart';
import '../test/support/state_w.dart';

void outline(Uint32List pic, int w, int h, List<num> b, int col) {
  final x0 = b[0].floor(),
      y0 = b[1].floor(),
      x1 = (b[0] + b[2]).floor() - 1,
      y1 = (b[1] + b[3]).floor() - 1;
  void put(int x, int y) {
    if (x >= 0 && y >= 0 && x < w && y < h) pic[y * w + x] = col;
  }

  for (var x = x0; x <= x1; x++) {
    put(x, y0);
    put(x, y1);
  }
  for (var y = y0; y <= y1; y++) {
    put(x0, y);
    put(x1, y);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final out = Platform.environment['COQUI_OUT'];
  final casesPath = Platform.environment['COQUI_CASES'];

  test('the pictures for the fresh readers', () async {
    if (out == null || casesPath == null) {
      markTestSkipped('set COQUI_OUT and COQUI_CASES');
      return;
    }
    final key = StringBuffer();
    final pairs = frentePairs();
    final source = ScenePictures(pairs: pairs);
    final frame = await source.frameOf('frente');
    final scene = frame.scene as Frente;

    // pairs: si on the left, no on the right, 4 picture pixels apart
    key.writeln(
      'pairs/<word>.png: the two pictures of a review pair of cual-frente as ScenePictures draws them, 3x: '
      'left the right answer (si), right the wrong one (no).',
    );
    for (final p in pairs) {
      final si = await source.pixels(
        PictureRef.of(p, p.yes),
        name: '${p.word}.si',
      );
      final no = await source.pixels(
        PictureRef.of(p, p.no),
        name: '${p.word}.no',
      );
      const w = 196 * 2 + 4, h = 104;
      final both = Uint32List(w * h)..fillRange(0, w * h, 0xFF241A0E);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < 196; x++) {
          both[y * w + x] = si[y * 196 + x];
          both[y * w + 200 + x] = no[y * 196 + x];
        }
      }
      writePng('$out/pairs/${p.word}.png', both, w, h, scale: 3);
      key.writeln('  pairs/${p.word}.png: the word "${p.word}"');
    }

    // the moments of the stories
    final cases = (jsonDecode(File(casesPath).readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
    final moments = cases
        .where((c) => c['kind'] == 'story' && c['plan'] == 'right')
        .toList();
    Uint32List drawMoment(Map<String, dynamic> c) {
      final W = previewRemapW(
        previewBaseW(scene.fresh(const {}), c['W'] as Map<String, dynamic>),
        scene.sheet,
      );
      final cam = scene.sheet.viewOf(c['view'] as String, scene.projection);
      frame.draw(W, F: c['F'] as int, cam: cam);
      return Uint32List.fromList(frame.display);
    }

    key.writeln(
      'story/<story>/<n>.png: each moment at rest of the story\'s recorded "right" run, in order, as the Dart '
      'scene draws the screen (196 x 216: the view, the signs, the plate in the corner), 3x. A moment at rest: '
      'the state after a step whose view is one of the sheet\'s views, nobody half faded, not the same as the one before.',
    );
    for (final c in moments) {
      writePng(
        '$out/story/${c['story']}/${(c['n'] as int).toString().padLeft(3, '0')}.png',
        drawMoment(c),
        196,
        216,
        scale: 3,
      );
      key.writeln(
        '  story/${c['story']}/${(c['n'] as int).toString().padLeft(3, '0')}.png: after step ${c['step']}, view ${c['view']}',
      );
    }

    key.writeln(
      'views/<view>.png: each view of the sheet in the first moment at rest of a story that uses it, as the screen, 3x.',
    );
    final seen = <String>{};
    for (final c in moments) {
      final v = c['view'] as String;
      if (!seen.add(v)) continue;
      writePng('$out/views/$v.png', drawMoment(c), 196, 216, scale: 3);
      key.writeln('  views/$v.png: ${c['story']} after step ${c['step']}');
    }

    // the 25 states of the set, as frente-set.html draws them (bake, wind at time 0)
    key.writeln(
      'states/<state>.png: the set in each of its 25 baked states, no characters, 240 x 216, 3x.',
    );
    final e = frenteEngine(), b = PpBuild(e);
    for (final r
        in (jsonDecode(setRefs) as List).cast<Map<String, dynamic>>()) {
      FrenteSet(e, b, FrenteState.fromQuery(r['query'] as String)).buildSet();
      e.pix.setAll(0, e.bakedPix);
      e.zb.setAll(0, e.bakedZ);
      e.drawLeaves(0);
      e.drawTufts(0);
      writePng('$out/states/${r['id']}.png', e.pix, 240, 216, scale: 3);
      key.writeln('  states/${r['id']}.png: ${r['query']}');
    }

    // the touch boxes: a frame of each state, with its things' boxes (yellow) and hit boxes (magenta) drawn on it
    key.writeln(
      'boxes/<name>.png: a frame of the whole picture (240 x 216, 3x) with each shown thing\'s touch box '
      'in yellow and the box its touch hits in magenta (things of the set), the frog and abuela in yellow.',
    );
    final boxWorlds = <String, ({Map<String, dynamic> W, int F})>{
      'day': wOfState(scene, FrenteState.fromQuery('door=open&win=open')),
      'hide': wOfState(
        scene,
        FrenteState.fromQuery('door=shut&win=shut&sky=dusk&hide=1'),
      ),
      'storm': wOfState(
        scene,
        FrenteState.fromQuery('door=shut&win=open&lights=1&sky=storm'),
      ),
    };
    boxWorlds['day']!.W['ab'] = {
      'en': 'puerta',
      'pose': 'idle',
      'bub': null,
      'al': 1,
    };
    boxWorlds['day']!.W['ave'] = {
      'mode': 'sit',
      'x': 101.09,
      'y': 55.45,
      'dir': 1,
      'st': 'n',
    };
    boxWorlds['hide']!.W['ab'] = {
      'en': 'paso',
      'pose': 'idle',
      'bub': null,
      'al': 1,
    };
    boxWorlds['storm']!.W['ab'] = {
      'en': 'ventana',
      'pose': 'idle',
      'bub': null,
      'al': 1,
    };
    boxWorlds['storm']!.W['nube'] = <String, dynamic>{'x': 22, 'tx': 22};
    for (final en in boxWorlds.entries) {
      final W = en.value.W;
      frame.draw(W, F: en.value.F, cam: scene.CAM['wide']!, allSigns: false);
      final pic = Uint32List.fromList(frame.picture);
      for (final k in scene.sheet.things.keys) {
        final t = scene.sheet.things[k]!;
        List<num>? box;
        if (k == 'coqui') {
          final f = frogBox(W['cq'] as Map<String, dynamic>);
          box = [f.x, f.y, f.w, f.h];
        } else if (k == 'pajaro') {
          if (W['ave'] == null) continue;
          final p = scene.avePos(W['ave'] as Map<String, dynamic>);
          box = [p[0] - 15, p[1] - 23, 31, 27];
        } else if (k == 'bizcocho') {
          continue;
        } else {
          if ((k.endsWith('_grande') || k.endsWith('_pequena')) &&
              !jsTruthy(W['escondite']))
            continue;
          if (k == 'abuela' && W['ab'] == null) continue;
          if (k == 'nube' && W['nube'] == null) continue;
          box = scene.box(k, W) ?? scene.sheet.boxOf(k, scene.projection);
        }
        outline(pic, 240, 216, box, 0xFF00FFFF);
        if (t.hit != null)
          outline(
            pic,
            240,
            216,
            scene.sheet.hitBoxOf(k, scene.projection)!,
            0xFFFF00FF,
          );
      }
      writePng('$out/boxes/${en.key}.png', pic, 240, 216, scale: 3);
      key.writeln('  boxes/${en.key}.png: ${scene.setKey(W)}');
    }
    File('$out/key.txt').writeAsStringSync(key.toString());
  }, timeout: const Timeout(Duration(minutes: 10)));
}
