/// "Find a word" (order 27): a field over the words; what he types keeps the cards whose word holds it.
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/add_box.dart';
import 'package:material_ui/material_ui.dart';

/// The field, in the look of "Add a word or a goal" ([fieldDecoration]); once it holds text, a 48 px button at its
/// right end empties it.
class FindBox extends StatelessWidget {
  const FindBox({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, v, _) => TextField(
          controller: controller,
          style: fieldText,
          cursorColor: CoquiColors.ink,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          decoration: fieldDecoration(context, 'Find a word').copyWith(
            suffixIcon: v.text.isEmpty
                ? null
                : Semantics(
                    button: true,
                    label: 'Clear',
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: controller.clear,
                      child: const SizedBox.square(
                        dimension: CoquiMetrics.targetMin,
                        child: Center(
                          child: CoquiIcon(
                            CoquiIcons.close,
                            size: 20,
                            color: CoquiColors.mut,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      );
}

/// A magnifying glass (24 x 24, stroked as the app's other icons).
final CoquiIconData searchIcon = CoquiIconData([
  const IconShape('M11 4a7 7 0 1 0 0 14a7 7 0 1 0 0-14z'),
  const IconShape('M16.5 16.5 20 20'),
]);

/// The 48 px square button beside the pills that opens and closes "Find a word": a ring like an unchosen pill, blue
/// when the field is open.
class FindButton extends StatelessWidget {
  const FindButton({super.key, required this.on, required this.onPressed});
  final bool on;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: on,
    label: 'Find a word',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        width: CoquiMetrics.targetMin,
        height: CoquiMetrics.targetMin,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? CoquiColors.info : null,
          borderRadius: BorderRadius.circular(CoquiMetrics.radiusButton),
          border: Border.all(
            color: on ? CoquiColors.info : CoquiColors.line2,
            width: CoquiLayout.border(context, CoquiMetrics.borderButton),
          ),
        ),
        child: CoquiIcon(
          searchIcon,
          color: on ? CoquiColors.white : CoquiColors.ink,
        ),
      ),
    ),
  );
}
