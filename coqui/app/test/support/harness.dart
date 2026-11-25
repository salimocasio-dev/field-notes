// The app in a widget test: the real modules, the real progress store, the real catalog reading the real files under
// historia/ from disk, the real scene pictures; fakes only where a phone is needed (sound, speech, the call, the clock,
// haptics, the build facts).
import 'dart:convert';
import 'dart:io';

import 'package:app/src/app.dart';
import 'package:app/src/content.dart';
import 'package:app/src/platform.dart';
import 'package:app/src/previa.dart';
import 'package:app/src/scoped_clip_player.dart';
import 'package:app/src/switches.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_progress/coqui_progress.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The repository's root (the tests run in coqui/app).
final String repoRoot = Directory.current.parent.parent.path;

/// A file of the repository, as text.
String repoFile(String path) => File('$repoRoot/$path').readAsStringSync();

/// The progress the old app keeps under `coqui.palabras.v1`: a seed of `coqui/ref/pantallas/seeds/` (as one line).
String seed(String name) =>
    repoFile('coqui/ref/pantallas/seeds/$name.json').replaceAll('\n', '');

/// The time the seeds were made for: 2026-11-19 16:00 UTC (`window.__PAL_NOW` of coqui/ref/pantallas/README.md).
const int seedNow = 1795104000000;

/// The progress store's key, where the old app left it.
const String progressKey = 'coqui.palabras.v1';

/// A clip player whose lines take as long as their marks say, on the test's time.
class TimedClips extends FakeClipPlayer {
  TimedClips(ClipInfo? Function(String id) lookup)
    : super(
        lengthOf: (id) {
          final c = lookup(id);
          return c == null ? null : c.endMs - c.startMs;
        },
      );

  @override
  Future<bool> play(String clipId, {Duration? limit}) async {
    final len = lengthOf!(clipId);
    final ok = await super.play(clipId, limit: limit);
    played[played.length - 1] = ScopedClipPlayer.unscope(played.last);
    if (len != null) {
      final cap = limit?.inMilliseconds;
      await Future<void>.delayed(
        Duration(milliseconds: cap != null && cap < len ? cap : len),
      );
    }
    return ok;
  }
}

/// One store of strings for every space: the progress store's key as it is, a space's under `coqui.<name>.`, as
/// coqui_platform keeps them in the browser.
class Spaces {
  Spaces([Map<String, String>? values]) : kv = FakeKeyValueStore(values);

  final FakeKeyValueStore kv;
  late final AppStorage storage = AppStorage(
    progress: kv,
    space: (name) => _Prefixed(kv, 'coqui.$name.'),
  );
}

class _Prefixed implements KeyValueStore {
  _Prefixed(this.kv, this.prefix);
  final KeyValueStore kv;
  final String prefix;

  @override
  String? read(String key) => kv.read('$prefix$key');

  @override
  Future<void> write(String key, String value) =>
      kv.write('$prefix$key', value);
}

/// The app, open in a test.
class TestApp {
  TestApp(this.tester);

  final WidgetTester tester;
  final FakeClock clock = FakeClock(seedNow);
  late Spaces spaces;
  TimedClips? clips;
  late FakeSpeechListener speech;
  late FakeCallSession call;
  final FakeHaptics haptics = FakeHaptics();
  final FakeAppInfo info = FakeAppInfo(build: '42');

  /// Every path the catalog fetched, in order.
  final List<String> fetched = [];

  /// The network is down: every fetch fails.
  bool offline = false;

  /// Changes a content file as it is fetched (its path under historia/, its text): a test's own content.
  String Function(String path, String text)? editContent;

  /// The preview content the app is built with (`previa.dart`); null: none, as the tests of the site's own files want.
  PreviaRead? previa;

  /// Optional per-language course loader passed to [AppPlatform.loadCourse].
  Future<CourseCatalog> Function(String languageCode)? loadCourse;

  /// Optional clip player factory passed to [AppPlatform.clipPlayer].
  ClipPlayer Function(ClipInfo? Function(String id) lookup)? clipPlayerFactory;

  /// The stored progress for the active language, read back (falling back to
  /// the legacy key when no per-language record has been written yet).
  String? get stored {
    final code = find.byType(WelcomeGate).evaluate().isNotEmpty
        ? services.course.language.code
        : _sharedLanguageCode();
    try {
      return storedFor(code) ?? spaces.kv.read(progressKey);
    } on ArgumentError {
      return storedFor(Language.spanish.code) ?? spaces.kv.read(progressKey);
    }
  }

  String _sharedLanguageCode() {
    final raw = sharedStored;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map &&
            decoded['idioma'] is String &&
            (decoded['idioma'] as String).isNotEmpty) {
          return decoded['idioma'] as String;
        }
      } catch (_) {}
    }
    return Language.spanish.code;
  }

  /// The cross-language shared progress snapshot (`coqui.shared.v1`).
  String? get sharedStored => spaces.kv.read(PalabrasStore.sharedStorageKey);

  /// The stored progress for language [code] (`coqui.<code>.palabras.v1`).
  String? storedFor(String code) =>
      spaces.kv.read(PalabrasStore.storageKeyFor(code));

  /// Lets [ms] of time go by, in steps of 20 ms, the clock and the frames together.
  Future<void> advance(int ms) async {
    for (var t = 0; t < ms; t += 20) {
      clock.advance(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  /// Gives real time to what reads the assets (the scenes' sheets and old pictures), with frames in between.
  Future<void> settle({int rounds = 40}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Pumps until [ok] is true (giving real time to asset reads); fails after [rounds].
  Future<void> until(
    bool Function() ok, {
    int rounds = 400,
    String what = 'the condition',
  }) async {
    for (var i = 0; i < rounds; i++) {
      if (ok()) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      clock.advance(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
    }
    if (!ok()) fail('$what never came');
  }

  /// Taps [finder] and lets the frame and a little time follow.
  Future<void> tap(Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await advance(100);
  }

  AppPlatform platform() => AppPlatform(
    fetch: (path) {
      fetched.add(path);
      if (offline) return Future.error(const SocketException('offline'));
      final f = File('$repoRoot/historia/$path');
      if (!f.existsSync()) return Future.error(StateError('404 $path'));
      final text = f.readAsStringSync();
      return Future.value(editContent?.call(path, text) ?? text);
    },
    bundle: TestSceneBundle(),
    contentBase: contentBaseOf(Uri.parse('http://127.0.0.1/field-notes/app/')),
    storage: () async => spaces.storage,
    clipPlayer: (lookup) =>
        clipPlayerFactory?.call(lookup) ?? (clips = TimedClips(lookup)),
    speech: speech,
    call: (info) async => call,
    haptics: haptics,
    info: info,
    clock: clock,
    previa: previa,
    loadCourse: loadCourse,
  );

  /// Opens the app at [location] with the stored progress [stored] (a seed's text, or nothing) and optional extra
  /// [initialStorage] entries (e.g. `coqui.shared.v1` and per-language stores).
  Future<void> open({
    String? stored,
    Map<String, String>? initialStorage,
    String? location,
    AppSwitches switches = const AppSwitches(),
    bool welcomeDone = false,
    Size size = const Size(412, 915),
    double ratio = 2.625,
    bool reduceMotion = true,
    List<String> micStub = const [],
    bool speechAvailable = true,
  }) async {
    tester.view.physicalSize = Size(size.width * ratio, size.height * ratio);
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: reduceMotion);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    spaces = Spaces({progressKey: ?stored, ...?initialStorage});
    speech = FakeSpeechListener(results: micStub, isAvailable: speechAvailable);
    call = FakeCallSession(stub: switches.stubOptions);
    addTearDown(call.dispose);
    await tester.pumpWidget(
      CoquiApp(
        platform: platform(),
        switches: switches,
        initialLocation: location,
      ),
    );
    await settle(rounds: 10);
  }

  /// The tab bar is on screen.
  bool get tabBarShown => find.byType(NocheTabBar).evaluate().isNotEmpty;

  /// The selected tab.
  String get selectedTab =>
      tester.widget<NocheTabBar>(find.byType(NocheTabBar)).selectedId;

  /// Taps the tab [id] in the tab bar.
  Future<void> openTab(String id) async {
    final label = services.course.language.tabNames[id]!;
    await tap(
      find.descendant(of: find.byType(NocheTabBar), matching: find.text(label)),
    );
    await settle(rounds: 5);
  }

  /// The services the app gave its features.
  Services get services =>
      tester.widget<WelcomeGate>(find.byType(WelcomeGate)).services;

  /// Goes where a feature would send him ([AppNavigator.go]), and lets the screen come.
  Future<void> go(AppRoute route) async {
    services.nav.go(route);
    await tester.pump();
    await settle(rounds: 10);
  }

  /// A lesson screen is on (the tab bar is hidden).
  bool get lessonShown => !tabBarShown;
}

/// The widgets whose class is named [name] (a feature's own screen, which only its package can name).
Finder byTypeName(String name) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

/// The state of the one widget named [name], to read what a feature's screen shows (its session), as a test of the
/// feature reads it, without naming its type.
dynamic stateNamed(WidgetTester tester, String name) =>
    tester.state(byTypeName(name));

/// Whether the map tab currently renders N4.1's Noche UI (PR #127) rather than v=39's [MapChips]/[TodayCard].
bool isNocheMap() =>
    find.byKey(const Key('language-chip')).evaluate().isNotEmpty;

/// The map's top chips bar: N4.1's `language-chip`, or v=39's [MapChips].
Finder findMapTopChips() => find.byWidgetPredicate(
  (w) => w.key == const Key('language-chip') || w is MapChips,
  description: 'map top chips (N4.1 language-chip or v=39 MapChips)',
);

/// The map's Up next / Today card: N4.1's `up-next-card`, or v=39's [TodayCard].
Finder findMapUpNextCard() => find.byWidgetPredicate(
  (w) => w.key == const Key('up-next-card') || w is TodayCard,
  description: 'map up-next card (N4.1 up-next-card or v=39 TodayCard)',
);

/// The tap target that starts the map's Up next / Today entry: N4.1's `up-next-play` disc, or v=39's [TodayCard].
Finder findMapUpNextAction() => find.byWidgetPredicate(
  (w) => w.key == const Key('up-next-play') || w is TodayCard,
  description: 'map up-next action (N4.1 up-next-play or v=39 TodayCard)',
);

/// TEST-ONLY. A scene that is not converted and never will be: no scene of coqui_scenes' registry has its id. Its old
/// pictures are order 06's pictures of El banco (coqui/ref/escenas/banco/pairs/), as they were before order 36b converted
/// El banco. The test of ¿Cuál?'s old pictures puts a review set at it (TestApp.editContent), so that it does not depend
/// on which real scenes are converted (order 36b).
const String testSceneId = 'prueba';

/// Where the test scene's old pictures are: the folder of order 06's pictures it takes them from.
String get testScenePictures => '$repoRoot/coqui/ref/escenas/banco/pairs';

/// The root bundle, with the old pictures of the test scene ([testSceneId]) added, read from [testScenePictures]: what
/// ScenePictures reads them from, as it reads a real scene's from the package's assets.
class TestSceneBundle extends CachingAssetBundle {
  static const _at = 'packages/coqui_scenes/assets/old_pictures/$testSceneId/';

  ByteData _bytes(List<int> b) => ByteData.sublistView(Uint8List.fromList(b));

  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith(_at)) {
      final file = key.substring(_at.length);
      if (file == 'index.json') {
        final names = [
          for (final f in Directory(testScenePictures).listSync())
            if (f.path.endsWith('.png')) f.uri.pathSegments.last,
        ]..sort();
        return _bytes(
          utf8.encode(
            jsonEncode({
              for (final f in names) f.substring(0, f.length - 4): f,
            }),
          ),
        );
      }
      final f = File('$testScenePictures/$file');
      if (f.existsSync()) return _bytes(f.readAsBytesSync());
    }
    return rootBundle.load(key);
  }
}
