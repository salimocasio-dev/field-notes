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
                    padding: EdgeInsets.fromLTRB(
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
                  padding: EdgeInsets.fromLTRB(
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
          Positioned(
            left: 0,
            right: 0,
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
            Positioned(
              left: CoquiMetrics.s16,
              right: 72,
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
          Positioned(
            right: 8,
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
        Positioned(
          left: 0,
          right: 0,
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
