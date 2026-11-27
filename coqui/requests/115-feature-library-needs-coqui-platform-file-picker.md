# Request: Native and web file picker contract + implementation in `coqui_contracts` + `coqui_platform`

## What I need

1. A file-picker contract in `coqui_contracts` (e.g. `ImportFilePicker` / `PickedImportFile` returning `{name, bytes}` for a learner-chosen file with `allowedExtensions`, or `null` on cancel), exposed on `Services` (or via an optional capability interface).
2. Platform implementations in `coqui_platform`:
   - Web: HTML `<input type="file" accept=".txt">` using `package:web` (already in the allowed third-party list for `coqui_platform`).
   - Mobile (iOS/Android): native document picker (or an approved third-party plugin added to the orchestrator's allowlist in `coqui/AGENTS.md` and `tool/check_boundaries.dart`).
3. A fake implementation in `coqui_testing` and wiring in `app` so `LibraryModule.screenFor(ImportRoute(), s)` can pass the platform file picker to `ImportScreen`.

## Why

Story N5.4 ("Add your own: the screen, paste text and plain text files", issue #115, board `docs/proyecto/noche/Noche-Importar.dc.html`) needs the primary `"Choose a file"` button to open the OS/browser file picker for `.txt` files. Feature packages (`feature_library`) may not import `package:web`, `dart:html`, or platform plugins, and `lane/feature_library/115` may not edit `coqui_contracts`, `coqui_platform`, `coqui_testing`, or `app`.

## What I am using meanwhile

- `coqui/packages/features/feature_library/lib/src/book_importer.dart` defines local `PickedImportFile` and `abstract interface class ImportFilePicker`.
- `ImportScreen` accepts an optional `ImportFilePicker? filePicker` parameter (used by tests with a fake picker). When `filePicker` is `null` in the current shell build, tapping `"Choose a file"` shows a calm error card (`LibraryWording.errorPickerUnavailable`) directing the learner to `"Paste text"` meanwhile.

## Order and branch

- Order: #115 (N5.4 Add your own: the screen, paste text and plain text files)
- Branch: `lane/feature_library/115`
