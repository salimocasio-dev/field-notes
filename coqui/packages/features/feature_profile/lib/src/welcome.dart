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
/// The sheet of step [step] (0 to 2) of the welcome, as `bienvenida(k)` builds it.
///
/// The first time it is a modal sheet: no header, a tap outside does nothing, and it can only be finished
/// (`modal:!AJ().bienvenida`). Opened again from Yo it is an ordinary sheet: the handle and the X, and
/// step 1 ends with the level check's paragraph.
///
/// [onStep] is `bienvenida(n)`; [onNew] is `listo()`; [onClose] is `cierra()` (the X and the drag).
CoquiSheet welcomeSheet({
  required Services services,
  required int step,
  required ValueChanged<int> onStep,
  required VoidCallback onNew,
  VoidCallback? onClose,
}) {
  final progress = services.progress;
  final seen = jsTruthy(progress.setting('bienvenida')); // AJ().bienvenida
  final footer = _footer(services, step, onStep, onNew);
  return CoquiSheet(
    key: ValueKey('welcome-step-$step'),
    modal: !seen,
    onClose: onClose,
    footer: footer,
    child: switch (step) {
      0 => _stepOne(seen),
      1 => _stepTwo(progress),
      _ => _stepThree(),
    },
  );
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
        },
      ),
    ],
  );
}
