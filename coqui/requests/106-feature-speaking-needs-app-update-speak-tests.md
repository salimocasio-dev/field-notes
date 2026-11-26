# Request: Update two coqui/app tests for N4.6 Noche HablarTab (Speak)

## What I need

Update two tests in `coqui/app/test/` that still expect the pre-N4.6 Hablar hero button text (`Start call`) on the Speak tab:

1. `coqui/app/test/tabs_test.dart`, test `(b)` (lines 70–79):
   - Currently asserts `find.text('Start call').hitTestable()` and after tapping `El parque` asserts `find.text('Opens when you finish El parque').hitTestable()`.
   - Update to support N4.6's Noche `HablarTab` alongside pre-N4.6 `main`:
     - On N4.6 (`find.byKey(const Key('speak-call-disc')).evaluate().isNotEmpty`): assert `find.text('Speak').hitTestable()`, `find.text('De visita en la casa').hitTestable()`, `find.text('Call Danny').hitTestable()`, and `find.byKey(const Key('speak-call-disc')).hitTestable()`; after tapping `find.text('El parque')`, assert `find.text('Opens when you finish El parque').hitTestable()` or `find.textContaining('after story').hitTestable()` (note: in `curso` seed, 4 of 12 stories of `El parque` are played, so `¿De qué color es?` shows `Coming soon · El parque` while `Mira el perro` shows `2 min · after story 8` and `El perro en el parque` shows `5 min · after story 12`).
     - On pre-N4.6 `main`: keep the existing assertions (`find.text('Start call')`, `find.text('Opens when you finish El parque')`).
2. `coqui/app/test/lessons_test.dart`, test `(i)` (lines 486–521):
   - Currently taps `find.text('Start call')` on the Speak tab to open `CallScreen`.
   - Update to tap `find.byKey(const Key('speak-call-disc'))` when present (falling back to `find.text('Start call')` on pre-N4.6 `main`).

## Why

Story N4.6 ("Speak", issue #106, board `Noche-Hablar.dc.html`) replaces the pre-N4.6 `"Start call"` `CoquiButton` on `HablarTab` with the Noche Speak screen (`Speak` header, place pills tablist, next-call card with open-word chips, 2-per-row other-calls cards, and `"Call <partner>"` + the 96 px orange `NochePlayDisc` keyed `Key('speak-call-disc')` above the floating tab bar). Editing `coqui/app/test/` from `lane/feature_speaking/106` is disallowed by `check_boundaries.dart`.

## What I am using meanwhile

All 155 `feature_speaking` unit, widget, static, Arabic/RTL, and N4.6 Speak tests pass inside `coqui/packages/features/feature_speaking/`, and all 7 other tests in `coqui/app/test/tabs_test.dart` and `coqui/app/test/lessons_test.dart` pass.

## Order and branch

- Order: 106 (N4.6 Speak)
- Branch: `lane/feature_speaking/106`
