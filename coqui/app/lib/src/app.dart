/// The app: the shared look, the routes, the start (storage, the course), and the welcome around everything.
library;

import 'dart:async';

import 'package:app/src/addresses.dart';
import 'package:app/src/content.dart';
import 'package:app/src/modules.dart';
import 'package:app/src/motion.dart';
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

/// The line shown under the pulsing dots while the course loads.
const String loadingCourseLine = 'Getting your course';

/// The one line the app shows when the course cannot be loaded, over a "Try again" button.
const String loadFailedLine = 'Coquí could not load. Check your connection.';

/// The button under [loadFailedLine].
const String tryAgainLabel = 'Try again';

/// Stable shell-owned key for the boot loading surface.
const ValueKey<String> shellLoadingKey = ValueKey('shell-loading');

/// Stable shell-owned key for the loading dots row on [_ShellLoading].
const ValueKey<String> shellLoadingDotsKey = ValueKey('shell-loading-dots');

/// Stable shell-owned key for the loading status line on [_ShellLoading].
const ValueKey<String> shellLoadingLineKey = ValueKey('shell-loading-line');

/// Stable shell-owned key for the course-turn opacity wrapper.
const ValueKey<String> shellCourseTurnKey = ValueKey('shell-course-turn');

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

class _CoquiAppState extends State<CoquiApp> with TickerProviderStateMixin {
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
  late final AnimationController _courseTurnController = AnimationController(
    vsync: this,
    value: 1.0,
    animationBehavior: AnimationBehavior.preserve,
  );
  BuildContext? _innerContext;
  Future<AppStorage>? _storage;
  ProgressStores? _stores;
  StreamSubscription<void>? _storesChanges;
  CallSession? _call;
  _Loaded? _loaded;
  Services? _services;
  List<FeatureModule>? _modules;
  bool _unlocked = false;
  bool _animateInitialLoadArrival = false;
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
    _courseTurnController.dispose();
    _nav.dispose();
    _router.dispose();
    _start.dispose();
    super.dispose();
  }

  NocheMotionData _currentMotion() {
    final ctx = _innerContext;
    if (ctx != null && ctx.mounted) {
      return NocheMotion.of(ctx);
    }
    return WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations
        ? NocheMotion.reduced
        : NocheMotion.normal;
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
    final isCourseTurn =
        goToMap && _loaded != null && _start.value.state == _Start.ready;
    Future<void>? fadeOutFuture;
    if (isCourseTurn) {
      final motion = _currentMotion();
      fadeOutFuture = _courseTurnController
          .animateTo(0.0, duration: motion.quick, curve: motion.exit)
          .orCancel
          .catchError((_) {});
    } else {
      _courseTurnController.value = 1.0;
      _start.value = (state: _Start.loading, generation: _generation);
    }
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
      if (fadeOutFuture != null) {
        await fadeOutFuture;
        if (!mounted || ticket != _loadTicket) return;
      }
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
      _animateInitialLoadArrival = _loaded == null;
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
      if (isCourseTurn) {
        final motion = _currentMotion();
        unawaited(
          _courseTurnController
              .animateTo(1.0, duration: motion.move, curve: motion.enter)
              .orCancel
              .catchError((_) {}),
        );
      }
    } catch (_) {
      if (mounted && ticket == _loadTicket) {
        _courseTurnController.value = 1.0;
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
    builder: (context, child) {
      _innerContext = context;
      return AnnotatedRegion<SystemUiOverlayStyle>(
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
      );
    },
  );
}

/// The page for one address: the start's state, then the app.
class _Screens extends StatefulWidget {
  const _Screens({required this.app, required this.address});

  final _CoquiAppState app;
  final Uri address;

  @override
  State<_Screens> createState() => _ScreensState();
}

class _ScreensState extends State<_Screens>
    with SingleTickerProviderStateMixin {
  final GlobalKey _loadingKey = GlobalKey();
  final GlobalKey _failedKey = GlobalKey();

  late ({_Start state, int generation}) _phase = widget.app._start.value;
  _Start? _lastBuiltState;
  _Start? _outgoingState;
  NocheMotionData _outgoingMotion = NocheMotion.normal;

  late final AnimationController _outgoingController = AnimationController(
    vsync: this,
    value: 1.0,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_handleOutgoingStatus);

  @override
  void initState() {
    super.initState();
    widget.app._start.addListener(_onStartChanged);
  }

  @override
  void didUpdateWidget(_Screens oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.app != widget.app) {
      oldWidget.app._start.removeListener(_onStartChanged);
      widget.app._start.addListener(_onStartChanged);
      _phase = widget.app._start.value;
    }
  }

  @override
  void dispose() {
    widget.app._start.removeListener(_onStartChanged);
    _outgoingController
      ..removeStatusListener(_handleOutgoingStatus)
      ..dispose();
    super.dispose();
  }

  void _handleOutgoingStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _outgoingState != null &&
        mounted) {
      setState(() {
        _outgoingState = null;
      });
    }
  }

  void _onStartChanged() {
    if (!mounted) return;
    final next = widget.app._start.value;
    if (next == _phase) return;
    setState(() {
      final fromState = _lastBuiltState ?? _phase.state;
      if (next.state != fromState &&
          (fromState == _Start.loading || fromState == _Start.failed)) {
        _outgoingState = fromState;
        _outgoingMotion = NocheMotion.of(context);
        _outgoingController.duration = _outgoingMotion.quick;
        _outgoingController.forward(from: 0.0);
      } else if (next.state == _outgoingState) {
        _outgoingState = null;
        _outgoingController.value = 1.0;
      }
      _phase = next;
    });
  }

  Widget _buildSurface(_Start state, int generation) => switch (state) {
    _Start.loading => _ShellLoading(key: _loadingKey),
    _Start.failed => LoadFailed(
      key: _failedKey,
      onRetry: () => unawaited(widget.app._load()),
    ),
    _Start.ready => Builder(
      builder: (context) {
        final s = widget.app._servicesFor(context);
        return AnimatedBuilder(
          animation: widget.app._courseTurnController,
          builder: (context, child) => Opacity(
            key: shellCourseTurnKey,
            opacity: widget.app._courseTurnController.value.clamp(0.0, 1.0),
            child: child,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: WelcomeGate(
              key: ValueKey('course:$generation'),
              services: s,
              child: AppShell(
                key: ValueKey('shell:$generation'),
                services: s,
                modules: widget.app._modules!,
                nav: widget.app._nav,
                route: routeOf(widget.address) ?? const TabRoute(startTab),
                animateLoadArrival: widget.app._animateInitialLoadArrival,
              ),
            ),
          ),
        );
      },
    ),
  };

  @override
  Widget build(BuildContext context) {
    _lastBuiltState = _phase.state;
    final active = _buildSurface(_phase.state, _phase.generation);

    return AnimatedBuilder(
      animation: _outgoingController,
      child: active,
      builder: (context, activeChild) {
        final outgoingState = _outgoingState;
        final Widget? outgoing =
            outgoingState != null && _outgoingController.value < 1.0
            ? Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Opacity(
                      opacity:
                          (1.0 -
                                  _outgoingMotion.exit.transform(
                                    _outgoingController.value,
                                  ))
                              .clamp(0.0, 1.0),
                      child: _buildSurface(outgoingState, _phase.generation),
                    ),
                  ),
                ),
              )
            : null;
        return Stack(fit: StackFit.expand, children: [activeChild!, ?outgoing]);
      },
    );
  }
}

/// The boot loading surface: silent for [ShellMotion.loadSilentDelay], then
/// fades in three staggered pulsing dots and [loadingCourseLine].
class _ShellLoading extends StatefulWidget {
  const _ShellLoading({super.key});

  @override
  State<_ShellLoading> createState() => _ShellLoadingState();
}

class _ShellLoadingState extends State<_ShellLoading>
    with TickerProviderStateMixin {
  late final AnimationController _enterController = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
  );
  late final AnimationController _dotsController = AnimationController(
    vsync: this,
    duration: NocheMotion.thinkingCycle,
    animationBehavior: AnimationBehavior.preserve,
  );

  late NocheMotionData _motion;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextMotion = NocheMotion.of(context);
    if (!_started) {
      _started = true;
      _motion = nextMotion;
      final total = ShellMotion.loadSilentDelay + _motion.move;
      _enterController.duration = total;
      _enterController.forward(from: 0.0);
      if (_motion.loops) {
        _dotsController.repeat();
      } else {
        _dotsController.value = 0.0;
      }
    } else if (_motion.loops != nextMotion.loops) {
      _motion = nextMotion;
      if (_motion.loops) {
        _dotsController.repeat();
      } else {
        _dotsController
          ..stop()
          ..value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  double _enterOpacity() {
    if (_enterController.isCompleted) return 1.0;
    final totalUs = (ShellMotion.loadSilentDelay + _motion.move).inMicroseconds
        .toDouble();
    final elapsedUs = _enterController.value * totalUs;
    final delayUs = ShellMotion.loadSilentDelay.inMicroseconds.toDouble();
    if (elapsedUs <= delayUs) return 0.0;
    final moveUs = _motion.move.inMicroseconds.toDouble();
    if (moveUs <= 0) return 1.0;
    final raw = ((elapsedUs - delayUs) / moveUs).clamp(0.0, 1.0);
    return _motion.enter.transform(raw).clamp(0.0, 1.0);
  }

  double _dotOpacity(int index) {
    if (!_motion.loops || _motion.reduced) return 1.0;
    final cycleUs = NocheMotion.thinkingCycle.inMicroseconds.toDouble();
    final staggerUs = ShellMotion.loadDotStagger.inMicroseconds.toDouble();
    var phase = (_dotsController.value - (index * staggerUs) / cycleUs) % 1.0;
    if (phase < 0) phase += 1.0;
    if (phase <= 0.3) {
      final t = (phase / 0.3).clamp(0.0, 1.0);
      return 0.35 + 0.65 * _motion.travel.transform(t);
    }
    if (phase <= 0.6) {
      final t = ((phase - 0.3) / 0.3).clamp(0.0, 1.0);
      return 1.0 - 0.65 * _motion.travel.transform(t);
    }
    return 0.35;
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: shellLoadingKey,
    color: NocheColors.ground,
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: NocheSize.grid * 3,
          ),
          child: AnimatedBuilder(
            animation: _enterController,
            builder: (context, child) =>
                Opacity(opacity: _enterOpacity(), child: child),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  key: shellLoadingDotsKey,
                  child: AnimatedBuilder(
                    animation: _dotsController,
                    builder: (context, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0)
                            const SizedBox(width: ShellMotion.loadDotGap),
                          Opacity(
                            opacity: _dotOpacity(i),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: NocheColors.label,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(
                                width: ShellMotion.loadDotSize,
                                height: ShellMotion.loadDotSize,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: ShellMotion.loadLineGap),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    loadingCourseLine,
                    key: shellLoadingLineKey,
                    style: NocheType.bodyLarge.copyWith(
                      color: NocheColors.label,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
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
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    return ColoredBox(
      key: screenKey,
      color: NocheColors.ground,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(NocheSize.grid * 3),
            child: NocheArrive(
              delay: motion.swapAfter,
              nextSpacing: ShellMotion.loadLineGap,
              next: NochePrimaryButton(
                key: retryKey,
                label: tryAgainLabel,
                onPressed: onRetry,
              ),
              children: [
                Text(
                  loadFailedLine,
                  style: NocheType.bodyLarge.copyWith(color: NocheColors.text),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
