import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:test/test.dart';

import 'fixtures/old_code.dart';

final _arabicLanguage = Language(
  code: 'ar',
  englishName: 'Arabic',
  nativeName: 'العربية',
  recognitionLocale: 'ar-SA',
  direction: LanguageDirection.rtl,
  script: 'Arab',
  partnerName: 'Tariq',
  callAgentId: 'agent_arabic_test',
  micWords: const {
    'ready': 'اضغط وتكلم',
    'listening': 'أسمعك',
    'thinking': 'لحظة',
    'theySpeak': 'استمع',
    'right': 'ممتاز',
    'notYet': 'مرة أخرى',
  },
  tabNames: const {
    'library': 'المكتبة',
    'words': 'الكلمات',
    'map': 'الخريطة',
    'speak': 'تكلم',
    'me': 'أنا',
  },
);

final _cyrillicLanguage = Language(
  code: 'ru',
  englishName: 'Russian',
  nativeName: 'Русский',
  recognitionLocale: 'ru-RU',
  direction: LanguageDirection.ltr,
  script: 'Cyrl',
  partnerName: 'Ivan',
  callAgentId: 'agent_ru_test',
  micWords: const {
    'ready': 'a',
    'listening': 'b',
    'thinking': 'c',
    'theySpeak': 'd',
    'right': 'e',
    'notYet': 'f',
  },
  tabNames: const {
    'library': 'a',
    'words': 'b',
    'map': 'c',
    'speak': 'd',
    'me': 'e',
  },
);

class _MinimalCatalog implements CourseCatalog {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LanguageAwareCatalog extends _MinimalCatalog implements LanguageCatalog {
  _LanguageAwareCatalog(this.language);

  @override
  final Language language;
}

void main() {
  group('Language.spanish', () {
    test('has the N2.1 fields and values', () {
      final es = Language.spanish;
      expect(es.code, 'es');
      expect(es.englishName, 'Spanish');
      expect(es.nativeName, 'Español');
      expect(es.recognitionLocale, 'es-US');
      expect(es.direction, LanguageDirection.ltr);
      expect(es.script, 'Latn');
      expect(es.partnerName, 'Danny');
      expect(es.callAgentId, 'agent_3301m795q3xtfpx8c99zc0s870vm');
      expect(es.callAgentId, spanishCallAgentId);
      expect(es.micWords, {
        'ready': 'Toca y habla',
        'listening': 'Te escucho',
        'thinking': 'Un momento',
        'theySpeak': 'Escucha',
        'right': '¡Muy bien!',
        'notYet': 'Otra vez',
      });
      expect(es.tabNames, {
        'library': 'Biblioteca',
        'words': 'Palabras',
        'map': 'Mapa',
        'speak': 'Hablar',
        'me': 'Yo',
      });
      expect(es.a11yWords, isEmpty);
      expect(() => es.tabNames['map'] = 'x', throwsUnsupportedError);
      expect(() => es.micWords['ready'] = 'x', throwsUnsupportedError);
      expect(() => es.a11yWords['close'] = 'x', throwsUnsupportedError);
    });

    test('matches all 30 PAL.norm cases and global normalize()', () {
      for (final c in normCases) {
        final input = c[0];
        final expected = c[1];
        expect(Language.spanish.normalize(input), expected);
        expect(normalize(input), expected);
      }
      expect(Language.spanish.normalize(null), '  ');
      expect(normalize(null), '  ');
    });

    test('tokens match today\'s token regex with exact UTF-16 offsets', () {
      final oldRegex = RegExp(r'[\p{L}\p{N}]+', unicode: true);
      const samples = [
        '¡Hola, abuela! ¿Cómo estás?',
        'El pingüino niño tiene 3 bizcochos.',
        '¡Sí, quiero café con azúcar!',
        '   ...   ',
        '',
        'uno-dos/tres',
      ];
      for (final s in samples) {
        final got = Language.spanish.tokens(s);
        final expected = [
          for (final m in oldRegex.allMatches(s))
            WordToken(m[0]!, m.start, m.end),
        ];
        expect(got, expected, reason: s);
        for (final t in got) {
          expect(s.substring(t.start, t.end), t.text);
        }
      }
      expect(const WordToken('Hola', 1, 5), const WordToken('Hola', 1, 5));
      expect(
        const WordToken('Hola', 1, 5).hashCode,
        const WordToken('Hola', 1, 5).hashCode,
      );
      expect(
        const WordToken('Hola', 1, 5),
        isNot(const WordToken('Hola', 0, 4)),
      );
      expect('${const WordToken('Hola', 1, 5)}', 'WordToken(Hola, 1, 5)');
    });
  });

  group('Language validation', () {
    Map<String, String> validMic() =>
        Map<String, String>.from(Language.spanish.micWords);
    Map<String, String> validTabs() =>
        Map<String, String>.from(Language.spanish.tabNames);

    Language build({
      Map<String, String>? micWords,
      Map<String, String>? tabNames,
      Map<String, String> a11yWords = const {},
    }) => Language(
      code: 'es',
      englishName: 'Spanish',
      nativeName: 'Español',
      recognitionLocale: 'es-US',
      direction: LanguageDirection.ltr,
      script: 'Latn',
      partnerName: 'Danny',
      callAgentId: spanishCallAgentId,
      micWords: micWords ?? validMic(),
      tabNames: tabNames ?? validTabs(),
      a11yWords: a11yWords,
    );

    test('rejects missing, extra, or empty tabNames', () {
      expect(
        () => build(tabNames: validTabs()..remove('map')),
        throwsArgumentError,
      );
      expect(
        () => build(tabNames: validTabs()..['extra'] = 'Extra'),
        throwsArgumentError,
      );
      expect(
        () => build(tabNames: validTabs()..['me'] = '   '),
        throwsArgumentError,
      );
    });

    test('rejects missing, extra, or empty micWords', () {
      expect(
        () => build(micWords: validMic()..remove('ready')),
        throwsArgumentError,
      );
      expect(
        () => build(micWords: validMic()..['extra'] = 'Extra'),
        throwsArgumentError,
      );
      expect(
        () => build(micWords: validMic()..['notYet'] = ''),
        throwsArgumentError,
      );
    });

    test('keeps optional a11yWords and compares by value', () {
      final a = build(a11yWords: const {'close': 'Cerrar'});
      final b = build(a11yWords: const {'close': 'Cerrar'});
      expect(a.a11yWords, {'close': 'Cerrar'});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(Language.spanish));
      expect('$a', 'Language(es)');
    });
  });

  group('Arabic and unsupported scripts', () {
    test('Arabic word does not come out blank from normalize or tokens', () {
      expect(_arabicLanguage.direction, LanguageDirection.rtl);
      expect(_arabicLanguage.script, 'Arab');

      final plain = _arabicLanguage.normalize('مرحبا');
      expect(plain.trim(), isNotEmpty);
      expect(plain, ' مرحبا ');

      // Tashkeel (diacritics) and tatweel removed; alef variants folded to bare alef.
      expect(_arabicLanguage.normalize('مَرْحَبًا'), ' مرحبا ');
      expect(
        _arabicLanguage.normalize('السَّلَامُ عَلَيْكُمْ!'),
        ' السلام عليكم ',
      );
      expect(
        _arabicLanguage.normalize('أحمد، إبراهيم، آمين'),
        ' احمد ابراهيم امين ',
      );
      expect(_arabicLanguage.normalize('مـرحـبا'), ' مرحبا ');

      // Ta marbuta (ة) and alef maksura (ى) are kept distinct.
      expect(_arabicLanguage.normalize('مدرسة'), ' مدرسة ');
      expect(_arabicLanguage.normalize('على'), ' على ');

      // Tokens keep Arabic words whole (marks do not split a word).
      const sentence = 'مَرْحَبًا، كَيْفَ حَالُكَ؟';
      final toks = _arabicLanguage.tokens(sentence);
      expect(toks.map((t) => t.text).toList(), [
        'مَرْحَبًا',
        'كَيْفَ',
        'حَالُكَ',
      ]);
      for (final t in toks) {
        expect(sentence.substring(t.start, t.end), t.text);
      }
    });

    test('unknown script throws UnsupportedError naming the script', () {
      expect(
        () => _cyrillicLanguage.normalize('Привет'),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('Cyrl'),
          ),
        ),
      );
      expect(
        () => _cyrillicLanguage.tokens('Привет'),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('Cyrl'),
          ),
        ),
      );
    });
  });

  group('Course.language', () {
    test('defaults to Spanish for a catalog without LanguageCatalog', () {
      final CourseCatalog course = _MinimalCatalog();
      expect(course.language, Language.spanish);
    });

    test(
      'returns the catalog\'s language when it implements LanguageCatalog',
      () {
        final CourseCatalog course = _LanguageAwareCatalog(_arabicLanguage);
        expect(course.language, _arabicLanguage);
      },
    );
  });

  group('Entitlements and AllowAllEntitlements', () {
    test('Plan and Feature have the N2.1 values', () {
      expect(Plan.values, [Plan.free, Plan.course, Plan.courseAndCalls]);
      expect(Feature.values, [
        Feature.calls,
        Feature.everyPlace,
        Feature.library,
      ]);
    });

    test('AllowAllEntitlements allows everything and returns nulls', () async {
      const Entitlements e = AllowAllEntitlements();
      expect(e.plan, Plan.courseAndCalls);
      for (final f in Feature.values) {
        expect(e.has(f), isTrue, reason: f.name);
      }
      for (final p in Plan.values) {
        expect(e.priceOf(p), isNull, reason: p.name);
        expect(e.callMinutes(p), isNull, reason: p.name);
        await e.buy(p);
      }
      await e.restore();
      expect(e.changes.isBroadcast, isTrue);
      expect(await e.changes.toList(), isEmpty);
    });
  });

  group('new N2.1 routes', () {
    test('compare by value and belong to AppRoute', () {
      const routes = <AppRoute>[
        LanguagesRoute(),
        PlansRoute(),
        ImportRoute(),
        PlaceRoute('casa'),
      ];
      expect(routes, hasLength(4));
      expect(const LanguagesRoute(), const LanguagesRoute());
      expect(const LanguagesRoute().hashCode, const LanguagesRoute().hashCode);
      expect('${const LanguagesRoute()}', 'LanguagesRoute()');

      expect(const PlansRoute(), const PlansRoute());
      expect(const PlansRoute().hashCode, const PlansRoute().hashCode);
      expect('${const PlansRoute()}', 'PlansRoute()');

      expect(const ImportRoute(), const ImportRoute());
      expect(const ImportRoute().hashCode, const ImportRoute().hashCode);
      expect('${const ImportRoute()}', 'ImportRoute()');

      expect(const PlaceRoute('casa'), const PlaceRoute('casa'));
      expect(const PlaceRoute('casa'), isNot(const PlaceRoute('plaza')));
      expect(
        const PlaceRoute('casa').hashCode,
        const PlaceRoute('casa').hashCode,
      );
      expect('${const PlaceRoute('casa')}', 'PlaceRoute(casa)');

      expect(const LanguagesRoute(), isNot(const PlansRoute()));
      expect(const PlansRoute(), isNot(const ImportRoute()));
      expect(const ImportRoute(), isNot(const PlaceRoute('casa')));
    });
  });

  group('CallBrief.agentId', () {
    test('defaults to Spanish agent id and keeps LLAMADAS JSON unchanged', () {
      final ll = jsonDecode(llamadasJson) as Map<String, dynamic>;
      final casa = CallBrief.fromJson(
        'casa',
        ll['casa'] as Map<String, dynamic>,
      );
      expect(casa.agentId, Language.spanish.callAgentId);
      expect(casa.toJson().containsKey('agentId'), isFalse);
      expect(casa.toJson(), ll['casa']);
    });

    test(
      'reads explicit agentId from parameter or JSON and round-trips it',
      () {
        final ll = jsonDecode(llamadasJson) as Map<String, dynamic>;
        final raw = Map<String, dynamic>.from(
          ll['casa'] as Map<String, dynamic>,
        );

        final viaParam = CallBrief.fromJson(
          'casa',
          raw,
          agentId: _arabicLanguage.callAgentId,
        );
        expect(viaParam.agentId, _arabicLanguage.callAgentId);
        expect(viaParam.toJson()['agentId'], _arabicLanguage.callAgentId);

        final viaJson = CallBrief.fromJson('casa', {
          ...raw,
          'agentId': 'agent_custom_123',
        });
        expect(viaJson.agentId, 'agent_custom_123');
        expect(viaJson.toJson()['agentId'], 'agent_custom_123');

        final direct = CallBrief(
          placeId: 'casa',
          minutes: 5,
          job: 'j',
          opening: 'o',
          photo: 'p',
        );
        expect(direct.agentId, Language.spanish.callAgentId);
      },
    );
  });
}
