/// The tap behaviour every button of the old app shares: a hand cursor on the
/// web, and a pressed state that lasts while the finger is down (`:active`).
library;

import 'package:material_ui/material_ui.dart';

/// Wraps [builder] in a tap target. [builder] gets `true` while the finger is
/// down. With a null [onPressed] it is disabled: it reports a disabled button to
/// accessibility and ignores taps.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.semanticLabel,
    this.semanticsButton = true,
    this.selected,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, bool pressed) builder;

  /// What a screen reader says (the old buttons carry `aria-label`).
  final String? semanticLabel;
  final bool semanticsButton;

  /// `aria-pressed` of a toggle (the "Aa" text size button). Null: not a toggle.
  final bool? selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: widget.semanticsButton,
      enabled: enabled,
      label: widget.semanticLabel,
      toggled: widget.selected,
      onTap: widget.onPressed,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: widget.onPressed,
          child: ExcludeSemantics(
            excluding: widget.semanticLabel != null,
            child: widget.builder(context, _down && enabled),
          ),
        ),
      ),
    );
  }
}
