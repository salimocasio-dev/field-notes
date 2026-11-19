# feature_map

The home map (page 11), the Today card, the place sheet.

- Kind: Flutter package.
- Replaces: pixel/mapa.js and mapa.html; the Today card and place sheet in app.html.
- One package is one lane. Branch: `lane/feature_map/<order number>`.
- Work orders: 13.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: contracts, ui, pixel.
- Coquí packages: `coqui_contracts`, `coqui_pixel`, `coqui_ui`.
- Third party: `material_ui` ^1.11.1.
- Dev only: `flutter_lints`, `flutter_test` (from the SDK), and `coqui_testing` (the fakes).
- `coqui_testing` goes under `dev_dependencies` only. Tests and `tool/` import it. Nothing under `lib/` does.
- Material widgets come from `package:material_ui/material_ui.dart`. Nobody imports `package:flutter/material.dart`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/feature_map.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- The file exports one thing: `MapModule` (boundary rule 4), the module with id `map` and the tab `map`. It answers no route.
- Order 13 built it. `lib/src/map_picture.dart` is a port of pixel/mapa.js (the island; the ten places are in `map_places.dart`, the layout in `map_layout.dart`), pure Dart, so it runs in the golden tests on the VM and in a browser. `map_model.dart` reads the state from the progress store (app.html: `hecho`, `abierto`, `aqui`) and today's plan (`plan`). `map_screen.dart` is the tab: the chips, the scrolling picture through `PixelView`, the Today card, the place sheet. `place_sheet.dart` is the sheet's body.
- The screen draws the whole screen: the card and the sheet sit above the tab bar's height, as in coqui_ui's gallery, so the shell draws the bar over it.
- `MapScreen.reviewTitle`: the title of the Today card's review entry (Spanish, from app.html's `plan()`) is not in the catalog, so the screen shows that entry only when it is given a title; `MapModule` gives none. See `coqui/requests/13-feature-map-needs-coqui-ui-review-title.md`.

## Run and test it alone

The dev entry is `tool/dev_main.dart`, not `lib/dev_main.dart` (`lib/` may not import `coqui_testing`; page 12, section 7 says `lib/dev_main.dart`; the orchestrator changed that on Nov 19, 2026):

```
cd coqui/packages/features/feature_map
flutter run -d chrome -t tool/dev_main.dart --web-launch-url "/?demo=three"
flutter build web -t tool/dev_main.dart --no-web-resources-cdn
node tool/shots.mjs --out <dir> [--perf]   # builds it, serves it, captures the map, the sheets and the Today card at 412 x 915, ratio 2.625; pairs.json says which reference picture each is held against
```

The address says what it opens on (all optional): `demo=none|three|all` (mapa.html's three states), `seed=vacio|segunda|uno|curso|casi|todo` (the stored progress of a reference picture of v=39), `todo=1` ("Open every place"), `place=1..10` (go to that place once the map is up), `reduce=1` (reduceMotion), `review=0`, `chip=0`. A corner chip shows the bake time and the slowest frame in ms; it exists only in the dev entry.

Tests: `flutter test` runs them all on the VM. The golden test (`test/map_golden_test.dart`) is pure Dart and also runs in a browser: `flutter test --platform chrome test/map_golden_test.dart` (the other tests import `../tool/`, which the browser runner cannot load). It reads the references of `coqui/ref/pp/map/` as files on the VM and from `test/support/fixtures/ref_map.dart` in the browser: `dart run tool/make_fixtures.dart` makes that file (`--check` says whether it is current). `tool/map_seeds.dart` is made by `dart run tool/make_seeds.dart` from `coqui/ref/pantallas/seeds/`. `tool/map_fixture.dart` is the course (curso.js's ten places) and the progress the dev entry and the tests run on.

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

From 03-requirements, "The app structure":

- "You made the whole app the map and game., when the map is just one part and it's how you interact with the lessons. The rest of the app should still exist."
- "we don't need to pack all the listening to the map, the app can have another opportunities just like it does outside of A1. The full app should be available for Day 1 just tailored for the A1 experience."
- UI vision: a simple welcome explaining how it works; A1→A2 as a classic Super Mario Bros. 3 style world map (16-bit, seen at an angle, roads, numbered stops, landmarks; places match what is learned), worked through daily; a profile showing where he is; a simple streak; a way to add words or state a goal ("I want to be able to speak to my 1-year-old son around the house") and get extra material; course adjusted to time commitment.

From 03-requirements, "The five plan decisions: all settled by him on Nov 13":

- 5. The map: approved. "the map is fine".

From 09-ui-plan, "What the doc says, in short":

- Home is the 16-bit course map, in the centre tab of a persistent bottom tab bar (3 to 5 tabs). Map = home; flashcards/review; library/reading; stats/profile; optional community.
- Pixel art scaled nearest-neighbour, by whole numbers; no sub-pixel movement.
- The map must read instantly: clear paths, done vs locked stops, the current objective highlighted. Branching allowed (autonomy).
- Thumb zone: primary actions and the mic in the bottom third. Targets 48 px or more, 16 to 24 px apart. 8-point grid. Type: H1 24 semibold, H2 16 to 18, body 14 to 16, labels 12.
- Haptics: short crisp ticks on taps, a richer pattern on unlocking a place, never long buzzes. Synced with sound and visuals.

From 09-ui-plan, "What is built (v=34, Nov 14)":

- Map: stop states (current ringed, done green, open outlined, locked grey); the Today card never covers a stop; small phones and landscape scroll the map instead of shrinking it.
- Place sheet: 70% high, a close X, the tab bar stays usable.

From 09-ui-plan, "Not done from the doc":

- A rich haptic on unlocking a place; streak freezes; the map at an angle; finished places changing the map's art.
