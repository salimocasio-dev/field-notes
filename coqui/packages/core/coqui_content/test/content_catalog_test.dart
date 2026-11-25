// The catalog over the small course (test/fixture/, made from real files by tool/make_fixture.mjs): runs on the vm
// and in chrome. The answers the old code gives (pares, oidoEn, cualCarga) are in fixture/small_expected.dart, made
// by tool/make_fixture.mjs in node.
import 'dart:convert';

import 'package:coqui_content/coqui_content.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:test/test.dart';

import 'fixture/small_expected.dart';
import 'fixture/small_tree.dart';
import 'support.dart';

final _expected = OldAnswers(
  jsonDecode(smallExpectedJson) as Map<String, dynamic>,
);

Map<String, dynamic> _tree(String path) =>
    jsonDecode(smallTree[path]!) as Map<String, dynamic>;

final _curso = _tree('datos/curso.json');
final _ready = _tree('audio/ready.json');
final _marks = _tree('audio/marcas.json');

/// Every story of the places, in the course's order.
final _courseStories = [
  for (final l in _curso['lugares'] as List)
    ...((l as Map)['cuentos'] as List? ?? const []),
].cast<String>();

Future<(ContentCatalog, Files)> _loaded([Map<String, String>? changes]) async {
  final files = Files({...smallTree, ...?changes});
  final catalog = ContentCatalog(files.call);
  await catalog.load();
  return (catalog, files);
}

void main() {
  group('load', () {
    test('reads the six data files, datos/repaso.json and the review sets, and no story or book', () async {
      final (catalog, files) = await _loaded();
      expect(catalog.loaded, isTrue);
      expect(files.calls.toSet(), {
        'datos/curso.json',
        'datos/nivel.json',
        'datos/llamadas.json',
        'datos/fijos.json',
        'audio/ready.json',
        'audio/marcas.json',
        'datos/repaso.json',
        'cuentos/palabras-solas.json',
        for (final f in _curso['cual'] as List) 'cuentos/$f.json',
      });
      expect(files.calls, hasLength(files.calls.toSet().length));
    });

    test(
      'two calls, one of them while the first runs, read each file once',
      () async {
        final files = Files(smallTree);
        final catalog = ContentCatalog(files.call);
        await Future.wait([catalog.load(), catalog.load()]);
        await catalog.load();
        expect(files.calls, hasLength(files.calls.toSet().length));
      },
    );

    test(
      'before it has finished the lists are empty and the lookups give null',
      () {
        final catalog = ContentCatalog(Files(smallTree).call);
        expect(catalog.loaded, isFalse);
        expect(catalog.places, isEmpty);
        expect(catalog.pairs, isEmpty);
        expect(catalog.levelItems, isEmpty);
        expect(catalog.goodbyeWords, isEmpty);
        expect(catalog.meta(_courseStories.first), isNull);
        expect(catalog.pairFor(_expected.words.first), isNull);
        expect(catalog.callFor('casa'), isNull);
        expect(catalog.callsFor('casa'), isEmpty);
        expect(catalog.clip(_ready['clips'][0] as String), isNull);
        expect(() => catalog.fixedClip('story_praise'), throwsArgumentError);
      },
    );

    test(
      'a file that is missing makes it throw, and a second call tries again',
      () async {
        for (final path in [
          'datos/curso.json',
          'datos/nivel.json',
          'datos/llamadas.json',
          'datos/fijos.json',
          'audio/marcas.json',
          'cuentos/${(_curso['cual'] as List).last}.json',
        ]) {
          final files = Files({...smallTree}..remove(path));
          final catalog = ContentCatalog(files.call);
          await expectLater(
            catalog.load(),
            throwsA(isA<StateError>()),
            reason: path,
          );
          expect(catalog.loaded, isFalse);
          files.files[path] = smallTree[path]!;
          await catalog.load();
          expect(catalog.loaded, isTrue, reason: path);
        }
      },
    );

    test('a file that is not JSON makes it throw a FormatException that names the file', () async {
      final catalog = ContentCatalog(
        Files({...smallTree, 'datos/nivel.json': '[{'}).call,
      );
      await expectLater(
        catalog.load(),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            startsWith('datos/nivel.json: '),
          ),
        ),
      );
    });

    test('datos/repaso.json missing or broken is no error: repaso is null and the rest loads', () async {
      for (final bad in [
        null,
        'nope',
        '[1]',
        '{"v":1}',
        '{"v":9,"frases":[],"palabras":[]}',
      ]) {
        final files = {...smallTree}..remove('datos/repaso.json');
        if (bad != null) files['datos/repaso.json'] = bad;
        final catalog = ContentCatalog(Files(files).call);
        await catalog.load();
        expect(catalog.loaded, isTrue, reason: '$bad');
        expect(catalog.repaso, isNull, reason: '$bad');
        expect(catalog.pairs, isNotEmpty, reason: '$bad');
      }
    });

    test('datos/repaso.json that reads is repaso, read once', () async {
      final files = Files({
        ...smallTree,
        'datos/repaso.json':
            '{"v":1,"frases":[{"clip":"a","cuento":"s","text":"T a b.","tokens":["t","a","b"],"prohibidas":[],"img":null,"oyes":true,"arma":true}],'
            '"palabras":[{"w":"t","lugar":"casa","puntua":"que_oyes","solo":null,"no_juntas":[],"cual":[],"frases":[0],"donde":[],"dilo":[]}]}',
      });
      final catalog = ContentCatalog(files.call);
      expect(catalog.repaso, isNull);
      await catalog.load();
      await catalog.load();
      expect(catalog, isA<RepasoCatalog>());
      expect(catalog.repaso!.word('t')!.sentences, [0]);
      expect(catalog.repaso!.sentences.single.clip, 'a');
      expect(files.count('datos/repaso.json'), 1);
    });

    test('audio/ready.json that cannot be read is no error (audioListo): no clip has a recording', () async {
      for (final bad in [null, 'nope', '[1]', 'null']) {
        final files = {...smallTree}..remove('audio/ready.json');
        if (bad != null) files['audio/ready.json'] = bad;
        final catalog = ContentCatalog(Files(files).call);
        await catalog.load();
        expect(catalog.loaded, isTrue, reason: '$bad');
        expect(catalog.clip(_marks.keys.first), isNull, reason: '$bad');
      }
    });
  });

  group('places, stories, data', () {
    test('places and meta are curso.json', () async {
      final (catalog, _) = await _loaded();
      expect([
        for (final p in catalog.places) p.toJson(),
      ], sameJson(_curso['lugares']));
      final cuentos = _curso['cuentos'] as Map<String, dynamic>;
      for (final id in cuentos.keys) {
        expect(catalog.meta(id)!.toJson(), sameJson(cuentos[id]), reason: id);
        expect(catalog.meta(id)!.id, id);
      }
      expect(catalog.meta('no-such-story'), isNull);
      expect(catalog.places.last.stories, isEmpty);
    });

    test(
      'levelItems, callFor, fixedClip and goodbyeWords are the data files',
      () async {
        final (catalog, _) = await _loaded();
        expect([
          for (final q in catalog.levelItems) q.toJson(),
        ], sameJson(jsonDecode(smallTree['datos/nivel.json']!)));
        final llamadas = _tree('datos/llamadas.json');
        for (final id in llamadas.keys) {
          expect(catalog.callFor(id)!.toJson(), sameJson(llamadas[id]));
          expect(catalog.callFor(id)!.placeId, id);
        }
        expect(catalog.callFor('no-such-place'), isNull);
        final fijos = _tree('datos/fijos.json');
        final roles = fijos['clips'] as Map<String, dynamic>;
        expect(roles, isNotEmpty);
        for (final role in roles.keys) {
          expect(catalog.fixedClip(role), roles[role], reason: role);
        }
        expect(catalog.goodbyeWords, fijos['despedidas']);
      },
    );

    test('fixedClip on a role it does not have throws an error that names the role', () async {
      final (catalog, _) = await _loaded();
      expect(
        () => catalog.fixedClip('no_such_role'),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.invalidValue, 'invalidValue', 'no_such_role')
              .having((e) => e.toString(), 'message', contains('no_such_role')),
        ),
      );
    });

    test(
      'a role that holds a prefix gives the prefix, which is not a clip',
      () async {
        final (catalog, _) = await _loaded();
        final roles =
            _tree('datos/fijos.json')['clips'] as Map<String, dynamic>;
        final prefixes = {
          for (final e in roles.entries)
            if (e.key.endsWith('_prefix')) e.key: e.value as String,
        };
        expect(prefixes, isNotEmpty);
        for (final e in prefixes.entries) {
          expect(catalog.fixedClip(e.key), e.value);
          expect(catalog.clip(e.value), isNull);
        }
      },
    );
  });

  group('story and book', () {
    test(
      'story is the raw file, read once however often it is asked for',
      () async {
        final (catalog, files) = await _loaded();
        final id = _courseStories.first;
        final both = await Future.wait([catalog.story(id), catalog.story(id)]);
        final again = await catalog.story(id);
        expect(both[0], sameJson(jsonDecode(smallTree['cuentos/$id.json']!)));
        expect(identical(both[0], both[1]), isTrue);
        expect(identical(both[0], again), isTrue);
        expect(files.count('cuentos/$id.json'), 1);
      },
    );

    test(
      'a review set is read once, by load, and story gives the kept file',
      () async {
        final (catalog, files) = await _loaded();
        final set = (_curso['cual'] as List).first as String;
        await catalog.story(set);
        expect(files.count('cuentos/$set.json'), 1);
      },
    );

    test('a story that is not there throws; the failure is not kept', () async {
      final (catalog, files) = await _loaded();
      await expectLater(
        catalog.story('no-such-story'),
        throwsA(isA<StateError>()),
      );
      files.files['cuentos/no-such-story.json'] = '{"id":"no-such-story"}';
      expect((await catalog.story('no-such-story'))['id'], 'no-such-story');
      expect(files.count('cuentos/no-such-story.json'), 2);
    });

    test('book is Book.fromJson of the file, read once', () async {
      final (catalog, files) = await _loaded();
      final books = smallTree.keys
          .where((p) => p.startsWith('libros/'))
          .toList();
      expect(books, isNotEmpty);
      for (final p in books) {
        final id = _tree(p)['id'] as String;
        final book = await catalog.book(id);
        expect(book!.toJson(), sameJson(jsonDecode(smallTree[p]!)));
        await catalog.book(id);
        expect(files.count(p), 1);
      }
    });

    test('a book that is not there is null, and stays null (libro keeps its answer)', () async {
      final (catalog, files) = await _loaded();
      final id = _courseStories.firstWhere(
        (c) => !smallTree.containsKey('libros/$c.json'),
      );
      expect(await catalog.book(id), isNull);
      files.files['libros/$id.json'] = smallTree.entries
          .firstWhere((e) => e.key.startsWith('libros/'))
          .value;
      expect(await catalog.book(id), isNull);
      expect(files.count('libros/$id.json'), 1);
    });

    test('a book file that is not a book is null', () async {
      final (catalog, _) = await _loaded({
        'libros/broken.json': '{"id":"broken"}',
      });
      expect(await catalog.book('broken'), isNull);
    });
  });

  group('pairs (cual.js, pares)', () {
    test('pairs are the items of the review sets, in the order curso.json names them', () async {
      final (catalog, _) = await _loaded();
      expect([
        for (final p in catalog.pairs) {...p.toJson(), 'esc': p.scene},
      ], sameJson(_expected.pairs));
    });

    test('pairFor gives each word of pares().m its own pair', () async {
      final (catalog, _) = await _loaded();
      expect(_expected.words, hasLength(catalog.pairs.length));
      for (final w in _expected.words) {
        final p = catalog.pairFor(w);
        expect(p, isNotNull, reason: w);
        expect(p!.word, w);
        expect(catalog.pairs, contains(p));
      }
    });

    test(
      'pairFor matches on normalize: case, accents and punctuation are ignored',
      () async {
        final (catalog, _) = await _loaded();
        for (final p in catalog.pairs) {
          final plain = normalize(p.word).trim();
          expect(
            normalize(catalog.pairFor(plain.toUpperCase())!.word),
            normalize(p.word),
          );
          expect(
            normalize(catalog.pairFor('  $plain! ')!.word),
            normalize(p.word),
          );
        }
        expect(catalog.pairFor('no such word'), isNull);
        expect(catalog.pairFor(''), isNull);
      },
    );

    test('two words with one normalised form: the exact word gives its own pair, another spelling the first', () async {
      final (catalog, _) = await _loaded();
      final groups = <String, List<ReviewPair>>{};
      for (final p in catalog.pairs) {
        (groups[normalize(p.word)] ??= []).add(p);
      }
      final clashes = groups.values.where(
        (g) => g.map((p) => p.word).toSet().length > 1,
      );
      expect(
        clashes,
        isNotEmpty,
        reason: 'the small course holds two such pairs',
      );
      for (final g in clashes) {
        for (final p in g) {
          expect(catalog.pairFor(p.word), same(p));
        }
        final spelled = g.first.word.toUpperCase();
        expect(g.map((p) => p.word), isNot(contains(spelled)));
        expect(catalog.pairFor(spelled), same(g.first));
      }
    });
  });

  group('clip', () {
    test('a clip with a recording and marks has its marks and the url juego.js builds', () async {
      final (catalog, _) = await _loaded();
      final ids = (_ready['clips'] as List).cast<String>();
      expect(_expected.urls, isNotEmpty);
      for (final id in ids) {
        final c = catalog.clip(id);
        final m = _marks[id] as List;
        expect(c, isNotNull, reason: id);
        expect(c!.id, id);
        expect([c.startMs, c.endMs], [m[0], m[1]], reason: id);
        expect(c.url, startsWith('audio/$id.mp3?v='));
        if (_expected.urls[id] != null) expect(c.url, _expected.urls[id]);
      }
      for (final e in _expected.urls.entries) {
        expect(catalog.clip(e.key)!.url, e.value);
      }
    });

    test('a clip without a recording is null, so is one without marks, and so is one that is not in the course', () async {
      final (catalog, _) = await _loaded();
      for (final id in _expectedWithoutRecording) {
        expect(_marks.containsKey(id), isFalse, reason: id);
        expect(catalog.clip(id), isNull, reason: id);
      }
      final first = (_ready['clips'] as List).first as String;
      final ready = {
        ..._ready,
        'clips': [..._ready['clips'] as List, 'extra_clip'],
      };
      final noMarks = await _loaded({'audio/ready.json': jsonEncode(ready)});
      expect(noMarks.$1.clip('extra_clip'), isNull);
      expect(noMarks.$1.clip(first), isNotNull);
      final marks = {
        ..._marks,
        'unlisted_clip': [1, 2, 3],
      };
      final notListed = await _loaded({'audio/marcas.json': jsonEncode(marks)});
      expect(notListed.$1.clip('unlisted_clip'), isNull);
      expect(catalog.clip('no_such_clip'), isNull);
    });

    test('the version in the url is ready.json v, and 0 where it has none (j.v||0)', () async {
      final id = (_ready['clips'] as List).first as String;
      for (final (v, text) in <(Object?, String)>[
        (12345, '12345'),
        (0, '0'),
        (null, '0'),
        ('', '0'),
        (7.0, '7'),
        (1.5, '1.5'),
      ]) {
        final ready = {..._ready, 'v': v}
          ..removeWhere((k, x) => k == 'v' && v == null);
        final (catalog, _) = await _loaded({
          'audio/ready.json': jsonEncode(ready),
        });
        expect(catalog.clip(id)!.url, 'audio/$id.mp3?v=$text', reason: '$v');
      }
    });

    test('who, text and habla are known from the review sets at load, and from a story once it is read', () async {
      final (catalog, _) = await _loaded();
      final cualClips = <String>{
        for (final f in _curso['cual'] as List)
          ...(_tree('cuentos/$f.json')['clips'] as Map).keys.cast<String>(),
      };
      final ready = (_ready['clips'] as List).cast<String>().toSet();
      // a clip of a review set: known at load
      final setClip = cualClips.firstWhere(ready.contains);
      final line = _firstLine(setClip)!;
      expect(catalog.clip(setClip)!.who, line['who']);
      expect(catalog.clip(setClip)!.text, line['text']);
      // a clip only a story has: marks and url, no line, until the story is read
      final id = _courseStories.last;
      final only = (_tree('cuentos/$id.json')['clips'] as Map).keys
          .cast<String>()
          .firstWhere((c) => ready.contains(c) && !cualClips.contains(c));
      final before = catalog.clip(only)!;
      expect([before.who, before.text, before.habla], ['', '', null]);
      expect(before.endMs, greaterThan(before.startMs));
      await catalog.story(id);
      final after = catalog.clip(only)!;
      final story = (_tree('cuentos/$id.json')['clips'] as Map)[only] as Map;
      expect(
        [after.who, after.text, after.habla],
        [story['who'], story['text'], story['habla']],
      );
      expect(after.url, before.url);
      expect([after.startMs, after.endMs], [before.startMs, before.endMs]);
    });

    test('the words said alone (cuentos/palabras-solas.json): their line is known at load, and the file is no story and no review set', () async {
      final solas = jsonEncode({
        'id': 'palabras-solas',
        'title': 'Palabras',
        'tipo': 'palabras',
        'clips': {
          'w_casa': {'who': 'narr', 'text': 'Casa.'},
          'w_tu_a': {'who': 'narr', 'text': 'Tú.'},
          'w_sin_voz': {'who': 'narr', 'text': 'Sin voz.'},
        },
      });
      final changes = {
        'cuentos/palabras-solas.json': solas,
        'audio/ready.json': jsonEncode({
          ..._ready,
          'clips': [..._ready['clips'] as List, 'w_casa', 'w_tu_a'],
        }),
        'audio/marcas.json': jsonEncode({
          ..._marks,
          'w_casa': [150, 900, 1200],
          'w_tu_a': [160, 700, 1000],
        }),
      };
      final (catalog, files) = await _loaded(changes);
      final (plain, _) = await _loaded();
      for (final (id, text) in [('w_casa', 'Casa.'), ('w_tu_a', 'Tú.')]) {
        final c = catalog.clip(id)!;
        expect([c.id, c.who, c.text, c.habla], [id, 'narr', text, null]);
        expect(c.url, 'audio/$id.mp3?v=${_ready['v']}');
      }
      expect(
        [catalog.clip('w_casa')!.startMs, catalog.clip('w_casa')!.endMs],
        [150, 900],
      );
      expect(catalog.clip('w_sin_voz'), isNull, reason: 'no recording');
      // not a story, not a review set: nothing else the catalog says changes, and no story was asked for
      expect(catalog.meta('palabras-solas'), isNull);
      expect([
        for (final p in catalog.places) ...[...p.stories, ...p.routines],
      ], isNot(contains('palabras-solas')));
      expect(catalog.pairs.length, plain.pairs.length);
      expect(
        [for (final p in catalog.pairs) p.word],
        [for (final p in plain.pairs) p.word],
      );
      expect(files.count('cuentos/palabras-solas.json'), 1);
      // the other clips are as they were
      final id = (_ready['clips'] as List).first as String;
      expect(catalog.clip(id)!.text, plain.clip(id)!.text);
      // a story that has the same id says its own line once it has been read (juego.js: a story's own line wins)
      final story = _tree('cuentos/la-lluvia.json');
      (story['clips'] as Map)['w_casa'] = {
        'who': 'abuela',
        'text': 'Casa, casa.',
      };
      final (own, _) = await _loaded({
        ...changes,
        'cuentos/la-lluvia.json': jsonEncode(story),
      });
      expect(own.clip('w_casa')!.text, 'Casa.');
      await own.story('la-lluvia');
      expect(
        [own.clip('w_casa')!.who, own.clip('w_casa')!.text],
        ['abuela', 'Casa, casa.'],
      );
    });

    test('the file of the words said alone missing or broken is no error: the clip has marks and a url and no line', () async {
      final ready = {
        ..._ready,
        'clips': [..._ready['clips'] as List, 'w_casa'],
      };
      final marks = {
        ..._marks,
        'w_casa': [150, 900, 1200],
      };
      for (final bad in [
        null,
        'nope',
        '[1]',
        '{}',
        '{"clips":[]}',
        '{"clips":{"w_casa":7}}',
      ]) {
        final files = {
          ...smallTree,
          'audio/ready.json': jsonEncode(ready),
          'audio/marcas.json': jsonEncode(marks),
        };
        if (bad != null) files['cuentos/palabras-solas.json'] = bad;
        final catalog = ContentCatalog(Files(files).call);
        await catalog.load();
        expect(catalog.loaded, isTrue, reason: '$bad');
        final c = catalog.clip('w_casa')!;
        expect(
          [c.who, c.text, c.url],
          ['', '', 'audio/w_casa.mp3?v=${_ready['v']}'],
          reason: '$bad',
        );
        expect([c.startMs, c.endMs], [150, 900], reason: '$bad');
        expect(catalog.pairs, isNotEmpty, reason: '$bad');
      }
    });

    test('a clip with a habla form keeps it', () async {
      final (catalog, _) = await _loaded();
      await Future.wait([for (final c in _courseStories) catalog.story(c)]);
      var withHabla = 0;
      for (final id in (_ready['clips'] as List).cast<String>()) {
        final line = _firstLine(id);
        if (line == null) continue;
        final c = catalog.clip(id)!;
        expect(
          [c.who, c.text, c.habla],
          [line['who'], line['text'], line['habla']],
          reason: id,
        );
        if (line['habla'] != null) withHabla++;
      }
      expect(withHabla, greaterThan(0));
    });
  });

  group('lines the old code writes in code (fijos.json, lineas)', () {
    final fijos = _tree('datos/fijos.json');
    final lineas = Map<String, dynamic>.from(fijos['lineas'] as Map);
    final id = lineas.keys.first;

    /// The story of the small course that has a line of its own for [id], and that line.
    String storyWith(String id) => _courseStories.firstWhere(
      (c) => (_tree('cuentos/$c.json')['clips'] as Map).containsKey(id),
    );

    Map<String, String> fijosWith(Object? lineas) => {
      'datos/fijos.json': jsonEncode({
        for (final e in fijos.entries)
          if (e.key != 'lineas') e.key: e.value,
        'lineas': ?lineas,
      }),
    };

    test('a clip the code gives a line to has it right after load, with no story read', () async {
      final (catalog, files) = await _loaded();
      expect(lineas, isNotEmpty);
      expect(lineas.keys, contains(catalog.fixedClip('story_your_turn')));
      for (final e in lineas.entries) {
        final c = catalog.clip(e.key);
        final line = e.value as Map;
        expect(c, isNotNull, reason: e.key);
        expect([c!.who, c.text, c.habla], [line['who'], line['text'], null]);
        expect(c.endMs, greaterThan(c.startMs));
        expect(c.url, startsWith('audio/${e.key}.mp3?v='));
      }
      expect(catalog.clip(id)!.who, 'narr');
      expect(
        files.calls.where((p) => p.startsWith('cuentos/')),
        isNot(contains('cuentos/${storyWith(id)}.json')),
      );
    });

    test(
      'a story that has the same id wins over it, once it has been read',
      () async {
        final other = {'who': 'tu', 'text': 'written elsewhere'};
        final (catalog, _) = await _loaded(fijosWith({id: other}));
        expect(
          (_ready['clips'] as List).contains(id),
          isTrue,
          reason: 'the small course keeps its recording',
        );
        final before = catalog.clip(id)!;
        expect([before.who, before.text], [other['who'], other['text']]);
        final sid = storyWith(id);
        await catalog.story(sid);
        final story = (_tree('cuentos/$sid.json')['clips'] as Map)[id] as Map;
        final after = catalog.clip(id)!;
        expect(
          [after.who, after.text, after.habla],
          [story['who'], story['text'], story['habla']],
        );
        expect(after.text, isNot(other['text']));
      },
    );

    test('a clip without a recording or marks stays null', () async {
      final (catalog, _) = await _loaded(
        fijosWith({
          ...lineas,
          'no_such_clip': {'who': 'narr', 'text': 'x'},
          _expectedWithoutRecording.first: {'who': 'narr', 'text': 'x'},
        }),
      );
      expect(catalog.clip('no_such_clip'), isNull);
      expect(catalog.clip(_expectedWithoutRecording.first), isNull);
      expect(catalog.clip(id), isNotNull);
    });

    test('a fijos.json without lineas loads, and the clip has no line until its story is read', () async {
      final (catalog, files) = await _loaded(fijosWith(null));
      expect(files.calls, contains('datos/fijos.json'));
      expect(catalog.fixedClip('story_your_turn'), id);
      final before = catalog.clip(id)!;
      expect([before.who, before.text], ['', '']);
      await catalog.story(storyWith(id));
      expect(catalog.clip(id)!.text, isNotEmpty);
    });

    test('lineas that is not an object of {who, text} is a FormatException that names the file', () async {
      for (final bad in <Object>[
        [1],
        'x',
        {id: 'Ahora'},
        {
          id: [1],
        },
      ]) {
        final catalog = ContentCatalog(
          Files({...smallTree, ...fijosWith(bad)}).call,
        );
        await expectLater(
          catalog.load(),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              startsWith('datos/fijos.json: lineas'),
            ),
          ),
          reason: '$bad',
        );
      }
    });
  });

  group('linesWith (app.html, oidoEn)', () {
    test(
      'every word, both cases: the lines the old code gives, in its order',
      () async {
        final (catalog, _) = await _loaded();
        expect(_expected.wordList, isNotEmpty);
        var nonEmpty = 0;
        for (final w in _expected.wordList) {
          for (final all in [true, false]) {
            final ids = all ? _expected.allPlayed : _expected.place1Played;
            final got = await catalog.linesWith(w, ids);
            final want = _expected.lines(w, allStories: all);
            expectSameLines(
              got,
              want,
              _expected.titles,
              '$w, ${all ? 'all' : 'place 1'}',
            );
            if (want.isNotEmpty) nonEmpty++;
          }
        }
        expect(nonEmpty, greaterThan(20));
      },
    );

    test('the order of the story ids given does not matter: the stories come in the course order', () async {
      final (catalog, _) = await _loaded();
      for (final w in _expected.wordList) {
        final got = await catalog.linesWith(w, _expected.allPlayed.reversed);
        expectSameLines(
          got,
          _expected.lines(w, allStories: true),
          _expected.titles,
          w,
        );
      }
    });

    test('an id that is not a story of a place is left out, as oidoEn leaves it out', () async {
      final (catalog, _) = await _loaded();
      final set = (_curso['cual'] as List).first as String;
      for (final w in _expected.wordList) {
        final got = await catalog.linesWith(w, [
          ..._expected.place1Played,
          set,
          'no-such-story',
        ]);
        expectSameLines(
          got,
          _expected.lines(w, allStories: false),
          _expected.titles,
          w,
        );
      }
    });

    test('max limits the lines to the first of those the old code gives, and 0 gives none', () async {
      final (catalog, _) = await _loaded();
      var checked = 0;
      for (final w in _expected.wordList) {
        final want = _expected.lines(w, allStories: true);
        for (final max in [0, 1, 2, 3]) {
          final got = await catalog.linesWith(w, _expected.allPlayed, max: max);
          expectSameLines(
            got,
            want.take(max).toList(),
            _expected.titles,
            '$w max $max',
          );
        }
        if (want.length > 3) checked++;
      }
      expect(checked, greaterThan(0));
    });

    test(
      'a text already given is given once: the lines are different texts',
      () async {
        final (catalog, _) = await _loaded();
        for (final w in _expected.wordList) {
          final got = await catalog.linesWith(w, _expected.allPlayed);
          expect(
            got.map((l) => normalize(l.text)).toSet(),
            hasLength(got.length),
            reason: w,
          );
        }
      },
    );

    test(
      'a line without a recording is left out, and with no ready.json none is',
      () async {
        final (catalog, _) = await _loaded();
        final without = _expectedWithoutRecording.toSet();
        expect(without, isNotEmpty);
        for (final w in _expected.wordList) {
          final got = await catalog.linesWith(w, _expected.allPlayed);
          expect(
            got.where((l) => without.contains(l.clipId)),
            isEmpty,
            reason: w,
          );
        }
        // oidoEn: `!HAVE||HAVE.has(id)` — with no file the filter is off; the same as a file that lists every clip
        final noFile = {...smallTree}..remove('audio/ready.json');
        final listsAll = {
          ..._ready,
          'clips': [...(_ready['clips'] as List), ...without],
        };
        final a = ContentCatalog(Files(noFile).call);
        final b = ContentCatalog(
          Files({...smallTree, 'audio/ready.json': jsonEncode(listsAll)}).call,
        );
        await Future.wait([a.load(), b.load()]);
        var differs = 0;
        for (final w in _expected.wordList) {
          final x = await a.linesWith(w, _expected.allPlayed);
          final y = await b.linesWith(w, _expected.allPlayed);
          expect(
            [for (final l in x) l.clipId],
            [for (final l in y) l.clipId],
            reason: w,
          );
          final z = await catalog.linesWith(w, _expected.allPlayed);
          if ([for (final l in x) l.clipId].join(' ') !=
              [for (final l in z) l.clipId].join(' ')) {
            differs++;
          }
        }
        expect(
          differs,
          greaterThan(0),
          reason: 'the filter changes some answer',
        );
      },
    );

    test('a story whose file cannot be read is left out (STOV has no entry for it)', () async {
      final gone = _courseStories.first;
      final (full, _) = await _loaded();
      final (cut, cutFiles) = await _loaded();
      cutFiles.files.remove('cuentos/$gone.json');
      final rest = [..._expected.allPlayed]..remove(gone);
      for (final w in _expected.wordList) {
        final want = await full.linesWith(w, rest);
        final got = await cut.linesWith(w, _expected.allPlayed);
        expect(
          [for (final l in got) l.clipId],
          [for (final l in want) l.clipId],
          reason: w,
        );
      }
    });

    test('a story is read once for all the words', () async {
      final (catalog, files) = await _loaded();
      for (final w in _expected.wordList) {
        await catalog.linesWith(w, _expected.allPlayed);
      }
      for (final c in _courseStories) {
        expect(files.count('cuentos/$c.json'), 1, reason: c);
      }
    });
  });

  group('language (idioma)', () {
    // NOT CHECKED BY AN ARABIC SPEAKER.
    Map<String, dynamic> arabicIdioma({bool withA11y = true}) => {
      'code': 'ar',
      'englishName': 'Arabic',
      'nativeName': 'العربية',
      'recognitionLocale': 'ar-SA',
      'direction': 'rtl',
      'script': 'Arab',
      'partnerName': 'Tariq',
      'callAgentId': 'agent_arabic_test',
      'micWords': {
        'ready': 'اضغط وتكلم',
        'listening': 'أسمعك',
        'thinking': 'لحظة',
        'theySpeak': 'استمع',
        'right': 'ممتاز',
        'notYet': 'مرة أخرى',
      },
      'tabNames': {
        'library': 'المكتبة',
        'words': 'الكلمات',
        'map': 'الخريطة',
        'speak': 'تحدث',
        'me': 'أنا',
      },
      if (withA11y) 'a11yWords': {'close': 'إغلاق'},
    };

    test('defaults to Language.spanish before and after load when idioma is missing or null', () async {
      final before = ContentCatalog(Files(smallTree).call);
      expect(before, isA<LanguageCatalog>());
      expect(before.language, Language.spanish);
      expect((before as CourseCatalog).language, Language.spanish);

      await before.load();
      expect(before.language, Language.spanish);
      expect((before as CourseCatalog).language, Language.spanish);
      final llamadas = _tree('datos/llamadas.json');
      for (final id in llamadas.keys) {
        expect(before.callFor(id)!.agentId, spanishCallAgentId, reason: id);
        expect(before.callFor(id)!.agentId, Language.spanish.callAgentId);
      }

      final withNull = {
        ...smallTree,
        'datos/curso.json': jsonEncode({..._curso, 'idioma': null}),
      };
      final (nullCatalog, _) = await _loaded(withNull);
      expect(nullCatalog.language, Language.spanish);
      expect((nullCatalog as CourseCatalog).language, Language.spanish);
    });

    test('parses custom Arabic/RTL idioma, uses language.normalize in pairFor and linesWith, and applies callAgentId precedence', () async {
      // NOT CHECKED BY AN ARABIC SPEAKER.
      final arabicLang = Language(
        code: 'ar',
        englishName: 'Arabic',
        nativeName: 'العربية',
        recognitionLocale: 'ar-SA',
        direction: LanguageDirection.rtl,
        script: 'Arab',
        partnerName: 'Tariq',
        callAgentId: 'agent_arabic_test',
        micWords: const {
          'ready': 'اضغط وتكلم',
          'listening': 'أسمعك',
          'thinking': 'لحظة',
          'theySpeak': 'استمع',
          'right': 'ممتاز',
          'notYet': 'مرة أخرى',
        },
        tabNames: const {
          'library': 'المكتبة',
          'words': 'الكلمات',
          'map': 'الخريطة',
          'speak': 'تحدث',
          'me': 'أنا',
        },
        a11yWords: const {'close': 'إغلاق'},
      );

      final arabicCurso = {
        'idioma': arabicIdioma(),
        'lugares': [
          {
            'id': 'casa',
            'n': 1,
            'nombre': 'البيت',
            'en': 'The house',
            'cuentos': ['ar-story'],
          },
        ],
        'cuentos': {
          'ar-story': {'t': 'القصة', 'min': 2},
        },
        'cual': ['cual-ar'],
      };

      const dummyPicture = {
        'cam': [0, 0, 100, 100],
      };
      final arabicCual = {
        'id': 'cual-ar',
        'title': 'أي؟',
        'place': 'البيت',
        'scene': 'frente',
        'tipo': 'cual',
        'clips': {
          'ar_1': {'who': 'narr', 'text': 'مَرْحَبًا'},
          'ar_2': {'who': 'narr', 'text': 'أحمد'},
          'ar_3': {'who': 'narr', 'text': 'بيت'},
          'ar_4': {'who': 'narr', 'text': 'باب'},
        },
        'items': [
          {
            'w': 'مَرْحَبًا',
            'say': 'ar_1',
            'si': dummyPicture,
            'no': dummyPicture,
          },
          {'w': 'أحمد', 'say': 'ar_2', 'si': dummyPicture, 'no': dummyPicture},
          {'w': 'بيت', 'say': 'ar_3', 'si': dummyPicture, 'no': dummyPicture},
          {'w': 'باب', 'say': 'ar_4', 'si': dummyPicture, 'no': dummyPicture},
        ],
      };

      final arabicStory = {
        'id': 'ar-story',
        'title': 'القصة',
        'place': 'البيت',
        'scene': 'frente',
        'clips': {
          'c1': {'who': 'narr', 'text': 'مَرْحَبًا يَا جَدَّةُ!'},
          'c2': {'who': 'narr', 'text': 'مرحبا يا جدة'},
          'c3': {'who': 'narr', 'text': 'هذا بيت كبير.'},
          'c4': {'who': 'narr', 'text': 'هذا باب.'},
        },
        'leer': ['c1', 'c2', 'c3', 'c4'],
      };

      final arabicCalls = {
        'casa': {'minutos': 5, 'job': 'Greet Tariq.', 'opening': 'مَرْحَبًا!'},
        'mercado': {
          'minutos': 5,
          'job': 'Ask the price.',
          'opening': 'بكم هذا؟',
          'agentId': 'agent_per_call',
        },
        'plaza': {
          'minutos': 5,
          'job': 'Legacy lowercase key.',
          'opening': 'أهلا!',
          'agentid': 'agent_legacy_lower',
        },
        'puerto': {
          'minutos': 5,
          'job': 'Whitespace falls back to idioma.',
          'opening': 'السلام عليكم!',
          'agentId': '   ',
        },
      };

      final files = {
        ...smallTree,
        'datos/curso.json': jsonEncode(arabicCurso),
        'datos/llamadas.json': jsonEncode(arabicCalls),
        'cuentos/cual-ar.json': jsonEncode(arabicCual),
        'cuentos/ar-story.json': jsonEncode(arabicStory),
        'audio/ready.json': jsonEncode({
          'v': 1,
          'clips': ['c1', 'c2', 'c3', 'c4'],
        }),
        'audio/marcas.json': jsonEncode({
          'c1': [0, 1000, 1200],
          'c2': [0, 1000, 1200],
          'c3': [0, 1000, 1200],
          'c4': [0, 1000, 1200],
        }),
      };

      final (catalog, _) = await _loaded(files);
      expect(catalog.language, arabicLang);
      expect((catalog as CourseCatalog).language, catalog.language);

      // Optional a11yWords omitted still loads with empty map.
      final (noA11y, _) = await _loaded({
        ...files,
        'datos/curso.json': jsonEncode({
          ...arabicCurso,
          'idioma': arabicIdioma(withA11y: false),
        }),
      });
      expect(noA11y.language.a11yWords, isEmpty);

      // pairFor uses Arabic word rules.
      expect(catalog.pairFor('مرحبا')!.word, 'مَرْحَبًا');
      expect(catalog.pairFor('  مـرحـبا! ')!.word, 'مَرْحَبًا');
      expect(catalog.pairFor('احمد')!.word, 'أحمد');
      expect(catalog.pairFor('بيت')!.word, 'بيت');
      expect(catalog.pairFor('باب')!.word, 'باب');
      expect(catalog.pairFor('ماء'), isNull);
      expect(catalog.pairFor(''), isNull);

      // linesWith uses Arabic normalization for matching AND deduplication.
      final greetings = await catalog.linesWith('مرحبا', ['ar-story']);
      expect(greetings, hasLength(1));
      expect(greetings.single.clipId, 'c1');
      expect(greetings.single.text, 'مَرْحَبًا يَا جَدَّةُ!');

      final houseLines = await catalog.linesWith('بيت', ['ar-story']);
      expect(houseLines, hasLength(1));
      expect(houseLines.single.clipId, 'c3');
      expect(houseLines.single.text, 'هذا بيت كبير.');

      // callFor agentId precedence.
      expect(catalog.callFor('casa')!.agentId, 'agent_arabic_test');
      expect(catalog.callFor('mercado')!.agentId, 'agent_per_call');
      expect(catalog.callFor('plaza')!.agentId, 'agent_legacy_lower');
      expect(catalog.callFor('puerto')!.agentId, 'agent_arabic_test');
    });

    test('invalid idioma fails cleanly without mutating state and allows retry once fixed', () async {
      final invalidCases = <String, Object?>{
        'string': 'es',
        'list': [1],
        'bad direction': {...arabicIdioma(), 'direction': 'up'},
        'missing code': arabicIdioma()..remove('code'),
        'empty callAgentId': {...arabicIdioma(), 'callAgentId': '   '},
        'missing tabNames key': {
          ...arabicIdioma(),
          'tabNames': Map<String, String>.from(
            arabicIdioma()['tabNames'] as Map,
          )..remove('map'),
        },
        'missing micWords key': {
          ...arabicIdioma(),
          'micWords': Map<String, String>.from(
            arabicIdioma()['micWords'] as Map,
          )..remove('ready'),
        },
        'non-map a11yWords': {...arabicIdioma(), 'a11yWords': 'close'},
        'non-string a11yWords value': {
          ...arabicIdioma(),
          'a11yWords': {'close': 42},
        },
      };

      for (final entry in invalidCases.entries) {
        final files = Files({
          ...smallTree,
          'datos/curso.json': jsonEncode({..._curso, 'idioma': entry.value}),
        });
        final catalog = ContentCatalog(files.call);
        await expectLater(
          catalog.load(),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              startsWith('datos/curso.json: idioma'),
            ),
          ),
          reason: entry.key,
        );
        expect(catalog.loaded, isFalse, reason: entry.key);
        expect(catalog.language, Language.spanish, reason: entry.key);
      }

      // Unsupported script with non-empty review pairs throws UnsupportedError naming the script.
      final cyrlFiles = Files({
        ...smallTree,
        'datos/curso.json': jsonEncode({
          ..._curso,
          'idioma': {...arabicIdioma(), 'script': 'Cyrl'},
        }),
      });
      final cyrlCatalog = ContentCatalog(cyrlFiles.call);
      await expectLater(
        cyrlCatalog.load(),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.toString(),
            'toString',
            contains('Cyrl'),
          ),
        ),
      );
      expect(cyrlCatalog.loaded, isFalse);
      expect(cyrlCatalog.language, Language.spanish);

      // Fixing datos/curso.json on the same instance allows load() to succeed cleanly.
      cyrlFiles.files['datos/curso.json'] = jsonEncode({
        ..._curso,
        'idioma': null,
      });
      await cyrlCatalog.load();
      expect(cyrlCatalog.loaded, isTrue);
      expect(cyrlCatalog.language, Language.spanish);
    });
  });

  group('calls (CallsCatalog)', () {
    test('implements CallsCatalog and returns unmodifiable single-call list for legacy datos/llamadas.json', () async {
      final (catalog, _) = await _loaded();
      expect(catalog, isA<CallsCatalog>());
      final CourseCatalog course = catalog;

      final mainCall = catalog.callFor('casa')!;
      final calls = catalog.callsFor('casa');
      expect(calls, hasLength(1));
      expect(calls.single, same(mainCall));
      expect(course.callsFor('casa'), [mainCall]);
      expect(catalog.callsFor('no-such-place'), isEmpty);
      expect(course.callsFor('no-such-place'), isEmpty);

      expect(() => calls.add(mainCall), throwsUnsupportedError);
    });

    test('parses multi-call array format alongside legacy object format with main selection, nullable photo, and agentId precedence', () async {
      final callsData = <String, Object?>{
        'casa': {
          'minutos': 5,
          'job': 'Legacy single call.',
          'opening': 'Hello!',
          'foto': 'casa',
        },
        'market': [
          {
            'id': 'market_small_1',
            'title': 'Fruit stand',
            'jobEn': 'Ask for fruit prices.',
            'minutos': 2,
            'job': 'Ask for fruit prices.',
            'opening': '',
            'isMain': false,
          },
          {
            'id': 'market_main',
            'title': 'Market visit',
            'jobEn': 'Buy groceries and pay.',
            'minutos': 5,
            'job': 'Buy groceries and pay.',
            'opening': 'Good morning!',
            'foto': null,
            'agentId': 'agent_market_main',
          },
          {
            'id': 'market_small_2',
            'title': 'Checkout line',
            'jobEn': 'Pay at the register.',
            'minutos': 2,
            'job': 'Pay at the register.',
            'opening': '',
            'isMain': false,
            'agentid': 'agent_legacy_small',
          },
        ],
        'harbor': [
          {
            'id': 'harbor_boats',
            'title': 'Boats',
            'jobEn': 'Talk about the boats.',
            'minutos': 2,
            'job': 'Talk about the boats.',
            'opening': '',
            'isMain': false,
          },
          {
            'id': 'harbor_tickets',
            'title': 'Tickets',
            'jobEn': 'Buy a ferry ticket.',
            'minutos': 3,
            'job': 'Buy a ferry ticket.',
            'opening': '',
            'isMain': false,
          },
        ],
        'empty_place': <Object?>[],
      };

      final (catalog, _) = await _loaded({
        'datos/llamadas.json': jsonEncode(callsData),
      });
      final CourseCatalog course = catalog;

      // Legacy single-object place still works.
      final casaCalls = course.callsFor('casa');
      expect(casaCalls, hasLength(1));
      expect(casaCalls.single.id, 'casa');
      expect(casaCalls.single.photo, 'casa');
      expect(casaCalls.single.isMain, isTrue);
      expect(casaCalls.single.agentId, spanishCallAgentId);

      // Multi-call place keeps order; callFor returns the isMain call even when not first.
      final marketCalls = course.callsFor('market');
      expect(
        [for (final c in marketCalls) c.id],
        ['market_small_1', 'market_main', 'market_small_2'],
      );
      expect(catalog.callFor('market')!.id, 'market_main');
      expect(catalog.callFor('market')!.isMain, isTrue);
      expect(catalog.callFor('market')!.photo, isNull);
      expect(catalog.callFor('market')!.agentId, 'agent_market_main');
      expect(marketCalls[0].isMain, isFalse);
      expect(marketCalls[0].photo, isNull);
      expect(marketCalls[0].agentId, spanishCallAgentId);
      expect(marketCalls[2].agentId, 'agent_legacy_small');
      expect(() => marketCalls.add(marketCalls.first), throwsUnsupportedError);

      // When all calls have isMain: false, callFor falls back to the first call.
      expect(course.callsFor('harbor'), hasLength(2));
      expect(catalog.callFor('harbor')!.id, 'harbor_boats');

      // Empty array yields empty list and null callFor.
      expect(course.callsFor('empty_place'), isEmpty);
      expect(catalog.callFor('empty_place'), isNull);
    });

    test('malformed datos/llamadas.json throws FormatException without mutating state and recovers on retry', () async {
      final validCall = <String, Object?>{
        'id': 'casa_main',
        'title': 'Main visit',
        'jobEn': 'Say hello.',
        'minutos': 5,
        'job': 'Say hello.',
        'opening': 'Hi!',
      };

      final invalidCases = <String, Object?>{
        'place is string': {'casa': 'bad'},
        'place is int': {'casa': 42},
        'array element not object': {
          'casa': ['bad'],
        },
        'blank id': {
          'casa': [
            {...validCall, 'id': '   '},
          ],
        },
        'non-string id': {
          'casa': [
            {...validCall, 'id': 123},
          ],
        },
        'non-string title': {
          'casa': [
            {...validCall, 'title': 123},
          ],
        },
        'non-string jobEn': {
          'casa': [
            {...validCall, 'jobEn': false},
          ],
        },
        'missing minutos': {
          'casa': [Map<String, Object?>.from(validCall)..remove('minutos')],
        },
        'zero minutos': {
          'casa': [
            {...validCall, 'minutos': 0},
          ],
        },
        'negative minutos': {
          'casa': [
            {...validCall, 'minutos': -2},
          ],
        },
        'fractional minutos': {
          'casa': [
            {...validCall, 'minutos': 2.5},
          ],
        },
        'non-numeric minutos': {
          'casa': [
            {...validCall, 'minutos': '5'},
          ],
        },
        'missing job': {
          'casa': [Map<String, Object?>.from(validCall)..remove('job')],
        },
        'missing opening': {
          'casa': [Map<String, Object?>.from(validCall)..remove('opening')],
        },
        'non-string foto': {
          'casa': [
            {...validCall, 'foto': 7},
          ],
        },
        'non-bool isMain': {
          'casa': [
            {...validCall, 'isMain': 'yes'},
          ],
        },
        'non-string agentId': {
          'casa': [
            {...validCall, 'agentId': 12},
          ],
        },
        'non-string agentid': {
          'casa': [
            {...validCall, 'agentid': true},
          ],
        },
        'duplicate call id in place': {
          'casa': [
            validCall,
            {...validCall, 'isMain': false},
          ],
        },
        'duplicate call id across places': {
          'casa': [validCall],
          'parque': [validCall],
        },
        'multiple main calls in place': {
          'casa': [
            validCall,
            {...validCall, 'id': 'casa_other', 'isMain': true},
          ],
        },
      };

      for (final entry in invalidCases.entries) {
        final files = Files({
          ...smallTree,
          'datos/llamadas.json': jsonEncode(entry.value),
        });
        final catalog = ContentCatalog(files.call);
        await expectLater(
          catalog.load(),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              startsWith('datos/llamadas.json'),
            ),
          ),
          reason: entry.key,
        );
        expect(catalog.loaded, isFalse, reason: entry.key);
        expect(catalog.callFor('casa'), isNull, reason: entry.key);
        expect(catalog.callsFor('casa'), isEmpty, reason: entry.key);
      }

      // Fixing datos/llamadas.json on the same catalog instance allows retry to succeed cleanly.
      final retryFiles = Files({
        ...smallTree,
        'datos/llamadas.json': jsonEncode({'casa': 'bad'}),
      });
      final retryCatalog = ContentCatalog(retryFiles.call);
      await expectLater(retryCatalog.load(), throwsFormatException);
      expect(retryCatalog.loaded, isFalse);

      retryFiles.files['datos/llamadas.json'] =
          smallTree['datos/llamadas.json']!;
      await retryCatalog.load();
      expect(retryCatalog.loaded, isTrue);
      expect(retryCatalog.callsFor('casa'), hasLength(1));
      expect(retryCatalog.callFor('casa')!.id, 'casa');
    });
  });
}

/// The ids ready.json leaves out in the small course: the clips of its stories that have no recording.
List<String> get _expectedWithoutRecording {
  final have = (_ready['clips'] as List).cast<String>().toSet();
  final all = <String>{
    for (final path in smallTree.keys)
      if (path.startsWith('cuentos/'))
        ...((_tree(path)['clips'] as Map?)?.keys.cast<String>() ??
            const <String>[]),
  };
  return (all.difference(have).toList()..sort());
}

/// The line `{who, text, habla}` of [id] in the first story file of the course that has it.
Map<String, dynamic>? _firstLine(String id) {
  for (final path in smallTree.keys) {
    if (!path.startsWith('cuentos/')) continue;
    final clips = _tree(path)['clips'] as Map?;
    if (clips != null && clips[id] != null) {
      return Map<String, dynamic>.from(clips[id] as Map);
    }
  }
  return null;
}
