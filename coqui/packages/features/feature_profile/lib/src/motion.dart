/// Feature-local motion waits for `feature_profile` (N8.16).
library;

import 'package:coqui_ui/coqui_ui.dart';

/// Named screen-local waits for Me and Your languages.
abstract final class ProfileMotion {
  /// Wait after tapping another language in `LanguagesSheet` before closing
  /// and switching course (`Noche-Motion-Idioma.dc.html`).
  static final Duration languageSwitchDelay = NocheMotion.ms(420);

  /// Delay before Listening and Speaking progress bars grow from zero in
  /// `settle` on the Me tab (`Noche-Motion-Tabs.dc.html`).
  static final Duration meSkillBarsDelay = NocheMotion.ms(180);
}
