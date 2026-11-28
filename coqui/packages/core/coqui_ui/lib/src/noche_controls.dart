/// Noche shared controls: pills, chips, cards, buttons, play bar, play disc,
/// segmented control, switch row, and section labels.
///
/// Every size, gap, radius, colour, and text style matches the Noche boards
/// (`docs/proyecto/noche/Noche-*.dc.html`) and page 22, story N1.2.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coqui_ui/src/noche_icons.dart';
import 'package:coqui_ui/src/noche_motion.dart';
import 'package:coqui_ui/src/noche_tokens.dart';
import 'package:coqui_ui/src/pressable.dart';
import 'package:flutter/rendering.dart'
    show
        BoxHitTestResult,
        ContainerBoxParentData,
        ContainerRenderObjectMixin,
        RenderBoxContainerDefaultsMixin;
import 'package:material_ui/material_ui.dart';

/// Paints a rounded-rectangle dashed border (`1 px dashed`) inside the box.
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  static const double _strokeWidth = 1;
  static const double _dashLength = 4;
  static const double _gapLength = 3;

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = _strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      (size.width - _strokeWidth).clamp(0, double.infinity),
      (size.height - _strokeWidth).clamp(0, double.infinity),
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular((radius - inset).clamp(0, double.infinity)),
    );
    final source = Path()..addRRect(rrect);
    final dashed = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = (dist + _dashLength).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(dist, next), Offset.zero);
        dist += _dashLength + _gapLength;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

/// Visual kind of [NochePill].
enum NochePillKind {
  /// 48-high pill: panel fill, 1 px line border, `button` text.
  outline,

  /// 48-high pill: text fill, ground text, `buttonStrong`.
  selected,

  /// 48 by 48 circle-pill: transparent fill, 1 px dashed line border, lock icon 20.
  dashedLocked,

  /// 24-high radius-12 tag: transparent fill, 1 px next border, `labelStrong` in next. Never touchable.
  planTag,
}

/// Noche pill (boards: `Noche-Biblioteca`, `Noche-Hablar`, `Noche-Hablar-Plan`).
class NochePill extends StatelessWidget {
  const NochePill({
    super.key,
    required this.kind,
    this.label,
    this.onPressed,
    this.leading,
    this.trailing,
    this.foregroundColor,
    this.script = 'Latn',
    this.locale,
    this.semanticLabel,
    this.padding,
  }) : assert(
         kind != NochePillKind.planTag || onPressed == null,
         'NochePill.planTag is a tag and is never touchable.',
       );

  const NochePill.outline({
    super.key,
    required String this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.foregroundColor,
    this.script = 'Latn',
    this.locale,
    this.semanticLabel,
    this.padding,
  }) : kind = NochePillKind.outline;

  const NochePill.selected({
    super.key,
    required String this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.script = 'Latn',
    this.locale,
    this.semanticLabel,
    this.padding,
  }) : kind = NochePillKind.selected,
       foregroundColor = null;

  const NochePill.dashedLocked({super.key, this.semanticLabel, this.onPressed})
    : kind = NochePillKind.dashedLocked,
      label = null,
      leading = null,
      trailing = null,
      foregroundColor = null,
      script = 'Latn',
      locale = null,
      padding = null;

  const NochePill.planTag({
    super.key,
    required String this.label,
    this.semanticLabel,
  }) : kind = NochePillKind.planTag,
       onPressed = null,
       leading = null,
       trailing = null,
       foregroundColor = null,
       script = 'Latn',
       locale = null,
       padding = null;

  final NochePillKind kind;
  final String? label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final Color? foregroundColor;
  final String script;
  final Locale? locale;
  final String? semanticLabel;
  final EdgeInsetsDirectional? padding;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case NochePillKind.planTag:
        return Semantics(
          label: semanticLabel ?? label,
          readOnly: true,
          child: ExcludeSemantics(
            child: Container(
              height: 24,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: NocheColors.next, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label ?? '',
                    maxLines: 1,
                    softWrap: false,
                    style: NocheType.labelStrong.copyWith(
                      color: NocheColors.next,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case NochePillKind.dashedLocked:
        final pill = CustomPaint(
          painter: const _DashedRRectPainter(
            color: NocheColors.line,
            radius: NocheSize.pillRadius,
          ),
          child: SizedBox(
            width: NocheSize.touch,
            height: NocheSize.touch,
            child: Center(
              child: NocheIcon(
                NocheIcons.lock,
                size: 20,
                color: NocheColors.label,
              ),
            ),
          ),
        );
        if (onPressed != null) {
          return Pressable(
            onPressed: onPressed,
            semanticLabel: semanticLabel,
            builder: (context, _) => pill,
          );
        }
        return Semantics(
          button: true,
          enabled: false,
          label: semanticLabel,
          child: ExcludeSemantics(child: pill),
        );

      case NochePillKind.outline:
      case NochePillKind.selected:
        final isSelected = kind == NochePillKind.selected;
        final bg = isSelected ? NocheColors.text : NocheColors.panel;
        final borderColor = isSelected ? NocheColors.text : NocheColors.line;
        final fg = isSelected
            ? NocheColors.ground
            : (foregroundColor ?? NocheColors.text);
        final baseStyle = isSelected
            ? NocheType.buttonStrong
            : NocheType.button;
        final style = NocheType.forScript(
          baseStyle,
          script,
        ).copyWith(color: fg);
        final innerPadding =
            padding ?? const EdgeInsetsDirectional.symmetric(horizontal: 16);

        return Pressable(
          onPressed: onPressed,
          semanticLabel: semanticLabel ?? label,
          selected: isSelected ? true : null,
          builder: (context, _) => ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: NocheSize.touch,
              minHeight: NocheSize.touch,
            ),
            child: Container(
              height: NocheSize.touch,
              padding: innerPadding,
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: borderColor, width: 1),
                borderRadius: BorderRadius.circular(NocheSize.pillRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: NocheSize.grid),
                  ],
                  if (label != null)
                    Text(
                      label!,
                      maxLines: 1,
                      softWrap: false,
                      locale: locale,
                      style: style,
                    ),
                  if (trailing != null) ...[
                    const SizedBox(width: NocheSize.grid),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        );
    }
  }
}

/// Non-touchable word/topic chip (`Noche-Hablar.dc.html`): 32 high, radius 16,
/// `chip` fill, horizontal padding 12, `button` style.
class NocheChip extends StatelessWidget {
  const NocheChip({
    super.key,
    required this.label,
    this.script = 'Latn',
    this.locale,
  });

  final String label;
  final String script;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final style = NocheType.forScript(
      NocheType.button,
      script,
    ).copyWith(color: NocheColors.text);
    return Container(
      height: NocheSize.chipHeight,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: NocheColors.chip,
        borderRadius: BorderRadius.circular(NocheSize.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            locale: locale,
            style: style,
          ),
        ],
      ),
    );
  }
}

/// Visual variant of [NocheCard].
enum NocheCardVariant {
  /// Panel fill, 1 px line border, radius 24.
  standard,

  /// Panel fill, 2 px next border, radius 24.
  highlight,

  /// No fill, 1 px dashed line border, radius 24, label text colour.
  dashed,
}

/// Noche card container (`Noche-Mapa.dc.html`, `Noche-Hablar-Plan.dc.html`).
class NocheCard extends StatelessWidget {
  const NocheCard({
    super.key,
    required this.child,
    this.variant = NocheCardVariant.standard,
    this.padding = const EdgeInsetsDirectional.all(16),
    this.onPressed,
    this.semanticLabel,
  });

  final Widget child;
  final NocheCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final textColor = variant == NocheCardVariant.dashed
        ? NocheColors.label
        : NocheColors.text;
    final styledChild = DefaultTextStyle.merge(
      style: NocheType.body.copyWith(color: textColor),
      child: IconTheme.merge(
        data: IconThemeData(color: textColor),
        child: Padding(padding: padding, child: child),
      ),
    );

    Widget box;
    switch (variant) {
      case NocheCardVariant.standard:
        box = DecoratedBox(
          decoration: BoxDecoration(
            color: NocheColors.panel,
            border: Border.all(color: NocheColors.line, width: 1),
            borderRadius: BorderRadius.circular(NocheSize.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(1),
            child: styledChild,
          ),
        );
      case NocheCardVariant.highlight:
        box = DecoratedBox(
          decoration: BoxDecoration(
            color: NocheColors.panel,
            border: Border.all(color: NocheColors.next, width: 2),
            borderRadius: BorderRadius.circular(NocheSize.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(2),
            child: styledChild,
          ),
        );
      case NocheCardVariant.dashed:
        box = CustomPaint(
          painter: const _DashedRRectPainter(
            color: NocheColors.line,
            radius: NocheSize.cardRadius,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(1),
            child: styledChild,
          ),
        );
    }

    if (onPressed == null) return box;

    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: NocheSize.touch,
          minHeight: NocheSize.touch,
        ),
        child: box,
      ),
    );
  }
}

/// Primary action button (`Noche-Palabras.dc.html`): full width, 56 high,
/// radius 28, `next` fill, `onAccent` text (`primary`). The
/// [NochePrimaryButton.text] variant uses `text` fill and `ground` label
/// (`primarySmall` by default). Disabled: `line` fill, `label` text.
class NochePrimaryButton extends StatelessWidget {
  const NochePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.small = false,
    this.semanticLabel,
  }) : _textFilled = false;

  /// Text-filled primary action button (`Noche-Motion-Escribir.dc.html`):
  /// `text` fill with `ground` label when enabled, `line` fill with `label`
  /// text when disabled, 56 high, radius 28, `primarySmall` by default.
  const NochePrimaryButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.small = true,
    this.semanticLabel,
  }) : _textFilled = true;

  final String label;
  final VoidCallback? onPressed;

  /// Uses [NocheType.primarySmall] (17 px) instead of [NocheType.primary] (18 px).
  final bool small;
  final String? semanticLabel;
  final bool _textFilled;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bg = enabled
        ? (_textFilled ? NocheColors.text : NocheColors.next)
        : NocheColors.line;
    final fg = enabled
        ? (_textFilled ? NocheColors.ground : NocheColors.onAccent)
        : NocheColors.label;
    final style = (small ? NocheType.primarySmall : NocheType.primary).copyWith(
      color: fg,
    );
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? label,
      builder: (context, _) => Container(
        width: double.infinity,
        height: NocheSize.primaryHeight,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(NocheSize.primaryRadius),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}

/// Outline button (`Noche-Biblioteca.dc.html`, "Write my story"): transparent,
/// 1 px `text` border, `text` colour, 48 high, radius 24, `buttonStrong`.
class NocheOutlineButton extends StatelessWidget {
  const NocheOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = enabled ? NocheColors.text : NocheColors.label;
    final borderColor = enabled ? NocheColors.text : NocheColors.line;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? label,
      builder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: NocheSize.touch,
          minHeight: NocheSize.touch,
        ),
        child: Container(
          width: expand ? double.infinity : null,
          height: NocheSize.touch,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(NocheSize.pillRadius),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NocheType.buttonStrong.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

/// Full-width play bar (`Noche-Lugar.dc.html`): 72 high, radius 36, `next`
/// fill. Start: 56 disc in `onAccent` with a `next` play icon (24). Middle:
/// uppercase `labelStrong` line, gap 8, then `cardTitle`. End: `button` meta.
class NochePlayBar extends StatelessWidget {
  const NochePlayBar({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.onPressed,
    this.meta,
    this.icon = NocheIcons.play,
    this.script = 'Latn',
    this.locale,
    this.semanticLabel,
  });

  final String eyebrow;
  final String title;
  final String? meta;
  final VoidCallback? onPressed;
  final NocheIconData icon;
  final String script;
  final Locale? locale;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticLabel ?? [eyebrow, title, ?meta].join(', ');
    final titleStyle = NocheType.forScript(
      NocheType.cardTitle,
      script,
    ).copyWith(color: NocheColors.onAccent);

    return Pressable(
      onPressed: onPressed,
      semanticLabel: effectiveLabel,
      builder: (context, _) => Container(
        width: double.infinity,
        height: NocheSize.playBarHeight,
        padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 24, 0),
        decoration: BoxDecoration(
          color: NocheColors.next,
          borderRadius: BorderRadius.circular(NocheSize.playBarRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: AlignmentDirectional.center,
              decoration: const BoxDecoration(
                color: NocheColors.onAccent,
                shape: BoxShape.circle,
              ),
              child: NocheIcon(icon, size: 24, color: NocheColors.next),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NocheType.labelStrong.copyWith(
                      color: NocheColors.onAccent,
                    ),
                  ),
                  const SizedBox(height: NocheSize.grid),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    locale: locale,
                    style: titleStyle,
                  ),
                ],
              ),
            ),
            if (meta != null) ...[
              const SizedBox(width: 16),
              Text(
                meta!,
                maxLines: 1,
                softWrap: false,
                style: NocheType.button.copyWith(color: NocheColors.onAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Circular orange action disc (`Noche-Mapa.dc.html` 64, `Noche-Hablar.dc.html`
/// 96): `next` fill, `onAccent` icon, optional 8 px soft ring halo. Icon
/// changes cross-fade in `quick` on `enter`.
class NochePlayDisc extends StatelessWidget {
  const NochePlayDisc({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.size = NocheSize.disc,
    this.icon = NocheIcons.play,
    this.iconSize,
    this.halo = false,
  }) : assert(size >= NocheSize.touch, 'Touch target must be at least 48.');

  final VoidCallback? onPressed;
  final String semanticLabel;
  final double size;
  final NocheIconData icon;
  final double? iconSize;

  /// Adds an 8 px soft halo ring around the disc (as on `Noche-Hablar.dc.html`).
  final bool halo;

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    final resolvedIconSize = iconSize ?? (size >= NocheSize.mic ? 40 : 28);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      disc: true,
      builder: (context, _) => Container(
        width: size,
        height: size,
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
          color: NocheColors.next,
          shape: BoxShape.circle,
          boxShadow: halo
              ? [BoxShadow(color: NocheColors.callHalo, spreadRadius: 8)]
              : null,
        ),
        child: AnimatedSwitcher(
          duration: motion.quick,
          reverseDuration: motion.quick,
          switchInCurve: motion.enter,
          switchOutCurve: motion.enter,
          child: NocheIcon(
            icon,
            key: ValueKey<NocheIconData>(icon),
            size: resolvedIconSize,
            color: NocheColors.onAccent,
          ),
        ),
      ),
    );
  }
}

/// Semantic role for [NocheSegmented].
enum NocheSegmentedRole { radioGroup, tabList }

/// One option inside [NocheSegmented].
class NocheSegmentOption<T> {
  const NocheSegmentOption({
    required this.value,
    this.label = '',
    this.icon,
    this.iconSize = 22,
    this.builder,
    this.muted = false,
    this.semanticLabel,
  }) : assert(
         label != '' || icon != null || builder != null,
         'NocheSegmentOption requires a non-empty label, an icon, or a builder.',
       ),
       assert(
         label != '' || semanticLabel != null,
         'NocheSegmentOption requires semanticLabel when label is empty.',
       );

  final T value;
  final String label;
  final NocheIconData? icon;
  final double iconSize;
  final Widget Function(BuildContext context, Color color, bool selected)?
  builder;

  /// Draws an unselected option in `label` colour (e.g. "Reading · A2" on `Noche-Palabras`).
  final bool muted;
  final String? semanticLabel;
}

/// Segmented control (`Noche-Yo.dc.html` minutes, `Noche-Palabras.dc.html` skills,
/// `Noche-Lector-Aa.dc.html` line spacing): panel fill, 1 px line border,
/// radius 28 with padding 4 (or compact radius 25 when `padding` is zero);
/// options 48 high, radius 24; single `text`-filled thumb slides behind the
/// labels/icons in `move` on `travel`.
class NocheSegmented<T> extends StatefulWidget {
  const NocheSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.role = NocheSegmentedRole.radioGroup,
    this.semanticLabel,
    this.large = false,
    this.padding = const EdgeInsetsDirectional.all(4),
    this.backgroundColor = NocheColors.panel,
  });

  final List<NocheSegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final NocheSegmentedRole role;
  final String? semanticLabel;

  /// Uses 16 px label text (as on `Noche-Yo.dc.html` minutes) instead of 14 px.
  final bool large;
  final EdgeInsetsDirectional padding;
  final Color backgroundColor;

  @override
  State<NocheSegmented<T>> createState() => _NocheSegmentedState<T>();
}

class _NocheSegmentedState<T> extends State<NocheSegmented<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  );

  late double _fromIndex;
  late double _toIndex;
  bool _reducedFade = false;

  int _indexOfSelected(List<NocheSegmentOption<T>> options, T selected) {
    final idx = options.indexWhere((o) => o.value == selected);
    return idx < 0 ? 0 : idx;
  }

  @override
  void initState() {
    super.initState();
    final initial = _indexOfSelected(
      widget.options,
      widget.selected,
    ).toDouble();
    _fromIndex = initial;
    _toIndex = initial;
  }

  @override
  void didUpdateWidget(NocheSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIdx = _indexOfSelected(widget.options, widget.selected).toDouble();
    final oldIdx = _indexOfSelected(
      oldWidget.options,
      oldWidget.selected,
    ).toDouble();
    if (newIdx == oldIdx && widget.selected == oldWidget.selected) return;

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
    final count = widget.options.length;
    final compact = widget.padding == EdgeInsetsDirectional.zero;
    final layout = LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = count == 0 ? 0.0 : constraints.maxWidth / count;
        return Stack(
          children: [
            if (count > 0)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final motion = NocheMotion.of(context);
                  final double pos;
                  final double opacity;
                  if (_reducedFade || motion.reduced) {
                    pos = _toIndex;
                    opacity = _reducedFade
                        ? motion.enter.transform(_controller.value)
                        : 1.0;
                  } else {
                    pos =
                        ui.lerpDouble(
                          _fromIndex,
                          _toIndex,
                          motion.travel.transform(_controller.value),
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
                          key: const ValueKey('noche_segmented_thumb'),
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
              children: [
                for (final option in widget.options)
                  Expanded(
                    child: _SegmentButton<T>(
                      option: option,
                      isSelected: option.value == widget.selected,
                      role: widget.role,
                      large: widget.large,
                      onTap: () => widget.onChanged(option.value),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );

    return Semantics(
      container: true,
      role: widget.role == NocheSegmentedRole.tabList
          ? ui.SemanticsRole.tabBar
          : ui.SemanticsRole.radioGroup,
      label: widget.semanticLabel,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: Border.all(color: NocheColors.line, width: 1),
          borderRadius: BorderRadius.circular(
            compact
                ? NocheSize.pillRadius + 1
                : NocheSize.pillRadius + widget.padding.top,
          ),
        ),
        child: compact
            ? ClipRRect(
                borderRadius: BorderRadius.circular(NocheSize.pillRadius),
                child: layout,
              )
            : layout,
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.option,
    required this.isSelected,
    required this.role,
    required this.large,
    required this.onTap,
  });

  final NocheSegmentOption<T> option;
  final bool isSelected;
  final NocheSegmentedRole role;
  final bool large;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    final hasLabel = option.label.isNotEmpty;
    final fg = isSelected
        ? NocheColors.ground
        : (option.muted ? NocheColors.label : NocheColors.text);
    final base = isSelected ? NocheType.buttonStrong : NocheType.button;
    final sizedBase = large ? base.copyWith(fontSize: 16) : base;

    return Semantics(
      role: role == NocheSegmentedRole.tabList
          ? ui.SemanticsRole.tab
          : ui.SemanticsRole.none,
      button: role == NocheSegmentedRole.radioGroup,
      inMutuallyExclusiveGroup: role == NocheSegmentedRole.radioGroup,
      checked: role == NocheSegmentedRole.radioGroup ? isSelected : null,
      selected: role == NocheSegmentedRole.tabList ? isSelected : null,
      label: option.semanticLabel ?? option.label,
      child: Pressable(
        onPressed: onTap,
        semanticsButton: false,
        builder: (context, _) => ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: NocheSize.touch,
              minHeight: NocheSize.touch,
            ),
            child: Container(
              height: NocheSize.touch,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: hasLabel ? 8 : 0,
              ),
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(NocheSize.pillRadius),
              ),
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: fg),
                duration: motion.quick,
                curve: motion.enter,
                builder: (context, color, _) {
                  final resolvedColor = color ?? fg;
                  if (option.builder != null) {
                    return option.builder!(context, resolvedColor, isSelected);
                  }
                  if (option.icon != null && !hasLabel) {
                    return NocheIcon(
                      option.icon!,
                      size: option.iconSize,
                      color: resolvedColor,
                    );
                  }
                  if (option.icon != null && hasLabel) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NocheIcon(
                          option.icon!,
                          size: option.iconSize,
                          color: resolvedColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sizedBase.copyWith(color: resolvedColor),
                          ),
                        ),
                      ],
                    );
                  }
                  return Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sizedBase.copyWith(color: resolvedColor),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoxSlot {
  const _BoxSlot(this.dx, this.dy, this.width, this.height);

  final double dx;
  final double dy;
  final double width;
  final double height;

  static _BoxSlot lerp(_BoxSlot a, _BoxSlot b, double t) => _BoxSlot(
    ui.lerpDouble(a.dx, b.dx, t) ?? b.dx,
    ui.lerpDouble(a.dy, b.dy, t) ?? b.dy,
    ui.lerpDouble(a.width, b.width, t) ?? b.width,
    ui.lerpDouble(a.height, b.height, t) ?? b.height,
  );
}

enum _SlidingMarkMode { wrap, verticalEqual, horizontalEqual }

class _SlidingMarkParentData extends ContainerBoxParentData<RenderBox> {}

class _SlidingMarkLayout extends MultiChildRenderObjectWidget {
  const _SlidingMarkLayout({
    required this.mode,
    required this.optionCount,
    required this.fromIndex,
    required this.toIndex,
    required this.progress,
    required this.transitionId,
    required this.gap,
    required this.runGap,
    required this.textDirection,
    required this.markBehindChildren,
    this.unselectedPillFill,
    required super.children,
  });

  final _SlidingMarkMode mode;
  final int optionCount;
  final int fromIndex;
  final int toIndex;
  final double progress;
  final int transitionId;
  final double gap;
  final double runGap;
  final TextDirection textDirection;
  final bool markBehindChildren;
  final Color? unselectedPillFill;

  @override
  _RenderSlidingMarkLayout createRenderObject(BuildContext context) =>
      _RenderSlidingMarkLayout(
        mode: mode,
        optionCount: optionCount,
        fromIndex: fromIndex,
        toIndex: toIndex,
        progress: progress,
        transitionId: transitionId,
        gap: gap,
        runGap: runGap,
        textDirection: textDirection,
        markBehindChildren: markBehindChildren,
        unselectedPillFill: unselectedPillFill,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSlidingMarkLayout renderObject,
  ) {
    renderObject
      ..mode = mode
      ..optionCount = optionCount
      ..fromIndex = fromIndex
      ..toIndex = toIndex
      ..progress = progress
      ..transitionId = transitionId
      ..gap = gap
      ..runGap = runGap
      ..textDirection = textDirection
      ..markBehindChildren = markBehindChildren
      ..unselectedPillFill = unselectedPillFill;
  }
}

class _RenderSlidingMarkLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SlidingMarkParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SlidingMarkParentData> {
  _RenderSlidingMarkLayout({
    required this._mode,
    required this._optionCount,
    required this._fromIndex,
    required this._toIndex,
    required this._progress,
    required this._transitionId,
    required this._gap,
    required this._runGap,
    required this._textDirection,
    required this._markBehindChildren,
    required this._unselectedPillFill,
  });

  _SlidingMarkMode _mode;
  set mode(_SlidingMarkMode v) {
    if (_mode == v) return;
    _mode = v;
    markNeedsLayout();
  }

  int _optionCount;
  set optionCount(int v) {
    if (_optionCount == v) return;
    _optionCount = v;
    markNeedsLayout();
  }

  int _fromIndex;
  set fromIndex(int v) {
    if (_fromIndex == v) return;
    _fromIndex = v;
    markNeedsLayout();
  }

  int _toIndex;
  set toIndex(int v) {
    if (_toIndex == v) return;
    _toIndex = v;
    markNeedsLayout();
  }

  double _progress;
  set progress(double v) {
    if (_progress == v) return;
    _progress = v;
    markNeedsLayout();
  }

  int _transitionId;
  set transitionId(int v) {
    if (_transitionId == v) return;
    _transitionId = v;
    if (_currentMarkSlot != null && _fromIndex != _toIndex) {
      _retargetStartSlot = _currentMarkSlot;
    } else {
      _retargetStartSlot = null;
    }
    markNeedsLayout();
  }

  double _gap;
  set gap(double v) {
    if (_gap == v) return;
    _gap = v;
    markNeedsLayout();
  }

  double _runGap;
  set runGap(double v) {
    if (_runGap == v) return;
    _runGap = v;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (_textDirection == v) return;
    _textDirection = v;
    markNeedsLayout();
  }

  bool _markBehindChildren;
  set markBehindChildren(bool v) {
    if (_markBehindChildren == v) return;
    _markBehindChildren = v;
    markNeedsPaint();
  }

  Color? _unselectedPillFill;
  set unselectedPillFill(Color? v) {
    if (_unselectedPillFill == v) return;
    _unselectedPillFill = v;
    markNeedsPaint();
  }

  List<_BoxSlot> _optionSlots = const [];
  _BoxSlot? _currentMarkSlot;
  _BoxSlot? _retargetStartSlot;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SlidingMarkParentData) {
      child.parentData = _SlidingMarkParentData();
    }
  }

  @override
  void performLayout() {
    final mark = firstChild;
    if (mark == null) {
      size = constraints.smallest;
      _optionSlots = const [];
      return;
    }

    final items = <RenderBox>[];
    var child = childAfter(mark);
    while (child != null) {
      items.add(child);
      child = childAfter(child);
    }

    final slots = List<_BoxSlot>.filled(
      _optionCount,
      const _BoxSlot(0, 0, 0, 0),
    );
    final isRtl = _textDirection == TextDirection.rtl;

    switch (_mode) {
      case _SlidingMarkMode.wrap:
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final childConstraints = BoxConstraints(maxWidth: maxW);
        final runs = <List<(RenderBox, int)>>[];
        final runWidths = <double>[];
        final runHeights = <double>[];

        var currentRun = <(RenderBox, int)>[];
        var currentW = 0.0;
        var currentH = 0.0;

        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          item.layout(childConstraints, parentUsesSize: true);
          final w = item.size.width;
          final h = item.size.height;
          if (currentRun.isNotEmpty && currentW + _gap + w > maxW) {
            runs.add(currentRun);
            runWidths.add(currentW);
            runHeights.add(currentH);
            currentRun = <(RenderBox, int)>[];
            currentW = 0.0;
            currentH = 0.0;
          }
          if (currentRun.isNotEmpty) currentW += _gap;
          currentRun.add((item, i));
          currentW += w;
          if (h > currentH) currentH = h;
        }
        if (currentRun.isNotEmpty) {
          runs.add(currentRun);
          runWidths.add(currentW);
          runHeights.add(currentH);
        }

        final widestRun = runWidths.fold<double>(0.0, math.max);
        final totalH =
            runHeights.fold<double>(0.0, (a, b) => a + b) +
            (runs.length > 1 ? _runGap * (runs.length - 1) : 0.0);
        final layoutW = constraints.constrainWidth(widestRun);
        final layoutH = constraints.constrainHeight(totalH);

        var y = 0.0;
        for (var r = 0; r < runs.length; r++) {
          final run = runs[r];
          final rh = runHeights[r];
          var cursor = isRtl ? layoutW : 0.0;
          for (final entry in run) {
            final item = entry.$1;
            final idx = entry.$2;
            final w = item.size.width;
            final h = item.size.height;
            final dy = y + (rh - h) / 2;
            final double dx;
            if (isRtl) {
              cursor -= w;
              dx = cursor;
              cursor -= _gap;
            } else {
              dx = cursor;
              cursor += w + _gap;
            }
            (item.parentData! as _SlidingMarkParentData).offset = Offset(
              dx,
              dy,
            );
            if (idx < _optionCount) {
              slots[idx] = _BoxSlot(dx, dy, w, h);
            }
          }
          y += rh + _runGap;
        }
        size = Size(layoutW, layoutH);

      case _SlidingMarkMode.verticalEqual:
        final childConstraints = BoxConstraints(
          minWidth: constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0,
          maxWidth: constraints.maxWidth,
        );
        var maxW = 0.0;
        var y = 0.0;
        for (var i = 0; i < items.length; i++) {
          if (i > 0) y += _gap;
          final item = items[i];
          item.layout(childConstraints, parentUsesSize: true);
          final w = item.size.width;
          final h = item.size.height;
          if (w > maxW) maxW = w;
          (item.parentData! as _SlidingMarkParentData).offset = Offset(0, y);
          if (i < _optionCount) {
            slots[i] = _BoxSlot(0, y, w, h);
          }
          y += h;
        }
        size = constraints.constrain(Size(maxW, y));

      case _SlidingMarkMode.horizontalEqual:
        final n = items.length;
        if (n == 0) {
          size = constraints.smallest;
        } else if (constraints.maxWidth.isFinite) {
          final slotW = math.max(
            0.0,
            (constraints.maxWidth - _gap * (n - 1)) / n,
          );
          var maxH = 0.0;
          for (final item in items) {
            item.layout(
              BoxConstraints(minWidth: slotW, maxWidth: slotW),
              parentUsesSize: true,
            );
            if (item.size.height > maxH) maxH = item.size.height;
          }
          for (var i = 0; i < n; i++) {
            final item = items[i];
            if (item.size.height != maxH) {
              item.layout(
                BoxConstraints.tightFor(width: slotW, height: maxH),
                parentUsesSize: true,
              );
            }
            final visualIndex = isRtl ? (n - 1 - i) : i;
            final dx = visualIndex * (slotW + _gap);
            (item.parentData! as _SlidingMarkParentData).offset = Offset(dx, 0);
            if (i < _optionCount) {
              slots[i] = _BoxSlot(dx, 0, slotW, maxH);
            }
          }
          size = constraints.constrain(Size(constraints.maxWidth, maxH));
        } else {
          var maxH = 0.0;
          var totalW = 0.0;
          for (var i = 0; i < n; i++) {
            items[i].layout(const BoxConstraints(), parentUsesSize: true);
            if (items[i].size.height > maxH) maxH = items[i].size.height;
            totalW += items[i].size.width + (i > 0 ? _gap : 0.0);
          }
          var cursor = isRtl ? totalW : 0.0;
          for (var i = 0; i < n; i++) {
            final item = items[i];
            final w = item.size.width;
            final double dx;
            if (isRtl) {
              cursor -= w;
              dx = cursor;
              cursor -= _gap;
            } else {
              dx = cursor;
              cursor += w + _gap;
            }
            (item.parentData! as _SlidingMarkParentData).offset = Offset(dx, 0);
            if (i < _optionCount) {
              slots[i] = _BoxSlot(dx, 0, w, item.size.height);
            }
          }
          size = constraints.constrain(Size(totalW, maxH));
        }
    }

    _optionSlots = slots;
    if (_optionCount == 0) {
      mark.layout(BoxConstraints.tight(Size.zero), parentUsesSize: true);
      (mark.parentData! as _SlidingMarkParentData).offset = Offset.zero;
      _currentMarkSlot = null;
      _retargetStartSlot = null;
      return;
    }

    final safeFrom = _fromIndex.clamp(0, _optionCount - 1);
    final safeTo = _toIndex.clamp(0, _optionCount - 1);
    final fromSlot = (_fromIndex != _toIndex && _retargetStartSlot != null)
        ? _retargetStartSlot!
        : slots[safeFrom];
    final toSlot = slots[safeTo];
    final curSlot = _BoxSlot.lerp(fromSlot, toSlot, _progress.clamp(0.0, 1.0));
    _currentMarkSlot = curSlot;
    if (_progress >= 1.0) {
      _retargetStartSlot = null;
    }

    mark.layout(
      BoxConstraints.tight(Size(curSlot.width, curSlot.height)),
      parentUsesSize: true,
    );
    (mark.parentData! as _SlidingMarkParentData).offset = Offset(
      curSlot.dx,
      curSlot.dy,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final mark = firstChild;
    if (mark == null) return;

    if (_unselectedPillFill != null) {
      final fillPaint = Paint()
        ..color = _unselectedPillFill!
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = NocheColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (final slot in _optionSlots) {
        final fillRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            offset.dx + slot.dx,
            offset.dy + slot.dy,
            slot.width,
            slot.height,
          ),
          const Radius.circular(NocheSize.pillRadius),
        );
        context.canvas.drawRRect(fillRRect, fillPaint);
        final borderRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            offset.dx + slot.dx + 0.5,
            offset.dy + slot.dy + 0.5,
            math.max(0.0, slot.width - 1),
            math.max(0.0, slot.height - 1),
          ),
          const Radius.circular(NocheSize.pillRadius - 0.5),
        );
        context.canvas.drawRRect(borderRRect, borderPaint);
      }
    }

    final markOffset = (mark.parentData! as _SlidingMarkParentData).offset;
    if (_markBehindChildren) {
      context.paintChild(mark, offset + markOffset);
    }

    var child = childAfter(mark);
    while (child != null) {
      final pd = child.parentData! as _SlidingMarkParentData;
      context.paintChild(child, offset + pd.offset);
      child = childAfter(child);
    }

    if (!_markBehindChildren) {
      context.paintChild(mark, offset + markOffset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final mark = firstChild;
    var child = lastChild;
    while (child != null && !identical(child, mark)) {
      final pd = child.parentData! as _SlidingMarkParentData;
      final isHit = result.addWithPaintOffset(
        offset: pd.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) =>
            child!.hitTest(result, position: transformed),
      );
      if (isHit) return true;
      child = childBefore(child);
    }
    return false;
  }
}

/// One option inside [NochePillGroup].
class NochePillOption<T> {
  const NochePillOption({
    this.key,
    required this.value,
    required this.label,
    this.leading,
    this.trailing,
    this.foregroundColor,
    this.script = 'Latn',
    this.locale,
    this.semanticLabel,
    this.padding,
  });

  final Key? key;
  final T value;
  final String label;
  final Widget? leading;
  final Widget? trailing;
  final Color? foregroundColor;
  final String script;
  final Locale? locale;
  final String? semanticLabel;
  final EdgeInsetsDirectional? padding;
}

/// Group of selectable 48-high pills where a single `text`-filled mark slides
/// behind the pill text from old pill to new pill, smoothly animating both
/// start edge and width in `move` on `travel` (in LTR and RTL).
class NochePillGroup<T> extends StatefulWidget {
  const NochePillGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.gap = NocheSize.grid,
    this.runGap = NocheSize.grid,
    this.unselectedFill = NocheColors.panel,
    this.trailing,
    this.role = NocheSegmentedRole.radioGroup,
    this.semanticLabel,
  });

  final List<NochePillOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final double gap;
  final double runGap;
  final Color unselectedFill;
  final Widget? trailing;
  final NocheSegmentedRole role;
  final String? semanticLabel;

  @override
  State<NochePillGroup<T>> createState() => _NochePillGroupState<T>();
}

class _NochePillGroupState<T> extends State<NochePillGroup<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  );

  late int _fromIndex;
  late int _toIndex;
  int _transitionId = 0;
  bool _reducedFade = false;

  int _indexOf(List<NochePillOption<T>> options, T selected) {
    final idx = options.indexWhere((o) => o.value == selected);
    return idx < 0 ? 0 : idx;
  }

  @override
  void initState() {
    super.initState();
    final initial = _indexOf(widget.options, widget.selected);
    _fromIndex = initial;
    _toIndex = initial;
  }

  @override
  void didUpdateWidget(NochePillGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIdx = _indexOf(widget.options, widget.selected);
    final oldIdx = _indexOf(oldWidget.options, oldWidget.selected);
    if (newIdx == oldIdx && widget.selected == oldWidget.selected) return;

    final motion = NocheMotion.of(context);
    _transitionId++;
    if (motion.reduced) {
      _fromIndex = newIdx;
      _toIndex = newIdx;
      _reducedFade = true;
      _controller.duration = motion.quick;
      _controller.forward(from: 0.0);
    } else {
      _fromIndex = oldIdx;
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
    final textDirection = Directionality.of(context);
    return Semantics(
      container: true,
      role: widget.role == NocheSegmentedRole.tabList
          ? ui.SemanticsRole.tabBar
          : ui.SemanticsRole.radioGroup,
      label: widget.semanticLabel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final motion = NocheMotion.of(context);
          final isReduced = _reducedFade || motion.reduced;
          final progress = isReduced
              ? 1.0
              : motion.travel.transform(_controller.value);
          final markOpacity = _reducedFade
              ? motion.enter.transform(_controller.value)
              : 1.0;

          return _SlidingMarkLayout(
            mode: _SlidingMarkMode.wrap,
            optionCount: widget.options.length,
            fromIndex: isReduced ? _toIndex : _fromIndex,
            toIndex: _toIndex,
            progress: progress,
            transitionId: _transitionId,
            gap: widget.gap,
            runGap: widget.runGap,
            textDirection: textDirection,
            markBehindChildren: true,
            unselectedPillFill: widget.unselectedFill,
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: markOpacity,
                  child: DecoratedBox(
                    key: const ValueKey('noche_pill_group_mark'),
                    decoration: BoxDecoration(
                      color: NocheColors.text,
                      borderRadius: BorderRadius.circular(NocheSize.pillRadius),
                    ),
                  ),
                ),
              ),
              for (final option in widget.options)
                _PillGroupItem<T>(
                  key: option.key,
                  option: option,
                  isSelected: option.value == widget.selected,
                  role: widget.role,
                  onTap: () => widget.onChanged(option.value),
                ),
              if (widget.trailing != null) widget.trailing!,
            ],
          );
        },
      ),
    );
  }
}

class _PillGroupItem<T> extends StatelessWidget {
  const _PillGroupItem({
    super.key,
    required this.option,
    required this.isSelected,
    required this.role,
    required this.onTap,
  });

  final NochePillOption<T> option;
  final bool isSelected;
  final NocheSegmentedRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    final fg = isSelected
        ? NocheColors.ground
        : (option.foregroundColor ?? NocheColors.text);
    final baseStyle = NocheType.forScript(
      isSelected ? NocheType.buttonStrong : NocheType.button,
      option.script,
    );
    final innerPadding =
        option.padding ?? const EdgeInsetsDirectional.symmetric(horizontal: 16);

    return Semantics(
      role: role == NocheSegmentedRole.tabList
          ? ui.SemanticsRole.tab
          : ui.SemanticsRole.none,
      button: role == NocheSegmentedRole.radioGroup,
      inMutuallyExclusiveGroup: role == NocheSegmentedRole.radioGroup,
      checked: role == NocheSegmentedRole.radioGroup ? isSelected : null,
      selected: role == NocheSegmentedRole.tabList ? isSelected : null,
      label: option.semanticLabel ?? option.label,
      child: Pressable(
        onPressed: onTap,
        semanticsButton: false,
        builder: (context, _) => ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: NocheSize.touch,
              minHeight: NocheSize.touch,
            ),
            child: Container(
              height: NocheSize.touch,
              padding: innerPadding,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: fg),
                duration: motion.quick,
                curve: motion.enter,
                builder: (context, animatedColor, _) {
                  final color = animatedColor ?? fg;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (option.leading != null) ...[
                        IconTheme.merge(
                          data: IconThemeData(color: color),
                          child: option.leading!,
                        ),
                        const SizedBox(width: NocheSize.grid),
                      ],
                      Text(
                        option.label,
                        maxLines: 1,
                        softWrap: false,
                        locale: option.locale,
                        style: baseStyle.copyWith(color: color),
                      ),
                      if (option.trailing != null) ...[
                        const SizedBox(width: NocheSize.grid),
                        IconTheme.merge(
                          data: IconThemeData(color: color),
                          child: option.trailing!,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One option inside [NocheOutlineGroup].
class NocheOutlineOption<T> {
  const NocheOutlineOption({
    required this.value,
    required this.child,
    this.semanticLabel,
  });

  final T value;
  final Widget child;
  final String? semanticLabel;
}

/// Group of selectable cards or rows where a single outline mark slides
/// between option rects in `move` on `travel`.
///
/// Use [Axis.vertical] for stacked language rows and [Axis.horizontal] for
/// equal-width font cards (automatically mirroring in RTL). Under reduced
/// motion, the mark snaps to the chosen option and fades in `quick`.
class NocheOutlineGroup<T> extends StatefulWidget {
  const NocheOutlineGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.axis = Axis.vertical,
    this.gap = NocheSize.grid,
    this.borderRadius = NocheSize.cardRadius,
    this.outlineColor = NocheColors.text,
    this.outlineWidth = 2,
    this.markFill,
    this.role = NocheSegmentedRole.radioGroup,
    this.semanticLabel,
  });

  final List<NocheOutlineOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final Axis axis;
  final double gap;
  final double borderRadius;
  final Color outlineColor;
  final double outlineWidth;
  final Color? markFill;
  final NocheSegmentedRole role;
  final String? semanticLabel;

  @override
  State<NocheOutlineGroup<T>> createState() => _NocheOutlineGroupState<T>();
}

class _NocheOutlineGroupState<T> extends State<NocheOutlineGroup<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  );

  late int _fromIndex;
  late int _toIndex;
  int _transitionId = 0;
  bool _reducedFade = false;

  int _indexOf(List<NocheOutlineOption<T>> options, T selected) {
    final idx = options.indexWhere((o) => o.value == selected);
    return idx < 0 ? 0 : idx;
  }

  @override
  void initState() {
    super.initState();
    final initial = _indexOf(widget.options, widget.selected);
    _fromIndex = initial;
    _toIndex = initial;
  }

  @override
  void didUpdateWidget(NocheOutlineGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIdx = _indexOf(widget.options, widget.selected);
    final oldIdx = _indexOf(oldWidget.options, oldWidget.selected);
    if (newIdx == oldIdx && widget.selected == oldWidget.selected) return;

    final motion = NocheMotion.of(context);
    _transitionId++;
    if (motion.reduced) {
      _fromIndex = newIdx;
      _toIndex = newIdx;
      _reducedFade = true;
      _controller.duration = motion.quick;
      _controller.forward(from: 0.0);
    } else {
      _fromIndex = oldIdx;
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
    final textDirection = Directionality.of(context);
    final mode = widget.axis == Axis.vertical
        ? _SlidingMarkMode.verticalEqual
        : _SlidingMarkMode.horizontalEqual;

    return Semantics(
      container: true,
      role: widget.role == NocheSegmentedRole.tabList
          ? ui.SemanticsRole.tabBar
          : ui.SemanticsRole.radioGroup,
      label: widget.semanticLabel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final motion = NocheMotion.of(context);
          final isReduced = _reducedFade || motion.reduced;
          final progress = isReduced
              ? 1.0
              : motion.travel.transform(_controller.value);
          final markOpacity = _reducedFade
              ? motion.enter.transform(_controller.value)
              : 1.0;

          return _SlidingMarkLayout(
            mode: mode,
            optionCount: widget.options.length,
            fromIndex: isReduced ? _toIndex : _fromIndex,
            toIndex: _toIndex,
            progress: progress,
            transitionId: _transitionId,
            gap: widget.gap,
            runGap: widget.gap,
            textDirection: textDirection,
            markBehindChildren: widget.markFill != null,
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: markOpacity,
                  child: DecoratedBox(
                    key: const ValueKey('noche_outline_group_mark'),
                    decoration: BoxDecoration(
                      color: widget.markFill,
                      border: Border.all(
                        color: widget.outlineColor,
                        width: widget.outlineWidth,
                      ),
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                  ),
                ),
              ),
              for (final option in widget.options)
                Semantics(
                  role: widget.role == NocheSegmentedRole.tabList
                      ? ui.SemanticsRole.tab
                      : ui.SemanticsRole.none,
                  button: widget.role == NocheSegmentedRole.radioGroup,
                  inMutuallyExclusiveGroup:
                      widget.role == NocheSegmentedRole.radioGroup,
                  checked: widget.role == NocheSegmentedRole.radioGroup
                      ? option.value == widget.selected
                      : null,
                  selected: widget.role == NocheSegmentedRole.tabList
                      ? option.value == widget.selected
                      : null,
                  label: option.semanticLabel,
                  child: Pressable(
                    onPressed: () => widget.onChanged(option.value),
                    semanticsButton: false,
                    builder: (context, _) => ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: NocheSize.touch,
                        minHeight: NocheSize.touch,
                      ),
                      child: option.child,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Full-width toggle row (`Noche-Lector-Aa.dc.html`): 52 high, label `rowTitle`
/// weight 600 size 15 at start, 52 by 32 switch at end (on: `text` track,
/// `ground` 24 knob; off: `line` track, `label` 24 knob).
class NocheSwitchRow extends StatelessWidget {
  const NocheSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.showTopBorder = true,
    this.borderColor = NocheColors.line,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showTopBorder;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final titleStyle = NocheType.rowTitle.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 15,
      height: 20 / 15,
      color: enabled ? NocheColors.text : NocheColors.label,
    );
    final subtitleStyle = NocheType.bodySmall.copyWith(
      fontSize: 12,
      height: 16 / 12,
      color: NocheColors.label,
    );

    return Pressable(
      onPressed: enabled ? () => onChanged!(!value) : null,
      semanticLabel: subtitle == null ? label : '$label. $subtitle',
      selected: value,
      builder: (context, _) {
        final motion = NocheMotion.of(context);
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: subtitle == null
              ? EdgeInsetsDirectional.zero
              : const EdgeInsetsDirectional.symmetric(vertical: 8),
          decoration: showTopBorder
              ? BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                )
              : null,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: titleStyle),
                    if (subtitle != null) Text(subtitle!, style: subtitleStyle),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                key: const ValueKey('noche_switch_track'),
                duration: motion.quick,
                curve: motion.enter,
                width: 52,
                height: 32,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: value ? NocheColors.text : NocheColors.line,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedAlign(
                  duration: motion.reduced ? Duration.zero : motion.move,
                  curve: motion.travel,
                  alignment: value
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: AnimatedContainer(
                    key: const ValueKey('noche_switch_knob'),
                    duration: motion.quick,
                    curve: motion.enter,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: value ? NocheColors.ground : NocheColors.label,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Uppercase section label (`NocheType.label` in `NocheColors.label`), 16 px
/// above the content it names by default.
class NocheSectionLabel extends StatelessWidget {
  const NocheSectionLabel(
    this.text, {
    super.key,
    this.color = NocheColors.label,
    this.bottomGap = 16,
    this.trailing,
    this.script = 'Latn',
    this.locale,
  });

  final String text;
  final Color color;
  final double bottomGap;
  final Widget? trailing;
  final String script;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final style = NocheType.forScript(
      NocheType.label,
      script,
    ).copyWith(color: color);
    final labelWidget = Text(text.toUpperCase(), locale: locale, style: style);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bottomGap),
      child: trailing == null
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: labelWidget,
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: labelWidget),
                const SizedBox(width: NocheSize.grid),
                trailing!,
              ],
            ),
    );
  }
}
