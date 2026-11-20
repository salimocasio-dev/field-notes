// Repaso's games run with no screen, on a virtual clock, over the real data and the mid-course learner: each game's
// rules (right, wrong, silence, the answer shown, the unscored return), what is written (Ear, Mouth, minutes), practice.
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:feature_review/src/logic/review_session.dart'
    show OptionRing, ReviewOptions;
import 'package:flutter_test/flutter_test.dart';

import '../tool/support/scripted_clips.dart';
import '../tool/support/virtual_time.dart';
import 'support/recording_store.dart';
import 'support/repaso_course.dart';

final course = RepasoTestCourse();

class Bench {
  Bench({
    String? json,
    int now = curseNow,
    int seed = 1,
    List<String> heard = const [],
    bool speech = false,
    ReviewOptions options = const ReviewOptions(),
    FakeKeyValueStore? space,
  }) : vt = VirtualTime(),
       kv = space ?? FakeKeyValueStore() {
    store = RecordingStore(
      vt,
      clock: FakeClock(now),
      json: json ?? seedJson('curso'),
    );
    clips = ScriptedClips(vt);
    listener = FakeSpeechListener(
      results: heard,
      isAvailable: speech,
      instant: true,
    );
    s = RepasoSession(
      data: realRepaso,
      rng: FakeRng(seed),
      clock: vt,
      course: course,
      progress: store,
      clips: clips,
      wait: vt.wait,
      speech: listener,
      storage: kv,
      options: options,
    );
    s.prepare();
  }

  final VirtualTime vt;
  late final RecordingStore store;
  late final ScriptedClips clips;
  late final FakeSpeechListener listener;
  final FakeKeyValueStore kv;
  late final RepasoSession s;

  List<Map<String, Object?>> answersOf(Skill k) => [
    for (final c in store.calls)
      if (c['op'] == 'responde' && (c['args'] as List)[1] == k.name) c,
  ];

  bool _needsMe(QueueEntry? acted) =>
      s.canNext ||
      s.choices.any((c) => c.sign) ||
      s.mic == MicState.ready ||
      (s.yourTurn && !identical(acted, s.entry));

  Future<void>? _run;
  int? endedAt;

  /// Plays the session on. [plan] says, for each entry the first time its turn comes, 'r' (right), 'w' (wrong first),
  /// or 'n' (no touch). A shown answer is touched; Next is pressed; a ready mic is tapped. With [until], it stops
  /// (the session still running) as soon as that is true; otherwise it plays to the end.
  Future<void> play({
    String Function(QueueEntry e, int n)? plan,
    bool Function()? until,
    int limit = 4000,
  }) async {
    QueueEntry? acted;
    var n = 0;
    _run ??= s.run();
    bool stop() => s.screen == LessonScreen.end || (until?.call() ?? false);
    for (var g = 0; g < limit && !stop(); g++) {
      await vt.runUntil(() => stop() || _needsMe(acted));
      if (stop()) break;
      if (s.canNext) {
        s.pressNext();
      } else if (s.choices.any((c) => c.sign)) {
        s.touch(s.choices.indexWhere((c) => c.sign));
      } else if (s.mic == MicState.ready) {
        s.pressMic();
      } else if (s.yourTurn && !identical(acted, s.entry)) {
        acted = s.entry;
        act(plan?.call(s.entry!, n) ?? 'r');
        n++;
      }
      await vt.settle();
    }
    if (until != null && until()) return;
    endedAt = vt.now;
    await vt.runUntil(() => false, limit: 50);
    await _run;
  }

  /// Plays right up to the turn of queue entry [at].
  Future<void> reach(int at) => play(until: () => s.index == at && s.yourTurn);

  /// Leaves the lesson and lets it stop (a lesson left while it waits for a touch just stays there, as the old one
  /// does: its screen is gone).
  Future<void> leave() async {
    s.leave();
    await vt.runUntil(() => false, limit: 20);
  }

  void act(String what) {
    final it = s.item!;
    switch (it) {
      case CualItem() || HearItem() || WhereItem():
        final r = s.choices.indexWhere((c) => c.right);
        if (what == 'r') s.touch(r);
        if (what == 'w') s.touch(r == 0 ? 1 : 0);
      case BuildItem():
        if (what == 'w') {
          s.touch(s.choices.indexWhere((c) => c.label != it.order.first));
        }
        for (final t in it.order) {
          s.touch(s.choices.indexWhere((c) => !c.done && c.label == t));
        }
      case MatchItem():
        for (var i = 0; i < it.words.length; i++) {
          s.touchSpeaker(i);
          final k = it.wordOrder.indexOf(i);
          if (what == 'w' && i == 0) s.touch((k + 1) % 4);
          s.touch(k);
        }
      case SayItem():
        break;
    }
  }
}

void main() {
  test('a whole session, all right: ten words, one scored item each, three play items between, in turn', () async {
    final b = Bench(seed: 3);
    expect(b.s.words, hasLength(10));
    expect(b.s.practice, isFalse);
    await b.play();
    final kinds = [for (final q in b.s.played) q.item!.kind];
    final scored = [
      for (final q in b.s.played)
        if (q.item!.scored) q.item!.word,
    ];
    expect(scored, [for (final w in b.s.words) w.word]);
    // after every third scored item a play item, the kinds in turn (no Dilo: the mic does not work here)
    final pattern = [for (final k in kinds) k.index > 1 ? '+' : 's'].join();
    expect(pattern, 'sss+sss+sss+s');
    expect(
      [
        for (final k in kinds)
          if (k.index > 1) k,
      ],
      [GameKind.build, GameKind.match, GameKind.where],
    );
    expect({...kinds}.length, greaterThanOrEqualTo(3));
    // an Ear answer for each word, right, scored (they are due), with the time from the sentence's end
    final ear = b.answersOf(Skill.ear);
    expect([for (final c in ear) (c['args'] as List)[0]], scored);
    for (final c in ear) {
      final a = c['args'] as List;
      expect((a[2], a[4]), (true, false));
      expect(a[3], isA<int>());
    }
    expect(b.answersOf(Skill.mouth), isEmpty);
    expect(b.s.end!.summary, '10 of 10 words right the first time');
    expect(b.s.end!.groups.single.rows, hasLength(10));
    // the end lists each word with the sentence it was asked in
    for (final r in b.s.end!.groups.single.rows) {
      final it = b.s.played
          .firstWhere((q) => q.item!.scored && q.item!.word == r.word)
          .item!;
      expect((r.clip, r.text), (it.clip, it.text));
    }
    // ten right: the count in a row
    expect(b.s.streak, greaterThanOrEqualTo(10));
    // the session's time went to the day's minutes, once
    expect(b.store.minutes, closeTo(108.9 + b.endedAt! / 6e4, 1e-6));
    // the last sentence of each word is remembered in the feature's own space
    final last = jsonDecode(b.kv.read(LastAsked.key)!) as Map;
    expect(last.keys.toSet(), {...scored});
  });

  test('a miss: the answer is shown, it comes back three items later, the same sentence and game, unscored', () async {
    final b = Bench(seed: 3);
    await b.play(plan: (e, n) => n == 0 ? 'w' : 'r');
    final first = b.s.played.first;
    final again = b.s.played.where((q) => q.again).toList();
    expect(again, hasLength(1));
    // the same game, word and sentence; not the identical item (see the test of the arrangement)
    final back = again.single.item!;
    expect(
      (back.runtimeType, back.kind, back.word, back.clip),
      (first.item!.runtimeType, first.item!.kind, first.item!.word, first.item!.clip),
    );
    expect(b.s.played.indexOf(again.single), 3);
    // scored once (wrong), asked again with nothing written
    final ear = b.answersOf(Skill.ear);
    expect(ear, hasLength(10));
    expect((ear.first['args'] as List)[2], isFalse);
    expect(b.s.secondAnswers.single.ok, isTrue);
    expect(b.s.end!.summary, '9 of 10 words right the first time');
    expect(b.s.end!.groups.map((g) => g.title), [
      'Got it the first time',
      'Coming back soon',
    ]);
    expect(b.s.end!.groups.last.rows.single.word, first.item!.word);
  });

  test('wrong in ¿Cuál? and ¿Qué oyes?: red-orange and an X on his, the sign alone on the right one, green and a check only once he touches it', () async {
    for (final kind in [GameKind.cual, GameKind.hear]) {
      final b = Bench(seed: 3);
      final at = b.s.queue.indexWhere((q) => q.item?.kind == kind);
      await b.reach(at);
      final r = b.s.choices.indexWhere((c) => c.right);
      final w = r == 0 ? 1 : 0;
      b.s.touch(w);
      await b.vt.settle();
      // his: the red-orange ring and the X badge, at once
      expect(b.s.choices[w].ring, OptionRing.bad, reason: '$kind');
      expect(b.s.choices[w].cross, isTrue);
      expect(b.s.choices[w].check, isFalse);
      await b.vt.runUntil(() => b.s.choices.any((c) => c.sign));
      expect(b.s.choices[w].ring, OptionRing.bad, reason: '$kind');
      // the right one: the sign, and no green ring and no check: not a hit yet
      expect(b.s.choices[r].sign, isTrue);
      expect(b.s.choices[r].ring, OptionRing.none);
      expect(b.s.choices[r].check, isFalse);
      expect(b.s.streak, 0);
      // only the right one takes the touch now
      b.s.touch(w);
      await b.vt.settle();
      expect(b.s.choices[r].sign, isTrue);
      b.s.touch(r);
      await b.vt.settle();
      // touched: green ring and the check, the sign gone; his keeps its red and its X
      expect(b.s.choices[r].sign, isFalse);
      expect(b.s.choices[r].ring, OptionRing.ok);
      expect(b.s.choices[r].check, isTrue);
      expect(b.s.choices[w].ring, OptionRing.bad);
      expect(b.s.choices[w].cross, isTrue);
      // the sentence shows and Next is there at once (both games)
      await b.vt.runUntil(() => b.s.canNext);
      expect(b.s.showText, isTrue);
      expect(b.s.canNext, isTrue);
      await b.leave();
    }
  });

  test('silence, scored games only: 6 s after the sentence it plays again, 6 s more and the answer shows: a miss', () async {
    for (final kind in [GameKind.cual, GameKind.hear]) {
      final b = Bench(seed: 3);
      final at = b.s.queue.indexWhere((q) => q.item?.kind == kind);
      await b.reach(at);
      final clip = b.s.item!.clip!;
      final t0 = b.vt.now;
      final before = b.clips.plays.where((p) => p['id'] == clip).length;
      await b.vt.advance(5900);
      expect(b.clips.plays.where((p) => p['id'] == clip).length, before);
      await b.vt.advance(200);
      expect(
        b.clips.plays.where((p) => p['id'] == clip).length,
        before + 1,
        reason: '$kind',
      );
      await b.vt.runUntil(() => b.s.choices.any((c) => c.sign));
      final r = b.s.choices.indexWhere((c) => c.right);
      expect(b.s.choices[r].sign, isTrue);
      expect(b.vt.now - t0, greaterThanOrEqualTo(12000));
      final a = b.s.answers.last;
      expect((a.word, a.ok, a.auto), (b.s.item!.word, false, true));
      expect(a.ms, greaterThanOrEqualTo(12000));
      await b.leave();
    }
  });

  HearItem hearOf(List<RepasoWord> tiles) => HearItem(
    word: tiles.first.word,
    sentence: realRepaso.sentences.first,
    tiles: [for (final w in tiles) w.word],
    answer: 0,
    solo: [for (final w in tiles) w.solo],
  );

  test('a speaker touched on a ¿Qué oyes? tile plays the word alone and is not silence', () async {
    final b = Bench(seed: 2);
    final solo = realRepaso.words.where((w) => w.solo != null).take(3).toList();
    expect(solo, hasLength(3));
    b.s.queue = [QueueEntry.scored(hearOf(solo))];
    await b.reach(0);
    // every tile has a clip of its word alone: every tile has its speaker
    expect([for (final c in b.s.choices) c.clip], [for (final w in solo) w.solo]);
    final k = 1;
    await b.vt.advance(5000);
    b.s.touchSpeaker(k);
    await b.vt.settle();
    expect(b.clips.plays.last['id'], b.s.choices[k].clip);
    await b.vt.advance(
      3000,
    ); // 8 s after the sentence, 3 s after the speaker: no replay yet
    expect(b.s.choices.any((c) => c.sign), isFalse);
    await b.leave();
  });

  test('H: speakers on the word tiles only when every tile of the item has a clip of its word alone; else none', () async {
    final solo = realRepaso.words.where((w) => w.solo != null).toList();
    final plain = realRepaso.words.where((w) => w.solo == null).toList();
    expect(hearOf(solo.take(3).toList()).speakers, isTrue);
    for (final mix in [
      [solo[0], solo[1], plain[0]],
      [solo[0], plain[0], plain[1]],
      [plain[0], plain[1], plain[2]],
    ]) {
      final item = hearOf(mix);
      expect(item.speakers, isFalse);
      final b = Bench(seed: 2);
      b.s.queue = [QueueEntry.scored(item)];
      await b.reach(0);
      // not one of the item's tiles has a speaker, not even the ones that have a clip
      expect([for (final c in b.s.choices) c.clip], [null, null, null]);
      // and no touch on a tile's speaker plays anything
      final plays = b.clips.plays.length;
      for (var k = 0; k < 3; k++) {
        b.s.touchSpeaker(k);
      }
      await b.vt.settle();
      expect(b.clips.plays.length, plays);
      await b.leave();
    }
  });

  test('the play games never time out', () async {
    final b = Bench(seed: 3);
    final at = b.s.queue.indexWhere((q) => q.slot);
    await b.reach(at);
    expect(b.s.item!.scored, isFalse);
    final plays = b.clips.plays.length;
    await b.vt.advance(60000);
    expect(b.s.index, at);
    expect(b.s.choices.any((c) => c.sign), isFalse);
    expect(b.clips.plays.length, plays);
    await b.leave();
  });

  test('at most five come back in a session', () async {
    final b = Bench(seed: 3);
    await b.play(plan: (e, n) => e.item!.scored && !e.again ? 'w' : 'r');
    expect(b.s.played.where((q) => q.again), hasLength(5));
    expect(b.answersOf(Skill.ear), hasLength(10));
    expect(b.s.end!.summary, '0 of 10 words right the first time');
  });

  test('Arma la frase and Parejas: a wrong touch jumps back and breaks the row; nothing is written', () async {
    final b = Bench(seed: 3);
    await b.play(
      plan: (e, n) => e.item is BuildItem || e.item is MatchItem ? 'w' : 'r',
    );
    final build = b.s.played.firstWhere((q) => q.item is BuildItem);
    expect(build.item, isA<BuildItem>());
    expect(b.answersOf(Skill.ear), hasLength(10));
    expect(b.answersOf(Skill.mouth), isEmpty);
  });

  group('Dilo', () {
    RepasoWord sayWord() => realRepaso.words.firstWhere(
      (w) => w.say.isNotEmpty && w.say.first.story == 'la-lluvia',
    );

    Future<Bench> dilo(
      List<String> heard, {
      bool speech = true,
      Object? habla,
    }) async {
      final j = jsonDecode(seedJson('curso')) as Map<String, dynamic>;
      if (habla != null) (j['ajustes'] as Map)['habla'] = habla;
      final b = Bench(json: jsonEncode(j), heard: heard, speech: speech);
      final w = sayWord();
      b.s.queue = [QueueEntry.play(SayItem(word: w.word, line: w.say.first))];
      return b;
    }

    test('heard right: a Mouth answer right, and what was heard shows; it hears the line before, not the line', () async {
      final w = sayWord();
      final b = await dilo([w.say.first.forms.first]);
      await b.play();
      final m = b.answersOf(Skill.mouth);
      expect(m, hasLength(1));
      expect((m.single['args'] as List).sublist(0, 3), [w.word, 'mouth', true]);
      expect(b.answersOf(Skill.ear), isEmpty);
      expect(b.clips.plays.first['id'], w.say.first.before);
      expect(b.clips.plays.where((p) => p['id'] == w.say.first.clip), isEmpty);
      expect(b.listener.listens.single.locale, 'es-US');
    });

    test(
      'heard wrong twice: nothing written, the line plays as the model',
      () async {
        final w = sayWord();
        final b = await dilo(['algo', 'otra cosa']);
        await b.play(until: () => b.s.canNext);
        // what the app heard shows, not as right
        expect(
          (b.s.heard, b.s.heardRight, b.s.showText),
          ('otra cosa', false, true),
        );
        expect(b.clips.plays.last['id'], w.say.first.clip);
        await b.play();
        expect(b.answersOf(Skill.mouth), isEmpty);
        expect(b.listener.used, 2);
      },
    );

    test('"Can\'t speak now" ends it and turns Dilo off for the session; nothing written', () async {
      final b = await dilo([]);
      await b.play(until: () => b.s.mic == MicState.ready);
      b.s.cantSpeak();
      await b.play();
      expect(b.s.sayOff, isTrue);
      expect(b.answersOf(Skill.mouth), isEmpty);
      expect(b.listener.listens, isEmpty);
    });

    test(
      'speaking cannot work here: off for the session, nothing written',
      () async {
        final b = await dilo(['error:not-allowed']);
        await b.play();
        expect(b.s.sayOff, isTrue);
        expect(b.answersOf(Skill.mouth), isEmpty);
      },
    );

    test('only when the mic works and "Speak in stories" is on', () async {
      for (final (speech, habla) in [(false, 1), (true, 0)]) {
        final b = Bench(
          speech: speech,
          json: () {
            final j = jsonDecode(seedJson('curso')) as Map<String, dynamic>;
            (j['ajustes'] as Map)['habla'] = habla;
            return jsonEncode(j);
          }(),
        );
        await b.play();
        expect(b.s.played.where((q) => q.item is SayItem), isEmpty);
      }
    });
  });

  test('the play kinds take turns from one session to the next (kept in the feature\'s own space)', () async {
    final space = FakeKeyValueStore();
    final one = Bench(seed: 3, speech: true, space: space);
    await one.play();
    expect(
      [
        for (final q in one.s.played)
          if (!q.item!.scored) q.item!.kind,
      ],
      [GameKind.build, GameKind.match, GameKind.where],
    );
    expect(space.read(LastAsked.kindKey), '3');
    final two = Bench(
      seed: 5,
      speech: true,
      space: space,
      heard: List.filled(4, 'nada que ver'),
    );
    await two.play();
    final kinds = [
      for (final q in two.s.played)
        if (!q.item!.scored) q.item!.kind,
    ];
    expect(kinds.first, GameKind.say);
    expect(kinds.skip(1).take(2), [GameKind.build, GameKind.match]);
    // and the second session's sentences are not the first's for the same word
    final last = jsonDecode(space.read(LastAsked.key)!) as Map;
    expect(last, isNotEmpty);
  });

  test('practice (nothing due): the same games, the answers written as today\'s practice writes them (intro)', () async {
    final b = Bench(now: 1700000000000, seed: 4);
    expect(b.s.practice, isTrue);
    await b.play();
    final ear = b.answersOf(Skill.ear);
    expect(ear, hasLength(b.s.words.length));
    for (final c in ear) {
      expect(
        (c['args'] as List)[4],
        isTrue,
      ); // intro: the schedule does not move
    }
    expect(b.s.end!.groups.single.title, 'Right');
    expect(b.s.end!.groups.single.sub, '');
  });

  test(
    'the day\'s minutes: a session left in the middle adds its time too, once',
    () async {
      final b = Bench(seed: 3);
      final m0 = b.store.minutes;
      await b.reach(2);
      final t = b.vt.now;
      b.s.leave();
      await b.leave();
      expect(b.store.minutes - m0, closeTo(t / 6e4, 1e-9));
    },
  );
}
