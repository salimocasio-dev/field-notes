import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/js.dart';
import 'package:feature_profile/src/texts.dart';
import 'package:material_ui/material_ui.dart';

/// The minutes the pills offer (app.html: `[15,30,60,120]`).
const List<int> minutePills = [15, 30, 60, 120];

/// The number of steps of the welcome.
const int welcomeSteps = 3;

/// The pill of [minutes] that is on: `AJ().min===m`.
int minutePillIndex(Object? min) {
  for (var i = 0; i < minutePills.length; i++) {
    if (min is num && min == minutePills[i]) return i;
  }
  return -1;
}

// app.html: bienvenida(k)
/// The sheet of step [step] (0 to 2) of the welcome, as `bienvenida(k)` builds it, in place, for the gate
/// (`CoquiSheetLayer`): the first time it is a modal sheet: no header, a tap outside does nothing, and it can only
/// be finished (`modal:!AJ().bienvenida`).
///
/// [onStep] is `bienvenida(n)`; [onNew] is `listo()`. "I understand some Spanish" writes the setting and goes
/// to the level check: the old page is left there, a page that is loaded again has no sheet; here the gate closes
/// when the setting is written.
CoquiSheet welcomeSheet({
  required Services services,
  required int step,
  required ValueChanged<int> onStep,
  required VoidCallback onNew,
}) {
  final progress = services.progress;
  final seen = jsTruthy(progress.setting('bienvenida')); // AJ().bienvenida
  final footer = _footer(services, step, onStep, onNew, null);
  return CoquiSheet(
    key: ValueKey('welcome-step-$step'),
    modal: !seen,
    footer: footer,
    child: switch (step) {
      0 => _stepOne(seen),
      1 => _stepTwo(progress),
      _ => _stepThree(),
    },
  );
}

/// The welcome's sheet for `showCoquiSheet`: "How it works" over Yo, where the welcome is opened again. An
/// ordinary sheet (the handle and the X; the route sets `onClose` and `modal`) and step 1 ends with the level
/// check's paragraph.
///
/// The route builds the sheet once, so the step is a [step] notifier that the body and the footer follow, as
/// `bienvenida(k)` writes the sheet again: the body starts at the top of its page for each step, and it
/// draws again whenever the store saves (the minutes pill that was just touched is the one that is on). [onNew]
/// is `listo()`; [onLeave] is called once "I understand some Spanish" has written the setting and gone to the
/// level check (the old page is left there): the sheet is closed.
CoquiSheet welcomeRouteSheet({
  required Services services,
  required ValueNotifier<int> step,
  required VoidCallback onNew,
  required VoidCallback onLeave,
}) => CoquiSheet(
  key: const ValueKey('welcome'),
  footer: ValueListenableBuilder<int>(
    valueListenable: step,
    builder: (context, k, _) =>
        _footer(services, k, (n) => step.value = n, onNew, onLeave),
  ),
  child: _StepBody(services: services, step: step),
);

/// The body of the welcome's sheet: the page of the step [step] holds, from the top, drawn again when the store
/// saves.
class _StepBody extends StatefulWidget {
  const _StepBody({required this.services, required this.step});

  final Services services;
  final ValueNotifier<int> step;

  @override
  State<_StepBody> createState() => _StepBodyState();
}

class _StepBodyState extends State<_StepBody> {
  late int _k = widget.step.value;
  StreamSubscription<void>? _changes;

  ProgressStore get _progress => widget.services.progress;

  @override
  void initState() {
    super.initState();
    widget.step.addListener(_onStep);
    _changes = _progress.changes.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.step.removeListener(_onStep);
    _changes?.cancel();
    super.dispose();
  }

  void _onStep() {
    if (widget.step.value == _k) return;
    setState(() => _k = widget.step.value);
    // `sh.innerHTML=...`: the new step's page is new, at its top
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final position = Scrollable.maybeOf(context)?.position;
      if (position != null && position.hasPixels && position.pixels != 0) {
        position.jumpTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) => switch (_k) {
    0 => _stepOne(jsTruthy(_progress.setting('bienvenida'))),
    1 => _stepTwo(_progress),
    _ => _stepThree(),
  };
}

// `h1` with `style="margin-top:0"`
Widget _title(String text) => Block(
  bottom: CoquiMetrics.s16,
  child: Text(text, style: CoquiText.h1),
);

// `<p>`: 1em above and below, 16 px; `<p class="small mut">`: 1em of 14 px
Widget _p(String text) => Block(
  top: CoquiMetrics.s16,
  bottom: CoquiMetrics.s16,
  child: Text(text, style: CoquiText.body),
);

Widget _stepOne(bool seen) => CollapsingColumn(
  children: [
    _title(welcomeTitle),
    _p(welcomeP1),
    _p(welcomeP2),
    _p(welcomeP3),
    Block(
      top: 14,
      bottom: 14,
      child: Text(welcomeP4, style: CoquiText.smallMuted),
    ),
    // opened again from Yo ("How it works"), not the first-time welcome
    if (seen) ...[
      const SectionTitle(welcomeLevelCheck),
      Block(child: Text(levelCheckText, style: CoquiText.body)),
    ],
  ],
);

Widget _stepTwo(ProgressStore progress) => CollapsingColumn(
  children: [
    _title(welcomeTimeTitle),
    Block(
      top: CoquiMetrics.s16,
      bottom: CoquiMetrics.s16,
      child: Text(welcomeTimeHelp, style: CoquiText.bodyMuted),
    ),
    SegmentedPills(
      labels: [for (final m in minutePills) '$m min'],
      selected: minutePillIndex(progress.setting('min')),
      // AJ().min=m; PAL.save(); bienvenida(1)   (no tick here)
      onSelected: (i) => progress.setSetting('min', minutePills[i]),
    ),
  ],
);

Widget _stepThree() => CollapsingColumn(
  children: [
    _title(welcomeStartTitle),
    Block(
      top: 14,
      bottom: 14,
      child: Text(welcomeStartHelp, style: CoquiText.smallMuted),
    ),
  ],
);

Widget _footer(
  Services services,
  int step,
  ValueChanged<int> onStep,
  VoidCallback onNew,
  VoidCallback? onLeave,
) {
  final dots = PageDots(count: welcomeSteps, index: step);
  if (step < 2) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        dots,
        CoquiButton(
          label: welcomeNext,
          full: true,
          onPressed: () => onStep(step + 1),
        ),
      ],
    );
  }
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      dots,
      CoquiButton(label: welcomeNew, full: true, onPressed: onNew),
      const SizedBox(height: CoquiMetrics.s16),
      CoquiButton(
        label: welcomeSome,
        full: true,
        kind: CoquiButtonKind.outline,
        // AJ().bienvenida=1; PAL.save(); location.href='nivel.html'
        onPressed: () {
          services.progress.setSetting('bienvenida', 1);
          services.nav.go(const LevelCheckRoute());
          onLeave?.call();
        },
      ),
    ],
  );
}
