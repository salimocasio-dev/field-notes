# Request: Update coqui/app/test/tabs_test.dart for N4.7 Noche Me screen

## What I need

Update `coqui/app/test/tabs_test.dart`, test `(b)` (lines 81–89), which currently asserts the legacy v=39 Yo stat grid (`find.text('78')`) and single-line place text (`find.text('A1 · place 2 of 10 · El parque')`):

- Currently:
  ```dart
  // Yo: the seed's streak, minutes and words heard, and where he is
  await app.openTab('me');
  expect(app.selectedTab, 'me');
  expect(find.text('109').hitTestable(), findsOneWidget);
  expect(find.text('78').hitTestable(), findsOneWidget);
  expect(
    find.text('A1 · place 2 of 10 · El parque').hitTestable(),
    findsOneWidget,
  );
  ```
- Update to support both the N4.7 Noche Me screen (`find.text('Me')`, `find.text('109')`, `find.text('0 of 78 good')` inside `Key('me-skill-listening')`, `find.text('A1 · place 2 of 10')`, and `find.text('El parque')`) alongside pre-N4.7 `main` (`find.text('78')` and `find.text('A1 · place 2 of 10 · El parque')`), matching the dual-compatibility pattern used in PR #182 for N4.4 Words.

## Why

Story N4.7 ("Me", issue #107, board `docs/proyecto/noche/Noche-Yo.dc.html`) replaces the legacy 4-card Yo stat grid (`78 words heard`) and single-line `"Where you are"` text (`A1 · place 2 of 10 · El parque`) with the Noche stats card (`109 minutes listened / all languages` + 7-day chart) and language card (`A1 · place 2 of 10` over `El parque`, 10 place dashes, and `Listening`/`Speaking` rows showing `"<N> of 78 good"`). Editing `coqui/app/test/` from `lane/feature_profile/107` is disallowed by `check_boundaries.dart`.

## What I am using meanwhile

All 194 tests in `coqui/packages/features/feature_profile/` (unit, widget, preserved Yo handlers/switches/notaHabla, Noche static guards, RTL mirroring, touch-target checks, and Part 1.6 screenshots at 390×844 and 412×915) pass inside `feature_profile`, and `coqui/app/test/lessons_test.dart` (including `(h)` opening Level check from Me) passes unchanged.

## Order and branch

- Order: 107 (N4.7 Me)
- Branch: `lane/feature_profile/107`
