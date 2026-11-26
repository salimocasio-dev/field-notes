/// Tab identifiers and legacy fallback labels still referenced by feature
/// modules (`NocheTabBar` in `noche_chrome.dart` draws the tab bar).
library;

import 'package:coqui_ui/src/icons.dart';
import 'package:coqui_ui/src/labels.dart';

/// One tab descriptor: its id (`library`, `words`, `map`, `speak`, `me`),
/// fallback label, and legacy icon.
class CoquiTabItem {
  const CoquiTabItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final CoquiIconData icon;
}

/// The five tab ids and fallback labels still referenced by feature modules.
abstract final class CoquiTabs {
  static const libraryId = 'library';
  static const wordsId = 'words';
  static const mapId = 'map';
  static const speakId = 'speak';
  static const meId = 'me';

  static final library = CoquiTabItem(
    id: libraryId,
    label: CoquiLabels.library,
    icon: CoquiIcons.book,
  );
  static final words = CoquiTabItem(
    id: wordsId,
    label: CoquiLabels.words,
    icon: CoquiIcons.cards,
  );
  static final map = CoquiTabItem(
    id: mapId,
    label: CoquiLabels.map,
    icon: CoquiIcons.map,
  );
  static final speak = CoquiTabItem(
    id: speakId,
    label: CoquiLabels.speak,
    icon: CoquiIcons.mic,
  );
  static final me = CoquiTabItem(
    id: meId,
    label: CoquiLabels.me,
    icon: CoquiIcons.me,
  );

  /// The five tabs in order: the map in the middle.
  static final all = [library, words, map, speak, me];
}
