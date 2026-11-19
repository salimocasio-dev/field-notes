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
- Since order 25 the file exports two things: `ProfileModule` (the tab `me`, the Yo screen) and `WelcomeGate`, the widget the shell wraps the app in so that the welcome (app.html: `bienvenida`, `listo`) shows over everything while the `bienvenida` setting is not set: `WelcomeGate(services: s, child: app)`.
- The dev entry is `tool/dev_main.dart`: `flutter run -d chrome -t tool/dev_main.dart`; `web/` is there for it.

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

The dev entry lives in `tool/dev_main.dart`, not in `lib/` (`lib/` may not import `coqui_testing`): `flutter run -d chrome -t tool/dev_main.dart` in `coqui/packages/features/feature_profile`. Page 12, section 7 says `lib/dev_main.dart`; the orchestrator changed that on Nov 19, 2026.

## Order 25: what is here

- `lib/src/yo_screen.dart` (the Yo tab: `yo`, `notaHabla`, the install hint, About, the build number), `welcome.dart` (the sheet of each welcome step: `welcomeSheet` in place for the gate, `welcomeRouteSheet` for "How it works", which Yo opens with `showCoquiSheet`, above the tab bar, as does About), `welcome_gate.dart`, `about_sheet.dart`, `install_hint.dart`, `texts.dart` (every English line, with its place in app.html), `js.dart` (the JavaScript truthiness, rounding and plural the old code leans on), `licence_text.dart` (made).
- The dev entry's address says the state (`tool/dev_main.dart` lists them): `?seed=curso`, `?screen=welcome&step=1`, `?how=2`, `?about=1`, `?mic=off`, `?ios=1`, `?do=min:120,todo,habla`, `?build=39`. The root widget and its fixture are in `test/support/dev_app.dart`, so the tests run the same.
- Made files (each has a `--check`): `dart run tool/make_licence.dart` (the licence text from coqui_pixel's file), `dart run tool/make_seeds.dart` (`coqui/ref/pantallas/seeds/` into `test/support/seeds.dart`), `node tool/make_course.mjs` (the ten places of `historia/curso.js` into `test/support/course_places.dart`), `node tool/old_expected.mjs` (what the old `yo`, `bienvenida`, `listo` and `notaHabla` do, run in node on the real palabras.js, into `test/support/old_expected.dart`).
- `node tool/shots.mjs` builds the dev entry for the web and captures each state of the order's reference pictures on both phones, with a pairing JSON and side-by-side pictures (the reference, the shot, the difference).

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
