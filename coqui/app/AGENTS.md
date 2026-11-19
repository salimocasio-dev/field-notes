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
- Nothing else. Routing (`go_router`) lives here and nowhere else.

## Public surface

- None. This is the app, not a library.
- `lib/main.dart` starts the app. Today it shows an empty `MaterialApp` titled "Coquí" with the text "Coquí", centred, and under it, small, "build <n>": the number comes from `String.fromEnvironment('COQUI_BUILD', defaultValue: 'dev')`, which the site workflow sets from `coqui/BUILD`.
- `lib/src/modules.dart` is the one list of feature modules. Today it is empty. Its comment names the seven features in tab order.
- `web/index.html` carries `translate="no"`, `<meta name="google" content="notranslate">`, the old app's viewport and theme-color, and the Apple web-app tags. `web/manifest.json` and `web/icons/` (placeholders made by `../tool/make_icons.dart`) are the home-screen app. The Flutter engine rewrites the page's `lang` and viewport when it starts (see `../tool/check_sitio.mjs`).
- `android/`: application id `dev.salimocasio.coqui`, display name "Coquí". `RECORD_AUDIO` and `INTERNET`, and the `RecognitionService` query, as the speech_to_text README gives them. `android/debug.keystore` is the standard Android debug key, not a secret: it is in the repo so every build installs over the last. Not for the store. The gradle files are Kotlin (`build.gradle.kts`).
- `ios/`: bundle id `dev.salimocasio.coqui`, display name "Coquí", the microphone and speech-recognition usage lines in `Runner/Info.plist`. Built unsigned, weekly, by CI.
- Do not run `flutter create` here again. If a platform file must change, change it by hand.

## Run and test it alone

```
cd coqui/app
flutter test
flutter run -d chrome
flutter build web --no-web-resources-cdn
```

The build the live site gets, and a check of it: `bash ../tool/build_sitio.sh <dir>`, then `node ../tool/check_sitio.mjs <dir>`.

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
