// The real Repaso data (historia/datos/repaso.json) and a real learner (coqui/ref/pantallas/seeds/curso.json, the
// mid-course seed: map stories 1 to 15 played, 78 words), for the tests of the games.
import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';

import 'fixture_catalog.dart';

/// The repository's root, found from where the tests run.
final Directory repoRoot = () {
  var dir = Directory.current.absolute;
  while (true) {
    if (Directory('${dir.path}/historia/datos').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) throw StateError('no historia/ above');
    dir = parent;
  }
}();

/// historia/datos/repaso.json, read.
final RepasoData realRepaso = RepasoData.fromJson(
  jsonDecode(
    File('${repoRoot.path}/historia/datos/repaso.json').readAsStringSync(),
  ) as Map<String, dynamic>,
);

/// The mid-course seed's text.
String seedJson(String name) =>
    File('${repoRoot.path}/coqui/ref/pantallas/seeds/$name.json')
        .readAsStringSync();

/// The seed's clock: just after its last due date, so every word with a due date is due.
const int curseNow = 1795312800000 + 1;

/// The review course of the old tests, with the real Repaso data ([repaso], or none) and every clip of it known
/// (its text from the data, so a line with no recording runs for the time its words take).
class RepasoTestCourse extends FixtureCatalog implements RepasoCatalog {
  RepasoTestCourse({RepasoData? data, bool none = false})
    : repaso = none ? null : (data ?? realRepaso);

  @override
  final RepasoData? repaso;

  late final Map<String, String> _texts = {
    if (repaso != null) ...{
      for (final s in repaso!.sentences) s.clip: s.text,
      for (final w in repaso!.words) ...{
        for (final p in w.pairLines) p.clip: p.text,
        for (final d in w.say) d.clip: d.text,
      },
    },
  };

  @override
  ClipInfo? clip(String id) =>
      super.clip(id) ??
      ClipInfo(
        id: id,
        who: 'narr',
        text: _texts[id] ?? '',
        startMs: 0,
        endMs: 1000,
        url: 'audio/$id.mp3',
      );
}

/// A learner who has met every word and finished every story (the data's stories): every sentence is his to get.
String everythingJson(RepasoData d, {int now = curseNow}) {
  final stories = {for (final s in d.sentences) s.story};
  for (final w in d.words) {
    for (final p in w.pairLines) {
      if (p.story != null) stories.add(p.story!);
    }
    for (final l in w.say) {
      stories.add(l.story);
    }
  }
  Map<String, dynamic> skill(int n) => {
    'etapa': 3,
    'paso': 1,
    'seguidas': 0,
    'fallos': 0,
    'gap': 1,
    'due': now - 1000,
    'aciertos': <int>[],
    'ultima': 0,
    'aparcada': 0,
    'marca': 0,
    'n': n,
    'bien': n,
  };
  return jsonEncode({
    'palabras': {
      for (final w in d.words)
        w.word: {
          'w': w.word,
          'primera': now - 86400000,
          'oida': 1,
          'ear': skill(0),
          'mouth': {...skill(0), 'etapa': 0, 'due': 0},
        },
    },
    'dias': {},
    'cuentos': {
      for (final s in stories) s: {'n': 1, 'primera': now - 86400000},
    },
    'ajustes': {'min': 30, 'todo': 0, 'bienvenida': 0, 'habla': 1},
    'minutos': 0,
    'v': 1,
  });
}
