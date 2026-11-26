import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/texts.dart';
import 'package:material_ui/material_ui.dart';

/// Where this feature remembers that the install hint has been shown (its own storage space, `yo`).
const String installHintSpace = 'yo';
const String installHintKey = 'installHintShown';

/// The card's directional padding: 16 at start, 8 on top/end/bottom where the 48 px close button sits.
const EdgeInsetsDirectional installHintPadding = EdgeInsetsDirectional.fromSTEB(
  16,
  8,
  8,
  8,
);

/// On an iPhone in the browser, not installed, a one-time Noche card at the top
/// of Me says how to install, with a 48 by 48 dismiss button.
class InstallHint extends StatelessWidget {
  const InstallHint({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          installHint,
          style: NocheType.body.copyWith(color: NocheColors.text),
        ),
      ),
      Pressable(
        key: const Key('install-hint-close'),
        onPressed: onDismiss,
        semanticLabel: NocheA11y.label(NocheA11y.close),
        builder: (context, pressed) => Transform.scale(
          scale: pressed ? 0.94 : 1,
          child: const SizedBox(
            width: NocheSize.touch,
            height: NocheSize.touch,
            child: Center(
              child: NocheIcon(
                NocheIcons.close,
                size: 20,
                color: NocheColors.text,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
