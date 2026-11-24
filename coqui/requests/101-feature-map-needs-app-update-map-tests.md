# Request: Update app/test map assertions for N4.1 Noche UI

## What I need

On `origin/main` (`3f0c653`), `coqui/app` `flutter test` passes **42 / 42**. With PR #127 (`lane/feature_map/101`) merged with `origin/main`, `coqui/app` `flutter test` gets **33 passed, 9 failed** — every failure is an assertion inspecting removed `v=39` map widgets (`MapChips`, `TodayCard`) or pre-Noche map copy (`1 · La casa`, `2 · El parque`, `4 · El colmado`, `¿Cuál?`, `TODAY · 1 OF 3`, `New story · play it twice · N min`). All 6 tests in `noche_shell_test.dart` already pass.

Please update the following **9 failing tests** (and shared helper `playFromToday`) in `coqui/app/test/` in `lane:app` (either before or in the same release train as PR #127):

1. **`coqui/app/test/start_test.dart`** (3 tests)
   - `(a) an empty store: the map, with the welcome over it; finishing it leaves the map`:
     - L16, L26: `expect(find.byType(MapChips), findsOneWidget)` -> `find.byKey(const Key('language-chip'))` (or `find.text('Spanish')`)
   - `(k) an unknown address opens the map`:
     - L49: `expect(find.byType(MapChips), findsOneWidget, reason: at)` -> `find.byKey(const Key('language-chip'))`
   - `(l) no network: one line and "Try again"; trying again with the network back starts the app`:
     - L84: `expect(find.byType(MapChips), findsOneWidget)` -> `find.byKey(const Key('language-chip'))` (`find.text('5 days')` on L85 still matches)

2. **`coqui/app/test/tabs_test.dart`** (2 tests)
   - `(b) the mid-course progress: each of the five tabs opens and shows it`:
     - L18: `expect(find.text('2 · El parque'), findsOneWidget)` -> `find.text('You are here')` / `find.text('Review')` (`find.text('5 days')` on L17 and `find.text('10 words coming back · 6 min')` on L19 still match)
     - L75: `expect(find.text('2 · El parque').hitTestable(), findsOneWidget)` -> `find.byKey(const Key('language-chip')).hitTestable()` / `find.text('You are here')`
   - `(c) tap a place, tap a story row: the story, the tab bar hidden; its X returns to the map with the bar back`:
     - L89: `tester.getBottomLeft(find.byType(MapChips)).dy` -> `find.byKey(const Key('language-chip'))`
     - L90: `tester.getTopLeft(find.byType(TodayCard)).dy` -> `find.byKey(const Key('up-next-card'))`
     - L126: `expect(find.text('2 · El parque').hitTestable(), findsOneWidget)` -> `find.byKey(const Key('language-chip')).hitTestable()` / `find.text('You are here')`

3. **`coqui/app/test/lessons_test.dart`** (2 tests)
   - `(f, g) Repaso from the Today card: the games of page 15; answered, they write ear answers; ¿Cuál?'s pictures come from ScenePictures (El frente: the new scene; another scene: its old picture); it ends on Palabras`:
     - L198: `expect(find.text(CoquiLabels.reviewTitle), findsOneWidget)` (`'¿Cuál?'`) -> `expect(find.text('Review'), findsOneWidget)`
     - L199: `await app.tap(find.byType(TodayCard))` -> `await app.tap(find.byKey(const Key('up-next-play')))` (or `find.byType(NochePlayDisc)`)
   - `(h) the level check opened from Yo, answered and finished, calls presume; the map follows`:
     - L404: `expect(find.text('1 · La casa'), findsOneWidget)` -> `expect(find.text('UP NEXT · LA CASA'), findsOneWidget)`
     - L428: `expect(find.text('1 · La casa'), findsNothing)` -> `expect(find.text('UP NEXT · LA CASA'), findsNothing)`
     - L429: `expect(find.text('2 · El parque'), findsOneWidget)` -> `expect(find.text('UP NEXT · EL PARQUE'), findsOneWidget)`
     - L430: `expect(find.byType(MapChips), findsOneWidget)` -> `expect(find.byKey(const Key('language-chip')), findsOneWidget)`

4. **`coqui/app/test/story_test.dart`** (1 test + helper)
   - Helper `playFromToday`:
     - L18: `await app.tap(find.byType(TodayCard))` -> `await app.tap(find.byKey(const Key('up-next-play')))` (or `find.byType(NochePlayDisc)`)
   - `(d) La lluvia played to its end writes storyFinished; the map follows, and names the next story once it is due`:
     - L55: `expect(find.text('New story · play it twice · 4 min'), findsOneWidget)` -> `expect(find.text('New story · 4 min'), findsOneWidget)`
     - L72: `expect(find.text('TODAY · 1 OF 3'), findsOneWidget)` -> `expect(find.text('UP NEXT · LA CASA'), findsOneWidget)` (`find.text('Second play · 2 min')` on L74 still matches)
     - L84: `expect(find.text('New story · play it twice · 6 min'), findsOneWidget)` -> `expect(find.text('New story · 6 min'), findsOneWidget)`

5. **`coqui/app/test/previa_test.dart`** (1 test)
   - `in the app a preview story with a converted scene opens from the map and plays to its end, silent`:
     - L329: `expect(find.text('4 · El colmado'), findsOneWidget)` -> `expect(find.text('UP NEXT · EL COLMADO'), findsOneWidget)`
     - L331: `expect(find.text('New story · play it twice · 4 min'), findsOneWidget)` -> `expect(find.text('New story · 4 min'), findsOneWidget)`
     - L333: calls `playFromToday(app)` (updated in `story_test.dart` L18).

Note: N4.1 omits any CEFR level badge (`'A1'`) from the language chip until `101-feature-map-needs-coqui-contracts-story-scene-and-level.md` lands, so `app/test` should not assert `'A1'` on the map.

## Why

Story N4.1 ("Map (home)", issue #101) replaces `MapScreen`'s old `MapChips` and `TodayCard` with the Noche UI (`Noche-Mapa.dc.html`). `lane/feature_map/101` cannot edit files under `coqui/app/`.

## What I am using meanwhile

All 63 unit, widget, static, and golden tests inside `feature_map` pass on `feature_map`'s own test harness; `coqui/app/test/` updates belong to `lane:app`.

## Order and branch

- Order: 101 (N4.1 Map home)
- Branch: `lane/feature_map/101`
