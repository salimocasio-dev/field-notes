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

    test('everything built played: listen again, six times at most', () {
      final p = plan(fixture(seed: 'todo'));
      expect(p, hasLength(6));
      expect(p.every((e) => e.line == 'Listen again'), isTrue);
      expect(p.first.title, 'La lluvia');
      expect(p.first.minutes, 2);
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
}

/// A course in which no place has a story.
class _NoStories extends MapFixtureCourse {
  _NoStories() : super(builtPlaces: 0);
}
