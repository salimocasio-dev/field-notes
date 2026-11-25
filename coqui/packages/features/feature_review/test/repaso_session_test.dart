// Repaso's games run with no screen, on a virtual clock, over the real data and the mid-course learner: each game's
// rules (right, wrong, silence, the answer shown, the unscored return), what is written (Ear, Mouth, minutes), practice.
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart' show DashMark;
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:feature_review/src/logic/review_session.dart'
    show OptionRing, ReviewOptions;
import 'package:feature_review/src/logic/word_picture.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/support/scripted_clips.dart';
import '../tool/support/virtual_time.dart';
import 'support/recording_store.dart';
import 'support/repaso_course.dart';

final course = RepasoTestCourse();

class _ScriptedSpeech implements SpeechListener {
  _ScriptedSpeech(this.results);
  final List<SpeechResult> results;
  int used = 0;

  @override
  Future<bool> available() async => true;

  @override
  SpeechTurn listen({
    required String locale,
    required Duration limit,
    int maxAlternatives = 5,
  }) {
    final res = used < results.length
        ? results[used]
        : SpeechResult(error: 'no-speech');
    used++;
    return _ScriptedTurn(res);
  }
}

class _ScriptedTurn implements SpeechTurn {
  _ScriptedTurn(SpeechResult res)
    : _result = Future<SpeechResult>.microtask(() => res),
      _speechEnd = Future<void>.microtask(() {});

  final Future<SpeechResult> _result;
  final Future<void> _speechEnd;

  @override
  Future<SpeechResult> get result => _result;

  @override
  Future<void> get speechEnd => _speechEnd;

  @override
  void cancel() {}
}

class Bench {
  Bench({
    String? json,
    int now = curseNow,
    int seed = 1,
    List<String> heard = const [],
    bool speech = false,
    SpeechListener? speechListener,
    ReviewOptions options = const ReviewOptions(),
    FakeKeyValueStore? space,
    Map<String, WordPictureAsset> wordAssets = const {},
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
      speech: speechListener ?? listener,
      storage: kv,
      options: options,
      wordAssets: wordAssets,
    );
    s.prepare();
  }

  static Map<String, WordPictureAsset> allDedicatedAssets() => {
    for (final p in course.pairs)
      p.word: WordPictureAsset(
        word: p.word,
        yesAsset: 'word_assets/${p.word}_yes.png',
        noAsset: 'word_assets/${p.word}_no.png',
      ),
  };

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
      [GameKind.build, GameKind.match, GameKind.build],
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
      (
        first.item!.runtimeType,
        first.item!.kind,
        first.item!.word,
        first.item!.clip,
      ),
    );
    expect(b.s.played.indexOf(again.single), 3);
    // scored once (wrong), asked again with nothing written
    final ear = b.answersOf(Skill.ear);
    expect(ear, hasLength(10));
    expect((ear.first['args'] as List)[2], isFalse);
    expect(b.s.secondAnswers.single.ok, isTrue);
    expect(b.s.end!.summary, '9 of 10 words right the first time');
    expect(b.s.end!.groups.map((g) => g.title), [
      'Coming back soon',
      'Got it the first time',
    ]);
    expect(b.s.end!.groups.first.rows.single.word, first.item!.word);
  });

  test('wrong in ¿Cuál? and ¿Qué oyes?: red-orange and an X on his, the sign alone on the right one, green and a check only once he touches it', () async {
    for (final kind in [GameKind.cual, GameKind.hear]) {
      final b = Bench(
        seed: 3,
        wordAssets: kind == GameKind.cual
            ? Bench.allDedicatedAssets()
            : const {},
      );
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
      final b = Bench(
        seed: 3,
        wordAssets: kind == GameKind.cual
            ? Bench.allDedicatedAssets()
            : const {},
      );
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

  /// An item with [tiles] and their clips of the word alone; [lacking]: the places of the tiles whose clip is taken away
  /// (every word of the data file has one now, so a word with none is made by hand).
  HearItem hearOf(List<RepasoWord> tiles, {Set<int> lacking = const {}}) =>
      HearItem(
        word: tiles.first.word,
        sentence: realRepaso.sentences.first,
        tiles: [for (final w in tiles) w.word],
        answer: 0,
        solo: [
          for (var i = 0; i < tiles.length; i++)
            lacking.contains(i) ? null : tiles[i].solo,
        ],
      );

  test('a speaker touched on a ¿Qué oyes? tile plays the word alone and is not silence', () async {
    final b = Bench(seed: 2);
    final solo = realRepaso.words.where((w) => w.solo != null).take(3).toList();
    expect(solo, hasLength(3));
    b.s.queue = [QueueEntry.scored(hearOf(solo))];
    await b.reach(0);
    // every tile has a clip of its word alone: every tile has its speaker
    expect(
      [for (final c in b.s.choices) c.clip],
      [for (final w in solo) w.solo],
    );
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

  test('the session preloads the word clips of its ¿Qué oyes? items with the sentences', () async {
    // a learner who has finished every story, each word at its turn for ¿Qué oyes? (an odd count of answers)
    final json = jsonDecode(everythingJson(realRepaso)) as Map<String, dynamic>;
    for (final e in (json['palabras'] as Map).values) {
      ((e as Map)['ear'] as Map)['n'] = 1;
    }
    final b = Bench(json: jsonEncode(json), seed: 4);
    final hears = [
      for (final q in b.s.queue)
        if (q.item case final HearItem it) it,
    ];
    expect(hears, isNotEmpty);
    expect(
      b.clips.preloaded.toSet(),
      containsAll({
        for (final it in hears) ...[it.clip, ...it.solo.nonNulls],
      }),
    );
    for (final it in hears) {
      expect(it.speakers, isTrue, reason: it.word);
      expect(
        b.clips.preloaded.toSet(),
        containsAll(it.solo.nonNulls.toSet()),
        reason: it.word,
      );
    }
    // the item as it comes back after a miss has the same clips (they are loaded already, and still the tiles' own)
    final back = hears.first.rearranged(.5);
    expect({...back.solo}, {...hears.first.solo});
    await b.leave();
  });

  test('over EVERY word: a touch on a ¿Qué oyes? tile\'s speaker plays that word\'s clip and does not answer; a touch on the tile answers (right, and wrong)', () async {
    final all = everythingJson(realRepaso);
    var items = 0, words = 0;
    for (final w in realRepaso.words) {
      for (final right in [true, false]) {
        final b = Bench(json: all, seed: 2);
        final sentences = b.s.planner.hearSentences(w);
        if (sentences.isEmpty) continue;
        if (right) words++;
        final item = b.s.planner.hearItem(w, sentences.first);
        final why = '${w.word} | ${item.tiles} | ${item.solo}';
        expect(item.speakers, isTrue, reason: why);
        b.s.queue = [QueueEntry.scored(item)];
        await b.reach(0);
        expect(b.s.yourTurn, isTrue, reason: why);
        expect([for (final c in b.s.choices) c.clip], item.solo, reason: why);
        // a touch on each tile's speaker plays that tile's word, and answers nothing
        for (var k = 0; k < 3; k++) {
          final plays = b.clips.plays.length;
          b.s.touchSpeaker(k);
          await b.vt.settle();
          expect(b.clips.plays.length, plays + 1, reason: why);
          expect(b.clips.plays.last['id'], item.solo[k], reason: why);
          expect(b.s.answers, isEmpty, reason: why);
          expect(b.s.yourTurn, isTrue, reason: why);
          expect(
            b.s.choices.every(
              (c) =>
                  c.ring == OptionRing.none && !c.check && !c.cross && !c.sign,
            ),
            isTrue,
            reason: why,
          );
        }
        // a touch on the tile answers: the right word is right, another is wrong
        b.s.touch(right ? item.answer : (item.answer + 1) % 3);
        await b.vt.settle();
        expect(b.s.answers, hasLength(1), reason: why);
        expect(
          (b.s.answers.single.word, b.s.answers.single.ok),
          (w.word, right),
          reason: why,
        );
        await b.leave();
        items++;
      }
    }
    expect(
      words,
      greaterThan(140),
    ); // the words that have a sentence for ¿Qué oyes?
    expect(items, 2 * words);
  });

  test('H: speakers on the word tiles only when every tile of the item has a clip of its word alone; else none', () async {
    final solo = realRepaso.words.where((w) => w.solo != null).toList();
    expect(solo, hasLength(167));
    expect(hearOf(solo.take(3).toList()).speakers, isTrue);
    for (final lacking in [
      {2},
      {1, 2},
      {0, 1, 2},
    ]) {
      final item = hearOf(solo.take(3).toList(), lacking: lacking);
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
      SpeechListener? speechListener,
      Object? habla,
    }) async {
      final j = jsonDecode(seedJson('curso')) as Map<String, dynamic>;
      if (habla != null) (j['ajustes'] as Map)['habla'] = habla;
      final b = Bench(
        json: jsonEncode(j),
        heard: heard,
        speech: speech,
        speechListener: speechListener,
      );
      final w = sayWord();
      b.s.queue = [QueueEntry.play(SayItem(word: w.word, line: w.say.first))];
      return b;
    }

    test('heard right: a Mouth answer right, and what was heard shows; it plays the sentence to say back, not the line before', () async {
      final w = sayWord();
      final b = await dilo([w.say.first.forms.first]);
      await b.play();
      final m = b.answersOf(Skill.mouth);
      expect(m, hasLength(1));
      expect((m.single['args'] as List).sublist(0, 3), [w.word, 'mouth', true]);
      expect(b.answersOf(Skill.ear), isEmpty);
      expect(b.clips.plays.first['id'], w.say.first.clip);
      expect(
        b.clips.plays.where((p) => p['id'] == w.say.first.before),
        isEmpty,
      );
      expect(
        b.listener.listens.single.locale,
        Language.spanish.recognitionLocale,
      );
    });

    test('heard right: the check, what was heard, the line in the reveal and Next at once, with no wait between them; the dash is green', () async {
      final w = sayWord();
      final b = await dilo([w.say.first.forms.first]);
      await b.play(until: () => b.s.mic == MicState.ready);
      expect(b.s.barMarks.single, DashMark.none);
      b.s.pressMic();
      await b.vt.runUntil(() => b.s.heardRight);
      await b.vt.settle();
      expect((b.s.mic, b.s.heard), (MicState.ok, w.say.first.forms.first));
      expect(
        (b.s.showText, b.s.canNext),
        (true, true),
        reason: 'no pause between the check and Next',
      );
      expect(b.s.barMarks.single, DashMark.right);
      await b.leave();
    });

    test('heard wrong twice: records a Mouth miss, the mic shows the X, the line plays as the model, the dash is red-orange', () async {
      final w = sayWord();
      final b = await dilo(['algo', 'otra cosa']);
      await b.play(until: () => b.s.mic == MicState.ready);
      b.s.pressMic();
      await b.vt.runUntil(() => b.s.notHeard && b.s.mic == MicState.ready);
      // a first try not heard right: the mic is ready again, with "Try again"; nothing recorded yet
      expect((b.s.heard, b.s.heardRight), ('algo', false));
      expect(b.s.barMarks.single, DashMark.none);
      expect(b.answersOf(Skill.mouth), isEmpty);
      b.s.pressMic();
      await b.vt.settle(); // the recogniser's answer comes on the next turn of the event loop
      await b.vt.runUntil(() => b.s.mic == MicState.missed);
      // the second: the mic shows the X, the dash is red-orange, and a Mouth miss is written
      expect(b.s.barMarks.single, DashMark.wrong);
      await b.vt.runUntil(() => b.s.canNext);
      // what the app heard shows, not as right; the line, with the word lit, and Next; the mic keeps its X
      expect(
        (b.s.heard, b.s.heardRight, b.s.showText, b.s.mic),
        ('otra cosa', false, true, MicState.missed),
      );
      expect(b.clips.plays.last['id'], w.say.first.clip);
      await b.play();
      final m = b.answersOf(Skill.mouth);
      expect(m, hasLength(1));
      expect(m.single['args'], [w.word, 'mouth', false, 120, false]);
      expect(b.answersOf(Skill.ear), isEmpty);
      expect(b.listener.used, 2);
      expect(b.s.barMarks.single, DashMark.wrong);
    });

    test(
      'heard wrong twice with null msToSound: records a Mouth miss with ms 0',
      () async {
        final w = sayWord();
        final b = await dilo(
          const [],
          speechListener: _ScriptedSpeech([
            SpeechResult(alternatives: const ['algo']),
            SpeechResult(alternatives: const ['otra cosa']),
          ]),
        );
        await b.play();
        final m = b.answersOf(Skill.mouth);
        expect(m, hasLength(1));
        expect(m.single['args'], [w.word, 'mouth', false, 0, false]);
      },
    );

    test(
      'wrong first try then right second try: records only a Mouth hit',
      () async {
        final w = sayWord();
        final b = await dilo(['algo', w.say.first.forms.first]);
        await b.play();
        final m = b.answersOf(Skill.mouth);
        expect(m, hasLength(1));
        expect((m.single['args'] as List).sublist(0, 3), [
          w.word,
          'mouth',
          true,
        ]);
      },
    );

    test('silent or empty captures write nothing to ProgressStore', () async {
      for (final results in [
        // both attempts no-speech error with empty alternatives
        [
          SpeechResult(alternatives: const [], error: 'no-speech'),
          SpeechResult(alternatives: const [], error: 'no-speech'),
        ],
        // both attempts pure empty alternatives with no error
        [
          SpeechResult(alternatives: const []),
          SpeechResult(alternatives: const []),
        ],
        // speech on try 1, silence on try 2
        [
          SpeechResult(alternatives: const ['algo'], msToSound: 120),
          SpeechResult(alternatives: const []),
        ],
        // silence on try 1, speech on try 2
        [
          SpeechResult(alternatives: const [], error: 'no-speech'),
          SpeechResult(alternatives: const ['algo'], msToSound: 120),
        ],
        // blank/whitespace transcript does not count as spoken speech
        [
          SpeechResult(alternatives: const ['algo'], msToSound: 120),
          SpeechResult(alternatives: const ['   '], msToSound: 120),
        ],
        // non-nodisp error on try 2 (even if alternatives were present)
        [
          SpeechResult(alternatives: const ['algo'], msToSound: 120),
          SpeechResult(alternatives: const ['otra cosa'], error: 'aborted'),
        ],
      ]) {
        final speech = _ScriptedSpeech(results);
        final b = await dilo(const [], speechListener: speech);
        await b.play();
        expect(b.answersOf(Skill.mouth), isEmpty);
        expect(b.answersOf(Skill.ear), isEmpty);
        expect(speech.used, 2);
      }
    });

    test('"Can\'t speak now" ends it and turns Dilo off for the session; nothing written', () async {
      final b = await dilo([]);
      await b.play(until: () => b.s.mic == MicState.ready);
      expect(b.s.barMarks.single, DashMark.none);
      b.s.cantSpeak();
      await b.play();
      expect(b.s.sayOff, isTrue);
      expect(b.answersOf(Skill.mouth), isEmpty);
      expect(b.listener.listens, isEmpty);
      // skipped: neither green nor red-orange
      expect(b.s.barMarks.single, DashMark.skipped);
    });

    test(
      '"Can\'t speak now" after a wrong first try writes nothing and skips',
      () async {
        final b = await dilo(['algo', 'otra cosa']);
        await b.play(until: () => b.s.mic == MicState.ready);
        b.s.pressMic();
        await b.vt.runUntil(() => b.s.notHeard && b.s.mic == MicState.ready);
        b.s.cantSpeak();
        await b.play();
        expect(b.s.sayOff, isTrue);
        expect(b.answersOf(Skill.mouth), isEmpty);
        expect(b.s.barMarks.single, DashMark.skipped);
      },
    );

    test(
      'speaking cannot work here: off for the session, nothing written',
      () async {
        for (final heard in [
          ['error:not-allowed'],
          ['algo', 'error:audio-capture'],
        ]) {
          final b = await dilo(heard);
          await b.play();
          expect(b.s.sayOff, isTrue);
          expect(b.answersOf(Skill.mouth), isEmpty);
          expect(b.s.barMarks.single, DashMark.skipped);
        }
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
      [GameKind.build, GameKind.match, GameKind.say],
    );
    expect(space.read(LastAsked.kindKey), '0');
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
    expect(kinds, [GameKind.build, GameKind.match, GameKind.say]);
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

  // ---- the readers' fixes (B, C, E, F, G, J, K, L), at the session's level

  test('B: the end lists every scored word of the session in exactly one of two lists, each row with its sentence and its sound', () async {
    final b = Bench(seed: 3);
    // the first, fourth and seventh scored words are missed
    final miss = {0, 3, 6};
    var scored = -1;
    await b.play(
      plan: (e, n) {
        if (!e.item!.scored || e.again) return 'r';
        scored++;
        return miss.contains(scored) ? 'w' : 'r';
      },
    );
    final end = b.s.end!;
    final words = [for (final w in b.s.words) w.word];
    expect(words, hasLength(10));
    final listed = [
      for (final g in end.groups)
        for (final r in g.rows) r.word,
    ];
    // ten words, ten rows, none twice, none left out
    expect(listed, hasLength(10));
    expect(listed.toSet(), words.toSet());
    expect((end.right, end.of), (7, 10));
    expect(end.summary, '7 of 10 words right the first time');
    // the missed words first, then the ones he got
    expect(
      [for (final g in end.groups) (g.title, g.sub)],
      [
        ('Coming back soon', "You'll see these again soon"),
        ('Got it the first time', "You'll see these less often"),
      ],
    );
    expect([for (final g in end.groups) g.rows.length], [3, 7]);
    // each row: the word, the sentence it was asked in, and its sound
    for (final g in end.groups) {
      for (final r in g.rows) {
        final it = b.s.played
            .firstWhere(
              (q) => q.item!.scored && !q.again && q.item!.word == r.word,
            )
            .item!;
        expect((r.clip, r.text), (it.clip, it.text));
        expect(r.text, isNotEmpty);
      }
    }
    // the play games do not count: M is the scored words, not the items
    expect(b.s.played.length, greaterThan(10));
    expect(end.of, 10);
  });

  test('F: the bar has one dash for each planned item; each takes the colour of its item\'s first answer at once and keeps it; a return has no dash and repaints nothing; the item on screen is the outlined one', () async {
    final b = Bench(seed: 3);
    expect(b.s.queue.length, 13); // ten scored items and three play places
    expect(b.s.barSegments, 13);
    expect(b.s.barMarks, everyElement(DashMark.none));
    expect(b.s.barCurrent, isNull, reason: 'the start screen: no item yet');
    // the first scored item: asked, nothing marked yet
    await b.reach(0);
    expect(b.s.barCurrent, 0);
    expect(b.s.barMarks, everyElement(DashMark.none));
    // his first answer is wrong: red-orange at once, before the right one has even been touched
    final r = b.s.choices.indexWhere((c) => c.right);
    b.s.touch(r == 0 ? 1 : 0);
    await b.vt.settle(); // no timer between the touch and the mark
    expect(b.s.barMarks.first, DashMark.wrong);
    expect(b.s.barMarks.skip(1), everyElement(DashMark.none));
    await b.vt.runUntil(() => b.s.choices.any((c) => c.sign));
    b.s.touch(b.s.choices.indexWhere((c) => c.sign));
    await b.vt.runUntil(() => b.s.canNext);
    expect(
      b.s.barMarks.first,
      DashMark.wrong,
      reason: 'touching the right one after it does not undo the miss',
    );
    b.s.pressNext();
    await b.vt.runUntil(() => b.s.index == 1 && b.s.yourTurn);
    expect(b.s.barCurrent, 1);
    expect(b.s.barMarks.first, DashMark.wrong);
    expect(b.s.barSegments, 13);
    // the return, three items later, is the item it answers again: its dash is the outlined one, and it has no dash of
    // its own
    await b.play(
      until: () =>
          b.s.item == b.s.queue[b.s.queue.indexWhere((q) => q.again)].item &&
          b.s.yourTurn &&
          b.s.entry!.again,
    );
    expect(b.s.barCurrent, 0);
    expect(b.s.barSegments, 13);
    expect(b.s.barMarks.first, DashMark.wrong);
    expect(
      b.s.barMarks.skip(1).take(2),
      everyElement(DashMark.right),
      reason: 'the two answered right in between',
    );
    final back = b.s.entry!;
    b.s.touch(b.s.choices.indexWhere((c) => c.right));
    await b.vt.runUntil(() => b.s.canNext);
    expect(
      b.s.barMarks.first,
      DashMark.wrong,
      reason: 'right on its return: it keeps the colour of its first answer',
    );
    b.s.pressNext();
    await b.vt.runUntil(() => b.s.entry != back);
    expect(b.s.barMarks.first, DashMark.wrong);
    await b.leave();
    // the whole session: the first wrong, the rest right; the count never changed, no dash is outlined at the end
    final c = Bench(seed: 3);
    await c.play(plan: (e, n) => n == 0 ? 'w' : 'r', limit: 4000);
    expect(c.s.barSegments, 13);
    expect(c.s.barMarks, [DashMark.wrong, ...List.filled(12, DashMark.right)]);
    expect(c.s.barCurrent, isNull);
  });

  test('F: a miss that has no return (more than five) is red-orange to the end, like the others; the right items stay green', () async {
    final b = Bench(seed: 3);
    await b.play(plan: (e, n) => e.item!.scored && !e.again ? 'w' : 'r');
    // five came back; the other five scored items did not
    expect(b.s.played.where((q) => q.again), hasLength(5));
    expect(b.s.barMarks.where((m) => m == DashMark.wrong), hasLength(10));
    expect(b.s.barMarks.where((m) => m == DashMark.right), hasLength(3));
    expect(b.s.barMarks.where((m) => m == DashMark.none), isEmpty);
  });

  test('F: every game marks its dash by its first answer: ¿Qué oyes? by the first touch, Parejas by a wrong pair, Arma la frase by a wrong tile', () async {
    for (final (kind, wrongFirst) in [
      (GameKind.hear, true),
      (GameKind.hear, false),
      (GameKind.match, true),
      (GameKind.match, false),
      (GameKind.build, true),
      (GameKind.build, false),
    ]) {
      final b = Bench(seed: 3);
      final at = b.s.queue.indexWhere((q) => q.slot);
      if (kind.index >= GameKind.build.index) {
        b.s.planner.nextKind = playKinds.indexOf(kind);
      }
      if (kind == GameKind.hear) {
        final i = b.s.queue.indexWhere((q) => q.item?.kind == kind);
        await b.reach(i);
        b.act(wrongFirst ? 'w' : 'r');
        await b.vt.settle();
        expect(
          b.s.barMarks[i],
          wrongFirst ? DashMark.wrong : DashMark.right,
          reason: '$kind $wrongFirst',
        );
        await b.leave();
        continue;
      }
      await b.reach(at);
      expect(b.s.item!.kind, kind);
      expect(b.s.barMarks[at], DashMark.none, reason: '$kind: asked only');
      b.act(wrongFirst ? 'w' : 'r');
      await b.vt.settle();
      // the whole item was played: it is marked by whether anything was wrong in it
      expect(
        b.s.barMarks[at],
        wrongFirst ? DashMark.wrong : DashMark.right,
        reason: '$kind $wrongFirst',
      );
      await b.leave();
    }
  });

  test('G: a missed item comes back as the same sentence and game, with its pictures or tiles in another order (never the identical arrangement)', () async {
    for (final kind in [GameKind.cual, GameKind.hear]) {
      for (final seed in [1, 2, 3, 4, 5]) {
        final b = Bench(
          seed: seed,
          wordAssets: kind == GameKind.cual
              ? Bench.allDedicatedAssets()
              : const {},
        );
        final target = b.s.queue.firstWhere((q) => q.item?.kind == kind);
        final seen = <QueueEntry, List<(String, bool)>>{};
        await b.play(
          plan: (e, n) {
            if (e.item?.scored ?? false) {
              seen[e] = [for (final c in b.s.choices) (c.label, c.right)];
            }
            return identical(e, target) ? 'w' : 'r';
          },
        );
        final back = b.s.played.firstWhere(
          (q) => q.again && q.item!.word == target.item!.word,
        );
        final first = seen[target]!;
        final second = seen[back]!;
        // the same sentence and the same pictures or tiles ...
        expect(back.item!.clip, target.item!.clip);
        String key((String, bool) x) => '${x.$1}|${x.$2}';
        expect(
          [for (final x in second) key(x)]..sort(),
          [for (final x in first) key(x)]..sort(),
        );
        // ... not in the same places
        expect(second, isNot(first), reason: '$kind seed $seed');
        // and the right one is still the right one
        expect(
          second.firstWhere((x) => x.$2).$1,
          first.firstWhere((x) => x.$2).$1,
        );
      }
    }
  });

  test('G: the arrangement of a returned ¿Qué oyes? is any order but the first, whatever the random number', () {
    final w = realRepaso.words.firstWhere((w) => w.solo != null);
    final sentence = realRepaso.sentences.first;
    final item = HearItem(
      word: 'a',
      sentence: sentence,
      tiles: const ['a', 'b', 'c'],
      answer: 1,
      solo: const [null, null, null],
    );
    expect(w, isNotNull);
    final orders = <String>{};
    for (var i = 0; i < 100; i++) {
      final back = item.rearranged(i / 100);
      expect(back.tiles, isNot(item.tiles));
      expect({...back.tiles}, {'a', 'b', 'c'});
      expect(back.tiles[back.answer], 'b');
      orders.add(back.tiles.join());
    }
    expect(orders, hasLength(5)); // every other order can come
  });

  test('E: ¿Cuál? ends with Next like every game: the sentence is not in the screen before the answer; after a right answer Next is there at once; after a wrong one when the right picture has been touched', () async {
    for (final wrong in [false, true]) {
      final b = Bench(seed: 3, wordAssets: Bench.allDedicatedAssets());
      final at = b.s.queue.indexWhere((q) => q.item?.kind == GameKind.cual);
      await b.reach(at);
      // before the answer: no sentence, no reveal, no Next
      expect((b.s.showText, b.s.canNext, b.s.caption), (false, false, ''));
      final r = b.s.choices.indexWhere((c) => c.right);
      b.s.touch(wrong ? 1 - r : r);
      await b.vt.settle();
      if (!wrong) {
        // right: the reveal and Next at once
        expect((b.s.showText, b.s.canNext), (true, true));
      } else {
        await b.vt.runUntil(() => b.s.choices.any((c) => c.sign));
        expect((b.s.showText, b.s.canNext), (false, false));
        b.s.touch(r);
        await b.vt.settle();
        expect((b.s.showText, b.s.canNext), (true, true));
      }
      // the item does not go on by itself
      final i = b.s.index;
      await b.vt.advance(20000);
      expect((b.s.index, b.s.canNext), (i, true));
      b.s.pressNext();
      await b.vt.runUntil(() => b.s.index > i);
      await b.leave();
    }
  });

  test(
    'E: before the answer no sentence shows in any game (the caption is off)',
    () async {
      final b = Bench(seed: 3);
      var checked = 0;
      await b.play(
        plan: (e, n) {
          expect(b.s.caption, '', reason: '${e.item!.kind}');
          expect(b.s.showText, isFalse);
          checked++;
          return 'r';
        },
      );
      expect(checked, greaterThan(10));
    },
  );

  test('J: Arma la frase: no places, an empty line; the next word of the sentence goes onto it and is green at once; any other tile stays in the bank, red-orange with an X for about a second, then clears, and the item counts as missed; a tile on the line cannot be taken back', () async {
    final b = Bench(seed: 3);
    final at = b.s.queue.indexWhere((q) => q.slot);
    await b.reach(at);
    final it = b.s.item! as BuildItem;
    expect(b.s.placed, isEmpty);
    expect(b.s.built, isEmpty);
    int idx(String w) => b.s.choices.indexWhere((c) => !c.done && c.label == w);
    // a tile that is not the next word: it stays in the bank with the red-orange border and the X; nothing is placed
    final wrong = b.s.choices.indexWhere((c) => c.label != it.order.first);
    b.s.touch(wrong);
    expect(
      (b.s.choices[wrong].ring, b.s.choices[wrong].cross),
      (OptionRing.bad, true),
    );
    expect(b.s.choices[wrong].done, isFalse);
    expect(b.s.placed, isEmpty);
    expect(
      b.s.barMarks[at],
      DashMark.wrong,
      reason: 'a wrong tile marks the item missed at once',
    );
    // about a second, then it clears by itself
    await b.vt.advance(900);
    expect(b.s.choices[wrong].cross, isTrue);
    await b.vt.advance(200);
    expect(
      (b.s.choices[wrong].ring, b.s.choices[wrong].cross),
      (OptionRing.none, false),
    );
    // a word of the sentence that is not the next one is wrong too: the second word first
    final second = idx(it.order[1]);
    b.s.touch(second);
    expect(
      (b.s.choices[second].ring, b.s.choices[second].cross),
      (OptionRing.bad, true),
    );
    expect(b.s.placed, isEmpty);
    // the right tiles in order: each goes onto the line, green at once
    final k0 = idx(it.order[0]);
    b.s.touch(k0);
    expect(b.s.placed, [k0]);
    expect((b.s.choices[k0].ring, b.s.choices[k0].done), (OptionRing.ok, true));
    // it stays: a touch on a tile that is on the line does nothing
    b.s.touch(k0);
    expect(b.s.placed, [k0]);
    expect(b.s.choices[k0].done, isTrue);
    // the wrong tile that was flashing has cleared on its own meanwhile; the next word goes on
    await b.vt.advance(1100);
    expect(b.s.choices[second].cross, isFalse);
    b.s.touch(second);
    expect(b.s.built, it.order.take(2));
    for (var i = 2; i < it.order.length; i++) {
      b.s.touch(idx(it.order[i]));
    }
    expect(b.s.built, it.order);
    // whole: the sentence shows, Next is there; he touched wrong tiles, so the item counts as missed
    await b.vt.settle();
    expect((b.s.showText, b.s.canNext), (true, true));
    expect(b.s.streak, 0);
    expect(b.s.barMarks[at], DashMark.wrong);
    await b.leave();
  });

  test('J: Arma la frase touched right all the way: every tile green as it goes, the item is green, nothing is red', () async {
    final b = Bench(seed: 3);
    final at = b.s.queue.indexWhere((q) => q.slot);
    await b.reach(at);
    final it = b.s.item! as BuildItem;
    for (var i = 0; i < it.order.length; i++) {
      final k = b.s.choices.indexWhere(
        (c) => !c.done && c.label == it.order[i],
      );
      b.s.touch(k);
      expect(b.s.built, it.order.take(i + 1));
      expect(b.s.choices[k].ring, OptionRing.ok);
    }
    await b.vt.settle();
    expect(b.s.barMarks[at], DashMark.right);
    expect(
      b.s.choices.where((c) => c.cross || c.ring == OptionRing.bad),
      isEmpty,
    );
    await b.leave();
  });

  test('K: Parejas: a wrong pair marks both tiles red-orange with an X for about a second, then clears; the slip resets the count at once; a matched pair gets its number on both tiles', () async {
    final b = Bench(seed: 3);
    final at = b.s.queue.indexWhere((q) => q.slot);
    // the play kinds in turn: the second is Parejas
    b.s.planner.nextKind = playKinds.indexOf(GameKind.match);
    await b.reach(at);
    final it = b.s.item! as MatchItem;
    b.s.streak = 5;
    // sound 0 against a word that is not its own
    b.s.touchSpeaker(0);
    final wrongWord = (it.wordOrder.indexOf(0) + 1) % 4;
    b.s.touch(wrongWord);
    expect(b.s.streak, 0, reason: 'a slip resets the count at once');
    for (final c in [b.s.speakers[0], b.s.choices[wrongWord]]) {
      expect((c.ring, c.cross, c.done), (OptionRing.bad, true, false));
    }
    await b.vt.advance(1100);
    for (final c in [b.s.speakers[0], b.s.choices[wrongWord]]) {
      expect(c.cross, isFalse);
    }
    expect(b.s.choices[wrongWord].ring, OptionRing.none);
    // the sound is still the chosen one: he can try another word
    expect(b.s.selectedSpeaker, 0);
    // the pairs, matched in a mixed order: 1 to 4 in the order matched, the same number on both tiles
    final order = [2, 0, 3, 1];
    for (var n = 0; n < 4; n++) {
      final i = order[n];
      b.s.touchSpeaker(i);
      b.s.touch(it.wordOrder.indexOf(i));
      expect(b.s.speakers[i].number, n + 1);
      expect(b.s.choices[it.wordOrder.indexOf(i)].number, n + 1);
      expect(
        (b.s.speakers[i].check, b.s.choices[it.wordOrder.indexOf(i)].check),
        (true, true),
      );
    }
    await b.vt.settle();
    expect(b.s.canNext, isTrue);
    await b.leave();
  });

  test('L: Dilo: listening shows while the app listens; a try not heard right shows what was heard and offers another; after the second the line shows, then Next', () async {
    final w = realRepaso.words.firstWhere(
      (w) => w.say.isNotEmpty && w.say.first.story == 'la-lluvia',
    );
    final j = jsonDecode(seedJson('curso')) as Map<String, dynamic>;
    final b = Bench(json: jsonEncode(j), heard: ['no sé', ''], speech: true);
    b.s.queue = [QueueEntry.play(SayItem(word: w.word, line: w.say.first))];
    await b.play(until: () => b.s.mic == MicState.ready);
    expect((b.s.notHeard, b.s.heard, b.s.showText), (false, '', false));
    b.s.pressMic();
    await b.vt.settle();
    expect(b.s.mic, MicState.listening);
    expect(b.s.heard, '');
    // the first try is not heard right
    await b.vt.runUntil(() => b.s.notHeard);
    expect((b.s.heard, b.s.heardRight), ('no sé', false));
    await b.vt.runUntil(() => b.s.mic == MicState.ready);
    expect(
      b.s.notHeard,
      isTrue,
      reason: '"Try again" is shown under the ready mic',
    );
    // the second: nothing heard; then the line (the model), and Next
    b.s.pressMic();
    await b.vt.runUntil(() => b.s.canNext);
    expect((b.s.notHeard, b.s.heard, b.s.showText), (true, '', true));
    expect(b.s.mic, MicState.missed, reason: 'the mic shows the X');
    expect(b.clips.plays.last['id'], w.say.first.clip);
    await b.leave();
  });
}
