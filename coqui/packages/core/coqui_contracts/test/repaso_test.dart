import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:test/test.dart';

/// A small file in the shape `make_repaso.py --app` writes.
const _file = '''
{"v":1,
 "frases":[
  {"clip":"a","cuento":"s1","text":"Abuela abre la puerta.","tokens":["abuela","abre","la","puerta"],"prohibidas":["abre","abuela","puerta"],"img":"img/s1-2.png","oyes":true,"arma":true},
  {"clip":"b","cuento":"s2","text":"Luis dice: ¡La puerta!","tokens":["la","puerta"],"prohibidas":["puerta"],"img":null,"oyes":true,"arma":false}
 ],
 "palabras":[
  {"w":"puerta","lugar":"casa","puntua":"cual","solo":null,"no_juntas":["puerto"],
   "cual":[{"clip":"esta_puerta","text":"Esta es la puerta.","cuento":null},{"clip":"a","text":"Abuela abre la puerta.","cuento":"s1"}],
   "frases":[1,0],"donde":[{"frase":0,"otras":["img/s1-4.png","img/s1-1.png"]}],
   "dilo":[{"clip":"d","cuento":"s1","text":"¡La puerta!","formas":["puerta"],"antes":"q","img":null}]},
  {"w":"¿quién?","lugar":"casa","puntua":"que_oyes","solo":"cq_quien","no_juntas":[],"cual":[],"frases":[],"donde":[],"dilo":[]},
  {"w":"hace calor","lugar":"cocina","puntua":"nada","solo":null,"no_juntas":[],"cual":[],"frases":[],"donde":[],"dilo":[]}
 ]}
''';

void main() {
  test('the file reads into its types', () {
    final d = RepasoData.fromJson(jsonDecode(_file) as Map<String, dynamic>);
    expect(d.sentences, hasLength(2));
    final s = d.sentences[0];
    expect(
      (s.clip, s.story, s.text, s.picture),
      ('a', 's1', 'Abuela abre la puerta.', 'img/s1-2.png'),
    );
    expect(s.tokens, ['abuela', 'abre', 'la', 'puerta']);
    expect(s.forbidden, ['abre', 'abuela', 'puerta']);
    expect((s.forHearing, s.forBuilding), (true, true));
    expect(d.sentences[1].picture, isNull);
    final w = d.word('puerta')!;
    expect((w.place, w.scoring, w.solo), ('casa', RepasoScoring.cual, null));
    expect(w.apart, ['puerto']);
    expect(
      [for (final p in w.pairLines) (p.clip, p.story)],
      [('esta_puerta', null), ('a', 's1')],
    );
    expect(w.sentences, [1, 0]);
    expect(w.where.single.sentence, 0);
    expect(w.where.single.others, ['img/s1-4.png', 'img/s1-1.png']);
    final say = w.say.single;
    expect(
      (say.clip, say.story, say.before, say.picture),
      ('d', 's1', 'q', null),
    );
    expect(say.forms, ['puerta']);
    expect(d.word('¿quién?')!.scoring, RepasoScoring.queOyes);
    expect(d.word('¿quién?')!.solo, 'cq_quien');
    expect(d.word('hace calor')!.scoring, RepasoScoring.none);
    expect(d.word('nada'), isNull);
  });

  test('another version, or a word that names a sentence that is not there, is refused', () {
    final j = jsonDecode(_file) as Map<String, dynamic>;
    expect(
      () => RepasoData.fromJson({...j, 'v': 2}),
      throwsA(isA<FormatException>()),
    );
    final bad = jsonDecode(_file) as Map<String, dynamic>;
    ((bad['palabras'] as List)[0] as Map)['frases'] = [5];
    expect(() => RepasoData.fromJson(bad), throwsA(isA<FormatException>()));
  });
}
