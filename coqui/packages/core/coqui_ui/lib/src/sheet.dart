/// The bottom sheet (app.html:67-85): the place sheet, the word sheet, the welcome.
library;

import 'package:coqui_ui/src/buttons.dart';
import 'package:coqui_ui/src/fades.dart';
import 'package:coqui_ui/src/layout.dart';
import 'package:coqui_ui/src/text_styles.dart';
import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// The sheet's surface: white, 24 px corners at the top, at most 70% of the
/// screen high (85% for a [modal] welcome), at most 560 px wide.
///
/// A header bar 56 px high holds the drag handle (40 x 4), the [title] (24/32
/// semibold, one line) and the X (48 px, 8 px from the top and right). A
/// [modal] sheet has no header: the welcome must be finished once. The [child]
/// scrolls under the header and fades out at its foot (24 px); a hairline shows
/// under the header once it has scrolled. [footer] stays in view.
///
/// Dragging the header down more than 72 px calls [onClose] (the old `arrastra`).
/// Place it with [CoquiSheetLayer], which adds the scrim and the slide.
class CoquiSheet extends StatefulWidget {
  const CoquiSheet({
    super.key,
    required this.child,
    this.title,
    this.footer,
    this.onClose,
    this.modal = false,
    this.titleVisible = true,
    this.scrollController,
  });

  /// The body: the rows. Padding (16, 16, 24) is added around it.
  final Widget child;
  final String? title;
  final Widget? footer;

  /// The X and the drag to close. Ignored when [modal].
  final VoidCallback? onClose;
  final bool modal;

  /// `#shead.wl .st`: the word sheet hides the title until its big word has
  /// scrolled away. app.html:76
  final bool titleVisible;
  final ScrollController? scrollController;

  @override
  State<CoquiSheet> createState() => _CoquiSheetState();
}

class _CoquiSheetState extends State<CoquiSheet> {
  ScrollController? _own;
  double _drag = 0;
  bool _scrolled = false;

  ScrollController get _controller =>
      widget.scrollController ?? (_own ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(CoquiSheet old) {
    super.didUpdateWidget(old);
    if (old.scrollController != widget.scrollController) {
      (old.scrollController ?? _own)?.removeListener(_onScroll);
      _controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _own?.dispose();
    super.dispose();
  }

  void _onScroll() {
    final s = _controller.hasClients && _controller.offset > 0;
    if (s != _scrolled) setState(() => _scrolled = s);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final maxH =
        media.height *
        (widget.modal
            ? CoquiMetrics.sheetModalMaxFraction
            : CoquiMetrics.sheetMaxFraction);
    final bodyTop = widget.modal ? CoquiMetrics.s24 : CoquiMetrics.s16;
    final footPad = widget.modal
        ? CoquiMetrics.s24 + CoquiLayout.safeBottom(context)
        : CoquiMetrics.s16;
    final hasTitle = widget.title != null;
    return Transform.translate(
      offset: Offset(0, _drag),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: CoquiMetrics.columnMax,
          maxHeight: maxH,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: CoquiColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(CoquiMetrics.radiusSheet),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.modal) _header(hasTitle),
              Flexible(
                child: FadingEdges(
                  bottom: CoquiMetrics.fadeSheet,
                  child: SingleChildScrollView(
                    controller: _controller,
                    padding: EdgeInsetsDirectional.fromSTEB(
                      CoquiMetrics.s16,
                      bodyTop,
                      CoquiMetrics.s16,
                      CoquiMetrics.s24,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
              if (widget.footer != null)
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    CoquiMetrics.s16,
                    CoquiMetrics.s8,
                    CoquiMetrics.s16,
                    footPad,
                  ),
                  child: widget.footer,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// `#shead`: an opaque 56 px bar; the handle, the title and the X. app.html:74-81
  Widget _header(bool hasTitle) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onVerticalDragUpdate: widget.onClose == null
        ? null
        : (d) => setState(() => _drag = (_drag + d.delta.dy).clamp(0, 2000)),
    onVerticalDragEnd: widget.onClose == null
        ? null
        : (_) {
            final close = _drag > 72;
            setState(() => _drag = 0);
            if (close) widget.onClose!();
          },
    onVerticalDragCancel: () => setState(() => _drag = 0),
    child: Container(
      height: CoquiMetrics.sheetHeader,
      decoration: BoxDecoration(
        color: CoquiColors.white,
        boxShadow: _scrolled ? CoquiShadows.sheetHeader : null,
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            end: 0,
            top: hasTitle ? 6 : 12,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CoquiColors.grab,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (hasTitle)
            PositionedDirectional(
              start: CoquiMetrics.s16,
              end: 72,
              top: 16,
              child: AnimatedOpacity(
                opacity: widget.titleVisible ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Text(
                  widget.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CoquiText.sheetTitle,
                ),
              ),
            ),
          PositionedDirectional(
            end: 8,
            top: 8,
            child: CoquiCloseButton(onPressed: widget.onClose),
          ),
        ],
      ),
    ),
  );
}

/// Puts a [CoquiSheet] where the old app puts it: a scrim over the page and the
/// tab bar (`rgba(0,0,0,.35)`), the sheet sliding up in 200 ms from just above
/// the tab bar and the raised Mapa disc (`bottom: navh + rise + safe-area`), or
/// from the screen's foot when [modal]. A tap on the scrim calls
/// [onScrimTap] (the welcome ignores it: leave it null). Fill the screen with it
/// (a `Stack` child). app.html:68-73
class CoquiSheetLayer extends StatelessWidget {
  const CoquiSheetLayer({
    super.key,
    required this.open,
    required this.sheet,
    this.modal = false,
    this.onScrimTap,
  });

  final bool open;
  final CoquiSheet sheet;
  final bool modal;
  final VoidCallback? onScrimTap;

  @override
  Widget build(BuildContext context) {
    final bottom = modal
        ? 0.0
        : CoquiLayout.navHeight(context) +
              CoquiLayout.rise(context) +
              CoquiLayout.safeBottom(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: !open,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onScrimTap,
            child: AnimatedOpacity(
              opacity: open ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: const ColoredBox(color: CoquiColors.scrim),
            ),
          ),
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: bottom,
          child: IgnorePointer(
            ignoring: !open,
            child: AnimatedSlide(
              offset: open ? Offset.zero : const Offset(0, 1.2),
              duration: const Duration(milliseconds: 200),
              child: Align(alignment: Alignment.bottomCenter, child: sheet),
            ),
          ),
        ),
      ],
    );
  }
}

/// The sheets that are open, one per root navigator: a second [showCoquiSheet] while one is open is
/// ignored, as the old page ignores a second open (`abre()` finds the one sheet already there).
final _openSheets = Expando<Future<void>>('open CoquiSheet');

/// Opens a [CoquiSheet] above everything, the shell's tab bar included, and completes when it closes.
///
/// v=39's scrim covers the whole page and the tab bar (`#sheetbg{position:fixed;inset:0;z-index:11}`),
/// and the sheet stands above it, over the tab bar and the raised Mapa disc (`#sheet{z-index:12}`;
/// `bottom: navh + rise + safe-area`, or 0 when [modal]). So the sheet is a route of the *root* navigator:
/// the scrim is the route's barrier (`rgba(0,0,0,.35)`, fading in 200 ms), the sheet slides up in 200 ms,
/// and nothing under it takes a touch. app.html:67-73
///
/// [builder] makes the sheet; it is given a `close` callback (for a button in its footer: the welcome's).
/// This function sets the sheet's `onClose` (the X, and the drag down past 72 px, both call `close`) and its
/// `modal` (to [modal]), so the builder writes neither. The ways to close a sheet:
///
/// - the X, a drag of the header down past 72 px, a tap on the scrim, the system back button: each closes it;
/// - `close`, from inside it, closes it;
/// - a [modal] sheet (the welcome) has no X and no drag, ignores a tap on the scrim, and ignores the system
///   back button: it must be finished, and its own button calls `close`.
///
/// Opening a sheet while one is open does nothing and returns the future of the one that is open. The
/// future completes when the sheet is popped (its slide out takes 200 ms more). Use [CoquiSheet] and
/// [CoquiSheetLayer] for a sheet in place inside a screen.
Future<void> showCoquiSheet(
  BuildContext context, {
  required CoquiSheet Function(BuildContext context, VoidCallback close)
  builder,
  bool modal = false,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final open = _openSheets[navigator];
  if (open != null) return open;
  final route = _CoquiSheetRoute(
    builder: builder,
    modal: modal,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
  );
  final future = navigator.push<void>(route).whenComplete(() {
    _openSheets[navigator] = null;
  });
  _openSheets[navigator] = future;
  return future;
}

class _CoquiSheetRoute extends PopupRoute<void> {
  _CoquiSheetRoute({
    required this.builder,
    required this.modal,
    required this.themes,
  });

  final CoquiSheet Function(BuildContext context, VoidCallback close) builder;
  final bool modal;
  final CapturedThemes themes;

  /// `#sheetbg` `rgba(0,0,0,.35)`. app.html:68
  @override
  Color? get barrierColor => CoquiColors.scrim;

  /// A tap on the scrim closes the sheet; the modal welcome ignores it. app.html:68-73
  @override
  bool get barrierDismissible => !modal;

  @override
  String? get barrierLabel => null;

  /// `transition:transform .2s`. app.html:70-71
  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  void _close() {
    final navigator = this.navigator;
    if (navigator == null || !isActive) return;
    if (isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(this);
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final slide = CurvedAnimation(parent: animation, curve: Curves.ease);
    return themes.wrap(
      PopScope(
        // The system back button closes a sheet; the welcome cannot be closed that way.
        canPop: !modal,
        child: Builder(
          builder: (context) {
            final sheet = builder(context, _close);
            final bottom = modal
                ? 0.0
                : CoquiLayout.navHeight(context) +
                      CoquiLayout.rise(context) +
                      CoquiLayout.safeBottom(context);
            return Stack(
              fit: StackFit.expand,
              children: [
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: bottom,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 1.2),
                      end: Offset.zero,
                    ).animate(slide),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: CoquiSheet(
                        key: sheet.key,
                        title: sheet.title,
                        footer: sheet.footer,
                        titleVisible: sheet.titleVisible,
                        scrollController: sheet.scrollController,
                        modal: modal,
                        onClose: modal ? null : _close,
                        child: sheet.child,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
