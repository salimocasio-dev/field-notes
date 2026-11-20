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

/// The one file of `cuentos/` the course does not name: `palabras-solas.json`, each tracked word said alone for the word
/// tiles of Repaso (made by tool/make_palabras_solas.py). It is not a story and not a review set; its `tipo` is `palabras`.
/// Its clips are recorded by the audio job after the file is committed, so the tree is in one of two states (see
/// [_solasState]).
const _solasId = 'palabras-solas';
const _solasClipCount = 133;

/// The keys of `clips` of a story file: every clip id it holds.
Set<String> _clipKeys(String id) =>
    ((_json('cuentos/$id.json') as Map)['clips'] as Map).keys
        .cast<String>()
        .toSet();

enum _Solas {
  /// None of the clips of palabras-solas has a recording or marks.
  notRecorded,

  /// Every one has both.
  recorded,
}

/// The state of the clips of palabras-solas: [_Solas.notRecorded] when none of them is in `audio/ready.json`, none has
/// marks in `audio/marcas.json` and none has an mp3 file in `audio/`; [_Solas.recorded] when every one has all three.
/// Anything between is a half-done recording, and fails here, naming what is missing.
_Solas _solasState() {
  final ids = _clipKeys(_solasId);
  final ready = ((_json('audio/ready.json') as Map)['clips'] as List)
      .cast<String>()
      .toSet();
  final marks = (_json('audio/marcas.json') as Map).keys.cast<String>().toSet();
  final inReady = ids.intersection(ready);
  final withMarks = ids.intersection(marks);
  final withMp3 = {
    for (final id in ids)
      if (File('${_historia.path}/audio/$id.mp3').existsSync()) id,
  };
  final parts = {
    'in ready.json': inReady,
    'with marks in marcas.json': withMarks,
    'with an mp3 file': withMp3,
  };
  if (parts.values.every((s) => s.isEmpty)) return _Solas.notRecorded;
  if (parts.values.every((s) => s.length == ids.length)) return _Solas.recorded;
  return fail(
    'the ${ids.length} clips of $_solasId are neither all recorded nor none: '
    '${parts.entries.map((e) => '${e.value.length} ${e.key}').join(', ')}',
  );
}

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
  // the files of cuentos/ the course names: its stories, picture stories and routines, and its review sets (`cual`)
  late Set<String> courseFiles;
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
    courseFiles = {
      ...(oldCurso['cuentos'] as Map).keys.cast<String>(),
      ...(oldCurso['cual'] as List).cast<String>(),
    };
    catalog = ContentCatalog(_read);
    await catalog.load();
  });

  test('the files are there: 62 stories and review sets the course names, the word list palabras-solas, 43 books', () {
    expect(courseFiles, hasLength(62));
    expect(storyFiles, hasLength(63));
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

    test('every file of cuentos/ is named by the course (51 stories and 11 review sets), except palabras-solas, a word list', () {
      expect((oldCurso['cuentos'] as Map).keys, hasLength(51));
      expect(oldCurso['cual'] as List, hasLength(11));
      expect(courseFiles, hasLength(62));
      final files = storyFiles.toSet();
      // every file the course names is there, and the only other one is palabras-solas: any other file fails
      expect(courseFiles.difference(files), isEmpty);
      expect(files.difference(courseFiles), {_solasId});
      final solas = _json('cuentos/$_solasId.json') as Map;
      expect(solas['id'], _solasId);
      expect(solas['tipo'], 'palabras');
    });

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

  test('datos/repaso.json reads: 156 words; every clip it names is a recorded line with marks, every story a story of '
      'the course, every picture a book picture on disk', () {
    final r = catalog.repaso;
    expect(r, isNotNull);
    expect(r!.words, hasLength(156));
    final stories = (oldCurso['cuentos'] as Map).keys.toSet();
    final clips = <String>{
      for (final s in r.sentences) s.clip,
      for (final w in r.words) ...[
        for (final p in w.pairLines) p.clip,
        for (final d in w.say) ...[d.clip, d.before],
        ?w.solo,
      ],
    };
    for (final c in clips) {
      expect(catalog.clip(c), isNotNull, reason: c);
    }
    final pictures = <String>{
      for (final s in r.sentences) ?s.picture,
      for (final w in r.words) ...[
        for (final d in w.where) ...d.others,
        for (final d in w.say) ?d.picture,
      ],
    };
    expect(pictures, isNotEmpty);
    for (final p in pictures) {
      expect(
        File('${_historia.path}/libros/$p').existsSync(),
        isTrue,
        reason: p,
      );
    }
    for (final s in r.sentences) {
      expect(stories, contains(s.story), reason: s.clip);
    }
    for (final w in r.words) {
      for (final p in w.pairLines.skip(1)) {
        expect(stories, contains(p.story), reason: '${w.word} ${p.clip}');
      }
      expect(w.pairLines.isEmpty || w.pairLines.first.story == null, isTrue);
      // a word with a pair has the pair's own sentence first
      final pair = catalog.pairFor(w.word);
      if (w.pairLines.isNotEmpty) expect(w.pairLines.first.clip, pair!.say);
      for (final d in w.where) {
        expect(r.sentences[d.sentence].picture, isNotNull, reason: w.word);
      }
    }
  });

  group('stories and books load', () {
    test('every file of cuentos/ loads (the 62 the course names and palabras-solas), and each is the file', () async {
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
    test(
      'every clip id a course file names has marks and a ClipInfo',
      () async {
        final named = <String, Set<String>>{};
        for (final id in storyFiles.where(courseFiles.contains)) {
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
      },
    );

    test('every clip of ready.json has a ClipInfo: the line a story gives, its marks, its url', () async {
      final ready = _json('audio/ready.json') as Map<String, dynamic>;
      final marks = _json('audio/marcas.json') as Map<String, dynamic>;
      final ids = (ready['clips'] as List).cast<String>();
      // the clips of the files the course names (1582), and the 133 of palabras-solas only once they are recorded
      final course = {for (final id in courseFiles) ..._clipKeys(id)};
      expect(course, hasLength(1582));
      final expected = {
        ...course,
        if (_solasState() == _Solas.recorded) ..._clipKeys(_solasId),
      };
      expect(ids, hasLength(expected.length));
      expect(ids.toSet(), expected);
      expect(marks.keys.toSet(), expected);
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
      // The fixture holds each url with the `v` ready.json had when the fixture was made. The audio job gives ready.json a
      // new `v` whenever it records a clip (voz.py), so what the old code says here is the address before `?v=`; the `v`
      // is ready.json's own, as checked for every clip above.
      for (final e in old.urls.entries) {
        expect(
          catalog.clip(e.key)!.url,
          e.value.replaceFirst(RegExp(r'\?v=[^&]*$'), '?v=${ready['v']}'),
        );
      }
      expect(old.urls, isNotEmpty);
    });

    test('the clips of palabras-solas: all 133 recorded, or none yet', () async {
      final solas = _clipKeys(_solasId);
      expect(solas, hasLength(_solasClipCount));
      expect(solas.every((id) => id.startsWith('w_')), isTrue);
      // no other file has one of them
      expect(
        {for (final id in courseFiles) ..._clipKeys(id)}.intersection(solas),
        isEmpty,
      );
      await catalog.story(_solasId);
      final state = _solasState();
      // ignore: avoid_print
      print(
        state == _Solas.recorded
            ? 'palabras-solas: RECORDED: its ${solas.length} clips are in ready.json, in marcas.json and on disk'
            : 'palabras-solas: NOT RECORDED YET: none of its ${solas.length} clips is in ready.json, marcas.json or audio/',
      );
      for (final id in solas) {
        final c = catalog.clip(id);
        if (state == _Solas.notRecorded) {
          expect(c, isNull, reason: id);
        } else {
          expect(c, isNotNull, reason: id);
          expect(c!.who, isNotEmpty, reason: id);
          expect(c.text, isNotEmpty, reason: id);
          expect(c.endMs, greaterThan(c.startMs), reason: id);
        }
      }
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
