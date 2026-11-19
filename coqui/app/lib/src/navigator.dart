/// Moving between the screens: the shell's [AppNavigator].
library;

import 'dart:async';

import 'package:app/src/addresses.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The shell's [AppNavigator], on go_router. The address is where the app is: a tab's (`#/tab/<id>`) or a lesson's
/// (story, Repaso, level check, book, call, voice test; see `addresses.dart`).
///
/// How the old pages move, kept here:
/// - A tab is switched in place (app.html, ver: `history.replaceState`): switching tabs adds no step to the browser's
///   history, so the browser's back on a tab leaves the app, as a web page would.
/// - A lesson opened from a tab is a new step in the history (the old app left for index.html, cual.html or
///   nivel.html), so the browser's back from it comes back to that tab.
/// - A lesson opened from a lesson (Next story) takes the place of the first, and keeps where the first began
///   (juego.js, origen: kept "while he moves from story to story").
/// - [back] from a lesson returns to the tab that opened it ([origin]), as the lesson's X does (juego.js, salir(origen())).
///   On the web it is the browser's own back, so the history stays as it was before the lesson; when the lesson was
///   not opened from a tab (its address was opened or reloaded as it is), it goes to the map, as the old page's
///   origen() does with no page before it.
/// - [go] to a tab from a lesson (the end screen's Map, Repaso's way back to Palabras) leaves the lesson for that tab.
/// - [back] on a tab leaves the app.
///
/// Android's system back and the browser's back do what [back] does: the shell wraps the screens in a `PopScope`
/// that calls [back] from a lesson, and the browser's back comes in as the tab's address.
class ShellNavigator implements AppNavigator {
  ShellNavigator({this.historyBack});

  /// The browser's `history.back()`; null where there is no browser history (a phone build, a test).
  final void Function()? historyBack;

  /// The router whose address this navigator moves. Set by the shell once it is made.
  late GoRouter router;

  /// Whether some module answers [route] (set by the shell once the services are made).
  bool Function(AppRoute route) answers = (_) => false;

  /// The tab a lesson returns to: the tab it was opened from.
  String get origin => _origin;
  String _origin = startTab;

  /// The route shown now (null before the first).
  AppRoute? get current => _current;
  AppRoute? _current;

  // the lesson's step in the browser's history sits over a tab's: back is the browser's back
  bool _lessonOverTab = false;
  // after the browser's back from a lesson: the tab to go to once the origin's address is back
  String? _pendingTab;
  Timer? _backGuard;

  @override
  void go(AppRoute route) {
    final cur = _current;
    if (route is TabRoute) {
      if (!tabIds.contains(route.tab)) return;
      if (cur == null || cur is TabRoute) {
        _replace(route);
      } else {
        _leaveLesson(route.tab);
      }
      return;
    }
    if (!answers(route)) return;
    if (cur == null || cur is TabRoute) {
      _push(route);
    } else {
      _replace(route);
    }
  }

  @override
  void back() {
    final cur = _current;
    if (cur == null || cur is TabRoute) {
      unawaited(SystemNavigator.pop());
      return;
    }
    _leaveLesson(_origin);
  }

  /// The shell shows the address [route]: what it means for where a lesson returns to. Returns the route to show: a
  /// lesson no module answers shows the map instead, and its address is replaced by the map's.
  AppRoute arrive(AppRoute route) {
    if (route != _current) _arrive(route);
    final cur = _current!;
    return cur;
  }

  void _arrive(AppRoute route) {
    final prev = _current;
    if (route is TabRoute) {
      _backGuard?.cancel();
      _current = route;
      _lessonOverTab = false;
      final pending = _pendingTab;
      _pendingTab = null;
      _origin = route.tab;
      if (pending != null && pending != route.tab) {
        _later(() => _replace(TabRoute(pending)));
      }
      return;
    }
    if (!answers(route)) {
      // an address no screen answers: the map, in its place
      final tab = TabRoute(prev is TabRoute ? prev.tab : startTab);
      _current = tab;
      _origin = tab.tab;
      _lessonOverTab = false;
      _later(() => _replace(tab));
      return;
    }
    if (prev == null) {
      _origin = startTab;
      _lessonOverTab = false;
    } else if (prev is TabRoute) {
      _origin = prev.tab;
      _lessonOverTab = true;
    }
    _current = route;
  }

  void _leaveLesson(String tab) {
    final hb = historyBack;
    if (hb != null && _lessonOverTab) {
      _pendingTab = tab == _origin ? null : tab;
      final lesson = _current;
      hb();
      // the browser answers with the tab's address; should it not, the tab is shown anyway
      _backGuard?.cancel();
      _backGuard = Timer(const Duration(milliseconds: 800), () {
        if (_current == lesson) {
          _lessonOverTab = false;
          _replace(TabRoute(tab));
        }
      });
    } else {
      _replace(TabRoute(tab));
    }
  }

  // a new step in the browser's history
  void _push(AppRoute route) => router.go(addressOf(route));

  // in place of the step shown now
  void _replace(AppRoute route) {
    final ctx = router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) {
      router.go(addressOf(route));
    } else {
      Router.neglect(ctx, () => router.go(addressOf(route)));
    }
  }

  void _later(VoidCallback f) =>
      WidgetsBinding.instance.addPostFrameCallback((_) => f());

  /// Stops the timer of a back that has not come in yet.
  void dispose() => _backGuard?.cancel();
}
