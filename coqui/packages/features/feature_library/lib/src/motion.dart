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

  /// Wait after the write-story sheet starts closing before the new story
  /// begins landing on the Stories shelf (`Noche-Motion-Escribir.dc.html`:
  /// `1900 -> 2160`).
  static final Duration shelfInsertAfter = NocheMotion.ms(260);

  /// Delay before the newly created story fades in while existing stories
  /// travel over in `move` on `travel` (`Noche-Motion-Escribir.dc.html` line 59).
  static final Duration shelfInsertFadeDelay = NocheMotion.ms(160);
}
