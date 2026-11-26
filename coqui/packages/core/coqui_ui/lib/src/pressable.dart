/// The tap behaviour every button of the old app shares: a hand cursor on the
/// web, and a pressed state that lasts while the finger is down (`:active`).
library;

import 'package:coqui_ui/src/noche_motion.dart';
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
    this.disc = false,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, bool pressed) builder;

  /// What a screen reader says (the old buttons carry `aria-label`).
  final String? semanticLabel;
  final bool semanticsButton;

  /// `aria-pressed` of a toggle (the "Aa" text size button). Null: not a toggle.
  final bool? selected;

  /// Whether this is a round disc target (uses `pressScaleDisc` instead of
  /// `pressScale`).
  final bool disc;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  bool _down = false;
  late final AnimationController _controller = AnimationController(vsync: this);

  void _set(bool v) {
    if (_down == v || !mounted) return;
    setState(() => _down = v);
    final motion = NocheMotion.of(context);
    if (v) {
      _controller.animateTo(1.0, duration: motion.press, curve: motion.enter);
    } else {
      _controller.animateTo(
        0.0,
        duration: motion.pressBack,
        curve: motion.enter,
      );
    }
  }

  @override
  void didUpdateWidget(Pressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null && (_down || _controller.value > 0)) {
      _down = false;
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final motion = NocheMotion.of(context);
    final targetScale = widget.disc ? motion.pressScaleDisc : motion.pressScale;
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
            child: AnimatedBuilder(
              animation: _controller,
              child: widget.builder(context, _down && enabled),
              builder: (context, child) {
                final t = _controller.value;
                final scale = 1.0 + (targetScale - 1.0) * t;
                final brightness = 1.0 - motion.pressDim * t;
                Widget current = child!;
                if (t > 0) {
                  current = ColorFiltered(
                    colorFilter: ColorFilter.matrix(<double>[
                      brightness,
                      0,
                      0,
                      0,
                      0,
                      0,
                      brightness,
                      0,
                      0,
                      0,
                      0,
                      0,
                      brightness,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
                    child: current,
                  );
                }
                return Transform.scale(scale: scale, child: current);
              },
            ),
          ),
        ),
      ),
    );
  }
}
