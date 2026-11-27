/// The app: the shared look, the routes, the start (storage, the course), and the welcome around everything.
library;

import 'dart:async';

import 'package:app/src/addresses.dart';
import 'package:app/src/content.dart';
import 'package:app/src/modules.dart';
import 'package:app/src/navigator.dart';
import 'package:app/src/platform.dart';
import 'package:app/src/previa.dart';
import 'package:app/src/scoped_clip_player.dart';
import 'package:app/src/shell.dart';
import 'package:app/src/switches.dart';
import 'package:app/src/voice_test_data.dart';
import 'package:coqui_content/coqui_content.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_progress/coqui_progress.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// System bar styling for Noche: `NocheColors.ground` bars with light icons.
const SystemUiOverlayStyle nocheSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: NocheColors.ground,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemStatusBarContrastEnforced: false,
  systemNavigationBarColor: NocheColors.ground,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: false,
);

/// The one line the app shows when the course cannot be loaded, over a "Try again" button.
const String loadFailedLine = 'Coquí could not load. Check your connection.';

/// The button under [loadFailedLine].
const String tryAgainLabel = 'Try again';

/// Stable shell-owned key for the boot loading surface.
const ValueKey<String> shellLoadingKey = ValueKey('shell-loading');

/// Setting key used by language pickers to store the active language code.
const String _languageSettingKey = 'idioma';

final RegExp _whitespace = RegExp(r'\s');

bool _isValidLanguageCode(String code) =>
    code.isNotEmpty && !code.contains('.') && !_whitespace.hasMatch(code);

/// Where the start stands.
enum _Start { loading, failed, ready }

/// What the start made, once the course is loaded.
class _Loaded {
  _Loaded(
    this.course,
    this.progress,
    this.clips,
    this.storage,
    this.call,
    this.voiceTest,
  );

  final CourseCatalog course;
  final PalabrasStore progress;
  final ClipPlayer clips;
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
  /// Mulberry32, seeded once from the clock at the start.
  late final Rng _rng = Mulberry32(widget.platform.clock.nowMs());
  late final ShellNavigator _nav = ShellNavigator(
    historyBack: widget.platform.historyBack,
  );
  late final GoRouter _router;
  final ValueNotifier<({_Start state, int generation})> _start = ValueNotifier((
    state: _Start.loading,
    generation: 0,
  ));
  Future<AppStorage>? _storage;
  ProgressStores? _stores;
  StreamSubscription<void>? _storesChanges;
  CallSession? _call;
  _Loaded? _loaded;
  Services? _services;
  List<FeatureModule>? _modules;
  bool _unlocked = false;
  int _generation = 0;
  int _loadTicket = 0;
  String? _requestedLanguageCode;
  Object? _activeStoreLanguageSetting;
  bool _syncingLanguageSetting = false;
  bool _pendingGoToMap = false;

  static const _page = ValueKey('coqui');

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(nocheSystemUiStyle);
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
          '/idiomas',
          '/planes',
          '/importar',
          '/lugar/:id',
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
    unawaited(_storesChanges?.cancel());
    _stores?.dispose();
    final clips = _loaded?.clips;
    if (clips != null) unawaited(clips.stop());
    _nav.dispose();
    _router.dispose();
    _start.dispose();
    super.dispose();
  }

  Future<CourseCatalog> _loadCourse(String languageCode) async {
    final loader = widget.platform.loadCourse;
    if (loader != null) {
      final course = await loader(languageCode);
      await course.load();
      return course;
    }
    // the site's files, with the preview content merged in (previa.dart)
    final course = ContentCatalog(
      previaFetch(widget.platform.fetch, widget.platform.previa ?? noPrevia),
    );
    await course.load();
    return course;
  }

  // The start (and language switch): the storage, ProgressStores on it, the chosen course (before the first screen,
  // which needs it), the voice test's lines, the call, and the language's own progress store and clip player.
  Future<void> _load({bool goToMap = false}) async {
    final ticket = ++_loadTicket;
    _pendingGoToMap = _pendingGoToMap || goToMap;
    _start.value = (state: _Start.loading, generation: _generation);
    try {
      final storage = await (_storage ??= widget.platform.storage());
      if (!mounted || ticket != _loadTicket) return;
      final stores = _stores ??= ProgressStores(
        storage.progress,
        widget.platform.clock,
      );
      _storesChanges ??= stores.changes.listen(_onProgressChanged);
      final requestedCode = stores.currentLanguageCode;
      _requestedLanguageCode = requestedCode;
      CourseCatalog course;
      try {
        course = await _loadCourse(requestedCode);
      } on UnsupportedError {
        if (requestedCode == Language.spanish.code) rethrow;
        course = await _loadCourse(Language.spanish.code);
      } on ArgumentError {
        if (requestedCode == Language.spanish.code) rethrow;
        course = await _loadCourse(Language.spanish.code);
      }
      if (!mounted || ticket != _loadTicket) return;
      VoiceTestData? voiceTest;
      try {
        voiceTest = VoiceTestData.parse(
          await widget.platform.fetch('datos/prueba-voz.json'),
        );
      } catch (_) {
        voiceTest =
            null; // the voice test only: everything else works without it
      }
      if (!mounted || ticket != _loadTicket) return;
      // CallSession is language-agnostic: each start(CallBrief) takes its agentId from the course.
      final call = _call ??= await widget.platform.call(widget.platform.info);
      if (!mounted || ticket != _loadTicket) return;
      if (course.language.code != requestedCode) {
        _requestedLanguageCode = course.language.code;
        _syncingLanguageSetting = true;
        try {
          stores.currentLanguageCode = course.language.code;
        } finally {
          _syncingLanguageSetting = false;
        }
      }
      final progress = stores.forLanguage(course.language);
      final existingSetting = progress.setting(_languageSettingKey);
      if (existingSetting is String &&
          existingSetting != course.language.code) {
        _syncingLanguageSetting = true;
        try {
          progress.setSetting(_languageSettingKey, course.language.code);
        } finally {
          _syncingLanguageSetting = false;
        }
      }
      _activeStoreLanguageSetting = progress.setting(_languageSettingKey);
      final prevClips = _loaded?.clips;
      if (prevClips != null) unawaited(prevClips.stop());
      final clips = ScopedClipPlayer(
        scope: course.language.code,
        clipInfo: course.clip,
        create: widget.platform.clipPlayer,
      );
      if (_unlocked) unawaited(clips.unlock());
      _loaded = _Loaded(course, progress, clips, storage, call, voiceTest);
      _services = null;
      _modules = null;
      _generation++;
      final shouldGoToMap = _pendingGoToMap;
      _pendingGoToMap = false;
      if (shouldGoToMap &&
          !_nav.isLeavingLesson &&
          routeOf(_router.routeInformationProvider.value.uri) !=
              const TabRoute(startTab)) {
        _nav.go(const TabRoute(startTab));
      }
      _start.value = (state: _Start.ready, generation: _generation);
    } catch (_) {
      if (mounted && ticket == _loadTicket) {
        _start.value = (state: _Start.failed, generation: _generation);
      }
    }
  }

  void _onProgressChanged(void _) {
    if (!mounted || _syncingLanguageSetting) return;
    final stores = _stores;
    if (stores == null) return;
    final sharedCode = stores.currentLanguageCode;
    if (_requestedLanguageCode != null &&
        sharedCode != _requestedLanguageCode) {
      unawaited(_load(goToMap: true));
      return;
    }
    final loaded = _loaded;
    if (loaded == null) return;
    final storeSetting = loaded.progress.setting(_languageSettingKey);
    if (storeSetting != _activeStoreLanguageSetting) {
      _activeStoreLanguageSetting = storeSetting;
      if (storeSetting is String &&
          _isValidLanguageCode(storeSetting) &&
          storeSetting != _requestedLanguageCode &&
          storeSetting != loaded.course.language.code) {
        _requestedLanguageCode = storeSetting;
        _syncingLanguageSetting = true;
        try {
          stores.currentLanguageCode = storeSetting;
        } finally {
          _syncingLanguageSetting = false;
        }
        unawaited(_load(goToMap: true));
      }
    }
  }

  // The services, once per loaded course: `reduceMotion` is the platform's (MediaQuery.disableAnimations) when the app shows.
  Services _servicesFor(BuildContext context) {
    final had = _services;
    if (had != null) return had;
    final l = _loaded!;
    final p = widget.platform;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final s = Services(
      progress: l.progress,
      course: l.course,
      clips: l.clips,
      speech: p.speech,
      call: l.call,
      nav: _nav,
      clock: p.clock,
      rng: _rng,
      haptics: p.haptics,
      info: p.info,
      pictures: ScenePictures(
        pairs: l.course.pairs,
        bundle: p.bundle,
        still: reduce,
      ),
      storage: l.storage.space,
      reduceMotion: reduce,
      entitlements: p.entitlements,
    );
    final modules = coquiModules(
      switches: widget.switches,
      bookImageUrl: (path) => bookImageUrl(p.contentBase, path),
      entitlements: p.entitlements,
      voiceTest: l.voiceTest,
    );
    _modules = modules;
    _nav.answers = (route) {
      // a story the course does not have is not an address of the app
      if (route is StoryRoute && l.course.meta(route.id) == null) return false;
      return modules.any((m) => m.screenFor(route, s) != null);
    };
    return _services = s;
  }

  // The first tap anywhere once a player exists opens the sound (the browser lets a page play sound only inside a touch).
  void _firstTap(PointerDownEvent _) {
    if (_unlocked) return;
    final clips = _loaded?.clips;
    if (clips == null) return;
    _unlocked = true;
    unawaited(clips.unlock());
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: CoquiLabels.appName,
    debugShowCheckedModeBanner: false,
    theme: coquiTheme().copyWith(
      scaffoldBackgroundColor: NocheColors.ground,
      canvasColor: NocheColors.ground,
    ),
    routerConfig: _router,
    builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: nocheSystemUiStyle,
      // Android 16 enforces transparent system bars. Paint their background
      // ourselves and keep legacy screens inside the system insets.
      child: ColoredBox(
        color: NocheColors.ground,
        child: SafeArea(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _firstTap,
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// The page for one address: the start's state, then the app.
class _Screens extends StatelessWidget {
  const _Screens({required this.app, required this.address});

  final _CoquiAppState app;
  final Uri address;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<({_Start state, int generation})>(
        valueListenable: app._start,
        builder: (context, phase, _) => switch (phase.state) {
          _Start.loading => const ColoredBox(
            key: shellLoadingKey,
            color: NocheColors.ground,
          ),
          _Start.failed => LoadFailed(onRetry: () => unawaited(app._load())),
          _Start.ready => Builder(
            builder: (context) {
              final s = app._servicesFor(context);
              return Material(
                type: MaterialType.transparency,
                child: WelcomeGate(
                  key: ValueKey('course:${phase.generation}'),
                  services: s,
                  child: AppShell(
                    key: ValueKey('shell:${phase.generation}'),
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

  /// Stable shell-owned key for the failed-load surface.
  static const ValueKey<String> screenKey = ValueKey('shell-load-failed');

  /// Stable shell-owned key for the retry button on [LoadFailed].
  static const ValueKey<String> retryKey = ValueKey('shell-load-failed-retry');

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: screenKey,
    color: NocheColors.ground,
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(NocheSize.grid * 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loadFailedLine,
                style: NocheType.bodyLarge.copyWith(color: NocheColors.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NocheSize.grid * 2),
              NochePrimaryButton(
                key: retryKey,
                label: tryAgainLabel,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
