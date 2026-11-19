/// A pressed state for the shelf's and the reader's own tap targets (coqui_ui keeps its `Pressable` inside).
library;

import 'package:material_ui/material_ui.dart';

/// A tap target that says whether a finger is down (`:active`).
class PressTarget extends StatefulWidget {
  const PressTarget({
    super.key,
    required this.onPressed,
    required this.builder,
    this.semanticLabel,
    this.button = true,
    this.excludeChildSemantics = true,
    this.selected,
    this.onTapUp,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, bool pressed) builder;
  final String? semanticLabel;
  final bool button;

  /// The label replaces what the child would say.
  final bool excludeChildSemantics;

  /// `aria-pressed` of a toggle.
  final bool? selected;

  /// With a callback here the tap's position is given (the reader's lines find the word under it).
  final void Function(TapUpDetails details)? onTapUp;

  @override
  State<PressTarget> createState() => _PressTargetState();
}

class _PressTargetState extends State<PressTarget> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null || widget.onTapUp != null;
    return Semantics(
      button: widget.button,
      enabled: enabled,
      label: widget.semanticLabel,
      toggled: widget.selected,
      onTap: widget.onPressed,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled
              ? (d) {
                  _set(false);
                  widget.onTapUp?.call(d);
                  if (widget.onTapUp == null) widget.onPressed?.call();
                }
              : null,
          onTapCancel: enabled ? () => _set(false) : null,
          child: ExcludeSemantics(
            excluding:
                widget.semanticLabel != null && widget.excludeChildSemantics,
            child: widget.builder(context, _down && enabled),
          ),
        ),
      ),
    );
  }
}
