// The shell's parts that need no screen: the addresses, the address switches, the cache rules, the scripted
// recogniser, the voice test's file.
import 'package:app/src/addresses.dart';
import 'package:app/src/content.dart';
import 'package:app/src/modules.dart';
import 'package:app/src/scripted_speech.dart';
import 'package:app/src/switches.dart';
import 'package:app/src/voice_test_data.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_speaking/feature_speaking.dart';
import 'package:feature_story/feature_story.dart' show TxtMode;
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  group('addresses', () {
    const routes = <AppRoute>[
      TabRoute('library'),
      TabRoute('words'),
      TabRoute('map'),
      TabRoute('speak'),
      TabRoute('me'),
      StoryRoute('la-lluvia'),
      StoryRoute('la-lluvia', listen: true),
      ReviewRoute(),
      ReviewRoute(practice: true),
      LevelCheckRoute(),
      BookRoute('el-bizcocho'),
      CallRoute('casa'),
      VoiceTestRoute(),
    ];
    test(
      'each route has one address, and the address gives the route back',
      () {
        final seen = <String>{};
        for (final r in routes) {
          final a = addressOf(r);
          expect(seen.add(a), isTrue, reason: a);
          expect(routeOf(Uri.parse(a)), r, reason: a);
        }
        expect(
          addressOf(const StoryRoute('la-lluvia', listen: true)),
          '/cuento/la-lluvia?oir=1',
        );
        expect(addressOf(const CallRoute('casa')), '/llamada/casa');
        expect(addressOf(const VoiceTestRoute()), '/prueba-voz');
      },
    );
    test('anything else names no route', () {
      for (final a in [
        '/',
        '',
        '/tab',
        '/tab/mapa',
        '/cuento',
        '/cuento/La-Lluvia',
        '/cuento/a/b',
        '/repaso/x',
        '/x',
      ]) {
        expect(routeOf(Uri.parse(a)), isNull, reason: a);
      }
    });
  });

  group('the address switches', () {
    test('none: nothing on', () {
      final s = AppSwitches.fromQuery(const {});
      expect(
        (s.perf, s.callStub, s.stubClock, s.micStub, s.micOff, s.txt),
        (false, false, 1, null, false, TxtMode.con),
      );
      expect(s.stubOptions, isEmpty);
    });
    test('as the old pages read them', () {
      final s = AppSwitches.fromQuery(const {
        'perf': '1',
        'callstub': '1',
        'stub': 'manual,nofin',
        'clock': '20',
        'mic': 'stub:hola abuela/ola abuela|none|error:not-allowed',
      });
      expect(s.perf, isTrue);
      expect(s.callStub, isTrue);
      expect(s.stubOptions, {'manual', 'nofin'});
      expect(s.stubClock, 20);
      expect(s.micStub, [
        'hola abuela/ola abuela',
        'none',
        'error:not-allowed',
      ]);
      expect(AppSwitches.fromQuery(const {'mic': 'off'}).micOff, isTrue);
      expect(AppSwitches.fromQuery(const {'callstub': '2'}).callStub, isFalse);
      expect(AppSwitches.fromQuery(const {'clock': 'x'}).stubClock, 1);
      expect(AppSwitches.fromQuery(const {'clock': '0'}).stubClock, 1);
    });
    test(
      '?txt= is con, tras or no, and con for anything else (juego.js: TXT)',
      () {
        expect(AppSwitches.fromQuery(const {}).txt, TxtMode.con);
        expect(AppSwitches.fromQuery(const {'txt': 'con'}).txt, TxtMode.con);
        expect(AppSwitches.fromQuery(const {'txt': 'tras'}).txt, TxtMode.tras);
        expect(AppSwitches.fromQuery(const {'txt': 'no'}).txt, TxtMode.no);
        for (final other in ['', 'NO', 'si', 'tras ', '1']) {
          expect(
            AppSwitches.fromQuery({'txt': other}).txt,
            TxtMode.con,
            reason: '"$other"',
          );
        }
      },
    );
  });

  group('the content base and the cache rules', () {
    test(
      '../historia/ from the app, on the live site and on a local server',
      () {
        expect(
          contentBaseOf(
            Uri.parse('https://salimocasio-dev.github.io/field-notes/app/'),
          ).toString(),
          'https://salimocasio-dev.github.io/field-notes/historia/',
        );
        expect(
          contentBaseOf(Uri.parse('http://127.0.0.1:8123/field-notes/app/'))
              .toString(),
          'http://127.0.0.1:8123/field-notes/historia/',
        );
      },
    );
    test('each file as the old pages ask for it', () {
      final base = Uri.parse('http://h/field-notes/historia/');
      String ask(String p) {
        final r = contentRequest(base, p);
        return '${r.url}${r.noStore ? ' no-store' : ''}';
      }

      expect(
        ask('audio/ready.json'),
        'http://h/field-notes/historia/audio/ready.json no-store',
      );
      expect(
        ask('audio/marcas.json'),
        'http://h/field-notes/historia/audio/marcas.json no-store',
      );
      expect(
        ask('datos/curso.json'),
        'http://h/field-notes/historia/datos/curso.json no-store',
      );
      expect(
        ask('cuentos/la-lluvia.json'),
        'http://h/field-notes/historia/cuentos/la-lluvia.json no-store',
      );
      expect(
        ask('libros/la-lluvia.json'),
        'http://h/field-notes/historia/libros/la-lluvia.json?v=39',
      );
      expect(
        bookImageUrl(base, 'img/la-lluvia-1.png'),
        'http://h/field-notes/historia/libros/img/la-lluvia-1.png?v=39',
      );
      // a clip: the catalog's url, resolved by the clip player against the base
      expect(
        base.resolve('audio/esta_casa.mp3?v=7').toString(),
        'http://h/field-notes/historia/audio/esta_casa.mp3?v=7',
      );
    });
  });

  testWidgets(
    'the scripted recogniser keeps the old stub\'s results and pace',
    (tester) async {
      final l = ScriptedSpeechListener([
        'hola abuela/ola abuela',
        'none',
        'error:not-allowed',
        '',
      ]);
      final got = <String>[];
      for (var i = 0; i < 5; i++) {
        final t = l.listen(locale: 'es-US', limit: const Duration(seconds: 6));
        var ended = false;
        t.speechEnd.then((_) => ended = true);
        t.result.then(
          (r) => got.add(
            '${r.alternatives.join('/')}|${r.error}|${r.msToSound}|$ended',
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(got, hasLength(i), reason: 'nothing before 100 ms');
        await tester.pump(const Duration(seconds: 1));
      }
      expect(got, [
        'hola abuela/ola abuela|null|120|true',
        '|no-speech|null|true',
        '|not-allowed|null|true',
        '|no-speech|null|true',
        '|no-speech|null|true',
      ]);
      final c = l.listen(locale: 'es-US', limit: const Duration(seconds: 6));
      String? err;
      c.result.then((r) => err = r.error);
      c.cancel();
      await tester.pump();
      expect(err, 'aborted');
      expect(
        await ScriptedSpeechListener(const [], off: true).available(),
        isFalse,
      );
      expect(await ScriptedSpeechListener(const []).available(), isTrue);
    },
  );

  test(
    'the voice test\'s file: twelve lines and the seven words around them',
    () {
      final v = VoiceTestData.parse(repoFile('historia/datos/prueba-voz.json'));
      expect(v.lines, hasLength(12));
      expect(v.lines.first.text, 'Hola, abuela');
      expect(
        [for (final t in v.lines.first.targets) t.word],
        ['hola', 'abuela'],
      );
      expect(v.lines[9].hint, 'tu nombre');
      expect(v.lines.last.targets.last.forms, ['tres', '3']);
      expect(v.labels.keys, VoiceTestData.labelNames);
      expect(v.labels['listening'], 'Escuchando…');
      expect(() => VoiceTestData.parse('{"lines": []}'), throwsFormatException);
    },
  );
  test('the voice test\'s content is the file, line for line, and the module has it only when the file was read', () {
    final file = VoiceTestData.parse(
      repoFile('historia/datos/prueba-voz.json'),
    );
    final content = voiceTestContent(file);
    expect(content.lines, hasLength(file.lines.length));
    for (var i = 0; i < file.lines.length; i++) {
      final a = file.lines[i], b = content.lines[i];
      expect(b.text, a.text, reason: 'line $i');
      expect(b.hint, a.hint, reason: 'line $i');
      expect(
        [for (final t in b.targets) (t.word, t.forms)],
        [for (final t in a.targets) (t.word, t.forms)],
        reason: 'line $i',
      );
    }
    expect({
      'listening': content.labels.listening,
      'processing': content.labels.processing,
      'unavailable': content.labels.unavailable,
      'again': content.labels.again,
      'mic': content.labels.mic,
      'next': content.labels.next,
      'progress': content.labels.progress,
    }, file.labels);
    expect(
      (speakingModule(voiceTest: file) as SpeakingModule).voiceTest,
      isNotNull,
    );
    expect((speakingModule() as SpeakingModule).voiceTest, isNull);
  });
}
