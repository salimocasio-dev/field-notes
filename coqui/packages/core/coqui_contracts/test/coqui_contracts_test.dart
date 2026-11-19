import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:test/test.dart';

import 'fixtures/old_code.dart';

const _deep = DeepCollectionEquality();

/// Same JSON, numbers compared as numbers (3 and 3.0 are one number in JavaScript).
Matcher sameJson(Object? expected) => predicate<Object?>(
  (actual) => _deep.equals(jsonDecode(jsonEncode(actual)), expected),
  'the same JSON as ${jsonEncode(expected)}',
);

void main() {
  group('normalize is PAL.norm', () {
    test('there are 30 strings', () => expect(normCases, hasLength(30)));
    for (final c in normCases) {
      test('${jsonEncode(c[0])} -> ${jsonEncode(c[1])}', () {
        expect(normalize(c[0]), c[1]);
      });
    }
  });

  group('Mulberry32', () {
    test('seed 1 gives the ten values node gives', () {
      final r = Mulberry32(1);
      expect([for (var i = 0; i < 10; i++) r.next()], mulberry32Seed1);
    });
    test('values stay in [0, 1) and two of one seed agree', () {
      final a = Mulberry32(123456789), b = Mulberry32(123456789);
      for (var i = 0; i < 1000; i++) {
        final x = a.next();
        expect(x, inInclusiveRange(0, 0.9999999999));
        expect(b.next(), x);
      }
    });
  });

  group('the stored JSON (a store made by palabras.js)', () {
    final store = jsonDecode(sampleStoreJson) as Map<String, dynamic>;
    final palabras = store['palabras'] as Map<String, dynamic>;
    final cuentos = store['cuentos'] as Map<String, dynamic>;

    test('the sample has the keys of today\'s store', () {
      expect(
        store.keys,
        containsAll([
          'palabras',
          'dias',
          'cuentos',
          'ajustes',
          'minutos',
          'v',
          'nivel',
          'oidos',
          'leidos',
          'extra',
        ]),
      );
      expect(palabras.length, greaterThan(5));
    });

    test('every word record round-trips', () {
      for (final e in palabras.entries) {
        final r = WordRecord.fromJson(e.value as Map<String, dynamic>);
        expect(r.w, e.key);
        expect(r.toJson(), sameJson(e.value), reason: e.key);
      }
    });

    test('the record fields read as palabras.js wrote them', () {
      final v = WordRecord.fromJson(
        palabras['ventana'] as Map<String, dynamic>,
      );
      expect(v.ear.marca, 1); // three misses: flagged
      expect(v.ear.aparcada, greaterThan(0));
      expect(v.ear.aciertos, isEmpty);
      final abre = WordRecord.fromJson(
        palabras['abre'] as Map<String, dynamic>,
      );
      expect(abre.ear.presunta, 1);
      expect(abre.of(Skill.ear).etapa, 3);
      final hola = WordRecord.fromJson(
        palabras['hola'] as Map<String, dynamic>,
      );
      expect(hola.of(Skill.mouth).n, 1);
    });

    test('every story record round-trips', () {
      for (final e in cuentos.entries) {
        expect(
          StoryRecord.fromJson(e.value as Map<String, dynamic>).toJson(),
          sameJson(e.value),
          reason: e.key,
        );
      }
      expect(
        StoryRecord.fromJson(cuentos['el-bizcocho'] as Map<String, dynamic>)
            .presunto,
        1,
      );
      expect(
        StoryRecord.fromJson(cuentos['la-lluvia'] as Map<String, dynamic>)
            .perdido,
        1,
      );
    });

    test('a fresh skill is skill()', () {
      expect(SkillRecord().toJson(), {
        'etapa': 0,
        'paso': 1,
        'seguidas': 0,
        'fallos': 0,
        'gap': 0,
        'due': 0,
        'aciertos': <int>[],
        'ultima': 0,
        'aparcada': 0,
        'marca': 0,
        'n': 0,
        'bien': 0,
      });
    });

    test('a decision keeps juego.js\'s keys', () {
      final d = {
        'word': 'casa',
        'asked': 'casa',
        'got': 'puerta',
        'ok': false,
        'ms': 1200,
      };
      expect(Decision.fromJson(d).toJson(), d);
      final e = {'word': null, 'asked': 'libre', 'got': 'si', 'ok': true};
      expect(Decision.fromJson(e).toJson(), e);
    });
  });

  group('the data files', () {
    final curso = jsonDecode(cursoJson) as Map<String, dynamic>;

    test('every place of CURSO round-trips', () {
      final lugares = curso['lugares'] as List;
      expect(lugares, hasLength(10));
      for (final l in lugares) {
        expect(Place.fromJson(l as Map<String, dynamic>).toJson(), sameJson(l));
      }
      final casa = Place.fromJson(lugares.first as Map<String, dynamic>);
      expect(casa.name, 'La casa');
      expect(casa.stories.take(3), [
        'la-lluvia',
        'el-bizcocho',
        'donde-esta-el-pajaro',
      ]);
      expect(casa.fork, isNull);
    });

    test('every story entry of CURSO round-trips', () {
      final cuentos = curso['cuentos'] as Map<String, dynamic>;
      for (final e in cuentos.entries) {
        final m = StoryMeta.fromJson(e.key, e.value as Map<String, dynamic>);
        expect(m.id, e.key);
        expect(m.toJson(), sameJson(e.value));
      }
    });

    test('every pair of cual-frente round-trips', () {
      final file = jsonDecode(cualFrenteJson) as Map<String, dynamic>;
      for (final it in file['items'] as List) {
        final p = ReviewPair.fromJson(
          it as Map<String, dynamic>,
          scene: file['scene'] as String,
        );
        expect(p.scene, 'frente');
        expect(p.toJson(), sameJson(it));
      }
    });

    test('a picture naming another scene keeps esc', () {
      final j = {
        'esc': 'sala',
        'set': {'gente': 1},
        'cam': [1, 2, 3, 4],
      };
      expect(PictureSpec.fromJson(j).scene, 'sala');
      expect(PictureSpec.fromJson(j).toJson(), j);
    });

    test('every level item of NV round-trips', () {
      final nv = jsonDecode(nvJson) as List;
      expect(nv, isNotEmpty);
      for (final q in nv) {
        expect(
          LevelItem.fromJson(q as Map<String, dynamic>).toJson(),
          sameJson(q),
        );
      }
      expect(
        LevelItem.fromJson(nv.first as Map<String, dynamic>).pictures.first,
        ['abuela', 'si', 166],
      );
    });

    test('every call of LLAMADAS round-trips', () {
      final ll = jsonDecode(llamadasJson) as Map<String, dynamic>;
      for (final e in ll.entries) {
        final b = CallBrief.fromJson(e.key, e.value as Map<String, dynamic>);
        expect(b.placeId, e.key);
        expect(b.toJson(), sameJson(e.value));
      }
      expect(
        CallBrief.fromJson('casa', ll['casa'] as Map<String, dynamic>).minutes,
        5,
      );
    });

    test('the book la-lluvia round-trips', () {
      final j = jsonDecode(bookLaLluviaJson) as Map<String, dynamic>;
      final b = Book.fromJson(j);
      expect(b.readable, isFalse);
      expect(b.pages.first.image, 'img/la-lluvia-1.png');
      expect(b.toJson(), sameJson(j));
    });
  });

  group('routes', () {
    test('compare by value', () {
      expect(const StoryRoute('la-lluvia'), const StoryRoute('la-lluvia'));
      expect(
        const StoryRoute('la-lluvia'),
        isNot(const StoryRoute('la-lluvia', listen: true)),
      );
      expect(const ReviewRoute(), const ReviewRoute(practice: false));
      expect(const BookRoute('a'), isNot(const BookRoute('b')));
      expect(const TabRoute('map').hashCode, const TabRoute('map').hashCode);
      expect(const LevelCheckRoute(), const LevelCheckRoute());
      expect(const VoiceTestRoute(), isNot(const LevelCheckRoute()));
      expect(const CallRoute('casa'), const CallRoute('casa'));
    });
  });

  group('call events', () {
    test('are the seven the page lists', () {
      final List<CallEvent> all = [
        const Connected(),
        const AgentLine('a'),
        const Heard('b'),
        const Mode('speaking'),
        const Tool('show_picture', {'picture': 'jugo'}),
        const CallError('x'),
        const Ended('user'),
      ];
      final names = all.map(
        (e) => switch (e) {
          Connected() => 'connected',
          AgentLine(:final text) => 'agent $text',
          Heard(:final text) => 'heard $text',
          Mode(:final mode) => 'mode $mode',
          Tool(:final name) => 'tool $name',
          CallError(:final message) => 'error $message',
          Ended(:final reason) => 'ended $reason',
        },
      );
      expect(names, hasLength(7));
    });
  });
}
