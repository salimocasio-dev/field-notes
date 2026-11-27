/// Shell-local motion timing and spacing constants (`Noche-Motion-Carga.dc.html`).
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Motion durations and dimensions specific to the app shell (`coqui/app/`).
abstract final class ShellMotion {
  /// Silent delay before boot loading dots and message appear.
  static final Duration loadSilentDelay = NocheMotion.ms(300);

  /// Stagger between the three loading dots over [NocheMotion.thinkingCycle].
  static final Duration loadDotStagger = NocheMotion.ms(150);

  /// Delay before the tab bar rises from below on initial course load.
  static final Duration loadTabBarDelay = NocheMotion.ms(160);

  /// Distance [NocheTabBar] sinks below its resting place on full-screen routes
  /// and rises from on initial load.
  static const double tabBarSinkDistance = 96.0;

  /// Diameter of each loading dot.
  static const double loadDotSize = 12.0;

  /// Gap between loading dots.
  static const double loadDotGap = NocheSize.grid;

  /// Gap between dots/failure message and line/action button (`margin-top: 20px`).
  static const double loadLineGap = 20.0;
}

/// Resolves the effective [NocheMotionData] for shell transitions, honouring
/// both ambient `MediaQuery.disableAnimations` and `services.reduceMotion`.
NocheMotionData resolveShellMotion(
  BuildContext context, {
  required bool serviceReduceMotion,
}) {
  final ambient = NocheMotion.of(context);
  if (ambient.reduced || serviceReduceMotion) return NocheMotion.reduced;
  return ambient;
}

/// Declarative [Page] backed by an opaque pass-through [PageRoute] using
/// Noche route transition durations so screens run their own fade/rise
/// choreography and [Hero] flights.
class NocheShellPage<T> extends Page<T> {
  const NocheShellPage({
    required LocalKey super.key,
    required this.child,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
    super.name,
  });

  final Widget child;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  @override
  Route<T> createRoute(BuildContext context) =>
      _NocheShellPageRoute<T>(page: this);
}

class _NocheShellPageRoute<T> extends PageRoute<T> {
  _NocheShellPageRoute({required NocheShellPage<T> page})
    : super(settings: page);

  NocheShellPage<T> get _page => settings as NocheShellPage<T>;

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _page.reverseTransitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _page.child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
