---
trigger: glob
globs:
  - "coqui/packages/**"
description: "Coqui Flutter package boundaries and Noche UI rules"
---

# Coqui Package & Noche Guardrails

- Change files in **one package only** per branch. If a contract or shared widget is missing, write a request in `coqui/requests/` instead of editing `coqui_contracts` or `coqui_ui` from a feature branch.
- **No raw styles outside `coqui_ui`:** Never add `Color(0x...)` or `fontFamily` outside `coqui_ui`. Use `NocheColors`, `NocheType`, and `NocheSize`.
- **Directional layout only in new/edited UI:** Use `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `start`, and `end` (never `left`/`right`). Pixel scenes (`PixelView`) never mirror.
- **No red, ever.** Misses use a white outline and replay the line.
- **One orange action per screen** (`NocheColors.next`), plus the Map disc in the tab bar.
- **No hardcoded Spanish strings in Dart code** (course words, mic words, and tab names come from course/language data).
- **Minimum touch target:** 48x48 dp.
- Before opening a PR, run `dart run tool/check_boundaries.dart`, `dart format`, `flutter analyze`, and the touched package's tests locally.
