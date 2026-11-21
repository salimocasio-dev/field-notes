// The catalog over the real files under historia/ (vm only: chrome cannot read files). The answers the old code gives
// are in fixture/real_expected.json, made by tool/make_expected.mjs in node: pares() and oidoEn() from app.html and
// cualCarga() from cual.js, run over these same files.
//
// A file of historia/cuentos/ is one of three kinds:
//   - named by the course: a story, picture story or routine of a place, or a review set (57 + 12 = 69 today);
//   - the word list `palabras-solas` (`"tipo": "palabras"`);
//   - STAGED: any other file. Another session pushes the files of a new story into cuentos/ and the audio job records
//     them; only later does datos/curso.json list the story (once its book and pictures exist). A staged file must parse,
//     have an `id` equal to its file name and a `clips` object; this test prints the staged files and does not fail on
//     their number. The app must not see them (see 'staged files are invisible to the app').
//
// A file of historia/libros/ is the book of the story of the same name (`libros/<id>.json` is the book of the story <id>):
//   - a COURSE book when the course names that story (46 today, asserted; the routines have none): the app asks for it, and
//     it loads;
//   - a STAGED book when <id> is a staged file of cuentos/: the pictures of a staged story may be in libros/img/ before the
//     course names it. It must parse and every picture it names must be under libros/img/; this test prints the staged books
//     and their page counts. The app must not ask for it either;
//   - any other book file fails.
// See coqui/AGENTS.md, "Stories staged by another session".
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
const _solasClipCount = 143;

/// The keys of `clips` of a story file: every clip id it holds.
Set<String> _clipKeys(String id) =>
    ((_json('cuentos/$id.json') as Map)['clips'] as Map).keys
        .cast<String>()
        .toSet();

/// A staged file as JSON: null when it does not parse.
Object? _stagedJson(String id) {
  try {
    return jsonDecode(
      File('${_historia.path}/cuentos/$id.json').readAsStringSync(),
    );
  } on FormatException {
    return null;
  }
}

/// What is wrong with a staged file, as lines (none: it is as a staged file must be): it parses, it is a JSON object, its
/// `id` is its file name, it has a `clips` object, and every clip in it is an object.
List<String> _stagedProblems(String id) {
  final j = _stagedJson(id);
  if (j == null) return ['$id.json does not parse (or is the JSON null)'];
  if (j is! Map) return ['$id.json is not a JSON object'];
  final clips = j['clips'];
  return [
    if (j['id'] != id) '$id.json has the id ${jsonEncode(j['id'])}, not "$id"',
    if (clips is! Map)
      '$id.json has no `clips` object'
    else
      for (final e in clips.entries)
        if (e.value is! Map) '$id.json: the clip ${e.key} is not an object',
  ];
}

/// The clips of a staged file (id -> the clip's object), as far as they can be read: none when the file does not parse or
/// has no `clips` object, and the clips that are not objects left out (the test of the staged files says what is wrong).
Map<String, Map<String, dynamic>> _stagedClips(String id) {
  final j = _stagedJson(id);
  final clips = j is Map ? j['clips'] : null;
  if (clips is! Map) return const {};
  return {
    for (final e in clips.entries)
      if (e.value is Map)
        e.key as String: Map<String, dynamic>.from(e.value as Map),
  };
}

/// What a staged book (`libros/<id>.json`, the book of a staged story) is, as far as it can be read: how many pages it has, the
/// pictures its pages name (as written, `img/<file>`), and what is wrong with it, as lines (none: it is as a staged book must
/// be): it parses, it is a JSON object with a `pages` list, every page is an object whose `img` is `img/<file>`, and that
/// picture is a file of historia/libros/img/.
({int pages, List<String> pictures, List<String> problems}) _stagedBook(
  String id,
) {
  final Object? j;
  try {
    j = jsonDecode(
      File('${_historia.path}/libros/$id.json').readAsStringSync(),
    );
  } on FormatException {
    return (
      pages: 0,
      pictures: const [],
      problems: ['libros/$id.json does not parse'],
    );
  }
  final pages = j is Map ? j['pages'] : null;
  if (pages is! List) {
    return (
      pages: 0,
      pictures: const [],
      problems: ['libros/$id.json is not a JSON object with a `pages` list'],
    );
  }
  final pictures = <String>[];
  final problems = <String>[];
  for (var n = 1; n <= pages.length; n++) {
    final page = pages[n - 1];
    final img = page is Map ? page['img'] : null;
    if (img is! String) {
      problems.add('libros/$id.json: page $n names no picture (`img`)');
      continue;
    }
    pictures.add(img);
    if (!RegExp(r'^img/[^/]+$').hasMatch(img)) {
      problems.add('libros/$id.json: page $n names $img, not a file of img/');
    } else if (!File('${_historia.path}/libros/$img').existsSync()) {
      problems.add('libros/$id.json: page $n names $img, which is not there');
    }
  }
  return (pages: pages.length, pictures: pictures, problems: problems);
}

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
  // every file of cuentos/; of them the ones the app reads (the course's and the word list), and the staged ones (the rest)
  final folderFiles = _ids('cuentos');
  late List<String> appFiles;
  late List<String> staged;
  // every file of libros/, the book of the story of the same name; of them the course's (the story is named by the course),
  // the staged ones (the story is a staged file of cuentos/) and any other (which fails)
  final bookFiles = _ids('libros');
  late List<String> courseBooks;
  late List<String> stagedBooks;
  late List<String> strayBooks;

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
    appFiles = [
      for (final id in folderFiles)
        if (courseFiles.contains(id) || id == _solasId) id,
    ];
    staged = [
      for (final id in folderFiles)
        if (!courseFiles.contains(id) && id != _solasId) id,
    ];
    courseBooks = [
      for (final id in bookFiles)
        if (courseFiles.contains(id)) id,
    ];
    stagedBooks = [
      for (final id in bookFiles)
        if (staged.contains(id)) id,
    ];
    strayBooks = [
      for (final id in bookFiles)
        if (!courseFiles.contains(id) && !staged.contains(id)) id,
    ];
    catalog = ContentCatalog(_read);
    await catalog.load();
  });

  test('the files are there: 69 stories and review sets the course names, the word list palabras-solas, 46 books of the course', () {
    expect(courseFiles, hasLength(69));
    expect(
      courseFiles.difference(folderFiles.toSet()),
      isEmpty,
      reason: 'a file the course names is not in cuentos/',
    );
    expect(folderFiles, contains(_solasId));
    expect(appFiles, hasLength(70));
    expect(courseBooks, hasLength(46));
  });

  group('the course', () {
    test('places and meta are curso.js, as the old code has it', () {
      expect([
        for (final p in catalog.places) p.toJson(),
      ], sameJson(oldCurso['lugares']));
      final cuentos = oldCurso['cuentos'] as Map<String, dynamic>;
      expect(cuentos, hasLength(57));
      for (final e in cuentos.entries) {
        expect(catalog.meta(e.key)!.toJson(), sameJson(e.value), reason: e.key);
      }
      expect(catalog.meta('no-such-story'), isNull);
    });

    test('every file of cuentos/ is named by the course (57 stories and 12 review sets), the word list palabras-solas, or staged', () {
      expect((oldCurso['cuentos'] as Map).keys, hasLength(57));
      expect(oldCurso['cual'] as List, hasLength(12));
      expect(courseFiles, hasLength(69));
      // datos/curso.json, which the catalog reads, names the same files
      final curso = _json('datos/curso.json') as Map;
      expect({
        ...(curso['cuentos'] as Map).keys.cast<String>(),
        ...(curso['cual'] as List).cast<String>(),
      }, courseFiles);
      // every file the course names is there
      expect(courseFiles.difference(folderFiles.toSet()), isEmpty);
      // the word list
      final solas = _json('cuentos/$_solasId.json') as Map;
      expect(solas['id'], _solasId);
      expect(solas['tipo'], 'palabras');
      // any other file is staged: it must parse, have an `id` equal to its file name and a `clips` object. How many there
      // are is not a failure; they are listed.
      expect(staged.toSet().intersection(courseFiles), isEmpty);
      expect(staged, isNot(contains(_solasId)));
      expect(
        folderFiles.length,
        courseFiles.length + 1 + staged.length,
        reason: 'every file is of one of the three kinds',
      );
      final ready = ((_json('audio/ready.json') as Map)['clips'] as List)
          .cast<String>()
          .toSet();
      final lines = <String>[];
      for (final id in staged) {
        final ids = _stagedClips(id).keys.toList();
        final recorded = ids.where(ready.contains).length;
        lines.add(
          '  $id: ${ids.length} clips, $recorded recorded, ${ids.length - recorded} not',
        );
      }
      // ignore: avoid_print
      print(
        'staged files (${staged.length}): ${staged.isEmpty ? 'none' : staged.join(', ')}'
        '${lines.isEmpty ? '' : '\n${lines.join('\n')}'}',
      );
      expect([for (final id in staged) ..._stagedProblems(id)], isEmpty);
    });

    test('level items, calls and fixed lines are the data files', () {
      expect([
        for (final q in catalog.levelItems) q.toJson(),
      ], sameJson(_json('datos/nivel.json')));
      expect(catalog.levelItems, hasLength(52));
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

  test('datos/repaso.json reads: 167 words; every clip it names is a recorded line with marks, every story a story of '
      'the course, every picture a book picture on disk', () {
    final r = catalog.repaso;
    expect(r, isNotNull);
    expect(r!.words, hasLength(167));
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
    test('every file of cuentos/ the app reads loads (the 69 the course names and palabras-solas), and each is the file', () async {
      for (final id in appFiles) {
        final s = await catalog.story(id);
        expect(s['id'], id);
        expect(s, sameJson(_json('cuentos/$id.json')), reason: id);
      }
    });

    test('all 46 books of the course load, and each is the file; a story without a book gives null', () async {
      expect(courseBooks, hasLength(46));
      for (final id in courseBooks) {
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
          if (!courseBooks.contains(c)) c as String,
      ];
      expect(
        without,
        hasLength(11),
        reason: 'the routines (Haz esto) have no book',
      );
      for (final id in without) {
        expect(await catalog.book(id), isNull, reason: id);
      }
      // the routines are what the places list under `haz`
      expect(without.toSet(), {for (final p in catalog.places) ...p.routines});
    });

    test('every file of libros/ is the book of a story the course names (46) or of a staged story file; a staged book parses and every picture it names is on disk', () {
      expect(
        strayBooks,
        isEmpty,
        reason: 'a book file whose story is neither named by the course nor a staged file of cuentos/',
      );
      expect(courseBooks, hasLength(46));
      expect(
        bookFiles.length,
        courseBooks.length + stagedBooks.length,
        reason: 'every book file is of one of the two kinds',
      );
      expect(courseBooks.toSet().intersection(stagedBooks.toSet()), isEmpty);
      expect(stagedBooks.toSet().difference(staged.toSet()), isEmpty);
      // the staged books are listed with their page counts and their pictures
      final books = {for (final id in stagedBooks) id: _stagedBook(id)};
      final pictures = {for (final b in books.values) ...b.pictures};
      // ignore: avoid_print
      print(
        'staged books (${stagedBooks.length}): ${stagedBooks.isEmpty ? 'none' : stagedBooks.join(', ')}'
        '${books.isEmpty ? '' : '\n${[for (final e in books.entries) '  ${e.key}: ${e.value.pages} pages, ${e.value.pictures.length} pictures'].join('\n')}'}'
        '\nstaged pictures: ${pictures.length} (the ${courseBooks.length} books of the course are counted apart)',
      );
      expect([for (final b in books.values) ...b.problems], isEmpty);
    });
  });

  group('clips', () {
    test(
      'every clip id a course file names has marks and a ClipInfo',
      () async {
        final named = <String, Set<String>>{};
        for (final id in appFiles.where(courseFiles.contains)) {
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

    test('every clip of ready.json belongs to a file of cuentos/ and has marks and an mp3; the 1722 clips of the course are all recorded, each with its ClipInfo', () async {
      final ready = _json('audio/ready.json') as Map<String, dynamic>;
      final marks = _json('audio/marcas.json') as Map<String, dynamic>;
      final ids = (ready['clips'] as List).cast<String>();
      final inReady = ids.toSet();
      expect(
        inReady,
        hasLength(ids.length),
        reason: 'a clip twice in ready.json',
      );
      bool hasMp3(String id) =>
          File('${_historia.path}/audio/$id.mp3').existsSync();
      // the clips of the files the course names: 1722, each with a recording, marks and an mp3
      final course = {for (final id in courseFiles) ..._clipKeys(id)};
      expect(course, hasLength(1722));
      expect(
        [
          for (final id in course)
            if (!inReady.contains(id) || !marks.containsKey(id) || !hasMp3(id))
              id,
        ],
        isEmpty,
        reason: 'a clip of a file the course names without a recording, marks or an mp3',
      );
      // the 143 of palabras-solas: all recorded or none, as the test below says; a staged file's: each on its own, any state.
      // Every clip of ready.json belongs to some file of the folder, has marks and an mp3; every key of marcas.json is a
      // clip of ready.json.
      final inFolder = {
        ...course,
        ..._clipKeys(_solasId),
        for (final id in staged) ..._stagedClips(id).keys,
      };
      expect(
        inReady.difference(inFolder),
        isEmpty,
        reason: 'in ready.json, but in no file of cuentos/',
      );
      expect(
        [
          for (final id in inReady)
            if (!marks.containsKey(id)) id,
        ],
        isEmpty,
        reason: 'in ready.json without marks in marcas.json',
      );
      expect(
        [
          for (final id in inReady)
            if (!hasMp3(id)) id,
        ],
        isEmpty,
        reason: 'in ready.json without an mp3 file in audio/',
      );
      expect(
        marks.keys.toSet().difference(inReady),
        isEmpty,
        reason: 'in marcas.json, but not a clip of ready.json',
      );
      // the lines of the files the app reads (the course's and the word list); one id must have one line (who, text, habla)
      // wherever it is. A speaking turn (`tu_turno`, page 16) is the story's mark on its clip, not the line: A comer's stories
      // mark clips that earlier stories say without one (cq_gracias_abuela)
      final lines = <String, Map<String, dynamic>>{};
      for (final sid in appFiles) {
        final clips = (_json('cuentos/$sid.json') as Map)['clips'] as Map;
        for (final e in clips.entries) {
          final l = Map<String, dynamic>.from(e.value as Map)
            ..remove('tu_turno');
          expect(
            lines.putIfAbsent(e.key as String, () => l),
            sameJson(l),
            reason: '${e.key} in $sid',
          );
        }
      }
      for (final id in appFiles) {
        await catalog.story(id);
      }
      for (final id in ids) {
        final c = catalog.clip(id);
        final m = marks[id] as List;
        expect(c, isNotNull, reason: id);
        expect([c!.startMs, c.endMs], [m[0], m[1]], reason: id);
        expect(c.url, 'audio/$id.mp3?v=${ready['v']}', reason: id);
        // a clip only a staged file has: no story the app reads gives it a line
        final l = lines[id];
        if (l != null) {
          expect(
            [c.who, c.text, c.habla],
            [l['who'], l['text'], l['habla']],
            reason: id,
          );
        }
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

    test('a clip id two files of cuentos/ share has one text and one voice in both (the audio job makes one recording for it)', () {
      // voz.py: one mp3 per clip id, in the voice of `who` (narr when it has none) and the clip's `text`; two different texts
      // under one id stop the job. `habla`, `tu_turno` and the like are not heard, so they may differ.
      final first = <String, ({String file, Object? text, Object? who})>{};
      final clashes = <String>[];
      var shared = 0;
      var sharedWithStaged = 0;
      for (final id in folderFiles) {
        final clips = staged.contains(id)
            ? _stagedClips(id)
            : {
                for (final e
                    in ((_json('cuentos/$id.json') as Map)['clips'] as Map)
                        .entries)
                  e.key as String: Map<String, dynamic>.from(e.value as Map),
              };
        for (final e in clips.entries) {
          final here = (
            file: id,
            text: e.value['text'],
            who: e.value['who'] ?? 'narr',
          );
          final there = first[e.key];
          if (there == null) {
            first[e.key] = here;
            continue;
          }
          shared++;
          if (staged.contains(id) || staged.contains(there.file)) {
            sharedWithStaged++;
          }
          if (there.text != here.text || there.who != here.who) {
            clashes.add(
              '${e.key}: ${there.file} says ${jsonEncode(there.text)} by ${there.who}, $id says ${jsonEncode(here.text)} by ${here.who}',
            );
          }
        }
      }
      // ignore: avoid_print
      print(
        'a clip id found again in another file: $shared times, $sharedWithStaged of them with a staged file; clashes: ${clashes.length}',
      );
      expect(clashes, isEmpty);
    });

    test('the clips of palabras-solas: all 143 recorded, or none yet', () async {
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

    test('a word said alone (w_*) resolves from a catalog that has read no story: its address, its marks, its line', () async {
      // the tree is recorded (the 143 clips of palabras-solas are in ready.json, marcas.json and audio/)
      expect(_solasState(), _Solas.recorded);
      final fresh = ContentCatalog(_read);
      await fresh.load(); // no story read, palabras-solas least of all
      final ready = _json('audio/ready.json') as Map<String, dynamic>;
      final marks = _json('audio/marcas.json') as Map<String, dynamic>;
      final solas = _json('cuentos/$_solasId.json') as Map<String, dynamic>;
      final clips = Map<String, dynamic>.from(solas['clips'] as Map);
      expect(clips, hasLength(_solasClipCount));
      for (final e in clips.entries) {
        final c = fresh.clip(e.key);
        final m = marks[e.key] as List;
        final line = e.value as Map;
        expect(c, isNotNull, reason: e.key);
        expect(c!.url, 'audio/${e.key}.mp3?v=${ready['v']}', reason: e.key);
        expect([c.startMs, c.endMs], [m[0], m[1]], reason: e.key);
        expect(c.endMs, greaterThan(c.startMs), reason: e.key);
        expect(
          [c.who, c.text, c.habla],
          [line['who'], line['text'], null],
          reason: e.key,
        );
        expect(
          File('${_historia.path}/${c.url.split('?').first}').existsSync(),
          isTrue,
          reason: e.key,
        );
      }
      // a word's clip in the repaso data is one of them or a clip of a story, and every one has a ClipInfo
      final words = (_json('datos/repaso.json') as Map)['palabras'] as List;
      expect(words, hasLength(167));
      var alone = 0;
      for (final w in words) {
        final id = (w as Map)['solo'] as String?;
        expect(id, isNotNull, reason: '${w['w']}');
        expect(fresh.clip(id!), isNotNull, reason: id);
        if (clips.containsKey(id)) alone++;
      }
      expect(alone, 143);
      // it is not a story and not a review set
      expect(fresh.meta(_solasId), isNull);
      expect(fresh.pairs, hasLength(140));
      expect([
        for (final p in fresh.places) ...[
          ...p.stories,
          ...p.routines,
          ...p.pictureStories,
        ],
      ], isNot(contains(_solasId)));
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
      for (final sid in appFiles) {
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
    test('the pairs are CU.items of the old code, 140 of them', () {
      expect(catalog.pairs, hasLength(140));
      expect([
        for (final p in catalog.pairs) {...p.toJson(), 'esc': p.scene},
      ], sameJson(old.pairs));
    });

    test('pairFor finds a pair for each of the 140 words pares().m has, the pair of that word', () {
      expect(old.words, hasLength(140));
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
      // 14th: word number floor(i * 140 / 10) for i = 0..9. So the ten are spread over the places.
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

    test('all 167 words the store can hold (the 140 and the focus and back_again words), both cases', () async {
      expect(old.wordList, hasLength(167));
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
      expect(withLines, 167);
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

  group('staged files are invisible to the app', () {
    // Everything the catalog loads, lists or counts, as plain data
    Future<Map<String, Object?>> snapshot(ContentCatalog c) async {
      final r = c.repaso!;
      final played = [for (final p in c.places) ...p.stories];
      return {
        'places': [for (final p in c.places) p.toJson()],
        'metas': {
          for (final id in (oldCurso['cuentos'] as Map).keys.cast<String>())
            id: c.meta(id)?.toJson(),
        },
        'pairs': [
          for (final p in c.pairs) {...p.toJson(), 'esc': p.scene},
        ],
        'level': [for (final q in c.levelItems) q.toJson()],
        'calls': {for (final p in c.places) p.id: c.callFor(p.id)?.toJson()},
        'goodbye': c.goodbyeWords,
        'words': [
          for (final w in r.words) [w.word, w.place, w.solo, ...w.sentences],
        ],
        'sentences': [
          for (final s in r.sentences) [s.clip, s.story, s.text, s.picture],
        ],
        // what oidoEn gives for each of the 167 words, with every story played
        'heard': {
          for (final w in old.wordList)
            w: [
              for (final l in await c.linesWith(w, played))
                [l.storyId, l.clipId, l.text],
            ],
        },
      };
    }

    test('the catalog never asks for a staged file or a staged book, and a catalog that cannot read one lists, loads and counts the same', () async {
      final asked = <String>[];
      Future<String> blind(String path) async {
        asked.add(path);
        // a staged story file and a staged book
        if (staged.any(
          (id) => path == 'cuentos/$id.json' || path == 'libros/$id.json',
        )) {
          throw StateError(
            'no file $path',
          ); // as a file that is not on the site
        }
        return _read(path);
      }

      final without = ContentCatalog(blind);
      await without.load();
      for (final id in appFiles) {
        await without.story(id);
      }
      // the app is asked for the books of the stories the course names, and only those
      for (final id in courseBooks) {
        await without.book(id);
      }
      final seen = await snapshot(without);
      // what it holds is what the fixture says: 140 pairs, 167 words, 52 level items and the places of curso.js
      expect(seen['places'], sameJson(oldCurso['lugares']));
      expect(seen['pairs'], sameJson(old.pairs));
      expect(without.pairs, hasLength(140));
      expect(without.repaso!.words, hasLength(167));
      expect(without.levelItems, hasLength(52));
      expect(
        without.repaso!.words.map((w) => w.word).toSet(),
        old.wordList.toSet(),
      );
      expect(without.repaso!.words.map((w) => w.word), [
        for (final w in (_json('datos/repaso.json') as Map)['palabras'] as List)
          (w as Map)['w'],
      ]);
      // and it is what the catalog over the whole folder holds
      expect(await snapshot(catalog), sameJson(seen));
      // the files it read of cuentos/ are the course's, the review sets', and the word list
      final reads = {
        for (final p in asked)
          if (p.startsWith('cuentos/'))
            p.substring('cuentos/'.length).replaceAll(RegExp(r'\.json$'), ''),
      };
      expect(reads.difference({...courseFiles, _solasId}), isEmpty);
      // the books it read are the course's
      final readBooks = {
        for (final p in asked)
          if (p.startsWith('libros/'))
            p.substring('libros/'.length).replaceAll(RegExp(r'\.json$'), ''),
      };
      expect(readBooks, courseBooks.toSet());
      expect(asked.where((p) => staged.any((id) => p.contains(id))), isEmpty);
    });

    test('a staged story is no story, no review set, no routine, no pair and no word of the app', () async {
      final listed = {
        for (final p in catalog.places) ...[
          ...p.stories,
          ...p.routines,
          ...p.pictureStories,
        ],
      };
      final r = catalog.repaso!;
      final readStories = {for (final s in r.sentences) s.story};
      final pairStories = {
        for (final w in r.words)
          for (final l in w.pairLines) ?l.story,
      };
      for (final id in staged) {
        expect(catalog.meta(id), isNull, reason: id);
        expect(listed, isNot(contains(id)), reason: id);
        expect(catalog.callFor(id), isNull, reason: id);
        expect(readStories, isNot(contains(id)), reason: id);
        expect(pairStories, isNot(contains(id)), reason: id);
        expect(
          [for (final p in catalog.pairs) p.scene],
          isNot(contains(id)),
          reason: id,
        );
        expect(
          [for (final q in catalog.levelItems) q.toJson().toString()]
              .where((t) => t.contains("'$id'") || t.contains('"$id"')),
          isEmpty,
          reason: id,
        );
      }
      // the lists are the course's: its 57 stories, picture stories and routines, listed in its places
      expect(listed, (oldCurso['cuentos'] as Map).keys.toSet());
    });
  });
}
