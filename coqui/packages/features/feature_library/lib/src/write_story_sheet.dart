import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/wording.dart';
import 'package:material_ui/material_ui.dart';

/// Result returned by the story-writing callback to [_StoryPromptSheet].
typedef WriteStoryResult = ({ReadingText? text, String? error, bool close});

/// Opens the Noche bottom sheet for entering optional practice words and
/// writing a new story at the learner's level (`Noche-Motion-Escribir.dc.html`).
Future<T?> showWriteStorySheet<T>(
  BuildContext context, {
  required Language language,
  required Future<WriteStoryResult> Function(String words) onSubmit,
}) {
  final motion = NocheMotion.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(
    _WriteStorySheetRoute<T>(
      language: language,
      onSubmit: onSubmit,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      motion: motion,
    ),
  );
}

class _WriteStoryScrimColorAnimation extends Animation<Color?>
    with AnimationWithParentMixin<double> {
  _WriteStoryScrimColorAnimation({
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

class _WriteStorySheetRoute<T> extends PopupRoute<T> {
  _WriteStorySheetRoute({
    required this.language,
    required this.onSubmit,
    required this.themes,
    required this.motion,
  });

  final Language language;
  final Future<WriteStoryResult> Function(String words) onSubmit;
  final CapturedThemes themes;
  final NocheMotionData motion;

  final ValueNotifier<bool> _dismissible = ValueNotifier<bool>(true);
  bool _closing = false;

  void _setDismissible(bool value) {
    if (_dismissible.value != value) {
      _dismissible.value = value;
    }
  }

  @override
  void dispose() {
    _dismissible.dispose();
    super.dispose();
  }

  @override
  Color? get barrierColor => NocheColors.scrim;

  @override
  bool get barrierDismissible => _dismissible.value;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => motion.pageIn;

  @override
  Duration get reverseTransitionDuration => motion.pageOut;

  void _close() {
    if (!_dismissible.value || _closing) return;
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
    return ValueListenableBuilder<bool>(
      valueListenable: _dismissible,
      builder: (context, canDismiss, _) {
        if (offstage) {
          return ModalBarrier(
            dismissible: canDismiss,
            semanticsLabel: barrierLabel,
            barrierSemanticsDismissible: semanticsDismissible && canDismiss,
            onDismiss: canDismiss ? _close : null,
          );
        }
        final barrier = AnimatedModalBarrier(
          key: const ValueKey<String>('noche_sheet_scrim'),
          color: _WriteStoryScrimColorAnimation(
            parent: animation!,
            motion: motion,
            targetColor: NocheColors.scrim,
          ),
          dismissible: canDismiss,
          semanticsLabel: barrierLabel,
          barrierSemanticsDismissible: semanticsDismissible && canDismiss,
          onDismiss: canDismiss ? _close : null,
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
      },
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final sheetBody = NocheSheet(
      title: null,
      onClose: null,
      scrollable: false,
      child: _StoryPromptSheet(
        language: language,
        onCancel: _close,
        setDismissible: _setDismissible,
        onSubmit: onSubmit,
      ),
    );

    return themes.wrap(
      ValueListenableBuilder<bool>(
        valueListenable: _dismissible,
        builder: (context, canDismiss, _) {
          final sheetChild = Padding(
            padding: EdgeInsetsDirectional.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.88,
              ),
              child: _DraggableSheetSurface(
                canDismiss: canDismiss,
                onDismiss: _close,
                child: sheetBody,
              ),
            ),
          );

          return PopScope(
            canPop: canDismiss,
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
                                  (1.0 - t).clamp(0, 1),
                                ))
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
          );
        },
      ),
    );
  }
}

class _DraggableSheetSurface extends StatefulWidget {
  const _DraggableSheetSurface({
    required this.canDismiss,
    required this.onDismiss,
    required this.child,
  });

  final bool canDismiss;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<_DraggableSheetSurface> createState() => _DraggableSheetSurfaceState();
}

class _DraggableSheetSurfaceState extends State<_DraggableSheetSurface> {
  double _drag = 0;

  @override
  void didUpdateWidget(_DraggableSheetSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.canDismiss && _drag != 0) {
      _drag = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _drag),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: !widget.canDismiss
            ? null
            : (d) =>
                  setState(() => _drag = (_drag + d.delta.dy).clamp(0, 2000)),
        onVerticalDragEnd: !widget.canDismiss
            ? null
            : (_) {
                final close = _drag > 72;
                setState(() => _drag = 0);
                if (close) widget.onDismiss();
              },
        onVerticalDragCancel: !widget.canDismiss
            ? null
            : () => setState(() => _drag = 0),
        child: widget.child,
      ),
    );
  }
}

class _StoryPromptSheet extends StatefulWidget {
  const _StoryPromptSheet({
    required this.language,
    required this.onCancel,
    required this.setDismissible,
    required this.onSubmit,
  });

  final Language language;
  final VoidCallback onCancel;
  final ValueChanged<bool> setDismissible;
  final Future<WriteStoryResult> Function(String words) onSubmit;

  @override
  State<_StoryPromptSheet> createState() => _StoryPromptSheetState();
}

class _StoryPromptSheetState extends State<_StoryPromptSheet> {
  final GlobalKey _formKey = GlobalKey();
  final _words = TextEditingController();
  bool _writing = false;
  bool _hasSwapped = false;
  String? _error;
  double? _measuredFormHeight;

  @override
  void dispose() {
    _words.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_writing) return;
    FocusScope.of(context).unfocus();
    final formBox = _formKey.currentContext?.findRenderObject();
    if (formBox is RenderBox && formBox.hasSize) {
      _measuredFormHeight = formBox.size.height;
    }
    widget.setDismissible(false);
    setState(() {
      _writing = true;
      _hasSwapped = true;
      _error = null;
    });
    final WriteStoryResult result;
    try {
      result = await widget.onSubmit(_words.text.trim());
    } on Object {
      if (!mounted) return;
      widget.setDismissible(true);
      setState(() {
        _writing = false;
        _error = LibraryWording.storySaveFailed;
      });
      return;
    }
    if (!mounted) return;
    if (result.close) {
      Navigator.pop(context, result.text);
      return;
    }
    widget.setDismissible(true);
    setState(() {
      _writing = false;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    final courseDirection = widget.language.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(NocheSize.tileRadius),
      borderSide: const BorderSide(color: NocheColors.line),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(NocheSize.tileRadius),
      borderSide: const BorderSide(color: NocheColors.text),
    );

    TextStyle fieldStyle(TextStyle base, Color color) =>
        base.copyWith(color: color, textBaseline: TextBaseline.alphabetic);

    final header = SizedBox(
      height: NocheSize.touch,
      child: Row(
        children: [
          Expanded(
            child: Text(
              LibraryWording.writeMyStory,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NocheType.sheetTitle.copyWith(color: NocheColors.text),
            ),
          ),
          Semantics(
            container: true,
            child: Pressable(
              onPressed: _writing ? null : widget.onCancel,
              semanticLabel: NocheA11y.label(NocheA11y.closeSheet),
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
    );

    final fieldAndMessage = Padding(
      padding: const EdgeInsetsDirectional.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _words,
            enabled: !_writing,
            minLines: 1,
            maxLines: 2,
            maxLength: 180,
            cursorColor: NocheColors.text,
            textDirection: courseDirection,
            style: fieldStyle(
              NocheType.forScript(NocheType.body, widget.language.script),
              NocheColors.text,
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => unawaited(_submit()),
            decoration: InputDecoration(
              filled: true,
              fillColor: NocheColors.ground,
              labelText: LibraryWording.practiceWordsLabel,
              labelStyle: fieldStyle(NocheType.body, NocheColors.label),
              floatingLabelStyle: fieldStyle(NocheType.label, NocheColors.text),
              counterStyle: fieldStyle(NocheType.bodySmall, NocheColors.label),
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: focusedBorder,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _error == null
                  ? Text(
                      LibraryWording.practiceWordsHelper,
                      style: NocheType.bodySmall.copyWith(
                        color: NocheColors.label,
                      ),
                    )
                  : Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: NocheType.body.copyWith(color: NocheColors.text),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );

    final actions = Padding(
      padding: const EdgeInsetsDirectional.only(top: 16),
      child: Row(
        children: [
          NocheOutlineButton(
            label: LibraryWording.cancel,
            expand: false,
            onPressed: _writing ? null : widget.onCancel,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _WriteStorySubmitButton(
              key: const Key('library-write-story-submit'),
              label: LibraryWording.writeMyStory,
              onPressed: _writing ? null : () => unawaited(_submit()),
            ),
          ),
        ],
      ),
    );

    final formSections = [header, fieldAndMessage, actions];

    final formBody = KeyedSubtree(
      key: _formKey,
      child: !_hasSwapped
          ? NocheArrive(delay: motion.rowsAfter, children: formSections)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: formSections,
            ),
    );

    final writingBody = ConstrainedBox(
      constraints: BoxConstraints(minHeight: _measuredFormHeight ?? 0),
      child: const Center(child: _WritingStoryView()),
    );

    return Material(
      type: MaterialType.transparency,
      child: NocheSheetSwap(
        contentKey: _writing ? 'writing' : 'form',
        alignment: AlignmentDirectional.topStart,
        child: _writing ? writingBody : formBody,
      ),
    );
  }
}

class _WriteStorySubmitButton extends StatelessWidget {
  const _WriteStorySubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bg = enabled ? NocheColors.text : NocheColors.line;
    final fg = enabled ? NocheColors.ground : NocheColors.label;
    final style = NocheType.primarySmall.copyWith(color: fg);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
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

class _WritingStoryView extends StatefulWidget {
  const _WritingStoryView();

  @override
  State<_WritingStoryView> createState() => _WritingStoryViewState();
}

class _WritingStoryViewState extends State<_WritingStoryView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: NocheMotion.thinkingCycle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loops = NocheMotion.of(context).loops;
    if (loops) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotOpacity(int index, bool loops) {
    if (!loops) return 1.0;
    final phase = (_controller.value - index / 6.0) % 1.0;
    final wave = 0.5 - 0.5 * math.cos(2 * math.pi * phase);
    return (0.35 + 0.65 * wave).clamp(0.35, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final loops = NocheMotion.of(context).loops;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Opacity(
                      key: ValueKey<String>('library-writing-dot-$i'),
                      opacity: _dotOpacity(i, loops),
                      child: const SizedBox(
                        width: 12,
                        height: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: NocheColors.other,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          NocheLtr(
            child: Text(
              LibraryWording.writingStoryTitle,
              style: NocheType.sheetTitle.copyWith(color: NocheColors.text),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          NocheLtr(
            child: Text(
              LibraryWording.writingStorySubtitle,
              style: NocheType.body.copyWith(color: NocheColors.label),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
