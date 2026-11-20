// Repaso's games (page 15) as a fresh reader sees them: the real app, the mid-course seed, sessions played by touches,
// every item at its moments (asked; answered, right after the touch; the answer shown with the sign, after a wrong
// touch; revealed, after the right thing was touched; and for each game its own: Arma la frase's placed tiles,
// Parejas' matched pairs, Dilo's listening and not-heard tries), saved as pictures in play order.
//
//   cd coqui/app && flutter test tool/repaso_shots_test.dart --dart-define=OUT=<dir>
//
// The real app shell on the harness's fakes (timed silent clips, the scripted recogniser, the fake clock) at 390 x 844,
// ratio 2 (pictures of 780 x 1688), the real fonts, reduced motion. The book pictures are the files of historia/libros/
// (a stand-in for the network, as the site would serve them). The first session is a whole one of ten words, with at
// least two words missed; more sessions follow until each game has been answered once right and once wrong. Writes
// <dir>/NNN-<moment>.png and <dir>/index.json: for each picture the session, the game, the word, the sentence and
// what was touched.
//
// It also checks, and fails the run when it finds: an `ErrorWidget` in the tree at any picture, or a picture that
// failed to draw (the scenes' own red error box); a game whose layout moved between the moment it was asked and any
// later one (the instruction line, the chip's place, the round speaker, the tiles and pictures, the reveal's place,
// Next's place); the end screen not listing every scored word of its session once.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import '../test/support/harness.dart';

const String _out = String.fromEnvironment('OUT');

Future<void> _loadFonts() async {
  final dir = '$repoRoot/coqui/packages/core/coqui_ui';
  Future<void> load(String family, Iterable<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File('$dir/$f').readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('packages/coqui_ui/Roboto', coquiFontFiles.values);
  await load('Roboto', coquiFontFiles.values);
}

// ---- the site's files, for the book pictures (NetworkImage asks an HttpClient)

class _Files implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _Request(url);

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _Headers implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _Request implements HttpClientRequest {
  _Request(this.url);
  final Uri url;

  @override
  final HttpHeaders headers = _Headers();

  @override
  Future<HttpClientResponse> close() async {
    final p = url.path;
    final i = p.indexOf('/field-notes/');
    final f = File('$repoRoot/${p.substring(i + '/field-notes/'.length)}');
    return _Response(f.existsSync() ? f.readAsBytesSync() : null);
  }

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.bytes);
  final Uint8List? bytes;

  @override
  int get statusCode => bytes == null ? 404 : 200;

  @override
  int get contentLength => bytes?.length ?? 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.fromIterable([?bytes]).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

// ---- the pictures

class _Shots {
  _Shots(this.tester, this.dir);
  final WidgetTester tester;
  final Directory dir;
  final List<Map<String, Object?>> index = [];

  /// How many pictures were checked for error boxes, and for layout against their item's first.
  int errorChecks = 0;
  int layoutChecks = 0;

  /// The layout of the item on screen when it was asked (null between items).
  List<(String, Rect)>? baseline;

  /// An `ErrorWidget` in the tree, or a picture that could not be drawn (coqui_scenes puts its own red box, a
  /// `ColoredBox` of 0xFF3A1E24 with the error's text, where a picture failed): the run fails.
  void checkNoErrorBoxes(String where) {
    errorChecks++;
    final errors = find.byType(ErrorWidget).evaluate();
    if (errors.isNotEmpty) {
      fail(
        '$where: an ErrorWidget is in the tree: '
        '${[for (final e in errors) (e.widget as ErrorWidget).message].join(' | ')}',
      );
    }
    final failed = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == const Color(0xFF3A1E24),
    );
    if (failed.evaluate().isNotEmpty) {
      final text = find.descendant(of: failed, matching: find.byType(Text));
      fail(
        '$where: a picture failed to draw: '
        '${[for (final t in text.evaluate()) (t.widget as Text).data].join(' | ')}',
      );
    }
  }

  /// Where the fixed parts of a game are: the instruction line, the chip's place, the round speaker, the tiles,
  /// pictures and sounds, Dilo's mic, the reveal's place, Next's place.
  List<(String, Rect)> geometry() {
    final out = <(String, Rect)>[];
    void add(String name, Finder f) {
      final n = f.evaluate().length;
      for (var i = 0; i < n; i++) {
        out.add(('$name[$i]', tester.getRect(f.at(i))));
      }
    }

    add(
      'instruction',
      find.byWidgetPredicate(
        (w) => w is Text && w.style == CoquiText.lessonHint,
      ),
    );
    add('chip', find.byType(StreakChip));
    add('speaker', find.byType(RoundSpeaker));
    add('picture', find.byType(PictureChoice));
    add('tile', find.byType(WordTile));
    add('sound', find.byType(SpeakerTile));
    add('mic', byTypeName('RepasoMic'));
    add('reveal', find.byKey(const ValueKey('reveal')));
    add('next', find.byKey(const ValueKey('next-slot')));
    return out;
  }

  /// The layout is the one the item had when it was asked: nothing moved.
  void checkLayout(String where) {
    final base = baseline;
    if (base == null) return;
    layoutChecks++;
    final now = geometry();
    final moved = <String>[];
    if (now.length != base.length) {
      moved.add('${base.length} parts then, ${now.length} now');
    } else {
      for (var i = 0; i < now.length; i++) {
        final a = base[i].$2, b = now[i].$2;
        if ((a.left - b.left).abs() > .01 ||
            (a.top - b.top).abs() > .01 ||
            (a.width - b.width).abs() > .01 ||
            (a.height - b.height).abs() > .01) {
          moved.add('${now[i].$1}: $a -> $b');
        }
      }
    }
    if (moved.isNotEmpty) fail('$where: the layout moved: ${moved.join('; ')}');
  }

  Future<void> shoot(String moment, Map<String, Object?> what) async {
    for (var i = 0; i < 2; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await tester.pump();
    }
    final n = index.length + 1;
    final where = 'picture $n ($moment, ${what['game'] ?? what['screen']})';
    checkNoErrorBoxes(where);
    if (moment == 'asked') {
      baseline = geometry();
    } else if (what['screen'] == null) {
      checkLayout(where);
    }
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final png = await tester.runAsync(() async {
      final image = await layer.toImage(view.paintBounds);
      final b = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List();
      image.dispose();
      return Uint8List.fromList(b);
    });
    final file = '${n.toString().padLeft(3, '0')}-$moment.png';
    File('${dir.path}/$file').writeAsBytesSync(png!);
    index.add({'n': n, 'file': file, 'moment': moment, ...what});
  }
}

/// The games' names as page 15 has them.
const Map<String, String> _games = {
  'CualItem': '¿Cuál?',
  'HearItem': '¿Qué oyes?',
  'BuildItem': 'Arma la frase',
  'MatchItem': 'Parejas',
  'WhereItem': '¿Dónde?',
  'SayItem': 'Dilo',
};

void main() {
  testWidgets('Repaso\'s games, as a reader sees them', (tester) async {
    if (_out.isEmpty) {
      markTestSkipped('no --dart-define=OUT=<dir>');
      return;
    }
    final dir = Directory(_out)..createSync(recursive: true);
    for (final f in dir.listSync()) {
      if (f is File && (f.path.endsWith('.png') || f.path.endsWith('.json'))) {
        f.deleteSync();
      }
    }
    await tester.runAsync(_loadFonts);
    debugNetworkImageHttpClientProvider = _Files.new;
    addTearDown(() => debugNetworkImageHttpClientProvider = null);
    final shots = _Shots(tester, dir);
    final app = TestApp(tester);
    await app.open(
      stored: seed('curso'),
      size: const Size(390, 844),
      ratio: 2,
      speechAvailable: true,
    );
    // right and wrong, each game: how many of each have been played
    final done = <String, Set<bool>>{for (final g in _games.keys) g: {}};
    bool covered() => done.values.every((s) => s.length == 2);
    var returned = 0;
    var wrongTotal = 0;
    var endsChecked = 0;

    for (
      var session = 1;
      session <= 6 && (session == 1 || !covered());
      session++
    ) {
      await app.go(const ReviewRoute());
      await app.settle(rounds: 10);
      dynamic s() => stateNamed(tester, 'RepasoScreen').session;
      final words = [for (final w in s().words as List) w.word as String];
      shots.baseline = null;
      await shots.shoot('start', {
        'session': session,
        'screen': 'start',
        'words': words,
      });
      await app.tap(find.byType(LessonStartButton));
      Object? acted;
      Object? shotFor; // the entry whose sign / reveal has been taken
      Object? revealFor;
      Map<String, Object?> about = {};
      var touched = '';
      var wrongItem = false;
      var micTries = 0;
      var missed = 0; // scored items answered wrong in this session
      for (var t = 0; ; t += 100) {
        if (t > 30 * 60 * 1000) fail('session $session did not end');
        final ss = s();
        if ((ss.screen as Enum).name == 'end') break;
        final item = ss.item;
        final kind = item?.runtimeType.toString();
        final choices = (ss.choices as List<dynamic>?) ?? const [];
        String label(int k) {
          final c = choices[k];
          final l = c.label as String;
          return l.isNotEmpty ? l : 'picture ${k + 1}';
        }

        Future<void> touchChoice(int k) async {
          if (kind == 'HearItem') {
            await app.tap(find.byType(WordTile).at(k));
          } else {
            final g = await tester.startGesture(
              tester.getCenter(find.byType(PictureChoice).at(k)),
            );
            await g.up();
            await tester.pump();
          }
        }

        if (item != null &&
            (ss.yourTurn as bool) &&
            !identical(acted, ss.entry)) {
          acted = ss.entry;
          final again = ss.again as bool;
          // this item: right or wrong? the scored items of a session start with two misses; then the first of each
          // game is wrong, the second right
          final seen = done[kind]!;
          final want = (item.scored as bool) && !again && missed < 2
              ? false
              : seen.isEmpty
              ? false
              : seen.length == 1
              ? !seen.single
              : true;
          final right = again ? true : want;
          wrongItem = !right;
          micTries = 0;
          final text =
              (item.text as String?) ??
              (kind == 'SayItem' ? item.line.text as String : null);
          about = {
            'session': session,
            'game': _games[kind],
            'again': again,
            'scored': (item.scored as bool) && !again,
            'word': item.word,
            if (kind == 'MatchItem') 'words': item.words,
            if (kind == 'MatchItem')
              'sentences': [for (final x in item.sentences) x.text],
            'sentence': text,
            if (kind == 'SayItem') 'heard_first': item.line.before,
            'options': [for (var k = 0; k < choices.length; k++) label(k)],
          };
          if (again) returned++;
          if (!right) wrongTotal++;
          if ((item.scored as bool) && !again && !right) missed++;
          await app.settle(rounds: 8);
          await shots.shoot('asked', {...about, 'touched': null});
          final r = choices.indexWhere((c) => c.right as bool);
          final w = r == 0 ? 1 : 0;
          switch (kind) {
            case 'CualItem' || 'WhereItem' || 'HearItem':
              final k = right ? r : w;
              touched = label(k);
              await touchChoice(k);
            case 'BuildItem':
              final order = (item.order as List).cast<String>();
              Finder tile(int k) => find
                  .descendant(
                    of: find.byType(TileTray).last,
                    matching: find.byType(WordTile),
                  )
                  .at(k);
              final taps = <String>[];
              Future<void> place(String x) async {
                final k = (ss.choices as List<dynamic>).indexWhere(
                  (c) => !(c.done as bool) && c.label == x,
                );
                taps.add(x);
                await app.tap(tile(k));
              }

              if (!right) {
                final k = choices.indexWhere((c) => c.label != order.first);
                taps.add(label(k));
                await app.tap(tile(k));
                await shots.shoot('answered', {
                  ...about,
                  'right': false,
                  'touched': taps.last,
                });
              }
              for (var n = 0; n < order.length; n++) {
                await place(order[n]);
                if (n == 1 && order.length > 2) {
                  await app.settle(rounds: 2);
                  await shots.shoot('placed', {
                    ...about,
                    'touched': taps.join(' / '),
                  });
                  // a tile in the sentence goes back to the bank when touched, and is put in again
                  final line = find.descendant(
                    of: find.byType(TileTray).first,
                    matching: find.byType(WordTile),
                  );
                  await app.tap(line.at(1));
                  await app.settle(rounds: 2);
                  await shots.shoot('returned', {
                    ...about,
                    'touched':
                        '${taps.last} (touched in the sentence: back to the bank)',
                  });
                  taps.removeLast();
                  await place(order[1]);
                }
              }
              touched = taps.join(' / ');
            case 'MatchItem':
              final order = (item.wordOrder as List).cast<int>();
              final words = (item.words as List).cast<String>();
              final taps = <String>[];
              for (var i = 0; i < 4; i++) {
                await app.tap(find.byType(SpeakerTile).at(i));
                if (!right && i == 0) {
                  final k = (order.indexOf(i) + 1) % 4;
                  taps.add('sound 1 -> ${words[order[k]]} (a slip)');
                  await app.tap(find.byType(WordTile).at(k));
                  await shots.shoot('answered', {
                    ...about,
                    'right': false,
                    'touched': taps.last,
                  });
                  await app.advance(1100); // the flash clears
                  await shots.shoot('cleared', {
                    ...about,
                    'touched': taps.last,
                  });
                }
                taps.add('sound ${i + 1} -> ${words[i]}');
                await app.tap(find.byType(WordTile).at(order.indexOf(i)));
                if (i == 1) {
                  await app.settle(rounds: 2);
                  await shots.shoot('matched', {
                    ...about,
                    'touched': taps.join(', '),
                  });
                }
              }
              touched = taps.join(', ');
            case 'SayItem':
              final forms = (item.line.forms as List).cast<String>();
              app.speech.results.addAll(
                right ? [forms.first] : ['no sé', 'eso no'],
              );
              touched = right
                  ? 'the mic: "${forms.first}"'
                  : 'the mic: "no sé", then "eso no"';
          }
          if (kind != 'SayItem' && kind != 'BuildItem' && kind != 'MatchItem') {
            await app.advance(150);
            await shots.shoot('answered', {
              ...about,
              'right': right,
              'touched': touched,
            });
          } else if (right && kind != 'SayItem') {
            await app.advance(150);
            await shots.shoot('answered', {
              ...about,
              'right': true,
              'touched': touched,
            });
          }
          if (!again) done[kind]!.add(right);
          shotFor = null;
          revealFor = null;
        } else if (ss.canNext as bool) {
          // the item is over but for Next: after a wrong touch (or tries) this is "the right thing was touched"
          if (wrongItem && !identical(revealFor, ss.entry)) {
            revealFor = ss.entry;
            await app.settle(rounds: 8);
            await shots.shoot('revealed', {...about, 'touched': touched});
          }
          await app.tap(find.widgetWithText(LessonButton, 'Next'));
        } else if (choices.any((c) => c.sign as bool)) {
          if (!identical(shotFor, ss.entry)) {
            shotFor = ss.entry;
            await app.settle(rounds: 4);
            await shots.shoot('shown', {...about, 'touched': touched});
          }
          await touchChoice(choices.indexWhere((c) => c.sign as bool));
        } else if (ss.mic != null &&
            (ss.mic as Enum).name == 'ready' &&
            kind == 'SayItem') {
          await app.tap(byTypeName('RepasoMic'));
          await app.advance(100);
          micTries++;
          await shots.shoot('listening', {
            ...about,
            'try': micTries,
            'touched': touched,
          });
          await app.advance(700);
          if (ss.heardRight as bool) {
            await shots.shoot('answered', {
              ...about,
              'right': true,
              'heard': ss.heard,
              'touched': touched,
            });
          } else {
            await shots.shoot('not-heard', {
              ...about,
              'try': micTries,
              'right': false,
              'heard': ss.heard,
              'touched': touched,
            });
          }
        }
        await app.advance(100);
      }
      await app.settle(rounds: 6);
      final end = s().end;
      // every scored word of the session is in exactly one of the two lists
      final rows = [
        for (final g in end.groups as List)
          for (final r in g.rows as List) r.word as String,
      ];
      expect(rows.length, rows.toSet().length, reason: 'a word twice');
      expect(rows.toSet(), words.toSet(), reason: 'every word listed once');
      expect(end.of, words.length);
      endsChecked++;
      shots.baseline = null;
      await shots.shoot('end', {
        'session': session,
        'screen': 'end',
        'summary': end.summary,
        'listed': rows,
        'missed': [
          for (final g in end.groups as List)
            if ((g.title as String) == 'Coming back soon')
              for (final r in g.rows as List) r.word as String,
        ],
      });
      // the list scrolls: the last rows, above the button
      final list = find.descendant(
        of: byTypeName('RepasoEndView'),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(list, const Offset(0, -4000));
      await app.settle(rounds: 6);
      await shots.shoot('end-bottom', {
        'session': session,
        'screen': 'end',
        'summary': end.summary,
      });
      await app.tap(find.text('Back to Palabras'));
      await app.settle(rounds: 5);
    }
    // the praise of the last item, cut short by Next, is a clip of the harness still counting its length
    await app.advance(5000);
    File('${dir.path}/index.json').writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert({
        'screen': '390 x 844, ratio 2',
        'learner': 'coqui/ref/pantallas/seeds/curso.json (map stories 1 to 15 played) at 2026-11-19 16:00 UTC',
        'covered': {
          for (final e in done.entries)
            _games[e.key]: [for (final b in e.value) b ? 'right' : 'wrong'],
        },
        'returned_items': returned,
        'wrong_answers': wrongTotal,
        'checks': {
          'no ErrorWidget and no failed picture, pictures checked':
              shots.errorChecks,
          'layout equal to the item\'s first, pictures checked':
              shots.layoutChecks,
          'end screens listing every scored word once': endsChecked,
        },
        'pictures': shots.index,
      }),
    );
  }, timeout: const Timeout(Duration(minutes: 40)));
}
