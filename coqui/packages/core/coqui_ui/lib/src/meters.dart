/// The Ear and Mouth meters: four dots, filled to the stage (app.html:93-94, 417).
library;

import 'package:coqui_ui/src/layout.dart';
import 'package:coqui_ui/src/text_styles.dart';
import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// `.dts`: four 10 px dots, 4 px apart. [value] of them are filled green
/// (stage 1 to 4); the others keep a 1.5 px `#8A8F99` outline (a 3:1 contrast on
/// white). app.html:94
class MeterDots extends StatelessWidget {
  const MeterDots({super.key, required this.value, this.count = 4});

  /// The stage, 0 to [count]; anything outside is clamped.
  final int value;
  final int count;

  @override
  Widget build(BuildContext context) {
    final n = value.clamp(0, count);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= count; i++) ...[
          if (i > 1) const SizedBox(width: CoquiMetrics.dotGap),
          Container(
            key: ValueKey('dot$i${i <= n ? 'on' : 'off'}'),
            width: CoquiMetrics.dotSize,
            height: CoquiMetrics.dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= n ? CoquiColors.ok : null,
              border: Border.all(
                color: i <= n ? CoquiColors.ok : CoquiColors.dotOutline,
                width: CoquiLayout.border(context, CoquiMetrics.dotBorder),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// `.mt`: a label (12/16 medium, secondary, 44 px wide) and its four dots, 8 px
/// apart, at least 20 px high. Says "Ear: 3 of 4" to a screen reader. app.html:93, 417
class SkillMeter extends StatelessWidget {
  const SkillMeter({super.key, required this.label, required this.value});

  /// `Ear` or `Mouth` (see [EarMouthMeters]).
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: ${value.clamp(0, 4)} of 4',
    image: true,
    excludeSemantics: true,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: CoquiMetrics.meterLabelWidth,
            child: Text(
              label,
              style: CoquiText.meterLabel,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
          const SizedBox(width: CoquiMetrics.s8),
          MeterDots(value: value),
        ],
      ),
    ),
  );
}

/// The two meters of a word: Ear then Mouth, 4 px apart (the word card: left
/// aligned; the word sheet's `.wsm`: centred). The labels "Ear" and "Mouth" are
/// the strings v=39 hard-codes (app.html:426, 443). app.html:93, 95
class EarMouthMeters extends StatelessWidget {
  const EarMouthMeters({
    super.key,
    required this.ear,
    required this.mouth,
    this.centered = false,
  });

  /// Stage 1 to 4 of the ear (0: not yet heard).
  final int ear;
  final int mouth;

  /// `.wsm`: centred, 4 px apart (the word sheet).
  final bool centered;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      SkillMeter(label: 'Ear', value: ear),
      if (centered) const SizedBox(height: CoquiMetrics.s4),
      SkillMeter(label: 'Mouth', value: mouth),
    ],
  );
}
