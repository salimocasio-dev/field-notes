/// The bottom tab bar with the raised Mapa disc (app.html:59-66, 136-137), and
/// the chips at the top of the map (app.html:38-39).
library;

import 'package:coqui_ui/src/icons.dart';
import 'package:coqui_ui/src/layout.dart';
import 'package:coqui_ui/src/pressable.dart';
import 'package:coqui_ui/src/text_styles.dart';
import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// One tab: its id (the `TabRoute` ids: `library`, `words`, `map`, `speak`,
/// `me`), its label and its icon. app.html:192 (`TABS`)
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

/// The five tabs of v=39, in order, with its labels and icons: Biblioteca,
/// Palabras, Mapa, Hablar, Yo. app.html:192 (`TABS`, labels in Spanish as the
/// page hard-codes them), app.html:190-191 (`IC`).
abstract final class CoquiTabs {
  static const libraryId = 'library';
  static const wordsId = 'words';
  static const mapId = 'map';
  static const speakId = 'speak';
  static const meId = 'me';

  static final library = CoquiTabItem(
    id: libraryId,
    label: 'Biblioteca',
    icon: CoquiIcons.book,
  );
  static final words = CoquiTabItem(
    id: wordsId,
    label: 'Palabras',
    icon: CoquiIcons.cards,
  );
  static final map = CoquiTabItem(
    id: mapId,
    label: 'Mapa',
    icon: CoquiIcons.map,
  );
  static final speak = CoquiTabItem(
    id: speakId,
    label: 'Hablar',
    icon: CoquiIcons.mic,
  );
  static final me = CoquiTabItem(id: meId, label: 'Yo', icon: CoquiIcons.me);

  /// The five, in the old order: the map in the middle.
  static final all = [library, words, map, speak, me];
}

/// `nav`: a white bar [CoquiMetrics.navHeight] high (+ the safe area) with a
/// hairline on top, five equal tabs in a column at most 560 px wide; the tab
/// whose id is [raisedId] is the round disc standing [CoquiMetrics.rise] above
/// the bar. Its label sits with the others'. The selected tab is blue.
///
/// The widget's own height is `rise + navHeight + safe area`: the region above
/// the bar is transparent and passes touches through, except on the disc. Use
/// [CoquiLayout.tabBarHeight] for the bar proper.
class CoquiTabBar extends StatelessWidget {
  CoquiTabBar({
    super.key,
    List<CoquiTabItem>? items,
    required this.selectedId,
    required this.onTap,
    this.raisedId = CoquiTabs.mapId,
  }) : items = items ?? CoquiTabs.all;

  final List<CoquiTabItem> items;
  final String selectedId;

  /// Called with the tapped tab's id.
  final ValueChanged<String> onTap;
  final String raisedId;

  @override
  Widget build(BuildContext context) {
    final compact = CoquiLayout.compact(context);
    final navH = CoquiLayout.navHeight(context);
    final rise = CoquiLayout.rise(context);
    final safe = CoquiLayout.safeBottom(context);
    final raisedIndex = items.indexWhere((t) => t.id == raisedId);
    return SizedBox(
      height: rise + navH + safe,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // nav: the white bar and its hairline. app.html:60
          Positioned(
            left: 0,
            right: 0,
            top: rise,
            bottom: 0,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: CoquiColors.white,
                boxShadow: CoquiShadows.navTop,
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: CoquiMetrics.columnMax,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: rise,
                      height: navH,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final t in items)
                            Expanded(
                              child: _Tab(
                                item: t,
                                selected: t.id == selectedId,
                                raised: t.id == raisedId,
                                onTap: () => onTap(t.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (raisedIndex >= 0)
                      // The disc stands outside its tab's box, so it is its own tap
                      // target here, where the whole raised height is inside the bar's box.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: Align(
                          alignment: Alignment(
                            2 * (raisedIndex + 0.5) / items.length - 1,
                            -1,
                          ),
                          child: Pressable(
                            onPressed: () => onTap(items[raisedIndex].id),
                            semanticLabel: items[raisedIndex].label,
                            builder: (context, pressed) => Transform.scale(
                              scale: pressed ? 0.98 : 1,
                              child: _Disc(
                                icon: items[raisedIndex].icon,
                                selected: items[raisedIndex].id == selectedId,
                                compact: compact,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.item,
    required this.selected,
    required this.raised,
    required this.onTap,
  });

  final CoquiTabItem item;
  final bool selected;
  final bool raised;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onTap,
    semanticLabel: item.label,
    selected: selected,
    builder: (context, pressed) {
      final color = selected ? CoquiColors.info : CoquiColors.mut;
      final style = selected ? CoquiText.tabOn : CoquiText.tab;
      return Transform.scale(
        scale: pressed ? 0.98 : 1,
        // `.tb`: the label 10 px from the foot; an icon 4 px above it. app.html:62
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!raised) ...[
                CoquiIcon(item.icon, color: color),
                const SizedBox(height: CoquiMetrics.s4),
              ],
              Text(
                item.label,
                style: style,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// `.tb.mid .disc`: 56 px (44 on its side), white with a 1.5 px ring and the grey
/// map icon; active: blue, a 4 px white border (3 on its side), a blue glow and a
/// white icon. app.html:64-66, 137
class _Disc extends StatelessWidget {
  const _Disc({
    required this.icon,
    required this.selected,
    required this.compact,
  });

  final CoquiIconData icon;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? CoquiMetrics.mapDiscLandscape : CoquiMetrics.mapDisc;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? CoquiColors.info : CoquiColors.white,
        border: Border.all(
          color: selected ? CoquiColors.white : CoquiColors.line2,
          width: selected ? (compact ? 3 : 4) : CoquiMetrics.borderButton,
        ),
        boxShadow: selected ? CoquiShadows.mapDiscActive : null,
      ),
      child: CoquiIcon(
        icon,
        size: compact ? 24 : 28,
        color: selected ? CoquiColors.white : CoquiColors.mut,
      ),
    );
  }
}

/// `#topchips`: the bar over the map. A white bar 48 px high (+ the safe area at
/// the top) with a hairline under it, two flat labels (no pill, no shadow, not
/// tappable) centred 24 px apart: the streak and the place. app.html:38-39
///
/// The old page writes them in `hud()` (app.html:286): `"🔥 " + N + " day" +
/// (N === 1 ? "" : "s")` and `N + " · " + place name`. [streakLabel] and
/// [placeLabel] write the same strings.
class MapChips extends StatelessWidget {
  const MapChips({super.key, required this.streak, required this.place});

  /// The first chip, e.g. `🔥 5 days`.
  final String streak;

  /// The second chip, e.g. `2 · El parque`.
  final String place;

  /// `"🔥 " + n + " day" + (n === 1 ? "" : "s")`. app.html:286
  static String streakLabel(int days) =>
      '\u{1F525} $days day${days == 1 ? '' : 's'}';

  /// `n + " · " + name`. app.html:286
  static String placeLabel(int number, String name) => '$number · $name';

  @override
  Widget build(BuildContext context) => Container(
    height: CoquiMetrics.chipsHeight + CoquiLayout.safeTop(context),
    padding: EdgeInsets.fromLTRB(
      CoquiMetrics.s16,
      CoquiLayout.safeTop(context),
      CoquiMetrics.s16,
      0,
    ),
    decoration: const BoxDecoration(
      color: CoquiColors.white,
      border: Border(bottom: BorderSide(color: CoquiColors.line)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(streak, style: CoquiText.chip, maxLines: 1),
        const SizedBox(width: CoquiMetrics.s24),
        Text(place, style: CoquiText.chip, maxLines: 1),
      ],
    ),
  );
}
