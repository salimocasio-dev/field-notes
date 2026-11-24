import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_progress/coqui_progress.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

const _dayMs = 86400000;
final _day1Utc = DateTime.utc(2026, 3, 2, 12); // 2026-03-02T12:00:00Z
final _t0 = _day1Utc.millisecondsSinceEpoch;

Language _arabicLanguage() => Language(
  code: 'ar',
  englishName: 'Arabic',
  nativeName: 'العربية',
  recognitionLocale: 'ar-EG',
  direction: LanguageDirection.rtl,
  script: 'Arab',
  partnerName: 'Nadia',
  callAgentId: 'agent_arabic_test',
  micWords: const {
    'ready': 'اضغط وتكلم',
    'listening': 'أسمعك',
    'thinking': 'لحظة',
    'theySpeak': 'اسمع',
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

Language _frenchLanguage() => Language(
  code: 'fr',
  englishName: 'French',
  nativeName: 'Français',
  recognitionLocale: 'fr-FR',
  direction: LanguageDirection.ltr,
  script: 'Latn',
  partnerName: 'Camille',
  callAgentId: 'agent_french_test',
  micWords: const {
    'ready': 'Parle',
    'listening': 'J’écoute',
    'thinking': 'Un instant',
    'theySpeak': 'Écoute',
    'right': 'Très bien',
    'notYet': 'Encore',
  },
  tabNames: const {
    'library': 'Bibliothèque',
    'words': 'Mots',
    'map': 'Carte',
    'speak': 'Parler',
    'me': 'Moi',
  },
);

const _legacyFixture =
    '{"palabras":{"casa":{"w":"casa","primera":1772366400000,"oida":2,'
    '"ear":{"etapa":3,"paso":2,"seguidas":1,"fallos":0,"gap":2.5,'
    '"due":1772582400000.5,"aciertos":[1772366400000],"ultima":1772366400000,'
    '"aparcada":0,"marca":0,"n":2,"bien":2},'
    '"mouth":{"etapa":0,"paso":1,"seguidas":0,"fallos":0,"gap":0,"due":0,'
    '"aciertos":[],"ultima":0,"aparcada":0,"marca":0,"n":0,"bien":0}}},'
    '"dias":{"2026-03-01":1,"2026-03-02":2},'
    '"cuentos":{"la-lluvia":{"n":1,"primera":1772366400000,"ultima":1772452800000,"perdido":0}},'
    '"ajustes":{"min":20,"todo":0,"bienvenida":1,"habla":1,"notaHabla":1},'
    '"minutos":14.5,"v":1,"futureKey":{"nested":[1,2.25,"keep"]}}';

Future<int> _countEvents(Stream<void> stream, void Function() act) async {
  var count = 0;
  final sub = stream.listen((_) => count++);
  act();
  await pumpEventQueue();
  await sub.cancel();
  return count;
}

void main() {
  final arabic = _arabicLanguage();
  final french = _frenchLanguage();

  group('legacy Spanish migration', () {
    test('ProgressStores copies coqui.palabras.v1 to coqui.es.palabras.v1 byte-for-byte, keeps legacy untouched, and seeds shared state', () {
      final kv = MemoryKeyValueStore(
        stored: _legacyFixture,
        key: PalabrasStore.storageKey,
      );
      final clock = SettableClock(_t0);

      final stores = ProgressStores(kv, clock);
      final esKey = PalabrasStore.storageKeyFor('es');

      expect(esKey, 'coqui.es.palabras.v1');
      expect(kv.data[esKey], _legacyFixture);
      expect(kv.data[PalabrasStore.storageKey], _legacyFixture);
      expect(kv.data[PalabrasStore.sharedStorageKey], isNotNull);

      expect(stores.streak, 2);
      expect(stores.minutes, 14.5);
      expect(stores.languagesWithProgress, ['es']);
      expect(stores.currentLanguageCode, 'es');

      final es = stores.forLanguage(Language.spanish);
      expect(es.word('casa')?.ear.gap, 2.5);
      expect(es.word('casa')?.ear.due, 1772582400000.5);
      expect(es.played('la-lluvia'), isTrue);
      expect(es.setting('min'), 20);
      expect(es.setting('notaHabla'), 1);
      expect(es.raw['futureKey'], {
        'nested': [1, 2.25, 'keep'],
      });
      expect(es.streak, 2);
      expect(es.minutes, 14.5);
    });

    test('standalone PalabrasStore(language: Language.spanish) migrates byte-for-byte and seeds shared state', () {
      final kv = MemoryKeyValueStore(
        stored: _legacyFixture,
        key: PalabrasStore.storageKey,
      );
      final clock = SettableClock(_t0);

      final es = PalabrasStore(kv, clock, language: Language.spanish);

      expect(kv.data['coqui.es.palabras.v1'], _legacyFixture);
      expect(kv.data[PalabrasStore.storageKey], _legacyFixture);
      expect(kv.data[PalabrasStore.sharedStorageKey], isNotNull);
      expect(es.word('casa')?.ear.due, 1772582400000.5);
      expect(es.raw['futureKey'], {
        'nested': [1, 2.25, 'keep'],
      });
      expect(es.streak, 2);
      expect(es.minutes, 14.5);

      final shared = jsonDecode(
        kv.data[PalabrasStore.sharedStorageKey]!,
      ) as Map<String, dynamic>;
      expect(shared['idiomas'], ['es']);
      expect(shared['minutos'], 14.5);
      expect(shared['dias'], {'2026-03-01': 1, '2026-03-02': 2});
    });

    test('second startup is idempotent: preserves edits, never overwrites from legacy, and performs zero writes', () {
      final kv = MemoryKeyValueStore(
        stored: _legacyFixture,
        key: PalabrasStore.storageKey,
      );
      final clock = SettableClock(_t0);

      // First startup migrates and learner makes new progress.
      final first = ProgressStores(kv, clock);
      final es1 = first.forLanguage(Language.spanish);
      es1.answer('perro', Skill.ear, ok: true, ms: 500);
      es1.storyFinished(
        StoryResult(
          id: 'el-parque',
          focusWords: ['perro'],
          log: [Decision(word: 'perro', ok: true, ms: 400)],
        ),
      );
      es1.addMinutes(3.5);

      final esSnapshot = kv.data['coqui.es.palabras.v1'];
      final sharedSnapshot = kv.data[PalabrasStore.sharedStorageKey];
      final writesAfterFirst = kv.writes;

      // Second startup: nothing changes, zero writes, legacy untouched.
      final second = ProgressStores(kv, clock);
      expect(kv.writes, writesAfterFirst);
      expect(kv.data['coqui.es.palabras.v1'], esSnapshot);
      expect(kv.data[PalabrasStore.sharedStorageKey], sharedSnapshot);
      expect(kv.data[PalabrasStore.storageKey], _legacyFixture);

      final es2 = second.forLanguage(Language.spanish);
      expect(kv.writes, writesAfterFirst);
      expect(es2.word('casa'), isNotNull);
      expect(es2.word('perro'), isNotNull);
      expect(es2.played('el-parque'), isTrue);
      expect(es2.minutes, 18.0);
      expect(es2.streak, 2);
    });

    test('after resetting Spanish, second startup does not resurrect legacy coqui.palabras.v1', () {
      final kv = MemoryKeyValueStore(
        stored: _legacyFixture,
        key: PalabrasStore.storageKey,
      );
      final clock = SettableClock(_t0);

      final first = ProgressStores(kv, clock);
      final es1 = first.forLanguage(Language.spanish);
      expect(es1.word('casa'), isNotNull);
      es1.reset();
      expect(es1.words, isEmpty);
      expect(first.languagesWithProgress, isEmpty);

      final writesAfterReset = kv.writes;

      // Restart with legacy key still present in kv.
      final second = ProgressStores(kv, clock);
      final es2 = second.forLanguage(Language.spanish);
      expect(kv.writes, writesAfterReset);
      expect(es2.words, isEmpty);
      expect(es2.word('casa'), isNull);
      expect(es2.played('la-lluvia'), isFalse);
      expect(second.languagesWithProgress, isEmpty);
      expect(kv.data[PalabrasStore.storageKey], _legacyFixture);
    });
  });

  group('minutesOn and 35-day rolling window', () {
    test('tracks 3-day sequence plus missed day, accumulates multiple calls, matches UTC and local DateTime, and persists', () {
      final kv = MemoryKeyValueStore();
      final clock = SettableClock(_t0);
      final stores = ProgressStores(kv, clock);
      final es = stores.forLanguage(Language.spanish);

      final day1 = DateTime.utc(2026, 3, 2, 12);
      final day2 = DateTime.utc(2026, 3, 3, 12);
      final day3 = DateTime.utc(2026, 3, 4, 12);
      final day4Missed = DateTime.utc(2026, 3, 5, 12);
      final day5 = DateTime.utc(2026, 3, 6, 12);

      // Day 1: two calls accumulate.
      clock.now = day1.millisecondsSinceEpoch;
      es.addMinutes(2.5);
      es.addMinutes(3.0);

      // Day 2: one call.
      clock.now = day2.millisecondsSinceEpoch;
      es.addMinutes(4.0);

      // Day 3: one call -> streak 3.
      clock.now = day3.millisecondsSinceEpoch;
      es.addMinutes(1.5);
      expect(es.streak, 3);
      expect(stores.streak, 3);

      // Day 4: missed -> streak 0, minutesOn 0.
      clock.now = day4Missed.millisecondsSinceEpoch;
      expect(es.streak, 0);
      expect(es.minutesOn(day4Missed), 0);

      // Day 5: activity restarts streak at 1.
      clock.now = day5.millisecondsSinceEpoch;
      es.addMinutes(6.0);
      expect(es.streak, 1);

      // Both UTC and local DateTime representing the same instant match.
      expect(es.minutesOn(day1), 5.5);
      expect(es.minutesOn(day1.toLocal()), 5.5);
      expect(es.minutesOn(day2), 4.0);
      expect(es.minutesOn(day3), 1.5);
      expect(es.minutesOn(day4Missed), 0);
      expect(es.minutesOn(day5), 6.0);
      expect(es.minutes, 17.0);

      // Persists across restart.
      final restarted = ProgressStores(kv, clock);
      final esRestarted = restarted.forLanguage(Language.spanish);
      expect(restarted.minutesOn(day1), 5.5);
      expect(esRestarted.minutesOn(day2), 4.0);
      expect(esRestarted.minutesOn(day3), 1.5);
      expect(esRestarted.minutesOn(day4Missed), 0);
      expect(esRestarted.minutesOn(day5), 6.0);
      expect(restarted.minutes, 17.0);
      expect(restarted.streak, 1);
    });

    test('keeps Day 1 at Day 35 inclusive (+34 days), prunes Day 1 at Day 36 (+35 days) while keeping Day 2 and total minutes', () {
      final kv = MemoryKeyValueStore();
      final clock = SettableClock(_t0);
      final stores = ProgressStores(kv, clock);
      final es = stores.forLanguage(Language.spanish);

      final day1 = _day1Utc;
      final day2 = _day1Utc.add(const Duration(days: 1));
      final day35 = _day1Utc.add(const Duration(days: 34));
      final day36 = _day1Utc.add(const Duration(days: 35));

      clock.now = day1.millisecondsSinceEpoch;
      es.addMinutes(10);

      clock.now = day2.millisecondsSinceEpoch;
      es.addMinutes(20);

      // Day 35 (+34 days): Day 1 is still inside the 35-day inclusive window.
      clock.now = day35.millisecondsSinceEpoch;
      es.addMinutes(5);
      expect(es.minutesOn(day1), 10);
      expect(es.minutesOn(day2), 20);
      expect(es.minutesOn(day35), 5);
      expect(es.minutes, 35);

      // Day 36 (+35 days): Day 1 is pruned, Day 2 (+34 days from Day 36) is kept,
      // and total minutes is NOT reduced.
      clock.now = day36.millisecondsSinceEpoch;
      es.addMinutes(7);
      expect(es.minutesOn(day1), 0);
      expect(es.minutesOn(day2), 20);
      expect(es.minutesOn(day35), 5);
      expect(es.minutesOn(day36), 7);
      expect(es.minutes, 42);

      final shared = jsonDecode(
        kv.data[PalabrasStore.sharedStorageKey]!,
      ) as Map<String, dynamic>;
      final minutosDia = shared['minutosDia'] as Map<String, dynamic>;
      expect(minutosDia.containsKey('2026-03-02'), isFalse);
      expect(minutosDia['2026-03-03'], 20);
    });
  });

  group('multi-language isolation with shared streak and minutes', () {
    test('isolates words, stories, levelResult, due, settings, added, and hasRead while sharing streak, minutes, and minutesOn', () async {
      final kv = MemoryKeyValueStore();
      final clock = SettableClock(_t0);
      final stores = ProgressStores(kv, clock);

      final es = stores.forLanguage(Language.spanish);
      final ar = stores.forLanguage(arabic);

      expect(es.language, Language.spanish);
      expect(ar.language, arabic);
      expect(es.stageMax, 4);
      expect(ar.stageMax, 4);
      expect(es.streakFreezes, isNull);
      expect(ar.streakFreezes, isNull);

      // Day 1: Spanish story + word + settings + added + read + levelResult.
      es.presume(['hola'], ['es-intro'], ['log-es']);
      es.answer('casa', Skill.ear, ok: true, ms: 400);
      es.setSetting('min', 45);
      es.add('café');
      es.markRead('libro-es');
      es.addMinutes(4.5);

      expect(es.streak, 1);
      expect(ar.streak, 1);
      expect(stores.streak, 1);

      // Day 2: Arabic story + word + minutes extends shared streak to 2!
      clock.now = _t0 + _dayMs;
      ar.storyFinished(
        StoryResult(
          id: 'ar-story-1',
          focusWords: ['مرحبا'],
          log: [Decision(word: 'مرحبا', ok: true, ms: 500)],
        ),
      );
      ar.setSetting('min', 15);
      ar.add('شاي');
      ar.markRead('book-ar');
      ar.addMinutes(3.0);

      // Same day (Day 2): Spanish also adds minutes -> minutesOn sums both languages!
      es.addMinutes(2.5);

      final day1 = DateTime.fromMillisecondsSinceEpoch(_t0, isUtc: true);
      final day2 = DateTime.fromMillisecondsSinceEpoch(
        _t0 + _dayMs,
        isUtc: true,
      );

      // Separate keys exist.
      expect(kv.data.containsKey('coqui.es.palabras.v1'), isTrue);
      expect(kv.data.containsKey('coqui.ar.palabras.v1'), isTrue);
      expect(kv.data.containsKey('coqui.shared.v1'), isTrue);
      expect(kv.data.containsKey(PalabrasStore.storageKey), isFalse);

      // Isolated per-language data.
      expect(es.word('casa'), isNotNull);
      expect(es.word('مرحبا'), isNull);
      expect(ar.word('مرحبا'), isNotNull);
      expect(ar.word('casa'), isNull);

      expect(es.played('es-intro'), isTrue);
      expect(es.played('ar-story-1'), isFalse);
      expect(ar.played('ar-story-1'), isTrue);
      expect(ar.played('es-intro'), isFalse);

      expect(es.levelResult?['historias'], 1);
      expect(ar.levelResult, isNull);

      final futureAt = _t0 + 10 * _dayMs;
      expect(es.due(Skill.ear, at: futureAt), contains('casa'));
      expect(es.due(Skill.ear, at: futureAt), isNot(contains('مرحبا')));
      expect(ar.due(Skill.ear, at: futureAt), contains('مرحبا'));
      expect(ar.due(Skill.ear, at: futureAt), isNot(contains('casa')));

      expect(es.setting('min'), 45);
      expect(ar.setting('min'), 15);
      expect(es.added, ['café']);
      expect(ar.added, ['شاي']);
      expect(es.hasRead('libro-es'), isTrue);
      expect(es.hasRead('book-ar'), isFalse);
      expect(ar.hasRead('book-ar'), isTrue);
      expect(ar.hasRead('libro-es'), isFalse);

      // Shared cross-language data.
      expect(es.streak, 2);
      expect(ar.streak, 2);
      expect(stores.streak, 2);
      expect(es.minutes, 10.0);
      expect(ar.minutes, 10.0);
      expect(stores.minutes, 10.0);
      expect(es.minutesOn(day1), 4.5);
      expect(ar.minutesOn(day1), 4.5);
      expect(es.minutesOn(day2), 5.5);
      expect(ar.minutesOn(day2), 5.5);
      expect(stores.minutesOn(day2), 5.5);

      // Single-language reset clears only Arabic without wiping Spanish or shared streak/minutes.
      ar.reset();
      expect(ar.words, isEmpty);
      expect(ar.played('ar-story-1'), isFalse);
      expect(es.word('casa'), isNotNull);
      expect(es.played('es-intro'), isTrue);
      expect(es.streak, 2);
      expect(ar.streak, 2);
      expect(stores.minutes, 10.0);
      expect(stores.minutesOn(day2), 5.5);
    });

    test('addMinutes fires changes once on acting store, once on sibling store, and once on ProgressStores', () async {
      final kv = MemoryKeyValueStore();
      final clock = SettableClock(_t0);
      final stores = ProgressStores(kv, clock);
      final es = stores.forLanguage(Language.spanish);
      final ar = stores.forLanguage(arabic);

      var esCount = 0;
      var arCount = 0;
      var storesCount = 0;
      final subEs = es.changes.listen((_) => esCount++);
      final subAr = ar.changes.listen((_) => arCount++);
      final subStores = stores.changes.listen((_) => storesCount++);

      es.addMinutes(2.0);
      await pumpEventQueue();

      await subEs.cancel();
      await subAr.cancel();
      await subStores.cancel();

      expect(esCount, 1);
      expect(arCount, 1);
      expect(storesCount, 1);
    });
  });

  group('ProgressStores discovery and currentLanguageCode', () {
    test('empty store reports no languages with progress and zero writes', () {
      final kv = MemoryKeyValueStore();
      final clock = SettableClock(_t0);
      final stores = ProgressStores(kv, clock);

      expect(stores.languagesWithProgress, isEmpty);
      expect(stores.hasProgress('es'), isFalse);
      expect(stores.currentLanguageCode, 'es');
      expect(kv.writes, 0);
    });

    test('settings-only and minutes-only do not count as progress; word-only and story-only both count', () {
      final kv = MemoryKeyValueStore();
      final clock = SettableClock(_t0);
      final stores = ProgressStores(kv, clock);

      final es = stores.forLanguage(Language.spanish);
      es.setSetting('min', 20);
      es.addMinutes(5);
      expect(es.hasProgress, isFalse);
      expect(stores.hasProgress('es'), isFalse);
      expect(stores.languagesWithProgress, isEmpty);

      // Word-only progress in Spanish.
      es.answer('agua', Skill.ear, ok: true, ms: 400);
      expect(es.hasProgress, isTrue);
      expect(stores.languagesWithProgress, ['es']);

      // Story-only progress in Arabic (story with no focusWords/decisions).
      final ar = stores.forLanguage(arabic);
      ar.storyFinished(StoryResult(id: 'ar-opening'));
      expect(ar.words, isEmpty);
      expect(ar.hasProgress, isTrue);
      expect(stores.languagesWithProgress, ['es', 'ar']);

      // Persists across restart without passing languages:.
      final restarted = ProgressStores(kv, clock);
      expect(restarted.languagesWithProgress, ['es', 'ar']);
      expect(restarted.hasProgress('es'), isTrue);
      expect(restarted.hasProgress('ar'), isTrue);

      // Reset removes Arabic immediately and after restart.
      restarted.forLanguage(arabic).reset();
      expect(restarted.languagesWithProgress, ['es']);
      expect(restarted.hasProgress('ar'), isFalse);

      final restartedAgain = ProgressStores(kv, clock);
      expect(restartedAgain.languagesWithProgress, ['es']);
      expect(restartedAgain.hasProgress('ar'), isFalse);
    });

    test('discovers pre-seeded languages when languages: is passed or hasProgress(code) is queried', () {
      final kv = MemoryKeyValueStore();
      kv.data['coqui.fr.palabras.v1'] = jsonEncode({
        'palabras': {
          'bonjour': {'w': 'bonjour', 'primera': _t0, 'oida': 1},
        },
        'dias': <String, dynamic>{},
        'cuentos': <String, dynamic>{},
        'ajustes': {'min': 30, 'todo': 0, 'bienvenida': 0, 'habla': 1},
        'minutos': 0,
        'v': 1,
      });
      final clock = SettableClock(_t0);

      final withKnown = ProgressStores(kv, clock, languages: [french]);
      expect(withKnown.languagesWithProgress, ['fr']);
      expect(withKnown.hasProgress('fr'), isTrue);

      final withoutKnown = ProgressStores(kv, clock);
      expect(withoutKnown.hasProgress('fr'), isTrue);
    });

    test(
      'currentLanguageCode defaults to es, persists, and fires changes',
      () async {
        final kv = MemoryKeyValueStore();
        final clock = SettableClock(_t0);
        final stores = ProgressStores(kv, clock);

        expect(stores.currentLanguageCode, 'es');
        final events = await _countEvents(
          stores.changes,
          () => stores.currentLanguageCode = 'ar',
        );
        expect(events, 1);
        expect(stores.currentLanguageCode, 'ar');

        final restarted = ProgressStores(kv, clock);
        expect(restarted.currentLanguageCode, 'ar');

        expect(() => stores.currentLanguageCode = '', throwsArgumentError);
        expect(() => stores.currentLanguageCode = 'es.pr', throwsArgumentError);
        expect(() => stores.currentLanguageCode = 'es pr', throwsArgumentError);
      },
    );
  });

  group('storage resilience and legacy constructor compatibility', () {
    test('survives broken synchronous storage without throwing', () {
      final kv = MemoryKeyValueStore(broken: true);
      final clock = SettableClock(_t0);

      final stores = ProgressStores(kv, clock, languages: [arabic]);
      final es = stores.forLanguage(Language.spanish);
      es.answer('casa', Skill.ear, ok: true, ms: 400);
      es.addMinutes(3);
      stores.currentLanguageCode = 'ar';

      expect(es.word('casa'), isNotNull);
      expect(es.minutes, 3);
      expect(es.minutesOn(_day1Utc), 3);
      expect(es.streak, 1);
      expect(stores.currentLanguageCode, 'ar');
      expect(stores.languagesWithProgress, ['es']);
    });

    test('survives async failing storage without unhandled errors', () async {
      final kv = AsyncFailingKeyValueStore();
      final clock = SettableClock(_t0);

      final stores = ProgressStores(kv, clock);
      final es = stores.forLanguage(Language.spanish);
      es.answer('sol', Skill.ear, ok: true, ms: 300);
      es.addMinutes(2);
      stores.currentLanguageCode = 'ar';
      await pumpEventQueue();

      expect(es.word('sol'), isNotNull);
      expect(es.minutes, 2);
      expect(stores.currentLanguageCode, 'ar');
    });

    test('storageKeyFor rejects invalid language codes', () {
      expect(PalabrasStore.storageKeyFor('es'), 'coqui.es.palabras.v1');
      expect(PalabrasStore.storageKeyFor('es-PR'), 'coqui.es-PR.palabras.v1');
      expect(() => PalabrasStore.storageKeyFor(''), throwsArgumentError);
      expect(() => PalabrasStore.storageKeyFor('a.b'), throwsArgumentError);
      expect(() => PalabrasStore.storageKeyFor('a b'), throwsArgumentError);
    });

    test('legacy PalabrasStore(kv, clock) exposes new getters and in-memory minutesOn without altering coqui.palabras.v1 or creating coqui.shared.v1', () {
      final kv = MemoryKeyValueStore(key: PalabrasStore.storageKey);
      final clock = SettableClock(_t0);
      final store = PalabrasStore(kv, clock);

      expect(store.language, Language.spanish);
      expect(store.stageMax, 4);
      expect(store.streakFreezes, isNull);
      expect(store.minutesOn(_day1Utc), 0);

      store.addMinutes(3.5);
      expect(store.minutes, 3.5);
      expect(store.minutesOn(_day1Utc), 3.5);
      expect(kv.data.containsKey(PalabrasStore.sharedStorageKey), isFalse);
      expect(kv.data.containsKey('coqui.es.palabras.v1'), isFalse);

      final saved = jsonDecode(
        kv.data[PalabrasStore.storageKey]!,
      ) as Map<String, dynamic>;
      expect(saved.containsKey('minutosDia'), isFalse);
      expect(saved['minutos'], 3.5);

      store.reset();
      expect(store.minutesOn(_day1Utc), 0);
    });

    test('standalone language stores on the same KeyValueStore coordinate shared minutes, streak, idiomas, and changes', () async {
      final kv = MemoryKeyValueStore();
      final clock = SettableClock(_t0);
      final es = PalabrasStore(kv, clock, language: Language.spanish);
      final ar = PalabrasStore(kv, clock, language: arabic);

      var esEvents = 0;
      var arEvents = 0;
      final subEs = es.changes.listen((_) => esEvents++);
      final subAr = ar.changes.listen((_) => arEvents++);

      es.addMinutes(4);
      ar.addMinutes(3);
      await pumpEventQueue();

      expect(es.minutes, 7);
      expect(ar.minutes, 7);
      expect(es.minutesOn(_day1Utc), 7);
      expect(ar.minutesOn(_day1Utc), 7);
      expect(es.streak, 1);
      expect(ar.streak, 1);
      expect(esEvents, 2); // 1 own save + 1 sibling shared update
      expect(arEvents, 2); // 1 sibling shared update + 1 own save

      es.answer('casa', Skill.ear, ok: true, ms: 400);
      ar.answer('مرحبا', Skill.ear, ok: true, ms: 400);
      final shared = jsonDecode(
        kv.data[PalabrasStore.sharedStorageKey]!,
      ) as Map<String, dynamic>;
      expect(shared['minutos'], 7);
      expect(shared['idiomas'], ['es', 'ar']);

      // ProgressStores on the same kv also coordinates live with standalone stores.
      final stores = ProgressStores(kv, clock);
      stores.forLanguage(french).addMinutes(2.5);
      expect(es.minutes, 9.5);
      expect(ar.minutes, 9.5);
      expect(stores.minutes, 9.5);

      await subEs.cancel();
      await subAr.cancel();
      es.dispose();
      ar.dispose();
      stores.dispose();
      await expectLater(es.changes, emitsDone);
      await expectLater(stores.changes, emitsDone);
    });

    test('storyFinished, presume, and heard+addMinutes emit one sibling changes event each', () async {
      final kv = MemoryKeyValueStore();
      final clock = SettableClock(_t0);
      final stores = ProgressStores(kv, clock);
      final es = stores.forLanguage(Language.spanish);
      final ar = stores.forLanguage(arabic);

      expect(
        await _countEvents(
          ar.changes,
          () => es.storyFinished(StoryResult(id: 'la-lluvia')),
        ),
        1,
      );
      expect(
        await _countEvents(
          es.changes,
          () => ar.presume(['مرحبا'], ['ar-1'], const []),
        ),
        1,
      );

      final fr = stores.forLanguage(french);
      fr.heard('bonjour');
      expect(await _countEvents(es.changes, () => fr.addMinutes(1.5)), 1);
      expect(stores.languagesWithProgress, ['es', 'ar', 'fr']);
      stores.dispose();
    });

    test(
      'invalid persisted idioma in coqui.shared.v1 falls back to es on load',
      () {
        final kv = MemoryKeyValueStore();
        kv.data[PalabrasStore.sharedStorageKey] = jsonEncode({
          'dias': <String, dynamic>{},
          'minutos': 0,
          'minutosDia': <String, dynamic>{},
          'idiomas': <Object?>[],
          'idioma': 'bad.code',
          'v': 1,
        });
        final stores = ProgressStores(kv, SettableClock(_t0));
        expect(stores.currentLanguageCode, 'es');
        stores.dispose();
      },
    );
  });
}
