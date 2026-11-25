/// Noche "Your languages" bottom sheet (`LanguagesRoute`, board:
/// `docs/proyecto/noche/Noche-Idiomas.dc.html`, story N2.10 / issue #93).
library;

import 'dart:async';
import 'dart:ui' show SemanticsRole;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/languages_data.dart';
import 'package:material_ui/material_ui.dart';

/// Sheet title (`Noche-Idiomas.dc.html:25`).
const String languagesSheetTitle = 'Your languages';

/// Section heading for catalog languages with no progress yet (`Noche-Idiomas.dc.html:46`).
const String addLanguageHeading = 'Add a language';

/// Trailing action label on non-current started language cards (`Noche-Idiomas.dc.html:42`).
const String switchLanguageLabel = 'Switch';

/// Accessibility label for the sheet container (`Noche-Idiomas.dc.html:22`).
const String languagesSectionA11y = 'Languages';

/// Accessibility label for the started-languages radio group (`Noche-Idiomas.dc.html:29`).
const String languagesRadioGroupA11y = 'Language you are learning now';

/// Foot note (`Noche-Idiomas.dc.html:62`, copied letter for letter).
const String languagesFootLine =
    'Each language keeps its own map and its own words. Your streak and your minutes count across all of them.';

/// The "Your languages" bottom sheet rendered on `LanguagesRoute`, over the
/// underlying screen dimmed with [NocheColors.scrim].
class LanguagesSheet extends StatefulWidget {
  const LanguagesSheet({
    super.key,
    required this.services,
    this.source,
    this.onClose,
    this.respectSafeArea = true,
  });

  final Services services;

  /// Optional multi-language source (defaults to [ServicesLanguagesSource]).
  final LanguagesSource? source;

  /// Optional close callback (defaults to `services.nav.back`).
  final VoidCallback? onClose;

  /// Forwarded to [NocheSheet.respectSafeArea].
  final bool respectSafeArea;

  @override
  State<LanguagesSheet> createState() => _LanguagesSheetState();
}

class _LanguagesSheetState extends State<LanguagesSheet> {
  late LanguagesSource _source;
  StreamSubscription<void>? _changes;

  @override
  void initState() {
    super.initState();
    _bindSource();
  }

  void _bindSource() {
    _changes?.cancel();
    _source = widget.source ?? ServicesLanguagesSource(widget.services);
    _changes = _source.changes.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(LanguagesSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.source, widget.source) ||
        !identical(oldWidget.services, widget.services)) {
      _bindSource();
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  void _close() {
    final close = widget.onClose;
    if (close != null) {
      close();
    } else {
      widget.services.nav.back();
    }
  }

  void _onSelectLanguage(LanguageEntry entry, {required bool isCurrent}) {
    widget.services.haptics.tick();
    if (isCurrent) {
      _close();
      return;
    }
    _source.selectLanguage(entry.language.code);
    widget.services.nav.go(const TabRoute(NocheTabs.map));
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final partition = partitionLanguages(_source);
    final yourLanguages = partition.yourLanguages;
    final addable = partition.addableLanguages;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: languagesSectionA11y,
      child: NocheSheetOverlay(
        onScrimTap: _close,
        sheet: NocheSheet(
          title: languagesSheetTitle,
          onClose: _close,
          closeLabel: NocheA11y.label(NocheA11y.closeSheet),
          respectSafeArea: widget.respectSafeArea,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                container: true,
                explicitChildNodes: true,
                role: SemanticsRole.radioGroup,
                label: languagesRadioGroupA11y,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < yourLanguages.length; i++) ...[
                      if (i > 0) const SizedBox(height: NocheSize.grid),
                      _LanguageRadioCard(
                        key: ValueKey(
                          'language-card-${yourLanguages[i].language.code}',
                        ),
                        entry: yourLanguages[i],
                        selected:
                            yourLanguages[i].language.code ==
                            partition.currentCode,
                        onPressed: () => _onSelectLanguage(
                          yourLanguages[i],
                          isCurrent:
                              yourLanguages[i].language.code ==
                              partition.currentCode,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (addable.isNotEmpty) ...[
                const SizedBox(height: NocheSize.grid * 3),
                const NocheSectionLabel(
                  addLanguageHeading,
                  bottomGap: NocheSize.grid,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < addable.length; i++)
                      _AddLanguageRow(
                        key: ValueKey(
                          'add-language-${addable[i].language.code}',
                        ),
                        language: addable[i].language,
                        showBottomBorder: i < addable.length - 1,
                        onPressed: () =>
                            _onSelectLanguage(addable[i], isCurrent: false),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: NocheSize.grid * 2),
              Text(
                languagesFootLine,
                textDirection: TextDirection.ltr,
                textAlign: Directionality.of(context) == TextDirection.rtl
                    ? TextAlign.end
                    : TextAlign.start,
                style: NocheType.body.copyWith(color: NocheColors.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 72-high radio card for a language with progress (`Noche-Idiomas.dc.html:30-43`).
class _LanguageRadioCard extends StatefulWidget {
  const _LanguageRadioCard({
    super.key,
    required this.entry,
    required this.selected,
    required this.onPressed,
  });

  final LanguageEntry entry;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_LanguageRadioCard> createState() => _LanguageRadioCardState();
}

class _LanguageRadioCardState extends State<_LanguageRadioCard> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final selected = widget.selected;
    final name = entry.language.englishName;
    final summary = entry.summaryLine;
    final semanticLabel = selected
        ? '$name, $summary, current language'
        : '$name, $summary, $switchLanguageLabel';

    final titleStyle = NocheType.row.copyWith(color: NocheColors.text);
    final summaryStyle = NocheType.bodySmall.copyWith(
      fontSize: 14,
      height: 16 / 14,
      color: NocheColors.label,
    );

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: semanticLabel,
      onTap: widget.onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setDown(true),
          onTapUp: (_) => _setDown(false),
          onTapCancel: () => _setDown(false),
          onTap: widget.onPressed,
          child: ExcludeSemantics(
            child: Transform.scale(
              scale: _down ? 0.99 : 1,
              child: Container(
                constraints: const BoxConstraints(minHeight: 72),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: NocheColors.ground,
                  border: Border.all(
                    color: selected ? NocheColors.text : NocheColors.line,
                    width: selected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(NocheSize.cardRadius),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                          Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: summaryStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (selected)
                      Container(
                        width: 32,
                        height: 32,
                        alignment: AlignmentDirectional.center,
                        decoration: const BoxDecoration(
                          color: NocheColors.text,
                          shape: BoxShape.circle,
                        ),
                        child: const NocheIcon(
                          NocheIcons.check,
                          size: 18,
                          color: NocheColors.ground,
                        ),
                      )
                    else
                      Text(
                        switchLanguageLabel,
                        maxLines: 1,
                        softWrap: false,
                        style: NocheType.button.copyWith(
                          color: NocheColors.label,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 56-high row for a catalog language with no progress yet (`Noche-Idiomas.dc.html:48-59`).
class _AddLanguageRow extends StatelessWidget {
  const _AddLanguageRow({
    super.key,
    required this.language,
    required this.showBottomBorder,
    required this.onPressed,
  });

  final Language language;
  final bool showBottomBorder;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final nativeDirection = language.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final englishStyle = NocheType.rowTitle.copyWith(
      fontWeight: FontWeight.w600,
      height: 20 / 16,
      color: NocheColors.text,
    );
    final nativeStyle = NocheType.forScript(
      NocheType.bodyLarge,
      language.script,
    ).copyWith(color: NocheColors.label);

    return Pressable(
      onPressed: onPressed,
      semanticLabel: 'Add ${language.englishName}',
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.99 : 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
          decoration: showBottomBorder
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: NocheColors.line, width: 1),
                  ),
                )
              : null,
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: NocheSize.grid,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      language.englishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: englishStyle,
                    ),
                    Directionality(
                      textDirection: nativeDirection,
                      child: Text(
                        language.nativeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        locale: Locale(language.code),
                        textDirection: nativeDirection,
                        style: nativeStyle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: NocheSize.grid),
              const NocheIcon(
                NocheIcons.plus,
                size: 22,
                color: NocheColors.text,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
