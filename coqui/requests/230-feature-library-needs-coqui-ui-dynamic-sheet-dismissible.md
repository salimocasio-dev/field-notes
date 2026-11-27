# Request: Dynamic dismissible control on showNocheSheet

## What I need

In `coqui/packages/core/coqui_ui/lib/src/noche_chrome.dart`:

Support dynamic dismissibility on `showNocheSheet<T>` (e.g., accepting a `ValueListenable<bool>? dismissibleListenable` or passing a `setDismissible(bool)` callback to the sheet builder) so a bottom sheet can lock itself against scrim taps, drag-down gestures, and system back (`PopScope`) while an in-place async operation is running, and unlock if it fails and swaps back to the form.

## Why

Order #230 (`N8.12 Library: writing a story`, `docs/proyecto/noche/Noche-Motion-Escribir.dc.html`) requires the "Write my story" sheet to become non-dismissible while writing (`scrim`, drag down, and back do nothing until writing finishes or fails and swaps back to the form), while keeping `NocheSheet`'s body locked at the exact form height without header toggles.

## What I am using meanwhile

A local `_WriteStorySheetRoute<T> extends PopupRoute<T>` in `coqui/packages/features/feature_library/lib/src/write_story_sheet.dart` that mirrors `_NocheSheetRoute<T>`'s scrim and sheet transitions while owning a `ValueNotifier<bool> _dismissible` (disposed in `PopupRoute.dispose()`) and gating `AnimatedModalBarrier`, drag-to-dismiss, and `PopScope`.

## Order and branch

- Order: 230 (`lane:feature_library`)
- Branch: `lane/feature_library/230`
