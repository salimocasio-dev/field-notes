/// The tabs, the tab bar and the lesson screens.
library;

import 'dart:ui' show lerpDouble;

import 'package:app/src/addresses.dart';
import 'package:app/src/motion.dart';
import 'package:app/src/navigator.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Stable shell-owned keys for mounted tabs, route screens, and shell chrome.
abstract final class ShellKeys {
  /// Mounted tab wrapper for [tabId] (inside `Offstage` and the epoch
  /// `KeyedSubtree`, so `find.byKey(ShellKeys.tab(id))` matches the visible
  /// tab across language switches without affecting epoch-based state reset).
  static ValueKey<String> tab(String tabId) => ValueKey('shell-tab:$tabId');

  /// Mounted non-tab route wrapper for [route] (inside `Directionality` and
  /// the epoch `KeyedSubtree`, so `Directionality.of` reflects the reading
  /// direction given to the route screen). Because the outer `KeyedSubtree`
  /// already keys on `lesson:$_epoch:${addressOf(route)}`, keying this inner
  /// wrapper on `addressOf(route)` preserves identical remount behavior.
  static ValueKey<String> route(AppRoute route) =>
      ValueKey('shell-route:${addressOf(route)}');

  /// Floating bottom tab bar wrapper.
  static const ValueKey<String> tabBar = ValueKey('tab-bar');

  /// Root ground `ColoredBox` behind the shell stack.
  static const ValueKey<String> ground = ValueKey('shell-ground');

  /// `Transform.translate` wrapping the floating [NocheTabBar].
  static const ValueKey<String> tabBarMotion = ValueKey('shell-tab-bar-motion');

  /// `Transform.translate` wrapping the kept-alive tab [tabId].
  static ValueKey<String> tabMotion(String tabId) =>
      ValueKey('shell-tab-motion:$tabId');

  /// `Opacity` wrapping the kept-alive tab [tabId].
  static ValueKey<String> tabOpacity(String tabId) =>
      ValueKey('shell-tab-opacity:$tabId');
}

enum _TabBarPhase { hidden, loadArrival, shown, sinking, rising }

/// The app's screens for the address [route]: the five tabs, each kept alive once it has been shown (the map bakes
/// once), with the tab bar drawn over the tab (each tab lays itself out under the bar and draws its own fade); or a
/// lesson (story, Repaso, level check, book, call, voice test) over everything, full screen, the tab bar hidden.
///
/// A tab is built the first time it is shown, so that nothing a tab does at its start happens before it is opened
/// (Hablar's open call card loads the call's voice library, as the old page's `precarga` does when Hablar shows it).
/// The tabs that are not shown are offstage, their tickers stopped.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.services,
    required this.modules,
    required this.nav,
    required this.route,
    this.animateLoadArrival = false,
  });

  final Services services;
  final List<FeatureModule> modules;
  final ShellNavigator nav;

  /// What the address says to show.
  final AppRoute route;

  /// Whether the initial mount animates load arrival (map fade + tab bar rise).
  final bool animateLoadArrival;

  @override
  State<AppShell> createState() => _AppShellState();
}

/// Whether [route] is a lesson screen that follows the course language's
/// reading direction (e.g. RTL for Arabic), rather than the English shell
/// chrome (tabs, tab bar, sheets, and place overview) which stays LTR.
bool isLessonRoute(AppRoute route) => switch (route) {
  StoryRoute() ||
  ReviewRoute() ||
  LevelCheckRoute() ||
  BookRoute() ||
  CallRoute() ||
  VoiceTestRoute() => true,
  TabRoute() ||
  PlaceRoute() ||
  LanguagesRoute() ||
  PlansRoute() ||
  ImportRoute() => false,
};

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  final Map<String, WidgetBuilder> _tabs = {};
  int _epoch = 0;

  late AppRoute _resolvedRoute;
  late String _activeTab;
  String? _outgoingTab;
  NocheFollowSide _tabFollowSide = NocheFollowSide.end;
  NocheMotionData _tabFollowMotion = NocheMotion.normal;

  late final AnimationController _tabFollowController = AnimationController(
    vsync: this,
    value: 1.0,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_handleTabFollowStatus);

  late final AnimationController _tabBarController = AnimationController(
    vsync: this,
    value: 1.0,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_handleTabBarStatus);

  late final AnimationController _groundController = AnimationController(
    vsync: this,
    value: 1.0,
    animationBehavior: AnimationBehavior.preserve,
  );

  late final AnimationController _loadArrivalController = AnimationController(
    vsync: this,
    value: 1.0,
    animationBehavior: AnimationBehavior.preserve,
  );

  _TabBarPhase _tabBarPhase = _TabBarPhase.shown;
  NocheMotionData _tabBarMotion = NocheMotion.normal;
  double _sinkFromDy = 0.0;
  double _sinkFromOpacity = 1.0;
  double _riseFromDy = ShellMotion.tabBarSinkDistance;
  double _riseFromOpacity = 0.0;

  Color _fromGround = NocheColors.ground;
  Color _toGround = NocheColors.ground;
  NocheMotionData _groundMotion = NocheMotion.normal;

  NocheMotionData _loadArrivalMotion = NocheMotion.normal;

  bool _initialized = false;
  bool _lastHasScreen = false;
  bool _lastShowsTabBar = true;

  @override
  void initState() {
    super.initState();
    _resolvedRoute = widget.nav.arrive(widget.route);
    _activeTab = _resolvedRoute is TabRoute
        ? (_resolvedRoute as TabRoute).tab
        : widget.nav.origin;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final motion = NocheMotion.of(context);
    final hasScreen =
        _resolvedRoute is! TabRoute && _lesson(_resolvedRoute) != null;
    final showsTabBar = !hasScreen || _resolvedRoute is PlaceRoute;
    _lastHasScreen = hasScreen;
    _lastShowsTabBar = showsTabBar;

    _fromGround = _toGround = isLessonRoute(_resolvedRoute)
        ? NocheColors.lessonGround
        : NocheColors.ground;
    _groundMotion = motion;
    _groundController.value = 1.0;

    if (!showsTabBar) {
      _tabBarPhase = _TabBarPhase.hidden;
      _tabBarMotion = motion;
      _tabBarController.value = 1.0;
    } else if (widget.animateLoadArrival) {
      _tabBarPhase = _TabBarPhase.loadArrival;
      _tabBarMotion = motion;
      _tabBarController.duration = ShellMotion.loadTabBarDelay + motion.pageIn;
      _tabBarController.forward(from: 0.0);
    } else {
      _tabBarPhase = _TabBarPhase.shown;
      _tabBarMotion = motion;
      _tabBarController.value = 1.0;
    }

    if (widget.animateLoadArrival) {
      _loadArrivalMotion = motion;
      _loadArrivalController.duration = motion.pageIn;
      _loadArrivalController.forward(from: 0.0);
    } else {
      _loadArrivalMotion = motion;
      _loadArrivalController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final servicesOrModulesChanged =
        !identical(oldWidget.services, widget.services) ||
        oldWidget.modules != widget.modules;
    if (servicesOrModulesChanged) {
      _tabs.clear();
      _epoch++;
    }

    if (widget.route != oldWidget.route || servicesOrModulesChanged) {
      _resolvedRoute = widget.nav.arrive(widget.route);
    }

    final oldHasScreen = _lastHasScreen;
    final oldShowsTabBar = _lastShowsTabBar;
    final oldTab = _activeTab;

    final newHasScreen =
        _resolvedRoute is! TabRoute && _lesson(_resolvedRoute) != null;
    final newShowsTabBar = !newHasScreen || _resolvedRoute is PlaceRoute;
    final newTab = _resolvedRoute is TabRoute
        ? (_resolvedRoute as TabRoute).tab
        : widget.nav.origin;

    _lastHasScreen = newHasScreen;
    _lastShowsTabBar = newShowsTabBar;

    final motion = NocheMotion.of(context);
    final nextGround = isLessonRoute(_resolvedRoute)
        ? NocheColors.lessonGround
        : NocheColors.ground;

    if (servicesOrModulesChanged) {
      _outgoingTab = null;
      _tabFollowController.value = 1.0;
      _activeTab = newTab;

      _fromGround = _toGround = nextGround;
      _groundMotion = motion;
      _groundController.value = 1.0;

      if (newShowsTabBar) {
        _tabBarPhase = _TabBarPhase.shown;
        _tabBarMotion = motion;
        _tabBarController.value = 1.0;
      } else {
        _tabBarPhase = _TabBarPhase.hidden;
        _tabBarMotion = motion;
        _tabBarController.value = 1.0;
      }
      return;
    }

    if (!oldHasScreen && !newHasScreen && newTab != oldTab) {
      final oldIdx = tabIds.indexOf(oldTab);
      final newIdx = tabIds.indexOf(newTab);
      _outgoingTab = oldTab;
      _tabFollowSide = newIdx > oldIdx
          ? NocheFollowSide.end
          : NocheFollowSide.start;
      _tabFollowMotion = motion;
      _tabFollowController.duration = motion.followAfter + motion.move;
      _tabFollowController.forward(from: 0.0);
      _activeTab = newTab;
    } else if (newTab != oldTab) {
      _outgoingTab = null;
      _tabFollowController.value = 1.0;
      _activeTab = newTab;
    } else if (newHasScreen && _resolvedRoute is! LanguagesRoute) {
      _outgoingTab = null;
      _tabFollowController.value = 1.0;
    }

    if (nextGround != _toGround) {
      _fromGround = _currentGroundColor();
      _toGround = nextGround;
      _groundMotion = motion;
      _groundController.duration = nextGround == NocheColors.lessonGround
          ? motion.pageIn
          : motion.pageOut;
      _groundController.forward(from: 0.0);
    }

    if (newShowsTabBar != oldShowsTabBar) {
      if (!newShowsTabBar) {
        _sinkFromDy = _currentTabBarDy();
        _sinkFromOpacity = _currentTabBarOpacity();
        _tabBarPhase = _TabBarPhase.sinking;
        _tabBarMotion = motion;
        _tabBarController.duration = motion.pageOut;
        _tabBarController.forward(from: 0.0);
      } else {
        final sinkDistance = motion.reduced
            ? 0.0
            : ShellMotion.tabBarSinkDistance;
        _riseFromDy = _tabBarPhase == _TabBarPhase.hidden
            ? sinkDistance
            : _currentTabBarDy();
        _riseFromOpacity = _tabBarPhase == _TabBarPhase.hidden
            ? 0.0
            : _currentTabBarOpacity();
        _tabBarPhase = _TabBarPhase.rising;
        _tabBarMotion = motion;
        _tabBarController.duration = motion.followAfter + motion.move;
        _tabBarController.forward(from: 0.0);
      }
    }
  }

  void _handleTabFollowStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _outgoingTab != null &&
        mounted) {
      setState(() {
        _outgoingTab = null;
      });
    }
  }

  void _handleTabBarStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (_tabBarPhase == _TabBarPhase.sinking) {
      setState(() {
        _tabBarPhase = _TabBarPhase.hidden;
      });
    } else if (_tabBarPhase == _TabBarPhase.rising ||
        _tabBarPhase == _TabBarPhase.loadArrival) {
      setState(() {
        _tabBarPhase = _TabBarPhase.shown;
      });
    }
  }

  @override
  void dispose() {
    _tabFollowController
      ..removeStatusListener(_handleTabFollowStatus)
      ..dispose();
    _tabBarController
      ..removeStatusListener(_handleTabBarStatus)
      ..dispose();
    _groundController.dispose();
    _loadArrivalController.dispose();
    super.dispose();
  }

  Color _currentGroundColor() =>
      Color.lerp(
        _fromGround,
        _toGround,
        _groundMotion.enter.transform(_groundController.value),
      ) ??
      _toGround;

  double _currentTabBarDy() {
    switch (_tabBarPhase) {
      case _TabBarPhase.hidden:
        return _tabBarMotion.reduced ? 0.0 : ShellMotion.tabBarSinkDistance;
      case _TabBarPhase.shown:
        return 0.0;
      case _TabBarPhase.loadArrival:
        if (_tabBarMotion.reduced) return 0.0;
        final totalUs = (ShellMotion.loadTabBarDelay + _tabBarMotion.pageIn)
            .inMicroseconds
            .toDouble();
        final elapsedUs = _tabBarController.value * totalUs;
        final delayUs = ShellMotion.loadTabBarDelay.inMicroseconds.toDouble();
        if (elapsedUs <= delayUs) return ShellMotion.tabBarSinkDistance;
        final posUs = _tabBarMotion.pageIn.inMicroseconds.toDouble();
        final raw = posUs <= 0
            ? 1.0
            : ((elapsedUs - delayUs) / posUs).clamp(0.0, 1.0);
        final p = _tabBarMotion.enter.transform(raw);
        return ShellMotion.tabBarSinkDistance * (1.0 - p);
      case _TabBarPhase.sinking:
        if (_tabBarMotion.reduced) return 0.0;
        final p = _tabBarMotion.exit.transform(_tabBarController.value);
        return lerpDouble(_sinkFromDy, ShellMotion.tabBarSinkDistance, p) ??
            ShellMotion.tabBarSinkDistance;
      case _TabBarPhase.rising:
        if (_tabBarMotion.reduced) return 0.0;
        final totalUs = (_tabBarMotion.followAfter + _tabBarMotion.move)
            .inMicroseconds
            .toDouble();
        final elapsedUs = _tabBarController.value * totalUs;
        final delayUs = _tabBarMotion.followAfter.inMicroseconds.toDouble();
        if (elapsedUs <= delayUs) return _riseFromDy;
        final moveUs = _tabBarMotion.move.inMicroseconds.toDouble();
        final raw = moveUs <= 0
            ? 1.0
            : ((elapsedUs - delayUs) / moveUs).clamp(0.0, 1.0);
        final p = _tabBarMotion.enter.transform(raw);
        return lerpDouble(_riseFromDy, 0.0, p) ?? 0.0;
    }
  }

  double _currentTabBarOpacity() {
    switch (_tabBarPhase) {
      case _TabBarPhase.hidden:
        return 0.0;
      case _TabBarPhase.shown:
        return 1.0;
      case _TabBarPhase.loadArrival:
        final totalUs = (ShellMotion.loadTabBarDelay + _tabBarMotion.pageIn)
            .inMicroseconds
            .toDouble();
        final elapsedUs = _tabBarController.value * totalUs;
        final delayUs = ShellMotion.loadTabBarDelay.inMicroseconds.toDouble();
        if (elapsedUs <= delayUs) return 0.0;
        final opUs = _tabBarMotion.move.inMicroseconds.toDouble();
        final raw = opUs <= 0
            ? 1.0
            : ((elapsedUs - delayUs) / opUs).clamp(0.0, 1.0);
        return _tabBarMotion.enter.transform(raw).clamp(0.0, 1.0);
      case _TabBarPhase.sinking:
        final p = _tabBarMotion.exit.transform(_tabBarController.value);
        return (lerpDouble(_sinkFromOpacity, 0.0, p) ?? 0.0).clamp(0.0, 1.0);
      case _TabBarPhase.rising:
        final totalUs = (_tabBarMotion.followAfter + _tabBarMotion.move)
            .inMicroseconds
            .toDouble();
        final elapsedUs = _tabBarController.value * totalUs;
        final delayUs = _tabBarMotion.followAfter.inMicroseconds.toDouble();
        if (elapsedUs <= delayUs) return _riseFromOpacity;
        final quickUs = _tabBarMotion.quick.inMicroseconds.toDouble();
        final raw = quickUs <= 0
            ? 1.0
            : ((elapsedUs - delayUs) / quickUs).clamp(0.0, 1.0);
        final p = _tabBarMotion.enter.transform(raw);
        return (lerpDouble(_riseFromOpacity, 1.0, p) ?? 1.0).clamp(0.0, 1.0);
    }
  }

  WidgetBuilder? _tab(String id) {
    final had = _tabs[id];
    if (had != null) return had;
    for (final m in widget.modules) {
      final t = m.tab(widget.services);
      if (t != null && t.id == id) return _tabs[id] = t.builder;
    }
    return null;
  }

  Widget? _lesson(AppRoute route) {
    for (final m in widget.modules) {
      final w = m.screenFor(route, widget.services);
      if (w != null) return w;
    }
    return null;
  }

  void _onTab(String id) {
    widget.services.haptics.tick(); // app.html, ver: tick()
    widget.nav.go(TabRoute(id));
  }

  @override
  Widget build(BuildContext context) {
    final route = _resolvedRoute;
    final screen = route is TabRoute ? null : _lesson(route);
    final tab = route is TabRoute ? route.tab : widget.nav.origin;
    final keepsTabBehind = screen != null && route is LanguagesRoute;
    final selectedTab = route is PlaceRoute ? NocheTabs.map : tab;
    _tab(tab);
    final language = widget.services.course.language;
    final isRtl = language.textDirection == TextDirection.rtl;
    final baseSign = _tabFollowSide == NocheFollowSide.end ? 1.0 : -1.0;
    final sign = isRtl ? -baseSign : baseSign;
    final isSinkingTabBar = _tabBarPhase == _TabBarPhase.sinking;

    final tabsLayer = AnimatedBuilder(
      animation: _loadArrivalController,
      builder: (context, child) => Opacity(
        opacity: _loadArrivalController.value >= 1.0
            ? 1.0
            : _loadArrivalMotion.enter
                  .transform(_loadArrivalController.value)
                  .clamp(0.0, 1.0),
        child: child,
      ),
      child: AnimatedBuilder(
        animation: _tabFollowController,
        builder: (context, _) {
          final totalUs = (_tabFollowMotion.followAfter + _tabFollowMotion.move)
              .inMicroseconds
              .toDouble();
          final elapsedUs = _tabFollowController.value * totalUs;
          final isFollowing =
              _outgoingTab != null &&
              _tabFollowController.value < 1.0 &&
              screen == null;

          return Stack(
            fit: StackFit.expand,
            children: [
              for (final id in tabIds)
                if (_tabs[id] != null)
                  () {
                    final bool isOffstage;
                    final bool isPassive;
                    final bool isTicking;
                    final double dx;
                    final double opacity;

                    if (isFollowing && id == _outgoingTab) {
                      final pressUs = _tabFollowMotion.press.inMicroseconds
                          .toDouble();
                      final tOut = pressUs <= 0
                          ? 1.0
                          : (elapsedUs / pressUs).clamp(0.0, 1.0);
                      if (tOut < 1.0) {
                        isOffstage = false;
                        isPassive = true;
                        isTicking = false;
                        dx = 0.0;
                        opacity = (1.0 - _tabFollowMotion.exit.transform(tOut))
                            .clamp(0.0, 1.0);
                      } else {
                        isOffstage = true;
                        isPassive = true;
                        isTicking = false;
                        dx = 0.0;
                        opacity = 0.0;
                      }
                    } else if (id == tab) {
                      isOffstage = screen != null && !keepsTabBehind;
                      isPassive = false;
                      isTicking = screen == null;
                      if (!isFollowing) {
                        dx = 0.0;
                        opacity = 1.0;
                      } else {
                        final followAfterUs = _tabFollowMotion
                            .followAfter
                            .inMicroseconds
                            .toDouble();
                        final moveUs = _tabFollowMotion.move.inMicroseconds
                            .toDouble();
                        final double pIn;
                        if (elapsedUs <= followAfterUs) {
                          pIn = 0.0;
                        } else if (moveUs <= 0) {
                          pIn = 1.0;
                        } else {
                          final rawIn = ((elapsedUs - followAfterUs) / moveUs)
                              .clamp(0.0, 1.0);
                          pIn = _tabFollowMotion.enter.transform(rawIn);
                        }
                        final effectiveDist = _tabFollowMotion.reduced
                            ? 0.0
                            : _tabFollowMotion.tab;
                        dx = sign * effectiveDist * (1.0 - pIn);
                        opacity = pIn.clamp(0.0, 1.0);
                      }
                    } else {
                      isOffstage = true;
                      isPassive = true;
                      isTicking = false;
                      dx = 0.0;
                      opacity = 1.0;
                    }

                    return KeyedSubtree(
                      key: ValueKey('tab:$_epoch:$id'),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Offstage(
                          offstage: isOffstage,
                          child: IgnorePointer(
                            ignoring: isPassive,
                            child: ExcludeSemantics(
                              excluding: isPassive,
                              child: TickerMode(
                                enabled: isTicking,
                                child: Transform.translate(
                                  key: ShellKeys.tabMotion(id),
                                  offset: Offset(dx, 0),
                                  child: Opacity(
                                    key: ShellKeys.tabOpacity(id),
                                    opacity: opacity,
                                    child: KeyedSubtree(
                                      key: ShellKeys.tab(id),
                                      child: Builder(builder: _tabs[id]!),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),
            ],
          );
        },
      ),
    );

    final Widget? screenLayer = screen == null
        ? null
        : KeyedSubtree(
            key: ValueKey('lesson:$_epoch:${addressOf(route)}'),
            child: Directionality(
              textDirection: isLessonRoute(route)
                  ? language.textDirection
                  : TextDirection.ltr,
              child: KeyedSubtree(key: ShellKeys.route(route), child: screen),
            ),
          );

    return PopScope(
      canPop: screen == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.nav.back();
      },
      child: AnimatedBuilder(
        animation: _groundController,
        builder: (context, child) => ColoredBox(
          key: ShellKeys.ground,
          color: _currentGroundColor(),
          child: child,
        ),
        child: AnimatedBuilder(
          animation: _tabBarController,
          child: tabsLayer,
          builder: (context, tabs) {
            final mountTabBar =
                _tabBarPhase != _TabBarPhase.hidden &&
                !(_tabBarPhase == _TabBarPhase.sinking &&
                    _tabBarController.value >= 1.0);
            return Stack(
              fit: StackFit.expand,
              children: [
                tabs!,
                ?screenLayer,
                if (mountTabBar)
                  PositionedDirectional(
                    key: ShellKeys.tabBar,
                    start: 0,
                    end: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      ignoring: isSinkingTabBar,
                      child: ExcludeSemantics(
                        excluding: isSinkingTabBar,
                        child: Transform.translate(
                          key: ShellKeys.tabBarMotion,
                          offset: Offset(0, _currentTabBarDy()),
                          child: Opacity(
                            opacity: _currentTabBarOpacity(),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: NocheTabBar(
                                selectedId: selectedTab,
                                tabNames: language.tabNames,
                                script: language.script,
                                languageCode: language.code,
                                onTap: _onTab,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
