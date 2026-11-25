/// "Add a word or goal" sheet body, styled with Noche tokens (story N4.4).
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// The add box: example line, input field, primary Add button, and the saved
/// list with its honest line once something is saved.
class AddBox extends StatelessWidget {
  const AddBox({
    super.key,
    required this.controller,
    required this.added,
    required this.onAdd,
  });

  final TextEditingController controller;

  /// `db().extra`, in the order saved.
  final List<String> added;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final text = NocheType.body.copyWith(
      color: NocheColors.text,
      textBaseline: TextBaseline.alphabetic,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(NocheSize.tileRadius),
      borderSide: const BorderSide(color: NocheColors.bar, width: 1),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(NocheSize.tileRadius),
      borderSide: const BorderSide(color: NocheColors.text, width: 1.5),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 16),
          child: Text(
            'For example: "talk to my 1-year-old around the house".',
            style: NocheType.bodySmall.copyWith(color: NocheColors.label),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: NocheSize.touch),
          child: Material(
            type: MaterialType.transparency,
            child: TextField(
              controller: controller,
              style: text,
              cursorColor: NocheColors.next,
              onSubmitted: (_) => onAdd(),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'A word or a goal',
                hintStyle: text.copyWith(color: NocheColors.label),
                filled: true,
                fillColor: NocheColors.ground,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: border,
                enabledBorder: border,
                focusedBorder: focusedBorder,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        NochePrimaryButton(label: 'Add', onPressed: onAdd),
        if (added.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 16, bottom: 8),
            child: Text(
              'Saved. Material for it comes later.',
              style: NocheType.bodySmall.copyWith(color: NocheColors.label),
            ),
          ),
          for (final x in added)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 4),
              child: Text(
                '· $x',
                style: NocheType.body.copyWith(color: NocheColors.text),
              ),
            ),
        ],
      ],
    );
  }
}

/// Stateful wrapper for [AddBox] inside [showNocheSheet] so newly saved items
/// appear immediately as the store updates.
class AddBoxSheetBody extends StatefulWidget {
  const AddBoxSheetBody({
    super.key,
    required this.progress,
    required this.haptics,
  });

  final ProgressStore progress;
  final Haptics haptics;

  @override
  State<AddBoxSheetBody> createState() => _AddBoxSheetBodyState();
}

class _AddBoxSheetBodyState extends State<AddBoxSheetBody> {
  final _field = TextEditingController();
  StreamSubscription<void>? _changes;
  late List<String> _added = widget.progress.added;

  @override
  void initState() {
    super.initState();
    _changes = widget.progress.changes.listen((_) {
      if (mounted) setState(() => _added = widget.progress.added);
    });
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    _field.dispose();
    super.dispose();
  }

  void _add() {
    final v = _field.text.trim();
    if (v.isEmpty) return;
    widget.haptics.tick();
    _field.clear();
    widget.progress.add(v);
    if (mounted) setState(() => _added = widget.progress.added);
  }

  @override
  Widget build(BuildContext context) =>
      AddBox(controller: _field, added: _added, onAdd: _add);
}
