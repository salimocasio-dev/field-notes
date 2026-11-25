// The map's pure parts: the state read from the progress (app.html: hecho, abierto, aqui), today's plan
// (app.html: plan), the road the frog hops, the hop itself, the nearest stop to a tap, the grey of a locked place.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_map/src/map_layout.dart';
import 'package:feature_map/src/map_model.dart';
import 'package:feature_map/src/map_picture.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_fixture.dart';

void main() {
  group('the state, by app.html', () {
    test('nothing played: places 1 to 3 have stories and are open; the frog is on place 1', () {
      final f = fixture(seed: 'vacio');
      final st = mapStateOf(f.progress, f.services.course);
      expect(st.hecho, everyElement(isFalse));
      expect(st.abierto, [
        true,
        true,
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
      ]);
      expect(st.aqui, 0);
    });

    test('mid-course: place 1 done, the frog on place 2', () {
      final f = fixture(seed: 'curso');
      final st = mapStateOf(f.progress, f.services.course);
      expect(st.hecho, [
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
      ]);
      expect(st.aqui, 1);
    });

    test('everything built played: three places done and the frog back on place 1 (the old page does the same)', () {
      final f = fixture(seed: 'todo');
      final st = mapStateOf(f.progress, f.services.course);
      expect(st.hecho.take(4), [true, true, true, false]);
      expect(st.aqui, 0);
    });

    test('a place is done only when every story of it is played', () {
      final f = fixture(seed: 'vacio');
      final casa = f.services.course.places[0];
      for (final id in casa.stories.take(casa.stories.length - 1)) {
        finishStory(f.progress, id);
      }
      expect(placeDone(f.progress, casa), isFalse);
      expect(storiesPlayed(f.progress, casa), casa.stories.length - 1);
      finishStory(f.progress, casa.stories.last);
      expect(placeDone(f.progress, casa), isTrue);
      expect(storiesPlayed(f.progress, casa), casa.stories.length);
    });

    test('a place with no stories is never done, and is open only with "Open every place"', () {
      final f = fixture(seed: 'vacio');
      final colmado = f.services.course.places[3];
      expect(placeDone(f.progress, colmado), isFalse);
      expect(placeOpen(f.progress, colmado), isFalse);
      f.progress.setSetting('todo', 1);
      expect(placeOpen(f.progress, colmado), isTrue);
      expect(placeDone(f.progress, colmado), isFalse);
      f.progress.setSetting('todo', 0);
      expect(placeOpen(f.progress, colmado), isFalse);
    });

    test('a place the course does not list is not open and not done', () {
      final st = MapState(
        hecho: const [true],
        abierto: const [true, true],
        aqui: 0,
      );
      expect(st.hecho, [
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
      ]);
      expect(st.abierto.where((o) => o).length, 2);
    });
  });

  group("today's plan, by app.html", () {
    List<TodayEntry> plan(MapFixture f) => todayPlan(
      progress: f.progress,
      course: f.services.course,
      clock: f.clock,
    );

    test('nothing played: three new stories, each to be played twice', () {
      final p = plan(fixture(seed: 'vacio'));
      expect(p, hasLength(3));
      expect(p.map((e) => e.title), [
        'La lluvia',
        'El bizcocho',
        '¿Dónde está el pájaro?',
      ]);
      expect(p.first.line, 'New story · play it twice');
      expect(p.first.minutes, 4);
      expect(p.first.subtitle, 'New story · play it twice · 4 min');
      expect(p.first.route, const StoryRoute('la-lluvia'));
      expect(p.any((e) => e.review), isFalse);
    });

    test('words due, with a picture pair, come first: at most ten, with the minutes of app.html', () {
      final p = plan(fixture(seed: 'curso'));
      expect(p.first.review, isTrue);
      expect(p.first.line, '10 words coming back');
      expect(p.first.minutes, 6);
      expect(p.first.route, const ReviewRoute());
      expect(p.first.title, isNull);
      final one = plan(fixture(seed: 'uno'));
      expect(one.first.line, '1 word coming back');
      expect(one.first.minutes, 3);
    });

    test('a due word with no picture pair is not offered', () {
      final f = fixture(seed: 'uno');
      final bare = fixture(seed: 'uno');
      expect(plan(f).first.review, isTrue);
      // the same store, a course in which no word has a pair
      final none = todayPlan(
        progress: bare.progress,
        course: MapFixtureCourse(),
        clock: bare.clock,
      );
      expect(none.any((e) => e.review), isFalse);
    });

    test('N: a due word with no picture pair is offered when Repaso can serve it (a sentence of a story he has finished); with no games\' data, today\'s rule', () {
      final f = fixture(seed: 'vacio');
      final progress = FakeProgressStore(clock: f.clock)
        ..storyFinished(StoryResult(id: 's1'));
      void word(String w, {required bool due}) => progress.put(
        WordRecord(
          w: w,
          primera: f.clock.nowMs(),
          ear: SkillRecord(
            etapa: 1,
            due: f.clock.nowMs() + (due ? -1 : 30) * 864e5,
          ),
        ),
      );
      // mesa is due and has no picture pair; sol and luna are met (the two wrong tiles beside its sentence)
      word('mesa', due: true);
      word('sol', due: false);
      word('luna', due: false);
      RepasoWord w(String x, {List<int> sentences = const []}) => RepasoWord(
        word: x,
        place: 'casa',
        scoring: RepasoScoring.queOyes,
        sentences: sentences,
      );
      final games = RepasoData(
        sentences: [
          RepasoSentence(
            clip: 'a',
            story: 's1',
            text: 'Abuela pone la mesa.',
            tokens: const ['abuela', 'pone', 'la', 'mesa'],
            forbidden: const ['mesa'],
            forHearing: true,
            forBuilding: false,
          ),
        ],
        words: [
          w('mesa', sentences: const [0]),
          w('sol'),
          w('luna'),
        ],
      );
      List<TodayEntry> planFor(MapFixtureCourse c) =>
          todayPlan(progress: progress, course: c, clock: f.clock);
      // the games' data read: mesa is served, so the card offers the review
      final withData = MapFixtureCourse()..repaso = games;
      expect(planFor(withData).first.review, isTrue);
      expect(planFor(withData).first.line, '1 word coming back');
      // no data: no word has a pair, so the review is not offered (today's rule)
      expect(planFor(MapFixtureCourse()).any((e) => e.review), isFalse);
      // a story he has not finished: mesa's sentence is not his yet
      final unfinished = FakeProgressStore(clock: f.clock)
        ..put(progress.word('mesa')!);
      expect(
        todayPlan(
          progress: unfinished,
          course: withData,
          clock: f.clock,
        ).any((e) => e.review),
        isFalse,
      );
    });

    test('everything built played: listen again, six times at most at 30 min, with listen: true', () {
      final p = plan(fixture(seed: 'todo'));
      expect(p, hasLength(6));
      expect(p.every((e) => e.line == 'Listen again'), isTrue);
      expect(p.every((e) => e.kind == TodayEntryKind.listenAgain), isTrue);
      expect(
        p.every((e) => e.route is StoryRoute && (e.route as StoryRoute).listen),
        isTrue,
      );
      expect(p.first.title, 'La lluvia');
      expect(p.first.minutes, 2);
      expect(p.first.route, const StoryRoute('la-lluvia', listen: true));
    });

    test('new and second plays route with listen: false; replays route with listen: true', () {
      final vacio = plan(fixture(seed: 'vacio'));
      expect(vacio.first.kind, TodayEntryKind.newStory);
      expect(vacio.first.route, const StoryRoute('la-lluvia'));

      final segunda = plan(fixture(seed: 'segunda'));
      expect(segunda.first.kind, TodayEntryKind.secondPlay);
      expect(segunda.first.route, const StoryRoute('la-lluvia'));

      final todo = plan(fixture(seed: 'todo'));
      expect(todo.first.kind, TodayEntryKind.listenAgain);
      expect(todo.first.route, const StoryRoute('la-lluvia', listen: true));
    });

    test('a story played once is the second play, at its own length', () {
      final p = plan(fixture(seed: 'segunda'));
      expect(p.first.title, 'La lluvia');
      expect(p.first.line, 'Second play');
      expect(p.first.minutes, 2);
    });

    test('the plan is sized to his minutes', () {
      final f = fixture(seed: 'vacio');
      f.progress.setSetting('min', 5);
      // 4 minutes of the first story are not enough for 5: a second story; then 8 >= 5 and it stops
      final p = plan(f);
      expect(p.map((e) => e.title), ['La lluvia', 'El bizcocho']);
    });

    test('review minutes count toward the daily minute budget', () {
      // uno has 1 due word (3 min review); La lluvia new is 4 min -> 3 + 4 = 7 meets min = 7
      final uno = fixture(seed: 'uno');
      uno.progress.setSetting('min', 7);
      final pUno = plan(uno);
      expect(pUno, hasLength(2));
      expect(pUno[0].review, isTrue);
      expect(pUno[0].minutes, 3);
      expect(pUno[1].title, 'La lluvia');
      expect(pUno[1].minutes, 4);

      // curso has 10+ due words (6 min review); min = 6 stops after review alone
      final cursoShort = fixture(seed: 'curso');
      cursoShort.progress.setSetting('min', 6);
      final pShort = plan(cursoShort);
      expect(pShort, hasLength(1));
      expect(pShort.single.review, isTrue);
      expect(pShort.single.minutes, 6);

      // curso at min = 11: review (6) + La bola second play (5) = 11 -> stops before next new story
      final cursoMid = fixture(seed: 'curso');
      cursoMid.progress.setSetting('min', 11);
      final pMid = plan(cursoMid);
      expect(pMid, hasLength(2));
      expect(pMid[0].review, isTrue);
      expect(pMid[0].minutes, 6);
      expect(pMid[1].title, 'La bola');
      expect(pMid[1].minutes, 5);

      // review also reduces remaining budget for Listen again replays
      final f = fixture(seed: 'todo');
      // Add a due word that has a pair in MapFixtureCourse (pairWords = all words not due in todo)
      final pairWord = f.services.course.pairs.first.word;
      f.progress.put(
        WordRecord(
          w: pairWord,
          primera: f.clock.nowMs() - 86400000,
          ear: SkillRecord(etapa: 1, due: f.clock.nowMs() - 1000),
        ),
      );
      // 1 due word -> 3 min review; replays start at 2 + 3 + 3 = 8 min -> 3 + 8 = 11 >= 11
      f.progress.setSetting('min', 11);
      final pReplay = plan(f);
      expect(pReplay, hasLength(4));
      expect(pReplay.first.review, isTrue);
      expect(pReplay.first.minutes, 3);
      expect(pReplay.skip(1).map((e) => e.minutes).toList(), const [2, 3, 3]);
      expect(
        pReplay
            .skip(1)
            .every(
              (e) =>
                  e.kind == TodayEntryKind.listenAgain &&
                  e.route is StoryRoute &&
                  (e.route as StoryRoute).listen,
            ),
        isTrue,
      );
    });

    test('replay cap stays at 6 for min <= 30 and scales proportionally for 60 and 120 minute goals', () {
      // With todo, min <= 30 caps at 6 replays (15 min stops at 5 replays = 15 min; 30 min caps at 6 = 19 min)
      for (final (goal, expectedLen) in [(15, 5), (30, 6)]) {
        final t = fixture(seed: 'todo');
        t.progress.setSetting('min', goal);
        final p = plan(t);
        expect(p, hasLength(expectedLen), reason: 'goal=$goal');
        expect(
          p.every(
            (e) =>
                e.kind == TodayEntryKind.listenAgain &&
                e.route is StoryRoute &&
                (e.route as StoryRoute).listen,
          ),
          isTrue,
        );
      }

      // Single 2-min story only: 15 min caps at 6 replays (12 min), 30 min caps at 6 replays (12 min)
      final singleStoryCourse = _SingleStoryCourse('la-lluvia', 'La lluvia', 2);
      for (final goal in [15, 30]) {
        final f = fixture(seed: 'vacio');
        finishStory(f.progress, 'la-lluvia');
        finishStory(f.progress, 'la-lluvia');
        f.progress.setSetting('min', goal);
        final p = todayPlan(
          progress: f.progress,
          course: singleStoryCourse,
          clock: f.clock,
        );
        expect(p, hasLength(6), reason: 'goal=$goal');
        expect(
          p.every(
            (e) => e.route == const StoryRoute('la-lluvia', listen: true),
          ),
          isTrue,
        );
      }

      // 60-min goal scales replay cap to 12 (2x of 6)
      final todo60 = fixture(seed: 'todo');
      todo60.progress.setSetting('min', 60);
      final p60 = plan(todo60);
      expect(p60, hasLength(12));
      expect(
        p60.every(
          (e) =>
              e.kind == TodayEntryKind.listenAgain &&
              e.route is StoryRoute &&
              (e.route as StoryRoute).listen,
        ),
        isTrue,
      );

      // 120-min goal scales replay cap to 24 (4x of 6)
      final todo120 = fixture(seed: 'todo');
      todo120.progress.setSetting('min', 120);
      final p120 = plan(todo120);
      expect(p120, hasLength(24));
      expect(
        p120.every(
          (e) =>
              e.kind == TodayEntryKind.listenAgain &&
              e.route is StoryRoute &&
              (e.route as StoryRoute).listen,
        ),
        isTrue,
      );

      // With 5-min stories, 60-min fills to 60 min (12 replays) and 120-min fills to 120 min (24 replays)
      final fiveMinCourse = _SingleStoryCourse('la-mesa', 'La mesa', 5);
      for (final (goal, expectedCount) in [(30, 6), (60, 12), (120, 24)]) {
        final f = fixture(seed: 'vacio');
        finishStory(f.progress, 'la-mesa');
        finishStory(f.progress, 'la-mesa');
        f.progress.setSetting('min', goal);
        final p = todayPlan(
          progress: f.progress,
          course: fiveMinCourse,
          clock: f.clock,
        );
        expect(p, hasLength(expectedCount), reason: 'goal=$goal');
        final totalMin = p.fold<int>(0, (sum, e) => sum + e.minutes);
        expect(totalMin, goal, reason: 'goal=$goal');
      }

      // With 6-min stories, stops once minute budget is reached before hitting the scaled cap
      final sixMinCourse = _SingleStoryCourse(
        'no-hay-leche',
        'No hay leche',
        6,
      );
      final f60 = fixture(seed: 'vacio');
      finishStory(f60.progress, 'no-hay-leche');
      finishStory(f60.progress, 'no-hay-leche');
      f60.progress.setSetting('min', 60);
      final pSix60 = todayPlan(
        progress: f60.progress,
        course: sixMinCourse,
        clock: f60.clock,
      );
      expect(pSix60, hasLength(10));
      expect(pSix60.fold<int>(0, (sum, e) => sum + e.minutes), 60);
    });

    test('with nothing at all to offer the card offers the review of all his words', () {
      final f = fixture();
      final p = todayPlan(
        progress: f.progress,
        course: _NoStories(),
        clock: f.clock,
      );
      expect(p, hasLength(1));
      expect(p.single.review, isTrue);
      expect(p.single.line, 'All your words');
      expect(p.single.minutes, 3);
    });
  });

  group('the road and the hop', () {
    test('the road from stop to stop turns at corners, one axis at a time', () {
      final r = route(0, 9);
      expect(r.first, PADS[0]);
      expect(r.last, PADS[9]);
      for (var i = 1; i < r.length; i++) {
        final du = r[i][0] - r[i - 1][0], dv = r[i][1] - r[i - 1][1];
        expect(du == 0 || dv == 0, isTrue, reason: 'leg $i');
        expect(du == 0 && dv == 0, isFalse, reason: 'leg $i');
      }
      expect(route(3, 3), [PADS[3]]);
    });

    test('the frog hops about 2.2 units, a fifth of a second each, squashes on landing, and says when he is there', () {
      var arrived = 0;
      final hopSounds = <int>[];
      final map = MapPicture(onHop: () => hopSounds.add(1))..placeFrog(0);
      map.hopTo(2, () => arrived++);
      final hops = map.FROG.path!.length;
      // 5 units across and 15 up: 2 + 7 hops
      expect(hops, 9);
      var t = 0.0;
      while (map.FROG.path != null) {
        map.updateFrog(.05);
        t += .05;
        expect(map.FROG.z, greaterThanOrEqualTo(0));
        expect(t, lessThan(5));
      }
      expect(arrived, 1);
      expect(hopSounds, hasLength(hops));
      expect(t, closeTo(hops * .2, .06));
      expect(map.FROG.at, 2);
      expect(map.FROG.yaw, map.b.FACE);
      expect(map.FROG.squash, 1);
      final stop = XY(PADS[2][0], PADS[2][1]);
      expect(map.FROG.x, closeTo(stop.x, 1e-9));
      expect(map.FROG.y, closeTo(stop.y, 1e-9));
      // he straightens up again
      map.updateFrog(.1);
      expect(map.FROG.squash, closeTo(.6, 1e-9));
      map.updateFrog(1);
      expect(map.FROG.squash, 0);
    });

    test('a hop to the stop he is at is done at once', () {
      final m = MapPicture()..placeFrog(4);
      var done = 0;
      m.hopTo(4, () => done++);
      expect(done, 1);
      expect(m.FROG.path, isNull);
    });
  });

  group('the tap', () {
    final m = MapPicture();
    test('each stop and each place picture finds its own number', () {
      for (var k = 0; k < placeCount; k++) {
        final s = m.stopOnPicture(k);
        expect(m.stopAt(s.sx, s.sy), k, reason: 'stop $k');
        final xy = XY(DIO[k][0], DIO[k][1]), p = m.e.project(xy.x, xy.y, 1);
        expect(m.stopAt(p.sx, p.sy), k, reason: 'place $k');
      }
    });

    test('within 22 picture pixels of a stop, not beyond', () {
      final s = m.stopOnPicture(3);
      expect(m.stopAt(s.sx + 21.5, s.sy), 3);
      expect(m.stopAt(s.sx - 21.5, s.sy), 3);
      expect(m.stopAt(s.sx, s.sy + 21.5), 3);
      expect(m.stopAt(s.sx + 22.5, s.sy), isNot(3));
      expect(m.stopAt(5, 5), -1);
    });
  });

  test('a locked place goes to a cool grey', () {
    final m = MapPicture();
    expect(m.greyOf(m.e.rgb(255, 255, 255)), m.e.rgb(221, 230, 255));
    expect(m.greyOf(m.e.rgb(0, 0, 0)), m.e.rgb(38, 42, 56));
    // l = 200 * .3 + 100 * .55 + 50 * .15 = 122.5
    expect(m.greyOf(m.e.rgb(200, 100, 50)), m.e.rgb(126, 132, 154));
  });

  _nocheHelpersTests();
}

/// A course in which no place has a story.
class _NoStories extends MapFixtureCourse {
  _NoStories() : super(builtPlaces: 0);
}

/// A course with a single story of fixed length, for testing replay budget & caps.
class _SingleStoryCourse extends MapFixtureCourse {
  _SingleStoryCourse(this._storyId, this._title, this._minutes)
    : super(builtPlaces: 0);

  final String _storyId;
  final String _title;
  final int _minutes;

  @override
  List<Place> get places => [
    Place(
      id: 'casa',
      n: 1,
      name: 'La casa',
      en: "Grandma's house",
      stories: [_storyId],
      scenes: const ['El frente'],
    ),
  ];

  @override
  StoryMeta? meta(String id) => id == _storyId
      ? StoryMeta(id: _storyId, title: _title, minutes: _minutes)
      : null;
}

void _nocheHelpersTests() {
  group('N4.1 Up next card helpers', () {
    test(
      'upNextKind maps each TodayEntryKind without matching English copy',
      () {
        const s1 = TodayEntry(
          title: 'Tengo hambre',
          line: 'arbitrary copy',
          minutes: 5,
          route: StoryRoute('tengo-hambre'),
          kind: TodayEntryKind.newStory,
        );
        const s2 = TodayEntry(
          title: 'La lluvia',
          line: 'arbitrary copy',
          minutes: 2,
          route: StoryRoute('la-lluvia'),
          kind: TodayEntryKind.secondPlay,
        );
        const s3 = TodayEntry(
          title: 'La lluvia',
          line: 'arbitrary copy',
          minutes: 2,
          route: StoryRoute('la-lluvia'),
          kind: TodayEntryKind.listenAgain,
        );
        const rev = TodayEntry(
          line: '3 words coming back',
          minutes: 3,
          route: ReviewRoute(),
          review: true,
          kind: TodayEntryKind.review,
        );
        expect(upNextKind(s1), 'New story');
        expect(upNextKind(s2), 'Second play');
        expect(upNextKind(s3), 'Listen again');
        expect(upNextKind(rev), '3 words coming back');
      },
    );

    test('upNextThenLine formats 0, 1, and 2 steps after the first entry', () {
      const storyNew = TodayEntry(
        title: 'A',
        line: 'New story · play it twice',
        minutes: 4,
        route: StoryRoute('a'),
        kind: TodayEntryKind.newStory,
      );
      const review = TodayEntry(
        line: '3 words coming back',
        minutes: 3,
        route: ReviewRoute(),
        review: true,
        kind: TodayEntryKind.review,
      );
      const call = TodayEntry(
        title: 'Call',
        line: 'Call Danny',
        minutes: 5,
        route: CallRoute('casa'),
        kind: TodayEntryKind.call,
      );
      const listening = TodayEntry(
        title: 'B',
        line: 'Listen again',
        minutes: 2,
        route: StoryRoute('b'),
        kind: TodayEntryKind.listenAgain,
      );
      expect(upNextThenLine(const []), isNull);
      expect(upNextThenLine(const [storyNew]), isNull);
      expect(upNextThenLine(const [storyNew, review]), 'Then review');
      expect(
        upNextThenLine(const [storyNew, review, call, listening]),
        'Then review, then a call',
      );
      expect(
        upNextThenLine(const [review, storyNew, listening]),
        'Then a new story, then listening',
      );
    });

    test(
      'todayPlan entries produce expected kinds, upNextKind, and planStepLabel',
      () {
        List<TodayEntry> planFor(MapFixture f) => todayPlan(
          progress: f.progress,
          course: f.services.course,
          clock: f.clock,
        );

        final vacio = planFor(fixture(seed: 'vacio'));
        expect(vacio.first.kind, TodayEntryKind.newStory);
        expect(upNextKind(vacio.first), 'New story');
        expect(planStepLabel(vacio.first), 'a new story');
        expect(upNextThenLine(vacio), 'Then a new story, then a new story');

        final segunda = planFor(fixture(seed: 'segunda'));
        expect(segunda.first.kind, TodayEntryKind.secondPlay);
        expect(upNextKind(segunda.first), 'Second play');
        expect(planStepLabel(segunda.first), 'listening');
        expect(upNextThenLine(segunda), 'Then a new story, then a new story');

        final uno = planFor(fixture(seed: 'uno'));
        expect(uno.first.kind, TodayEntryKind.review);
        expect(upNextKind(uno.first), uno.first.line);
        expect(planStepLabel(uno.first), 'review');
        expect(upNextThenLine(uno), 'Then a new story, then a new story');

        final todo = planFor(fixture(seed: 'todo'));
        expect(todo.first.kind, TodayEntryKind.listenAgain);
        expect(upNextKind(todo.first), 'Listen again');
        expect(planStepLabel(todo.first), 'listening');
        expect(upNextThenLine(todo), 'Then listening, then listening');

        final empty = todayPlan(
          progress: fixture().progress,
          course: _NoStories(),
          clock: fixture().clock,
        );
        expect(empty.single.kind, TodayEntryKind.review);
        expect(upNextKind(empty.single), 'All your words');
        expect(planStepLabel(empty.single), 'review');
        expect(upNextThenLine(empty), isNull);
      },
    );

    test('placeIndexForStory finds the owning place index', () {
      final course = MapFixtureCourse(builtPlaces: 3);
      expect(placeIndexForStory(course.places, 'la-lluvia'), 0);
      expect(placeIndexForStory(course.places, 'tengo-hambre'), 2);
      expect(placeIndexForStory(course.places, 'missing'), isNull);
    });

    test(
      'placeInPlan and storyInPlan gate places past place 1 by everyPlace',
      () {
        final course = MapFixtureCourse(builtPlaces: 3);
        final casa = course.places[0];
        final parque = course.places[1];
        final cocina = course.places[2];

        const allowAll = AllowAllEntitlements();
        expect(placeInPlan(casa, course.places, allowAll), isTrue);
        expect(placeInPlan(parque, course.places, allowAll), isTrue);
        expect(placeInPlan(cocina, course.places, allowAll), isTrue);
        expect(storyInPlan('la-lluvia', course.places, allowAll), isTrue);
        expect(storyInPlan('uno-dos-tres', course.places, allowAll), isTrue);
        expect(storyInPlan('missing', course.places, allowAll), isTrue);

        final free = FakeEntitlements(plan: Plan.free);
        addTearDown(free.dispose);
        expect(placeInPlan(casa, course.places, free), isTrue);
        expect(placeInPlan(parque, course.places, free), isFalse);
        expect(placeInPlan(cocina, course.places, free), isFalse);
        expect(placeInPlan(casa, const [], free), isTrue);
        expect(placeInPlan(parque, const [], free), isFalse);
        expect(storyInPlan('la-lluvia', course.places, free), isTrue);
        expect(storyInPlan('uno-dos-tres', course.places, free), isFalse);
        expect(storyInPlan('tengo-hambre', course.places, free), isFalse);
        expect(storyInPlan('missing', course.places, free), isFalse);

        final coursePlan = FakeEntitlements(plan: Plan.course);
        addTearDown(coursePlan.dispose);
        expect(placeInPlan(casa, course.places, coursePlan), isTrue);
        expect(placeInPlan(parque, course.places, coursePlan), isTrue);
        expect(placeInPlan(cocina, course.places, coursePlan), isTrue);
        expect(storyInPlan('uno-dos-tres', course.places, coursePlan), isTrue);

        final callsPlan = FakeEntitlements(plan: Plan.courseAndCalls);
        addTearDown(callsPlan.dispose);
        expect(placeInPlan(parque, course.places, callsPlan), isTrue);
        expect(storyInPlan('uno-dos-tres', course.places, callsPlan), isTrue);
      },
    );
  });
}
