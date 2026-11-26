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

/// The selected minute value matching [minutePills], or `-1` when none matches.
int _selectedMinuteValue(Object? min) {
  final idx = minutePillIndex(min);
  return idx >= 0 ? minutePills[idx] : -1;
}

/// Step progress dots for the Noche welcome sheet.
///
/// Uses `NocheColors.text` for the active step and `NocheColors.line` for the
/// rest so `NocheColors.next` stays reserved for the single primary button on
/// the screen (page 22, Part 1.4).
class WelcomePageDots extends StatelessWidget {
  const WelcomePageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: NocheSize.grid),
            Container(
              width: i == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? NocheColors.text : NocheColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// app.html: bienvenida(k)
/// The Noche sheet of step [step] (0 to 2) of the welcome, as `bienvenida(k)`
/// builds it, in place, for the gate ([NocheSheetOverlay]): the first time it
/// is modal (no close button, a tap outside does nothing, and it can only be
/// finished: `modal:!AJ().bienvenida`).
///
/// [onStep] is `bienvenida(n)`; [onNew] is `listo()`. "I understand some
/// Spanish" writes the setting and goes to the level check: the gate closes
/// when the setting is written.
NocheSheet welcomeSheet({
  required Services services,
  required int step,
  required ValueChanged<int> onStep,
  required VoidCallback onNew,
}) {
  final progress = services.progress;
  final seen = jsTruthy(progress.setting('bienvenida')); // AJ().bienvenida
  return NocheSheet(
    key: ValueKey('welcome-step-$step'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (step) {
          0 => _stepOne(seen),
          1 => _stepTwo(progress),
          _ => _stepThree(),
        },
        const SizedBox(height: 16),
        _footer(services, step, onStep, onNew, null),
      ],
    ),
  );
}

/// The welcome's body for `showNocheSheet`: "How it works" over Me, where the
/// welcome is opened again as a dismissible sheet and step 1 ends with the
/// level check's paragraph.
///
/// The step is driven by [step] so the body starts at the top of its page for
/// each step and redraws whenever the store saves (the minutes pill just
/// touched highlights immediately). [onNew] is `listo()`; [onLeave] closes the
/// sheet after navigating to the level check.
Widget welcomeRouteBody({
  required Services services,
  required ValueNotifier<int> step,
  required VoidCallback onNew,
  required VoidCallback onLeave,
}) => _WelcomeRouteBody(
  key: const ValueKey('welcome'),
  services: services,
  step: step,
  onNew: onNew,
  onLeave: onLeave,
);

class _WelcomeRouteBody extends StatefulWidget {
  const _WelcomeRouteBody({
    super.key,
    required this.services,
    required this.step,
    required this.onNew,
    required this.onLeave,
  });

  final Services services;
  final ValueNotifier<int> step;
  final VoidCallback onNew;
  final VoidCallback onLeave;

  @override
  State<_WelcomeRouteBody> createState() => _WelcomeRouteBodyState();
}

class _WelcomeRouteBodyState extends State<_WelcomeRouteBody> {
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
  Widget build(BuildContext context) {
    final seen = jsTruthy(_progress.setting('bienvenida'));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (_k) {
          0 => _stepOne(seen),
          1 => _stepTwo(_progress),
          _ => _stepThree(),
        },
        const SizedBox(height: 16),
        _footer(
          widget.services,
          _k,
          (n) => widget.step.value = n,
          widget.onNew,
          widget.onLeave,
        ),
      ],
    );
  }
}

Widget _title(String text) => Padding(
  padding: const EdgeInsetsDirectional.only(bottom: 16),
  child: Text(
    text,
    style: NocheType.pageTitle.copyWith(color: NocheColors.text),
  ),
);

Widget _p(String text) => Padding(
  padding: const EdgeInsetsDirectional.only(bottom: 16),
  child: Text(
    text,
    style: NocheType.bodyLarge.copyWith(color: NocheColors.text),
  ),
);

Widget _muted(String text) => Padding(
  padding: const EdgeInsetsDirectional.only(bottom: 16),
  child: Text(text, style: NocheType.body.copyWith(color: NocheColors.label)),
);

Widget _stepOne(bool seen) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    _title(welcomeTitle),
    _p(welcomeP1),
    _p(welcomeP2),
    _p(welcomeP3),
    _muted(welcomeP4),
    // opened again from Me ("How it works"), not the first-time welcome
    if (seen) ...[
      Padding(
        padding: const EdgeInsetsDirectional.only(
          top: NocheSize.grid,
          bottom: NocheSize.grid,
        ),
        child: Text(
          welcomeLevelCheck,
          style: NocheType.sheetTitle.copyWith(color: NocheColors.text),
        ),
      ),
      _p(levelCheckText),
    ],
  ],
);

Widget _stepTwo(ProgressStore progress) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    _title(welcomeTimeTitle),
    _muted(welcomeTimeHelp),
    NocheSegmented<int>(
      key: const Key('welcome-minutes-segmented'),
      semanticLabel: welcomeTimeTitle,
      role: NocheSegmentedRole.radioGroup,
      options: [
        for (final m in minutePills)
          NocheSegmentOption<int>(value: m, label: '$m min'),
      ],
      selected: _selectedMinuteValue(progress.setting('min')),
      // AJ().min=m; PAL.save(); bienvenida(1)   (no tick here)
      onChanged: (m) => progress.setSetting('min', m),
    ),
  ],
);

Widget _stepThree() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [_title(welcomeStartTitle), _muted(welcomeStartHelp)],
);

Widget _footer(
  Services services,
  int step,
  ValueChanged<int> onStep,
  VoidCallback onNew,
  VoidCallback? onLeave,
) {
  final dots = WelcomePageDots(count: welcomeSteps, index: step);
  if (step < 2) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        dots,
        NochePrimaryButton(
          key: const Key('welcome-next-button'),
          label: welcomeNext,
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
      NochePrimaryButton(
        key: const Key('welcome-new-button'),
        label: welcomeNew,
        onPressed: onNew,
      ),
      const SizedBox(height: 16),
      NocheOutlineButton(
        key: const Key('welcome-some-button'),
        label: welcomeSome,
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
