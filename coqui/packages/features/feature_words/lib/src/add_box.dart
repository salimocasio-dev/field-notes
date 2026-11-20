/// "Add a word or a goal" (app.html: the card at the foot of `palabras`, and `extra`).
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// The card: the example, the field, the green Add button and, once something is saved, the honest line and the
/// saved list. [onAdd] is the Add button; the field is [controller]'s.
class AddBox extends StatelessWidget {
  const AddBox({
    super.key,
    required this.controller,
    required this.added,
    required this.onAdd,
  });

  final TextEditingController controller;

  /// `db().extra`, in the order he saved them.
  final List<String> added;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return CoquiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `<p class="small mut" style="margin-top:0">`: 14 px under it, the paragraph's own `1em`
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'For example: "talk to my 1-year-old around the house".',
              style: CoquiText.smallMuted,
            ),
          ),
          TextField(
            controller: controller,
            style: fieldText,
            cursorColor: CoquiColors.ink,
            decoration: fieldDecoration(context, 'A word or a goal'),
          ),
          const SizedBox(height: CoquiMetrics.s16),
          CoquiButton(label: 'Add', kind: CoquiButtonKind.go, onPressed: onAdd),
          if (added.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: CoquiMetrics.s16,
                bottom: CoquiMetrics.s8,
              ),
              child: Text(
                'Saved. Material for it comes later.',
                style: CoquiText.smallMuted,
              ),
            ),
            for (final x in added)
              Padding(
                padding: const EdgeInsets.only(bottom: CoquiMetrics.s4),
                child: Text('· $x', style: CoquiText.small),
              ),
          ],
        ],
      ),
    );
  }
}

/// The text of a field: the body style, with the baseline a TextField wants on a style that inherits nothing.
final TextStyle fieldText = CoquiText.body.copyWith(
  textBaseline: TextBaseline.alphabetic,
);

/// The look of v=39's `input`: 48 px, white, a `--line2` ring, 12 px corners, the browser's grey placeholder.
InputDecoration fieldDecoration(BuildContext context, String hint) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(CoquiMetrics.radiusButton),
    borderSide: BorderSide(
      color: CoquiColors.line2,
      width: CoquiLayout.border(context, CoquiMetrics.borderButton),
    ),
  );
  return InputDecoration(
    isDense: true,
    hintText: hint,
    // `input` placeholder: the browser's own grey
    hintStyle: fieldText.copyWith(color: const Color(0xFF757575)),
    filled: true,
    fillColor: CoquiColors.white,
    // Material greys a hovered or focused field: the old input stays white
    hoverColor: const Color(0x00000000),
    focusColor: const Color(0x00000000),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: CoquiMetrics.s12,
      vertical: CoquiMetrics.s12,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: border,
  );
}
