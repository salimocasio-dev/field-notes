import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/texts.dart';
import 'package:material_ui/material_ui.dart';

/// Where this feature remembers that the install hint has been shown (its own storage space, `yo`).
const String installHintSpace = 'yo';
const String installHintKey = 'installHintShown';

/// The card's padding: the usual 16, less 8 where the X (a 48 px target) sits.
const EdgeInsets installHintPadding = EdgeInsets.fromLTRB(
  CoquiMetrics.s16,
  CoquiMetrics.s8,
  CoquiMetrics.s8,
  CoquiMetrics.s8,
);

/// New in order 25: on an iPhone in the browser, not installed, a small card at the top of Yo says how to
/// install. This is what goes inside the card: the line, and the X to dismiss it.
class InstallHint extends StatelessWidget {
  const InstallHint({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(installHint, style: CoquiText.small)),
      CoquiCloseButton(onPressed: onDismiss),
    ],
  );
}
