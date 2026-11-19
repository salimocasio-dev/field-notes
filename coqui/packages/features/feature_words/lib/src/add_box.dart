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

  /// `input` placeholder: the browser's own grey.
  static const _placeholder = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    // a TextField wants a baseline on a style that inherits nothing
    final text = CoquiText.body.copyWith(textBaseline: TextBaseline.alphabetic);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(CoquiMetrics.radiusButton),
      borderSide: const BorderSide(
        color: CoquiColors.line2,
        width: CoquiMetrics.borderButton,
      ),
    );
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
            style: text,
            cursorColor: CoquiColors.ink,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'A word or a goal',
              hintStyle: text.copyWith(color: _placeholder),
              filled: true,
              fillColor: CoquiColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: CoquiMetrics.s12,
                vertical: CoquiMetrics.s12,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border,
            ),
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
