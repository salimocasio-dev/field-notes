// The catalog over the real files under historia/ (vm only: chrome cannot read files). The answers the old code gives
// are in fixture/real_expected.json, made by tool/make_expected.mjs in node: pares() and oidoEn() from app.html and
// cualCarga() from cual.js, run over these same files.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:coqui_content/coqui_content.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:test/test.dart';

import 'support.dart';

/// historia/, found from where the tests run (the package folder, or coqui/, or the repository's root).
final Directory _historia = () {
  var dir = Directory.current.absolute;
  while (true) {
    final candidate = Directory('${dir.path}/historia');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('no historia/ above ${Directory.current.path}');
    }
    dir = parent;
  }
}();

Future<String> _read(String path) =>
    File('${_historia.path}/$path').readAsString();

Object? _json(String path) =>
    jsonDecode(File('${_historia.path}/$path').readAsStringSync());

List<String> _ids(String dir) => [
  for (final f in Directory(
    '${_historia.path}/$dir',
  ).listSync()..sort((a, b) => a.path.compareTo(b.path)))
    if (f is File && f.path.endsWith('.json'))
      f.uri.pathSegments.last.replaceAll(RegExp(r'\.json$'), ''),
];

/// The clip ids a story file names: the keys of `clips`, `leer`, the values of `names`, `bien`, and the plain
/// (no `$` placeholder) ids its beats say: a string in `lead`, `line`, `say`, `right`, `wrong`, `then`, `else`,
/// `after` or `before`, a bare string in a beat list, and the arrays an `elige` beat keeps under its option names.
/// An id with a `$` is made when the story runs, so it is not here.
Set<String> _namedClips(Map<String, dynamic> story) {
  final out = <String>{};
  out.addAll((story['clips'] as Map?)?.keys.cast<String>() ?? const []);
  for (final id in [
    ...((story['leer'] as List?) ?? const []),
    ...((story['names'] as Map?)?.values ?? const []),
    story['bien'],
  ]) {
    _addPlain(out, id);
  }
  for (final key in ['beats', 'final']) {
    final l = story[key];
    if (l is List) _sequence(out, l);
  }
  return out;
}

const _say = [
  'lead',
  'line',
  'say',
  'right',
  'wrong',
  'then',
  'else',
  'after',
  'before',
];

void _addPlain(Set<String> out, Object? v) {
  if (v is String && !v.contains(r'$')) out.add(v);
}

void _sequence(Set<String> out, List l) {
  for (final x in l) {
    _addPlain(out, x);
    if (x is Map) _beat(out, x);
  }
}

void _beat(Set<String> out, Map b) {
  for (final k in _say) {
    final v = b[k];
    if (v is String && (k == 'line' || k == 'say')) _addPlain(out, v);
    if (v is List) _sequence(out, v);
  }
  if (b['elige'] != null) {
    for (final e in b.entries) {
      if (e.value is List && !_say.contains(e.key) && e.key != 'options') {
        _sequence(out, e.value as List);
      }
    }
  }
}

void main() {
  late ContentCatalog catalog;
  late OldAnswers old;
  late Map<String, dynamic> oldCurso;
  final storyFiles = _ids('cuentos');
  final bookFiles = _ids('libros');

  setUpAll(() async {
    final expected = [
      'test/fixture/real_expected.json',
      'packages/core/coqui_content/test/fixture/real_expected.json',
      'coqui/packages/core/coqui_content/test/fixture/real_expected.json',
    ].map(File.new).firstWhere((f) => f.existsSync());
    final j = jsonDecode(expected.readAsStringSync()) as Map<String, dynamic>;
    old = OldAnswers(j);
    oldCurso = Map<String, dynamic>.from(j['curso'] as Map);
    catalog = ContentCatalog(_read);
    await catalog.load();
  });

  test('the files are there: 62 stories and review sets, 43 books', () {
    expect(storyFiles, hasLength(62));
    expect(bookFiles, hasLength(43));
  });

  group('the course', () {
    test('places and meta are curso.js, as the old code has it', () {
      expect([
        for (final p in catalog.places) p.toJson(),
      ], sameJson(oldCurso['lugares']));
      final cuentos = oldCurso['cuentos'] as Map<String, dynamic>;
      expect(cuentos, hasLength(51));
      for (final e in cuentos.entries) {
        expect(catalog.meta(e.key)!.toJson(), sameJson(e.value), reason: e.key);
      }
      expect(catalog.meta('no-such-story'), isNull);
    });

    test(
      'every story file is named by the course: 51 stories and 11 review sets',
      () {
        final named = {
          ...(oldCurso['cuentos'] as Map).keys.cast<String>(),
          ...(oldCurso['cual'] as List).cast<String>(),
        };
        expect(named, storyFiles.toSet());
      },
    );

    test('level items, calls and fixed lines are the data files', () {
      expect([
        for (final q in catalog.levelItems) q.toJson(),
      ], sameJson(_json('datos/nivel.json')));
      expect(catalog.levelItems, hasLength(48));
      final llamadas = _json('datos/llamadas.json') as Map<String, dynamic>;
      for (final e in llamadas.entries) {
        expect(catalog.callFor(e.key)!.toJson(), sameJson(e.value));
      }
      for (final p in catalog.places) {
        expect(catalog.callFor(p.id) != null, llamadas.containsKey(p.id));
      }
      final fijos = _json('datos/fijos.json') as Map<String, dynamic>;
      for (final e in (fijos['clips'] as Map).entries) {
        expect(catalog.fixedClip(e.key as String), e.value);
      }
      expect(catalog.goodbyeWords, fijos['despedidas']);
      expect(() => catalog.fixedClip('no_such_role'), throwsArgumentError);
    });
  });

  group('stories and books load', () {
    test('all 62 story files load, and each is the file', () async {
      for (final id in storyFiles) {
        final s = await catalog.story(id);
        expect(s['id'], id);
        expect(s, sameJson(_json('cuentos/$id.json')), reason: id);
      }
    });

    test('all 43 books load, and each is the file; a story without a book gives null', () async {
      for (final id in bookFiles) {
        final b = await catalog.book(id);
        expect(b, isNotNull, reason: id);
        expect(b!.id, id);
        expect(b.pages, isNotEmpty, reason: id);
        expect(b.toJson(), sameJson(_json('libros/$id.json')), reason: id);
        // every line on its pages is a line of its story, with marks
        await catalog.story(id);
        for (final page in b.pages) {
          for (final clip in page.clips) {
            final c = catalog.clip(clip);
            expect(c, isNotNull, reason: '$id: $clip');
            expect(c!.text, isNotEmpty, reason: '$id: $clip');
          }
        }
      }
      final without = [
        for (final c in (oldCurso['cuentos'] as Map).keys)
          if (!bookFiles.contains(c)) c as String,
      ];
      expect(
        without,
        hasLength(8),
        reason: 'the routines (Haz esto) have no book',
      );
      for (final id in without) {
        expect(await catalog.book(id), isNull, reason: id);
      }
      // the routines are what the places list under `haz`
      expect(without.toSet(), {for (final p in catalog.places) ...p.routines});
    });
  });

  group('clips', () {
    test('every clip id a story file names has marks and a ClipInfo', () async {
      final named = <String, Set<String>>{};
      for (final id in storyFiles) {
        named[id] = _namedClips(await catalog.story(id));
      }
      final all = {for (final s in named.values) ...s};
      expect(all.length, greaterThan(1500));
      final bad = <String>[];
      for (final e in named.entries) {
        for (final id in e.value) {
          final c = catalog.clip(id);
          if (c == null ||
              c.who.isEmpty ||
              c.text.isEmpty ||
              c.endMs <= c.startMs) {
            bad.add('${e.key}: $id');
          }
        }
      }
      expect(bad, isEmpty);
    });

    test('every clip of ready.json has a ClipInfo: the line a story gives, its marks, its url', () async {
      final ready = _json('audio/ready.json') as Map<String, dynamic>;
      final marks = _json('audio/marcas.json') as Map<String, dynamic>;
      final ids = (ready['clips'] as List).cast<String>();
      expect(ids, hasLength(1582));
      expect(marks.keys.toSet(), ids.toSet());
      // the lines of every story file; one id must have one line (who, text, habla) wherever it is
      final lines = <String, Map<String, dynamic>>{};
      for (final sid in storyFiles) {
        final clips = (_json('cuentos/$sid.json') as Map)['clips'] as Map;
        for (final e in clips.entries) {
          final l = Map<String, dynamic>.from(e.value as Map);
          expect(
            lines.putIfAbsent(e.key as String, () => l),
            sameJson(l),
            reason: '${e.key} in $sid',
          );
        }
      }
      for (final id in storyFiles) {
        await catalog.story(id);
      }
      for (final id in ids) {
        final c = catalog.clip(id);
        final m = marks[id] as List;
        final l = lines[id]!;
        expect(c, isNotNull, reason: id);
        expect(
          [c!.who, c.text, c.habla],
          [l['who'], l['text'], l['habla']],
          reason: id,
        );
        expect([c.startMs, c.endMs], [m[0], m[1]], reason: id);
        expect(c.url, 'audio/$id.mp3?v=${ready['v']}', reason: id);
      }
      for (final e in old.urls.entries) {
        expect(catalog.clip(e.key)!.url, e.value);
      }
      expect(old.urls, isNotEmpty);
    });

    test('a clip that is on disk but not in ready.json has no ClipInfo', () {
      final ready = ((_json('audio/ready.json') as Map)['clips'] as List)
          .toSet();
      final onDisk = [
        for (final f in Directory('${_historia.path}/audio').listSync())
          if (f is File && f.path.endsWith('.mp3'))
            f.uri.pathSegments.last.replaceAll(RegExp(r'\.mp3$'), ''),
      ];
      final loose = onDisk.where((id) => !ready.contains(id)).toList();
      for (final id in loose) {
        expect(catalog.clip(id), isNull, reason: id);
      }
    });

    test('a line the old code writes in code is there right after load, as fijos.json has it', () async {
      final lineas = Map<String, dynamic>.from(
        (_json('datos/fijos.json') as Map)['lineas'] as Map,
      );
      expect(lineas, isNotEmpty);
      final fresh = ContentCatalog(_read);
      await fresh.load(); // no story read
      expect(lineas.keys, contains(fresh.fixedClip('story_your_turn')));
      for (final e in lineas.entries) {
        final c = fresh.clip(e.key);
        final line = e.value as Map;
        expect(c, isNotNull, reason: e.key);
        expect([c!.who, c.text], [line['who'], line['text']], reason: e.key);
        expect(c.endMs, greaterThan(c.startMs), reason: e.key);
      }
      expect(fresh.clip(fresh.fixedClip('story_your_turn'))!.who, 'narr');
      // a story that has the same id says the same, and is the one that wins once it is read
      for (final sid in storyFiles) {
        final clips = (_json('cuentos/$sid.json') as Map)['clips'] as Map;
        for (final e in lineas.entries) {
          final own = clips[e.key];
          if (own == null) continue;
          await fresh.story(sid);
          final c = fresh.clip(e.key)!;
          expect(
            [c.who, c.text],
            [(own as Map)['who'], own['text']],
            reason: sid,
          );
        }
      }
    });

    test('the fixed lines have marks, except a prefix', () {
      final roles = (_json('datos/fijos.json') as Map)['clips'] as Map;
      for (final e in roles.entries) {
        final id = catalog.fixedClip(e.key as String);
        if ((e.key as String).endsWith('_prefix')) {
          expect(catalog.clip(id), isNull, reason: id);
          expect(
            (_json('audio/ready.json') as Map)['clips'].any(
              (c) => (c as String).startsWith(id),
            ),
            isTrue,
            reason: id,
          );
        } else {
          expect(catalog.clip(id), isNotNull, reason: '${e.key}: $id');
        }
      }
    });
  });

  group('pairs', () {
    test('the pairs are CU.items of the old code, 128 of them', () {
      expect(catalog.pairs, hasLength(128));
      expect([
        for (final p in catalog.pairs) {...p.toJson(), 'esc': p.scene},
      ], sameJson(old.pairs));
    });

    test('pairFor finds a pair for each of the 128 words pares().m has, the pair of that word', () {
      expect(old.words, hasLength(128));
      for (final w in old.words) {
        final p = catalog.pairFor(w);
        expect(p, isNotNull, reason: w);
        expect(p!.word, w);
        expect({
          ...p.toJson(),
          'esc': p.scene,
        }, sameJson(old.pairs.firstWhere((x) => x['w'] == w)));
      }
    });

    test('pairFor also finds each word by its normalised form', () {
      for (final w in old.words) {
        final p = catalog.pairFor(normalize(w).trim().toUpperCase());
        expect(p, isNotNull, reason: w);
        expect(normalize(p!.word), normalize(w));
      }
    });
  });

  group('linesWith (app.html, oidoEn)', () {
    test('ten words, picked by a rule, give the lines oidoEn gives: every story played, and only place 1', () async {
      // The rule: the pair words in the order of the review sets (which is the order of the places), every
      // 12.8th: word number floor(i * 128 / 10) for i = 0..9. So the ten are spread over the places.
      final pairs = catalog.pairs;
      final ten = [
        for (var i = 0; i < 10; i++) pairs[i * pairs.length ~/ 10].word,
      ];
      expect(ten.toSet(), hasLength(10));
      expect(
        {for (final w in ten) pairs.firstWhere((p) => p.word == w).scene}
            .length,
        greaterThanOrEqualTo(8),
      );
      var differ = 0;
      for (final w in ten) {
        final all = await catalog.linesWith(w, old.allPlayed);
        final one = await catalog.linesWith(w, old.place1Played);
        expectSameLines(
          all,
          old.lines(w, allStories: true),
          old.titles,
          '$w, all stories played',
        );
        expectSameLines(
          one,
          old.lines(w, allStories: false),
          old.titles,
          '$w, place 1 played',
        );
        expect(all, isNotEmpty, reason: w);
        if (all.map((l) => l.clipId).join(',') !=
            one.map((l) => l.clipId).join(',')) {
          differ++;
        }
      }
      expect(differ, greaterThan(0), reason: 'the two cases are not the same');
    });

    test('all 156 words the store can hold (the 128 and the focus and back_again words), both cases', () async {
      expect(old.wordList, hasLength(156));
      var withLines = 0;
      for (final w in old.wordList) {
        final all = await catalog.linesWith(w, old.allPlayed);
        final one = await catalog.linesWith(w, old.place1Played);
        expectSameLines(
          all,
          old.lines(w, allStories: true),
          old.titles,
          '$w, all',
        );
        expectSameLines(
          one,
          old.lines(w, allStories: false),
          old.titles,
          '$w, place 1',
        );
        if (all.isNotEmpty) withLines++;
      }
      expect(withLines, 156);
    });

    test('the played stories are given in any order, as a Set or a List, and the answer is the same', () async {
      for (final w in old.wordList.take(20)) {
        final want = old.lines(w, allStories: true);
        expectSameLines(
          await catalog.linesWith(w, old.allPlayed.reversed),
          want,
          old.titles,
          w,
        );
        expectSameLines(
          await catalog.linesWith(w, old.allPlayed.toSet()),
          want,
          old.titles,
          w,
        );
      }
    });
  });
}
