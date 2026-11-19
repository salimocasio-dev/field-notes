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
- Third party: none.
- Dev only: `flutter_lints`, `flutter_test` (from the SDK).
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/feature_map.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- Today the file holds a library comment and nothing else.
- Later it holds one thing: its module, a `FeatureModule` (boundary rule 4).

## Run and test it alone

```
cd coqui/packages/features/feature_map
flutter test
```

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

A dev entry that starts the feature on the fakes comes with order 02: `flutter run -d chrome -t lib/dev_main.dart` in `coqui/packages/features/feature_map`.

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
