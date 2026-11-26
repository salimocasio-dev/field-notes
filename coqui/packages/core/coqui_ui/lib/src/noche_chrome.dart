/// Noche chrome: floating tab bar, bottom sheet, and screen frame.
library;

import 'dart:ui' show SemanticsRole;

import 'package:coqui_ui/src/noche_a11y.dart';
import 'package:coqui_ui/src/noche_icons.dart';
import 'package:coqui_ui/src/noche_motion.dart';
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
class NocheTabBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    assert(
      NocheTabs.order.every((id) => (tabNames[id] ?? '').isNotEmpty),
      'NocheTabBar requires non-empty tabNames for all five tabs: ${NocheTabs.order}',
    );
    final safeBottom = respectSafeArea
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    final locale = languageCode == null ? null : Locale(languageCode!);
    final totalBoxHeight = mapRise + NocheSize.tabBarHeight;

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
                top: mapRise,
                height: NocheSize.tabBarHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: NocheColors.panel,
                    border: Border.all(color: NocheColors.line, width: 1),
                    borderRadius: BorderRadius.circular(NocheSize.tabBarRadius),
                  ),
                ),
              ),
              // Fixed visual order: library, words, map, speak, me never mirrors.
              Positioned.fill(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final id in NocheTabs.order)
                        Expanded(
                          child: id == NocheTabs.map
                              ? _MapTab(
                                  label: tabNames[id] ?? '',
                                  selected: selectedId == id,
                                  script: script,
                                  locale: locale,
                                  onTap: () => onTap(id),
                                )
                              : Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    top: mapRise,
                                  ),
                                  child: _RegularTab(
                                    icon: _iconFor(id),
                                    label: tabNames[id] ?? '',
                                    selected: selectedId == id,
                                    script: script,
                                    locale: locale,
                                    onTap: () => onTap(id),
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
    final fg = selected ? NocheColors.text : NocheColors.label;
    final style = NocheType.forScript(
      selected ? NocheType.tabLabelOn : NocheType.tabLabel,
      script,
    ).copyWith(color: fg);

    return Semantics(
      role: SemanticsRole.tab,
      selected: selected,
      child: Pressable(
        onPressed: onTap,
        semanticLabel: label,
        semanticsButton: false,
        builder: (context, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 28,
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                color: selected ? NocheColors.line : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: NocheIcon(icon, size: 22, color: fg),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              locale: locale,
              style: style,
            ),
          ],
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
    final labelColor = selected ? NocheColors.text : NocheColors.label;
    final style = NocheType.forScript(
      selected ? NocheType.tabLabelOn : NocheType.tabLabel,
      script,
    ).copyWith(color: labelColor);
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
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                locale: locale,
                style: style,
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

/// Bottom sheet surface (`Noche-Idiomas.dc.html`, `Noche-Lector-Aa.dc.html`):
/// `panel` fill, radius 24 top corners, 40 by 4 `bar` handle 12 from the top,
/// optional `pageTitle` header with a 48 close button at the end.
class NocheSheet extends StatefulWidget {
  const NocheSheet({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.closeLabel,
    this.respectSafeArea = true,
    this.scrollable = true,
  });

  final Widget child;
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

    final body = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        16,
        hasHeader ? 8 : 16,
        16,
        24 + safeBottom,
      ),
      child: widget.child,
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

  void _close() {
    final nav = navigator;
    if (nav == null || !isActive) return;
    if (isCurrent) {
      nav.pop();
    } else {
      nav.removeRoute(this);
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final motion = NocheMotion.of(context);
    final slide = CurvedAnimation(
      parent: animation,
      curve: motion.enter,
      reverseCurve: motion.exit,
    );
    return themes.wrap(
      PopScope(
        canPop: dismissible,
        child: Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(slide),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.88,
              ),
              child: NocheSheet(
                title: title,
                closeLabel: closeLabel,
                onClose: dismissible ? _close : null,
                child: Builder(builder: (c) => builder(c, _close)),
              ),
            ),
          ),
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
