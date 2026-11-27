/// Noche chrome: floating tab bar, bottom sheet, and screen frame.
library;

import 'dart:ui' show SemanticsRole, lerpDouble;

import 'package:coqui_ui/src/noche_a11y.dart';
import 'package:coqui_ui/src/noche_icons.dart';
import 'package:coqui_ui/src/noche_motion.dart';
import 'package:coqui_ui/src/noche_motion_pieces.dart';
import 'package:coqui_ui/src/noche_tokens.dart';
import 'package:coqui_ui/src/pressable.dart';
import 'package:material_ui/material_ui.dart';

/// Fixed Noche tab ids and display order (`library`, `words`, `map`, `speak`,
/// `me`). The order never mirrors.
abstract final class NocheTabs {
  static const String library = 'library';
  static const String words = 'words';
  static const String map = 'map';
  static const String speak = 'speak';
  static const String me = 'me';

  static const List<String> order = [library, words, map, speak, me];
}

/// Floating bottom tab bar (`Noche-Mapa.dc.html`, `Noche-Palabras.dc.html`).
///
/// Inset 16 from start, end and bottom, 64 high, radius 32, `panel` fill,
/// 1 px `line` border, 5 equal columns in fixed order (`library`, `words`,
/// `map`, `speak`, `me` — never mirrors). Labels come from [tabNames] (from
/// `course.language.tabNames`, or `CoquiLabels` until N2.1 merges), drawn with
/// `NocheType.forScript`. The Map disc is a 56 circle in `next` with a 26
/// `onAccent` map icon (stroke 2.2), raised 24 above the bar with a 4 px ring
/// of `ground`, on every screen.
class NocheTabBar extends StatefulWidget {
  const NocheTabBar({
    super.key,
    required this.selectedId,
    required this.tabNames,
    required this.onTap,
    this.script = 'Latn',
    this.languageCode,
    this.respectSafeArea = true,
  });

  final String selectedId;

  /// Tab labels keyed by [NocheTabs.order] (`library`, `words`, `map`, `speak`, `me`).
  final Map<String, String> tabNames;
  final ValueChanged<String> onTap;
  final String script;
  final String? languageCode;
  final bool respectSafeArea;

  /// How far the raised Map disc + 4 px ring rises above the 64 px bar.
  static const double mapRise = 24;

  static NocheIconData _iconFor(String id) => switch (id) {
    NocheTabs.library => NocheIcons.library,
    NocheTabs.words => NocheIcons.words,
    NocheTabs.map => NocheIcons.map,
    NocheTabs.speak => NocheIcons.mic,
    NocheTabs.me => NocheIcons.me,
    _ => NocheIcons.map,
  };

  @override
  State<NocheTabBar> createState() => _NocheTabBarState();
}

class _NocheTabBarState extends State<NocheTabBar>
    with TickerProviderStateMixin {
  late final AnimationController _posController = AnimationController(
    vsync: this,
    value: 1.0,
  );
  late final AnimationController _visController = AnimationController(
    vsync: this,
    value: _hidesPill(widget.selectedId) ? 0.0 : 1.0,
  );

  late double _fromIndex = _indexFor(widget.selectedId).toDouble();
  late double _toIndex = _indexFor(widget.selectedId).toDouble();

  static int _indexFor(String id) {
    final idx = NocheTabs.order.indexOf(id);
    return idx < 0 ? 2 : idx;
  }

  static bool _hidesPill(String id) =>
      id == NocheTabs.map || !NocheTabs.order.contains(id);

  @override
  void didUpdateWidget(NocheTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId == oldWidget.selectedId) return;

    final motion = NocheMotion.of(context);
    final newIndex = _indexFor(widget.selectedId).toDouble();
    final toHidden = _hidesPill(widget.selectedId);
    final fromHidden = _hidesPill(oldWidget.selectedId);

    if (motion.reduced) {
      _fromIndex = newIndex;
      _toIndex = newIndex;
      _posController.value = 1.0;
      if (toHidden) {
        _visController.animateTo(
          0.0,
          duration: motion.quick,
          curve: motion.enter,
        );
      } else if (fromHidden) {
        _visController.animateTo(
          1.0,
          duration: motion.quick,
          curve: motion.enter,
        );
      } else {
        _visController.value = 0.0;
        _visController.animateTo(
          1.0,
          duration: motion.quick,
          curve: motion.enter,
        );
      }
      return;
    }

    final currentPos =
        lerpDouble(
          _fromIndex,
          _toIndex,
          motion.travel.transform(_posController.value),
        ) ??
        newIndex;
    _fromIndex = currentPos;
    _toIndex = newIndex;
    _posController.duration = motion.move;
    _posController.forward(from: 0.0);

    if (toHidden) {
      _visController.animateTo(
        0.0,
        duration: motion.quick,
        curve: motion.enter,
      );
    } else if (fromHidden || _visController.value < 1.0) {
      _visController.animateTo(
        1.0,
        duration: motion.quick,
        curve: motion.enter,
      );
    }
  }

  @override
  void dispose() {
    _posController.dispose();
    _visController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      NocheTabs.order.every((id) => (widget.tabNames[id] ?? '').isNotEmpty),
      'NocheTabBar requires non-empty tabNames for all five tabs: ${NocheTabs.order}',
    );
    final motion = NocheMotion.of(context);
    final safeBottom = widget.respectSafeArea
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    final locale = widget.languageCode == null
        ? null
        : Locale(widget.languageCode!);
    final totalBoxHeight = NocheTabBar.mapRise + NocheSize.tabBarHeight;
    final metricGlyph = widget.script == 'Arab'
        ? String.fromCharCode(0x0627)
        : 'x';

    return Semantics(
      container: true,
      role: SemanticsRole.tabBar,
      label: NocheA11y.label(NocheA11y.tabs),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          NocheSize.tabBarInset,
          0,
          NocheSize.tabBarInset,
          NocheSize.tabBarInset + safeBottom,
        ),
        child: SizedBox(
          height: totalBoxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PositionedDirectional(
                start: 0,
                end: 0,
                top: NocheTabBar.mapRise,
                height: NocheSize.tabBarHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: NocheColors.panel,
                    border: Border.all(color: NocheColors.line, width: 1),
                    borderRadius: BorderRadius.circular(NocheSize.tabBarRadius),
                  ),
                  child: NocheLtr(
                    child: IgnorePointer(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 28,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final slotWidth =
                                    constraints.maxWidth /
                                    NocheTabs.order.length;
                                return AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _posController,
                                    _visController,
                                  ]),
                                  builder: (context, _) {
                                    final pos = motion.reduced
                                        ? _toIndex
                                        : (lerpDouble(
                                                _fromIndex,
                                                _toIndex,
                                                motion.travel.transform(
                                                  _posController.value,
                                                ),
                                              ) ??
                                              _toIndex);
                                    final pillOpacity = _visController.value
                                        .clamp(0.0, 1.0);
                                    final pillScale = motion.reduced
                                        ? 1.0
                                        : 0.5 + 0.5 * pillOpacity;
                                    final pillStart =
                                        pos * slotWidth + (slotWidth - 48) / 2;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        PositionedDirectional(
                                          start: pillStart,
                                          top: 0,
                                          width: 48,
                                          height: 28,
                                          child: Opacity(
                                            opacity: pillOpacity,
                                            child: Transform.scale(
                                              scale: pillScale,
                                              child: DecoratedBox(
                                                key: const ValueKey(
                                                  'noche_tab_pill',
                                                ),
                                                decoration: BoxDecoration(
                                                  color: NocheColors.line,
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                          Opacity(
                            opacity: 0,
                            child: ExcludeSemantics(
                              child: Text(
                                metricGlyph,
                                maxLines: 1,
                                softWrap: false,
                                locale: locale,
                                style: NocheType.forScript(
                                  NocheType.tabLabel,
                                  widget.script,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Fixed visual order: library, words, map, speak, me never mirrors.
              Positioned.fill(
                child: NocheLtr(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final id in NocheTabs.order)
                        Expanded(
                          child: id == NocheTabs.map
                              ? _MapTab(
                                  label: widget.tabNames[id] ?? '',
                                  selected: widget.selectedId == id,
                                  script: widget.script,
                                  locale: locale,
                                  onTap: () => widget.onTap(id),
                                )
                              : Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    top: NocheTabBar.mapRise,
                                  ),
                                  child: _RegularTab(
                                    icon: NocheTabBar._iconFor(id),
                                    label: widget.tabNames[id] ?? '',
                                    selected: widget.selectedId == id,
                                    script: widget.script,
                                    locale: locale,
                                    onTap: () => widget.onTap(id),
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegularTab extends StatelessWidget {
  const _RegularTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.script,
    required this.locale,
    required this.onTap,
  });

  final NocheIconData icon;
  final String label;
  final bool selected;
  final String script;
  final Locale? locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    final fg = selected ? NocheColors.text : NocheColors.label;
    final baseStyle = NocheType.forScript(
      selected ? NocheType.tabLabelOn : NocheType.tabLabel,
      script,
    );

    return Semantics(
      role: SemanticsRole.tab,
      selected: selected,
      child: Pressable(
        onPressed: onTap,
        semanticLabel: label,
        semanticsButton: false,
        builder: (context, _) => TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: fg),
          duration: motion.quick,
          curve: motion.enter,
          builder: (context, animatedColor, _) {
            final color = animatedColor ?? fg;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 28,
                  alignment: AlignmentDirectional.center,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: NocheIcon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  locale: locale,
                  style: baseStyle.copyWith(color: color),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab({
    required this.label,
    required this.selected,
    required this.script,
    required this.locale,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final String script;
  final Locale? locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    final labelColor = selected ? NocheColors.text : NocheColors.label;
    final baseStyle = NocheType.forScript(
      selected ? NocheType.tabLabelOn : NocheType.tabLabel,
      script,
    );
    final bottomPad = script == 'Arab' ? 2.0 : 8.0;

    return Semantics(
      role: SemanticsRole.tab,
      selected: selected,
      child: Pressable(
        onPressed: onTap,
        semanticLabel: label,
        semanticsButton: false,
        disc: true,
        builder: (context, _) => Stack(
          alignment: AlignmentDirectional.topCenter,
          clipBehavior: Clip.none,
          children: [
            // 56 disc in `next` inside a 4 px ring of `ground` (64 total),
            // rising 24 above the 64 px bar.
            Container(
              width: 64,
              height: 64,
              alignment: AlignmentDirectional.center,
              decoration: const BoxDecoration(
                color: NocheColors.ground,
                shape: BoxShape.circle,
              ),
              child: Container(
                width: 56,
                height: 56,
                alignment: AlignmentDirectional.center,
                decoration: const BoxDecoration(
                  color: NocheColors.next,
                  shape: BoxShape.circle,
                ),
                child: const NocheIcon(
                  NocheIcons.map,
                  size: 26,
                  strokeWidth: 2.2,
                  color: NocheColors.onAccent,
                ),
              ),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: bottomPad,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: labelColor),
                duration: motion.quick,
                curve: motion.enter,
                builder: (context, animatedColor, _) => Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  locale: locale,
                  style: baseStyle.copyWith(color: animatedColor ?? labelColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTopBorderPainter extends CustomPainter {
  const _SheetTopBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, radius)
      ..arcToPoint(Offset(radius, 0.5), radius: Radius.circular(radius))
      ..lineTo(size.width - radius, 0.5)
      ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_SheetTopBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// Swaps sheet body content in place when [contentKey] changes without
/// changing height (locks a fixed height to the measured height of the initial
/// content and preserves the mounted outgoing element while it fades out).
///
/// The outgoing child fades out `1 -> 0` in `quick` on `exit` starting at
/// `t = 0`. The incoming child waits `swapAfter` (100 ms), then fades in
/// `0 -> 1` in `move` on `enter` (in reduced motion `quick` after
/// `swapAfter`).
class NocheSheetSwap extends StatefulWidget {
  const NocheSheetSwap({
    super.key,
    required this.contentKey,
    required this.child,
    this.alignment = AlignmentDirectional.topStart,
  });

  final Object contentKey;
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  State<NocheSheetSwap> createState() => _NocheSheetSwapState();
}

class _NocheSheetSwapState extends State<NocheSheetSwap>
    with SingleTickerProviderStateMixin {
  final GlobalKey _measureBoxKey = GlobalKey();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  )..addStatusListener(_handleStatus);

  GlobalKey _currentChildKey = GlobalKey();
  GlobalKey? _outgoingChildKey;
  Widget? _outgoingChild;
  double? _lockedHeight;
  NocheMotionData _activeMotion = NocheMotion.normal;

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _outgoingChild != null &&
        mounted) {
      setState(() {
        _outgoingChild = null;
        _outgoingChildKey = null;
      });
    }
  }

  @override
  void didUpdateWidget(NocheSheetSwap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentKey != oldWidget.contentKey) {
      if (_lockedHeight == null) {
        final ro = _measureBoxKey.currentContext?.findRenderObject();
        if (ro is RenderBox && ro.hasSize) {
          _lockedHeight = ro.size.height;
        }
      }
      _outgoingChild = oldWidget.child;
      _outgoingChildKey = _currentChildKey;
      _currentChildKey = GlobalKey();
      _activeMotion = NocheMotion.of(context);
      _controller.duration = _activeMotion.swapAfter + _activeMotion.move;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final motion = _controller.isAnimating
            ? _activeMotion
            : NocheMotion.of(context);
        final totalUs = (motion.swapAfter + motion.move).inMicroseconds
            .toDouble();
        final elapsedUs = _controller.value * totalUs;

        Widget? outgoingLayer;
        if (_outgoingChild != null && _controller.value < 1.0) {
          final quickUs = motion.quick.inMicroseconds.toDouble();
          final tOut = quickUs <= 0
              ? 1.0
              : (elapsedUs / quickUs).clamp(0.0, 1.0);
          if (tOut < 1.0) {
            final outOpacity = (1.0 - motion.exit.transform(tOut)).clamp(
              0.0,
              1.0,
            );
            outgoingLayer = Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    key: const ValueKey('noche_sheet_swap_outgoing'),
                    opacity: outOpacity,
                    child: SingleChildScrollView(
                      primary: false,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Align(
                        alignment: widget.alignment,
                        child: KeyedSubtree(
                          key: _outgoingChildKey,
                          child: _outgoingChild!,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        final double inOpacity;
        if (_controller.value >= 1.0) {
          inOpacity = 1.0;
        } else {
          final swapAfterUs = motion.swapAfter.inMicroseconds.toDouble();
          final moveUs = motion.move.inMicroseconds.toDouble();
          if (elapsedUs <= swapAfterUs) {
            inOpacity = 0.0;
          } else if (moveUs <= 0) {
            inOpacity = 1.0;
          } else {
            final rawIn = ((elapsedUs - swapAfterUs) / moveUs).clamp(0.0, 1.0);
            inOpacity = motion.enter.transform(rawIn);
          }
        }

        final keyedIncoming = KeyedSubtree(
          key: _currentChildKey,
          child: widget.child,
        );

        if (_lockedHeight == null) {
          return SizedBox(
            key: _measureBoxKey,
            child: Stack(
              alignment: widget.alignment,
              clipBehavior: Clip.none,
              children: [
                ?outgoingLayer,
                Opacity(
                  key: const ValueKey('noche_sheet_swap_incoming'),
                  opacity: inOpacity,
                  child: keyedIncoming,
                ),
              ],
            ),
          );
        }

        return SizedBox(
          key: _measureBoxKey,
          height: _lockedHeight,
          child: ClipRect(
            child: Stack(
              alignment: widget.alignment,
              fit: StackFit.expand,
              children: [
                ?outgoingLayer,
                Positioned.fill(
                  child: Opacity(
                    key: const ValueKey('noche_sheet_swap_incoming'),
                    opacity: inOpacity,
                    child: SingleChildScrollView(
                      primary: false,
                      child: Align(
                        alignment: widget.alignment,
                        child: keyedIncoming,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bottom sheet surface (`Noche-Idiomas.dc.html`, `Noche-Lector-Aa.dc.html`):
/// `panel` fill, radius 24 top corners, 40 by 4 `bar` handle 12 from the top,
/// optional `pageTitle` header with a 48 close button at the end.
class NocheSheet extends StatefulWidget {
  const NocheSheet({
    super.key,
    this.child,
    this.rows,
    this.next,
    this.rowsDelay = NocheMotion.rowsAfter,
    this.rowSpacing = 0,
    this.contentKey,
    this.title,
    this.onClose,
    this.closeLabel,
    this.respectSafeArea = true,
    this.scrollable = true,
  }) : assert(
         child != null || rows != null,
         'NocheSheet requires either child or rows.',
       );

  final Widget? child;
  final List<Widget>? rows;
  final Widget? next;
  final Duration rowsDelay;
  final double rowSpacing;
  final Object? contentKey;
  final String? title;
  final VoidCallback? onClose;
  final String? closeLabel;
  final bool respectSafeArea;
  final bool scrollable;

  @override
  State<NocheSheet> createState() => _NocheSheetState();
}

class _NocheSheetState extends State<NocheSheet> {
  double _drag = 0;

  @override
  Widget build(BuildContext context) {
    final safeBottom = widget.respectSafeArea
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    final hasHeader = widget.title != null || widget.onClose != null;
    const sheetRadius = NocheSize.cardRadius;

    Widget content = widget.rows != null
        ? NocheArrive(
            delay: widget.rowsDelay,
            spacing: widget.rowSpacing,
            next: widget.next,
            children: widget.rows!,
          )
        : widget.child!;

    if (widget.contentKey != null) {
      content = NocheSheetSwap(contentKey: widget.contentKey!, child: content);
    }

    final body = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        16,
        hasHeader ? 8 : 16,
        16,
        24 + safeBottom,
      ),
      child: content,
    );

    return Transform.translate(
      offset: Offset(0, _drag),
      child: ClipRRect(
        borderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(sheetRadius),
          topEnd: Radius.circular(sheetRadius),
        ),
        child: CustomPaint(
          foregroundPainter: const _SheetTopBorderPainter(
            color: NocheColors.line,
            radius: sheetRadius,
          ),
          child: ColoredBox(
            color: NocheColors.panel,
            child: DefaultTextStyle.merge(
              style: NocheType.body.copyWith(color: NocheColors.text),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: widget.onClose == null
                        ? null
                        : (d) => setState(
                            () => _drag = (_drag + d.delta.dy).clamp(0, 2000),
                          ),
                    onVerticalDragEnd: widget.onClose == null
                        ? null
                        : (_) {
                            final close = _drag > 72;
                            setState(() => _drag = 0);
                            if (close) widget.onClose!();
                          },
                    onVerticalDragCancel: () => setState(() => _drag = 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: NocheColors.bar,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (hasHeader) ...[
                          const SizedBox(height: NocheSize.grid),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              16,
                              0,
                              4,
                              0,
                            ),
                            child: SizedBox(
                              height: NocheSize.touch,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: widget.title == null
                                        ? const SizedBox.shrink()
                                        : Text(
                                            widget.title!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: NocheType.pageTitle.copyWith(
                                              color: NocheColors.text,
                                            ),
                                          ),
                                  ),
                                  if (widget.onClose != null)
                                    Semantics(
                                      container: true,
                                      child: Pressable(
                                        onPressed: widget.onClose,
                                        semanticLabel:
                                            widget.closeLabel ??
                                            NocheA11y.label(
                                              NocheA11y.closeSheet,
                                            ),
                                        disc: true,
                                        builder: (context, _) => const SizedBox(
                                          width: NocheSize.touch,
                                          height: NocheSize.touch,
                                          child: Center(
                                            child: NocheIcon(
                                              NocheIcons.close,
                                              size: 24,
                                              color: NocheColors.text,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.scrollable)
                    Flexible(child: SingleChildScrollView(child: body))
                  else
                    body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline overlay showing [sheet] over `NocheColors.scrim`.
class NocheSheetOverlay extends StatelessWidget {
  const NocheSheetOverlay({super.key, required this.sheet, this.onScrimTap});

  final NocheSheet sheet;
  final VoidCallback? onScrimTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onScrimTap,
          child: const ColoredBox(color: NocheColors.scrim),
        ),
        Align(alignment: AlignmentDirectional.bottomCenter, child: sheet),
      ],
    );
  }
}

/// Opens a [NocheSheet] over `NocheColors.scrim` on the root navigator.
Future<T?> showNocheSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, VoidCallback close) builder,
  String? title,
  String? closeLabel,
  bool dismissible = true,
}) {
  final motion = NocheMotion.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(
    _NocheSheetRoute<T>(
      builder: builder,
      title: title,
      closeLabel: closeLabel,
      dismissible: dismissible,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      motion: motion,
    ),
  );
}

class _NocheScrimColorAnimation extends Animation<Color?>
    with AnimationWithParentMixin<double> {
  _NocheScrimColorAnimation({
    required this.parent,
    required this.motion,
    required this.targetColor,
  });

  @override
  final Animation<double> parent;
  final NocheMotionData motion;
  final Color targetColor;

  @override
  Color? get value {
    final t = parent.value.clamp(0.0, 1.0);
    final isReverse =
        parent.status == AnimationStatus.reverse ||
        parent.status == AnimationStatus.dismissed;
    final double eased;
    if (isReverse) {
      final u = (1.0 - t).clamp(0.0, 1.0);
      eased = (1.0 - motion.exit.transform(u)).clamp(0.0, 1.0);
    } else {
      final pageInUs = motion.pageIn.inMicroseconds.toDouble();
      final moveUs = motion.move.inMicroseconds.toDouble();
      final ratio = pageInUs <= 0 ? 1.0 : (moveUs / pageInUs).clamp(0.0, 1.0);
      final rawIn = ratio <= 0 ? 1.0 : (t / ratio).clamp(0.0, 1.0);
      eased = motion.enter.transform(rawIn).clamp(0.0, 1.0);
    }
    return Color.lerp(targetColor.withValues(alpha: 0.0), targetColor, eased);
  }
}

class _NocheSheetRoute<T> extends PopupRoute<T> {
  _NocheSheetRoute({
    required this.builder,
    required this.title,
    required this.closeLabel,
    required this.dismissible,
    required this.themes,
    required this.motion,
  });

  final Widget Function(BuildContext context, VoidCallback close) builder;
  final String? title;
  final String? closeLabel;
  final bool dismissible;
  final CapturedThemes themes;
  final NocheMotionData motion;

  @override
  Color? get barrierColor => NocheColors.scrim;

  @override
  bool get barrierDismissible => dismissible;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => motion.pageIn;

  @override
  Duration get reverseTransitionDuration => motion.pageOut;

  bool _closing = false;

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
  Widget buildModalBarrier() {
    if (offstage) {
      return ModalBarrier(
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
        onDismiss: barrierDismissible ? _close : null,
      );
    }
    final barrier = AnimatedModalBarrier(
      key: const ValueKey<String>('noche_sheet_scrim'),
      color: _NocheScrimColorAnimation(
        parent: animation!,
        motion: motion,
        targetColor: NocheColors.scrim,
      ),
      dismissible: barrierDismissible,
      semanticsLabel: barrierLabel,
      barrierSemanticsDismissible: semanticsDismissible,
      onDismiss: barrierDismissible ? _close : null,
    );
    return AnimatedBuilder(
      animation: animation!,
      child: barrier,
      builder: (context, child) {
        final isReverse =
            animation!.status == AnimationStatus.reverse ||
            animation!.status == AnimationStatus.dismissed;
        return IgnorePointer(ignoring: isReverse, child: child);
      },
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final sheetChild = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: NocheSheet(
        title: title,
        closeLabel: closeLabel,
        onClose: dismissible ? _close : null,
        child: Builder(builder: (c) => builder(c, _close)),
      ),
    );

    return themes.wrap(
      PopScope(
        canPop: dismissible,
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
                  ? (1.0 - currentMotion.exit.transform((1.0 - t).clamp(0, 1)))
                        .clamp(0.0, 1.0)
                  : currentMotion.enter.transform(t).clamp(0.0, 1.0);
              sheetTransition = Opacity(
                key: const ValueKey('noche_sheet_surface'),
                opacity: sheetOpacity,
                child: child,
              );
            } else {
              final dy = isReverse
                  ? currentMotion.exit.transform((1.0 - t).clamp(0.0, 1.0))
                  : (1.0 - currentMotion.enter.transform(t));
              sheetTransition = FractionalTranslation(
                key: const ValueKey('noche_sheet_surface'),
                translation: Offset(0, dy),
                child: child,
              );
            }

            return Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: sheetTransition,
            );
          },
        ),
      ),
    );
  }
}

/// Noche screen frame: paints [backgroundColor] (`NocheColors.ground` by
/// default), respects safe areas, draws [tabBar] over the foot, and ensures
/// content scrolls under nothing by ending [body] at `NocheSize.aboveTabBar`
/// (104) above the bottom whenever [tabBar] is present.
class NocheScreen extends StatelessWidget {
  const NocheScreen({
    super.key,
    required this.body,
    this.tabBar,
    this.background,
    this.backgroundColor = NocheColors.ground,
  });

  final Widget body;
  final Widget? tabBar;

  /// Optional full-bleed background drawn behind [body] and [tabBar] (e.g. map).
  final Widget? background;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final bottomClearance = tabBar != null
        ? NocheSize.aboveTabBar + pad.bottom
        : pad.bottom;

    return ColoredBox(
      color: backgroundColor,
      child: DefaultTextStyle.merge(
        style: NocheType.body.copyWith(color: NocheColors.text),
        child: IconTheme.merge(
          data: const IconThemeData(color: NocheColors.text),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (background != null) Positioned.fill(child: background!),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    top: pad.top,
                    bottom: bottomClearance,
                  ),
                  child: ClipRect(child: body),
                ),
              ),
              if (tabBar != null)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: tabBar!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
