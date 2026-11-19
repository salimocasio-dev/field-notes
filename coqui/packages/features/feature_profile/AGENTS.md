# feature_profile

Yo, the welcome, settings, About.

- Kind: Flutter package.
- Replaces: the Yo tab and the welcome in app.html.
- One package is one lane. Branch: `lane/feature_profile/<order number>`.
- Work orders: 25.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: contracts, ui.
- Coquí packages: `coqui_contracts`, `coqui_ui`.
- Third party: `material_ui` ^1.11.1.
- Dev only: `flutter_lints`, `flutter_test` (from the SDK), and `coqui_testing` (the fakes).
- `coqui_testing` goes under `dev_dependencies` only. Tests and `tool/` import it. Nothing under `lib/` does.
- Material widgets come from `package:material_ui/material_ui.dart`. Nobody imports `package:flutter/material.dart`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/feature_profile.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- Today the file holds a library comment and nothing else.
- Later it holds one thing: its module, a `FeatureModule` (boundary rule 4).

## Run and test it alone

```
cd coqui/packages/features/feature_profile
flutter test
```

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

A dev entry that starts the feature on the fakes comes with order 02. It lives in `tool/dev_main.dart`, not in `lib/` (`lib/` may not import `coqui_testing`): `flutter run -d chrome -t tool/dev_main.dart` in `coqui/packages/features/feature_profile`. Page 12, section 7 says `lib/dev_main.dart`; the orchestrator changed that on Nov 19, 2026.

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

From 03-requirements, "The app structure":

- UI vision: a simple welcome explaining how it works; A1→A2 as a classic Super Mario Bros. 3 style world map (16-bit, seen at an angle, roads, numbered stops, landmarks; places match what is learned), worked through daily; a profile showing where he is; a simple streak; a way to add words or state a goal ("I want to be able to speak to my 1-year-old son around the house") and get extra material; course adjusted to time commitment.

From 09-ui-plan, "What the doc says, in short":

- Each tab keeps its state (scroll, place in a deck).
- Avoid gamification fatigue: forgiving streaks (streak freezes), meaningful rewards, no rigid single path.

From 09-ui-plan, "What is built (v=34, Nov 14)":

- Round 3 (v=34): map stops show done/current/open/locked with an N/M chip; the place sheet marks the next story; story ends offer Play again and Map; landscape lessons keep their controls in the right column; Hablar is one card; the level check's explanation lives in Yo.

From 09-ui-plan, "Not done from the doc":

- A rich haptic on unlocking a place; streak freezes; the map at an angle; finished places changing the map's art.
