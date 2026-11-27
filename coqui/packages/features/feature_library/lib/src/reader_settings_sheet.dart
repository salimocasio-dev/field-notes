import 'dart:ui' as ui show SemanticsRole, lerpDouble;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reader_model.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the Noche Text and page settings sheet without a scrim so the learner
/// can see the book page change live behind it (`Noche-Motion-Lector.dc.html`,
/// `Noche-Lector-Aa.dc.html`).
Future<T?> showReaderSettingsSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, VoidCallback close) builder,
  required String closeLabel,
}) {
  final motion = NocheMotion.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(
    _ReaderSettingsSheetRoute<T>(
      builder: builder,
      closeLabel: closeLabel,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      motion: motion,
    ),
  );
}

class _ReaderSettingsSheetRoute<T> extends PopupRoute<T> {
  _ReaderSettingsSheetRoute({
    required this.builder,
    required this.closeLabel,
    required this.themes,
    required this.motion,
  });

  final Widget Function(BuildContext context, VoidCallback close) builder;
  final String closeLabel;
  final CapturedThemes themes;
  final NocheMotionData motion;

  bool _closing = false;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => motion.pageIn;

  @override
  Duration get reverseTransitionDuration => motion.pageOut;

  void _close() {
    if (_closing) return;
    final nav = navigator;
    if (nav == null || !isActive) return;
    _closing = true;
    if (isCurrent) {
      nav.pop();
    } else {
      nav.removeRoute(this);
    }
  }

  @override
  Widget buildModalBarrier() => const SizedBox.shrink();

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final sheetChild = _DraggableSheetDismiss(
      onDismiss: _close,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: NocheSheet(child: Builder(builder: (c) => builder(c, _close))),
      ),
    );

    return themes.wrap(
      PopScope(
        canPop: true,
        child: AnimatedBuilder(
          animation: animation,
          child: sheetChild,
          builder: (context, child) {
            final currentMotion = NocheMotion.of(context);
            final isReverse =
                animation.status == AnimationStatus.reverse ||
                animation.status == AnimationStatus.dismissed;
            final t = animation.value.clamp(0.0, 1.0);

            final Widget sheetTransition;
            if (currentMotion.reduced) {
              final sheetOpacity = isReverse
                  ? (1.0 -
                            currentMotion.exit.transform(
                              (1.0 - t).clamp(0.0, 1.0),
                            ))
                        .clamp(0.0, 1.0)
                  : currentMotion.enter.transform(t).clamp(0.0, 1.0);
              sheetTransition = Opacity(
                key: const ValueKey('reader_settings_sheet_surface'),
                opacity: sheetOpacity,
                child: child,
              );
            } else {
              final dy = isReverse
                  ? currentMotion.exit.transform((1.0 - t).clamp(0.0, 1.0))
                  : (1.0 - currentMotion.enter.transform(t));
              sheetTransition = FractionalTranslation(
                key: const ValueKey('reader_settings_sheet_surface'),
                translation: Offset(0, dy),
                child: child,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: IgnorePointer(
                    ignoring: isReverse,
                    child: Semantics(
                      button: true,
                      label: closeLabel,
                      onTap: _close,
                      child: GestureDetector(
                        key: const Key('reader-settings-closer'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _close,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                sheetTransition,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DraggableSheetDismiss extends StatefulWidget {
  const _DraggableSheetDismiss({required this.onDismiss, required this.child});

  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<_DraggableSheetDismiss> createState() => _DraggableSheetDismissState();
}

class _DraggableSheetDismissState extends State<_DraggableSheetDismiss> {
  double _drag = 0;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _drag),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (d) =>
            setState(() => _drag = (_drag + d.delta.dy).clamp(0, 2000)),
        onVerticalDragEnd: (_) {
          final close = _drag > 72;
          setState(() => _drag = 0);
          if (close) widget.onDismiss();
        },
        onVerticalDragCancel: () => setState(() => _drag = 0),
        child: widget.child,
      ),
    );
  }
}

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
              child: _TextSizeDashes(
                step: settings.step,
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
        NocheOutlineGroup<ReaderFont>(
          key: const Key('reader-font-group'),
          axis: Axis.horizontal,
          gap: NocheSize.grid,
          borderRadius: NocheSize.tileRadius,
          outlineColor: NocheColors.text,
          outlineWidth: 2,
          markFill: NocheColors.chip,
          semanticLabel: _a11yGroup('font', 'Font', a11yWords),
          selected: activeFont,
          onChanged: (font) {
            // Disabled until coqui_ui exposes NocheType.bookBodyLexend
            // (coqui/requests/113-feature-library-needs-coqui-ui-reader-font-styles.md).
            if (font == ReaderFont.lexend && !ReaderSettings.lexendAvailable) {
              return;
            }
            onChanged(settings.copyWith(font: font));
          },
          options: [
            NocheOutlineOption<ReaderFont>(
              value: ReaderFont.literata,
              semanticLabel: 'Literata',
              child: ExcludeSemantics(
                child: _FontTileContent(
                  font: ReaderFont.literata,
                  name: 'Literata',
                  selected: activeFont == ReaderFont.literata,
                  enabled: true,
                ),
              ),
            ),
            NocheOutlineOption<ReaderFont>(
              value: ReaderFont.atkinson,
              semanticLabel: 'Atkinson',
              child: ExcludeSemantics(
                child: _FontTileContent(
                  font: ReaderFont.atkinson,
                  name: 'Atkinson',
                  selected: activeFont == ReaderFont.atkinson,
                  enabled: true,
                ),
              ),
            ),
            NocheOutlineOption<ReaderFont>(
              value: ReaderFont.lexend,
              semanticLabel: ReaderSettings.lexendAvailable ? 'Lexend' : null,
              child: ReaderSettings.lexendAvailable
                  ? ExcludeSemantics(
                      child: _FontTileContent(
                        font: ReaderFont.lexend,
                        name: 'Lexend',
                        selected: activeFont == ReaderFont.lexend,
                        enabled: true,
                      ),
                    )
                  : Semantics(
                      container: true,
                      button: true,
                      enabled: false,
                      inMutuallyExclusiveGroup: true,
                      checked: false,
                      label: 'Lexend',
                      hint: 'Unavailable until Lexend font style is added',
                      child: ExcludeSemantics(
                        child: _FontTileContent(
                          font: ReaderFont.lexend,
                          name: 'Lexend',
                          selected: activeFont == ReaderFont.lexend,
                          enabled: false,
                        ),
                      ),
                    ),
            ),
          ],
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
                    key: const Key('reader-line-spacing-control'),
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
                    key: const Key('reader-page-color-control'),
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
          key: const Key('reader-switch-underline'),
          label: underlineWordsLabel,
          value: settings.underlineWords,
          onChanged: (value) =>
              onChanged(settings.copyWith(underlineWords: value)),
        ),
        NocheSwitchRow(
          key: const Key('reader-switch-lit'),
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
      builder: (context, _) => Container(
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
    );
  }
}

class _TextSizeDashes extends StatelessWidget {
  const _TextSizeDashes({required this.step, required this.semanticLabel});

  final int step;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    return Semantics(
      label: semanticLabel,
      readOnly: true,
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: AnimatedContainer(
                  key: ValueKey('reader-size-dash-$i'),
                  duration: motion.quick,
                  curve: motion.enter,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i < step ? NocheColors.text : NocheColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FontTileContent extends StatelessWidget {
  const _FontTileContent({
    required this.font,
    required this.name,
    required this.selected,
    required this.enabled,
  });

  final ReaderFont font;
  final String name;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    final sampleColor = enabled ? NocheColors.text : NocheColors.label;
    final labelColor = selected ? NocheColors.text : NocheColors.label;
    final labelStyle = selected ? NocheType.tabLabelOn : NocheType.tabLabel;

    return AnimatedContainer(
      duration: motion.quick,
      curve: motion.enter,
      height: 80,
      alignment: AlignmentDirectional.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? Colors.transparent : NocheColors.line,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(NocheSize.tileRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Ag', style: ReaderSettings.previewStyleFor(font, sampleColor)),
          const SizedBox(height: NocheSize.grid),
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: labelColor),
            duration: motion.quick,
            curve: motion.enter,
            builder: (context, color, _) => Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle.copyWith(color: color ?? labelColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineSpacingControl extends StatefulWidget {
  const _LineSpacingControl({
    super.key,
    required this.selected,
    required this.a11yWords,
    required this.onChanged,
  });

  final ReaderLineSpacing selected;
  final Map<String, String>? a11yWords;
  final ValueChanged<ReaderLineSpacing> onChanged;

  @override
  State<_LineSpacingControl> createState() => _LineSpacingControlState();
}

class _LineSpacingControlState extends State<_LineSpacingControl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  );

  late double _fromIndex;
  late double _toIndex;
  bool _reducedFade = false;

  @override
  void initState() {
    super.initState();
    final initial = ReaderLineSpacing.values
        .indexOf(widget.selected)
        .toDouble();
    _fromIndex = initial;
    _toIndex = initial;
  }

  @override
  void didUpdateWidget(_LineSpacingControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == oldWidget.selected) return;

    final newIdx = ReaderLineSpacing.values.indexOf(widget.selected).toDouble();
    final oldIdx = ReaderLineSpacing.values
        .indexOf(oldWidget.selected)
        .toDouble();
    final motion = NocheMotion.of(context);
    if (motion.reduced) {
      _fromIndex = newIdx;
      _toIndex = newIdx;
      _reducedFade = true;
      _controller.duration = motion.quick;
      _controller.forward(from: 0.0);
    } else {
      final current =
          ui.lerpDouble(
            _fromIndex,
            _toIndex,
            motion.travel.transform(_controller.value),
          ) ??
          oldIdx;
      _fromIndex = current;
      _toIndex = newIdx;
      _reducedFade = false;
      _controller.duration = motion.move;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    final options = <(ReaderLineSpacing, NocheIconData, String)>[
      (
        ReaderLineSpacing.tight,
        NocheIcons.lineSpacingTight,
        NocheA11y.label(
          NocheA11y.lineSpacingTight,
          courseWords: widget.a11yWords,
        ),
      ),
      (
        ReaderLineSpacing.normal,
        NocheIcons.lineSpacingNormal,
        NocheA11y.label(
          NocheA11y.lineSpacingNormal,
          courseWords: widget.a11yWords,
        ),
      ),
      (
        ReaderLineSpacing.loose,
        NocheIcons.lineSpacingLoose,
        NocheA11y.label(
          NocheA11y.lineSpacingLoose,
          courseWords: widget.a11yWords,
        ),
      ),
    ];

    return Semantics(
      container: true,
      role: ui.SemanticsRole.radioGroup,
      label: _a11yGroup('lineSpacing', 'Line spacing', widget.a11yWords),
      child: Container(
        height: NocheSize.touch + 2,
        decoration: BoxDecoration(
          border: Border.all(color: NocheColors.line, width: 1),
          borderRadius: BorderRadius.circular(NocheSize.pillRadius + 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(NocheSize.pillRadius),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / options.length;
              return Stack(
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final activeMotion = NocheMotion.of(context);
                      final double pos;
                      final double opacity;
                      if (_reducedFade || activeMotion.reduced) {
                        pos = _toIndex;
                        opacity = _reducedFade
                            ? activeMotion.enter.transform(_controller.value)
                            : 1.0;
                      } else {
                        pos =
                            ui.lerpDouble(
                              _fromIndex,
                              _toIndex,
                              activeMotion.travel.transform(_controller.value),
                            ) ??
                            _toIndex;
                        opacity = 1.0;
                      }
                      return PositionedDirectional(
                        start: pos * slotWidth,
                        top: 0,
                        width: slotWidth,
                        height: NocheSize.touch,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: opacity,
                            child: DecoratedBox(
                              key: const ValueKey('reader-line-spacing-thumb'),
                              decoration: BoxDecoration(
                                color: NocheColors.text,
                                borderRadius: BorderRadius.circular(
                                  NocheSize.pillRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (value, icon, label) in options)
                        Expanded(
                          child: Semantics(
                            button: true,
                            inMutuallyExclusiveGroup: true,
                            checked: value == widget.selected,
                            label: label,
                            child: Pressable(
                              onPressed: () => widget.onChanged(value),
                              semanticsButton: false,
                              builder: (context, _) {
                                final targetColor = value == widget.selected
                                    ? NocheColors.ground
                                    : NocheColors.label;
                                return ExcludeSemantics(
                                  child: Container(
                                    alignment: AlignmentDirectional.center,
                                    child: TweenAnimationBuilder<Color?>(
                                      tween: ColorTween(end: targetColor),
                                      duration: motion.quick,
                                      curve: motion.enter,
                                      builder: (context, color, _) => NocheIcon(
                                        icon,
                                        size: 22,
                                        strokeWidth: 2,
                                        color: color ?? targetColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PageColorControl extends StatefulWidget {
  const _PageColorControl({
    super.key,
    required this.selected,
    required this.a11yWords,
    required this.onChanged,
  });

  final ReaderPageTheme selected;
  final Map<String, String>? a11yWords;
  final ValueChanged<ReaderPageTheme> onChanged;

  @override
  State<_PageColorControl> createState() => _PageColorControlState();
}

class _PageColorControlState extends State<_PageColorControl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  );

  late double _fromIndex;
  late double _toIndex;
  bool _reducedFade = false;

  @override
  void initState() {
    super.initState();
    final initial = ReaderPageTheme.values.indexOf(widget.selected).toDouble();
    _fromIndex = initial;
    _toIndex = initial;
  }

  @override
  void didUpdateWidget(_PageColorControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == oldWidget.selected) return;

    final newIdx = ReaderPageTheme.values.indexOf(widget.selected).toDouble();
    final oldIdx = ReaderPageTheme.values
        .indexOf(oldWidget.selected)
        .toDouble();
    final motion = NocheMotion.of(context);
    if (motion.reduced) {
      _fromIndex = newIdx;
      _toIndex = newIdx;
      _reducedFade = true;
      _controller.duration = motion.quick;
      _controller.forward(from: 0.0);
    } else {
      final current =
          ui.lerpDouble(
            _fromIndex,
            _toIndex,
            motion.travel.transform(_controller.value),
          ) ??
          oldIdx;
      _fromIndex = current;
      _toIndex = newIdx;
      _reducedFade = false;
      _controller.duration = motion.move;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options =
        <(ReaderPageTheme, Color fill, Color ink, Color? borderColor, String)>[
          (
            ReaderPageTheme.night,
            NocheColors.lessonGround,
            NocheColors.nightText,
            NocheColors.bar,
            NocheA11y.label(NocheA11y.pageNight, courseWords: widget.a11yWords),
          ),
          (
            ReaderPageTheme.sepia,
            NocheColors.sepiaPage,
            NocheColors.sepiaText,
            null,
            NocheA11y.label(NocheA11y.pageSepia, courseWords: widget.a11yWords),
          ),
          (
            ReaderPageTheme.day,
            NocheColors.dayPage,
            NocheColors.dayText,
            null,
            NocheA11y.label(NocheA11y.pageDay, courseWords: widget.a11yWords),
          ),
        ];

    return Semantics(
      container: true,
      role: ui.SemanticsRole.radioGroup,
      label: _a11yGroup('pageColour', 'Page colour', widget.a11yWords),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = (constraints.maxWidth - 2 * NocheSize.grid) / 3;
          final stride = slotWidth + NocheSize.grid;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final activeMotion = NocheMotion.of(context);
                  final double pos;
                  final double opacity;
                  if (_reducedFade || activeMotion.reduced) {
                    pos = _toIndex;
                    opacity = _reducedFade
                        ? activeMotion.enter.transform(_controller.value)
                        : 1.0;
                  } else {
                    pos =
                        ui.lerpDouble(
                          _fromIndex,
                          _toIndex,
                          activeMotion.travel.transform(_controller.value),
                        ) ??
                        _toIndex;
                    opacity = 1.0;
                  }
                  return PositionedDirectional(
                    start: pos * stride,
                    top: 0,
                    width: slotWidth,
                    height: NocheSize.touch,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: opacity,
                        child: DecoratedBox(
                          key: const ValueKey('reader-page-color-ring'),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              NocheSize.pillRadius,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: NocheColors.text,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: NocheColors.panel,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Row(
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    if (i > 0) const SizedBox(width: NocheSize.grid),
                    Expanded(
                      child: Semantics(
                        button: true,
                        inMutuallyExclusiveGroup: true,
                        checked: options[i].$1 == widget.selected,
                        label: options[i].$5,
                        child: Pressable(
                          onPressed: () => widget.onChanged(options[i].$1),
                          semanticsButton: false,
                          builder: (context, _) => ExcludeSemantics(
                            child: Container(
                              height: NocheSize.touch,
                              alignment: AlignmentDirectional.center,
                              decoration: BoxDecoration(
                                color: options[i].$2,
                                borderRadius: BorderRadius.circular(
                                  NocheSize.pillRadius,
                                ),
                                border: options[i].$4 != null
                                    ? Border.all(
                                        color: options[i].$4!,
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Text(
                                'A',
                                style: NocheType.bookTitle.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  height: 1,
                                  color: options[i].$3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
