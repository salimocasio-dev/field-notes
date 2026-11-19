# app

The shell: tabs, routes, wiring, web/, android/, ios/.

- Kind: Flutter package.
- Replaces: app.html's tab bar and page switching.
- Orders: 03 (site build; Android and iOS builds) and 26 (the shell). Both are the orchestrator's.
- The runbook is `../AGENTS.md`. Read it first.

## May depend on

- The plan's row: everything.
- Coquí packages: every package in the workspace (`coqui_testing` as a dev dependency only).
- Third party: `go_router` ^18.1.4 (only here), `material_ui` ^1.11.1.
- Dev only: `flutter_lints`, `flutter_test` (from the SDK), and `coqui_testing` (the fakes).
- `coqui_testing` goes under `dev_dependencies` only. Nothing under `lib/` imports it.
- Material widgets come from `package:material_ui/material_ui.dart`. Nobody imports `package:flutter/material.dart`.
- Nothing else. Routing (`go_router`) lives here and nowhere else. The browser is reached by `dart:js_interop` in
  `lib/src/web/browser_web.dart` only, behind a conditional import (`browser_io.dart` in a phone build).

## Public surface

- None. This is the app, not a library.
- `lib/main.dart` starts it: the address switches, read once, and the real platform (`lib/src/real_platform.dart`).
- `lib/src/modules.dart` is the one list of feature modules: the five tabs in v=39's order (Biblioteca, Palabras,
  Mapa, Hablar, Yo), then the story and Repaso / the level check. A route opens the first module whose `screenFor`
  answers it.
- `lib/src/app.dart`: `CoquiApp` on an `AppPlatform` (`lib/src/platform.dart`: fetch, content base, storage, clip
  player, speech, call, haptics, `AppInfo`, clock, the browser's back). `coquiTheme()`; `MaterialApp.router` on
  go_router; the first tap anywhere calls `clips.unlock()`. The start: the storage, `PalabrasStore` on its progress
  space and the clock (the old key `coqui.palabras.v1` is simply there: nothing is imported or deleted), the course
  (`ContentCatalog.load`) before the first screen, the voice test's file, the call session. While it loads: the page
  colour, nothing else. If the course cannot be loaded: one line, "Coquí could not load. Check your connection.", and a
  blue "Try again" that starts again. Then `WelcomeGate` around everything. `Services`: `Mulberry32` seeded once from the
  clock; `reduceMotion` from `MediaQuery.disableAnimations` when the app first shows (fixed for the session, as
  `ScenePictures(still:)` is); `ScenePictures(pairs: course.pairs)` as the picture source; storage spaces by name.
- `lib/src/shell.dart`: the tabs, each built the first time it is shown and then kept (offstage, tickers off, when not
  shown: the map bakes once; Hablar reads `call.available`, which loads the ElevenLabs library, only once it is shown);
  `CoquiTabBar` with `CoquiTabs` drawn over the tab body (`FeatureTab.icon` is not used); a lesson screen over
  everything, the tab bar hidden; a `PopScope` that turns the system back on a lesson into `nav.back()`.
- `lib/src/navigator.dart`: `ShellNavigator`, the `AppNavigator` (see "Addresses" below).
- `lib/src/content.dart`: the content base and the cache rules. `lib/src/switches.dart`: the address switches.
  `lib/src/scripted_speech.dart`: the recogniser of `?mic=stub:` / `?mic=off`. `lib/src/voice_test_data.dart`: the voice
  test's file read; `modules.dart` builds from it the `VoiceTestContent` of `SpeakingModule(voiceTest:)`, so `#/prueba-voz`
  opens the voice test (no entry to it on a tab: v=39 links it from nowhere).
- `web/index.html` carries `translate="no"`, `<meta name="google" content="notranslate">`, the old app's viewport and
  theme-color, the Apple web-app tags, the title "Coquí", and v=39's page colour (#F6F5F1) behind everything until the
  first frame. No service worker. `web/manifest.json` and `web/icons/` are the home-screen app. The Flutter engine
  rewrites the page's `lang` and viewport when it starts.
- `android/`: application id `dev.salimocasio.coqui`, display name "Coquí". `RECORD_AUDIO` and `INTERNET`, and the
  `RecognitionService` query, as the speech_to_text README gives them. `android/debug.keystore` is the standard Android
  debug key, not a secret: it is in the repo so every build installs over the last. Not for the store. The gradle files
  are Kotlin (`build.gradle.kts`). A phone build reads the course from the live site
  (`https://salimocasio-dev.github.io/field-notes/historia/`): it has no page to take a base from.
- `ios/`: bundle id `dev.salimocasio.coqui`, display name "Coquí", the microphone and speech-recognition usage lines in
  `Runner/Info.plist`. Built unsigned, weekly, by CI.
- Do not run `flutter create` here again. If a platform file must change, change it by hand.

## Addresses

Hash addresses (GitHub Pages has no fallback for path addresses). Reloading an address opens that screen; an address
that names nothing, or a lesson no module answers (a story the course does not have, a call for a place with none),
opens the map.

| Screen | Address |
| --- | --- |
| a tab (`library`, `words`, `map`, `speak`, `me`) | `#/tab/<id>` |
| a story / told straight through | `#/cuento/<id>` / `#/cuento/<id>?oir=1` |
| Repaso / practice | `#/repaso` / `#/repaso?practica=1` |
| the level check | `#/nivel` |
| a book | `#/libro/<id>` |
| the call for a place | `#/llamada/<placeId>` |
| the voice test | `#/prueba-voz` |

How the app moves, as the old pages do:

- A tab is switched in place (`history.replaceState`, app.html `ver`): the browser's back on a tab leaves the app.
- A lesson opened from a tab is a new step in the history; one opened from a lesson (Next story) takes its place.
- `back()` (a lesson's X, Android's system back) returns to the tab that opened the lesson, kept while he moves from
  story to story (juego.js `origen`). On the web it is the browser's own `history.back()`, so the browser's back and the X
  do the same thing and the history is as it was before the lesson. A lesson whose address was opened as it is (a
  reload) returns to the map.
- `go(TabRoute(...))` from a lesson (a story's Map, Repaso's way back to Palabras, the level check's "To the map")
  leaves it for that tab.

## Address switches

Before the `#`, read once at the start, never kept: `?perf=1` (the map's bake and frame times and a story's scene bake in
corner chips: `MapModule(showPerf:)`, `StoryModule(showPerf:)`), `?callstub=1` with `stub=` and `clock=` (the call is
coqui_platform's `CallStub`), `?mic=stub:<r1>|<r2>|...` and `?mic=off` (the scripted recogniser,
docs/hablar/01-decisiones.md, "Machine tests"), and `?txt=con|tras|no` (juego.js's TXT: when a story's words show, as the
line is spoken, right after it, never; anything else is `con`; `StoryModule(txt:)`).

## The cache rules (the old pages')

`audio/ready.json`, `audio/marcas.json`, `datos/*.json` and `cuentos/*.json`: `cache: "no-store"`. `libros/*.json` and the
books' pictures: `?v=39`. Clips: `audio/<id>.mp3?v=<ready.json's v>` (the catalog's url, from the content base).

## Run and test it alone

```
cd coqui/app
flutter test
flutter run -d chrome
flutter build web --no-web-resources-cdn
```

The tests run the real modules, the real `PalabrasStore`, the real `ContentCatalog` on the files of `historia/` read
from disk and the real `ScenePictures`; fakes only for sound, speech, the call, the clock, haptics and `AppInfo`
(`test/support/harness.dart`).

Gate A's pictures (a tool, not a test; it is not run by `flutter test`): `tool/gate_a_frames_test.dart` plays stories 1 to 3
(El frente), each right and wrong, by touches in the real app on a 390 x 844 screen at ratio 2, and saves what is seen:

```
flutter test tool/gate_a_frames_test.dart --dart-define=OUT=<dir>   # [--dart-define=ONLY=la-lluvia-right,...] [--dart-define=TXT=con|tras|no]
flutter test tool/gate_a_sheets_test.dart --dart-define=OUT=<dir>   # the contact sheets again, from the pictures on disk
```

It writes `<dir>/<story>-<plan>/NN-<kind>.png`, `index.json` and `sheet-NN.png` (4 pictures a sheet), and `<dir>/summary.json`.
`TXT` (default `con`) starts the app as the address `?txt=` does (`AppSwitches.fromQuery({'txt': ...})`): when the story's words
show, as the line is spoken, right after it, or never. With `no` nothing of the story's words is on the screen (the speech
bubble's mic and tick, the end title and the buttons still are, as in the old page). The tool still finds its way: it reads the
runner and the clip player, not the screen. In `index.json` each picture's `caption` and `bubble` are what the runner shows
(empty with `no`); `said` is the text of the last line the story began to speak, whether it shows or not; `txt` names the setting.

The build the live site gets, and the browser checks of it:

```
COQUI_BUILD=$(cat ../BUILD) bash ../tool/build_sitio.sh <dir>
node ../tool/check_app.mjs <dir> --out=<shots dir>   # serves <dir> at /field-notes/app/ and the repo's historia/ beside it
node ../tool/check_sitio.mjs <dir>                   # the same serving: the app starts on the map, reads historia/, Yo shows "build <BUILD>"
```

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

From 03-requirements, "The app structure":

- "You made the whole app the map and game., when the map is just one part and it's how you interact with the lessons. The rest of the app should still exist."
- UI vision: a simple welcome explaining how it works; A1→A2 as a classic Super Mario Bros. 3 style world map (16-bit, seen at an angle, roads, numbered stops, landmarks; places match what is learned), worked through daily; a profile showing where he is; a simple streak; a way to add words or state a goal ("I want to be able to speak to my 1-year-old son around the house") and get extra material; course adjusted to time commitment.

From 09-ui-plan, "What the doc says, in short":

- Home is the 16-bit course map, in the centre tab of a persistent bottom tab bar (3 to 5 tabs). Map = home; flashcards/review; library/reading; stats/profile; optional community.
- Lessons go full screen; the tab bar hides and comes back on exit. Learning screens are calm (white, off-white or dark grey); colour only for meaning (green right, red/orange wrong, blue/purple system and active tab).
- Each tab keeps its state (scroll, place in a deck).

From 03-requirements, "His instructions to the build chat (Nov 13)":

- "Why are the captions English. Everything should be in spanish." (The code was all Spanish; most likely his phone translated the page. Pages are now marked do-not-translate.) Then: "It's good. Continue". So: nothing on screen in a lesson may turn into English, by any route.
