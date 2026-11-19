/// The tabs, the tab bar and the lesson screens.
library;

import 'package:app/src/addresses.dart';
import 'package:app/src/navigator.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

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
  });

  final Services services;
  final List<FeatureModule> modules;
  final ShellNavigator nav;

  /// What the address says to show.
  final AppRoute route;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final Map<String, WidgetBuilder> _tabs = {};

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
    final route = widget.nav.arrive(widget.route);
    final lesson = route is TabRoute ? null : _lesson(route);
    final tab = route is TabRoute ? route.tab : widget.nav.origin;
    _tab(tab);
    return PopScope(
      canPop: lesson == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.nav.back();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final id in tabIds)
            if (_tabs[id] != null)
              KeyedSubtree(
                key: ValueKey('tab:$id'),
                child: Offstage(
                  offstage: lesson != null || id != tab,
                  child: TickerMode(
                    enabled: lesson == null && id == tab,
                    child: Builder(builder: _tabs[id]!),
                  ),
                ),
              ),
          if (lesson == null)
            Positioned(
              key: const ValueKey('tab-bar'),
              left: 0,
              right: 0,
              bottom: 0,
              child: CoquiTabBar(selectedId: tab, onTap: _onTab),
            )
          else
            KeyedSubtree(
              key: ValueKey('lesson:${addressOf(route)}'),
              child: lesson,
            ),
        ],
      ),
    );
  }
}
