/// Motion constants and directional helpers for `feature_words` (story N8.10).
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/words_view.dart';

/// Motion timing and travel direction rules for the Words tab.
abstract final class WordsMotion {
  /// Wait before the 5-column return bar chart begins growing on arrival
  /// (`Noche-Motion-Tabs.dc.html` `.pane.on .bar`, 120 ms).
  static const Duration chartArrivalDelay = NocheMotion.rowsAfter;

  /// Base wait passed to [NocheArrive] for the primary review action so it
  /// begins at `followAfter + nextDelay` (140 ms) and lands last after the
  /// chart and word list begin arriving (`Noche-Motion-Tabs.dc.html`
  /// `.pane.on .next`).
  static const Duration reviewActionDelay = NocheMotion.followAfter;

  /// Travel distance for the skill-switched word list (16 px).
  static const double skillListDistance = NocheMotion.tab;

  /// Directional entry side for [NocheFollow] when switching from [from] to
  /// [to]: forward switches enter from the end side, backward switches enter
  /// from the start side (mirrored automatically by [NocheFollow] in RTL).
  static NocheFollowSide skillFollowSide({
    required WordsSkill from,
    required WordsSkill to,
  }) => to.index >= from.index ? NocheFollowSide.end : NocheFollowSide.start;
}
