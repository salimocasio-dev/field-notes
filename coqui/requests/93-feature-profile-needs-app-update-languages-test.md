# Request: Update coqui/app/test/noche_shell_test.dart for N2.10 LanguagesRoute

## What I need

Update `coqui/app/test/noche_shell_test.dart`, test `'unanswered LanguagesRoute, PlansRoute, ImportRoute, and unknown PlaceRoute do nothing and log a line without crashing'` (lines 259–316):

1. Remove `LanguagesRoute()` from the unanswered `AppRoute` list (line 274) and `'/idiomas'` from the unanswered location list (line 289).
2. Add an assertion alongside the existing `/lugar/casa` check (lines 304–315) that verifies `LanguagesRoute()` / `'/idiomas'` opens `LanguagesSheet` (with `NocheTabBar` hidden and the map tab kept behind it) once N2.10 lands, or logs unanswered on pre-N2.10 `main` (same pattern as PR #150 for N4.2 `PlaceRoute('casa')`).

## Why

Story N2.10 ("Your languages (the sheet) and the language chip", issue #93) wires `ProfileModule.screenFor` to answer `LanguagesRoute()` with `LanguagesSheet`. Changing `coqui/app/test/` from `lane/feature_profile/93` is disallowed by `check_boundaries.dart`.

## What I am using meanwhile

All `feature_profile` unit, widget, static, and screenshot tests pass against `LanguagesSheet` and `ProfileModule.screenFor(const LanguagesRoute(), s)` inside `coqui/packages/features/feature_profile/`.

## Order and branch

- Order: 93 (N2.10 Your languages sheet)
- Branch: `lane/feature_profile/93`
