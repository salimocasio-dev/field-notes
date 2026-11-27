/// Motion timing constants and helpers for `feature_story`
/// (`docs/proyecto/24-noche-motion.md` Part 1.2 & story N8.8).
///
/// This is the only file under `feature_story/lib/` permitted to call
/// [NocheMotion.ms]. All shared durations, curves, and distances come directly
/// from [NocheMotion] / [NocheMotionData].
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Screen-local waits, hero tags, and reduced-motion resolution for the story
/// lesson screen (`docs/proyecto/24-noche-motion.md`, N8.8).
abstract final class StoryMotion {
  /// Shared [NocheWindow] tag connecting a story's picture across map, place,
  /// and story lesson screens (matches `MapMotion.storyWindowTag`).
  static String storyWindowTag(String storyId) => storyId;

  /// Resolves effective [NocheMotionData], honouring both ambient
  /// `MediaQuery.disableAnimations` and `services.reduceMotion`.
  static NocheMotionData resolve(
    BuildContext context, {
    required bool serviceReduceMotion,
  }) {
    final ambient = NocheMotion.of(context);
    if (ambient.reduced || serviceReduceMotion) return NocheMotion.reduced;
    return ambient;
  }

  /// Wait before the lesson's speaker row rises on arrival (`160 ms`); line
  /// follows at `190 ms` and prompt at `220 ms` (`stagger = 30 ms`).
  static final Duration lessonArriveDelay = NocheMotion.ms(160);

  /// Wait before the lesson's bottom controls land on arrival (`300 ms`).
  static final Duration controlsArriveDelay = NocheMotion.ms(300);

  /// Wait after an old turn starts fading (`quick`) before the new turn's rows
  /// start rising (`160 ms`).
  static final Duration turnRowsDelay = NocheMotion.ms(160);

  /// How long a speaking turn holds `notYet` before replaying the prompt line
  /// (`900 ms`).
  static final Duration missHold = NocheMotion.ms(900);

  /// Wait after a right speaking answer before the part's dash fills (`600 ms`).
  static final Duration rightDashDelay = NocheMotion.ms(600);

  /// Wait after the dash fills before the next turn arrives (`700 ms`).
  static final Duration rightNextTurnDelay = NocheMotion.ms(700);

  /// Fallback hold for a touch-turn miss outline when there is no replay clip
  /// end to listen for (`1300 ms`).
  static final Duration touchMissHold = NocheMotion.ms(1300);

  /// How long a touch-turn right outline holds before fading out (`900 ms`).
  static final Duration touchHitHold = NocheMotion.ms(900);

  /// Wait before the end-of-story summary rows start rising (`200 ms`).
  static final Duration endRowsDelay = NocheMotion.ms(200);

  /// Wait before the first new-word [NocheStageBar] starts growing (`520 ms`).
  static final Duration endStageBarDelay = NocheMotion.ms(520);

  /// Wait before the "Today" minutes [NocheProgressBar] starts growing (`700 ms`).
  static final Duration endMinutesBarDelay = NocheMotion.ms(700);

  /// Wait before the end-of-story orange next action rises (`860 ms`).
  static final Duration endNextDelay = NocheMotion.ms(860);

  /// Live loop period for the speaking-turn flanking level bars (`900 ms`).
  static final Duration levelAnimCycle = NocheMotion.ms(900);

  /// Live loop periods for the three small replay level bars beside a touch
  /// turn's line (`640 ms`, `480 ms`, `760 ms`).
  static final Duration smallBarCycleA = NocheMotion.ms(640);
  static final Duration smallBarCycleB = NocheMotion.ms(480);
  static final Duration smallBarCycleC = NocheMotion.ms(760);

  /// Live loop period for the legacy over-scene speech bubble dots/mic (`1200 ms`).
  static final Duration bubbleLoopCycle = NocheMotion.ms(1200);

  /// Fade duration for the over-scene speech bubble (`120 ms`).
  static final Duration bubbleFade = NocheMotion.ms(120);
}
