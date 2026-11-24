/// Noche shared controls: pills, chips, cards, buttons, play bar, play disc,
/// segmented control, switch row, and section labels.
///
/// Every size, gap, radius, colour, and text style matches the Noche boards
/// (`docs/proyecto/noche/Noche-*.dc.html`) and page 22, story N1.2.
library;

import 'dart:ui' as ui;

import 'package:coqui_ui/src/noche_icons.dart';
import 'package:coqui_ui/src/noche_tokens.dart';
import 'package:coqui_ui/src/pressable.dart';
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
            builder: (context, pressed) =>
                Transform.scale(scale: pressed ? 0.98 : 1, child: pill),
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
          builder: (context, pressed) => Transform.scale(
            scale: pressed ? 0.98 : 1,
            child: ConstrainedBox(
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
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.99 : 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: NocheSize.touch,
            minHeight: NocheSize.touch,
          ),
          child: box,
        ),
      ),
    );
  }
}

/// Primary action button (`Noche-Palabras.dc.html`): full width, 56 high,
/// radius 28, `next` fill, `onAccent` text (`primary`). Disabled: `line` fill,
/// `label` text.
class NochePrimaryButton extends StatelessWidget {
  const NochePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.small = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Uses [NocheType.primarySmall] (17 px) instead of [NocheType.primary] (18 px).
  final bool small;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bg = enabled ? NocheColors.next : NocheColors.line;
    final fg = enabled ? NocheColors.onAccent : NocheColors.label;
    final style = (small ? NocheType.primarySmall : NocheType.primary).copyWith(
      color: fg,
    );
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? label,
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.98 : 1,
        child: Container(
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
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.98 : 1,
        child: ConstrainedBox(
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
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.98 : 1,
        child: Container(
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
      ),
    );
  }
}

/// Circular orange action disc (`Noche-Mapa.dc.html` 64, `Noche-Hablar.dc.html`
/// 96): `next` fill, `onAccent` icon, optional 8 px soft ring halo.
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
    final resolvedIconSize = iconSize ?? (size >= NocheSize.mic ? 40 : 28);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.96 : 1,
        child: Container(
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
          child: NocheIcon(
            icon,
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
    required this.label,
    this.muted = false,
    this.semanticLabel,
  });

  final T value;
  final String label;

  /// Draws an unselected option in `label` colour (e.g. "Reading · A2" on `Noche-Palabras`).
  final bool muted;
  final String? semanticLabel;
}

/// Segmented control (`Noche-Yo.dc.html` minutes, `Noche-Palabras.dc.html` skills):
/// panel fill, 1 px line border, radius 28, padding 4; options 48 high, radius 24;
/// selected = text fill and ground text.
class NocheSegmented<T> extends StatelessWidget {
  const NocheSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.role = NocheSegmentedRole.radioGroup,
    this.semanticLabel,
    this.large = false,
  });

  final List<NocheSegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final NocheSegmentedRole role;
  final String? semanticLabel;

  /// Uses 16 px label text (as on `Noche-Yo.dc.html` minutes) instead of 14 px.
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      role: role == NocheSegmentedRole.tabList
          ? ui.SemanticsRole.tabBar
          : ui.SemanticsRole.radioGroup,
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsetsDirectional.all(4),
        decoration: BoxDecoration(
          color: NocheColors.panel,
          border: Border.all(color: NocheColors.line, width: 1),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            for (final option in options)
              Expanded(
                child: _SegmentButton(
                  label: option.label,
                  semanticLabel: option.semanticLabel ?? option.label,
                  isSelected: option.value == selected,
                  muted: option.muted,
                  role: role,
                  large: large,
                  onTap: () => onChanged(option.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatefulWidget {
  const _SegmentButton({
    required this.label,
    required this.semanticLabel,
    required this.isSelected,
    required this.muted,
    required this.role,
    required this.large,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool isSelected;
  final bool muted;
  final NocheSegmentedRole role;
  final bool large;
  final VoidCallback onTap;

  @override
  State<_SegmentButton> createState() => _SegmentButtonState();
}

class _SegmentButtonState extends State<_SegmentButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected ? NocheColors.text : Colors.transparent;
    final fg = widget.isSelected
        ? NocheColors.ground
        : (widget.muted ? NocheColors.label : NocheColors.text);
    final base = widget.isSelected ? NocheType.buttonStrong : NocheType.button;
    final style = (widget.large ? base.copyWith(fontSize: 16) : base).copyWith(
      color: fg,
    );

    return Semantics(
      role: widget.role == NocheSegmentedRole.tabList
          ? ui.SemanticsRole.tab
          : ui.SemanticsRole.none,
      button: widget.role == NocheSegmentedRole.radioGroup,
      inMutuallyExclusiveGroup: widget.role == NocheSegmentedRole.radioGroup,
      checked: widget.role == NocheSegmentedRole.radioGroup
          ? widget.isSelected
          : null,
      selected: widget.role == NocheSegmentedRole.tabList
          ? widget.isSelected
          : null,
      label: widget.semanticLabel,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: widget.onTap,
          child: ExcludeSemantics(
            child: Transform.scale(
              scale: _down ? 0.98 : 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: NocheSize.touch,
                  minHeight: NocheSize.touch,
                ),
                child: Container(
                  height: NocheSize.touch,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
                  alignment: AlignmentDirectional.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(NocheSize.pillRadius),
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ),
            ),
          ),
        ),
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
      builder: (context, _) => Container(
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
              duration: const Duration(milliseconds: 140),
              width: 52,
              height: 32,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: value ? NocheColors.text : NocheColors.line,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 140),
                alignment: value
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Container(
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
      ),
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
