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

/// The page colour of mapa.html (`body`), under the picture: the island floats on it. mapa.html: line 12.
const Color mapPageColor = Color(0xFF14141F);

/// The map tab: the chips at the top, the island map scrolling under them, the Today card over its foot, and the
/// place sheet. The picture is `MapPicture` (a port of mapa.js) shown by `PixelView` at a whole-number scale.
///
/// It draws the whole screen, as the tab bar is drawn over it by the shell (the card and the sheet sit above
/// the bar's height). [reviewTitle] is the Spanish title of today's review entry, which app.html writes in its
/// `plan()` and which comes from nowhere in the catalog: with none given the plan has no review entry.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.services,
    this.perf,
    this.reviewTitle,
    this.openPlace,
    this.onPicture,
  });

  final Services services;

  /// Where the bake time and the frame times go, if anyone wants them.
  final MapPerf? perf;

  /// The title the Today card gives its review entry; null: no review entry.
  final String? reviewTitle;

  /// For a dev entry and its screenshots: once the map is up, go to this place (0 to 9) as if it had been
  /// tapped.
  final int? openPlace;

  /// For tests: given the picture the screen draws, as soon as it is made.
  final void Function(MapPicture picture)? onPicture;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _FrameSignal extends ChangeNotifier {
  void fire() => notifyListeners();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late final MapPicture _map;
  final _frames = _FrameSignal();
  final _scroll = ScrollController();
  Ticker? _ticker;
  Duration _last = Duration.zero;
  StreamSubscription<void>? _changes;

  /// The picture has been baked and the state laid on it.
  bool _baked = false;
  int? _sheetPlace;
  bool _sheetOpen = false;

  // what the last layout gave: to open the map scrolled to the frog
  double _viewportH = 0, _scale = 1, _dpr = 1;

  Services get _s => widget.services;

  @override
  void initState() {
    super.initState();
    _map = MapPicture(still: _s.reduceMotion, onHop: _hopSound);
    widget.onPicture?.call(_map);
    _changes = _s.progress.changes.listen((_) => _progressChanged());
    // the first frame shows the page colour; the bake comes after it
    WidgetsBinding.instance.addPostFrameCallback((_) => _bake());
  }

  @override
  void dispose() {
    _changes?.cancel();
    _ticker?.dispose();
    _scroll.dispose();
    _frames.dispose();
    super.dispose();
  }

  // mapa.html: bake, setState, placeFrog
  Future<void> _bake() async {
    if (!mounted) return;
    final sw = Stopwatch()..start();
    _map.bake();
    sw.stop();
    widget.perf?.recordBake(sw.elapsedMicroseconds / 1000);
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
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFrog());
    final go = widget.openPlace;
    if (go != null) _visit(go);
  }

  // mapa.html: frame
  void _onTick(Duration elapsed) {
    final dt = math.min(.05, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    final sw = Stopwatch()..start();
    _map.tick(dt);
    sw.stop();
    widget.perf?.recordFrame(sw.elapsedMicroseconds / 1000);
    _frames.fire();
  }

  // the picture is drawn again now (with the motion off nothing else ever redraws it)
  void _redraw() {
    _map.draw();
    _frames.fire();
  }

  // Redraw on `progress.changes`: the new state goes on the baked picture; the frog moves when the current
  // place changes
  void _progressChanged() {
    if (!mounted || !_baked) return;
    final st = mapStateOf(_s.progress, _s.course);
    final moved = st.aqui != _map.STATE.aqui;
    _map.setState(st);
    if (moved) _map.placeFrog(st.aqui);
    _redraw();
    setState(() {});
  }

  // mapa.html: open on the frog
  void _scrollToFrog() {
    if (!mounted || !_scroll.hasClients) return;
    final p = _map.stopOnPicture(_map.FROG.at);
    final y = p.sy * _scale / _dpr - _viewportH * .45;
    _scroll.jumpTo(
      math.max(0.0, math.min(y, _scroll.position.maxScrollExtent)),
    );
  }

  // mapa.js: sfxHop
  void _hopSound() =>
      _s.clips.tone(320, dur: .07, wave: 'square', vol: .025, toHz: 520);

  // mapa.html: the click on the canvas
  void _onTapPixel(int x, int y) {
    if (!_baked || _map.FROG.path != null) return;
    _visit(_map.stopAt(x + .5, y + .5));
  }

  // mapa.html: what a tap on stop k does
  void _visit(int k) {
    if (!_baked || _map.FROG.path != null) return;
    if (k < 0 || k >= _s.course.places.length) return;
    _s.haptics.tick();
    if (_map.STATE.abierto[k] && k != _map.FROG.at) {
      if (_s.reduceMotion) {
        // everything stands still: the frog is simply there, then the sheet
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
    setState(() {
      _sheetPlace = k;
      _sheetOpen = true;
    });
  }

  // app.html: cierra
  void _closeSheet() => setState(() => _sheetOpen = false);

  // app.html: empieza
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

  @override
  Widget build(BuildContext context) {
    final places = _s.course.places;
    final aqui = _baked ? _map.STATE.aqui : 0;
    final here = aqui < places.length ? places[aqui] : null;
    final plan = _baked ? _plan() : const <TodayEntry>[];
    final sheetPlace = _sheetPlace;
    final foot =
        CoquiLayout.tabBarHeight(context) + CoquiLayout.rise(context) + 16;
    return ColoredBox(
      color: mapPageColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              MapChips(
                streak: MapChips.streakLabel(_s.progress.streak),
                place: here == null
                    ? ''
                    : MapChips.placeLabel(here.n, here.name),
              ),
              Expanded(child: _mapArea(context, foot)),
            ],
          ),
          if (plan.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: foot,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: CoquiMetrics.columnMax,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _todayCard(plan),
                  ),
                ),
              ),
            ),
          ExcludeSemantics(
            excluding: !_sheetOpen,
            child: CoquiSheetLayer(
              open: _sheetOpen,
              onScrimTap: _closeSheet,
              sheet: sheetPlace != null && sheetPlace < places.length
                  ? CoquiSheet(
                      title: places[sheetPlace].name,
                      onClose: _closeSheet,
                      child: PlaceSheetBody(
                        place: places[sheetPlace],
                        progress: _s.progress,
                        course: _s.course,
                        onPlay: (id) => _s.nav.go(StoryRoute(id)),
                      ),
                    )
                  : CoquiSheet(onClose: _closeSheet, child: const SizedBox()),
            ),
          ),
        ],
      ),
    );
  }

  // app.html: hud. `Today` and, when there is more than one, ` · 1 of N`; the first entry
  Widget _todayCard(List<TodayEntry> plan) {
    final p = plan.first;
    return TodayCard(
      eyebrow: 'Today${plan.length > 1 ? " · 1 of ${plan.length}" : ""}',
      title: p.review ? widget.reviewTitle! : p.title!,
      subtitle: p.subtitle,
      onPressed: () => _start(p),
    );
  }

  // mapa.html: `#mapwrap`: the picture at a whole-number scale, centred, scrolling; room under it so the
  // island's foot can come up above the Today card
  Widget _mapArea(BuildContext context, double foot) {
    return LayoutBuilder(
      builder: (context, c) {
        _viewportH = c.maxHeight;
        _dpr = MediaQuery.devicePixelRatioOf(context);
        _scale = pixelViewScale(
          availableWidth: math.min(c.maxWidth, CoquiMetrics.columnMax),
          devicePixelRatio: _dpr,
          width: mapW,
        ).toDouble();
        return SingleChildScrollView(
          controller: _scroll,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: CustomPaint(
              painter: const _DotsPainter(),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: foot + CoquiMetrics.todayMin + 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: CoquiMetrics.columnMax,
                    ),
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
            ),
          ),
        );
      },
    );
  }
}

/// mapa.html: `body{background: #14141F radial-gradient(rgba(255,255,255,.07) 1px, transparent 1.4px) 0 0/12px 12px}`:
/// a faint dot every 12 px.
class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x12FFFFFF);
    for (var y = 6.0; y < size.height; y += 12) {
      for (var x = 6.0; x < size.width; x += 12) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => false;
}
