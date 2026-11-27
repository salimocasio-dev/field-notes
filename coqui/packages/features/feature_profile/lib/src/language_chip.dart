/// Noche language switcher chip (`Noche-Mapa.dc.html:22`, `Noche-Yo.dc.html:49`).
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// 48-high directional pill showing the current language's English name,
/// an optional CEFR [level] in [NocheColors.label], and a 16 px downward
/// chevron. Opens [LanguagesRoute] when tapped.
class LanguageChip extends StatelessWidget {
  const LanguageChip({
    super.key,
    required this.language,
    required this.onPressed,
    this.level,
    this.onPanel = false,
  });

  final Language language;
  final VoidCallback onPressed;

  /// Optional CEFR level label (e.g. from the course or progress store).
  final String? level;

  /// When `true` (e.g. inside a card on the Me screen), uses [NocheColors.ground]
  /// fill and 16 px label text; when `false` (on ground/map), uses
  /// [NocheColors.panel] fill and [NocheType.buttonStrong] (14 px).
  final bool onPanel;

  @override
  Widget build(BuildContext context) {
    final name = language.englishName;
    final hasLevel = level != null && level!.isNotEmpty;
    final semanticLabel = hasLevel
        ? '$name, level $level. Change language.'
        : '$name. Change language.';
    final nameStyle = onPanel
        ? NocheType.rowTitle.copyWith(color: NocheColors.text)
        : NocheType.buttonStrong.copyWith(color: NocheColors.text);
    final levelStyle = NocheType.button.copyWith(
      fontWeight: FontWeight.w500,
      color: NocheColors.label,
    );

    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, _) => Container(
        height: NocheSize.touch,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 12, 0),
        decoration: BoxDecoration(
          color: onPanel ? NocheColors.ground : NocheColors.panel,
          border: Border.all(color: NocheColors.line, width: 1),
          borderRadius: BorderRadius.circular(NocheSize.pillRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, maxLines: 1, softWrap: false, style: nameStyle),
            if (hasLevel) ...[
              const SizedBox(width: NocheSize.grid),
              Text(level!, maxLines: 1, softWrap: false, style: levelStyle),
            ],
            const SizedBox(width: NocheSize.grid),
            const NocheIcon(
              NocheIcons.chevronDown,
              size: 16,
              color: NocheColors.text,
            ),
          ],
        ),
      ),
    );
  }
}
