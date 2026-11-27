# Request: Text-filled variant on NochePrimaryButton

## What I need

In `coqui/packages/core/coqui_ui/lib/src/noche_controls.dart`:

Add a text-filled variant on `NochePrimaryButton` (e.g., `NochePrimaryButton.text(...)` or an inverted/text-fill style parameter) using `NocheColors.text` fill with `NocheColors.ground` label when enabled, and `NocheColors.line` fill with `NocheColors.label` text when disabled, at `NocheSize.primaryHeight` (56) and `NocheSize.primaryRadius` (28) with `NocheType.primarySmall`.

## Why

Order #230 (`N8.12 Library: writing a story`, `docs/proyecto/noche/Noche-Motion-Escribir.dc.html`) specifies a `#EEF3F7` (`NocheColors.text`) filled primary action button with `#0C1926` (`NocheColors.ground`) text for the "Write my story" submit action inside the bottom sheet, rather than the orange `NocheColors.next` fill.

## What I am using meanwhile

A local `_WriteStorySubmitButton` widget in `coqui/packages/features/feature_library/lib/src/write_story_sheet.dart` built with `Pressable`, `NocheSize.primaryHeight`, `NocheSize.primaryRadius`, `NocheType.primarySmall`, and `NocheColors.text` / `NocheColors.ground` (disabled `NocheColors.line` / `NocheColors.label`).

## Order and branch

- Order: 230 (`lane:feature_library`)
- Branch: `lane/feature_library/230`
