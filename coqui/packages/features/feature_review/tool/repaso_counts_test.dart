// How many words get each game, for a learner who has finished map stories 1..k (k = 3, 11, 22, 32) and the picture
// stories of every place whose map stories are all done; he has met the focus and back-again words of those stories.
// A tool, not a test: `flutter test tool/repaso_counts_test.dart` in this package prints the table.
import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/repaso_course.dart';

void main() {
  test('words by game, for a learner at stories 3, 11, 22, 32', () {
    final h = '${repoRoot.path}/historia';
    final curso = jsonDecode(
      File('$h/datos/curso.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final map = <String>[];
    final placeOf = <String, int>{};
    final pictures = <int, List<String>>{};
    final places = curso['lugares'] as List;
    for (var i = 0; i < places.length; i++) {
      final l = places[i] as Map;
      for (final s in (l['cuentos'] as List? ?? const [])) {
        map.add(s as String);
        placeOf[s] = i;
      }
      pictures[i] = [
        for (final s in (l['dibujos'] as List? ?? const [])) s as String,
      ];
    }
    final course = RepasoTestCourse();
    final out = StringBuffer(
      '| learner | words met | ¿Cuál? and ¿Qué oyes? | ¿Cuál? only | ¿Qué oyes? only | none | Arma la frase | ¿Dónde? | Dilo |\n|---|---|---|---|---|---|---|---|---|\n',
    );
    for (final k in [3, 11, 22, 32]) {
      final done = map.take(k).toList();
      final stories = <String>{...done};
      for (final e in pictures.entries) {
        final mine = [
          for (final s in map)
            if (placeOf[s] == e.key) s,
        ];
        if (mine.isNotEmpty && mine.every(done.contains)) {
          stories.addAll(e.value);
        }
      }
      final words = <String>{};
      for (final s in done) {
        final j =
            jsonDecode(File('$h/cuentos/$s.json').readAsStringSync()) as Map;
        words.addAll(
          [
            ...(j['focus_words'] as List? ?? const []),
            ...(j['back_again'] as List? ?? const []),
          ].cast<String>(),
        );
      }
      final json = jsonEncode({
        'palabras': {
          for (final w in words)
            w: {
              'w': w,
              'primera': 1,
              'oida': 1,
              'ear': {'etapa': 3, 'n': 0, 'due': 1},
              'mouth': {'etapa': 0, 'n': 0},
            },
        },
        'cuentos': {
          for (final s in stories) s: {'n': 1, 'primera': 1},
        },
      });
      final p = FakeProgressStore(clock: FakeClock(curseNow), json: json);
      final pl = RepasoPlanner(
        data: realRepaso,
        progress: p,
        pairs: course.pairs,
        rng: Mulberry32(1),
      );
      var both = 0, cual = 0, hear = 0, none = 0, arma = 0, where = 0, say = 0;
      for (final w in realRepaso.words.where((x) => words.contains(x.word))) {
        final c = pl.cualLines(w).isNotEmpty,
            q = pl.hearSentences(w).isNotEmpty;
        if (c && q) {
          both++;
        } else if (c) {
          cual++;
        } else if (q) {
          hear++;
        } else {
          none++;
        }
        if (w.sentences.any(
          (i) =>
              realRepaso.sentences[i].forBuilding &&
              pl.finished(realRepaso.sentences[i].story),
        )) {
          arma++;
        }
        if (w.where.any(
          (d) => pl.finished(realRepaso.sentences[d.sentence].story),
        )) {
          where++;
        }
        if (w.say.any((l) => pl.finished(l.story))) say++;
      }
      out.writeln(
        '| stories 1..$k | ${words.length} | $both | $cual | $hear | $none | $arma | $where | $say |',
      );
    }
    // ignore: avoid_print
    print(out);
  });
}
