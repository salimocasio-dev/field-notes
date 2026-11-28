import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:test/test.dart';

final Language _arabic = Language(
  code: 'ar',
  englishName: 'Arabic',
  nativeName: 'العربية',
  recognitionLocale: 'ar-SA',
  direction: LanguageDirection.rtl,
  script: 'Arab',
  partnerName: 'Nadia',
  callAgentId: 'agent_ar_test',
  micWords: const {
    'ready': 'تحدث',
    'listening': 'أستمع',
    'thinking': 'لحظة',
    'theySpeak': 'اسمع',
    'right': 'ممتاز',
    'notYet': 'مرة أخرى',
  },
  tabNames: const {
    'library': 'المكتبة',
    'words': 'الكلمات',
    'map': 'الخريطة',
    'speak': 'تحدث',
    'me': 'أنا',
  },
);

class _LegacyProgressStore implements ProgressStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LanguageAwareProgressStore extends _LegacyProgressStore
    implements LanguageProgressStore {
  _LanguageAwareProgressStore({
    required this.language,
    required this.byDay,
    required this.stageMax,
    this.streakFreezes,
  });

  @override
  final Language language;

  final Map<String, double> byDay;

  @override
  final int stageMax;

  @override
  final int? streakFreezes;

  @override
  double minutesOn(DateTime day) {
    final utc = day.toUtc();
    final key = '${utc.year}-${utc.month}-${utc.day}';
    return byDay[key] ?? 0;
  }
}

class _FakeCollection implements ProgressStoreCollection {
  final Map<String, ProgressStore> _stores = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  String _current = 'es';

  @override
  ProgressStore forLanguage(Language language) =>
      _stores.putIfAbsent(language.code, () => _LegacyProgressStore());

  @override
  List<String> get languagesWithProgress => _stores.keys.toList();

  @override
  bool hasProgress(String languageCode) => _stores.containsKey(languageCode);

  @override
  String get currentLanguageCode => _current;

  @override
  set currentLanguageCode(String code) {
    _current = code;
    _changes.add(null);
  }

  @override
  int get streak => 7;

  @override
  double get minutes => 42.5;

  @override
  double minutesOn(DateTime day) =>
      day.toUtc() == DateTime.utc(2026, 11, 25) ? 12.5 : 0;

  @override
  Stream<void> get changes => _changes.stream;

  void close() => _changes.close();
}

class _LegacyClipPlayer implements ClipPlayer {
  final List<(String, Duration?)> plays = [];
  bool nextResult = true;

  @override
  Future<bool> play(String clipId, {Duration? limit}) async {
    plays.add((clipId, limit));
    return nextResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VariableSpeedPlayer extends _LegacyClipPlayer
    implements VariableSpeedClipPlayer {
  final List<(String, double, Duration?)> ratePlays = [];

  @override
  Future<bool> playAtRate(
    String clipId, {
    double rate = 1.0,
    Duration? limit,
  }) async {
    ratePlays.add((clipId, rate, limit));
    return nextResult;
  }
}

class _LegacyKeyValueStore implements KeyValueStore {
  final Map<String, String> data = {};

  @override
  String? read(String key) => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

class _DeletableStore extends _LegacyKeyValueStore
    implements DeletableKeyValueStore {
  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

void main() {
  group('LanguageProgressStore and LanguageProgress', () {
    test('returns backward-compatible defaults on legacy ProgressStore', () {
      final ProgressStore store = _LegacyProgressStore();
      expect(store.language, Language.spanish);
      expect(store.minutesOn(DateTime.utc(2026, 11, 25)), 0);
      expect(store.stageMax, 4);
      expect(store.streakFreezes, isNull);
    });

    test('delegates to LanguageProgressStore when implemented', () {
      final ProgressStore store = _LanguageAwareProgressStore(
        language: _arabic,
        byDay: const {'2026-11-25': 14.5},
        stageMax: 5,
        streakFreezes: 2,
      );
      expect(store.language, _arabic);
      expect(store.minutesOn(DateTime.utc(2026, 11, 25, 18, 30)), 14.5);
      expect(store.minutesOn(DateTime.utc(2026, 11, 24)), 0);
      expect(store.stageMax, 5);
      expect(store.streakFreezes, 2);
    });
  });

  group('ProgressStoreCollection', () {
    test('supports per-language stores and shared metrics', () async {
      final raw = _FakeCollection();
      addTearDown(raw.close);
      final ProgressStoreCollection collection = raw;

      final events = <void>[];
      final sub = collection.changes.listen(events.add);
      addTearDown(sub.cancel);

      expect(collection.languagesWithProgress, isEmpty);
      expect(collection.hasProgress('ar'), isFalse);
      expect(collection.currentLanguageCode, 'es');

      final arStore = collection.forLanguage(_arabic);
      expect(collection.forLanguage(_arabic), same(arStore));
      expect(collection.hasProgress('ar'), isTrue);
      expect(collection.languagesWithProgress, ['ar']);

      collection.currentLanguageCode = 'ar';
      await Future<void>.delayed(Duration.zero);
      expect(collection.currentLanguageCode, 'ar');
      expect(events, hasLength(1));

      expect(collection.streak, 7);
      expect(collection.minutes, 42.5);
      expect(collection.minutesOn(DateTime.utc(2026, 11, 25)), 12.5);
      expect(collection.minutesOn(DateTime.utc(2026, 11, 24)), 0);
    });
  });

  group('VariableSpeedClipPlayer and ClipPlayerSpeed', () {
    test('falls back to ClipPlayer.play when player omits interface', () async {
      final legacy = _LegacyClipPlayer()..nextResult = false;
      final ClipPlayer player = legacy;
      const limit = Duration(milliseconds: 800);

      final ok = await player.playAtRate('clip_1', rate: 0.75, limit: limit);
      expect(ok, isFalse);
      expect(legacy.plays, [('clip_1', limit)]);
    });

    test('delegates playAtRate with default and custom rates', () async {
      final speed = _VariableSpeedPlayer()..nextResult = true;
      final ClipPlayer player = speed;
      const limit = Duration(milliseconds: 500);

      expect(await player.playAtRate('c1'), isTrue);
      expect(await player.playAtRate('c2', rate: 0.9, limit: limit), isTrue);

      expect(speed.plays, isEmpty);
      expect(speed.ratePlays, [('c1', 1.0, null), ('c2', 0.9, limit)]);
    });
  });

  group('DeletableKeyValueStore and KeyValueStoreDelete', () {
    test(
      'fails with UnsupportedError when store omits DeletableKeyValueStore',
      () async {
        final legacy = _LegacyKeyValueStore();
        await legacy.write('k', 'v');
        final KeyValueStore store = legacy;

        await expectLater(store.delete('k'), throwsUnsupportedError);
        expect(store.read('k'), 'v');
      },
    );

    test('delegates delete asynchronously when implemented', () async {
      final deletable = _DeletableStore();
      await deletable.write('k1', 'v1');
      await deletable.write('k2', 'v2');
      final KeyValueStore store = deletable;

      await store.delete('k1');
      await store.delete('missing');
      expect(store.read('k1'), isNull);
      expect(store.read('k2'), 'v2');
    });
  });
}
