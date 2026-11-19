// Speaking turns (docs/hablar/01-decisiones.md; juego.js 214-312). The cases of historia/tools/habla_motor_check.py, on a
// story of our own with the same shape as the scratch story that check makes from El bizcocho: one plain coquí line, one
// signed ask and one elige that are marked "tu_turno", a decide whose said clips are marked too (never a turn), and a second
// occurrence of a marked clip. The recogniser is the old `?mic=stub:` switch.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:feature_story/src/runner/pending.dart';
import 'package:feature_story/src/runner/speech_session.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/stand_in_scene.dart';
import 'support/rig.dart';
import 'support/stories.dart';

Map<String, dynamic> marked(String text, String palabra, List<String> formas) => {
  'who': 'tu',
  'text': text,
  'tu_turno': [
    {'palabra': palabra, 'formas': formas},
  ],
};

Map<String, dynamic> turnsStory({List<Object?>? beats, Map<String, dynamic> extraClips = const {}}) {
  final s = story(
    beats: beats ??
        [
          {'wait': 100},
          'hola_q',
          'cq_si',
          'ahora_no',
          {'ask': 'puerta', 'line': 'puerta_q', 'said': {'puerta': 'cq_no'}},
          'mira',
          {'elige': 'x', 'options': ['si', 'no'], 'line': 'bizcocho_q', 'said': {'si': 'cq_si_gracias', 'no': 'cq_no_gracias'}, 'si': ['toma'], 'no': ['abuela_no']},
          'cq_mmm',
          {'decide': 'do', 'options': ['puerta', 'ventana'], 'pick': 'puerta', 'line': 'dq', 'said': {'puerta': 'cq_no'}},
          'abre_puerta',
          'cq_si',
          'fin',
        ],
    clips: {
      for (final k in ['hola_q', 'ahora_no', 'puerta_q', 'mira', 'bizcocho_q', 'toma', 'abuela_no', 'cq_mmm', 'dq', 'abre_puerta', 'fin', 'muy_bien']) k: k,
    },
  );
  final c = s['clips'] as Map<String, dynamic>;
  c['cq_si'] = marked('Sí', 'sí', ['sí', 'si']);
  c['cq_no'] = marked('No', 'no', ['no']);
  c['cq_si_gracias'] = marked('Sí, gracias', 'sí', ['sí', 'si']);
  c['cq_no_gracias'] = marked('No, gracias', 'no', ['no']);
  c.addAll(extraClips);
  return s;
}

final things = [
  Thing(id: 'puerta', box: [150, 60, 30, 50]),
  Thing(id: 'ventana', box: [60, 60, 40, 30]),
];

/// The first right answer of a decide, the first live thing of the rest (what the check touches).
String? rightOne(Pending pn) => pn.kind == 'decide' && pn.pick != null && pn.live.contains(pn.pick) ? pn.pick : pn.live.first;

class Played {
  Played(this.r, this.mic, this.bubbles);

  final Rig r;
  final List<String> mic;
  final List<String> bubbles;

  List<String> get clips => r.clips;
  List<Map<String, dynamic>> get log => r.runner.habLog;

  /// What the learner said by word: `[n, bien]` of the mouth record (the check's `mouth(R, w)`).
  List<int> mouth(String w) => [r.progress.mouth[w] ?? 0, r.progress.answers.where((a) => a.w == w && a.ok).length];

  /// The clips played between the first [a] and the next [b] (null when there is none), as the check's `seq`.
  List<String>? seq(String a, String b) {
    final c = clips;
    final i = c.indexOf(a);
    if (i < 0) return null;
    for (var x = i + 1; x < c.length; x++) {
      if (c[x] == b) return c.sublist(i + 1, x);
    }
    return null;
  }

  List<(String, String)> get kinds => [for (final x in log) (x['tipo'] as String, x['est'] as String)];
}

Future<Played> play(
  String stubSpec, {
  Map<String, dynamic>? file,
  bool open = true,
  bool micOff = false,
  bool listen = false,
  Object habla = 1,
  TxtMode txt = TxtMode.con,
  bool touchElige = false,
  Set<String> words = const {},
  SpeechSession? session,
  TestProgress? progress,
}) async {
  final prog = progress ?? TestProgress(habla: habla, open: words);
  final r = await Rig.make(
    file ?? turnsStory(),
    scene: StandInScene(things: things),
    progress: prog,
    stub: stubSpec.isEmpty ? <String>[] : stubSpec.split('|'),
    allOpen: open,
    micOff: micOff,
    listen: listen,
    txt: txt,
    session: session,
  );
  final mic = <String>[], bubbles = <String>[];
  r.runner.view.addListener(() {
    final m = r.runner.view.mic;
    if (m.isNotEmpty && (mic.isEmpty || mic.last != m)) mic.add(m);
    final b = r.runner.view.bubbleOn ? '${r.runner.view.bubbleKind.name}@${r.runner.view.bubbleWho}' : '';
    if (b.isNotEmpty && (bubbles.isEmpty || bubbles.last != b)) bubbles.add(b);
  });
  await r.finishTurns(rightOne, touchElige: touchElige);
  return Played(r, mic, bubbles);
}

void main() {
  group('habla_motor_check.py: the cases', () {
    test('habla_motor_check: mic=off: no turn, the mic never shows, the line plays as today', () async {
      final off = await play('si|no|si gracias', micOff: true);
      expect(off.kinds, isEmpty);
      expect(off.mic, isEmpty);
      expect(off.r.runner.habDisp(), isFalse);
      expect(off.r.progress.mouth, isEmpty);
      expect(off.r.runner.W['lost'], 0);
      // the reference for the other runs
      expect(off.clips.take(4), ['hola_q', 'cq_si', 'ahora_no', 'puerta_q']);
    });

    test('habla_motor_check: first play with no turn: a word not open for speaking is not a turn; nothing is recorded', () async {
      final off = await play('si|no|si gracias', micOff: true);
      final noab = await play('si|no|si gracias', open: false);
      expect(noab.kinds, isEmpty);
      expect(noab.mic, isEmpty);
      expect(noab.r.progress.mouth, isEmpty);
      expect(noab.clips, off.clips); // the same clips as a run with the mic off
    });

    test('habla_motor_check: every turn heard right: three turns, mouth right once per target, the model first for a new word', () async {
      final off = await play('si|no|si gracias', micOff: true);
      final ok = await play('si|no|si gracias');
      expect(ok.kinds, [('linea', 'ok'), ('ask', 'ok'), ('elige', 'ok')]);
      expect(ok.r.runner.HAB.n, 3); // the marked clips inside the decide were not turns
      // a plain line with a new word: the coquí's recording first, then "Ahora tú."
      expect(ok.seq('hola_q', 'ahora_no'), ['cq_si', 'ahora_tu']);
      // an ask: the question, then the turn; said[t] did not play; bien came
      expect(ok.seq('puerta_q', 'mira'), ['muy_bien']);
      // an elige: said[option] did not play again, the option's steps ran
      expect(ok.seq('bizcocho_q', 'cq_mmm'), ['toma']);
      // once per play: a later occurrence of a clip that was a turn plays as today
      expect(ok.seq('abre_puerta', 'fin'), ['cq_si']);
      // the decide's said clip was not a turn: it plays
      expect(ok.seq('dq', 'abre_puerta'), ['cq_no', 'muy_bien']);
      expect(ok.mouth('sí'), [2, 2]);
      expect(ok.mouth('no'), [1, 1]);
      // only the mouth record, three answers, right, the ms of the recogniser's first sound (120 on the stub)
      expect(ok.r.progress.answers, hasLength(3));
      expect(ok.r.progress.answers.every((a) => a.ok && a.ms == 120), isTrue);
      expect(ok.r.runner.W['lost'], off.r.runner.W['lost']);
      // one right signal more than without turns (the plain line's)
      expect(ok.r.sounds.where((s) => s == 'right').length, off.r.sounds.where((s) => s == 'right').length + 1);
      // the mic went dead, ready, listening, processing, ok
      expect(ok.mic.take(5), ['dead', 'ready', 'listening', 'processing', 'ok']);
      // the bubble held the mic at the frog, then the tick
      expect(ok.bubbles, containsAllInOrder(['mic@coqui', 'tick@coqui']));
    });

    test('habla_motor_check: right on the second try is right (Ahora tú. again)', () async {
      final r = await play('none|si|none|no|none|none');
      expect(r.kinds, [('linea', 'ok'), ('ask', 'ok'), ('elige', 'fallo')]);
      expect(r.log[0]['intentos'], 2);
      expect(r.clips.where((c) => c == 'ahora_tu'), hasLength(2));
      expect(r.mouth('sí'), [1, 1]);
      expect(r.mouth('no'), [1, 1]);
    });

    test('habla_motor_check: every turn missed twice: Ahora tú. after the first miss, the model after the second; nothing right', () async {
      final off = await play('si|no|si gracias', micOff: true);
      final r = await play('none|none|none|none|none|none');
      expect(r.kinds, [('linea', 'fallo'), ('ask', 'fallo'), ('elige', 'fallo')]);
      expect(r.seq('hola_q', 'ahora_no'), ['cq_si', 'ahora_tu', 'ahora_tu', 'cq_si']);
      expect(r.mouth('sí'), [1, 0]);
      expect(r.mouth('no'), [1, 0]);
      // no right signal for the plain line, the stake unchanged
      expect(r.r.sounds.where((s) => s == 'right').length, off.r.sounds.where((s) => s == 'right').length);
      expect(r.r.runner.W['lost'], off.r.runner.W['lost']);
      expect(r.r.sounds, contains('suave')); // the soft sound after the second miss of a plain line
      // the ask: the question was asked again, the touch worked, said played as today
      expect(r.clips.where((c) => c == 'puerta_q'), hasLength(2));
      expect(r.seq('puerta_q', 'mira'), contains('cq_no'));
      // the elige: the bubbles worked after the mic went (said played as today)
      expect(r.seq('bizcocho_q', 'cq_mmm'), contains('cq_si_gracias'));
    });

    test('habla_motor_check: the other option said twice in an ask is a miss: written wrong, the sign and the touch come back', () async {
      final r = await play('si|si|si|none|none');
      expect(r.kinds, [('linea', 'ok'), ('ask', 'fallo'), ('elige', 'fallo')]);
      expect(r.mouth('no'), [1, 0]);
      expect(r.clips.where((c) => c == 'puerta_q'), hasLength(2));
      expect(r.seq('puerta_q', 'mira'), contains('cq_no'));
    });

    test('habla_motor_check: an error that says speaking cannot work: the line plays as today, nothing recorded, no more turns', () async {
      final session = SpeechSession();
      final r = await play('error:not-allowed|si|no|si', session: session);
      expect(r.kinds, [('linea', 'nodisp')]);
      expect(r.seq('hola_q', 'ahora_no'), ['cq_si', 'ahora_tu', 'cq_si']);
      expect(r.r.progress.mouth, isEmpty);
      expect(session.unavailable, isTrue);
      expect(r.r.runner.habDisp(), isFalse);
      expect(r.r.runner.HAB.n, 1);
      expect(r.r.runner.W['lost'], 0);
      expect(r.clips, contains('cq_si_gracias')); // the rest played as today
    });

    test('habla_motor_check: at most 4 turns in one play (the first 4 live ones)', () async {
      final s = turnsStory(extraClips: {
        'cq_ay': marked('Ay', 'ay', ['ay']),
        'no_pajaro': {'who': 'narr', 'text': 'pájaro', 'tu_turno': [{'palabra': 'pájaro', 'formas': ['pájaro', 'pajaro']}]},
      });
      final beats = (s['beats'] as List).toList();
      beats.insert(3, 'cq_ay');
      beats.insert(4, 'no_pajaro');
      s['beats'] = beats;
      final r = await play('si|ay|no|pajaro|si gracias', file: s);
      expect(r.r.runner.HAB.n, 4);
      expect(r.clips, contains('cq_si_gracias')); // the 5th (the elige) played as today, by touch
      expect(r.r.runner.W['lost'], 0);
    });

    test('habla_motor_check: elige: two options matched is a miss; then one', () async {
      final r = await play('si|no|si no gracias|si gracias');
      expect(r.kinds, [('linea', 'ok'), ('ask', 'ok'), ('elige', 'ok')]);
      expect(r.log[2]['intentos'], 2);
      expect(r.log[2]['op'], 'si');
    });

    test('habla_motor_check: elige: a touch while the mic is up is taken; nothing written for it', () async {
      final r = await play('si|no|none', touchElige: true);
      expect(r.kinds.take(2), [('linea', 'ok'), ('ask', 'ok')]);
      expect(r.mouth('sí'), [1, 1]);
      expect(r.clips, contains('cq_si_gracias'));
    });

    test('habla_motor_check: which words are open: stage 3 or a mouth answer; not stage 2', () async {
      final a = await play('si|no|si gracias', open: false, words: {'sí'});
      expect(a.kinds, [('linea', 'ok')]); // sí open, no not open
      final b = await play('si|no|si gracias', open: false, words: {});
      expect(b.kinds, isEmpty); // stage 2 only opens nothing
      final c = await play('si|no|si gracias', open: false, progress: TestProgress()..mouth['sí'] = 1..mouth['no'] = 1);
      expect(c.kinds, [('linea', 'ok'), ('ask', 'ok'), ('elige', 'ok')]);
      // no model when every target has been said before: straight to the mic
      expect(c.seq('hola_q', 'ahora_no'), isEmpty);
      expect(c.mouth('sí'), [3, 2]);
      expect(c.mouth('no'), [2, 1]);
    });

    test('habla_motor_check: the Yo switch off, Listen mode and ?txt=no', () async {
      final off = await play('si|no|si gracias', micOff: true);
      final sw = await play('si|no|si gracias', habla: 0);
      expect(sw.kinds, isEmpty);
      expect(sw.clips, off.clips);
      final oir = await play('si|no|si gracias', listen: true);
      expect(oir.kinds, isEmpty);
      expect(oir.mic, isEmpty);
      expect(oir.r.progress.mouth, isEmpty);
      final txt = await play('si|no|si gracias', txt: TxtMode.no);
      expect(txt.kinds, [('linea', 'ok'), ('ask', 'ok'), ('elige', 'ok')]);
      // the mic bubble and the tick still show with no words; the tick holds none of his words
      expect(txt.bubbles, containsAllInOrder(['mic@coqui', 'tick@coqui']));
      expect(txt.r.runner.view.bubbleText, '');
    });

    test('a story that is callado has no turns', () async {
      final s = turnsStory();
      s['callado'] = true;
      final r = await play('si|no|si gracias', file: s);
      expect(r.kinds, isEmpty);
    });

    test('the tick shows his words when TXT allows (the best alternative)', () async {
      final r = await Rig.make(turnsStory(), scene: StandInScene(things: things), stub: ['si'], allOpen: true);
      await r.start();
      await r.until(() => r.runner.HAB.est == 'ready', what: 'the mic');
      r.runner.tapMic();
      await r.until(() => r.runner.HAB.est == 'ok', what: 'the tick');
      expect(r.runner.view.bubbleKind, BubbleKind.tick);
      expect(r.runner.view.bubbleText, 'si');
      expect(r.runner.view.mic, 'ok');
    });

    test('a touch while he is listened to does nothing (the frog neither)', () async {
      final scene = StandInScene(things: things);
      final r = await Rig.make(turnsStory(), scene: scene, stub: ['si'], allOpen: true);
      await r.start();
      await r.until(() => r.runner.HAB.est == 'ready');
      r.runner.tapMic();
      expect(r.runner.HAB.est, 'listening');
      r.touch('ventana');
      r.touch('coqui');
      expect(scene.pokes, isEmpty);
    });

    test('hush() before listening: nothing is playing while he is listened to; clips then get a time limit', () async {
      final r = await Rig.make(turnsStory(), scene: StandInScene(things: things), stub: ['si', 'no', 'si'], allOpen: true);
      await r.start();
      await r.until(() => r.runner.HAB.est == 'ready');
      expect(r.runner.speaking, 0);
      expect(r.runner.HAB.guard, isFalse);
      r.runner.tapMic();
      expect(r.runner.speaking, 0);
      expect(r.runner.HAB.guard, isTrue);
    });
  });

  group('what counts as heard right (docs/hablar/01-decisiones.md)', () {
    Target t(String w, List<String> f) => (palabra: w, formas: f);
    final cases = <(List<String>, List<Target>, bool)>[
      (['hola abuela'], [t('hola', ['hola']), t('abuela', ['abuela'])], true),
      (['abuela hola'], [t('hola', ['hola']), t('abuela', ['abuela'])], true),
      (['ola abuela', 'hola abuela'], [t('hola', ['hola']), t('abuela', ['abuela'])], true),
      (['ola abuela'], [t('hola', ['hola']), t('abuela', ['abuela'])], false),
      (['Sí, gracias, abuela'], [t('sí', ['si'])], true),
      (['sin azúcar'], [t('sí', ['si'])], false),
      (['quiero jugo por favor'], [t('quiero', ['quiero']), t('jugo', ['jugo'])], true),
      (['favor'], [t('por favor', ['por favor'])], false),
      (['uno dos tres'], [t('uno', ['uno', '1']), t('tres', ['tres', '3'])], true),
      (['1 2 3'], [t('uno', ['uno', '1']), t('tres', ['tres', '3'])], true),
      (['uno dos'], [t('uno', ['uno', '1']), t('tres', ['tres', '3'])], false),
      (['¿Cómo estás tú?'], [t('¿cómo estás?', ['como estas'])], true),
      ([''], [t('hola', ['hola'])], false),
      (<String>[], [t('hola', ['hola'])], false),
    ];
    for (final (alts, targets, want) in cases) {
      test('habla_motor_check: $alts against ${targets.map((x) => x.formas)}: $want', () {
        expect(heardRight(alts, targets), want);
      });
    }
  });
}
