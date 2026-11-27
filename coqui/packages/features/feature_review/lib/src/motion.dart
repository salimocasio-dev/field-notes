/// Feature-local motion waits and loop periods for `feature_review`
/// (`docs/proyecto/24-noche-motion.md` Part 1.2 & Part 2 "Review").
///
/// This is the only file under `feature_review/lib/` allowed to call
/// [NocheMotion.ms]; raw duration and curve literals are forbidden across `lib/`.
library;

import 'package:coqui_ui/coqui_ui.dart' show NocheMotion;

/// Named screen-local waits and durations for review and level-check screens.
abstract final class ReviewMotion {
  /// Converts a millisecond wait from session timing logic into a [Duration].
  static Duration ms(int milliseconds) => NocheMotion.ms(milliseconds);

  /// 300 ms wait after a right answer before the progress dash fills.
  static final Duration dashFillDelay = NocheMotion.ms(300);

  /// 300 ms wait after a word arrives on the end screen before its
  /// `NocheStageBar` starts growing.
  static final Duration stageBarDelay = NocheMotion.ms(300);

  /// Wait after the old item fades out (`quick`) before new item rows start rising.
  static final Duration itemRowsDelay = NocheMotion.ms(160);

  /// Wait after the last item fades out (`quick`) before "Done" starts rising.
  static final Duration endStartDelay = NocheMotion.ms(160);

  /// Speech recognition listen timeout for Dilo (6 s).
  static final Duration speechListenLimit = NocheMotion.ms(6000);

  /// Touch sign gentle bounce period (700 ms).
  static final Duration touchSignCycle = NocheMotion.ms(700);

  /// Round speaker listening pulse cycle (900 ms).
  static final Duration speakerPulseCycle = NocheMotion.ms(900);
}
