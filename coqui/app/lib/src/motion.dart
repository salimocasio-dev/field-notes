/// Shell-local motion timing and spacing constants (`Noche-Motion-Carga.dc.html`).
library;

import 'package:coqui_ui/coqui_ui.dart';

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
