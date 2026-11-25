// What the tests of the module share: a small course whose pieces the test sets, and a clip player that takes the
// time a clip takes (the fake clock of the test moves it).
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// A line of a story file.
Map<String, dynamic> line(String who, String text) => {
  'who': who,
  'text': text,
};

/// The course the tests use. Everything is in memory; [bookAsked] and [storyAsked] say what was fetched.
class TestCourse implements CourseCatalog {
  TestCourse({
    List<Place>? places,
    Map<String, StoryMeta>? metas,
    Map<String, Book>? books,
    Map<String, Map<String, dynamic>>? stories,
    List<ReviewPair>? pairs,
    Set<String>? recorded,
  }) : places = places ?? _places(),
       metas = metas ?? _metas(),
       books = books ?? _books(),
       stories = stories ?? _stories(),
       pairs = pairs ?? _pairs(),
       recorded =
           recorded ??
           {
             for (final s in _stories().values)
               ...((s['clips'] as Map).keys.cast<String>()),
           };

  @override
  final List<Place> places;
  final Map<String, StoryMeta> metas;
  final Map<String, Book> books;
  final Map<String, Map<String, dynamic>> stories;
  @override
  final List<ReviewPair> pairs;

  /// The clips that have a recording (and so marks).
  final Set<String> recorded;

  final List<String> bookAsked = [];
  final List<String> storyAsked = [];

  static List<Place> _places() => [
    Place(
      id: 'casa',
      n: 1,
      name: 'La casa',
      en: "Grandma's house",
      stories: ['uno', 'dos', 'tres'],
      pictureStories: ['d-uno'],
      routines: ['h-uno'],
    ),
    Place(
      id: 'parque',
      n: 2,
      name: 'El parque',
      en: 'The park',
      stories: ['cuatro', 'cinco'],
    ),
  ];

  static Map<String, StoryMeta> _metas() => {
    for (final e in {
      'uno': ('Uno', 2),
      'dos': ('Dos', 3),
      'tres': ('Tres', 4),
      'cuatro': ('Cuatro', 5),
      'cinco': ('Cinco', 6),
      'd-uno': ('Dibujo uno', 3),
      'h-uno': ('Haz uno', 1),
    }.entries)
      e.key: StoryMeta(id: e.key, title: e.value.$1, minutes: e.value.$2),
  };

  static Book _book(String id, bool lee, List<List<String>> pages) => Book(
    id: id,
    title: id,
    readable: lee,
    pages: [
      for (var i = 0; i < pages.length; i++)
        BookPage(image: 'img/$id-${i + 1}.png', clips: pages[i]),
    ],
  );

  static Map<String, Book> _books() => {
    'uno': _book('uno', true, [
      ['u1', 'u2', 'u3'],
      ['u4'],
      ['u5', 'u6'],
      ['u7'],
    ]),
    'dos': _book('dos', false, [
      ['u1'],
    ]),
    'tres': _book('tres', true, [
      ['u1'],
      ['u4'],
    ]),
    'd-uno': _book('d-uno', true, [
      ['u1'],
    ]),
    'cuatro': _book('cuatro', true, [
      ['u1'],
    ]),
  };

  static Map<String, Map<String, dynamic>> _stories() {
    final clips = {
      'u1': line(
        'abuela',
        'La hermana dice: Hola. Me llamo Carmen. Soy la hermana de Luis.',
      ),
      'u2': line('abuela', '¿Cómo estás? El hermano dice: Y yo me llamo Luis.'),
      'u3': line('tu', 'Yo soy Coquí. Me llamo Coquí.'),
      'u4': line('abuela', 'La casa es azul.'),
      'u5': line('abuela', 'Abuelo dice: ¡Ah! ¡Mis espejuelos!'),
      'u6': line('tu', '¡Sí! Yo soy Coquí.'),
      'u7': line('narr', 'Fin del cuento.'),
    };
    return {
      for (final id in ['uno', 'dos', 'tres', 'd-uno', 'cuatro'])
        id: {'title': id, 'clips': clips},
    };
  }

  static List<ReviewPair> _pairs() => [
    for (final w in ['hermana', 'hermano', 'casa', 'cómo estás', 'yo'])
      ReviewPair.fromJson({
        'w': w,
        'say': 'x',
        'si': {
          'cam': [10, 0],
        },
        'no': {
          'cam': [90, 0],
        },
      }, scene: 'frente'),
  ];

  @override
  Future<void> load() async {}

  @override
  StoryMeta? meta(String id) => metas[id];

  @override
  Future<Map<String, dynamic>> story(String id) async {
    storyAsked.add(id);
    final s = stories[id];
    if (s == null) throw StateError('no story $id');
    return s;
  }

  @override
  Future<Book?> book(String id) async {
    bookAsked.add(id);
    final b = books[id];
    return b == null ? null : Book.fromJson(b.toJson());
  }

  @override
  ReviewPair? pairFor(String word) {
    final lang = language;
    final n = lang.normalize(word);
    for (final p in pairs) {
      if (lang.normalize(p.word) == n) return p;
    }
    return null;
  }

  @override
  ClipInfo? clip(String id) {
    if (!recorded.contains(id)) return null;
    for (final s in stories.values) {
      final c = (s['clips'] as Map?)?[id] as Map?;
      if (c != null) {
        return ClipInfo(
          id: id,
          who: c['who'] as String,
          text: c['text'] as String,
          startMs: 0,
          endMs: 1000,
          url: 'audio/$id.mp3',
        );
      }
    }
    return null;
  }

  @override
  List<LevelItem> get levelItems => const [];
  @override
  CallBrief? callFor(String placeId) => null;
  @override
  String fixedClip(String role) => throw UnimplementedError();
  @override
  List<String> get goodbyeWords => const [];
  @override
  Future<List<HeardLine>> linesWith(
    String word,
    Iterable<String> storyIds, {
    int max = 5,
  }) async => const [];
}

/// A clip player that plays each recorded clip for [length] (time of the test, moved by `pump`), and says what it was asked.
class TimedClips implements ClipPlayer {
  TimedClips({this.length = const Duration(seconds: 1)});

  final Duration length;
  final List<String> played = [];
  final List<String> preloaded = [];
  final List<Completer<bool>> _pending = [];
  final List<Timer> _timers = [];
  int stops = 0;
  bool unlocked = false;

  /// What is playing now, or null.
  String? now;

  @override
  bool muted = false;

  @override
  Future<void> unlock() async => unlocked = true;

  @override
  Future<List<String>> preload(Iterable<String> clipIds) async {
    preloaded.addAll(clipIds);
    return const [];
  }

  @override
  Future<bool> play(String clipId, {Duration? limit}) {
    played.add(clipId);
    now = clipId;
    final done = Completer<bool>();
    _pending.add(done);
    _timers.add(
      Timer(length, () {
        if (!done.isCompleted) {
          if (now == clipId) now = null;
          done.complete(true);
        }
      }),
    );
    return done.future;
  }

  @override
  Future<void> stop() async {
    stops++;
    now = null;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    for (final c in _pending) {
      if (!c.isCompleted) c.complete(false);
    }
    _pending.clear();
  }

  @override
  void tone(
    double hz, {
    double at = 0,
    double dur = .1,
    String wave = 'square',
    double vol = .05,
    double? toHz,
  }) {}
  @override
  void noiseBurst({double vol = 1}) {}
  @override
  void loop(String name, bool on) {}
}

/// The services a test builds: the pieces it gives, the fakes for the rest.
class Rig {
  Rig({
    TestCourse? course,
    ProgressStore? progress,
    TimedClips? clips,
    FakeNavigator? nav,
    FakeHaptics? haptics,
    Map<String, FakeKeyValueStore>? spaces,
  }) : course = course ?? TestCourse(),
       clips = clips ?? TimedClips(),
       nav = nav ?? FakeNavigator(),
       haptics = haptics ?? FakeHaptics(),
       spaces = spaces ?? {} {
    this.progress = progress ?? FakeProgressStore();
  }

  final TestCourse course;
  final TimedClips clips;
  final FakeNavigator nav;
  final FakeHaptics haptics;
  final Map<String, FakeKeyValueStore> spaces;
  late final ProgressStore progress;

  FakeProgressStore get store => progress as FakeProgressStore;

  Services get services => fakeServices(
    progress: progress,
    course: course,
    clips: clips,
    nav: nav,
    haptics: haptics,
    storage: (space) => spaces.putIfAbsent(space, FakeKeyValueStore.new),
  );

  /// The progress of a player who has played [ids] (each once) and read [read].
  void played(List<String> ids, {List<String> read = const []}) {
    for (final id in ids) {
      store.storyFinished(
        StoryResult(
          id: id,
          focusWords: const [],
          backAgain: const [],
          lost: 0,
          log: const [],
        ),
      );
    }
    for (final id in read) {
      store.markRead(id);
    }
  }
}

/// Lets what loads and decodes finish (the pictures are made by the engine, in real time).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
  }
  await tester.pump();
}

/// Moves the test's time on and lets the page see it.
Future<void> advance(WidgetTester tester, Duration d) async {
  await tester.pump(d);
  await tester.pump();
}
