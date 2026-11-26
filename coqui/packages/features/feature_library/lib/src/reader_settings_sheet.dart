import 'dart:ui' show SemanticsRole;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reader_model.dart';
import 'package:material_ui/material_ui.dart';

/// Resolves a settings radio-group accessibility label using the same switch as
/// [NocheA11y.label] (`NocheA11y.lessonLabelsInCourseLanguage` + `a11yWords`).
String _a11yGroup(
  String role,
  String englishFallback,
  Map<String, String>? courseWords,
) {
  if (NocheA11y.lessonLabelsInCourseLanguage && courseWords != null) {
    final candidate = courseWords[role];
    if (candidate != null && candidate.isNotEmpty) return candidate;
  }
  return englishFallback;
}

/// Noche Text and page settings sheet body (`docs/proyecto/noche/Noche-Lector-Aa.dc.html`).
class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({
    super.key,
    required this.settings,
    required this.language,
    required this.onChanged,
  });

  static const String fontHelpLine =
      'No font is fastest for everyone. Keep the one you read most easily.';
  static const String underlineWordsLabel =
      "Underline words I'm still learning";
  static const String lightUpSentenceLabel = 'Light up the sentence being read';

  final ReaderSettings settings;
  final Language language;
  final ValueChanged<ReaderSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final a11yWords = language.a11yWords;
    final stepText = 'Step ${settings.step} of 7';
    final canDecrease = settings.step > 1;
    final canIncrease = settings.step < 7;
    final activeFont = settings.effectiveFont;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NocheSectionLabel(
          'Text size',
          bottomGap: NocheSize.grid,
          trailing: Text(
            stepText,
            style: NocheType.label.copyWith(
              letterSpacing: 0,
              color: NocheColors.label,
            ),
          ),
        ),
        Row(
          children: [
            _TextSizeButton(
              fontSize: 15,
              semanticLabel: NocheA11y.label(
                NocheA11y.smallerText,
                courseWords: a11yWords,
              ),
              onPressed: canDecrease
                  ? () => onChanged(settings.copyWith(step: settings.step - 1))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NocheDashes.progress(
                count: 7,
                done: settings.step,
                gap: 4,
                semanticLabel: stepText,
              ),
            ),
            const SizedBox(width: 12),
            _TextSizeButton(
              fontSize: 24,
              semanticLabel: NocheA11y.label(
                NocheA11y.largerText,
                courseWords: a11yWords,
              ),
              onPressed: canIncrease
                  ? () => onChanged(settings.copyWith(step: settings.step + 1))
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const NocheSectionLabel('Font', bottomGap: NocheSize.grid),
        Semantics(
          container: true,
          role: SemanticsRole.radioGroup,
          label: _a11yGroup('font', 'Font', a11yWords),
          child: Row(
            children: [
              Expanded(
                child: _FontTile(
                  font: ReaderFont.literata,
                  name: 'Literata',
                  selected: activeFont == ReaderFont.literata,
                  onTap: () =>
                      onChanged(settings.copyWith(font: ReaderFont.literata)),
                ),
              ),
              const SizedBox(width: NocheSize.grid),
              Expanded(
                child: _FontTile(
                  font: ReaderFont.atkinson,
                  name: 'Atkinson',
                  selected: activeFont == ReaderFont.atkinson,
                  onTap: () =>
                      onChanged(settings.copyWith(font: ReaderFont.atkinson)),
                ),
              ),
              const SizedBox(width: NocheSize.grid),
              Expanded(
                child: _FontTile(
                  font: ReaderFont.lexend,
                  name: 'Lexend',
                  selected: activeFont == ReaderFont.lexend,
                  // Disabled until coqui_ui exposes NocheType.bookBodyLexend
                  // (coqui/requests/113-feature-library-needs-coqui-ui-reader-font-styles.md).
                  onTap: ReaderSettings.lexendAvailable
                      ? () => onChanged(
                          settings.copyWith(font: ReaderFont.lexend),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NocheSize.grid),
        Text(
          fontHelpLine,
          style: NocheType.bodySmall.copyWith(
            fontSize: 12,
            height: 16 / 12,
            color: NocheColors.label,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const NocheSectionLabel(
                    'Line spacing',
                    bottomGap: NocheSize.grid,
                  ),
                  _LineSpacingControl(
                    selected: settings.spacing,
                    a11yWords: a11yWords,
                    onChanged: (spacing) =>
                        onChanged(settings.copyWith(spacing: spacing)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const NocheSectionLabel('Page', bottomGap: NocheSize.grid),
                  _PageColorControl(
                    selected: settings.page,
                    a11yWords: a11yWords,
                    onChanged: (page) =>
                        onChanged(settings.copyWith(page: page)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        NocheSwitchRow(
          label: underlineWordsLabel,
          value: settings.underlineWords,
          onChanged: (value) =>
              onChanged(settings.copyWith(underlineWords: value)),
        ),
        NocheSwitchRow(
          label: lightUpSentenceLabel,
          value: settings.lightUpSentence,
          onChanged: (value) =>
              onChanged(settings.copyWith(lightUpSentence: value)),
        ),
      ],
    );
  }
}

class _TextSizeButton extends StatelessWidget {
  const _TextSizeButton({
    required this.fontSize,
    required this.semanticLabel,
    required this.onPressed,
  });

  final double fontSize;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.96 : 1,
        child: Container(
          width: 56,
          height: NocheSize.touch,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            border: Border.all(color: NocheColors.line, width: 1),
            borderRadius: BorderRadius.circular(NocheSize.pillRadius),
          ),
          child: Text(
            'A',
            style: NocheType.bookTitle.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
              height: 1,
              color: enabled ? NocheColors.text : NocheColors.label,
            ),
          ),
        ),
      ),
    );
  }
}

class _FontTile extends StatelessWidget {
  const _FontTile({
    required this.font,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final ReaderFont font;
  final String name;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final sampleColor = enabled ? NocheColors.text : NocheColors.label;
    return _RadioOption(
      semanticLabel: name,
      selected: selected,
      onTap: onTap,
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.98 : 1,
        child: Container(
          height: 80,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            color: selected ? NocheColors.chip : Colors.transparent,
            border: Border.all(
              color: selected ? NocheColors.text : NocheColors.line,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(NocheSize.tileRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ag',
                style: ReaderSettings.previewStyleFor(font, sampleColor),
              ),
              const SizedBox(height: NocheSize.grid),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (selected ? NocheType.tabLabelOn : NocheType.tabLabel)
                    .copyWith(
                      color: selected ? NocheColors.text : NocheColors.label,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineSpacingControl extends StatelessWidget {
  const _LineSpacingControl({
    required this.selected,
    required this.a11yWords,
    required this.onChanged,
  });

  final ReaderLineSpacing selected;
  final Map<String, String>? a11yWords;
  final ValueChanged<ReaderLineSpacing> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <(ReaderLineSpacing, NocheIconData, String)>[
      (
        ReaderLineSpacing.tight,
        NocheIcons.lineSpacingTight,
        NocheA11y.label(NocheA11y.lineSpacingTight, courseWords: a11yWords),
      ),
      (
        ReaderLineSpacing.normal,
        NocheIcons.lineSpacingNormal,
        NocheA11y.label(NocheA11y.lineSpacingNormal, courseWords: a11yWords),
      ),
      (
        ReaderLineSpacing.loose,
        NocheIcons.lineSpacingLoose,
        NocheA11y.label(NocheA11y.lineSpacingLoose, courseWords: a11yWords),
      ),
    ];

    return Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      label: _a11yGroup('lineSpacing', 'Line spacing', a11yWords),
      child: Container(
        height: NocheSize.touch + 2,
        decoration: BoxDecoration(
          border: Border.all(color: NocheColors.line, width: 1),
          borderRadius: BorderRadius.circular(NocheSize.pillRadius + 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(NocheSize.pillRadius),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (value, icon, label) in options)
                Expanded(
                  child: _RadioOption(
                    semanticLabel: label,
                    selected: value == selected,
                    onTap: () => onChanged(value),
                    builder: (context, pressed) {
                      final isSelected = value == selected;
                      return Transform.scale(
                        scale: pressed ? 0.96 : 1,
                        child: Container(
                          alignment: AlignmentDirectional.center,
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: NocheColors.text,
                                  borderRadius: BorderRadius.circular(
                                    NocheSize.pillRadius,
                                  ),
                                )
                              : null,
                          child: NocheIcon(
                            icon,
                            size: 22,
                            strokeWidth: 2,
                            color: isSelected
                                ? NocheColors.ground
                                : NocheColors.label,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageColorControl extends StatelessWidget {
  const _PageColorControl({
    required this.selected,
    required this.a11yWords,
    required this.onChanged,
  });

  final ReaderPageTheme selected;
  final Map<String, String>? a11yWords;
  final ValueChanged<ReaderPageTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    final options =
        <
          (
            ReaderPageTheme,
            Color fill,
            Color ink,
            Color? unselectedBorder,
            String,
          )
        >[
          (
            ReaderPageTheme.night,
            NocheColors.lessonGround,
            NocheColors.nightText,
            NocheColors.bar,
            NocheA11y.label(NocheA11y.pageNight, courseWords: a11yWords),
          ),
          (
            ReaderPageTheme.sepia,
            NocheColors.sepiaPage,
            NocheColors.sepiaText,
            null,
            NocheA11y.label(NocheA11y.pageSepia, courseWords: a11yWords),
          ),
          (
            ReaderPageTheme.day,
            NocheColors.dayPage,
            NocheColors.dayText,
            null,
            NocheA11y.label(NocheA11y.pageDay, courseWords: a11yWords),
          ),
        ];

    return Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      label: _a11yGroup('pageColour', 'Page colour', a11yWords),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: NocheSize.grid),
            Expanded(
              child: _PageColorPill(
                fill: options[i].$2,
                ink: options[i].$3,
                unselectedBorder: options[i].$4,
                semanticLabel: options[i].$5,
                selected: options[i].$1 == selected,
                onTap: () => onChanged(options[i].$1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PageColorPill extends StatelessWidget {
  const _PageColorPill({
    required this.fill,
    required this.ink,
    required this.unselectedBorder,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final Color fill;
  final Color ink;
  final Color? unselectedBorder;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _RadioOption(
      semanticLabel: semanticLabel,
      selected: selected,
      onTap: onTap,
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.96 : 1,
        child: Container(
          height: NocheSize.touch,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(NocheSize.pillRadius),
            border: !selected && unselectedBorder != null
                ? Border.all(color: unselectedBorder!, width: 1)
                : null,
            // Paint outer 4px text ring first, then inner 2px panel ring over it
            // (matches CSS `box-shadow: 0 0 0 2px #152A3D, 0 0 0 4px #EEF3F7`).
            boxShadow: selected
                ? const [
                    BoxShadow(color: NocheColors.text, spreadRadius: 4),
                    BoxShadow(color: NocheColors.panel, spreadRadius: 2),
                  ]
                : null,
          ),
          child: Text(
            'A',
            style: NocheType.bookTitle.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 1,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioOption extends StatefulWidget {
  const _RadioOption({
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    required this.builder,
  });

  final String semanticLabel;
  final bool selected;
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool pressed) builder;

  @override
  State<_RadioOption> createState() => _RadioOptionState();
}

class _RadioOptionState extends State<_RadioOption> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      checked: widget.selected,
      label: widget.semanticLabel,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: widget.onTap,
          child: ExcludeSemantics(child: widget.builder(context, _down)),
        ),
      ),
    );
  }
}
