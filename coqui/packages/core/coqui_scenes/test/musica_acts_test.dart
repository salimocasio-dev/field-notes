// La música's acts, Needs things, touch boxes, and speaker keys (musica.md, stories 111 to 113).
// Walks all three stories (la-musica, quieres-bailar, que-bueno) across both right and wrong branches, verifies every
// touchable thing answers a touch inside wide view, verifies all speaker keys have talkAt points, and checks
// ronda113 action-to-spot mapping and held-instrument transitions.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:coqui_pixel/coqui_pixel.dart' show jsTruthy;
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/musica/musica.dart';
import 'package:coqui_scenes/src/musica/musica_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// Deterministic draw variable assignment for walking [id] in acts/frames tests (`pick`: 0 or 1).
Map<String, String> musicaVars(String id, int pick) => switch (id) {
  'la-musica' =>
    pick == 0
        ? {'wa': 'guitarra', 'wb': 'tambor'}
        : {'wa': 'tambor', 'wb': 'guitarra'},
  'quieres-bailar' =>
    pick == 0
        ? {
            'qa': 'abuelo',
            'qb': 'carmen',
            'wa': 'baila',
            'pa': 'pista',
            'wb': 'canta',
            'pb': 'microfono',
          }
        : {
            'qa': 'luis',
            'qb': 'abuelo',
            'wa': 'canta',
            'pa': 'microfono',
            'wb': 'baila',
            'pb': 'pista',
          },
  _ =>
    pick == 0
        ? {
            'pa': 'abuelo',
            'pb': 'luis',
            'pc': 'carmen',
            'pd': 'senor',
            'pe': 'senora',
            'ra': 'a',
            'om': 'baila',
            'wa': 'rie',
            'wb': 'baila',
            'ka': 'abuelo',
            'kb': 'senor',
          }
        : {
            'pa': 'mujer',
            'pb': 'hombre',
            'pc': 'joven',
            'pd': 'senora',
            'pe': 'luis',
            'ra': 'b',
            'om': 'come',
            'wa': 'come',
            'wb': 'rie',
            'ka': 'luis',
            'kb': 'hombre',
          },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('musica');
  });

  test(
    'every story walks to the end across both picks and right/wrong acts',
    () async {
      for (final id in const ['la-musica', 'quieres-bailar', 'que-bueno']) {
        final story = jsonDecode(
          File('test/support/fixtures/musica/$id.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        for (final pick in const [0, 1]) {
          final scene = createMusica() as Musica;
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
          final v = {...musicaVars(id, pick)};
          Object? sub(Object? s) => s is String
              ? s.replaceAllMapped(
                  RegExp(r'\$([a-z]+)'),
                  (m) => v[m[1]!] ?? m[0]!,
                )
              : s;

          Future<void> walk(Object? steps) async {
            if (steps is! List) return;
            for (final st in steps) {
              if (st is! Map<String, dynamic>) continue;
              if (st['set'] is Map) {
                host.W.addAll((st['set'] as Map).cast<String, dynamic>());
              } else if (st['act'] is String) {
                final actName = st['act'] as String;
                expect(
                  scene.acts.containsKey(actName),
                  isTrue,
                  reason: '$id: unknown act $actName',
                );
                final o = {for (final e in st.entries) e.key: sub(e.value)};
                await scene.acts[actName]!(o);
                host.F += 3;
                frame.draw(host.W, F: host.F, cam: host.cam);
              } else if (st['ask'] is String) {
                await walk(st['lead']);
                await walk(st['after']);
                await walk(st['then']);
              } else if (st['decide'] is String) {
                await walk(st['lead']);
                final pk = sub(st['pick']) as String;
                v['x'] = [
                  for (final o in st['options'] as List) sub(o) as String,
                ].firstWhere((o) => o != pk);
                await walk(st['wrong']);
                await walk(st['right']);
              } else if (st['calc'] is String) {
                final c = (st['cond'] as String).split('=');
                v[st['calc'] as String] =
                    sub(v[c[0]] == c[1] ? st['then'] : st['else']) as String;
              } else if (st['if'] is String) {
                await walk(st['then']);
                await walk(st['else']);
              }
            }
          }

          await walk(story['beats']);
          await walk(story['final']);
          expect(frame.display.length, 196 * 216);
        }
      }
    },
  );

  test('every Needs touch thing answers a touch inside wide view', () async {
    final s111 = jsonDecode(
      File('test/support/fixtures/musica/la-musica.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final s112 = jsonDecode(
      File('test/support/fixtures/musica/quieres-bailar.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final s113 = jsonDecode(
      File('test/support/fixtures/musica/que-bueno.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    // Story 111 opening: stage, rack instruments, dancers, musicians, abuela, bench, floor, frog
    final sc1 = createMusica() as Musica;
    final f1 = StillFrame(sc1);
    f1.host.S = s111;
    f1.host.W = {...f1.host.W, ...sc1.fresh(s111)};
    await sc1.acts['parejas']!({'act': 'parejas', 'n': 3});
    await sc1.acts['llega']!({'quien': 'musico1', 'a': 'taburete1'});
    await sc1.acts['llega']!({'quien': 'musico2', 'a': 'taburete2'});
    await sc1.acts['llega']!({'quien': 'abuela', 'a': 'junto_escenario'});
    await sc1.acts['ir']!({'a': 'borde_coqui'});

    // Story 112 opening: microphone, abuelo, luis, carmen
    final sc2 = createMusica() as Musica;
    final f2 = StillFrame(sc2);
    f2.host.S = s112;
    f2.host.W = {...f2.host.W, ...sc2.fresh(s112)};
    await sc2.acts['notas']!({'n': 3});
    await sc2.acts['llega']!({'quien': 'musico1', 'a': 'taburete1'});
    await sc2.acts['llega']!({'quien': 'musico2', 'a': 'taburete2'});
    await sc2.acts['llega']!({'quien': 'abuelo', 'a': 'espera1'});
    await sc2.acts['llega']!({'quien': 'luis', 'a': 'espera2'});
    await sc2.acts['llega']!({'quien': 'carmen', 'a': 'espera3'});
    await sc2.acts['ir']!({'a': 'centro_coqui'});

    // Story 113 game: camara on frog + Pool 113 people
    final sc3 = createMusica() as Musica;
    final f3 = StillFrame(sc3);
    f3.host.S = s113;
    f3.host.W = {...f3.host.W, ...sc3.fresh(s113)};
    await sc3.acts['llega']!({'quien': 'abuela', 'a': 'banqueta_abuela'});
    await sc3.acts['ronda113']!({
      'quienes': 'senor,senora,joven,mujer,hombre',
      'que': 'rie,canta,bosteza,baila,come',
    });

    final frames = [
      (
        sc1,
        f1,
        const [
          'guitarra',
          'tambor',
          'escenario',
          'pista',
          'banco',
          'musico1',
          'musico2',
          'abuela',
          'coqui',
        ],
      ),
      (sc2, f2, const ['microfono', 'abuelo', 'luis', 'carmen']),
      (
        sc3,
        f3,
        const ['camara', 'senor', 'senora', 'joven', 'mujer', 'hombre'],
      ),
    ];
    for (final (sc, fr, ids) in frames) {
      final view = sc.CAM['wide']!;
      for (final id in ids) {
        final t = sc.cosas.firstWhere((c) => c.id == id);
        expect(t.si == null || t.si!(fr.host.W), isTrue, reason: '$id hidden');
        final box = t.box(fr.host.W)!;
        expect(box[0], greaterThanOrEqualTo(view[0]), reason: '$id left');
        expect(
          box[0] + box[2],
          lessThanOrEqualTo(view[0] + view[2]),
          reason: '$id right',
        );
        final hit = sc.hit(box[0] + box[2] / 2, box[1] + box[3] / 2, fr.host.W);
        expect(hit, isNotNull, reason: '$id center did not answer');
      }
    }

    for (final sp in const [
      'musico1',
      'musico2',
      'abuela',
      'abuelo',
      'luis',
      'carmen',
      'coqui',
    ]) {
      final pt = sc2.talkAt(sp, f2.host.W);
      expect(pt, isNotNull, reason: 'talkAt($sp) null');
      expect(pt!.length, 2);
    }
  });

  test(
    'ronda113 maps spots by action and cuelga111 returns instruments',
    () async {
      final story113 = jsonDecode(
        File('test/support/fixtures/musica/que-bueno.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final sc = createMusica() as Musica;
      final fr = StillFrame(sc);
      fr.host.S = story113;
      fr.host.W = {...fr.host.W, ...sc.fresh(story113)};
      await sc.acts['ronda113']!({
        'quienes': 'abuelo,luis,carmen,senor,senora',
        'que': 'rie,canta,bosteza,baila,come',
      });
      final g = fr.host.W['gente'] as Map<String, dynamic>;
      expect((g['abuelo'] as Map)['spot'], 'ronda4');
      expect((g['luis'] as Map)['spot'], 'ante_micro');
      expect((g['carmen'] as Map)['spot'], 'ronda5');
      expect((g['senor'] as Map)['spot'], 'ronda1');
      expect((g['senora'] as Map)['spot'], 'banco3');
      expect((g['luis'] as Map)['sing'], 1);
      expect((g['senor'] as Map)['dance'], 1);

      // Dancing participant renders a distinct animated sprite across frames
      final dance0 = sc
          .items(fr.host.W, 0)
          .firstWhere((i) => i.tag == 'persona:senor');
      final dance3 = sc
          .items(fr.host.W, 3)
          .firstWhere((i) => i.tag == 'persona:senor');
      final idleSenor = mkMusicaPersona('senor', 'idle');
      expect(dance0.s.px, isNot(equals(idleSenor.px)));
      expect(dance3.s.px, isNot(equals(dance0.s.px)));

      // Wrong photo keeps rejected photo under abuela's stool until corrected
      await sc.acts['foto113']!({'a': 'abuelo', 'ok': 0});
      expect(fr.host.W['badFoto'], 1);
      await sc.acts['hojas']!({'n': 2});
      await sc.acts['marca']!({'que': 'x'});
      expect(sc.items(fr.host.W, 0).any((i) => i.tag == 'fx:bad_foto'), isTrue);
      await sc.acts['foto113']!({'a': 'carmen', 'ok': 1});
      expect(fr.host.W['badFoto'], 0);
      expect(
        sc.items(fr.host.W, 0).any((i) => i.tag == 'fx:bad_foto'),
        isFalse,
      );

      // `gesto(carmen, rie)` preserves laughing expression across opening asks until moved
      await sc.acts['gesto']!({'quien': 'carmen', 'que': 'rie'});
      expect((g['carmen'] as Map)['laugh'], 1);
      await sc.acts['llega']!({'quien': 'carmen', 'a': 'banco1'});
      expect((g['carmen'] as Map)['laugh'], 0);

      // Held instrument and hang-back cycle in Story 111
      final story111 = jsonDecode(
        File('test/support/fixtures/musica/la-musica.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final sc1 = createMusica() as Musica;
      final fr1 = StillFrame(sc1);
      fr1.host.S = story111;
      fr1.host.W = {...fr1.host.W, ...sc1.fresh(story111)};
      await sc1.acts['llega']!({'quien': 'musico1', 'a': 'taburete1'});
      await sc1.acts['toca111']!({
        'quien': 'musico1',
        'que': 'guitarra',
        'ok': 1,
      });
      expect(fr1.host.W['guitarraHeldBy'], 'musico1');
      expect(
        sc1.items(fr1.host.W, 0).any((i) => i.tag == 'held:guitarra'),
        isTrue,
      );
      await sc1.acts['cuelga111']!({});
      expect(fr1.host.W['guitarraHeldBy'], isNull);
      expect(
        sc1.items(fr1.host.W, 0).any((i) => i.tag == 'cosa:guitarra'),
        isTrue,
      );
    },
  );

  test('gesto variants and suelto/ya run cleanly', () async {
    final story = jsonDecode(
      File('test/support/fixtures/musica/quieres-bailar.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final sc = createMusica() as Musica;
    final fr = StillFrame(sc);
    fr.host.S = story;
    fr.host.W = {...fr.host.W, ...sc.fresh(story)};
    await sc.acts['llega']!({'quien': 'abuelo', 'a': 'espera1', 'suelto': 1});
    await sc.acts['llega']!({'quien': 'luis', 'a': 'espera3', 'suelto': 1});
    await sc.acts['ya']!({});
    for (final q in const [
      'saluda',
      'mira',
      'senala',
      'reverencia',
      'no',
      'si',
      'pies',
      'oido',
      'rie',
      'abanico',
    ]) {
      await sc.acts['gesto']!({'quien': 'abuelo', 'que': q});
    }
    expect(jsTruthy(fr.host.W['cq']['vis']), isTrue);
  });
}
