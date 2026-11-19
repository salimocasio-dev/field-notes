/// The app: the shared look, the routes, the start (storage, the course), and the welcome around everything.
library;

import 'dart:async';

import 'package:app/src/addresses.dart';
import 'package:app/src/content.dart';
import 'package:app/src/modules.dart';
import 'package:app/src/navigator.dart';
import 'package:app/src/platform.dart';
import 'package:app/src/shell.dart';
import 'package:app/src/switches.dart';
import 'package:app/src/voice_test_data.dart';
import 'package:coqui_content/coqui_content.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_progress/coqui_progress.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The one line the app shows when the course cannot be loaded, over a "Try again" button.
const String loadFailedLine = 'Coquí could not load. Check your connection.';

/// The button under [loadFailedLine].
const String tryAgainLabel = 'Try again';

/// Where the start stands.
enum _Start { loading, failed, ready }

/// What the start made, once the course is loaded.
class _Loaded {
  _Loaded(this.progress, this.storage, this.call, this.voiceTest);

  final ProgressStore progress;
  final AppStorage storage;
  final CallSession call;
  final VoiceTestData? voiceTest;
}

/// The app on [platform], for the address switches [switches]. [initialLocation]: the address to open when the platform
/// gives none (tests; on the web the page's own address is used).
class CoquiApp extends StatefulWidget {
  const CoquiApp({
    super.key,
    required this.platform,
    this.switches = const AppSwitches(),
    this.initialLocation,
  });

  final AppPlatform platform;
  final AppSwitches switches;
  final String? initialLocation;

  @override
  State<CoquiApp> createState() => _CoquiAppState();
}

class _CoquiAppState extends State<CoquiApp> {
  late final ContentCatalog _course = ContentCatalog(widget.platform.fetch);
  late final ClipPlayer _clips = widget.platform.clipPlayer(_course.clip);

  /// Mulberry32, seeded once from the clock at the start.
  late final Rng _rng = Mulberry32(widget.platform.clock.nowMs());
  late final ShellNavigator _nav = ShellNavigator(
    historyBack: widget.platform.historyBack,
  );
  late final GoRouter _router;
  final ValueNotifier<_Start> _start = ValueNotifier(_Start.loading);
  Future<AppStorage>? _storage;
  _Loaded? _loaded;
  Services? _services;
  List<FeatureModule>? _modules;
  bool _unlocked = false;

  static const _page = ValueKey('coqui');

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: widget.initialLocation,
      redirect: (context, state) => routeOf(state.uri) == null
          ? addressOf(const TabRoute(startTab))
          : null,
      routes: [
        for (final path in const [
          '/tab/:id',
          '/cuento/:id',
          '/repaso',
          '/nivel',
          '/libro/:id',
          '/llamada/:id',
          '/prueba-voz',
        ])
          GoRoute(
            path: path,
            pageBuilder: (context, state) => NoTransitionPage(
              key: _page,
              child: _Screens(app: this, address: state.uri),
            ),
          ),
      ],
    );
    _nav.router = _router;
    unawaited(_load());
  }

  @override
  void dispose() {
    _nav.dispose();
    _router.dispose();
    _start.dispose();
    super.dispose();
  }

  // The start: the storage, the progress store on it, the course (before the first screen, which needs it), the voice
  // test's lines, the call.
  Future<void> _load() async {
    _start.value = _Start.loading;
    try {
      final storage = await (_storage ??= widget.platform.storage());
      await _course.load();
      VoiceTestData? voiceTest;
      try {
        voiceTest = VoiceTestData.parse(
          await widget.platform.fetch('datos/prueba-voz.json'),
        );
      } catch (_) {
        voiceTest =
            null; // the voice test only: everything else works without it
      }
      final call = await widget.platform.call(widget.platform.info);
      _loaded = _Loaded(
        PalabrasStore(storage.progress, widget.platform.clock),
        storage,
        call,
        voiceTest,
      );
      if (mounted) _start.value = _Start.ready;
    } catch (_) {
      if (mounted) _start.value = _Start.failed;
    }
  }

  // The services, once: `reduceMotion` is the platform's (MediaQuery.disableAnimations) when the app first shows.
  Services _servicesFor(BuildContext context) {
    final had = _services;
    if (had != null) return had;
    final l = _loaded!;
    final p = widget.platform;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final s = Services(
      progress: l.progress,
      course: _course,
      clips: _clips,
      speech: p.speech,
      call: l.call,
      nav: _nav,
      clock: p.clock,
      rng: _rng,
      haptics: p.haptics,
      info: p.info,
      pictures: ScenePictures(
        pairs: _course.pairs,
        bundle: p.bundle,
        still: reduce,
      ),
      storage: l.storage.space,
      reduceMotion: reduce,
    );
    final modules = coquiModules(
      switches: widget.switches,
      bookImageUrl: (path) => bookImageUrl(p.contentBase, path),
      voiceTest: l.voiceTest,
    );
    _modules = modules;
    _nav.answers = (route) {
      // a story the course does not have is not an address of the app
      if (route is StoryRoute && _course.meta(route.id) == null) return false;
      return modules.any((m) => m.screenFor(route, s) != null);
    };
    return _services = s;
  }

  // The first tap anywhere opens the sound (the browser lets a page play sound only after a touch).
  void _firstTap(PointerDownEvent _) {
    if (_unlocked) return;
    _unlocked = true;
    unawaited(_clips.unlock());
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: CoquiLabels.appName,
    debugShowCheckedModeBanner: false,
    theme: coquiTheme(),
    routerConfig: _router,
    builder: (context, child) => Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _firstTap,
      child: child,
    ),
  );
}

/// The page for one address: the start's state, then the app.
class _Screens extends StatelessWidget {
  const _Screens({required this.app, required this.address});

  final _CoquiAppState app;
  final Uri address;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<_Start>(
    valueListenable: app._start,
    builder: (context, start, _) => switch (start) {
      _Start.loading => const ColoredBox(color: CoquiColors.bg),
      _Start.failed => LoadFailed(onRetry: () => unawaited(app._load())),
      _Start.ready => Builder(
        builder: (context) {
          final s = app._servicesFor(context);
          return Material(
            type: MaterialType.transparency,
            child: WelcomeGate(
              services: s,
              child: AppShell(
                services: s,
                modules: app._modules!,
                nav: app._nav,
                route: routeOf(address) ?? const TabRoute(startTab),
              ),
            ),
          );
        },
      ),
    },
  );
}

/// The course could not be loaded (no network): one line and "Try again", on the page colour.
class LoadFailed extends StatelessWidget {
  const LoadFailed({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CoquiColors.bg,
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(CoquiMetrics.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loadFailedLine,
                style: CoquiText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CoquiMetrics.s16),
              CoquiButton(label: tryAgainLabel, onPressed: onRetry),
            ],
          ),
        ),
      ),
    ),
  );
}
