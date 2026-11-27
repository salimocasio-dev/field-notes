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
- Not ported: the landscape two-column layout of v=39 (the chips and the Today card in a right column). The app is portrait: the phone builds are locked to portrait and the web manifest asks for it. The map tab scrolls, and the place sheet hides its "Place N" line in landscape as v=39 does.
- The screen draws the whole screen: the card sits above the tab bar's height, as in coqui_ui's gallery, so the shell draws the bar over it. The place sheet opens with `showCoquiSheet` (a route of the root navigator), so its scrim dims the tab bar too, as v=39's does.
- Order 26: `MapModule(showPerf: true)` (`MapScreen.showPerf`) shows the bake time and the frame times (slowest and mean) in a small chip in a corner, under the chips bar: the app's `?perf=1`. Off by default.
- The Today card's review entry ("N words coming back") counts the words Repaso can serve (`repasoServing` in coqui_contracts, the rule the session asks), not only the words with a picture pair; with no games' data, today's rule (`test/map_model_test.dart`).
- `MapScreen.reviewTitle`: the title of the Today card's review entry (app.html's `plan()`); the screen shows that entry only when it is given a title, and `MapModule` gives `MapWording.reviewTitle`.

## Standing contracts & conventions

- **Stable widget keys** (used by shell and integration tests; do not rename or drop):
  - `MapScreen`: `Key('map-screen')`, `Key('language-chip')`, `Key('streak-chip')`, `Key('up-next-card')`, `Key('up-next-play')`, `Key('up-next-place')`, `Key('you-are-here')`, `Key('map-perf-chip')`.
  - `PlaceScreen`: `Key('place-screen')`, `Key('place-back')`, `Key('place-counter')`, `Key('place-hero-picture')`, `Key('story-tile-$storyId')`, `Key('story-heard-$storyId')`, `Key('place-plan-card')`, `Key('place-see-plans')`, `Key('place-play-bar')`, `Key('place-plan-tag')`, `Key('place-stories-scroll')`, `Key('place-pill-listen')`, `Key('place-pill-read')`, `Key('place-pill-call')`.
- **Wording (`lib/src/wording.dart`):** All English UI and semantic strings for `feature_map` live in `MapWording` so screens, models, and tests share one source of truth.
- **Motion (`lib/src/motion.dart`):** Never use literal `Duration(`, `Curves.`, or `Cubic(` anywhere under `lib/`. `lib/src/motion.dart` is the only file under `lib/` allowed to call `NocheMotion.ms(...)`; all other timings, curves, and distances come from `NocheMotion` / `NocheMotionData`.
- **Shared scene picture window (`NocheWindow` / `lib/src/scene_window.dart`):** The scene picture shared across the map card, the place hero, and the lesson uses `MapSceneWindow` with tag `MapMotion.storyWindowTag(storyId)` (`storyId`) and a single whole-number device-pixel scale so `PixelView` never zooms during transitions. A tag is used at most once per screen (story tiles take no tag), and `MapScreen` gates its tag on `TickerMode.valuesOf(context).enabled` so offstage tabs never collide with an active `PlaceScreen`.

## Run and test it alone

The dev entry is `tool/dev_main.dart`, not `lib/dev_main.dart` (`lib/` may not import `coqui_testing`; page 12, section 7 says `lib/dev_main.dart`; the orchestrator changed that on Nov 19, 2026):

```
cd coqui/packages/features/feature_map
flutter run -d chrome -t tool/dev_main.dart --web-launch-url "/?demo=three"
flutter build web -t tool/dev_main.dart --no-web-resources-cdn
node tool/shots.mjs --out <dir> [--perf]   # builds it, serves it, captures the map, the sheets and the Today card at 412 x 915, ratio 2.625; pairs.json says which reference picture each is held against
```

The dev entry's root widget (`MapDevApp`) and the fixture it runs on are in `test/support/` (`map_dev_app.dart`, `map_fixture.dart`, `map_seeds.dart`), because a browser test loads nothing outside `test/`.

The address says what it opens on (all optional): `demo=none|three|all` (mapa.html's three states), `seed=vacio|segunda|uno|curso|casi|todo` (the stored progress of a reference picture of v=39), `todo=1` ("Open every place"), `place=1..10` (go to that place once the map is up), `reduce=1` (reduceMotion), `review=0`, `chip=0`. A corner chip shows the bake time and the slowest frame in ms; it exists only in the dev entry.

Tests: `flutter test` runs them all on the VM, and `flutter test --platform chrome` runs them all in a browser. The golden test (`test/map_golden_test.dart`) is pure Dart. It reads the references of `coqui/ref/pp/map/` as files on the VM and from `test/support/fixtures/ref_map.dart` in the browser: `dart run tool/make_fixtures.dart` makes that file (`--check` says whether it is current). `test/support/map_seeds.dart` is made by `dart run tool/make_seeds.dart` from `coqui/ref/pantallas/seeds/`. `test/support/map_fixture.dart` is the course (curso.js's ten places) and the progress the dev entry and the tests run on.

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
