// Repaso's games (page 15) as a fresh reader sees them: the real app, the mid-course seed, sessions played by touches,
// every item at its three moments (asked, answered, answer shown), saved as pictures in play order.
//
//   cd coqui/app && flutter test tool/repaso_shots_test.dart --dart-define=OUT=<dir>
//
// The real app shell on the harness's fakes (timed silent clips, the scripted recogniser, the fake clock) at 390 x 844,
// ratio 2 (pictures of 780 x 1688), the real fonts, reduced motion. The book pictures are the files of historia/libros/
// (a stand-in for the network, as the site would serve them). The first session is a whole one of ten words; more
// sessions follow until each game has been answered once right and once wrong. Writes <dir>/NNN-<moment>.png and
// <dir>/index.json: for each picture the session, the game, the word, the sentence and what was touched.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/rendering.dart';
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

  Future<void> shoot(String moment, Map<String, Object?> what) async {
    for (var i = 0; i < 2; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await tester.pump();
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
    final n = index.length + 1;
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

    for (
      var session = 1;
      session <= 6 && (session == 1 || !covered());
      session++
    ) {
      await app.go(const ReviewRoute());
      await app.settle(rounds: 10);
      dynamic s() => stateNamed(tester, 'RepasoScreen').session;
      final words = [for (final w in s().words as List) w.word as String];
      await shots.shoot('start', {
        'session': session,
        'screen': 'start',
        'words': words,
      });
      await app.tap(find.byType(LessonStartButton));
      Object? acted;
      var shownFor = -1;
      Map<String, Object?> about = {};
      var touched = '';
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

        if (item != null &&
            (ss.yourTurn as bool) &&
            !identical(acted, ss.entry)) {
          acted = ss.entry;
          final again = ss.again as bool;
          // this item: right or wrong? the first of each game one way, the next the other way
          final want = done[kind]!.contains(false)
              ? true
              : done[kind]!.contains(true)
              ? false
              : (kind == 'HearItem' ||
                    kind == 'MatchItem' ||
                    kind == 'SayItem');
          final right = again ? true : want;
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
          await app.settle(rounds: 8);
          await shots.shoot('asked', {...about, 'touched': null});
          final r = choices.indexWhere((c) => c.right as bool);
          final w = r == 0 ? 1 : 0;
          switch (kind) {
            case 'CualItem' || 'WhereItem':
              final k = right ? r : w;
              touched = label(k);
              final g = await tester.startGesture(
                tester.getCenter(find.byType(PictureChoice).at(k)),
              );
              await g.up();
              await tester.pump();
            case 'HearItem':
              final k = right ? r : w;
              touched = label(k);
              await app.tap(find.byType(WordTile).at(k));
            case 'BuildItem':
              final order = (item.order as List).cast<String>();
              final tray = find.descendant(
                of: find.byType(TileTray).last,
                matching: find.byType(WordTile),
              );
              final taps = <String>[];
              if (!right) {
                final k = choices.indexWhere((c) => c.label != order.first);
                taps.add(label(k));
                await app.tap(tray.at(k));
              }
              for (final x in order) {
                final k = (s().choices as List<dynamic>).indexWhere(
                  (c) => !(c.done as bool) && c.label == x,
                );
                taps.add(x);
                await app.tap(tray.at(k));
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
                  taps.add('sound 1 -> ${words[order[k]]}');
                  await app.tap(find.byType(WordTile).at(k));
                  await app.settle(rounds: 2);
                  await shots.shoot('answered', {
                    ...about,
                    'right': false,
                    'touched': taps.last,
                  });
                }
                taps.add('sound ${i + 1} -> ${words[i]}');
                await app.tap(find.byType(WordTile).at(order.indexOf(i)));
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
          if (kind != 'SayItem' && !(kind == 'MatchItem' && !right)) {
            await app.advance(150);
            await shots.shoot('answered', {
              ...about,
              'right': right,
              'touched': touched,
            });
          }
          if (!again) done[kind]!.add(right);
          shownFor = -1;
        } else if (choices.any((c) => c.sign as bool) && shownFor != ss.index) {
          shownFor = ss.index as int;
          await app.settle(rounds: 4);
          await shots.shoot('shown', {...about, 'touched': touched});
          final k = choices.indexWhere((c) => c.sign as bool);
          if (kind == 'HearItem') {
            await app.tap(find.byType(WordTile).at(k));
          } else {
            final g = await tester.startGesture(
              tester.getCenter(find.byType(PictureChoice).at(k)),
            );
            await g.up();
            await tester.pump();
          }
        } else if (ss.mic != null &&
            (ss.mic as Enum).name == 'ready' &&
            kind == 'SayItem') {
          await app.tap(byTypeName('RepasoMic'));
          await app.advance(700);
          await shots.shoot('answered', {
            ...about,
            'right': ss.heardRight,
            'heard': ss.heard,
            'touched': touched,
          });
        } else if (ss.canNext as bool) {
          await app.settle(rounds: 8);
          await shots.shoot('shown', {...about, 'touched': touched});
          await app.tap(find.widgetWithText(LessonButton, 'Next'));
        } else if (kind == 'CualItem' &&
            choices.any((c) => c.check as bool) &&
            shownFor != ss.index) {
          // ¿Cuál? goes on by itself: its last moment is the answer with its check
          shownFor = ss.index as int;
          await shots.shoot('shown', {...about, 'touched': touched});
        }
        await app.advance(100);
      }
      await app.settle(rounds: 6);
      final end = s().end;
      await shots.shoot('end', {
        'session': session,
        'screen': 'end',
        'summary': end.summary,
      });
      await app.tap(find.text('Back to Palabras'));
      await app.settle(rounds: 5);
    }
    File('${dir.path}/index.json').writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert({
        'screen': '390 x 844, ratio 2',
        'learner': 'coqui/ref/pantallas/seeds/curso.json (map stories 1 to 15 played) at 2026-11-19 16:00 UTC',
        'covered': {
          for (final e in done.entries)
            _games[e.key]: [for (final b in e.value) b ? 'right' : 'wrong'],
        },
        'pictures': shots.index,
      }),
    );
  }, timeout: const Timeout(Duration(minutes: 40)));
}
