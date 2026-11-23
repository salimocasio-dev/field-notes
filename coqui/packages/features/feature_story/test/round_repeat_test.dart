// When he waits at a decision, the round is said again (page 13, orders 58 to 61): a round where two people speak, or
// one person says two things (more than one line since its `dots` step), is said again whole, in order; a round of one
// line says that line again, as before. La plaza's stories 60 (Ana, then her mamá) and 62 (the piragüero's question,
// then the two who answer) need it; El quiosco's 67 too. A decision that is not `mudo` says its own `line` after the
// round's lines, so the whole round again ends with it (el-jugo, h-balcon and h-sala have such rounds). If he answers
// or leaves while the round is being said again, the rest of it stays unsaid.
import 'dart:async';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:feature_story/src/play/virtual_parts.dart';
import 'package:feature_story/src/runner/pending.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/stand_in_scene.dart';
import 'support/rig.dart';
import 'support/stories.dart';

/// A clip player whose clips last as long as the course says (the test course: 1000 ms each), where the stand-in player's
/// end at once. A test can then answer, or leave, while a line is being said.
class _LastingPlayer extends VirtualClipPlayer {
  _LastingPlayer(super.timers, super.course);

  final List<Completer<bool>> _held = [];

  @override
  Future<bool> play(String clipId, {Duration? limit}) {
    played.add(clipId);
    limits.add(limit);
    final c = Completer<bool>();
    _held.add(c);
    final info = course.clip(clipId);
    timers.setTimeout(() {
      if (c.isCompleted) return;
      _held.remove(c);
      c.complete(true);
    }, info == null ? 0 : info.endMs - info.startMs);
    return c.future;
  }

  @override
  Future<void> stop() async {
    for (final c in List.of(_held)) {
      if (!c.isCompleted) c.complete(false);
    }
    _held.clear();
    await super.stop();
  }
}

final things = [
  Thing(id: 'puerta', box: [10, 10, 20, 20]),
  Thing(id: 'ventana', box: [60, 10, 20, 20]),
];

const clips = {
  'intro': 'I',
  'a': 'A',
  'b': 'B',
  'c': 'C',
  'q': 'Q',
  'muy_bien': 'M',
  'mal': 'N',
};

Map<String, dynamic> round(
  List<Object?> lines,
  String line, {
  bool mudo = true,
}) => story(
  beats: [
    'intro',
    {'dots': 1},
    ...lines,
    {
      'decide': 'do',
      'options': ['puerta', 'ventana'],
      'line': line,
      if (mudo) 'mudo': true,
      'tests': 'uno',
      'pick': 'puerta',
      'right': <Object?>[],
      'wrong': ['mal'],
    },
  ],
  clips: clips,
);

Future<List<String>> waitOnce(Map<String, dynamic> st) async {
  final r = await Rig.make(st, scene: StandInScene(things: things));
  await r.start();
  await r.untilAsked();
  final before = r.clips.length;
  await r.advance(9000 + 6000); // one repeat, and time for it to be said
  final again = r.clips.sublist(before);
  r.touch('puerta');
  await r.finish((pn) => 'puerta');
  return again;
}

void main() {
  test('two lines in the round: both said again, in order, the decision\'s line among them', () async {
    expect(await waitOnce(round(['a', 'q'], 'q')), ['a', 'q']);
  });

  test('three lines, the decision\'s line first (a question, then two answers): all three again', () async {
    expect(await waitOnce(round(['q', 'a', 'b'], 'q')), ['q', 'a', 'b']);
  });

  test(
    'a line said under an if counts; a line before the round\'s dots does not',
    () async {
      expect(
        await waitOnce(
          round([
            {
              'if': 'ok',
              'then': ['b'],
              'else': ['a'],
            },
            'q',
          ], 'q'),
        ),
        ['a', 'q'],
      );
    },
  );

  test('one line in the round: that line alone, as before', () async {
    expect(await waitOnce(round(['q'], 'q')), ['q']);
  });

  group('a decision that is not mudo says its own line after the round', () {
    test(
      'two lines since dots, then the decision\'s line: all three, in order',
      () async {
        // the shape of el-jugo `vaso_en_silla` + `vaso_en_mesa`, then `toma_vaso_$l`
        expect(await waitOnce(round(['a', 'b'], 'q', mudo: false)), [
          'a',
          'b',
          'q',
        ]);
      },
    );

    test('mudo: false said out loud is the same as no mudo', () async {
      final st = round(['a', 'b'], 'q', mudo: false);
      (st['beats'] as List).whereType<Map>().last['mudo'] = false;
      expect(await waitOnce(st), ['a', 'b', 'q']);
    });

    test(
      'the decision\'s line is not said twice when the round already says it',
      () async {
        expect(await waitOnce(round(['q', 'a'], 'q', mudo: false)), ['q', 'a']);
      },
    );

    test('a round of one line is still that line alone', () async {
      expect(await waitOnce(round(['a'], 'q', mudo: false)), ['q']);
    });
  });

  group('the rest of the round stays unsaid once he answers or leaves', () {
    // The repeat starts 9 s after the question is asked; each clip lasts 1000 ms and a gap of 300 ms follows it (the
    // player of this group holds a clip for its length).
    // Returns the clips played from the repeat's first line on, and the question's `Pending` after it all.
    Future<({List<String> said, Pending pn})> stopped(
      Map<String, dynamic> st,
      int intoRepeat,
      void Function(Rig r) stop,
    ) async {
      final r = await Rig.make(
        st,
        scene: StandInScene(things: things),
        playerFor: _LastingPlayer.new,
      );
      await r.start();
      final pn = await r.untilAsked();
      final before = r.clips.length;
      await r.advance(9000); // the repeat starts: its first line is playing
      expect(r.clips.sublist(before), ['a'], reason: 'the first line plays');
      await r.advance(intoRepeat);
      stop(r);
      await r.advance(
        15000,
      ); // time enough to say the whole round, were it not stopped
      return (said: r.clips.sublist(before), pn: pn);
    }

    test('he answers while the first line is being said again', () async {
      final res = await stopped(
        round(['a', 'b', 'c'], 'q', mudo: false),
        500,
        (r) => r.touch('puerta'),
      );
      expect(res.said.first, 'a');
      expect(res.said, isNot(contains('b')));
      expect(res.said, isNot(contains('c')));
      expect(res.said, isNot(contains('q')));
      expect(res.pn.rep, isFalse, reason: 'ready to repeat if he waits again');
    });

    test('he answers in the 300 ms gap after the first line', () async {
      final res = await stopped(
        round(['a', 'b', 'c'], 'q', mudo: false),
        1100,
        (r) => r.touch('puerta'),
      );
      expect(res.said.first, 'a');
      expect(res.said, isNot(contains('b')));
      expect(res.said, isNot(contains('c')));
      expect(res.said, isNot(contains('q')));
      expect(res.pn.rep, isFalse);
    });

    test('the round of a mudo decision stops the same way', () async {
      final res = await stopped(
        round(['a', 'b', 'q'], 'q'),
        500,
        (r) => r.touch('puerta'),
      );
      expect(res.said.first, 'a');
      expect(res.said, isNot(contains('b')));
      expect(res.said, isNot(contains('q')));
      expect(res.pn.rep, isFalse);
    });

    test('he leaves while the first line is being said again: nothing else is said', () async {
      final res = await stopped(
        round(['a', 'b', 'c'], 'q', mudo: false),
        500,
        (r) => r.runner.leave(),
      );
      expect(res.said, ['a']);
      expect(res.pn.rep, isFalse);
    });

    test(
      'he leaves in the gap after the first line: nothing else is said',
      () async {
        final res = await stopped(
          round(['a', 'b', 'c'], 'q', mudo: false),
          1100,
          (r) => r.runner.leave(),
        );
        expect(res.said, ['a']);
        expect(res.pn.rep, isFalse);
      },
    );
  });
}
