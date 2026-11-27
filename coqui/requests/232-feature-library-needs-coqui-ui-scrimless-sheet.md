# Request: Scrimless and headerless option on showNocheSheet

## What I need

In `coqui/packages/core/coqui_ui/lib/src/noche_chrome.dart`:

Support an optional scrimless mode (e.g., `bool scrim = true`) and headerless drag-to-dismiss mode (e.g., `bool showCloseButton = true`, keeping drag-to-dismiss enabled when `title == null && !showCloseButton`) on `showNocheSheet<T>`, where `scrim: false` omits `NocheColors.scrim` (`barrierColor => null`), renders a transparent tap-to-close region above the sheet carrying `closeLabel`, and keeps the same `pageIn` (`enter`) / `pageOut` (`exit`) slide (and `quick` reduced-motion fade) on `NocheSheet`.

## Why

Order #232 (`N8.14 Reader: text and page`, `docs/proyecto/noche/Noche-Motion-Lector.dc.html`, `docs/proyecto/noche/Noche-Lector-Aa.dc.html`) requires the Text and page sheet to open with NO scrim so the learner can watch the book page's text size, font, line spacing, colour palette, underlines, and lit sentence update live behind it, with only the 40×4 drag handle (no title bar / close `X` button) and tap-above or drag-down dismissal.

## What I am using meanwhile

A package-local `showReaderSettingsSheet<T>` and `_ReaderSettingsSheetRoute<T> extends PopupRoute<T>` with `_DraggableSheetDismiss` in `coqui/packages/features/feature_library/lib/src/reader_settings_sheet.dart`, wrapping `NocheSheet(child: ...)` with `barrierColor => null` and an `Expanded` transparent `Semantics(button: true, label: closeLabel)` closer above the sheet.

## Order and branch

- Order: #232 (`N8.14 Reader: text and page`, `lane:feature_library`)
- Branch: `lane/feature_library/232`
