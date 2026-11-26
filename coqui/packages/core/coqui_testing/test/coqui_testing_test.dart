import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
      expect(
        [clip.startMs, clip.endMs],
        [193, 2041],
      ); // historia/audio/marcas.json
      expect(clip.url, 'audio/esta_casa.mp3');
      expect(c.fixedClip('story_praise'), 'muy_bien');
      expect(c.fixedClip('story_your_turn'), 'ahora_tu');
      expect(FakeCourseCatalog(fixedClips: {'x': 'y'}).fixedClip('x'), 'y');
      expect(() => c.fixedClip('nada'), throwsArgumentError);
      expect(c.goodbyeWords, ['adiós', 'hasta mañana']);
    });

    test('Repaso\'s games: none in the sample; given, or read from datos/repaso.json', () async {
      expect(c, isA<RepasoCatalog>());
      expect(c.repaso, isNull);
      final given = RepasoData(sentences: [], words: []);
      expect(FakeCourseCatalog(repaso: given).repaso, same(given));
      final read = FakeCourseCatalog(
        fetch: (path) => path == 'datos/repaso.json'
            ? Future.value('{"v":1,"frases":[],"palabras":[]}')
            : sampleFile(path),
      );
      await read.load();
      expect(read.repaso!.words, isEmpty);
    });

    test('lines a word was heard in (oidoEn)', () async {
      final ls = await c.linesWith('casa', ['la-lluvia', 'el-bizcocho']);
      expect(ls, hasLength(5));
      expect(ls.first.storyId, 'la-lluvia');
      expect(ls.every((l) => normalize(l.text).contains(' casa ')), isTrue);
      expect(ls.map((l) => normalize(l.text)).toSet(), hasLength(5));
      expect(await c.linesWith('casa', ['nada']), isEmpty);
    });

    test(
      'the sample files are the files in sample/, and every clip is in a story',
      () async {
        final onDisk = [
          for (final f in Directory(
            'sample',
          ).listSync(recursive: true).whereType<File>())
            f.path.substring('sample/'.length),
        ]..sort();
        expect(sampleFiles.keys.toList()..sort(), onDisk);
        for (final p in onDisk) {
          expect(
            sampleFiles[p],
            File('sample/$p').readAsStringSync(),
            reason: p,
          );
        }
        final texts = <String, String>{};
        for (final id in ['la-lluvia', 'el-bizcocho', 'donde-esta-el-pajaro']) {
          final clips = (await c.story(id))['clips'] as Map<String, dynamic>;
          clips.forEach((k, v) => texts[k] ??= (v as Map)['text'] as String);
        }
        final ids = (jsonDecode(
          await sampleFile('audio/marcas.json'),
        ) as Map<String, dynamic>).keys;
        expect(ids, hasLength(20));
        for (final id in ids) {
          expect(texts[id], c.clip(id)!.text);
        }
      },
    );
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
      expect(await p.preload(['a']), isEmpty);
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

    test('preload gives back the clips that are not ready', () async {
      final p = FakeClipPlayer(lengthOf: (id) => id == 'none' ? null : 900);
      expect(p.failing, isEmpty);
      expect(await p.preload(['a', 'b']), isEmpty);
      expect(await p.preload([]), isEmpty);
      // A clip with no ClipInfo (lengthOf gives null), once, where it first stands.
      expect(await p.preload(['b', 'none', 'a', 'none', 'b']), ['none']);
      // Clips told to fail: in the order given, no duplicates, whatever else is asked for.
      p.failing = {'a', 'b', 'c'};
      expect(await p.preload(['c', 'none', 'ok', 'a', 'c', 'b', 'a']), [
        'c',
        'none',
        'a',
        'b',
      ]);
      // A retry gives what the set holds then.
      p.failing.remove('a');
      p.failing.remove('c');
      expect(await p.preload(['a', 'b', 'c']), ['b']);
      p.failing = {};
      expect(await p.preload(['a', 'b', 'c']), isEmpty);
      // Every call is recorded as it came, duplicates and all.
      expect(p.preloaded, [
        ...['a', 'b'],
        ...['b', 'none', 'a', 'none', 'b'],
        ...['c', 'none', 'ok', 'a', 'c', 'b', 'a'],
        ...['a', 'b', 'c'],
        ...['a', 'b', 'c'],
      ]);
      // An iterable that can be read once.
      expect(await p.preload(['none', 'a'].map((id) => id)), ['none']);
    });

    test('without lengths nothing is unknown; only the failing fail', () async {
      final p = FakeClipPlayer()..failing = {'y'};
      expect(await p.preload(['x', 'y', 'y', 'x']), ['y']);
      expect(p.played, isEmpty);
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

      for (final (o, kind, text) in [
        (
          'mic',
          CallStartFailure.microphone,
          'NotAllowedError: Permission denied',
        ),
        ('fail', CallStartFailure.failed, 'Error: The call did not start.'),
        (
          'library',
          CallStartFailure.library,
          'LibraryError: The voice library did not load.',
        ),
        (
          'unavailable',
          CallStartFailure.unavailable,
          'NotAvailable: Calls are off on this build.',
        ),
      ]) {
        Object? err;
        unawaited(
          FakeCallSession(stub: {o})
              .start(brief, {})
              .catchError((Object e) => err = e),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(err, isA<CallStartError>().having((e) => e.kind, 'kind', kind));
        expect('$err', text);
      }
      Object? off;
      unawaited(
        FakeCallSession(available: false)
            .start(brief, {})
            .catchError((Object e) => off = e),
      );
      await tester.pump();
      expect((off! as CallStartError).kind, CallStartFailure.unavailable);
    });
  });

  group('FakePictureSource', () {
    final ref = PictureRef(scene: 'frente', cam: [52, 8, 180, 96]);

    void phone(WidgetTester tester, double dpr) {
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = const Size(800, 800) * dpr;
      addTearDown(tester.view.reset);
    }

    // no limit on the width: the picture takes its own width in logical pixels
    Widget unlimited(Widget picture) => UnconstrainedBox(child: picture);

    Size boxOf(WidgetTester tester) =>
        tester.getSize(find.byType(ColoredBox).first);

    testWidgets('a labelled grey box the size of the picture', (tester) async {
      phone(tester, 1);
      final p = FakePictureSource();
      await tester.pumpWidget(unlimited(p.of(ref)));
      expect(find.text('frente 52,8,180,96'), findsOneWidget);
      expect(boxOf(tester), const Size(196, 104));
      await tester.pumpWidget(unlimited(p.of(ref, width: 96, height: 106)));
      expect(boxOf(tester), const Size(96, 106));
      await p.warm([ref]);
      expect([p.shown.length, p.warmed.length], [2, 1]);
    });

    testWidgets(
      'it is laid out as PixelView is: whole device pixels per picture pixel, a tight box filled',
      (tester) async {
        final p = FakePictureSource();
        phone(tester, 2.625);
        // no limit: the whole number of device pixels the picture's own width holds (2 of 2.625)
        await tester.pumpWidget(unlimited(p.of(ref)));
        expect(boxOf(tester), const Size(196 * 2 / 2.625, 104 * 2 / 2.625));
        // a box of 3 device pixels per picture pixel
        await tester.pumpWidget(
          Center(
            child: SizedBox(width: 196 * 3 / 2.625, child: p.of(ref)),
          ),
        );
        expect(boxOf(tester).width, closeTo(196 * 3 / 2.625, 1e-9));
        expect(boxOf(tester).height, closeTo(104 * 3 / 2.625, 1e-9));
        // the width a column gives it: 5 whole device pixels per picture pixel hold in 980 device pixels
        await tester.pumpWidget(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 980 / 2.625, child: p.of(ref)),
          ),
        );
        expect(boxOf(tester).width, closeTo(980 / 2.625, 1e-9));
        expect(boxOf(tester).height, closeTo(104 * 5 / 2.625, 1e-9));
        // the width given by [width]: a cell of 96 x 106
        await tester.pumpWidget(unlimited(p.of(ref, width: 96, height: 106)));
        expect(boxOf(tester), const Size(96 * 2 / 2.625, 106 * 2 / 2.625));
        // a tight box is filled (the caller sizes the box, not the picture)
        await tester.pumpWidget(
          Center(child: SizedBox(width: 300, height: 120, child: p.of(ref))),
        );
        expect(boxOf(tester), const Size(300, 120));
        // a box too narrow for one device pixel per picture pixel is not scaled below 1, it is clipped to
        await tester.pumpWidget(
          Center(child: SizedBox(width: 50, child: p.of(ref))),
        );
        expect(boxOf(tester).width, 50);
      },
    );

    testWidgets('a picture with a name shows it above the scene and camera', (
      tester,
    ) async {
      phone(tester, 1);
      final p = FakePictureSource();
      final named = PictureRef(
        scene: 'frente',
        cam: [52, 8, 180, 96],
        name: 'abuela.si',
      );
      await tester.pumpWidget(unlimited(p.of(named)));
      expect(find.text('abuela.si'), findsOneWidget);
      expect(find.text('frente 52,8,180,96'), findsOneWidget);
      await tester.pumpWidget(unlimited(p.of(ref)));
      expect(find.text('abuela.si'), findsNothing);
      expect(find.text('frente 52,8,180,96'), findsOneWidget);
    });

    testWidgets('a saved frame replaces the box, callers unchanged', (
      tester,
    ) async {
      phone(tester, 1);
      int? asked;
      final p = FakePictureSource(
        frames: (r, {required width, required height}) {
          asked = width * 1000 + height;
          return Text('frame of ${r.scene}', textDirection: TextDirection.ltr);
        },
      );
      await tester.pumpWidget(Center(child: p.of(ref, width: 96, height: 106)));
      expect(find.text('frame of frente'), findsOneWidget);
      expect(asked, 96106);
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
      expect(s.clock.nowMs() - t0, 2041 - 193);
      s.progress.heard('casa');
      expect(s.progress.word('casa')!.primera, s.clock.nowMs());
    });

    test('its clip player does not have a clip the course lacks', () async {
      final s = fakeServices();
      await s.course.load();
      expect(
        await s.clips.preload(['esta_casa', 'nada', 'esta_casa', 'nada']),
        ['nada'],
      );
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

  group('FakeCourseCatalog Spanish language parity', () {
    test('defaults to Language.spanish and wires spanishCallAgentId', () async {
      final c = FakeCourseCatalog();
      expect(c, isA<LanguageCatalog>());
      expect(c.language, Language.spanish);
      final CourseCatalog asCourse = c;
      expect(asCourse.language, Language.spanish);
      await c.load();
      expect(c.callFor('casa')!.agentId, spanishCallAgentId);
      expect(fakeServices().course.language, Language.spanish);
    });
  });

  group('FakeCourseCatalog.arabic()', () {
    final es = FakeCourseCatalog();
    final ar = FakeCourseCatalog.arabic();
    setUpAll(() async {
      await es.load();
      await ar.load();
    });

    test('exposes arabicTestLanguage metadata and chrome keys', () {
      expect(ar, isA<LanguageCatalog>());
      expect(ar.language, arabicTestLanguage);
      final CourseCatalog asCourse = ar;
      expect(asCourse.language, arabicTestLanguage);
      expect(ar.language.direction, LanguageDirection.rtl);
      expect(ar.language.script, 'Arab');
      expect(ar.language.code, 'ar');
      expect(ar.language.partnerName, 'Tariq');
      expect(ar.language.callAgentId, 'agent_arabic_test');
      expect(ar.language.tabNames.keys, unorderedEquals(languageTabKeys));
      expect(ar.language.micWords.keys, unorderedEquals(languageMicKeys));
    });

    test('preserves Spanish sample places and stories structure', () async {
      expect(ar.places.single.id, 'casa');
      expect(ar.places.single.name, 'البيت');
      expect(ar.places.single.stories, es.places.single.stories);
      expect(ar.meta('la-lluvia')!.title, 'المطر');
      expect(ar.meta('el-bizcocho')!.title, 'الكعكة');
      expect(ar.meta('donde-esta-el-pajaro')!.title, 'أين الطائر؟');
      final s = await ar.story('la-lluvia');
      expect(s['scene'], 'frente');
      expect(s['next'], 'el-bizcocho');
      expect((await ar.book('la-lluvia'))!.title, 'المطر');
    });

    test('overlays Arabic clip texts while keeping audio marks and roles', () {
      final clip = ar.clip('esta_casa')!;
      expect(clip.text, 'هذا بيت جدة.');
      expect([clip.startMs, clip.endMs], [193, 2041]);
      expect(ar.fixedClip('story_praise'), 'muy_bien');
      expect(ar.clip('muy_bien')!.text, 'ممتاز!');
      expect(ar.goodbyeWords, ['وداعاً', 'إلى الغد']);
    });

    test('uses Arabic call brief with arabicTestLanguage.callAgentId', () {
      final call = ar.callFor('casa')!;
      expect(call.agentId, 'agent_arabic_test');
      expect(call.photo, 'بيت');
      expect(ar.pairFor(call.photo!), isNotNull);
    });

    test('uses Arabic normalize, tokens, pairFor and linesWith', () async {
      expect(ar.pairFor('بيت')!.word, 'بيت');
      // Alef folding via language.normalize: ا matches أ.
      expect(ar.pairFor('اغلق')!.word, 'أغلق');
      // Diacritic stripping via language.normalize: مرحبا matches مرحباً.
      expect(ar.pairFor('مرحبا')!.word, 'مرحباً');

      final lines = await ar.linesWith('بيت', [
        'la-lluvia',
        'el-bizcocho',
        'donde-esta-el-pajaro',
      ]);
      expect(lines, isNotEmpty);
      expect(
        lines.every((l) => ar.language.normalize(l.text).contains(' بيت ')),
        isTrue,
      );

      expect(ar.language.tokens('هذا بيت جدة.'), const [
        WordToken('هذا', 0, 3),
        WordToken('بيت', 4, 7),
        WordToken('جدة', 8, 11),
      ]);
    });

    test('wires cleanly into fakeServices', () async {
      final s = fakeServices(course: FakeCourseCatalog.arabic());
      expect(s.course.language.direction, LanguageDirection.rtl);
      await s.course.load();
      final t0 = s.clock.nowMs();
      expect(await s.clips.play('esta_casa'), isTrue);
      expect(s.clock.nowMs() - t0, 2041 - 193);
    });
  });

  group('FakeEntitlements', () {
    test('defaults to Plan.courseAndCalls with empty prices/minutes/logs', () {
      final e = FakeEntitlements();
      expect(e.plan, Plan.courseAndCalls);
      for (final f in Feature.values) {
        expect(e.has(f), isTrue, reason: 'feature $f');
      }
      for (final p in Plan.values) {
        expect(e.priceOf(p), isNull, reason: 'priceOf $p');
        expect(e.callMinutes(p), isNull, reason: 'callMinutes $p');
      }
      expect(e.bought, isEmpty);
      expect(e.restores, 0);
      e.dispose();
    });

    test('gates every (Plan, Feature) combination accurately', () {
      final e = FakeEntitlements(plan: Plan.free);
      expect(e.has(Feature.everyPlace), isFalse);
      expect(e.has(Feature.library), isFalse);
      expect(e.has(Feature.calls), isFalse);

      e.plan = Plan.course;
      expect(e.has(Feature.everyPlace), isTrue);
      expect(e.has(Feature.library), isTrue);
      expect(e.has(Feature.calls), isFalse);

      e.plan = Plan.courseAndCalls;
      expect(e.has(Feature.everyPlace), isTrue);
      expect(e.has(Feature.library), isTrue);
      expect(e.has(Feature.calls), isTrue);
      e.dispose();
    });

    test(
      'emits on changes when plan changes and handles dispose safely',
      () async {
        final e = FakeEntitlements(plan: Plan.free);
        var events = 0;
        var done = false;
        final sub = e.changes.listen(
          (_) => events++,
          onDone: () => done = true,
        );

        e.plan = Plan.free;
        e.plan = Plan.course;
        e.plan = Plan.course;
        e.plan = Plan.courseAndCalls;
        await Future<void>.delayed(Duration.zero);
        expect(events, 2);

        e.dispose();
        await Future<void>.delayed(Duration.zero);
        expect(done, isTrue);

        expect(() => e.plan = Plan.free, returnsNormally);
        expect(e.plan, Plan.free);
        unawaited(sub.cancel());
      },
    );

    test('returns configured and mutated prices and call minutes', () {
      final e = FakeEntitlements(
        prices: {Plan.course: '\$9.99/mo'},
        minutes: {Plan.courseAndCalls: 60},
      );
      expect(e.priceOf(Plan.free), isNull);
      expect(e.priceOf(Plan.course), '\$9.99/mo');
      expect(e.priceOf(Plan.courseAndCalls), isNull);
      expect(e.callMinutes(Plan.free), isNull);
      expect(e.callMinutes(Plan.course), isNull);
      expect(e.callMinutes(Plan.courseAndCalls), 60);

      e.prices[Plan.courseAndCalls] = '\$19.99/mo';
      e.minutes[Plan.course] = 0;
      expect(e.priceOf(Plan.courseAndCalls), '\$19.99/mo');
      expect(e.callMinutes(Plan.course), 0);
      e.dispose();
    });

    test('records buy and restore without mutating plan', () async {
      final e = FakeEntitlements(plan: Plan.free);
      await e.buy(Plan.course);
      await e.buy(Plan.courseAndCalls);
      await e.restore();
      await e.restore();

      expect(e.bought, [Plan.course, Plan.courseAndCalls]);
      expect(e.restores, 2);
      expect(e.plan, Plan.free);
      e.dispose();
    });
  });

  group('fakeServices entitlements and multi-language wiring (#181)', () {
    test('defaults to FakeEntitlements and matches course language', () {
      final s = fakeServices();
      expect(s.entitlements, isA<FakeEntitlements>());
      expect(s.entitlements.plan, Plan.courseAndCalls);
      expect(s.progressStores, isNull);
      expect(s.availableCourses, isEmpty);
      expect(s.progress.language, Language.spanish);

      final ar = fakeServices(course: FakeCourseCatalog.arabic());
      expect(ar.progress.language, arabicTestLanguage);
    });

    test('accepts custom entitlements and availableCourses', () {
      final entitlements = FakeEntitlements(plan: Plan.free);
      final courses = <CourseCatalog>[
        FakeCourseCatalog(),
        FakeCourseCatalog.arabic(),
      ];
      final s = fakeServices(
        entitlements: entitlements,
        availableCourses: courses,
      );
      expect(identical(s.entitlements, entitlements), isTrue);
      expect(s.entitlements.plan, Plan.free);
      expect(s.availableCourses, same(courses));
      entitlements.dispose();
    });
  });

  group('FakeProgressStore CallProgressStore and LanguageProgressStore', () {
    test('tracks completed calls idempotently and ignores blanks', () {
      final clock = FakeClock(0);
      final store = FakeProgressStore(clock: clock);
      final ProgressStore asBase = store;
      expect(store, isA<CallProgressStore>());
      expect(asBase.callDone('casa'), isFalse);

      final savesBefore = store.saves;
      asBase.markCallDone('');
      asBase.markCallDone('   ');
      expect(store.saves, savesBefore);
      expect(asBase.callDone(''), isFalse);

      // Works even when clock is 0 and stays idempotent.
      asBase.markCallDone('casa');
      expect(asBase.callDone('casa'), isTrue);
      expect(store.saves, savesBefore + 1);

      asBase.markCallDone('casa');
      expect(store.saves, savesBefore + 1);

      // Persists across export/import and clears on reset.
      final exported = store.export();
      final restored = FakeProgressStore(json: exported);
      expect(restored.callDone('casa'), isTrue);
      expect(restored.callDone('casa_agua'), isFalse);

      restored.reset();
      expect(restored.callDone('casa'), isFalse);
    });

    test('exposes language, stageMax, streakFreezes, and minutesOn', () {
      final day1 = DateTime.utc(2026, 5, 1, 10);
      final day2 = DateTime.utc(2026, 5, 2, 15);
      final clock = FakeClock(day1.millisecondsSinceEpoch);
      final store = FakeProgressStore(
        clock: clock,
        language: arabicTestLanguage,
        streakFreezes: 2,
      );
      final ProgressStore asBase = store;
      expect(store, isA<LanguageProgressStore>());
      expect(asBase.language, arabicTestLanguage);
      expect(asBase.stageMax, 4);
      expect(asBase.streakFreezes, 2);
      expect(asBase.minutesOn(day1), 0);

      store.addMinutes(3.5);
      store.addMinutes(1.5);
      clock.now = day2.millisecondsSinceEpoch;
      store.addMinutes(4.0);

      expect(asBase.minutesOn(day1), 5.0);
      expect(asBase.minutesOn(day2), 4.0);
      expect(asBase.minutesOn(DateTime.utc(2026, 5, 3)), 0);

      store.reset();
      expect(asBase.minutesOn(day1), 0);
      expect(asBase.minutesOn(day2), 0);
    });
  });

  group('FakeCourseCatalog CallsCatalog and MinAppCatalog', () {
    test(
      'exposes single-object sample call via callsFor and default null minApp',
      () async {
        final cat = FakeCourseCatalog();
        final CourseCatalog asBase = cat;
        expect(cat, isA<CallsCatalog>());
        expect(cat, isA<MinAppCatalog>());
        await cat.load();
        expect(asBase.minApp, isNull);
        expect(asBase.callsFor('casa'), hasLength(1));
        expect(asBase.callsFor('casa').single.id, cat.callFor('casa')!.id);
        expect(asBase.callsFor('unknown'), isEmpty);
      },
    );

    test('parses multi-call arrays and curso.json minApp', () async {
      final cat = FakeCourseCatalog(
        fetch: (path) async {
          if (path == 'datos/curso.json') {
            final base =
                jsonDecode(await sampleFile(path)) as Map<String, dynamic>;
            base['minApp'] = 42;
            return jsonEncode(base);
          }
          if (path == 'datos/llamadas.json') {
            return jsonEncode({
              'casa': [
                {
                  'id': 'casa_agua',
                  'title': 'Pedir agua',
                  'minutos': 2,
                  'job': 'ask for water',
                  'opening': 'Hola',
                  'isMain': false,
                },
                {
                  'id': 'casa_main',
                  'title': 'Visita',
                  'minutos': 3,
                  'job': 'visit',
                  'opening': 'Pasa',
                  'isMain': true,
                },
              ],
            });
          }
          return sampleFile(path);
        },
      );
      await cat.load();
      final CourseCatalog asBase = cat;
      expect(asBase.minApp, 42);
      expect(asBase.minAppFor('la-lluvia'), 42);
      expect(asBase.callsFor('casa').map((c) => c.id), [
        'casa_agua',
        'casa_main',
      ]);
      expect(cat.callFor('casa')!.id, 'casa_main');

      final override = FakeCourseCatalog(minApp: 99);
      await override.load();
      expect(override.minApp, 99);
    });
  });

  group('FakeClipPlayer VariableSpeedClipPlayer', () {
    test('records playback rates and scales fake clock duration', () async {
      final clock = FakeClock(1000);
      final player = FakeClipPlayer(clock: clock, lengthOf: (_) => 1000);
      final ClipPlayer asBase = player;
      expect(player, isA<VariableSpeedClipPlayer>());
      expect(player.lastRate, isNull);

      expect(await asBase.play('c1'), isTrue);
      expect(clock.nowMs(), 2000);
      expect(await asBase.playAtRate('c2', rate: 0.5), isTrue);
      expect(clock.nowMs(), 4000);
      expect(
        await asBase.playAtRate(
          'c3',
          rate: 0.5,
          limit: const Duration(milliseconds: 700),
        ),
        isFalse,
      );
      expect(clock.nowMs(), 4700);

      expect(player.played, ['c1', 'c2', 'c3']);
      expect(player.playedRates, [1.0, 0.5, 0.5]);
      expect(player.lastRate, 0.5);

      for (final bad in [0.0, -0.5, double.nan, double.infinity]) {
        expect(() => player.playAtRate('c1', rate: bad), throwsArgumentError);
      }
    });
  });
}
