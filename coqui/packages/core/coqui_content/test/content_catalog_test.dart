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
