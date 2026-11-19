import 'dart:async';
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Module implements FeatureModule {
  @override
  String get id => 'probe';
  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: 'probe',
    label: 'probe',
    icon: Icons.circle,
    builder: (_) => const Text('the tab'),
  );
  @override
  Widget? screenFor(AppRoute route, Services s) =>
      route is BookRoute ? Text('book ${route.id}') : null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the small fakes', () {
    test('FakeClock stands still, is set and moves on', () {
      final c = FakeClock(1000);
      expect(c.nowMs(), 1000);
      c.advance(const Duration(seconds: 2));
      expect(c.nowMs(), 3000);
      c.now = 5;
      expect(c.nowMs(), 5);
      expect(
        FakeClock().nowMs(),
        DateTime.utc(2026, 11, 19, 15).millisecondsSinceEpoch,
      );
    });

    test('FakeRng is Mulberry32 with its seed, and counts draws', () {
      final a = FakeRng(7), b = Mulberry32(7);
      for (var i = 0; i < 5; i++) {
        expect(a.next(), b.next());
      }
      expect(a.draws, 5);
      expect(FakeRng().next(), Mulberry32(1).next());
    });

    test('FakeKeyValueStore keeps what is written', () async {
      final s = FakeKeyValueStore({'a': '1'});
      expect(s.read('a'), '1');
      await s.write('b', '2');
      expect(s.read('b'), '2');
      expect(s.writes, [
        ['b', '2'],
      ]);
      expect(s.read('c'), isNull);
    });

    test('FakeHaptics counts', () {
      final h = FakeHaptics()
        ..tick()
        ..tick()
        ..unlock();
      expect([h.ticks, h.unlocks], [2, 1]);
    });

    test('FakeAppInfo is settable', () {
      final i = FakeAppInfo(build: '42', isIos: true);
      expect(
        [i.build, i.isIos, i.isWeb, i.callsAllowed],
        ['42', true, true, true],
      );
      i.callsAllowed = false;
      expect(i.callsAllowed, isFalse);
    });

    test('FakeNavigator records routes', () {
      final n = FakeNavigator()
        ..go(const StoryRoute('la-lluvia'))
        ..go(const ReviewRoute())
        ..back();
      expect(n.routes, [const StoryRoute('la-lluvia'), const ReviewRoute()]);
      expect(n.last, const ReviewRoute());
      expect(n.backs, 1);
    });
  });

  group('FakeProgressStore', () {
    late FakeClock clock;
    late FakeProgressStore p;
    setUp(() {
      clock = FakeClock(DateTime.utc(2026, 11, 19, 15).millisecondsSinceEpoch);
      p = FakeProgressStore(clock: clock);
    });

    test('starts as palabras.js does', () {
      expect(p.raw, {
        'palabras': {},
        'dias': {},
        'cuentos': {},
        'ajustes': {'min': 30, 'todo': 0, 'bienvenida': 0, 'habla': 1},
        'minutos': 0,
        'v': 1,
      });
      expect(p.words, isEmpty);
      expect(p.setting('min'), 30);
    });

    test('heard, then answered', () {
      final r = p.heard('casa');
      expect([r.oida, r.ear.etapa, r.primera], [1, 1, clock.now]);
      clock.advance(const Duration(minutes: 1));
      final e = p.answer('casa', Skill.ear, ok: true, ms: 900);
      expect([e.n, e.bien, e.etapa, e.ultima], [1, 1, 2, clock.now]);
      p.answer('casa', Skill.mouth, ok: false);
      expect(p.word('casa')!.mouth.n, 1);
      expect(p.word('casa')!.mouth.bien, 0);
      expect(p.word('casa')!.ear.due, 0, reason: 'not the scheduler');
    });

    test('a finished story', () {
      p.storyFinished(
        StoryResult(
          id: 'la-lluvia',
          focusWords: ['casa', 'puerta'],
          lost: 1,
          log: [
            Decision(
              word: 'casa',
              asked: 'casa',
              got: 'casa',
              ok: true,
              ms: 800,
            ),
            Decision(asked: 'libre', got: 'si', ok: true),
          ],
        ),
      );
      expect(p.played('la-lluvia'), isTrue);
      expect(p.played('el-bizcocho'), isFalse);
      final s = p.story('la-lluvia')!;
      expect([s.n, s.perdido, s.ultima], [1, 1, clock.now]);
      expect(p.word('casa')!.ear.n, 1);
      expect(p.word('puerta')!.oida, 1);
      expect(p.raw['dias'], {'2026-11-19': 1});
      expect(p.streak, 1);
    });

    test('presume', () {
      p.presume(['abre'], ['el-bizcocho'], [
        {'w': 'abre', 'ok': true},
      ]);
      expect(p.word('abre')!.ear.etapa, 3);
      expect(p.word('abre')!.ear.presunta, 1);
      expect(p.openForSpeaking('abre'), isTrue);
      expect(p.story('el-bizcocho')!.presunto, 1);
      expect(p.played('el-bizcocho'), isTrue);
      expect(p.levelResult!['historias'], 1);
    });

    test('due is PAL.vence over the records as they stand', () {
      final t = clock.now;
      p.put(
        WordRecord(
          w: 'b',
          primera: t,
          ear: SkillRecord(etapa: 2, due: t - 10),
        ),
      );
      p.put(
        WordRecord(
          w: 'a',
          primera: t,
          ear: SkillRecord(etapa: 2, due: t - 20),
        ),
      );
      p.put(
        WordRecord(
          w: 'c',
          primera: t,
          ear: SkillRecord(etapa: 2, due: t + 10),
        ),
      );
      p.put(
        WordRecord(
          w: 'd',
          primera: t,
          ear: SkillRecord(etapa: 2, due: t - 30, aparcada: t + 99),
        ),
      );
      p.put(
        WordRecord(
          w: 'e',
          primera: t,
          ear: SkillRecord(etapa: 0, due: t - 30),
        ),
      );
      expect(p.due(Skill.ear), ['a', 'b']);
      expect(p.due(Skill.ear, at: t + 10), ['a', 'b', 'c']);
      expect(p.due(Skill.mouth), isEmpty);
    });

    test('the rest of the store', () {
      p.listened('d-toc-toc');
      p.listened('d-toc-toc');
      expect((p.raw['oidos'] as Map)['d-toc-toc'], 2);
      expect(p.hasRead('la-lluvia'), isFalse);
      p.markRead('la-lluvia');
      expect(p.hasRead('la-lluvia'), isTrue);
      p.addMinutes(2.5);
      expect(p.minutes, 2.5);
      p.add('the weather');
      expect(p.added, ['the weather']);
      p.setSetting('habla', 0);
      expect(p.setting('habla'), 0);
      expect(p.openForSpeaking('nada'), isFalse);
    });

    test('keeps unknown keys through export and import', () {
      final q = FakeProgressStore(
        clock: clock,
        json: jsonEncode({
          'palabras': {
            'casa': {
              'w': 'casa',
              'primera': 1,
              'oida': 1,
              'futuro': 'x',
              'ear': {'etapa': 1, 'nuevo': 2},
              'mouth': {},
            },
          },
          'dias': {},
          'v': 1,
          'otra': [1, 2],
        }),
      );
      expect(q.raw['ajustes'], {
        'min': 30,
        'todo': 0,
        'bienvenida': 0,
        'habla': 1,
      });
      expect(q.raw['cuentos'], {});
      q.answer('casa', Skill.ear, ok: true);
      final out = jsonDecode(q.export()) as Map<String, dynamic>;
      expect(out['otra'], [1, 2]);
      final casa = (out['palabras'] as Map)['casa'] as Map;
      expect(casa['futuro'], 'x');
      expect((casa['ear'] as Map)['nuevo'], 2);
      expect((casa['ear'] as Map)['n'], 1);
      p.import(q.export());
      expect(p.word('casa')!.ear.n, 1);
      p.reset();
      expect(p.words, isEmpty);
    });

    test('fires changes after every save', () async {
      var n = 0;
      final sub = p.changes.listen((_) => n++);
      p.heard('casa');
      p.add('x');
      await Future<void>.delayed(Duration.zero);
      expect(n, 2);
      unawaited(sub.cancel());
    });
  });

  group('FakeCourseCatalog over the sample course', () {
    final c = FakeCourseCatalog();
    setUpAll(c.load);

    test('La casa and stories 1 to 3', () async {
      expect(c.places.single.id, 'casa');
      expect(c.places.single.scenes, contains('El frente'));
      expect(c.meta('la-lluvia')!.title, 'La lluvia');
      final s = await c.story('la-lluvia');
      expect(s['scene'], 'frente');
      expect(s['next'], 'el-bizcocho');
      expect((await c.story('donde-esta-el-pajaro'))['title'], isNotEmpty);
      expect(() => c.story('el-jugo'), throwsStateError);
    });

    test('the review set, the level items, the call, the book', () async {
      expect(c.pairs, hasLength(12));
      expect(c.pairs.every((p) => p.scene == 'frente'), isTrue);
      expect(c.pairFor('Casa')!.word, 'casa');
      expect(c.pairFor('nada'), isNull);
      expect(
        c.levelItems.map((q) => q.step),
        everyElement(lessThanOrEqualTo(3)),
      );
      expect(c.callFor('casa')!.minutes, 5);
      expect(c.callFor('parque'), isNull);
      final b = (await c.book('la-lluvia'))!;
      expect(b.pages.first.clips, ['esta_casa']);
      expect(await c.book('nada'), isNull);
    });

    test('twenty clips, fixed lines, goodbye words', () {
      final clip = c.clip('esta_casa')!;
      expect(clip.text, 'Esta es la casa de abuela.');
      expect(clip.endMs, 360 * 6 + 300);
      expect(clip.url, 'audio/esta_casa.mp3');
      expect(c.fixedClip('muy_bien'), 'muy_bien');
      expect(() => c.fixedClip('nada'), throwsArgumentError);
      expect(c.goodbyeWords, ['adiós', 'hasta mañana']);
    });

    test('lines a word was heard in (oidoEn)', () async {
      final ls = await c.linesWith('casa', ['la-lluvia', 'el-bizcocho']);
      expect(ls, hasLength(5));
      expect(ls.first.storyId, 'la-lluvia');
      expect(ls.every((l) => normalize(l.text).contains(' casa ')), isTrue);
      expect(ls.map((l) => normalize(l.text)).toSet(), hasLength(5));
      expect(await c.linesWith('casa', ['nada']), isEmpty);
    });

    test('the sample files are the old files, byte for byte (checked by make_sample.mjs); every clip is in a story', () async {
      final texts = <String, String>{};
      for (final id in ['la-lluvia', 'el-bizcocho', 'donde-esta-el-pajaro']) {
        final clips = (await c.story(id))['clips'] as Map<String, dynamic>;
        clips.forEach((k, v) => texts[k] ??= (v as Map)['text'] as String);
      }
      for (final id
          in jsonDecode(await sampleAsset('audio/clips.json')).keys
              as Iterable<String>) {
        expect(texts[id], c.clip(id)!.text);
      }
    });
  });

  group('FakeClipPlayer', () {
    test('records, and plays instantly on the fake clock', () async {
      final clock = FakeClock(0);
      final p = FakeClipPlayer(
        clock: clock,
        lengthOf: (id) => id == 'a' ? 1500 : null,
      );
      expect(await p.play('a'), isTrue);
      expect(clock.now, 1500);
      expect(
        await p.play('a', limit: const Duration(milliseconds: 500)),
        isFalse,
      );
      expect(clock.now, 2000);
      expect(await p.play('b'), isFalse);
      expect(p.played, ['a', 'a', 'b']);
      p.tone(320, dur: .07, vol: .025, toHz: 520);
      p.noiseBurst();
      p.loop('rain', true);
      expect(p.tones.single.toHz, 520);
      expect(p.noises, [1]);
      expect(p.looping, {'rain'});
      p.loop('rain', false);
      expect(p.looping, isEmpty);
      await p.unlock();
      await p.preload(['a']);
      await p.stop();
      expect(
        [p.unlocked, p.preloaded, p.stops],
        [
          true,
          ['a'],
          1,
        ],
      );
    });

    test('without lengths every clip plays', () async {
      expect(await FakeClipPlayer().play('x'), isTrue);
    });
  });

  group('FakeSpeechListener (?mic=stub:)', () {
    testWidgets('results in order, at the stub\'s pace', (tester) async {
      final s = FakeSpeechListener.stub(
        'hola abuela/ola abuela|none|error:not-allowed|error:',
      );
      expect(await s.available(), isTrue);
      SpeechResult? got;
      var ended = false;
      final t = s.listen(locale: 'es-US', limit: const Duration(seconds: 6));
      unawaited(t.result.then((r) => got = r));
      unawaited(t.speechEnd.then((_) => ended = true));
      await tester.pump(const Duration(milliseconds: 299));
      expect(ended, isFalse);
      await tester.pump(const Duration(milliseconds: 2));
      expect(ended, isTrue);
      expect(got, isNull);
      await tester.pump(const Duration(milliseconds: 120));
      expect(got!.alternatives, ['hola abuela', 'ola abuela']);
      expect(got!.msToSound, 120);

      final codes = <String?>[];
      for (var i = 0; i < 4; i++) {
        unawaited(
          s
              .listen(locale: 'es-US', limit: const Duration(seconds: 6))
              .result
              .then((r) => codes.add(r.error)),
        );
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(codes, ['no-speech', 'not-allowed', 'error', 'no-speech']);
      expect(s.listens.first.locale, 'es-US');
      expect(s.used, 5);
    });

    test('cancel ends a turn as aborted; off is not available', () async {
      final t = FakeSpeechListener.stub('hola')
          .listen(locale: 'es-US', limit: const Duration(seconds: 6));
      t.cancel();
      expect((await t.result).error, 'aborted');
      expect(await FakeSpeechListener(isAvailable: false).available(), isFalse);
      final quick = FakeSpeechListener.stub('sí', instant: true);
      expect(
        (await quick.listen(locale: 'es-US', limit: Duration.zero).result)
            .alternatives,
        ['sí'],
      );
    });
  });

  group('FakeCallSession (?callstub=1)', () {
    final brief = CallBrief(
      placeId: 'casa',
      minutes: 5,
      job: 'j',
      opening: 'o',
      photo: 'casa',
    );
    String show(CallEvent e) => switch (e) {
      Connected() => 'connected',
      AgentLine(:final text) => 'danny $text',
      Heard(:final text) => 'heard $text',
      Mode(:final mode) => mode,
      Tool(:final name, :final args) => '$name ${args['picture']}',
      CallError(:final message) => 'error $message',
      Ended(:final reason) => 'ended $reason',
    };

    testWidgets('walks through the stub\'s steps by itself', (tester) async {
      final c = FakeCallSession();
      final seen = <String>[];
      final sub = c.events.listen((e) => seen.add(show(e)));
      var started = false;
      unawaited(
        c.start(brief, {'place': 'La casa'}).then((_) => started = true),
      );
      await tester.pump();
      expect(started, isTrue);
      expect(c.variables, {'place': 'La casa'});
      await tester.pump(const Duration(seconds: 30));
      expect(seen, [
        'connected',
        'speaking',
        'danny ¡Hola! Soy Danny. ¿Cómo estás?',
        'listening',
        'heard Hola. Bien, gracias.',
        'speaking',
        'danny Eso. Mira. ¿Quieres jugo?',
        'show_picture jugo',
        'listening',
        'heard Sí, quiero jugo.',
        'listening',
        'heard Adiós.',
      ]);
      c.send('(fin)');
      await tester.pump(const Duration(seconds: 3));
      expect(seen.sublist(12), [
        'speaking',
        'danny Eso. Hasta mañana.',
        'listening',
      ]);
      await c.end();
      await tester.pump(const Duration(milliseconds: 40));
      expect(seen.last, 'ended user');
      expect(c.sent, ['(fin)']);
      c.dispose();
      unawaited(sub.cancel());
    });

    testWidgets('manual, mic and fail', (tester) async {
      final m = FakeCallSession(stub: {'manual', 'hasta'});
      final seen = <String>[];
      final sub = m.events.listen((e) => seen.add(show(e)));
      unawaited(m.start(brief, {}));
      await tester.pump(const Duration(seconds: 5));
      expect(seen, isEmpty);
      for (final n in ['connect', 'you3', 'talk3', 'heard3', 'end', 'danny1']) {
        m.go(n);
      }
      await tester.pump();
      expect(seen, [
        'connected',
        'listening',
        'heard Hasta mañana.',
        'ended agent',
      ]);
      expect(m.names, contains('danny2'));
      unawaited(sub.cancel());

      final talking = FakeCallSession(stub: {'manual'});
      talking.go('talk1');
      expect(talking.inputVolume(), greaterThan(.1));
      talking.go('danny1');
      expect(talking.outputVolume(), greaterThan(0));

      for (final o in ['mic', 'fail']) {
        Object? err;
        unawaited(
          FakeCallSession(stub: {o})
              .start(brief, {})
              .catchError((Object e) => err = e),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(
          err.toString(),
          o == 'mic' ? contains('NotAllowedError') : contains('did not start'),
        );
      }
    });
  });

  group('FakePictureSource', () {
    final ref = PictureRef(scene: 'frente', cam: [52, 8, 180, 96]);

    testWidgets('a labelled grey box the size of the picture', (tester) async {
      final p = FakePictureSource();
      await tester.pumpWidget(Center(child: p.of(ref, scale: 2)));
      expect(find.text('frente 52,8,180,96'), findsOneWidget);
      expect(tester.getSize(find.byType(SizedBox).first), const Size(392, 208));
      await p.warm([ref]);
      expect([p.shown.length, p.warmed.length], [1, 1]);
    });

    testWidgets('a saved frame replaces the box, callers unchanged', (
      tester,
    ) async {
      final p = FakePictureSource(
        frames: (r, {required height, scale}) =>
            Text('frame of ${r.scene}', textDirection: TextDirection.ltr),
      );
      await tester.pumpWidget(Center(child: p.of(ref)));
      expect(find.text('frame of frente'), findsOneWidget);
    });
  });

  group('fakeServices', () {
    test('wires every fake, one clock, one store a space', () async {
      final s = fakeServices();
      expect(s.progress, isA<FakeProgressStore>());
      expect(s.course, isA<FakeCourseCatalog>());
      expect(s.clips, isA<FakeClipPlayer>());
      expect(s.speech, isA<FakeSpeechListener>());
      expect(s.call, isA<FakeCallSession>());
      expect(s.nav, isA<FakeNavigator>());
      expect(s.clock, isA<FakeClock>());
      expect(s.rng, isA<FakeRng>());
      expect(s.haptics, isA<FakeHaptics>());
      expect(s.info, isA<FakeAppInfo>());
      expect(s.pictures, isA<FakePictureSource>());
      expect(identical(s.storage('leer'), s.storage('leer')), isTrue);
      expect(identical(s.storage('leer'), s.storage('juego')), isFalse);
      expect(s.reduceMotion, isFalse);

      await s.course.load();
      final t0 = s.clock.nowMs();
      expect(await s.clips.play('esta_casa'), isTrue);
      expect(s.clock.nowMs() - t0, 2460);
      s.progress.heard('casa');
      expect(s.progress.word('casa')!.primera, s.clock.nowMs());
    });

    test('takes what it is given', () {
      final nav = FakeNavigator();
      final s = fakeServices(nav: nav, reduceMotion: true);
      expect(identical(s.nav, nav), isTrue);
      expect(s.reduceMotion, isTrue);
    });
  });

  group('FeatureDevApp', () {
    testWidgets('shows the module\'s tab, or its screen for a route', (
      tester,
    ) async {
      await tester.pumpWidget(
        FeatureDevApp(module: _Module(), services: fakeServices()),
      );
      expect(find.text('the tab'), findsOneWidget);
      await tester.pumpWidget(
        FeatureDevApp(
          module: _Module(),
          services: fakeServices(),
          route: const BookRoute('la-lluvia'),
        ),
      );
      expect(find.text('book la-lluvia'), findsOneWidget);
    });
  });
}
