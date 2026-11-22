// When he waits at a decision, the round is said again (page 13, orders 58 to 61): a round where two people speak, or
// one person says two things (more than one line since its `dots` step), is said again whole, in order; a round of one
// line says that line again, as before. La plaza's stories 60 (Ana, then her mamá) and 62 (the piragüero's question,
// then the two who answer) need it; El quiosco's 67 too.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/stand_in_scene.dart';
import 'support/rig.dart';
import 'support/stories.dart';

final things = [
  Thing(id: 'puerta', box: [10, 10, 20, 20]),
  Thing(id: 'ventana', box: [60, 10, 20, 20]),
];

const clips = {
  'intro': 'I',
  'a': 'A',
  'b': 'B',
  'q': 'Q',
  'muy_bien': 'M',
  'mal': 'N',
};

Map<String, dynamic> round(List<Object?> lines, String line) => story(
  beats: [
    'intro',
    {'dots': 1},
    ...lines,
    {
      'decide': 'do',
      'options': ['puerta', 'ventana'],
      'line': line,
      'mudo': true,
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

  test('a line said under an if counts; a line before the round\'s dots does not', () async {
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
  });

  test('one line in the round: that line alone, as before', () async {
    expect(await waitOnce(round(['q'], 'q')), ['q']);
  });
}
