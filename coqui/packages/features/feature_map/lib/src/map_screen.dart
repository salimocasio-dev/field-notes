import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_layout.dart';
import 'package:feature_map/src/map_model.dart';
import 'package:feature_map/src/map_perf.dart';
import 'package:feature_map/src/map_picture.dart';
import 'package:feature_map/src/place_sheet.dart';
import 'package:flutter/scheduler.dart';
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

/// The home map tab (`Noche-Mapa.dc.html`, story N4.1): `ground` ocean behind
/// `MapPicture` (`PixelView` at scale 2), the crisp `"You are here"` pill over
/// the current stop, the language & streak chips at the top, and the `"Up next"`
/// card above the tab bar.
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

  /// For tests: notified whenever the camera centers on the current stop.
  final void Function(MapCamera camera)? onCamera;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _FrameSignal extends ChangeNotifier {
  void fire() => notifyListeners();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  static const String _defaultLevel = 'A1';
  static const double _pillLift = 88;
  static const double _pillAnchorHalfWidth = 100;

  late final MapPicture _map;
  late final MapPerf? _perf =
      widget.perf ?? (widget.showPerf ? MapPerf() : null);
  final _frames = _FrameSignal();
  final _scrollV = ScrollController();
  final _scrollH = ScrollController();
  Ticker? _ticker;
  Duration _last = Duration.zero;
  StreamSubscription<void>? _changes;

  bool _baked = false;
  Size _viewport = Size.zero;
  double _dpr = 1;
  double _bottomPad = 0;
  final Map<String, String?> _storyScenes = {};
  final Set<String> _loadingScenes = {};

  Services get _s => widget.services;

  @override
  void initState() {
    super.initState();
    _map = MapPicture(still: _s.reduceMotion, onHop: _hopSound);
    widget.onPicture?.call(_map);
    _changes = _s.progress.changes.listen((_) => _progressChanged());
    WidgetsBinding.instance.addPostFrameCallback((_) => _bake());
  }

  @override
  void didUpdateWidget(MapScreen old) {
    super.didUpdateWidget(old);
    if (old.services != widget.services) {
      _changes?.cancel();
      _changes = _s.progress.changes.listen((_) => _progressChanged());
      _storyScenes.clear();
      _loadingScenes.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _s.course.load();
        if (!mounted) return;
        _progressChanged();
        _centerOnCurrentStop();
      });
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    _ticker?.dispose();
    _scrollV.dispose();
    _scrollH.dispose();
    _frames.dispose();
    if (widget.perf == null) _perf?.dispose();
    super.dispose();
  }

  Future<void> _bake() async {
    if (!mounted) return;
    final sw = Stopwatch()..start();
    _map.bake();
    sw.stop();
    _perf?.recordBake(sw.elapsedMicroseconds / 1000);
    await _s.course.load();
    if (!mounted) return;
    final st = mapStateOf(_s.progress, _s.course);
    _map.setState(st);
    _map.placeFrog(st.aqui);
    _baked = true;
    _map.draw();
    _frames.fire();
    if (!_s.reduceMotion) {
      _ticker = createTicker(_onTick)..start();
    }
    _primeNextStoryScene();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnCurrentStop());
    final go = widget.openPlace;
    if (go != null) _visit(go);
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

  void _redraw() {
    _map.draw();
    _frames.fire();
  }

  void _progressChanged() {
    if (!mounted || !_baked) return;
    final st = mapStateOf(_s.progress, _s.course);
    final moved = st.aqui != _map.STATE.aqui;
    _map.setState(st);
    if (moved) _map.placeFrog(st.aqui);
    _redraw();
    _primeNextStoryScene();
    setState(() {});
    if (moved) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _centerOnCurrentStop(),
      );
    }
  }

  void _primeNextStoryScene() {
    final plan = _plan();
    if (plan.isEmpty) return;
    final route = plan.first.route;
    if (route is! StoryRoute) return;
    final id = route.id;
    if (_storyScenes.containsKey(id) || _loadingScenes.contains(id)) return;
    _loadingScenes.add(id);
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
      if (!mounted) return;
      if (_storyScenes[id] != scene) {
        setState(() => _storyScenes[id] = scene);
      } else {
        _storyScenes[id] = scene;
      }
    }());
  }

  MapCamera _cameraFor(Size viewport, double dpr, double bottomPad) {
    final aqui = _baked ? _map.STATE.aqui : 0;
    return computeMapCamera(
      viewport: viewport,
      dpr: dpr,
      stop: _map.stopOnPicture(aqui),
      bottomPad: bottomPad,
    );
  }

  void _centerOnCurrentStop() {
    if (!mounted || _viewport.isEmpty) return;
    final cam = _cameraFor(_viewport, _dpr, _bottomPad);
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

  void _hopSound() =>
      _s.clips.tone(320, dur: .07, wave: 'square', vol: .025, toHz: 520);

  void _onTapPixel(int x, int y) {
    if (!_baked || _map.FROG.path != null) return;
    _visit(_map.stopAt(x + .5, y + .5));
  }

  void _visit(int k) {
    if (!_baked || _map.FROG.path != null) return;
    if (k < 0 || k >= _s.course.places.length) return;
    _s.haptics.tick();
    if (_map.STATE.abierto[k] && k != _map.FROG.at) {
      if (_s.reduceMotion) {
        _map.placeFrog(k);
        _redraw();
        _openSheet(k);
      } else {
        _map.hopTo(k, () => _openSheet(k));
      }
    } else {
      _openSheet(k);
    }
  }

  void _openSheet(int k) {
    if (!mounted) return;
    final places = _s.course.places;
    if (k < 0 || k >= places.length) return;
    final place = places[k];
    unawaited(
      showCoquiSheet(
        context,
        builder: (context, close) => CoquiSheet(
          title: place.name,
          child: PlaceSheetBody(
            place: place,
            progress: _s.progress,
            course: _s.course,
            onPlay: (id) {
              close();
              _s.nav.go(StoryRoute(id));
            },
          ),
        ),
      ),
    );
  }

  void _start(TodayEntry e) {
    _s.haptics.tick();
    _s.nav.go(e.route);
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
    final pairs = _s.course.pairs;
    if (pairs.isEmpty) return null;
    if (entry.review) {
      for (final word in _s.progress.due(Skill.ear)) {
        final pair = _s.course.pairFor(word);
        if (pair != null) return PictureRef.of(pair, pair.yes);
      }
      return PictureRef.of(pairs.first, pairs.first.yes);
    }
    final route = entry.route;
    if (route is StoryRoute) {
      final scene = _storyScenes[route.id];
      if (scene != null) {
        for (final pair in pairs) {
          if ((pair.yes.scene ?? pair.scene) == scene) {
            return PictureRef.of(pair, pair.yes);
          }
        }
        return null;
      }
    }
    if (place != null) {
      final normalizedScenes = [
        for (final s in place.scenes) _s.course.language.normalize(s).trim(),
      ];
      for (final pair in pairs) {
        final scene = pair.yes.scene ?? pair.scene;
        if (normalizedScenes.any((s) => s.contains(scene))) {
          return PictureRef.of(pair, pair.yes);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final places = _s.course.places;
    final plan = _baked ? _plan() : const <TodayEntry>[];
    final lang = _s.course.language;
    final foot = NocheSize.aboveTabBar + pad.bottom;

    return ColoredBox(
      color: NocheColors.ground,
      child: DefaultTextStyle.merge(
        style: NocheType.body.copyWith(color: NocheColors.text),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _mapViewport(context, foot),
            PositionedDirectional(
              top: pad.top + 16,
              start: 16,
              end: 16,
              child: _TopChips(
                languageName: lang.englishName,
                level: _defaultLevel,
                streak: _s.progress.streak,
                onLanguageTap: () {
                  _s.haptics.tick();
                  _s.nav.go(const LanguagesRoute());
                },
              ),
            ),
            if (widget.showPerf && _perf != null)
              PositionedDirectional(
                top: pad.top + 16 + NocheSize.touch + NocheSize.grid,
                end: 16,
                child: MapPerfChip(_perf),
              ),
            if (plan.isNotEmpty)
              PositionedDirectional(
                start: 16,
                end: 16,
                bottom: foot,
                child: _UpNextCard(
                  entry: plan.first,
                  thenLine: upNextThenLine(plan),
                  places: places,
                  language: lang,
                  reviewTitle: widget.reviewTitle,
                  pictures: _s.pictures,
                  pictureRef: _pictureRefFor(
                    plan.first,
                    plan.first.route is StoryRoute
                        ? _placeFor((plan.first.route as StoryRoute).id, places)
                        : null,
                  ),
                  onPlay: () => _start(plan.first),
                  onOpenPlace: (placeIndex) {
                    _s.haptics.tick();
                    _openSheet(placeIndex);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Place? _placeFor(String storyId, List<Place> places) {
    final idx = placeIndexForStory(places, storyId);
    return idx == null ? null : places[idx];
  }

  Widget _mapViewport(BuildContext context, double foot) {
    return LayoutBuilder(
      builder: (context, c) {
        _viewport = c.biggest;
        _dpr = MediaQuery.devicePixelRatioOf(context);
        _bottomPad = math.max(foot + 220, _viewport.height * 0.51);
        final cam = _cameraFor(_viewport, _dpr, _bottomPad);
        final availWidth = mapW * cam.deviceScale / _dpr;
        final contentW = math.max(_viewport.width, cam.mapWidth);
        final contentH = cam.mapHeight + _bottomPad;

        return Directionality(
          textDirection: TextDirection.ltr,
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
                            semanticLabel: 'Course map',
                          ),
                        ),
                      ),
                    ),
                    if (_baked)
                      PositionedDirectional(
                        start: cam.stopX - _pillAnchorHalfWidth,
                        width: _pillAnchorHalfWidth * 2,
                        top: cam.stopY - _pillLift,
                        child: const Center(
                          child: _YouAreHerePill(key: Key('you-are-here')),
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

class _TopChips extends StatelessWidget {
  const _TopChips({
    required this.languageName,
    required this.level,
    required this.streak,
    required this.onLanguageTap,
  });

  final String languageName;
  final String level;
  final int streak;
  final VoidCallback onLanguageTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Pressable(
          key: const Key('language-chip'),
          onPressed: onLanguageTap,
          semanticLabel: '$languageName, level $level. Change language.',
          builder: (context, pressed) => Transform.scale(
            scale: pressed ? 0.98 : 1,
            child: Container(
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
                  Text(
                    level,
                    maxLines: 1,
                    softWrap: false,
                    style: NocheType.body.copyWith(
                      height: 1,
                      color: NocheColors.label,
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
        ),
        if (streak > 0)
          Semantics(
            label: streak == 1 ? '1 day' : '$streak days',
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
                    const NocheIcon(
                      NocheIcons.flame,
                      size: 18,
                      color: NocheColors.next,
                    ),
                    const SizedBox(width: NocheSize.grid),
                    Text(
                      streak == 1 ? '1 day' : '$streak days',
                      maxLines: 1,
                      softWrap: false,
                      style: NocheType.button.copyWith(color: NocheColors.text),
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
                  'You are here',
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

class _UpNextCard extends StatelessWidget {
  const _UpNextCard({
    required this.entry,
    required this.thenLine,
    required this.places,
    required this.language,
    required this.reviewTitle,
    required this.pictures,
    required this.pictureRef,
    required this.onPlay,
    required this.onOpenPlace,
  });

  final TodayEntry entry;
  final String? thenLine;
  final List<Place> places;
  final Language language;
  final String? reviewTitle;
  final PictureSource pictures;
  final PictureRef? pictureRef;
  final VoidCallback onPlay;
  final ValueChanged<int> onOpenPlace;

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
        ? (reviewTitle ?? 'Review')
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
        : '${upNextKind(entry)} · ${entry.minutes} min';

    final details = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _SceneThumb(
          pictures: pictures,
          ref: pictureRef,
          isReview: entry.review,
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
                      text: place != null ? 'UP NEXT · ' : 'UP NEXT',
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

    final tappableDetails = placeIdx != null
        ? Pressable(
            key: const Key('up-next-place'),
            onPressed: () => onOpenPlace(placeIdx),
            builder: (context, pressed) =>
                Opacity(opacity: pressed ? 0.85 : 1, child: details),
          )
        : details;

    return NocheCard(
      key: const Key('up-next-card'),
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
              NochePlayDisc(
                key: const Key('up-next-play'),
                size: NocheSize.disc,
                onPressed: onPlay,
                semanticLabel: entry.review
                    ? 'Start review'
                    : 'Play the story $titleText',
              ),
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

class _SceneThumb extends StatelessWidget {
  const _SceneThumb({
    required this.pictures,
    required this.ref,
    required this.isReview,
  });

  final PictureSource pictures;
  final PictureRef? ref;
  final bool isReview;

  @override
  Widget build(BuildContext context) {
    final dpr =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    final scale = math.max(1, (dpr - 1e-6).ceil());
    final avail = 72.0 * scale / dpr;
    final child = ref != null
        ? OverflowBox(
            maxWidth: avail,
            maxHeight: avail,
            alignment: AlignmentDirectional.center,
            child: pictures.of(
              ref!,
              width: _UpNextCard._thumbSize.toInt(),
              height: _UpNextCard._thumbSize.toInt(),
            ),
          )
        : ColoredBox(
            color: NocheColors.chip,
            child: Center(
              child: NocheIcon(
                isReview ? NocheIcons.words : NocheIcons.map,
                size: 28,
                color: NocheColors.label,
              ),
            ),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(NocheSize.tileRadius),
      child: SizedBox.square(dimension: _UpNextCard._thumbSize, child: child),
    );
  }
}
