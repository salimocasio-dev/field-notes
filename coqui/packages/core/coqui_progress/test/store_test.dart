// What PalabrasStore does beyond the recorded calls: `changes`, export, import, reset, the typed
// records, and the members palabras.js does not have. The recorded calls are in replay_test.dart.
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_progress/coqui_progress.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

const _t0 = 1772452800000; // 2026-03-02T12:00:00Z

PalabrasStore _store({
  String? stored,
  MemoryKeyValueStore? kv,
  SettableClock? clock,
}) => PalabrasStore(
  kv ?? MemoryKeyValueStore(stored: stored, key: PalabrasStore.storageKey),
  clock ?? SettableClock(_t0),
);

void main() {
  group('the empty store', () {
    test('is what palabras.js starts with', () {
      final s = _store();
      expect(
        jsonEncode(s.raw),
        '{"palabras":{},"dias":{},"cuentos":{},'
        '"ajustes":{"min":30,"todo":0,"bienvenida":0,"habla":1},"minutos":0,"v":1}',
      );
      expect(s.words, isEmpty);
      expect(s.word('casa'), isNull);
      expect(s.story('la-lluvia'), isNull);
      expect(s.minutes, 0);
      expect(s.streak, 0);
      expect(s.levelResult, isNull);
      expect(s.added, isEmpty);
      expect(s.setting('min'), 30);
      expect(s.setting('habla'), 1);
      expect(s.setting('nada'), isNull);
    });

    test('loading saves nothing', () {
      final kv = MemoryKeyValueStore(key: PalabrasStore.storageKey);
      _store(kv: kv);
      expect(kv.writes, 0);
      expect(kv.data, isEmpty);
    });
  });

  group('changes fires after every save', () {
    Future<int> events(PalabrasStore s, void Function() act) async {
      var n = 0;
      final sub = s.changes.listen((_) => n++);
      act();
      await pumpEventQueue();
      await sub.cancel();
      return n;
    }

    test('an answer, minutes, a listen, a reset', () async {
      final s = _store();
      expect(
        await events(s, () => s.answer('casa', Skill.ear, ok: true, ms: 500)),
        1,
      );
      expect(await events(s, () => s.addMinutes(1)), 1);
      expect(await events(s, () => s.listened('la-lluvia')), 1);
      expect(await events(s, s.reset), 1);
    });

    test(
      'a finished story: one save for each answer and one at the end',
      () async {
        final s = _store();
        final n = await events(
          s,
          () => s.storyFinished(
            StoryResult(
              id: 'la-lluvia',
              focusWords: ['casa'],
              log: [
                Decision(word: 'casa', ok: true, ms: 400),
                Decision(word: 'casa', ok: false),
                Decision(word: null, ok: true),
              ],
            ),
          ),
        );
        expect(n, 3);
      },
    );

    test('hearing a word does not save, as palabras.js oida() does not (the store has it, the storage not yet)', () async {
      final kv = MemoryKeyValueStore(key: PalabrasStore.storageKey);
      final s = _store(kv: kv);
      expect(await events(s, () => s.heard('casa')), 0);
      expect(s.word('casa'), isNotNull);
      expect(kv.writes, 0);
      // the next save takes it along
      s.addMinutes(1);
      expect(kv.writes, 1);
      expect(
        jsonDecode(kv.data[PalabrasStore.storageKey]!)['palabras'],
        contains('casa'),
      );
    });

    test('presume and setSetting and import save too', () async {
      final s = _store();
      expect(await events(s, () => s.presume(['casa'], ['la-lluvia'], [])), 1);
      expect(await events(s, () => s.setSetting('min', 15)), 1);
      expect(await events(s, () => s.import(s.export())), 1);
    });
  });

  group('the storage', () {
    test(
      'what is saved is what export() gives, under the key coqui.palabras.v1',
      () {
        final kv = MemoryKeyValueStore(key: PalabrasStore.storageKey);
        final s = _store(kv: kv);
        s.answer('casa', Skill.ear, ok: true, ms: 100);
        expect(PalabrasStore.storageKey, 'coqui.palabras.v1');
        expect(kv.data.keys, ['coqui.palabras.v1']);
        expect(kv.data['coqui.palabras.v1'], s.export());
      },
    );

    test(
      'a store that cannot be written is ignored: the data stays in memory',
      () {
        final kv = MemoryKeyValueStore(broken: true);
        final s = _store(kv: kv);
        s.addMinutes(2);
        expect(s.minutes, 2);
      },
    );

    test('a write that fails later, in the Future, is ignored too', () async {
      final s = PalabrasStore(AsyncFailingKeyValueStore(), SettableClock(_t0));
      s.addMinutes(2);
      await pumpEventQueue();
      expect(s.minutes, 2);
    });

    test('keys this code does not know are kept on save, after the ones palabras.js starts with', () {
      final kv = MemoryKeyValueStore(
        stored: '{"palabras":{},"futuro":{"x":[1,2.5]},"v":1,"otro":null}',
        key: PalabrasStore.storageKey,
      );
      final s = _store(kv: kv);
      s.addMinutes(0.5);
      s.addMinutes(0.5);
      expect(
        kv.data[PalabrasStore.storageKey],
        '{"palabras":{},"dias":{"2026-03-02":1},"cuentos":{},'
        '"ajustes":{"min":30,"todo":0,"bienvenida":0,"habla":1},"minutos":1,"v":1,'
        '"futuro":{"x":[1,2.5]},"otro":null}',
      );
    });
  });

  group('export, import, reset', () {
    test('export of one store imported into another gives the same store', () {
      final a = _store();
      a.heard('casa');
      a.answer('casa', Skill.ear, ok: false);
      a.presume(['agua'], ['la-lluvia'], [
        {'w': 'agua', 'ok': true},
      ]);
      a.setSetting('min', 15);
      final b = _store();
      b.import(a.export());
      expect(jsonEncode(b.raw), jsonEncode(a.raw));
      expect(b.export(), a.export());
    });

    test('import replaces the store, with palabras.js\'s load: defaults first, then the keys', () {
      final s = _store();
      s.addMinutes(5);
      s.import(
        '{"palabras":{},"cuentos":null,"ajustes":{"min":10},"extra":["la playa"]}',
      );
      expect(
        jsonEncode(s.raw),
        '{"palabras":{},"dias":{},"cuentos":{},'
        '"ajustes":{"min":10,"todo":0,"bienvenida":0,"habla":1},"minutos":0,"v":1,'
        '"extra":["la playa"]}',
      );
      expect(s.added, ['la playa']);
    });

    test(
      'import of text that is not JSON throws and leaves the store as it was',
      () {
        final kv = MemoryKeyValueStore(key: PalabrasStore.storageKey);
        final s = _store(kv: kv);
        s.addMinutes(5);
        final before = s.export();
        expect(() => s.import('{palabras: not json'), throwsFormatException);
        expect(() => s.import(''), throwsFormatException);
        expect(s.export(), before);
        expect(kv.data[PalabrasStore.storageKey], before);
      },
    );

    test(
      'reset empties everything, the keys it does not know too, and saves',
      () {
        final kv = MemoryKeyValueStore(
          stored: '{"palabras":{},"futuro":1}',
          key: PalabrasStore.storageKey,
        );
        final s = _store(kv: kv);
        s.heard('casa');
        s.reset();
        expect(
          kv.data[PalabrasStore.storageKey],
          '{"palabras":{},"dias":{},"cuentos":{},'
          '"ajustes":{"min":30,"todo":0,"bienvenida":0,"habla":1},"minutos":0,"v":1}',
        );
        expect(s.words, isEmpty);
      },
    );
  });

  group('the typed records', () {
    test('a heard word, an answer, a finished story', () {
      final clock = SettableClock(_t0);
      final s = _store(clock: clock);
      final w = s.heard('casa');
      expect(w.w, 'casa');
      expect(w.primera, _t0);
      expect(w.oida, 1);
      expect(w.ear.etapa, 1);
      expect(w.ear.gap, 1);
      expect(w.ear.due, greaterThan(_t0));
      expect(w.mouth.etapa, 0);

      clock.now = _t0 + 60000;
      final e = s.answer('casa', Skill.ear, ok: true, ms: 500);
      expect(e.etapa, 3);
      expect(e.gap, 2.5);
      expect(e.aciertos, [_t0 + 60000]);
      expect(e.ultima, _t0 + 60000);
      expect(e.due, _t0 + 60000 + 2.5 * 864e5);

      final m = s.answer('casa', Skill.mouth, ok: false);
      expect(m.fallos, 1);
      expect(m.due, _t0 + 60000 + 600000);
      expect(s.word('casa')!.ear.etapa, 3);
      expect(s.openForSpeaking('casa'), isTrue);
      expect(s.openForSpeaking('nada'), isFalse);

      s.storyFinished(StoryResult(id: 'la-lluvia', lost: 2));
      final c = s.story('la-lluvia')!;
      expect(c.n, 1);
      expect(c.primera, _t0 + 60000);
      expect(c.ultima, _t0 + 60000);
      expect(c.perdido, 2);
      expect(c.presunto, isNull);
      expect(s.played('la-lluvia'), isTrue);
      expect(s.played('el-jugo'), isFalse);
      expect([for (final x in s.words) x.w], ['casa']);
    });

    test(
      'presume marks the words and the stories, and keeps the level result',
      () {
        final s = _store();
        s.presume(['tú'], ['la-lluvia'], [
          {'w': 'tú', 'ok': true},
        ]);
        expect(s.word('tú')!.ear.presunta, 1);
        expect(s.word('tú')!.ear.etapa, 3);
        expect(s.story('la-lluvia')!.presunto, 1);
        expect(s.played('la-lluvia'), isTrue);
        expect(s.levelResult, {
          't': _t0,
          'log': [
            {'w': 'tú', 'ok': true},
          ],
          'historias': 1,
        });
      },
    );

    test('a store written by palabras.js, with a word that has no ear, is read, not repaired', () {
      final s = _store(
        stored:
            '{"palabras":{"soloboca":{"w":"soloboca","primera":5,"oida":0,'
            '"mouth":{"n":1,"bien":1}}}}',
      );
      expect(s.raw['palabras'], {
        'soloboca': {
          'w': 'soloboca',
          'primera': 5,
          'oida': 0,
          'mouth': {'n': 1, 'bien': 1},
        },
      });
      expect(s.openForSpeaking('soloboca'), isTrue);
      expect(() => s.due(Skill.ear), throwsA(anything));
      expect(() => s.heard('soloboca'), throwsA(anything));
      // the typed copy has the fields palabras.js's skill() starts with
      expect(s.word('soloboca')!.ear.etapa, 0);
      expect(s.word('soloboca')!.mouth.n, 1);
    });
  });

  group('due', () {
    test('at: 0 means now, as `t || now()`', () {
      final clock = SettableClock(_t0);
      final s = _store(clock: clock);
      s.heard('casa');
      clock.now = _t0 + 3 * 864e5.toInt();
      expect(s.due(Skill.ear), ['casa']);
      expect(s.due(Skill.ear, at: 0), ['casa']);
      expect(s.due(Skill.ear, at: _t0), isEmpty);
      expect(s.due(Skill.mouth), isEmpty);
    });
  });

  group('the members palabras.js does not have', () {
    test('settings are read and written in ajustes, and saved', () {
      final kv = MemoryKeyValueStore(key: PalabrasStore.storageKey);
      final s = _store(kv: kv);
      s.setSetting('min', 20);
      s.setSetting('bienvenida', 1);
      expect(s.setting('min'), 20);
      expect(s.raw['ajustes'], {
        'min': 20,
        'todo': 0,
        'bienvenida': 1,
        'habla': 1,
      });
      expect(
        jsonDecode(kv.data[PalabrasStore.storageKey]!)['ajustes']['bienvenida'],
        1,
      );
    });

    test(
      'hasRead and added read what a store keeps under leidos and extra',
      () {
        final s = _store(
          stored: '{"leidos":{"la-lluvia":1,"el-jugo":0},"extra":["la playa","hablar"]}',
        );
        expect(s.hasRead('la-lluvia'), isTrue);
        expect(s.hasRead('el-jugo'), isFalse);
        expect(s.hasRead('nada'), isFalse);
        expect(s.added, ['la playa', 'hablar']);
        expect(_store().hasRead('la-lluvia'), isFalse);
      },
    );

    test('markRead and add are not settled yet: they say so', () {
      final s = _store();
      expect(() => s.markRead('la-lluvia'), throwsUnimplementedError);
      expect(() => s.add('la playa'), throwsUnimplementedError);
    });
  });
}
