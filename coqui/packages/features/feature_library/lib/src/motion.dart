/// Screen-local motion tokens and waits for `feature_library`
/// (`docs/proyecto/24-noche-motion.md`, Part 1.2).
///
/// This is the only file in `feature_library` allowed to call
/// `NocheMotion.ms(...)`. No literal duration or curve constructors are used
/// anywhere under `lib/`.
library;

import 'package:coqui_ui/coqui_ui.dart';

/// Named motion durations and waits for `feature_library`.
abstract final class LibraryMotion {
  /// Duration of the new-story slot cross-fade when `canWrite` changes on
  /// screen (`Noche-Biblioteca-Cerrado.dc.html`: 140 ms = `NocheMotion.quick`).
  static Duration slotFade(NocheMotionData motion) => motion.quick;
}
