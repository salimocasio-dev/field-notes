import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_layout.dart';
import 'package:feature_map/src/map_model.dart';
import 'package:feature_map/src/map_perf.dart';
import 'package:feature_map/src/map_picture.dart';
import 'package:feature_map/src/motion.dart';
import 'package:feature_map/src/scene_window.dart';
import 'package:feature_map/src/wording.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';

/// Camera geometry for the Noche home map: whole-number device scale, scaled map
/// dimensions, clamped scroll offsets, and screen coordinates of the active stop.
@visibleForTesting
class MapCamera {
  const MapCamera({
    required this.deviceScale,
    required this.mapWidth,
    required this.mapHeight,
    required this.scrollX,
    required this.scrollY,
    required this.maxScrollX,
    required this.maxScrollY,
    required this.stopX,
    required this.stopY,
    required this.screenStopX,
    required this.screenStopY,
    required this.viewport,
  });

  final int deviceScale;
  final double mapWidth;
  final double mapHeight;
  final double scrollX;
  final double scrollY;
  final double maxScrollX;
  final double maxScrollY;
  final double stopX;
  final double stopY;
  final double screenStopX;
  final double screenStopY;
  final Size viewport;
}

/// Computes the Noche camera for [viewport], device pixel ratio [dpr],
/// current [stop] in picture coordinates, and [bottomPad] scrollable clearance
/// below the map so early stops can rise to 51% of the screen height.
@visibleForTesting
MapCamera computeMapCamera({
  required Size viewport,
  required double dpr,
  required ({double sx, double sy}) stop,
  required double bottomPad,
}) {
  final minDeviceScale = math.max(
    2.0 * dpr,
    math.max(viewport.width * dpr / mapW, viewport.height * dpr / mapH),
  );
  final deviceScale = math.max(1, (minDeviceScale - 1e-6).ceil());
  final mapWidth = mapW * deviceScale / dpr;
  final mapHeight = mapH * deviceScale / dpr;
  final stopX = stop.sx * mapWidth / mapW;
  final stopY = stop.sy * mapHeight / mapH;
  final maxScrollX = math.max(0.0, mapWidth - viewport.width);
  final maxScrollY = math.max(0.0, mapHeight + bottomPad - viewport.height);
  final scrollX = (stopX - viewport.width / 2).clamp(0.0, maxScrollX);
  final scrollY = (stopY - viewport.height * 0.51).clamp(0.0, maxScrollY);
  return MapCamera(
    deviceScale: deviceScale,
    mapWidth: mapWidth,
    mapHeight: mapHeight,
    scrollX: scrollX,
    scrollY: scrollY,
    maxScrollX: maxScrollX,
    maxScrollY: maxScrollY,
    stopX: stopX,
    stopY: stopY,
    screenStopX: stopX - scrollX,
    screenStopY: stopY - scrollY,
    viewport: viewport,
  );
}

/// The home map tab (`Noche-Mapa.dc.html`, story N4.1 & N8.5): `ground` ocean
/// behind `MapPicture` (`PixelView` at scale 2), the crisp `"You are here"`
/// pill over the current stop, destination and lock pills on place taps, the
/// language & streak chips at the top, and the `"Up next"` / focused-place card
/// above the tab bar.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.services,
    this.perf,
    this.showPerf = false,
    this.reviewTitle,
    this.openPlace,
    this.onPicture,
    this.onCamera,
    required this.entitlements,
    this.overlayOpacity,
    this.animateColdLoad = false,
  });

  final Services services;

  /// Where the bake time and the frame times go, if anyone wants them.
  final MapPerf? perf;

  /// Shows the bake time and the frame times in a small chip under the top chips.
  final bool showPerf;

  /// Title shown when today's plan opens with a review entry; null skips review.
  final String? reviewTitle;

  /// For a dev entry and its screenshots: once the map is up, go to this place (0 to 9).
  final int? openPlace;

  /// For tests: given the picture the screen draws, as soon as it is made.
  final void Function(MapPicture picture)? onPicture;

  /// For tests: notified whenever the camera centers on the active stop.
  final void Function(MapCamera camera)? onCamera;

  /// Explicit plan entitlements used to gate places and Up next stories.
  final Entitlements entitlements;

  /// Optional shell-driven opacity (`0.0` to `1.0`) applied to map overlays
  /// during a course language turn while keeping `PixelView` unfaded.
  final ValueListenable<double>? overlayOpacity;

  /// Whether to stagger internal overlays on initial bake (`Noche-Motion-Carga`).
  final bool animateColdLoad;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _FrameSignal extends ChangeNotifier {
  void fire() => notifyListeners();
}

class _CardSnapshot {
  const _CardSnapshot.upNext({required this.entry, required this.thenLine})
    : placeIndex = null;

  const _CardSnapshot.place({required int this.placeIndex})
    : entry = null,
      thenLine = null;

  final TodayEntry? entry;
  final String? thenLine;
  final int? placeIndex;
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const double _pillLift = 88;
  static const double _pillAnchorWidth = 240;
  static const double _herePillHeight = 52;
  static const double _flatPillHeight = 40;

  late MapPicture _map;
  late final MapPerf? _perf =
      widget.perf ?? (widget.showPerf ? MapPerf() : null);
  final _frames = _FrameSignal();
  final _scrollV = ScrollController();
  final _scrollH = ScrollController();
  Ticker? _ticker;
  Duration _last = Duration.zero;
  StreamSubscription<void>? _changes;
  StreamSubscription<void>? _entitlementChanges;

  late final AnimationController _hereController = AnimationController(
    vsync: this,
    value: 1.0,
  );
  late final AnimationController _destController = AnimationController(
    vsync: this,
    value: 0.0,
  );
  late final AnimationController _cameraController = AnimationController(
    vsync: this,
  );
  late final AnimationController _frogFadeController = AnimationController(
    vsync: this,
    value: 1.0,
  );
  late final AnimationController _tripDelayController = AnimationController(
    vsync: this,
  );
  late final AnimationController _lockController = AnimationController(
    vsync: this,
  );
  late final AnimationController _cardController = AnimationController(
    vsync: this,
    value: 1.0,
  );
  late final AnimationController _cardDragController = AnimationController(
    vsync: this,
  );
  late final AnimationController _coldLoadController = AnimationController(
    vsync: this,
    value: 1.0,
  );

  bool _baked = false;
  bool _openedInitialPlace = false;
  int _serviceGen = 0;
  int _tripToken = 0;
  int _lockToken = 0;
  int _cardToken = 0;

  bool _visiting = false;
  int _hereStopIndex = 0;
  bool _hereRising = false;
  int? _destPlaceIndex;
  bool _destExiting = false;
  int? _lockPlaceIndex;
  bool _lockReduced = false;
  int? _focusedPlaceIndex;
  _CardSnapshot? _outgoingCard;
  bool _cardSwapping = false;
  bool _cardSwapToPlace = false;
  bool _cardSwapReduced = false;
  double _cardDragDy = 0.0;
  double _cardDragStartDy = 0.0;
  bool _cardDragging = false;

  double _camStartX = 0;
  double _camStartY = 0;
  double _camTargetX = 0;
  double _camTargetY = 0;
  Curve _camCurve = NocheMotion.travel;
  MapCamera? _camTarget;

  bool _frogFadeActive = false;
  bool _frogFadingIn = false;
  NocheMotionData _frogFadeMotion = NocheMotion.normal;

  bool _coldLoadStarted = false;
  bool _coldLoadPending = false;
  bool _coldLoadActive = false;
  bool _coldLoadReduced = false;

  Size _viewport = Size.zero;
  double _dpr = 1;
  double _bottomPad = 0;
  final Map<String, String?> _storyScenes = {};
  final Set<String> _loadingScenes = {};

  Services get _s => widget.services;

  @override
  void initState() {
    super.initState();
    _cameraController.addListener(_onCameraTick);
    _frogFadeController.addListener(_onFrogFadeTick);
    _cardDragController.addListener(_onCardDragTick);
    if (widget.animateColdLoad) {
      _coldLoadPending = true;
      _coldLoadController.value = 0.0;
    }
    _map = MapPicture(still: _s.reduceMotion, onHop: _hopSound);
    widget.onPicture?.call(_map);
    _changes = _s.progress.changes.listen((_) => _progressChanged());
    _entitlementChanges = widget.entitlements.changes.listen((_) {
      if (mounted) setState(() {});
    });
    final gen = _serviceGen;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bake(gen));
  }

  @override
  void didUpdateWidget(MapScreen old) {
    super.didUpdateWidget(old);
    if (old.entitlements != widget.entitlements) {
      _entitlementChanges?.cancel();
      _entitlementChanges = widget.entitlements.changes.listen((_) {
        if (mounted) setState(() {});
      });
    }
    if (old.services != widget.services) {
      final gen = ++_serviceGen;
      _cancelActiveTrip();
      _clearLockPill();
      _cardToken++;
      _focusedPlaceIndex = null;
      _outgoingCard = null;
      _cardSwapping = false;
      _cardSwapToPlace = false;
      _cardController.stop();
      _cardController.value = 1.0;
      _cardDragController.stop();
      _cardDragging = false;
      _cardDragDy = 0.0;
      _cardDragStartDy = 0.0;
      _hereRising = false;
      _hereController.stop();
      _hereController.value = 1.0;
      _destPlaceIndex = null;
      _destExiting = false;
      _destController.stop();
      _destController.value = 0.0;
      _changes?.cancel();
      _changes = _s.progress.changes.listen((_) => _progressChanged());
      _storyScenes.clear();
      _loadingScenes.clear();
      if (_ticker?.isActive ?? false) {
        _ticker!.stop();
      }
      _last = Duration.zero;
      _baked = false;
      _map = MapPicture(still: _s.reduceMotion, onHop: _hopSound);
      widget.onPicture?.call(_map);
      WidgetsBinding.instance.addPostFrameCallback((_) => _bake(gen));
    }
  }

  @override
  void dispose() {
    _serviceGen++;
    _tripToken++;
    _lockToken++;
    _cardToken++;
    _changes?.cancel();
    _entitlementChanges?.cancel();
    _ticker?.dispose();
    _hereController.dispose();
    _destController.dispose();
    _cameraController.removeListener(_onCameraTick);
    _cameraController.dispose();
    _frogFadeController.removeListener(_onFrogFadeTick);
    _frogFadeController.dispose();
    _tripDelayController.dispose();
    _lockController.dispose();
    _cardController.dispose();
    _cardDragController.removeListener(_onCardDragTick);
    _cardDragController.dispose();
    _coldLoadController.dispose();
    _scrollV.dispose();
    _scrollH.dispose();
    _frames.dispose();
    if (widget.perf == null) _perf?.dispose();
    super.dispose();
  }

  Future<void> _bake(int gen) async {
    if (!mounted || gen != _serviceGen) return;
    final sw = Stopwatch()..start();
    _map.bake();
    sw.stop();
    _perf?.recordBake(sw.elapsedMicroseconds / 1000);
    await _s.course.load();
    if (!mounted || gen != _serviceGen) return;
    final st = mapStateOf(_s.progress, _s.course);
    _map.setState(st);
    _map.placeFrog(st.aqui);
    _hereStopIndex = st.aqui;
    _hereRising = false;
    _hereController.value = 1.0;
    _baked = true;
    _map.draw();
    _frames.fire();
    if (!_s.reduceMotion) {
      _last = Duration.zero;
      _ticker ??= createTicker(_onTick);
      if (!_ticker!.isActive) _ticker!.start();
    } else if (_ticker?.isActive ?? false) {
      _ticker!.stop();
    }
    _primeNextStoryScene();
    _maybeStartColdLoad();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _serviceGen) return;
      _centerOnStop(st.aqui);
    });
    if (!_openedInitialPlace) {
      _openedInitialPlace = true;
      final go = widget.openPlace;
      if (go != null) _openPlace(go);
    }
  }

  void _maybeStartColdLoad() {
    if (_coldLoadStarted) return;
    _coldLoadStarted = true;
    if (!widget.animateColdLoad) {
      _coldLoadPending = false;
      _coldLoadActive = false;
      _coldLoadController.value = 1.0;
      return;
    }
    final motion = MapMotion.resolve(
      context,
      serviceReduceMotion: _s.reduceMotion,
    );
    _coldLoadPending = false;
    _coldLoadReduced = motion.reduced;
    _coldLoadActive = true;
    final total = motion.reduced
        ? motion.quick
        : (MapMotion.loadPlayAfter + motion.move);
    _coldLoadController.stop();
    _coldLoadController.duration = total;
    unawaited(
      _coldLoadController.forward(from: 0.0).whenComplete(() {
        if (mounted && _coldLoadController.isCompleted) {
          setState(() => _coldLoadActive = false);
        }
      }),
    );
  }

  void _onTick(Duration elapsed) {
    final dt = math.min(.05, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    final sw = Stopwatch()..start();
    _map.tick(dt);
    sw.stop();
    _perf?.recordFrame(sw.elapsedMicroseconds / 1000);
    _frames.fire();
  }

  void _onCameraTick() {
    if (!mounted) return;
    final t = _camCurve.transform(_cameraController.value.clamp(0.0, 1.0));
    if (_scrollH.hasClients) {
      final nextX = _camStartX + (_camTargetX - _camStartX) * t;
      _scrollH.jumpTo(nextX.clamp(0.0, _scrollH.position.maxScrollExtent));
    }
    if (_scrollV.hasClients) {
      final nextY = _camStartY + (_camTargetY - _camStartY) * t;
      _scrollV.jumpTo(nextY.clamp(0.0, _scrollV.position.maxScrollExtent));
    }
    if (_cameraController.isCompleted && _camTarget != null) {
      final target = _camTarget!;
      _camTarget = null;
      widget.onCamera?.call(target);
    }
  }

  void _onFrogFadeTick() {
    if (!_baked || !_frogFadeActive) return;
    final v = _frogFadeController.value.clamp(0.0, 1.0);
    _map.FROG.opacity = _frogFadingIn
        ? _frogFadeMotion.enter.transform(v).clamp(0.0, 1.0)
        : (1.0 - _frogFadeMotion.exit.transform(v)).clamp(0.0, 1.0);
    _redraw();
  }

  void _redraw() {
    _map.draw();
    _frames.fire();
  }

  void _cancelActiveTrip() {
    _tripToken++;
    _visiting = false;
    _frogFadeActive = false;
    _camTarget = null;
    _tripDelayController.stop();
    _cameraController.stop();
    _frogFadeController.stop();
    _map.FROG
      ..opacity = 1.0
      ..hideArrow = false;
  }

  void _clearLockPill() {
    _lockToken++;
    _lockController.stop();
    _lockPlaceIndex = null;
  }

  void _progressChanged() {
    if (!mounted || !_baked) return;
    final prevAqui = _map.STATE.aqui;
    final st = mapStateOf(_s.progress, _s.course);
    final moved = st.aqui != prevAqui;
    _map.setState(st);
    if (moved) {
      _cancelActiveTrip();
      _clearLockPill();
      _cardToken++;
      _focusedPlaceIndex = null;
      _outgoingCard = null;
      _cardSwapping = false;
      _cardSwapToPlace = false;
      _cardController.stop();
      _cardController.value = 1.0;
      _cardDragController.stop();
      _cardDragging = false;
      _cardDragDy = 0.0;
      _cardDragStartDy = 0.0;
      _hereStopIndex = st.aqui;
      _hereRising = false;
      _hereController.stop();
      _hereController.value = 1.0;
      _destPlaceIndex = null;
      _destExiting = false;
      _destController.stop();
      _destController.value = 0.0;
      _map.placeFrog(st.aqui);
    }
    _redraw();
    _primeNextStoryScene();
    setState(() {});
    if (moved) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _centerOnStop(st.aqui),
      );
    }
  }

  void _primeNextStoryScene() {
    final plan = _plan();
    if (plan.isEmpty) return;
    final route = plan.first.route;
    if (route is! StoryRoute) return;
    _primeStoryScene(route.id);
  }

  void _primePlaceHeroScene(Place place) {
    final heroStoryId = _heroStoryIdForPlace(place);
    if (heroStoryId != null) _primeStoryScene(heroStoryId);
  }

  void _primeStoryScene(String id) {
    if (_storyScenes.containsKey(id) || _loadingScenes.contains(id)) return;
    _loadingScenes.add(id);
    final gen = _serviceGen;
    unawaited(() async {
      String? scene;
      try {
        final data = await _s.course.story(id);
        final raw = data['scene'];
        if (raw is String && raw.isNotEmpty) scene = raw;
      } on Object {
        scene = null;
      } finally {
        _loadingScenes.remove(id);
      }
      if (!mounted || gen != _serviceGen) return;
      if (_storyScenes[id] != scene) {
        setState(() => _storyScenes[id] = scene);
      } else {
        _storyScenes[id] = scene;
      }
    }());
  }

  String? _heroStoryIdForPlace(Place place) =>
      nextUnheardStory(_s.progress, place) ??
      (place.stories.isNotEmpty ? place.stories.first : null);

  MapCamera _cameraForStop(
    int stopIndex,
    Size viewport,
    double dpr,
    double bottomPad,
  ) {
    final clamped = stopIndex.clamp(0, placeCount - 1);
    return computeMapCamera(
      viewport: viewport,
      dpr: dpr,
      stop: _map.stopOnPicture(clamped),
      bottomPad: bottomPad,
    );
  }

  void _centerOnStop(int stopIndex) {
    if (!mounted || _viewport.isEmpty) return;
    final cam = _cameraForStop(stopIndex, _viewport, _dpr, _bottomPad);
    if (_scrollH.hasClients) {
      _scrollH.jumpTo(
        cam.scrollX.clamp(0.0, _scrollH.position.maxScrollExtent),
      );
    }
    if (_scrollV.hasClients) {
      _scrollV.jumpTo(
        cam.scrollY.clamp(0.0, _scrollV.position.maxScrollExtent),
      );
    }
    widget.onCamera?.call(cam);
  }

  Future<bool> _animateCameraTo(
    int stopIndex, {
    required Duration duration,
    required Curve curve,
    required int token,
  }) async {
    if (!mounted || token != _tripToken) return false;
    if (_viewport.isEmpty) return true;
    final targetCam = _cameraForStop(stopIndex, _viewport, _dpr, _bottomPad);
    _camStartX = _scrollH.hasClients ? _scrollH.offset : targetCam.scrollX;
    _camTargetX = _scrollH.hasClients
        ? targetCam.scrollX.clamp(0.0, _scrollH.position.maxScrollExtent)
        : targetCam.scrollX;
    _camStartY = _scrollV.hasClients ? _scrollV.offset : targetCam.scrollY;
    _camTargetY = _scrollV.hasClients
        ? targetCam.scrollY.clamp(0.0, _scrollV.position.maxScrollExtent)
        : targetCam.scrollY;
    _camCurve = curve;
    _camTarget = targetCam;
    _cameraController.stop();
    if (duration <= Duration.zero) {
      _centerOnStop(stopIndex);
      _camTarget = null;
      return true;
    }
    _cameraController.duration = duration;
    try {
      await _cameraController.forward(from: 0.0).orCancel;
    } on TickerCanceled {
      return false;
    }
    return mounted && token == _tripToken;
  }

  Future<bool> _waitTripDelay(Duration duration, int token) async {
    if (!mounted || token != _tripToken) return false;
    if (duration <= Duration.zero) return true;
    _tripDelayController.stop();
    _tripDelayController.duration = duration;
    try {
      await _tripDelayController.forward(from: 0.0).orCancel;
    } on TickerCanceled {
      return false;
    }
    return mounted && token == _tripToken;
  }

  Future<bool> _runFrogFade({
    required bool fadeIn,
    required Duration duration,
    required NocheMotionData motion,
    required int token,
  }) async {
    if (!mounted || token != _tripToken) return false;
    _frogFadeActive = true;
    _frogFadingIn = fadeIn;
    _frogFadeMotion = motion;
    _frogFadeController.stop();
    if (duration <= Duration.zero) {
      _map.FROG.opacity = fadeIn ? 1.0 : 0.0;
      _frogFadeActive = false;
      _redraw();
      return true;
    }
    _frogFadeController.duration = duration;
    try {
      await _frogFadeController.forward(from: 0.0).orCancel;
    } on TickerCanceled {
      _frogFadeActive = false;
      return false;
    }
    _frogFadeActive = false;
    if (!mounted || token != _tripToken) return false;
    _map.FROG.opacity = fadeIn ? 1.0 : 0.0;
    _redraw();
    return true;
  }

  void _hopSound() =>
      _s.clips.tone(320, dur: .07, wave: 'square', vol: .025, toHz: 520);

  void _onTapPixel(int x, int y) {
    if (!_baked || _visiting || _map.FROG.path != null) return;
    _visit(_map.stopAt(x + .5, y + .5));
  }

  void _visit(int k) {
    if (!_baked || _visiting || _map.FROG.path != null) return;
    final places = _s.course.places;
    if (k < 0 || k >= places.length) return;
    _s.haptics.tick();
    if (!_map.STATE.abierto[k]) {
      _showLockPill(k);
      return;
    }
    final hadLock = _lockPlaceIndex != null;
    _clearLockPill();
    if (k == _map.FROG.at) {
      if (_focusedPlaceIndex == k) {
        if (hadLock) setState(() {});
        _openPlace(k);
      } else {
        _switchCardToPlace(k);
      }
      return;
    }
    final motion = MapMotion.resolve(
      context,
      serviceReduceMotion: _s.reduceMotion,
    );
    if (motion.reduced) {
      _map.placeFrog(k);
      _redraw();
      setState(() {
        _hereStopIndex = k;
        _hereRising = false;
        _hereController.stop();
        _hereController.value = 1.0;
        _destPlaceIndex = null;
        _destExiting = false;
        _destController.stop();
        _destController.value = 0.0;
      });
      _centerOnStop(k);
      _switchCardToPlace(k);
      return;
    }
    unawaited(_runTrip(k, motion));
  }

  Future<void> _runTrip(int k, NocheMotionData motion) async {
    final token = ++_tripToken;
    final startHereOpacity = _herePillMotion(motion).opacity;
    setState(() {
      _visiting = true;
      _destPlaceIndex = k;
      _destExiting = false;
      _hereRising = false;
    });
    _destController.stop();
    _destController.duration = motion.press;
    unawaited(_destController.forward(from: 0.0));
    _hereController.stop();
    if (startHereOpacity <= 0.0) {
      _hereController.value = 0.0;
    } else {
      _hereController.duration = motion.quick;
      unawaited(_hereController.reverse(from: startHereOpacity));
    }

    if (!await _waitTripDelay(MapMotion.tripStartDelay, token)) return;

    final List<Hop> hops = _map.planHops(_map.FROG.at, k);
    if (hops.isNotEmpty) {
      // planHops expands per-leg counts into individual Hop segments, so
      // hops.length is the total hop count across all legs (<= maxTripHops).
      final totalHopCount = hops.length;
      unawaited(
        _animateCameraTo(
          k,
          duration: motion.hop * totalHopCount,
          curve: motion.travel,
          token: token,
        ),
      );
      _map.hopTo(k, () {
        if (mounted && token == _tripToken) {
          unawaited(_finishTripAfterSettle(k, motion, token));
        }
      });
      return;
    }

    // Far trip (> 6 legs): fade coquí out, travel camera in pageIn, fade coquí in.
    _map.FROG.hideArrow = true;
    if (!await _runFrogFade(
      fadeIn: false,
      duration: motion.quick,
      motion: motion,
      token: token,
    )) {
      return;
    }
    _map.placeFrog(k);
    _map.FROG
      ..opacity = 0.0
      ..hideArrow = true;
    _redraw();

    if (!await _animateCameraTo(
      k,
      duration: motion.pageIn,
      curve: motion.travel,
      token: token,
    )) {
      return;
    }

    if (!await _runFrogFade(
      fadeIn: true,
      duration: motion.quick,
      motion: motion,
      token: token,
    )) {
      return;
    }
    _map.FROG
      ..opacity = 1.0
      ..hideArrow = false;
    _redraw();

    await _finishTripAfterSettle(k, motion, token);
  }

  Future<void> _finishTripAfterSettle(
    int k,
    NocheMotionData motion,
    int token,
  ) async {
    if (!await _waitTripDelay(MapMotion.tripSettleDelay, token)) return;
    if (!mounted || token != _tripToken) return;

    setState(() {
      _destExiting = true;
      _hereStopIndex = k;
      _hereRising = true;
      _visiting = false;
    });
    _destController.stop();
    _destController.duration = motion.quick;
    unawaited(
      _destController.reverse(from: _destController.value).whenComplete(() {
        if (mounted &&
            token == _tripToken &&
            _destExiting &&
            _destController.isDismissed) {
          setState(() => _destPlaceIndex = null);
        }
      }),
    );
    _hereController.stop();
    _hereController.duration = MapMotion.hereRiseAfter + motion.move;
    unawaited(_hereController.forward(from: 0.0));
    _switchCardToPlace(k);
  }

  void _showLockPill(int k) {
    final motion = MapMotion.resolve(
      context,
      serviceReduceMotion: _s.reduceMotion,
    );
    final enterDur = motion.reduced ? motion.quick : motion.press;
    final exitDur = motion.reduced ? motion.quick : motion.move;
    final total = enterDur + motion.lockHold + exitDur;
    final token = ++_lockToken;
    setState(() {
      _lockPlaceIndex = k;
      _lockReduced = motion.reduced;
    });
    _lockController.stop();
    _lockController.duration = total;
    unawaited(
      _lockController.forward(from: 0.0).whenComplete(() {
        if (mounted && token == _lockToken && _lockController.isCompleted) {
          setState(() => _lockPlaceIndex = null);
        }
      }),
    );
  }

  void _switchCardToPlace(int k) {
    final places = _s.course.places;
    if (k < 0 || k >= places.length) return;
    _primePlaceHeroScene(places[k]);

    final plan = _plan();
    final _CardSnapshot? prevSnapshot;
    if (_focusedPlaceIndex != null && _focusedPlaceIndex! < places.length) {
      prevSnapshot = _CardSnapshot.place(placeIndex: _focusedPlaceIndex!);
    } else if (plan.isNotEmpty) {
      prevSnapshot = _CardSnapshot.upNext(
        entry: plan.first,
        thenLine: upNextThenLine(plan),
      );
    } else {
      prevSnapshot = null;
    }

    final motion = MapMotion.resolve(
      context,
      serviceReduceMotion: _s.reduceMotion,
    );
    final token = ++_cardToken;
    _cardDragController.stop();
    _cardDragging = false;
    _cardDragDy = 0.0;
    _cardDragStartDy = 0.0;
    setState(() {
      _outgoingCard = prevSnapshot;
      _focusedPlaceIndex = k;
      _cardSwapping = prevSnapshot != null;
      _cardSwapToPlace = true;
      _cardSwapReduced = motion.reduced;
    });
    if (prevSnapshot == null) {
      _cardController.stop();
      _cardController.value = 1.0;
      return;
    }
    final total = motion.reduced
        ? motion.quick
        : (motion.followAfter + motion.nextDelay + motion.move);
    _cardController.stop();
    _cardController.duration = total;
    unawaited(
      _cardController.forward(from: 0.0).whenComplete(() {
        if (mounted && token == _cardToken && _cardController.isCompleted) {
          setState(() {
            _outgoingCard = null;
            _cardSwapping = false;
          });
        }
      }),
    );
  }

  void _switchCardToUpNext() {
    if (!_baked || _focusedPlaceIndex == null) return;
    final places = _s.course.places;
    final idx = _focusedPlaceIndex!;
    if (idx < 0 || idx >= places.length) {
      setState(() => _focusedPlaceIndex = null);
      return;
    }
    _primeNextStoryScene();
    final prevSnapshot = _CardSnapshot.place(placeIndex: idx);
    final motion = MapMotion.resolve(
      context,
      serviceReduceMotion: _s.reduceMotion,
    );
    final token = ++_cardToken;
    setState(() {
      _outgoingCard = prevSnapshot;
      _focusedPlaceIndex = null;
      _cardSwapping = true;
      _cardSwapToPlace = false;
      _cardSwapReduced = motion.reduced;
    });
    final total = motion.reduced
        ? motion.quick
        : (motion.followAfter + motion.move);
    _cardController.stop();
    _cardController.duration = total;
    unawaited(
      _cardController.forward(from: 0.0).whenComplete(() {
        if (mounted && token == _cardToken && _cardController.isCompleted) {
          setState(() {
            _outgoingCard = null;
            _cardSwapping = false;
          });
        }
      }),
    );
  }

  void _onCardDragTick() {
    if (!mounted || _cardDragging) return;
    final motion = MapMotion.resolve(
      context,
      serviceReduceMotion: _s.reduceMotion,
    );
    final t = motion.travel.transform(
      _cardDragController.value.clamp(0.0, 1.0),
    );
    _cardDragDy = _cardDragStartDy * (1.0 - t);
  }

  void _animateCardDragBack(NocheMotionData motion) {
    _cardDragController.stop();
    final from = _cardDragDy;
    if (from == 0.0) return;
    if (motion.reduced || motion.move <= Duration.zero) {
      setState(() {
        _cardDragDy = 0.0;
        _cardDragStartDy = 0.0;
      });
      return;
    }
    _cardDragStartDy = from;
    _cardDragController.duration = motion.move;
    unawaited(
      _cardDragController.forward(from: 0.0).whenComplete(() {
        if (mounted && !_cardDragging && _cardDragController.isCompleted) {
          setState(() {
            _cardDragDy = 0.0;
            _cardDragStartDy = 0.0;
          });
        }
      }),
    );
  }

  void _finishCardDrag(int placeIdx, NocheMotionData motion) {
    if (!_cardDragging) return;
    _cardDragging = false;
    if (_cardDragDy < -MapMotion.cardDragThreshold) {
      _s.haptics.tick();
      _openPlace(placeIdx);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_cardDragging && _cardDragDy != 0) {
          setState(() {
            _cardDragDy = 0.0;
            _cardDragStartDy = 0.0;
          });
        }
      });
      return;
    }
    if (_cardDragDy > MapMotion.cardDragThreshold) {
      _s.haptics.tick();
      _switchCardToUpNext();
      _animateCardDragBack(motion);
      return;
    }
    _animateCardDragBack(motion);
  }

  void _openPlace(int k) {
    if (!mounted) return;
    final places = _s.course.places;
    if (k < 0 || k >= places.length) return;
    _s.nav.go(PlaceRoute(places[k].id));
  }

  void _start(TodayEntry e) {
    _s.haptics.tick();
    final route = e.route;
    if (route is StoryRoute &&
        !storyInPlan(route.id, _s.course.places, widget.entitlements)) {
      final idx = placeIndexForStory(_s.course.places, route.id);
      if (idx != null) {
        _openPlace(idx);
      } else {
        _s.nav.go(const PlansRoute());
      }
      return;
    }
    _s.nav.go(route);
  }

  void _playFocusedPlace(int placeIdx) {
    final places = _s.course.places;
    if (placeIdx < 0 || placeIdx >= places.length) return;
    final place = places[placeIdx];
    _s.haptics.tick();
    if (!placeInPlan(place, places, widget.entitlements)) {
      _openPlace(placeIdx);
      return;
    }
    if (place.stories.isEmpty) {
      _openPlace(placeIdx);
      return;
    }
    final nextId = nextUnheardStory(_s.progress, place);
    if (nextId != null) {
      if (!storyInPlan(nextId, places, widget.entitlements)) {
        _openPlace(placeIdx);
        return;
      }
      _s.nav.go(StoryRoute(nextId));
      return;
    }
    final calls = _s.course.callsFor(place.id);
    if (calls.isNotEmpty) {
      _s.nav.go(CallRoute(place.id));
    } else {
      _s.nav.go(const ReviewRoute());
    }
  }

  List<TodayEntry> _plan() => [
    for (final e in todayPlan(
      progress: _s.progress,
      course: _s.course,
      clock: _s.clock,
    ))
      if (!e.review || widget.reviewTitle != null) e,
  ];

  PictureRef? _pictureRefFor(TodayEntry entry, Place? place) {
    final route = entry.route;
    return pickUpNextPictureRef(
      entry: entry,
      course: _s.course,
      progress: _s.progress,
      place: place,
      storyScene: route is StoryRoute ? _storyScenes[route.id] : null,
    );
  }

  PictureRef? _pictureRefForPlace(Place place) {
    final pairs = _s.course.pairs;
    if (pairs.isEmpty) return null;
    final language = _s.course.language;
    final heroStoryId = _heroStoryIdForPlace(place);
    final preferredScene = heroStoryId != null
        ? _storyScenes[heroStoryId]
        : null;
    if (preferredScene != null) {
      final target = normalizeSceneName(language, preferredScene);
      if (target.isNotEmpty) {
        for (final pair in pairs) {
          final scene = pair.yes.scene ?? pair.scene;
          if (normalizeSceneName(language, scene) == target) {
            return PictureRef.of(pair, pair.yes);
          }
        }
      }
    }
    for (final pair in pairs) {
      final scene = pair.yes.scene ?? pair.scene;
      if (sceneMatchesPlace(language, scene, place)) {
        return PictureRef.of(pair, pair.yes);
      }
    }
    return null;
  }

  double _contentOpacity(Animation<double>? sec, NocheMotionData motion) {
    if (sec == null) return 1.0;
    return switch (sec.status) {
      AnimationStatus.dismissed => 1.0,
      AnimationStatus.forward => MapMotion.outgoingFadeOpacity(
        routeValue: sec.value,
        motion: motion,
        totalDuration: motion.pageIn,
      ),
      AnimationStatus.completed => 0.0,
      AnimationStatus.reverse => MapMotion.backReturnOpacity(
        reverseProgress: 1.0 - sec.value,
        motion: motion,
      ),
    };
  }

  ({double opacity, double dy}) _coldSlotMotion(
    NocheMotionData motion,
    Duration delay, {
    bool isPlayDisc = false,
  }) {
    if (_coldLoadPending) {
      return (opacity: 0.0, dy: motion.reduced ? 0.0 : motion.row);
    }
    if (!_coldLoadActive) {
      return (opacity: 1.0, dy: 0.0);
    }
    if (_coldLoadReduced) {
      if (isPlayDisc) return (opacity: 1.0, dy: 0.0);
      final p = motion.enter.transform(
        _coldLoadController.value.clamp(0.0, 1.0),
      );
      return (opacity: p.clamp(0.0, 1.0), dy: 0.0);
    }
    final totalUs = (MapMotion.loadPlayAfter + motion.move).inMicroseconds
        .toDouble();
    final elapsedUs = _coldLoadController.value * totalUs;
    final p = MapMotion.segmentProgressUs(
      elapsedUs: elapsedUs,
      start: delay,
      duration: motion.move,
      curve: motion.enter,
    );
    return (opacity: p, dy: motion.row * (1.0 - p));
  }

  ({double opacity, double dy}) _herePillMotion(NocheMotionData motion) {
    if (!_hereRising) {
      final v = _hereController.value.clamp(0.0, 1.0);
      if (v >= 1.0) return (opacity: 1.0, dy: 0.0);
      if (v <= 0.0) return (opacity: 0.0, dy: 0.0);
      final fadeOut = motion.exit.transform((1.0 - v).clamp(0.0, 1.0));
      return (opacity: (1.0 - fadeOut).clamp(0.0, 1.0), dy: 0.0);
    }
    final totalUs = (MapMotion.hereRiseAfter + motion.move).inMicroseconds
        .toDouble();
    final elapsedUs = _hereController.value * totalUs;
    final p = MapMotion.segmentProgressUs(
      elapsedUs: elapsedUs,
      start: MapMotion.hereRiseAfter,
      duration: motion.move,
      curve: motion.enter,
    );
    return (opacity: p, dy: motion.row * (1.0 - p));
  }

  ({double opacity, double scale}) _destPillMotion(NocheMotionData motion) {
    final v = _destController.value.clamp(0.0, 1.0);
    final double p;
    if (_destExiting) {
      p = (1.0 - motion.exit.transform((1.0 - v).clamp(0.0, 1.0))).clamp(
        0.0,
        1.0,
      );
    } else {
      p = motion.enter.transform(v).clamp(0.0, 1.0);
    }
    final scale =
        MapMotion.destEnterScale + (1.0 - MapMotion.destEnterScale) * p;
    return (opacity: p, scale: scale);
  }

  ({double opacity, double dy}) _lockPillMotion(NocheMotionData motion) {
    final enterDur = _lockReduced ? motion.quick : motion.press;
    final holdDur = motion.lockHold;
    final exitDur = _lockReduced ? motion.quick : motion.move;
    final total = enterDur + holdDur + exitDur;
    final totalUs = total.inMicroseconds.toDouble();
    if (totalUs <= 0) return (opacity: 0.0, dy: 0.0);
    final elapsedUs = _lockController.value * totalUs;
    final enterUs = enterDur.inMicroseconds.toDouble();
    final holdEndUs = (enterDur + holdDur).inMicroseconds.toDouble();
    if (elapsedUs < enterUs) {
      final p = MapMotion.segmentProgressUs(
        elapsedUs: elapsedUs,
        start: Duration.zero,
        duration: enterDur,
        curve: motion.enter,
      );
      return (
        opacity: p,
        dy: _lockReduced ? 0.0 : MapMotion.lockDropOffset * (1.0 - p),
      );
    }
    if (elapsedUs <= holdEndUs) {
      return (opacity: 1.0, dy: 0.0);
    }
    final p = MapMotion.segmentProgressUs(
      elapsedUs: elapsedUs,
      start: enterDur + holdDur,
      duration: exitDur,
      curve: motion.exit,
    );
    return (
      opacity: (1.0 - p).clamp(0.0, 1.0),
      dy: _lockReduced ? 0.0 : MapMotion.lockDropOffset * p,
    );
  }

  ({
    double outgoingOpacity,
    double incomingOpacity,
    double incomingDy,
    double playOpacity,
    double playDy,
  })
  _cardSwapMotion(NocheMotionData motion) {
    if (!_cardSwapping) {
      return (
        outgoingOpacity: 0.0,
        incomingOpacity: 1.0,
        incomingDy: 0.0,
        playOpacity: 1.0,
        playDy: 0.0,
      );
    }
    if (_cardSwapReduced) {
      final v = _cardController.value.clamp(0.0, 1.0);
      final outP = motion.exit.transform(v).clamp(0.0, 1.0);
      final inP = motion.enter.transform(v).clamp(0.0, 1.0);
      return (
        outgoingOpacity: (1.0 - outP).clamp(0.0, 1.0),
        incomingOpacity: inP,
        incomingDy: 0.0,
        playOpacity: 1.0,
        playDy: 0.0,
      );
    }
    final totalDuration = _cardSwapToPlace
        ? (motion.followAfter + motion.nextDelay + motion.move)
        : (motion.followAfter + motion.move);
    final totalUs = totalDuration.inMicroseconds.toDouble();
    final elapsedUs = _cardController.value * totalUs;
    final outP = MapMotion.segmentProgressUs(
      elapsedUs: elapsedUs,
      start: Duration.zero,
      duration: motion.press,
      curve: motion.exit,
    );
    final inP = MapMotion.segmentProgressUs(
      elapsedUs: elapsedUs,
      start: motion.followAfter,
      duration: motion.move,
      curve: motion.enter,
    );
    final playP = _cardSwapToPlace
        ? MapMotion.segmentProgressUs(
            elapsedUs: elapsedUs,
            start: motion.followAfter + motion.nextDelay,
            duration: motion.move,
            curve: motion.enter,
          )
        : 1.0;
    return (
      outgoingOpacity: (1.0 - outP).clamp(0.0, 1.0),
      incomingOpacity: inP,
      incomingDy: motion.row * (1.0 - inP),
      playOpacity: playP,
      playDy: _cardSwapToPlace ? motion.row * (1.0 - playP) : 0.0,
    );
  }

  double _pillTopForStop(
    int k,
    MapCamera cam, {
    required double pillHeight,
    required double minTop,
  }) {
    final scale = cam.mapHeight / mapH;
    final stopY = _map.stopOnPicture(k).sy * scale;
    final defaultTop = stopY - _pillLift;
    final houseTopPic = _map.houseTopOnPicture(k);
    if (houseTopPic == null) return defaultTop;
    final aboveHouse = houseTopPic * scale - pillHeight - NocheSize.grid;
    return math.max(minTop, math.min(defaultTop, aboveHouse));
  }

  double _pillStartForStop(int k, MapCamera cam, double contentW) {
    final stopX = _map.stopOnPicture(k).sx * cam.mapWidth / mapW;
    final maxStart = math.max(0.0, contentW - _pillAnchorWidth);
    return (stopX - _pillAnchorWidth / 2).clamp(0.0, maxStart);
  }

  Widget _buildCardBody({
    required _CardSnapshot snapshot,
    required bool interactive,
    required List<Place> places,
    required Language lang,
    required bool allowHero,
    double playDiscOpacity = 1.0,
    double playDiscDy = 0.0,
  }) {
    final placeIdx = snapshot.placeIndex;
    if (placeIdx != null && placeIdx >= 0 && placeIdx < places.length) {
      final place = places[placeIdx];
      final heard = storiesPlayed(_s.progress, place);
      final nextId = nextUnheardStory(_s.progress, place);
      final heroStoryId = _heroStoryIdForPlace(place);
      final windowTag = interactive && allowHero && heroStoryId != null
          ? MapMotion.storyWindowTag(heroStoryId)
          : null;
      final nextIdx = nextId == null ? -1 : place.stories.indexOf(nextId);
      final nextMeta = nextId != null ? _s.course.meta(nextId) : null;
      final calls = _s.course.callsFor(place.id);
      final mainCall = calls.isNotEmpty
          ? calls.firstWhere((c) => c.isMain, orElse: () => calls.first)
          : null;
      return _FocusedPlaceCardBody(
        interactive: interactive,
        place: place,
        totalPlaces: places.length,
        heardCount: heard,
        language: lang,
        pictures: _s.pictures,
        pictureRef: _pictureRefForPlace(place),
        windowTag: windowTag,
        nextStoryId: nextId,
        nextStoryNumber: nextIdx >= 0 ? nextIdx + 1 : null,
        nextStoryMeta: nextMeta,
        mainCall: mainCall,
        playDiscOpacity: interactive ? playDiscOpacity : 1.0,
        playDiscDy: interactive ? playDiscDy : 0.0,
        onOpenPlace: interactive
            ? () {
                _s.haptics.tick();
                _openPlace(placeIdx);
              }
            : null,
        onPlay: interactive ? () => _playFocusedPlace(placeIdx) : null,
      );
    }

    final entry = snapshot.entry!;
    final route = entry.route;
    final windowTag = interactive && allowHero && route is StoryRoute
        ? MapMotion.storyWindowTag(route.id)
        : null;
    return _UpNextCardBody(
      interactive: interactive,
      entry: entry,
      thenLine: snapshot.thenLine,
      places: places,
      language: lang,
      reviewTitle: widget.reviewTitle,
      pictures: _s.pictures,
      pictureRef: _pictureRefFor(
        entry,
        route is StoryRoute ? _placeFor(route.id, places) : null,
      ),
      windowTag: windowTag,
      playDiscOpacity: interactive ? playDiscOpacity : 1.0,
      playDiscDy: interactive ? playDiscDy : 0.0,
      onPlay: interactive ? () => _start(entry) : null,
      onOpenPlace: interactive
          ? (idx) {
              _s.haptics.tick();
              _openPlace(idx);
            }
          : null,
    );
  }

  double _currentOverlayOpacity() =>
      (widget.overlayOpacity?.value ?? 1.0).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final places = _s.course.places;
    final plan = _baked ? _plan() : const <TodayEntry>[];
    final lang = _s.course.language;
    final foot = NocheSize.aboveTabBar + pad.bottom;
    final motion = MapMotion.resolve(
      context,
      serviceReduceMotion: _s.reduceMotion,
    );
    final secondaryAnimation = ModalRoute.of(context)?.secondaryAnimation;
    final overlayListenable = widget.overlayOpacity;
    final suppressHeroForServiceReduce =
        _s.reduceMotion && !NocheMotion.of(context).reduced;
    final allowHero =
        !suppressHeroForServiceReduce && TickerMode.valuesOf(context).enabled;

    final _CardSnapshot? activeSnapshot;
    if (_baked &&
        _focusedPlaceIndex != null &&
        _focusedPlaceIndex! >= 0 &&
        _focusedPlaceIndex! < places.length) {
      activeSnapshot = _CardSnapshot.place(placeIndex: _focusedPlaceIndex!);
    } else if (plan.isNotEmpty) {
      activeSnapshot = _CardSnapshot.upNext(
        entry: plan.first,
        thenLine: upNextThenLine(plan),
      );
    } else {
      activeSnapshot = null;
    }

    final body = DefaultTextStyle.merge(
      style: NocheType.body.copyWith(color: NocheColors.text),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _mapViewport(
            context,
            foot: foot,
            pad: pad,
            places: places,
            lang: lang,
            motion: motion,
            overlayListenable: overlayListenable,
          ),
          PositionedDirectional(
            top: pad.top + 16,
            start: 16,
            end: 16,
            child: AnimatedBuilder(
              animation: overlayListenable == null
                  ? _coldLoadController
                  : Listenable.merge([_coldLoadController, overlayListenable]),
              builder: (context, child) {
                final slot = _coldSlotMotion(motion, MapMotion.loadChipsAfter);
                return Transform.translate(
                  key: const Key('map-load-chips'),
                  offset: Offset(0, slot.dy),
                  child: Opacity(
                    opacity: (_currentOverlayOpacity() * slot.opacity).clamp(
                      0.0,
                      1.0,
                    ),
                    child: child,
                  ),
                );
              },
              child: _TopChips(
                languageName: lang.englishName,
                // Level badge omitted until coqui/requests/101-feature-map-needs-coqui-contracts-story-scene-and-level.md lands.
                streak: _s.progress.streak,
                onLanguageTap: () {
                  _s.haptics.tick();
                  _s.nav.go(const LanguagesRoute());
                },
              ),
            ),
          ),
          if (widget.showPerf && _perf != null)
            PositionedDirectional(
              top: pad.top + 16 + NocheSize.touch + NocheSize.grid,
              end: 16,
              child: MapPerfChip(_perf),
            ),
          if (activeSnapshot != null)
            PositionedDirectional(
              start: 16,
              end: 16,
              bottom: foot,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _cardController,
                  _cardDragController,
                  _coldLoadController,
                  ?overlayListenable,
                ]),
                builder: (context, _) {
                  final coldCard = _coldSlotMotion(
                    motion,
                    MapMotion.loadCardAfter,
                  );
                  final coldPlay = _coldSlotMotion(
                    motion,
                    MapMotion.loadPlayAfter,
                    isPlayDisc: true,
                  );
                  final swap = _cardSwapMotion(motion);
                  final playOpacity = (coldPlay.opacity * swap.playOpacity)
                      .clamp(0.0, 1.0);
                  final playDy = coldPlay.dy + swap.playDy;
                  final activeBody = _buildCardBody(
                    snapshot: activeSnapshot!,
                    interactive: true,
                    places: places,
                    lang: lang,
                    allowHero: allowHero,
                    playDiscOpacity: playOpacity,
                    playDiscDy: playDy,
                  );
                  final stack = Stack(
                    alignment: AlignmentDirectional.topCenter,
                    children: [
                      if (_outgoingCard != null && _cardSwapping)
                        PositionedDirectional(
                          top: 0,
                          start: 0,
                          end: 0,
                          child: IgnorePointer(
                            child: ExcludeSemantics(
                              child: Opacity(
                                opacity: swap.outgoingOpacity,
                                child: _buildCardBody(
                                  snapshot: _outgoingCard!,
                                  interactive: false,
                                  places: places,
                                  lang: lang,
                                  allowHero: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Transform.translate(
                        key: const Key('map-card-motion'),
                        offset: Offset(0, swap.incomingDy),
                        child: Opacity(
                          opacity: swap.incomingOpacity,
                          child: activeBody,
                        ),
                      ),
                    ],
                  );
                  final Widget sizedStack = motion.reduced
                      ? stack
                      : AnimatedSize(
                          duration: motion.move,
                          curve: motion.travel,
                          alignment: AlignmentDirectional.topCenter,
                          clipBehavior: Clip.hardEdge,
                          child: stack,
                        );
                  Widget card = Transform.translate(
                    key: const Key('map-card-drag'),
                    offset: Offset(0, _cardDragDy),
                    child: NocheCard(
                      key: const Key('up-next-card'),
                      padding: EdgeInsetsDirectional.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          NocheSize.cardRadius - 1,
                        ),
                        child: sizedStack,
                      ),
                    ),
                  );
                  final focusedPlaceIdx =
                      (activeSnapshot.placeIndex != null &&
                          activeSnapshot.placeIndex! >= 0 &&
                          activeSnapshot.placeIndex! < places.length)
                      ? activeSnapshot.placeIndex
                      : null;
                  card = Semantics(
                    customSemanticsActions: focusedPlaceIdx != null
                        ? {
                            CustomSemanticsAction(
                              label: MapWording.cardActionOpen,
                            ): () {
                              _s.haptics.tick();
                              _openPlace(focusedPlaceIdx);
                            },
                            CustomSemanticsAction(
                              label: MapWording.cardActionShowUpNext,
                            ): () {
                              _s.haptics.tick();
                              _switchCardToUpNext();
                            },
                          }
                        : null,
                    child: GestureDetector(
                      behavior: focusedPlaceIdx != null
                          ? HitTestBehavior.opaque
                          : HitTestBehavior.deferToChild,
                      dragStartBehavior: DragStartBehavior.down,
                      onTap: focusedPlaceIdx != null
                          ? () {
                              _s.haptics.tick();
                              _openPlace(focusedPlaceIdx);
                            }
                          : null,
                      onVerticalDragStart: focusedPlaceIdx != null
                          ? (_) {
                              _cardDragController.stop();
                              _cardDragging = true;
                              _cardDragStartDy = _cardDragDy;
                            }
                          : null,
                      onVerticalDragUpdate: focusedPlaceIdx != null
                          ? (details) {
                              if (!_cardDragging) return;
                              setState(() {
                                _cardDragDy = (_cardDragDy + details.delta.dy)
                                    .clamp(
                                      MapMotion.cardDragUpLimit,
                                      MapMotion.cardDragDownLimit,
                                    );
                              });
                            }
                          : null,
                      onVerticalDragEnd: focusedPlaceIdx != null
                          ? (_) => _finishCardDrag(focusedPlaceIdx, motion)
                          : null,
                      onVerticalDragCancel: focusedPlaceIdx != null
                          ? () => _finishCardDrag(focusedPlaceIdx, motion)
                          : null,
                      child: card,
                    ),
                  );
                  return Transform.translate(
                    key: const Key('map-load-card'),
                    offset: Offset(0, coldCard.dy),
                    child: Opacity(
                      opacity: (_currentOverlayOpacity() * coldCard.opacity)
                          .clamp(0.0, 1.0),
                      child: card,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );

    return ColoredBox(
      key: const Key('map-screen'),
      color: NocheColors.ground,
      child: AnimatedBuilder(
        animation: secondaryAnimation ?? kAlwaysDismissedAnimation,
        builder: (context, child) => Opacity(
          key: const Key('map-motion-content'),
          opacity: _contentOpacity(secondaryAnimation, motion),
          child: child,
        ),
        child: body,
      ),
    );
  }

  Place? _placeFor(String storyId, List<Place> places) {
    final idx = placeIndexForStory(places, storyId);
    return idx == null ? null : places[idx];
  }

  Widget _mapViewport(
    BuildContext context, {
    required double foot,
    required EdgeInsets pad,
    required List<Place> places,
    required Language lang,
    required NocheMotionData motion,
    required ValueListenable<double>? overlayListenable,
  }) {
    final ambientDir = Directionality.of(context);
    final minPillTop = pad.top + 16 + NocheSize.touch + NocheSize.grid;

    return LayoutBuilder(
      builder: (context, c) {
        _viewport = c.biggest;
        _dpr = MediaQuery.devicePixelRatioOf(context);
        _bottomPad = math.max(foot + 220, _viewport.height * 0.51);
        final cam = _cameraForStop(
          _baked ? _hereStopIndex : 0,
          _viewport,
          _dpr,
          _bottomPad,
        );
        final availWidth = mapW * cam.deviceScale / _dpr;
        final contentW = math.max(_viewport.width, cam.mapWidth);
        final contentH = cam.mapHeight + _bottomPad;
        final destIdx = _destPlaceIndex;
        final lockIdx = _lockPlaceIndex;

        return NocheLtr(
          child: SingleChildScrollView(
            controller: _scrollV,
            child: SingleChildScrollView(
              controller: _scrollH,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: contentW,
                height: contentH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      width: cam.mapWidth,
                      height: cam.mapHeight,
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: availWidth),
                          child: PixelView(
                            pixels: _map.pix,
                            width: mapW,
                            height: mapH,
                            repaint: _frames,
                            onTapPixel: _onTapPixel,
                            semanticLabel: MapWording.courseMapSemantic,
                          ),
                        ),
                      ),
                    ),
                    if (_baked)
                      PositionedDirectional(
                        start: _pillStartForStop(_hereStopIndex, cam, contentW),
                        width: _pillAnchorWidth,
                        top: _pillTopForStop(
                          _hereStopIndex,
                          cam,
                          pillHeight: _herePillHeight,
                          minTop: minPillTop,
                        ),
                        child: Center(
                          child: Directionality(
                            textDirection: ambientDir,
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _hereController,
                                _coldLoadController,
                                ?overlayListenable,
                              ]),
                              builder: (context, child) {
                                final here = _herePillMotion(motion);
                                final cold = _coldSlotMotion(
                                  motion,
                                  MapMotion.loadHereAfter,
                                );
                                final op =
                                    (_currentOverlayOpacity() *
                                            cold.opacity *
                                            here.opacity)
                                        .clamp(0.0, 1.0);
                                return ExcludeSemantics(
                                  excluding: op == 0.0,
                                  child: Transform.translate(
                                    key: const Key('map-here-motion'),
                                    offset: Offset(0, cold.dy + here.dy),
                                    child: Opacity(opacity: op, child: child),
                                  ),
                                );
                              },
                              child: const _YouAreHerePill(
                                key: Key('you-are-here'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_baked &&
                        destIdx != null &&
                        destIdx >= 0 &&
                        destIdx < places.length)
                      PositionedDirectional(
                        start: _pillStartForStop(destIdx, cam, contentW),
                        width: _pillAnchorWidth,
                        top: _pillTopForStop(
                          destIdx,
                          cam,
                          pillHeight: _flatPillHeight,
                          minTop: minPillTop,
                        ),
                        child: Center(
                          child: Directionality(
                            textDirection: ambientDir,
                            child: AnimatedBuilder(
                              animation: overlayListenable == null
                                  ? _destController
                                  : Listenable.merge([
                                      _destController,
                                      overlayListenable,
                                    ]),
                              builder: (context, child) {
                                final dest = _destPillMotion(motion);
                                final op =
                                    (_currentOverlayOpacity() * dest.opacity)
                                        .clamp(0.0, 1.0);
                                return ExcludeSemantics(
                                  excluding: op == 0.0,
                                  child: Transform.scale(
                                    key: const Key('map-dest-motion'),
                                    scale: dest.scale,
                                    child: Opacity(opacity: op, child: child),
                                  ),
                                );
                              },
                              child: _DestPlacePill(
                                key: const Key('map-dest-pill'),
                                placeName: places[destIdx].name,
                                language: lang,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_baked &&
                        lockIdx != null &&
                        lockIdx >= 0 &&
                        lockIdx < places.length)
                      PositionedDirectional(
                        start: _pillStartForStop(lockIdx, cam, contentW),
                        width: _pillAnchorWidth,
                        top: _pillTopForStop(
                          lockIdx,
                          cam,
                          pillHeight: _flatPillHeight,
                          minTop: minPillTop,
                        ),
                        child: Center(
                          child: Directionality(
                            textDirection: ambientDir,
                            child: AnimatedBuilder(
                              animation: overlayListenable == null
                                  ? _lockController
                                  : Listenable.merge([
                                      _lockController,
                                      overlayListenable,
                                    ]),
                              builder: (context, child) {
                                final lock = _lockPillMotion(motion);
                                final op =
                                    (_currentOverlayOpacity() * lock.opacity)
                                        .clamp(0.0, 1.0);
                                return ExcludeSemantics(
                                  excluding: op == 0.0,
                                  child: Transform.translate(
                                    key: const Key('map-lock-motion'),
                                    offset: Offset(0, lock.dy),
                                    child: Opacity(opacity: op, child: child),
                                  ),
                                );
                              },
                              child: _LockPlacePill(
                                key: const Key('map-lock-pill'),
                                prevPlaceName: lockIdx > 0
                                    ? places[lockIdx - 1].name
                                    : null,
                                language: lang,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Chooses a matching [PictureRef] for the Up next card thumbnail, or `null`
/// to show the placeholder icon when no review pair matches cleanly.
@visibleForTesting
PictureRef? pickUpNextPictureRef({
  required TodayEntry entry,
  required CourseCatalog course,
  required ProgressStore progress,
  Place? place,
  String? storyScene,
}) {
  final pairs = course.pairs;
  if (pairs.isEmpty) return null;
  final language = course.language;
  if (entry.review) {
    for (final word in progress.due(Skill.ear)) {
      final pair = course.pairFor(word);
      if (pair != null) return PictureRef.of(pair, pair.yes);
    }
    return null;
  }
  if (entry.route is StoryRoute && storyScene != null) {
    final target = normalizeSceneName(language, storyScene);
    if (target.isEmpty) return null;
    for (final pair in pairs) {
      if (normalizeSceneName(language, pair.yes.scene ?? pair.scene) ==
          target) {
        return PictureRef.of(pair, pair.yes);
      }
    }
    return null;
  }
  if (place != null) {
    for (final pair in pairs) {
      final scene = pair.yes.scene ?? pair.scene;
      if (sceneMatchesPlace(language, scene, place)) {
        return PictureRef.of(pair, pair.yes);
      }
    }
  }
  return null;
}

class _TopChips extends StatelessWidget {
  const _TopChips({
    required this.languageName,
    required this.streak,
    required this.onLanguageTap,
  });

  final String languageName;
  final int streak;
  final VoidCallback onLanguageTap;

  @override
  Widget build(BuildContext context) {
    final streakLabel = MapWording.streakDays(streak);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Pressable(
          key: const Key('language-chip'),
          onPressed: onLanguageTap,
          semanticLabel: MapWording.changeLanguageSemantic(languageName),
          builder: (context, _) => Container(
            height: NocheSize.touch,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 12, 0),
            decoration: BoxDecoration(
              color: NocheColors.panel,
              border: Border.all(color: NocheColors.line, width: 1),
              borderRadius: BorderRadius.circular(NocheSize.pillRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languageName,
                  maxLines: 1,
                  softWrap: false,
                  style: NocheType.buttonStrong.copyWith(
                    color: NocheColors.text,
                  ),
                ),
                const SizedBox(width: NocheSize.grid),
                const NocheIcon(
                  NocheIcons.chevronDown,
                  size: 16,
                  color: NocheColors.text,
                ),
              ],
            ),
          ),
        ),
        if (streak > 0)
          Semantics(
            label: streakLabel,
            readOnly: true,
            child: ExcludeSemantics(
              child: Container(
                key: const Key('streak-chip'),
                height: NocheSize.touch,
                padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 16, 0),
                decoration: BoxDecoration(
                  color: NocheColors.panel,
                  border: Border.all(color: NocheColors.line, width: 1),
                  borderRadius: BorderRadius.circular(NocheSize.pillRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Noche-Mapa.dc.html:23 and Noche-Yo.dc.html:31 stroke the
                    // 18 px outline flame with #E69F00 (NocheColors.next).
                    const NocheIcon(
                      NocheIcons.flame,
                      size: 18,
                      color: NocheColors.next,
                    ),
                    const SizedBox(width: NocheSize.grid),
                    NocheLtr(
                      child: Text(
                        streakLabel,
                        maxLines: 1,
                        softWrap: false,
                        style: NocheType.button.copyWith(
                          color: NocheColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _YouAreHerePill extends StatelessWidget {
  const _YouAreHerePill({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: NocheColors.text,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  MapWording.youAreHere,
                  maxLines: 1,
                  softWrap: false,
                  style: NocheType.buttonStrong.copyWith(
                    color: NocheColors.ground,
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -6),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: const SizedBox.square(
                dimension: 12,
                child: ColoredBox(color: NocheColors.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestPlacePill extends StatelessWidget {
  const _DestPlacePill({
    super.key,
    required this.placeName,
    required this.language,
  });

  final String placeName;
  final Language language;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: 40,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: NocheColors.panel,
          border: Border.all(color: NocheColors.line, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                placeName,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                locale: Locale(language.code),
                style: NocheType.forScript(
                  NocheType.buttonStrong,
                  language.script,
                ).copyWith(color: NocheColors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockPlacePill extends StatelessWidget {
  const _LockPlacePill({
    super.key,
    required this.prevPlaceName,
    required this.language,
  });

  final String? prevPlaceName;
  final Language language;

  @override
  Widget build(BuildContext context) {
    final prev = prevPlaceName;
    final label = prev != null
        ? MapWording.afterPlace(prev)
        : MapWording.notBuiltYet;
    final baseStyle = NocheType.buttonStrong.copyWith(color: NocheColors.text);
    final placeStyle = NocheType.forScript(
      NocheType.buttonStrong,
      language.script,
    ).copyWith(color: NocheColors.text);

    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        label: label,
        child: ExcludeSemantics(
          child: Container(
            height: 40,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: NocheColors.panel,
              border: Border.all(color: NocheColors.line, width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NocheIcon(NocheIcons.lock, size: 18, color: NocheColors.text),
                const SizedBox(width: NocheSize.grid),
                Flexible(
                  child: prev != null
                      ? Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: MapWording.afterPlacePrefix,
                                style: baseStyle,
                              ),
                              TextSpan(
                                text: prev,
                                locale: Locale(language.code),
                                style: placeStyle,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          MapWording.notBuiltYet,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: baseStyle,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpNextCardBody extends StatelessWidget {
  const _UpNextCardBody({
    required this.interactive,
    required this.entry,
    required this.thenLine,
    required this.places,
    required this.language,
    required this.reviewTitle,
    required this.pictures,
    required this.pictureRef,
    required this.windowTag,
    required this.playDiscOpacity,
    required this.playDiscDy,
    required this.onPlay,
    required this.onOpenPlace,
  });

  final bool interactive;
  final TodayEntry entry;
  final String? thenLine;
  final List<Place> places;
  final Language language;
  final String? reviewTitle;
  final PictureSource pictures;
  final PictureRef? pictureRef;
  final Object? windowTag;
  final double playDiscOpacity;
  final double playDiscDy;
  final VoidCallback? onPlay;
  final ValueChanged<int>? onOpenPlace;

  static const double _thumbSize = 72;

  @override
  Widget build(BuildContext context) {
    final route = entry.route;
    final placeIdx = !entry.review && route is StoryRoute
        ? placeIndexForStory(places, route.id)
        : null;
    final place = placeIdx != null ? places[placeIdx] : null;
    final locale = Locale(language.code);
    final titleText = entry.review
        ? (reviewTitle ?? MapWording.reviewTitle)
        : (entry.title ?? '');
    final titleStyle =
        (entry.review
                ? NocheType.cardTitle
                : NocheType.forScript(NocheType.cardTitle, language.script))
            .copyWith(color: NocheColors.text);
    final metaStyle = NocheType.bodySmall.copyWith(
      fontSize: 14,
      height: 16 / 14,
      color: NocheColors.label,
    );
    final metaText = entry.review
        ? entry.subtitle
        : MapWording.lineWithMinutes(upNextKind(entry), entry.minutes);

    final details = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: _thumbSize,
          child: MapSceneWindow(
            key: interactive ? const Key('up-next-window') : null,
            pictures: pictures,
            pictureRef: pictureRef,
            borderRadius: NocheSize.tileRadius,
            tag: interactive ? windowTag : null,
            placeholder: ColoredBox(
              color: NocheColors.chip,
              child: Center(
                child: NocheIcon(
                  entry.review ? NocheIcons.words : NocheIcons.map,
                  size: 28,
                  color: NocheColors.label,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: place != null
                          ? MapWording.upNextWithPlacePrefix
                          : MapWording.upNext,
                      style: NocheType.label.copyWith(color: NocheColors.label),
                    ),
                    if (place != null)
                      TextSpan(
                        text: place.name.toUpperCase(),
                        locale: locale,
                        style: NocheType.forScript(
                          NocheType.label,
                          language.script,
                        ).copyWith(color: NocheColors.label),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: NocheSize.grid),
              Text(
                titleText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                locale: entry.review ? null : locale,
                style: titleStyle,
              ),
              const SizedBox(height: NocheSize.grid),
              Text(
                metaText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: metaStyle,
              ),
            ],
          ),
        ),
      ],
    );

    final tappableDetails = placeIdx != null && interactive
        ? Pressable(
            key: const Key('up-next-place'),
            scaleOnPress: false,
            onPressed: () => onOpenPlace?.call(placeIdx),
            builder: (context, _) => details,
          )
        : details;

    final playDisc = NochePlayDisc(
      key: interactive ? const Key('up-next-play') : null,
      size: NocheSize.disc,
      onPressed: onPlay ?? () {},
      semanticLabel: entry.review
          ? MapWording.startReviewSemantic
          : MapWording.playStorySemantic(titleText),
    );

    final wrappedPlay = interactive
        ? Transform.translate(
            key: const Key('map-load-play'),
            offset: Offset(0, playDiscDy),
            child: Opacity(opacity: playDiscOpacity, child: playDisc),
          )
        : playDisc;

    return Padding(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: tappableDetails),
              const SizedBox(width: 16),
              wrappedPlay,
            ],
          ),
          if (thenLine != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsetsDirectional.only(top: 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: NocheColors.line, width: 1),
                ),
              ),
              child: Text(
                thenLine!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: metaStyle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FocusedPlaceCardBody extends StatelessWidget {
  const _FocusedPlaceCardBody({
    required this.interactive,
    required this.place,
    required this.totalPlaces,
    required this.heardCount,
    required this.language,
    required this.pictures,
    required this.pictureRef,
    required this.windowTag,
    required this.nextStoryId,
    required this.nextStoryNumber,
    required this.nextStoryMeta,
    required this.mainCall,
    required this.playDiscOpacity,
    required this.playDiscDy,
    required this.onOpenPlace,
    required this.onPlay,
  });

  final bool interactive;
  final Place place;
  final int totalPlaces;
  final int heardCount;
  final Language language;
  final PictureSource pictures;
  final PictureRef? pictureRef;
  final Object? windowTag;
  final String? nextStoryId;
  final int? nextStoryNumber;
  final StoryMeta? nextStoryMeta;
  final CallBrief? mainCall;
  final double playDiscOpacity;
  final double playDiscDy;
  final VoidCallback? onOpenPlace;
  final VoidCallback? onPlay;

  static const double _thumbSize = 72;

  @override
  Widget build(BuildContext context) {
    final locale = Locale(language.code);
    final total = place.stories.length;
    final labelStyle = NocheType.label.copyWith(color: NocheColors.label);
    final titleStyle = NocheType.forScript(
      NocheType.cardTitle,
      language.script,
    ).copyWith(color: NocheColors.text);
    final metaStyle = NocheType.bodySmall.copyWith(
      fontSize: 14,
      height: 16 / 14,
      color: NocheColors.label,
    );

    final arrowCircle = Container(
      width: NocheSize.touch,
      height: NocheSize.touch,
      alignment: AlignmentDirectional.center,
      decoration: BoxDecoration(
        color: NocheColors.ground,
        border: Border.all(color: NocheColors.line, width: 1),
        shape: BoxShape.circle,
      ),
      child: Transform.flip(
        flipY: true,
        child: const NocheIcon(
          NocheIcons.chevronDown,
          size: 24,
          color: NocheColors.text,
        ),
      ),
    );

    final openButton = interactive
        ? Pressable(
            key: const Key('place-card-open'),
            semanticLabel: MapWording.openPlaceSemantic(place.name),
            onPressed: onOpenPlace,
            builder: (context, _) => arrowCircle,
          )
        : arrowCircle;

    final topRow = Row(
      key: interactive ? const Key('up-next-place') : null,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: _thumbSize,
          child: MapSceneWindow(
            key: interactive ? const Key('up-next-window') : null,
            pictures: pictures,
            pictureRef: pictureRef,
            borderRadius: NocheSize.tileRadius,
            tag: interactive ? windowTag : null,
            placeholder: const ColoredBox(
              color: NocheColors.chip,
              child: Center(
                child: NocheIcon(
                  NocheIcons.map,
                  size: 28,
                  color: NocheColors.label,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NocheLtr(
                child: Text(
                  MapWording.placeCounter(place.n, totalPlaces).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
              const SizedBox(height: NocheSize.grid),
              Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                locale: locale,
                style: titleStyle,
              ),
              const SizedBox(height: NocheSize.grid),
              NocheLtr(
                child: Text(
                  total == 0
                      ? MapWording.notBuiltYet
                      : MapWording.storiesHeard(heardCount, total),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        openButton,
      ],
    );

    Widget? bottomSection;
    if (total > 0) {
      final hasNextStory = nextStoryId != null && nextStoryNumber != null;
      final call = mainCall;
      final String eyebrowText;
      final Widget titleWidget;
      final int? minutes;
      final NocheIconData discIcon;
      final String discSemantic;

      if (hasNextStory) {
        final nextTitle = nextStoryMeta?.title ?? nextStoryId!;
        eyebrowText = MapWording.playNextStory(nextStoryNumber!).toUpperCase();
        titleWidget = Text(
          nextTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          locale: locale,
          style: NocheType.forScript(
            NocheType.row,
            language.script,
          ).copyWith(fontWeight: FontWeight.w700, color: NocheColors.text),
        );
        minutes = nextStoryMeta?.minutes;
        discIcon = NocheIcons.play;
        discSemantic = MapWording.playStorySemantic(nextTitle);
      } else if (call != null) {
        final callTitle = MapWording.callPartner(language.partnerName);
        eyebrowText = MapWording.allStoriesHeard.toUpperCase();
        titleWidget = Text(
          callTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: NocheType.row.copyWith(
            fontWeight: FontWeight.w700,
            color: NocheColors.text,
          ),
        );
        minutes = call.minutes > 0 ? call.minutes : null;
        discIcon = NocheIcons.mic;
        discSemantic = callTitle;
      } else {
        eyebrowText = MapWording.allStoriesHeard.toUpperCase();
        titleWidget = Text(
          MapWording.reviewTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: NocheType.row.copyWith(
            fontWeight: FontWeight.w700,
            color: NocheColors.text,
          ),
        );
        minutes = null;
        discIcon = NocheIcons.play;
        discSemantic = MapWording.startReviewSemantic;
      }

      final playDisc = NochePlayDisc(
        key: interactive ? const Key('up-next-play') : null,
        size: NocheSize.disc,
        icon: discIcon,
        onPressed: onPlay ?? () {},
        semanticLabel: discSemantic,
      );

      final wrappedPlay = interactive
          ? Transform.translate(
              key: const Key('map-load-play'),
              offset: Offset(0, playDiscDy),
              child: Opacity(opacity: playDiscOpacity, child: playDisc),
            )
          : playDisc;

      bottomSection = Container(
        padding: const EdgeInsetsDirectional.only(top: 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: NocheColors.line, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NocheLtr(
                    child: Text(
                      eyebrowText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                  ),
                  const SizedBox(height: NocheSize.grid),
                  titleWidget,
                ],
              ),
            ),
            if (minutes != null) ...[
              const SizedBox(width: 16),
              NocheLtr(
                child: Text(
                  MapWording.minutesLabel(minutes),
                  maxLines: 1,
                  softWrap: false,
                  style: NocheType.button.copyWith(color: NocheColors.label),
                ),
              ),
            ],
            const SizedBox(width: 16),
            wrappedPlay,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
      child: Column(
        key: interactive ? const Key('map-place-card') : null,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Center(
              child: Container(
                key: interactive ? const Key('place-card-handle') : null,
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: NocheColors.bar,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          topRow,
          if (bottomSection != null) ...[
            const SizedBox(height: 16),
            bottomSection,
          ],
        ],
      ),
    );
  }
}
