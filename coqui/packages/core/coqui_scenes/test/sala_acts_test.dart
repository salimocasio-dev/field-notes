// La sala's acts and what is new in its sheet. Every act the six stories name runs, in each story's order and with the
// story's own arguments, on a host whose waits return at once (each one tick), and its world draws after it; the places
// the sheet moves (`moves`) are where the port puts people; a bubble goes where the sheet's `talk` says; the photos are
// drawn in their frames' openings; the low table is drawn again over who stands behind it, only where it is nearer; the
// blur (W.borroso) and the camera's window out of focus keep their smoothing (the sheet's `smoothing`); the scene draws its
// random numbers from the game's one source; remap gives the sheet's places.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/sala/sala.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_files.dart';
import 'support/sheet_bundle.dart';

/// A still host whose every wait is one tick (the frame counter goes on), so an act that waits for frames ends.
class TickingHost extends StillHost {
  TickingHost(super.scene);

  @override
  Future<void> wait(num ms) async {
    F++;
  }
}

/// The game's one random source, counting its draws.
class CountingRng implements Rng {
  CountingRng(this.inner);

  final Rng inner;
  int draws = 0;

  @override
  double next() {
    draws++;
    return inner.next();
  }
}

const stories = [
  'la-familia',
  'la-foto',
  'quien-eres-tu',
  'd-bizcocho-bebe',
  'd-foto-familia',
  'h-sala',
];

// every {act: ...} of a story file, in its order
List<Map<String, dynamic>> actsIn(Object? v) => [
  if (v is Map && v['act'] is String) Map<String, dynamic>.from(v),
  if (v is Map)
    for (final e in v.values) ...actsIn(e),
  if (v is List)
    for (final e in v) ...actsIn(e),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Sala scene;
  late TickingHost host;
  final rng = CountingRng(Mulberry32(1));
  setUpAll(() async {
    final sheet = (await ScenePictures(bundle: testBundle()).frameOf('sala'))
        .scene
        .sheet;
    frame = StillFrame(Sala(sheet, rng: rng));
    scene = frame.scene as Sala;
    host = TickingHost(scene);
  });

  Map<String, dynamic> fresh({String thing = 'none'}) {
    host
      ..fresh()
      ..S = {
        'stake': {'thing': thing, 'steps': 3},
      }
      ..F = 40;
    return host.W;
  }

  void draw(Map<String, dynamic> W, {int? F}) {
    frame.host.V = host.V;
    scene.host = frame.host;
    frame.draw(W, F: F ?? host.F, cam: scene.CAM['wide']!);
    scene.host = host;
  }

  Map<String, dynamic> person(String id) =>
      (host.W['gente'] as Map<String, dynamic>)[id] as Map<String, dynamic>;

  test(
    'everyone starts where the sheet puts them; the frog at LUGAR.centro',
    () {
      final W = fresh();
      for (final id in scene.SITIO.keys) {
        final s = scene.sheet.spots['sitio.$id']!.now!;
        expect([person(id)['x'], person(id)['y']], s, reason: id);
      }
      final q = W['cq'] as Map<String, dynamic>;
      expect([q['x'], q['y']], scene.sheet.spots['frog.centro']!.now);
      expect(scene.setKey(W), '1-000');
      (W['fotos'] as List)[1] = <String, dynamic>{
        'q': ['mama'],
        'ok': 0,
        'pata': 1,
      };
      expect(scene.setKey(W), '1-010');
    },
  );

  for (final st in stories) {
    test(
      '$st: every act it names runs, in its order, and the world draws after each',
      () async {
        final story = jsonDecode(
          historiaFile('cuentos/$st.json')!,
        ) as Map<String, dynamic>;
        final W = fresh(
          thing: (story['stake'] as Map?)?['thing'] as String? ?? 'none',
        );
        host.V = {'mem_fotos': 'mama.1c-papa.0p-pies'};
        final acts = actsIn(story['beats']);
        expect(acts, isNotEmpty);
        // the story's variables, as a run fills them
        const vars = {
          r'$p': 'papa',
          r'$x': 'mama',
          r'$n': 'hermano',
          r'$ca': 'hermano',
          r'$cb': 'hermana',
        };
        for (final o0 in acts) {
          final o = {
            for (final e in o0.entries)
              e.key: e.value is String && (e.value as String).startsWith(r'$')
                  ? vars[e.value] ?? 'mama'
                  : e.value,
          };
          final name = o['act'] as String, act = scene.acts[name];
          expect(act, isNotNull, reason: '$st: no act $name');
          await act!(o);
          draw(W);
        }
      },
      skip: historiaFile('datos/curso.json') == null
          ? 'reads historia/ (vm only)'
          : false,
    );
  }

  test('the places the sheet moves are where the port puts people', () async {
    List<num> at(String id) => [person(id)['x'], person(id)['y']];
    List<num> moved(int k, int place) => scene.sheet.moves[k].places[place].now;
    expect(
      [for (final m in scene.sheet.moves) m.act],
      [
        'corren',
        'solo',
        'inicio8',
        'suelta',
        'final8',
        'final8',
        'final7',
        'lados',
      ],
    );
    final W = fresh();
    await scene.acts['corren']!({});
    expect(at('hermano'), moved(0, 0));
    expect(at('hermana'), moved(0, 1));
    await scene.acts['solo']!({'quien': 'hermano'});
    expect(at('hermano'), moved(1, 0));
    expect(at('hermana'), moved(1, 1));
    await scene.acts['inicio8']!({});
    expect(at('hermano'), moved(2, 0));
    expect(at('hermana'), moved(2, 1));
    await scene.acts['suelta']!({'quien': 'hermano'});
    expect(at('hermano'), moved(3, 0));
    await scene.acts['suelta']!({'quien': 'hermana'});
    expect(at('hermana'), moved(3, 1));
    W['lost'] = 3;
    await scene.acts['final8']!({});
    expect(at('abuelo'), moved(4, 0));
    expect(at('abuela'), moved(5, 0));
    fresh();
    await scene.acts['final7']!({});
    expect(at('abuelo'), moved(6, 0));
    expect(scene.JUNTOS, [moved(7, 0), moved(7, 1)]);
  });

  test('lados draws one random number from the game\'s source; with none it says so', () async {
    fresh();
    final before = rng.draws;
    await scene.acts['lados']!({'a': 'mama', 'b': 'papa', 'donde': 'juntos'});
    expect(rng.draws, before + 1);
    final xs = [person('mama')['x'], person('papa')['x']]..sort();
    expect(xs, [scene.JUNTOS[0][0], scene.JUNTOS[1][0]]);
    final bare = Sala(scene.sheet);
    TickingHost(bare).fresh();
    expect(
      () => bare.acts['lados']!({'a': 'mama', 'b': 'papa', 'donde': 'juntos'}),
      throwsStateError,
    );
    scene.host = host;
  });

  test('talk: no bubble, the old place over the head; a bubble that would land on a face goes beside the head', () {
    final W = fresh();
    final papa = person('papa');
    expect(scene.talkAt('papa', W), [papa['x'], (papa['y'] as num) - 49 - 1]);
    // the boy standing before papá on the sofa: over papá's head his bubble would be on the boy's face? no, the boy's
    // bubble over his head would be on papá's face
    final h = person('hermano')
      ..['vis'] = 1
      ..['x'] = 131
      ..['y'] = 150;
    h['bub'] = 'amor';
    final at = scene.talkAt('hermano', W)!;
    final top = [131, 150 - 44 - 1];
    final r = scene.sheet.bubbleRects['amor']!;
    expect(at, isNot([top[0], top[1] - 38]));
    // its rectangle is clear of papá's face (sitting: heads papa.sent)
    final hd = scene.sheet.talk!.heads['papa.sent']!;
    final face = [131 + hd.head - 6, 127 + hd.top + 5, 12, 10];
    final tip = [at[0], at[1] + 38],
        rect = [tip[0] + r[0], tip[1] + r[1], r[2], r[3]];
    final meets =
        rect[0] < face[0] + face[2] &&
        face[0] < rect[0] + rect[2] &&
        rect[1] < face[1] + face[3] &&
        face[1] < rect[1] + rect[3];
    expect(meets, isFalse, reason: 'bubble $rect, face $face');
    draw(W);
  });

  test(
    'a photo is drawn only inside its frame\'s opening, straight or crooked',
    () {
      for (final ok in [1, 0]) {
        final W = fresh();
        final f = <String, dynamic>{
          'q': ['coqui', 'mama'],
          'ok': ok,
          if (ok == 0) 'pata': 1,
        };
        W['fotos'] = [f, null, null];
        draw(W);
        final clip = scene.sheet.clips[ok == 1 ? 'foto.0' : 'foto.0.torcida']!;
        // against the set itself, baked for that state: on the wall over everyone's heads, what the photo changed lies in
        // its opening's box
        final baked = frame.bakes.bakeKey(scene.setKey(W)).pix;
        var changed = 0, outside = 0;
        for (var i = 0; i < baked.length; i++) {
          final x = i % 240, y = i ~/ 240;
          if (x < 60 || x > 150 || y >= 78) continue;
          if (frame.picture[i] == baked[i]) continue;
          changed++;
          final c = clip.box;
          if (x < c[0] || x >= c[0] + c[2] || y < c[1] || y >= c[1] + c[3]) {
            outside++;
          }
        }
        expect(changed, greaterThan(100), reason: 'ok $ok');
        expect(outside, 0, reason: 'ok $ok');
      }
    },
  );

  test(
    'the low table is drawn again over who stands behind it, only where nearer',
    () {
      final W = fresh();
      final b = person('hermano')
        ..['vis'] = 1
        ..['x'] = 121
        ..['y'] = 150;
      draw(W);
      final withTable = Uint32List.fromList(frame.picture);
      // the boy's own pixels where the table is in front: the set's table pixels are there, not his
      // the boy alone, on a clear picture: which pixels are his
      final mine = Uint32List(240 * 216);
      scene.gente(Ctx(mine, 240, 216), 'hermano', 0);
      var tablePx = 0, boyPx = 0;
      for (var i = 0; i < mine.length; i++) {
        if (mine[i] >> 24 == 0) continue;
        if (withTable[i] == frame.engine.bakedPix[i]) {
          tablePx++;
        } else {
          boyPx++;
        }
      }
      expect(
        boyPx,
        greaterThan(200),
        reason: 'his head and body over the table show',
      );
      expect(tablePx, greaterThan(20));
    },
  );

  test(
    'the blur and the camera\'s window out of focus keep their smoothing',
    () {
      final W = fresh();
      draw(W);
      final sharp = Uint32List.fromList(frame.picture);
      W['borroso'] = 1;
      draw(W);
      final blur = frame.picture;
      var differ = 0;
      for (var i = 0; i < blur.length; i++) {
        if (blur[i] != sharp[i]) differ++;
      }
      expect(differ, greaterThan(blur.length ~/ 2));
      // a smooth picture: neighbours differ little
      var jumps = 0;
      for (var i = 1; i < blur.length; i++) {
        final a = blur[i], c = blur[i - 1];
        if (((a & 255) - (c & 255)).abs() > 40) jumps++;
      }
      expect(jumps, lessThan(500));
      W['borroso'] = 0;
      W['visor'] = <String, dynamic>{'quien': 'hermano', 'nitido': 0};
      draw(W);
      W['visor'] = <String, dynamic>{'quien': 'hermano', 'nitido': 1};
      draw(W);
    },
  );

  test(
    'retrato takes the photo of everyone from the last frame drawn: 128 x 80',
    () async {
      final W = fresh();
      draw(W);
      await scene.acts['retrato']!({});
      final k = W['retrato'] as Sprite;
      expect([k.w, k.h], [128, 80]);
      var drawn = 0;
      for (final p in k.px) {
        if (p >> 24 != 0) drawn++;
      }
      expect(drawn, 128 * 80);
      draw(W);
    },
  );

  test('remap: a floor point keeps its place; a pair rectangle its pictures\' crop', () {
    expect(scene.remap([120, 146]), [120, 146]);
    expect(scene.remap([41, 70, 113, 60]), [48, 77, 98, 52]);
    expect(scene.remap([70]), [70]);
    expect(() => scene.remap([1, 2]), throwsA(isA<SheetError>()));
  });
}
