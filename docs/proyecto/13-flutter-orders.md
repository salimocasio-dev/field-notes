# Flutter work orders

Nov 19 2026, after the second review. Goes with 11-flutter-plan (decisions), 12-flutter-contracts (interfaces, the scene method, porting rules) and 11-pixel-engine (the spec for the map and scene pictures).

## How to use this page

- The orchestrator is the Claude Code session. It does the orders marked "orchestrator" itself, hands each other order to one Sonnet builder, merges the branch when "Done when" is met, and runs the gates.
- A builder is given: its order (whole), `coqui/AGENTS.md`, page 12 (the sections its first lines name), its package's AGENTS.md, the old files the order names, and the `coqui/ref/` folders the order names. Pixel, scenes and map builders also get 11-pixel-engine and `docs/proyecto/pixel/`.
- A builder makes no decisions. Where its order and these pages do not settle something, it stops and reports. The orchestrator decides from pages 03, 09, 10 and 11-pixel-engine; what those do not settle goes to Salim in one question.
- **Two kinds of work are not builders' work, and are never handed to Sonnet:** designing a scene's set (orders 07 and 30a to 39a), and anything that goes to Salim.
- "Done when" is checked by the orchestrator by running the commands, not by reading the report.
- Reviews and silent reads are done by fresh agents that did not build the thing.
- Money: no order spends any without the amount told to Salim first.

Every "Done when" includes, without saying so each time: `flutter analyze` clean, `dart format` clean, the package's tests pass (pure Dart packages on `-p vm` and `-p chrome`), `dart run tool/check_boundaries.dart` passes, the branch touches one package.

## The orders at a glance

| Order | What | Who | Needs |
| --- | --- | --- | --- |
| 00 | Six questions on real phones | orchestrator | nothing |
| 01 | Workspace, runbook, checks, CI | orchestrator | nothing |
| 02 | Contracts and fakes | orchestrator | 01 |
| 03 | Site build; Android and iOS builds | orchestrator | 01 |
| 04 | Content exports and clip marks | orchestrator | 01 |
| 05 | Reference data from the old code | orchestrator | 01 |
| 06 | Scene inventories and frames | orchestrator | 05 |
| 07 | El frente's set reference and sheet, completed | orchestrator (design) | 06 |
| 10 | The Pixel Plays engine in Dart | builder, coqui_pixel | 02, 05 |
| 11 | Sprites and the software canvas | builder, coqui_pixel | 10 merged |
| 12 | The scene kit, the signs, the frame | builder, coqui_pixel | 11 merged |
| 13 | The map | builder, feature_map | 10, 20 |
| 14 | El frente in Dart | builder, coqui_scenes | 07, 12, 20 |
| 15 | The story runner and play screen | builder, feature_story | 02, 12, 20 |
| 16 | Progress | builder, coqui_progress | 02, 05 |
| 17 | Content | builder, coqui_content | 02, 04 |
| 18 | Audio, storage, haptics, speech | builder, coqui_platform | 02, 00's answers |
| 19 | The call connection | builder, coqui_platform | 18 merged |
| 20 | Shared look | builder, coqui_ui | 02 |
| 21 to 25 | Palabras; Biblioteca and Leer; Repaso and the level check; Hablar; Yo | builders, one a feature | 02, 20 |
| 26 | The shell | orchestrator | 02 |
| **Gate A** | **The map, El frente and stories 1 to 3 to Salim. The scenes lane stops** | orchestrator | 13 to 26 |
| 30a to 39a | Each other scene's set reference and sheet | orchestrator (design), one at a time | Gate A |
| 30b to 39b | Each other scene in Dart | builder, coqui_scenes, one at a time | its "a" |
| 50 to 53 | El colmado's four new scenes in Dart (sets and sheets are done) | builder, coqui_scenes, one at a time | 39b, or sooner if the lane is free |
| 54 to 57 | La calle's four new scenes in Dart (sets and sheets are done) | builder, coqui_scenes, one at a time | 53b |
| 58 to 61 | La plaza's four new scenes in Dart (sets and sheets are done) | builder, coqui_scenes, one at a time | 57b |
| 62 to 65 | La playa's four new scenes in Dart (sets and sheets are done) | builder, coqui_scenes, one at a time | 61b |
| 66 to 69 | La fonda's four new scenes in Dart (sets and sheets are done) | builder, coqui_scenes, one at a time | 65b |
| 70 to 73 | La casa, un día entero: four new scenes in Dart (sets and sheets are done) | builder, coqui_scenes, one at a time | 69b |
| 74 to 77 | El fuerte's four new scenes in Dart (sets and sheets are done); then the fort check (a first design is with the orders) | builder, coqui_scenes, one at a time | 73b |
| 40 | Every story against its recorded runs | orchestrator | 39b |
| 41 | Books' pictures captured again | orchestrator | 40 |
| 42 | Cutover | orchestrator | 41 |
| 43 | The Android build he can install | orchestrator | 42 |
| 44 | Testers | orchestrator | 42 |

Orders 10 to 12 run one after another. Order 13 and orders 16 to 26 run in parallel with them and with each other. Orders 14 and 15 run in parallel once 12 is merged.

---

## Order 00. Six questions on real phones (orchestrator)

Each answer picks a route. Nothing here shows course pictures.

**Build:** one small Flutter web app, `coqui/tool/prueba_telefono/`, its build committed as static files to `prueba/` on main (today's Pages serves it). Thrown away afterwards. One screen. On start, where the browser has it, set `navigator.audioSession.type = "play-and-record"`. Six numbered buttons, each ending in a line of result text; one "Copy results" button.

1. **Lines.** Ten recorded clips back to back (`../historia/audio/<id>.mp3`, each from its start to its end by juego.js's `trim` rule), once with the audio plugin, once with the browser's Web Audio through JS interop. Shows each gap in ms for both.
2. **Mic in stories.** One Spanish line through the speech plugin (settings as docs/hablar/01-decisiones.md). Then five rounds of: a clip plays, he says "hola", a clip plays. Shows what was heard and whether sound came back each round.
3. **Mic for a call.** Opens a microphone stream (`getUserMedia`) for three seconds and shows the loudest level. This is what a call with Danny needs.
4. **Silent switch (iPhone).** Plays a clip, asks "Did you hear it? Yes / No".
5. **Storage.** Writes a marker; shows whether `coqui.palabras.v1` is visible and whether the app was opened from the home screen.
6. **Load.** The ms from page start to first frame.

**Run:** Salim on his Android: in Chrome, then installed. One tester on an iPhone: in Safari, then from the home screen. One link, one line: "Tap 1 to 6, then Copy results, and paste them to me. Once in the browser, once from the home screen." Also look up, with the source, how long iPhone Safari keeps a site's storage when it is not opened.

**Routes** (write the answers into page 08 and into order 18):

| Answer | Route |
| --- | --- |
| Plugin gaps under 120 ms on both phones | The plugin everywhere |
| Otherwise | On the web, Web Audio by interop; the plugin only in phone builds |
| iPhone: 2 or 3 fails only when installed | Testers use Safari, not the home screen (order 44) |
| iPhone: 2 fails after round 1 | Speaking turns are off on iPhone web. Nothing else changes |
| iPhone: 3 fails | Calls are off on iPhone web |
| iPhone: silent with the switch on | The welcome says once, on iPhone: "Turn the ring switch on to hear the lessons" |
| Android installed app cannot see the old progress | Order 25 builds "Move my progress" before Gate A |

**Done when:** both phones' results are in page 08; each route is written into order 18.

**State (Nov 19): live, waiting for the two phones.** https://salimocasio-dev.github.io/field-notes/prueba/?v=1 . Built by an Opus builder; played through by the orchestrator in headless Chrome (all six tests end in a result, no errors); the 24 live files match the build byte for byte.
- Desktop Chrome, test 1: just_audio leaves a median of about 215 ms between lines (it only notices a clip's end every 250 ms or so); Web Audio about 6 ms.
- Test 4 on an iPhone runs under both audio session types (`playback`, then `play-and-record`), so order 18 gets the type that works.
- The page uses Roboto, not Pixelify Sans: Pixelify's "fi" ligature reads as "A" and its 5 looks like S. Order 20 must turn ligatures off wherever Pixelify Sans is used.
- A just_audio fault on the web: a second `setAudioSources` on the same player keeps the first playlist (just_audio_web 0.4.16). For order 18.
- speech_to_text on the web never sets `maxAlternatives`; the page wraps `webkitSpeechRecognition` to ask for 5. For order 18.
- Safari's storage rule is not confirmed (webkit.org is blocked from the build machine). Unverified: 7 days of Safari use without a visit clears a site's storage; a home-screen app counts separately.

## Order 01. Workspace, runbook, checks, CI (orchestrator)

- `coqui/` as in the plan's "The layout". Every package a shell: `pubspec.yaml` (`resolution: workspace`, only the dependencies its row allows), `lib/<package>.dart`, `lib/src/`, `test/`, `AGENTS.md`.
- Pin Flutter in the repo and in CI. One `analysis_options.yaml`: `flutter_lints`, plus `depend_on_referenced_packages`, `avoid_relative_lib_imports`, `avoid_print`, `always_use_package_imports` as errors.
- Third-party packages, all added now: an audio player (picked after order 00), `speech_to_text`, `shared_preferences`, `go_router` (shell only), `collection`, `web` (coqui_platform only). Check each one's current version and platforms on pub.dev first.
- `coqui/AGENTS.md`: the plan's boundary rules; page 12 sections 1, 6, 7; the audio and reporting rules of historia/notas/runbook-agentes.md; the lanes.
- Each package's `AGENTS.md`: what it is; its row; its public surface; how to run and test it alone; the lines of 03-requirements, 09 and 10 that apply.
- `tool/check_boundaries.dart`: fails when (a) a pubspec lists a package its row does not allow, (b) a file imports a package its pubspec does not list, (c) a file imports another package's `src/`, (d) a branch `lane/<package>/…` changes a file outside that package and `requests/`.
- `.github/workflows/coqui.yml`: on every push under `coqui/`: pub get, the check, analyze, every package's tests (pure Dart on vm and chrome), `flutter build web`.
- Made now, so no two lanes meet in a file: the scene registry in coqui_scenes (eleven ids, each a stub that throws "not converted yet"), the module list in app, the fonts and the Pixelify Sans licence in coqui_ui.

**Done when:** a test branch that imports one feature from another fails CI; a clean branch passes; `flutter build web` makes an empty app.

**Result (Nov 19): done, merged to main.** Built by a Sonnet builder; every check below was run again by the orchestrator.
- `bash coqui/tool/test_all.sh`: passes. 21 test blocks (the four pure Dart packages on vm and chrome), format, analyze, the web build.
- The check fails, with exit 1, on: a feature importing a feature (rule e); an import of another package's `src/` (rule c); a branch `lane/feature_words/99` changing a file in feature_map (rule d). A clean branch passes.
- The check script has 51 tests of its own. Rules added: (f) no `package:flutter/material.dart`; (g) nothing under `lib/` imports coqui_testing.
- Versions resolved: just_audio 0.10.6, speech_to_text 7.5.0, shared_preferences 2.5.6, web 1.1.2, go_router 18.1.4, collection 1.19.1, material_ui 1.11.1, flutter_lints 6.0.0, test 1.32.0.
- Decisions taken while it ran are in 11-flutter-plan, "Decisions made here", the rows marked Nov 19.
- Pixelify Sans is in coqui_ui as .ttf (converted from the site's woff2, Latin subset, 239 glyphs), with its licence.

## Order 02. Contracts and fakes (orchestrator)

**From:** historia/palabras.js, curso.js, juego.js (the names in page 12 section 4), escenas/kit.js (`escena`), cual.js (`panelW`, items), nivel.js (`NV`), llamada.js (`LLAMADAS`, the session calls).

- coqui_contracts, coqui_ui's contracts, and `Thing`, `Scene`, `SceneHost` in coqui_pixel, as page 12 sections 2 to 4. `SceneHost`: one member per name listed, with juego.js's parameters. `normalize` tested on 30 strings whose expected values come from `PAL.norm` in node. `Mulberry32` with ten values checked against the same generator in node.
- coqui_testing: a fake for every interface (in memory; a settable clock; a scripted `SpeechListener` in the shape of today's `?mic=stub:`; a scripted `CallSession` in the shape of today's `?callstub`), and the sample course: El frente, stories 1 to 3, cual-frente, the book la-lluvia, twenty clips. The fake `PictureSource` shows labelled grey boxes now, and saved frames from `ref/` once order 06 has made them.
- A dev entry in each feature that starts it on the fakes.

**Done when:** everything compiles; each dev entry opens; the report lists every member added beyond page 12.

**Result (Nov 19): done, merged to main.** Built by an Opus builder; `bash coqui/tool/test_all.sh` run again by the orchestrator on merged main (passes).
- coqui_contracts: 51 tests on vm and on chrome. `normalize` matches `PAL.norm` on 30 strings (and 2,000 random ones in the generator); Dart has no NFD, so a table of 628 code points is generated from the old regex. Mulberry32 seed 1 matches node on ten values.
- **Differs from page 12:** `SkillRecord.due` is a `num`: palabras.js line 33 (`e.due=t+e.gap*DAY`) can store a fraction, and a real run does (six rights, five misses, one right gives `due = 1794283613888.889`). Every other time field is whole and stays `int`.
- Added beyond page 12, each from the old code: `Scene.SW`, `SH`; `Scene.box`, `hit`, `handAt` declared; `hud(c, W, a)`; `stake(lost, max, en)` returning a Future; `talkAt(who, W)`; `respIcon(c, k, x, y, w, h, a)`; `estado(W)`; `Scene.host` (the old globals); `CallSession.inputVolume()`, `outputVolume()`, and `start` throws when a call cannot start; `PictureRef.of(pair, side)`; `Sfx` with the 18 names of juego.js (right, toc, blip, creak, hop, coqui, win, luz, drop, trueno, lluvia, calla, suave, pio, slam, bonk, munch, swoop).
- In page 12 but not in the old code (kept): `Scene.setKey`, `buildSet`, `remap`, `Thing.world`, `CallSession.setVolume`, `available`, `ProgressStore.changes`, `AppInfo.callsAllowed`, `isIos`, `isAndroid`, `installed`.
- `PpEngine`, `PpBuild`, `Sprite`, `Ctx` are shells for orders 10 and 11. `Ctx` starts with smoothing off.
- coqui_testing: a fake for every interface and `fakeServices()`. The sample course (El frente, stories 1 to 3, cual-frente, the book la-lluvia, 20 clips with real marks) is embedded as Dart strings, checked byte for byte against the copied files: a dev dependency's assets are left out of a web build.
- The fake progress store is not the scheduler (no gaps, no due dates, no 4 am rule): tests seed due words by hand.
- A dev entry in each feature: `tool/dev_main.dart`, with a placeholder module. Each builds for the web.
- `PAL.rec` is called by no page, so it has no member.

## Order 03. Site build; Android and iOS builds (orchestrator)

- One workflow that deploys Pages from Actions: the repo's static files as they are, plus `flutter build web --base-href /field-notes/app/` under `app/`. Change the Pages source to "GitHub Actions".
- `.github/workflows/voz.yml`: as its last step, start the site build (`workflow_dispatch`; the job needs `actions: write`). Commits made with GitHub's own token do not start other workflows.
- `flutter create --platforms=android,ios` in `coqui/app`. Android: the microphone permission and the speech-recognition `<queries>` entry in the manifest; a fixed debug signing key kept in the repo (not a secret; it lets each build install over the last; not for the store). iOS: the microphone and speech-recognition usage lines in Info.plist. Take the exact entries from the `speech_to_text` page.
- CI: `flutter build apk --debug` on every push to main, kept as an artifact; `flutter build ios --no-codesign` weekly on a macOS runner. Confirm on GitHub's pricing page that Actions minutes are free for this public repo before turning the macOS job on; tell Salim if not.
- `web/manifest.json` and `web/index.html`: name Coquí, `display: standalone`, portrait, the coquí icon (rendered from `mkCoqui` after order 11; a placeholder until then), `translate="no"`, `<meta name="google" content="notranslate">`, the Apple touch icon and web-app meta tags.

**Done when:** https://salimocasio-dev.github.io/field-notes/app/ serves the empty app; the old site works at its old addresses (checked with the GitHub API as page 07 says); a dry run shows the audio job would start the site build; the Android artifact installs on an emulator, twice in a row.

**Result (Nov 19): built and merged to main.** Built by a Sonnet builder; the local checks were run again by the orchestrator on merged main.
- **Differs from the order:** the Pages source is not changed (that setting cannot be reached from the build machine). Pages keeps serving main. `.github/workflows/coqui-sitio.yml` builds the web app and commits it to `app/` on main when `coqui/BUILD` changes (or by hand). `coqui/BUILD` is the build number; the orchestrator raises it when a build should go live. `voz.yml` is not changed.
- `bash coqui/tool/build_sitio.sh <dir>`: the same build, locally. 16 MB, 26 files, no service worker, CanvasKit from our own site, only the two CanvasKit variants a dart2js build loads. `node coqui/tool/check_sitio.mjs <dir>` and `bash coqui/tool/dry_sitio.sh` (the commit step against a local repo: main moved, nothing new, main moved twice) pass.
- Android (`coqui-android.yml`, on every push to main under `coqui/`): run 44548671591 built the debug apk, signed with the key in the repo, installed it twice on an emulator and started it. The apk is the artifact `coqui-debug-apk`.
- iOS (`coqui-ios.yml`, weekly and by hand): run 44548671850 built `Runner.app` unsigned. Standard GitHub-hosted runners are free in public repositories (github/docs, billing, github-actions.md: "The use of standard GitHub-hosted runners is free: In public repositories").
- App id `dev.salimocasio.coqui`. Portrait only on Android and iOS. Bluetooth permissions left out on purpose (no extra prompt). The icon is a placeholder until order 11.
- Flutter's engine replaces the page's viewport meta at start, so pinch zoom up to 5x is allowed. Accepted for now.
- Theme colour #5C94FC, page background #F6F5F1, from historia/app.html.

## Order 04. Content exports and clip marks (orchestrator)

New files beside the stories. The old site does not read them.

- `historia/datos/curso.json` (`CURSO`), `nivel.json` (`NV`), `llamadas.json` (`LLAMADAS`), `fijos.json` (every clip id that juego.js, cual.js and llamada.js name in code, each under a role; the goodbye words). Made by `coqui/tool/export_datos.mjs` in node.
- `historia/audio/marcas.json`: for every clip in ready.json, `[startMs, endMs, lengthMs]` by juego.js's `trim` rule (threshold 0.012 on channel 0; 30 ms before the first loud sample, 100 ms after the last). `historia/tools/voz.py` adds the marks for clips it makes.

**Done when:** every clip has marks; ten, picked at random, match what the old page computes in Chrome within 5 ms; a dry run of the audio job records 0 clips.

**Result (Nov 19): done, merged to main.** Built by a Sonnet builder; every check below was run again by the orchestrator.
- `node coqui/tool/export_datos.mjs`: the four files in `historia/datos/`; a second run is byte-identical.
- `historia/audio/marcas.json`: all 1,582 clips of ready.json. Made by `historia/tools/marcas.py` (ffmpeg), which `voz.py` now calls for the clips it records. `voz.yml` installs ffmpeg if the runner lacks it.
- All clips were checked against Chrome, not ten (`node coqui/tool/check_marcas.mjs`). At the clips' own rate, 24 kHz: every mark within 0.5 ms.
- **Differs from "within 5 ms":** at Chrome's default rate (44.1 kHz) 25 clips have an end mark more than 5 ms off, the worst 31 ms, and one start mark is 7 ms off. The old page's `trim` gives different marks on different devices (up to 31 ms between 24 and 44.1 kHz), because the hiss at a clip's tail sits just under its threshold. The marks are kept at the clips' own rate. Decided by the orchestrator.
- `fijos.json`: `story_your_turn` ahora_tu, `story_praise` muy_bien, `review_praise_right` si_muy_bien, `review_praise_after_miss` muy_bien, and `story_routine_no_prefix` hz_no_ (a prefix: juego.js builds `"hz_no_" + thing`). Goodbye words: adiós, hasta mañana. llamada.js names no clip.
- Dry run of the audio job (`python3 coqui/tool/dry_voz.py`): 0 new clips of 1,582.
- Two mp3 files are on disk but not in ready.json (`abuela_abre`, `c22_senor_sombrero`); they have no marks.

## Order 05. Reference data from the old code (orchestrator)

Made by scripts in `coqui/tool/ref/`, written to `coqui/ref/`, committed.

- **Engine** (`ref/pp/`): headless Chrome renders of `docs/proyecto/pixel/`: the map with the demo states `?hecho=0`, `?hecho=3`, `?hecho=10` at time 0 (with the `hecho`, `abierto`, `aqui` arrays mapa.html builds for each, saved beside the picture), each as raw `pix`, `zb`, `kinds` and as PNG. A unit page that calls `hash`, `noise`, `project`, `unproject`, `rampOf` on 200 fixed inputs, outputs as JSON.
- **Sprites** (`ref/sprites/`): every sprite engine.js and kit.js can make, and every sprite a scene file makes for itself (read each scene's sprite cache after its stories' runs), as width, height, raw pixels, and the call that made it.
- **Canvas sheet** (`ref/ctx/`): one page drawing 40 numbered cases with the browser's canvas into 64 × 64 tiles: fillRect at whole and half positions; drawImage plain, scaled 1.6 and 0.86, flipped, rotated 0.5 rad; with smoothing on; globalAlpha 0.5; arc and ellipse fills at five sizes; a clip rectangle; strokes of width 1 and 2.
- **Scheduler** (`ref/progress/`): palabras.js in node on 30 scripted sequences with `__PAL_NOW`, each run twice, under `TZ=UTC` and `TZ=America/New_York`: the 20-day run of page 08, a miss, three misses in a row, a slow right answer, `presume`, a story finished twice, an answer at 3:59 and at 4:01 local. The calls and the store after every call.
- **Stories** (`ref/trazas/`): each of the 51 story, picture-story and routine files, played on the old page by tools/juega.py with `Math.random` replaced by Mulberry32 (seed 1) and juego.js's `noise()` buffer filled without it (both injected by the tool; the old site is not changed), every draw fixed: all right, all wrong, right and wrong alternating. Per run: the decisions (`LOG`), the marks, `lost`, the ending, the order of clips spoken. The list of runs is committed. Remake a story's traces whenever its file changes.
- **Screens** (`ref/pantallas/`): phone-size screenshots of v=39: every tab, each sheet, a book page, a Repaso item and its end screen, the level check, the call screen on its stub, the welcome.

**Done when:** every file exists; a second run gives byte-identical pp, sprites, ctx, progress and trazas.

**Result, part C (Nov 19): screens: done, merged to main.** Built by a Sonnet builder; captured again by the orchestrator with no picture changed (about 5 min).
- `node coqui/tool/ref/pantallas/capturar.mjs`. 300 pictures, 150 per phone (`android-412x915` at 2.625, `iphone-390x844` at 3), 38 MB. `index.json` gives each picture's screen, state, URL, steps and the orders it serves. `seeds/` holds the 8 progress states, made by the old palabras.js day by day; builders can reuse them.
- Per phone: welcome 8, map 7, place sheets 14, Palabras 10, word sheet 8, Biblioteca 7, book reader 10, Hablar 7, Yo 11, Repaso 13, level check 6, call 18, voice test 10, story page 21.
- 166 of the 167 English strings of v=39 show in a picture (`strings.json`). "All your words" on the Today card cannot be reached in v=39.
- The old Yo has no About (order 25's About is new). The story mic pictures use a copy of El bizcocho with four clips marked, held in the browser's memory, because no story has speaking turns yet.
- Text is drawn in Inter (the build machine's system font), so line breaks differ a little from a real phone.
- Faults seen in the old app, not fixed: with every built story played the frog sits on place 1 and Yo says "place 1 of 10"; words with no picture pair are never asked in Repaso but still get return dates; a place with stories is open even if earlier places are unfinished; Repaso sets a sign flag for the right picture that nothing draws.

**Result, part B (Nov 19): scheduler, stories, the scenes' own sprites: done, merged to main.** Built by an Opus builder; regenerated by the orchestrator with no file changed.
- Scheduler: `node coqui/tool/ref/progress/make.mjs`. 31 sequences × 2 time zones. palabras.js coverage: lines 59/59, branches 97/98, functions 18/18; all 15 names of `PAL` called.
- Stories: `node coqui/tool/ref/trazas/juega.mjs` (about 40 s). curso.js lists 51 files (32 stories, 11 picture stories, 8 routines); 153 runs, all finish, 0 page errors. The 11 picture stories have no choice, so their three plans are the same (flagged in `runs.json`).
- What "wrong" means, the injections, and what a Dart player must do to repeat a run: `coqui/tool/ref/trazas/README.md`. A touch is made by thing id, not by position. The learner answers 700 ms (virtual) after a choice is ready, so `ms` is checked too.
- Mulberry32 seed 1 starts 0.6270739405881613, 0.002735721180215478, 0.5274470399599522.
- `juega.mjs --states DIR` writes W, V and the camera after every step (for order 06).
- Scene sprites: 937 files in `ref/sprites/escenas/`. Not made by any story: mesa.js line 156 (`puesto` with `W.afuera`), set only by cual-mesa.
- **Not covered by the recordings:** speaking turns (no story file has a `tu_turno` mark yet; order 15's unit tests cover the rule), listen mode, touches before a question ends, the 9 s repeat, memory carried from earlier stories.
- **Bugs found in the old code, not fixed** (the port copies them; page 12): the streak and the day keys are UTC dates of local times, so in US Eastern time the streak reads 0 in the evening and an evening play is filed under the next day; on the nights the clocks change "next morning" is 5:00 or 3:00, not 4:00; `vence` throws on a stored word with no `ear` or `mouth`; frente.js holds two copies of its hide-and-seek helpers; sala.js keeps a working canvas (`bor`) in the sprite cache (marked `scratch`, not compared).

**Result, part A (Nov 19): engine, canvas sheet, sprites of engine.js and kit.js: done, merged to main.** Built by a Sonnet builder; regenerated by the orchestrator with no file changed.
- `node coqui/tool/ref/{pp,ctx,sprites}/make.js` makes each part; `check.js` beside it verifies sizes and hashes. Data: 14 MB.
- `ref/pp/`: the map at `hecho` 0, 3 and 10, the island with no places (with `calls.md`, the mapa.js calls in order), El frente's one state, 200 unit values each of hash, noise, project, unproject, rampOf. Order 07 adds El frente's states by adding lines to `coqui/tool/ref/pp/states.json`.
- `ref/ctx/`: 40 cases, each with the canvas calls a Dart test replays. `ref/sprites/`: 445 sprites of engine.js (20 functions), 469 of kit.js (8 functions), one packed file per function.
- `Math.random` is never called by pixel/*.js, engine.js or kit.js.
- `Math.sin` differs in its last digits between Chrome and Node (up to 7.3e-12 in `hash` and `noise`); the references are Chrome's. The order's 1e-9 holds.
- **Found:** the old scene canvas draws with smoothing ON by default, so a sprite at a fractional position (the frog in a hop) is blurred in the old game. Page 12 says smoothing is on in three places in sala.js only. **Decided:** the new game does not smooth. `Ctx` draws an unscaled, unrotated sprite at its position rounded to a whole pixel (`(x + 0.5).floor()`), nearest neighbour; smoothing stays only where sala.js turns it on itself. Reason: 11-pixel-engine decisions 3 and 4 (whole pixels, no smoothing). He sees it at Gate A.

## Order 06. Scene inventories and frames (orchestrator)

`coqui/ref/escenas/<id>/` for each of the eleven scenes:

- `inventory.json`. For the ten kit scenes: wrap `KIT.escena` to capture what each scene passes it (`cosas`, `lugar`, `CAM`, `heartAt`, `fresh`, the act names); `ESCENAS[id]` alone does not hold them. For El frente, which has no kit: by hand from frente.js (`box`, `hit`, `LUGAR`, `ABAT`, `PERCH`, `HOLE`, `SPOT`). For every scene: each thing's box in the fresh state and in every state its stories reach (read `W` after each step of the order-05 runs, so states set by acts are caught), and the name of its background function (`bg`, `fondo`, `mkPuesto`).
- `positions.json`: every distinct screen position in the scene's story files, review pairs and level-check items (`set` steps with x and y, `cam`, crops), each with where it is used.
- `frames/`: each state, with and without characters.
- `pairs.json`: every review pair and level-check picture that uses the scene.
- `draw-order.md`: for each character, what the old `draw()` draws after it (what covers it), and every clip region.

**Done when:** eleven folders; each inventory's thing ids equal the old scene's; a fresh reader, shown three frames from each with no words, names what is in them.

**Result (Nov 19): done, merged to main.** A fresh reader, shown three frames of each scene with no words (33 frames), named the place, the things and the people in every one. It found these old frames hard to read, for the set designers: camino's dog-and-basket frame (a figure caught mid-tumble), camino without its big tree (the path ends in a flat cut), sala (a yellow shape on the woman's lap with no baby's head), estufa (a pan that seems to float), lago (bread that looks pasted on the dock's face), frente (the small palm stands half on the path). Built by an Opus builder; regenerated by the orchestrator with no file changed; `check.mjs` passes.
- `node coqui/tool/ref/escenas/make.mjs` (about 2.5 min), `check.mjs` (the proofs), `sheets.mjs OUTDIR [scene]` (contact sheets, outside the repo). 18 MB.
- Things / states / positions / pairs / level items / views: frente 14/43/18/12/5/5; balcon 13/50/26/10/9/3; sala 16/27/46/11/12/2; patio 21/73/73/13/11/1; camino 22/9/35/13/4/1; campo 10/7/66/11/4/1; lago 19/10/48/11/4/1; banco 20/49/62/12/4/1; mesa 19/141/26/12/4/1; estufa 17/164/35/12/4/1; nevera 26/87/29/12/4/1. All 128 review pairs and 48 level items are drawn.
- A state = the same background, the same boxes and visibility of set things, the same set keys. Characters and moving props do not make a new state; prop contents (pots, plates, food, shelves) do, which is why mesa, estufa and nevera have so many.
- Frames per state: `full` (the scene's draw, no game signs), `nochar` (no characters), `bg` (the background alone), and each 196 × 216 view.
- No story names a thing its scene lacks. Scene things no story names are listed in each inventory (nevera has twelve).
- For the set designer: boxes that move with the frame counter (El frente's bird and storm cloud, lago's ducks and fish, banco's cart); states reached only by a review pair (frente 3, balcon 7, patio 7, campo 1, banco 1, mesa 9 with the `mkPuesto` background, estufa 12, nevera 3); box functions that throw when their thing is hidden; El frente's roof is a trapezoid in `hit()` and its big palm is still drawn by `bg()` with its own hit rectangle; the story donde-esta-el-pajaro replaces El frente's `wide` view with [30,0,196,216]; the pair `parque.no` of cual-camino is drawn by patio.
- Old-code faults noted, not fixed: `draw()` changes W in frente, lago and banco, so state moves with the frame rate; sala keeps a canvas in W (`W.retrato`).

## Order 07. El frente's set reference and sheet, completed (orchestrator; design)

frente-set.html is one state of El frente: door open, shutters open, a porch lamp lit. Page 11-pixel-engine approved its look. It is not yet everything the stories need.

**Build, in `docs/proyecto/pixel/`:**
- frente-set.html takes its state from the address and draws every state in `ref/escenas/frente/`: the door shut, half and open; the shutters shut and open; the lights on inside (page 08: "the lights come on inside and stay on: the shutters and the door both glow"; the old scene has no porch lamp, so the lamp goes). Sky enough for the storm cloud.
- The things the stories touch or name that the set lacks: the sun; the big palm (story 3's hiding places), put where it covers no touch box (decision 14 took the first palm out for that); the small palm and the birdhouse if the inventory has them in the background.
- `frente-sheet.json`, every part of page 12 section 5.
- Check the views: at `S = 26` the house is wider than the 196 window. Every view in the sheet must show what its stories need without zoom; where one cannot, move the origin (decision 9 allows it), not `S`.

**Done when:** every state rendered; each of the 12 pairs of cual-frente told apart by a fresh reader with no words; a fresh reader names everything in the wide view; nothing green over a touch box; order 05's script has added each state's raw pixels to `ref/pp/frente/`.

**This is design.** It needs a session that renders and looks. If the orchestrator cannot settle a look question from pages 03, 09 and 11-pixel-engine, it asks Salim with two pictures side by side, before order 14.

**Result (Nov 19): done, merged.** Designed by an Opus agent in three rounds; the orchestrator looked at every round's pictures; three fresh readers saw them with no words.
- `docs/proyecto/pixel/frente-set.html` (states from the address), `set-kit.js` (the helpers the set added), `frente-sheet.json` (made and checked by `frente-sheet-make.js`), `frente-preview.html` (a dev tool: the old sprite layer on the new set, through the sheet).
- State parameters (the builder's `setKey`): `door` shut, half, open; `win` shut, open; `lights` 0, 1; `sky` day, storm, storm2, rain, dusk, sunset; `hide` 0, 1; `rustle` none, palma, casa, todo with `side`. 25 baked states, all in `coqui/ref/pp/frente/`.
- In the set: the house, door, window, big palm, small palm, birdhouse, sun. In the sprite layer: abuela, the frog, the bird, the cloud. The cake stays in the HUD. No porch lamp.
- Views: `wide`, `casa` and story 3's view at zoom 1; `puerta`, `ventana`, `cuadro` at zoom 2, as in the old game (see page 12 section 5, changed the same day). Each review and level picture has its own centre and zoom in the sheet.
- What a learner would notice against the old picture: the 30° view; a smaller, narrower house (so that story 3's view holds both palms, the house and the birdhouse); storm, rain, dusk and sunset are baked into the set and characters are no longer dimmed; an open door shows a room (floor and back wall), lit when the lights are on; the potted plant and the old sky clouds are gone; a change of zoom cuts.
- Readers: every review pair told apart at a glance after round 3 (the "cierra" picture went back to the old idea: a wide door leaf across half the doorway, hiding half of abuela); all eight story sequences followed; the 25 states sorted correctly by door, window, lights, time of day and birdhouse. Their remaining doubts are in the pairs' own design, the same as in the old game (for example sí / no shown by arrows; hola and adiós differing in four things at once).
- Bake: 46 to 84 ms per state in headless Chrome once warm; a first bake in a fresh page is slower (about 130 to 240 ms). The Dart number is order 14's to measure.
- Not solved: an open door shows no door leaf (with this camera a leaf opened inward is hidden behind the wall); the frog peeking from behind the half door loses 2 px on his right.

---

## Order 10. The Pixel Plays engine in Dart (builder, coqui_pixel)

Page 11-pixel-engine, build step 1. Page 12: sections 1, 2, 4, 6, 7.

**From:** docs/proyecto/pixel/pp-engine.js (all but `fit()` and the canvas lines); from pixel/mapa.js the palette `C`, `toneOf`, `ST`, and the helpers `shade` to `person`.

**Build:** `PpEngine`, `PpBuild`. Globals become fields. `STILL` is the `still` argument. The caller reads `pix`. `toInt32`, `imul` with tests. The Pixel Plays MIT notice stays at the top of the engine file, word for word, with "Changed for Coquí" under it.

**Done when:**
- The 200 unit values match: `project`, `unproject`, `rampOf` exactly; `hash`, `noise` to 1e-9.
- The map's island with no places (ground, `slabSides`, `growGrass`, `decorate`), built in a test with mapa.js's calls in order, differs from the same in JavaScript in no more than 0.5% of pixels, on vm and chrome. (Order 05 adds this picture to `ref/pp/`.) Report both numbers.
- If order 07 is merged: every state of El frente's set, the same test.

**Stop if:** more than 0.5% differ after the porting rules are checked. Report the first twenty differing pixels with both colours. Do not tune constants.

**Result (Nov 19): done, merged to main.** Built by a Sonnet builder; the parity tests were run again by the orchestrator on vm and chrome (40 tests each, all pass).
- Unit values: `hash`, `noise`, `project`, `unproject`, `rampOf` all match the 200 references exactly, on vm and chrome.
- The island: 0 of 122,880 pixels differ from the JavaScript, on vm and chrome (`pix`, `zb` and `kinds`).
- El frente's one state (added to this order as a test of the building helpers at S = 26): 0 of 51,840 pixels differ, vm and chrome.
- An extra scene the builder added for the functions the island and El frente do not reach (`growTree`, `drawLeaves`, `box`, `person`, lit windows, the arrow and dots): 0 of 22,400 pixels differ; one depth value in 22,400 is one float step off.
- `toInt32` and `imul` are public in coqui_pixel, tested against node.
- The island, El frente's set and the extra scene are test-only code under `test/support/`; nothing of the map is in `lib/`.
- A colour is `[r, g, b]`; the palette is `b.C`; `project` returns a record `(sx, sy, d)`.
- Old-code quirks, ported as they are: `sx | 0` draws a point just left of or above the picture on column or row 0; frente-set.html's curtain uses `%` on a negative number.
- Open: pp-engine.js carries a one-line attribution, not the MIT text. Order 11 adds the full licence text to the Dart engine file.

## Order 11. Sprites and the software canvas (builder, coqui_pixel)

Page 12: sections 1, 4, 6, 7. **From:** historia/engine.js, all of it.

**Build:** `Sprite`, `Buf`, every `mk*`, `RP`, `sky`, `grass`, `shadow`, `face`, `coqui`, `bubble`, `GL`, `GC`, `fr`. `Ctx`: a transform stack (2 × 3 matrix); alpha blending in 0–255 steps; drawImage by inverse mapping, nearest neighbour at pixel centres, bilinear when `smoothing` is on; arc and ellipse fills by scanline with 4 × 4 coverage; a clip stack of rectangles and one path mask; `snapshot`.

**Done when:** every sprite of engine.js in `ref/sprites/` is reproduced exactly, every pixel, on vm and chrome. Canvas sheet: fillRect, plain and flipped drawImage, clip: exact. The other cases: no more than 3% of a tile's pixels differ by more than 24 in any channel. Report every case's number.

**Stop if:** a sprite differs in one pixel. That is a porting error, not a tolerance.

**Result (Nov 19): done, merged to main.** Built by a Sonnet builder; the package's tests were run again by the orchestrator (184 on vm, 179 on chrome, all pass) and `test_all.sh` on merged main.
- Sprites: 445 of 445 of engine.js reproduced exactly, every pixel, on vm and chrome, by replaying each recorded call.
- Canvas sheet: all 40 cases pass. 25 are exact (every fillRect, plain, scaled and flipped drawImage, the clip rectangles). The rest are under the 3% limit; the worst is a 1-pixel stroke at 2.05%.
- `SpriteLib` holds what were engine.js's globals (the sprite cache keyed as before, `GL`, `GC`); one per game. The stateless makers keep their old names at top level.
- `Ctx` copies the browser's integer blending, which is why the exact cases are exact. Smoothing is off by default; an unscaled, unrotated sprite lands on `(x + 0.5).floor()`.
- The full MIT text of Pixel Plays is at the top of `pp_engine.dart` and in `LICENSE-pixel-plays.txt`, fetched from the Pixel Plays repository.
- For order 12: patio.js calls `setLineDash`, which `Ctx` lacks; `translate`, `scale`, `rotate` take doubles.
- Old-code quirks ported as they are: `bubble` leaves the fill colour transparent; `pointer()` has terms that always add 0.

## Order 12. The scene kit, the signs, the frame (builder, coqui_pixel)

Page 12: sections 1, 4, 5, 6, 7. **From:** historia/escenas/kit.js, all of it; from historia/juego.js: `hand`, `heart`, `star`, `spot`, the twinkle and glow, the answer bubbles (`respDraw`, `BUBL`, `bx`), `frogBox`, the frog's draw (juego.js line 48 on), the view and its slide (`cam`, `camGo`).

**Build:** the kit: `escena` as a base class giving `box`, `hit`, `handAt` and the shared acts; the bird; `FAM`, `mkPersona`, `mkBebe`, `mkAbuelaS`, `mkPerro`, `mkCesta`, `tarjeta`, `mano`. A sheet reader: `<id>-sheet.json` to things, spots, views, `remap`, clips, front, shadows. The camera of page 12 section 5 (a 196 × 216 window, whole pixels, no zoom). The frame recipe of section 5 as one function. `clipTo(thing, face)`: the polygon of that face on screen as the clip.

**Done when:** the kit's sprites in `ref/sprites/` match exactly; tests for the sheet reader, the camera (a view at each edge stays inside the picture; `camGo` passes only whole pixels), `clipTo` on a made-up box; `hit` on a made-up scene returns the same ids as the old `hit` for 50 points (expected values from the old function in node).

**Result (Nov 19): done, merged to main.** Built by a Sonnet builder; the package's tests were run again by the orchestrator (400 on vm, 393 on chrome) and `test_all.sh` on merged main.
- Kit sprites: 469 of 469 exact on vm and chrome. `hit`, `box`, `handAt` and the shared acts equal kit.js run in node (200 `hit` results, 21 act runs).
- Signs against the old code drawn in headless Chrome: `hand`, `heart`, `star`, `spot`, `twinkle`, `bub`, `bang`, `frog`, `respDraw`, `drawSigns` and the hand over the view at both zooms: 0 pixels differ. The bird: 18 pixels of 57,344 differ, all in its one rotated pose.
- The camera has zoom 1 and 2 (page 12 section 5 as changed on Nov 19): a same-zoom `camGo` slides in whole pixels with the old positions rounded; a change of zoom is a cut with the old number of steps. `pictureToDisplay` and `displayToPicture` are inverse on the pixel grid.
- `drawFrame` is the frame recipe as one function. It takes a `BakedSet`, which holds everything a bake leaves behind (pictures, depth, ground, kinds, static shadow, tufts, leaves), about 780 KB a state.
- `clipToWorld` clips to a polygon of world points, which is how the sheet gives clips.
- `Sheet.parse(text)` reads `<id>-sheet.json`: things, spots, frames, points, views, remap (by kind: point, cam, crop, x), pictures, level pictures, clips, front, shadows, setKey, code. Against the real frente-sheet.json: every recorded box, view, crop and remap entry is reproduced; screen points within the sheet's own rounding (0.005).
- SFX: all 18 names make the same calls as juego.js. `Sfx.lluvia` and `calla` keep no state, so `ClipPlayer.loop` must be idempotent (order 19 checks it).
- `Ctx.setLineDash` added (patio.js). `SceneHost.lib` added (the sprite cache).
- Order 10's one-state El frente test now runs from a fixture of its own (`frente_nov14.dart`), since order 07 replaced that state.
- Not in the sheet as data: the heights at which each character casts its shadow (only as text) and the shadow direction (.9, -.1 in frente-set.html). Order 14 ports them from frente-set.html.

## Order 13. The map (builder, feature_map)

Page 11-pixel-engine, build step 2, decisions 5 to 8. Page 12: sections 1 to 4, 6, 7.

**From:** docs/proyecto/pixel/mapa.js and mapa.html. From historia/app.html: `hecho`, `abierto`, `aqui`, `jugados` (lines 185 to 256), the Today card (`plan`), the chips (`hud`), the place sheet (`sheet`, `lugar`), as page 09 describes them.

**Build:**
- The map: buffer 256 × 480, `S = 8`, `originY = 36`; constants exactly as mapa.js. `bake` once, off the first frame.
- States from `Services.progress` and `Services.course`: a place is open by app.html's `abierto`; done when every one of its stories is `played`; current by `aqui`. Redraw on `progress.changes`.
- Tap: `stopAt` within 22 buffer pixels. Open place: the frog hops there (decision 8), then the place sheet. Locked: the sheet says so. Opens scrolled to the frog.
- The hop sound: `clips.tone(320, dur: .07, wave: 'square', vol: .025, toHz: 520)`. Still when `reduceMotion`.
- Around the picture, widgets from coqui_ui: the chips, the Today card with the green play button, the place sheet. A story row calls `nav.go(StoryRoute(id))`.
- The dev entry shows bake ms and the slowest frame's ms in a corner chip.

**Done when:**
- Golden tests: with `hecho`, `abierto`, `aqui` set as `ref/pp/` records for the three demo states, the frame at time 0 differs from each reference in no more than 0.5% of pixels.
- Widget tests: tap an open place (hop, then sheet); tap a locked place; finishing a place's last story on the fake store adds its flag and moves the frog; the Today card names the next story.
- A fresh reader, shown the three states with no words, says which places are open, done and locked, and where the frog is.
- Then, on Salim's phone (the orchestrator sends the link with the seven steps of page 00 done): bake under 500 ms, frame under 8 ms, read off the corner chip. Over: report the numbers. Do not change the look.

**Result (Nov 19): built and merged to main; the reader's look and the phone numbers are open.** Built by a Sonnet builder; its tests were run again by the orchestrator (47 on vm, 47 in Chrome) and `test_all.sh` on merged main.
- The map frame at time 0 differs from the JavaScript in 0 of 122,880 pixels in each of the three states, on vm and in Chrome.
- Tested: tap an open place (hop with the old tone, then the sheet); tap a locked place; finishing a place's last story adds its flag and moves the frog; the Today card names the next story; a story row opens the story; reduced motion stands still; the first frame is empty and the bake follows; the map opens scrolled to the frog.
- In headless Chrome on the shared build machine (release build): bake 376 to 769 ms, mean frame 3.4 to 4.9 ms, slowest frame 10 to 38 ms. Over the limits there; the real numbers are his phone's, at Gate A. The look was not changed.
- The review entry's title on the Today card is `CoquiLabels.reviewTitle` in coqui_ui (a fixed label of v=39, like the tab names). The map module has one marked line where it is passed; the shell order wires it.
- Not ported: v=39's sideways two-column layout (the app is portrait).
- Around the island is mapa.html's dark page colour with dots, not the old blue checker: the map is new art.
- Old quirks ported: once every built story is played the frog and chip sit on place 1; the frog stays squashed through a trip of several hops; the bake runs every place twice.
- For the shell: keep the map tab alive (a rebuilt tab bakes again, about half a second); draw the tab bar over the tab.

## Order 14. El frente in Dart (builder, coqui_scenes)

Page 11-pixel-engine, build step 3. Page 12: sections 1 to 7. Step b of section 5.

**From:** docs/proyecto/pixel/frente-set.html and frente-sheet.json (as order 07 left them); historia/escenas/frente.js; `coqui/ref/escenas/frente/`.

**Build:**
- `buildSet`: frente-set.html, call for call, its states as inputs; `setKey`.
- The scene: frente.js line for line, minus `bg`. frente.js was written before the kit: port it as it is; do not move it onto the kit. Every screen position replaced by the sheet's spot, view or clip of the same name.
- `PictureSource` for coqui_scenes: a still host; bakes cached by scene and `setKey`; `warm`.

**Done when:**
- Every state of the set differs from `ref/pp/frente/` in no more than 0.5% of pixels.
- Every thing's touch box, drawn on a frame, contains the thing.
- All 12 pairs of cual-frente draw through `PictureSource`.
- A bake takes under 150 ms in a release web build on a desktop. Report the number. Over: report, do not redesign.

**Stop if:** frente.js holds a screen position the sheet has no name for. Report it with its line. Do not place it.

**Result (Nov 19): done, merged to main.** Built by an Opus builder; its tests were run again by the orchestrator (205 on vm, 204 in Chrome) and `test_all.sh` on merged main. One line was changed by the orchestrator at the merge (the still host's `preload`, after order 02b changed the contract).
- The set: all 25 states equal the JavaScript references exactly (0 of 51,840 elements differ in `pix`, `zb` and `kinds`), on vm and in Chrome.
- The 22 sprites frente.js makes for itself: exact.
- The whole picture against `frente-preview.html` in headless Chrome: 513 pictures (the 33 review and level pictures, and 480 moments at rest from all 15 recorded runs): none has a pixel differing by more than 24 in a channel; 380 are bit-identical; the other 133 differ only along clip edges. 91 of them are a committed test.
- No position in frente.js lacked a sheet entry.
- Touch boxes: every pixel a set thing draws lies inside its box in all 25 states (the small palm puts 3 of 912 pixels outside when it rustles to one side). `hit` at each box's middle gives the thing's key, except where the old test order says otherwise (listed in the test with reasons).
- `ScenePictures` is the picture source: all 24 pair pictures and 9 level pictures draw; a scene not yet converted says "not converted yet".
- **The pattern for the next ten scenes** (in the package's AGENTS.md): `set_kit.dart` (shared); per scene `<id>_set.dart` (the set, call for call), `<id>_places.dart` (every place, read from the sheet), `<id>.dart` (the old scene file line for line, as a `SetScene`); the sheet copied into `assets/sheets/` by `tool/make_sheets.dart`; the same six tests.
- Bake time in a release web build, on the build machine while other builders loaded it (load average about 15): median 86 to 209 ms, slowest (the first bake, which also builds the ground) 289 to 703 ms. Over 150 ms in the loaded runs. To be measured again on a quiet machine and on his phone.
- Decided after the report: shadows are cast only while a character is more than half faded in (as the preview the readers saw does); the cake plate's touch area is tested in display coordinates, so it matches the plate at either zoom; the frog's shadow on the porch stays at ground height, as in the preview. Order 14b applies them.
- `PictureRef` gets a `name`: abuela.si and cierra.no share scene, state and view and differ only in their crop.
- Old faults ported: `draw()` moves the clouds, so state changes with the frame rate; `come` and `regala` throw when abuela is at the step.

## Order 15. The story runner and play screen (builder, feature_story)

Page 12: sections 1 to 7. **From:** historia/juego.js (all but what orders 12 and 18 take), historia/index.html, docs/hablar/01-decisiones.md, page 09 (the lesson frame, the mic states), page 07 ("A decision, as the engine runs it").

**Build:**
- The runner reads the raw story map. Take the kinds of step from juego.js's step function (`paso`, about lines 319 to 336): a bare string is a step (say that clip); an object is the kind its key names there. Fail loudly on anything else. `$name` filling, `as`, `other`, `alterna`, `pick`, `lock`, `noretry`, `bien`, `resp`, the memory between stories (`coqui.juego.mem`, `coqui.juego.ult`, in this feature's storage space).
- It implements `SceneHost`. `Clock`, `Rng`, the scene, `ClipPlayer`, `SpeechListener` come in through the constructor. Every position read from a story file goes through the scene's `remap`.
- Speaking turns exactly as docs/hablar/01-decisiones.md: its recogniser settings, its matching, its limits, its test switches (as constructor options).
- The play screen: `PixelView` on the display picture; captions and speech bubbles as Flutter text over it (Spanish only; the TXT setting); the dots; the mic button and its states; close; at the end "again" and "next". Full screen, tab bar hidden.
- Listen mode: the story straight through, nothing to touch; `progress.listened(id)` at the end.
- At the end of a played story: `progress.storyFinished(...)`. Nothing the learner reports himself.
- A player with no screen, as a library function `play(story, plan, draws, seed)` returning a trace in the shape of `ref/trazas/`. The orchestrator wraps it as `coqui/tool/juega.dart`.

**Done when:** on a fake scene, a unit test for every step kind, and the cases of habla_motor_check.py (every turn heard, every turn missed twice, the mic off, first play with no turn). With El frente merged: the traces of stories 1 to 3 are reproduced: decisions, marks, `lost`, ending, order of clips.

**Result (Nov 19): done, merged to main.** Built by a Sonnet builder; its tests were run again by the orchestrator (197) with `flutter analyze` and the boundary check on merged main.
- `StoryRunner` is juego.js ported line for line, on a virtual clock (timers fire by due time, then creation order). Step kinds, from juego.js lines 320 to 336: string, say, wait, cam, dots, set, if, act, ask, decide, elige, draw, reparte, calc, recuerda, cost; anything else throws.
- **All 153 recorded runs are reproduced whole**, to the millisecond, with the old scenes' acts replayed from a recording of what each old scene did (no story is independent of its scene's acts, so the builder recorded them from the old page: `tool/ref/record_acts.mjs`).
- **With the real El frente** (5 files × 3 plans): decisions, marks, steps lost, ending, the order of clips, the steps, the choices, the touches, the random draws and the memory are equal in all 15. Two runs are equal whole. The other 13 differ only in times and in the number of hop sounds, for two reasons that come from the new set, not the runner: the `casa` view is now the same window as `wide`, so `camGo("casa")` no longer slides (about a second shorter where a story used it); and the frog's new spots are nearer, so he takes one hop fewer in some moves (460 ms each). **Accepted**: the game is the same; the pacing is a little quicker in those places. Order 40 compares the other scenes the same way: everything but time and hop sounds.
- Speaking turns: every case of habla_motor_check.py as a test. The real listener path is tested with the settings of docs/hablar/01-decisiones.md.
- The play screen: the frame, the dashes, captions, the speech bubble, the mic disc in its five states, the end title with Play again, Next story and Map; Listen mode; a tap is mapped back to the picture and hit-tested by the scene.
- The no-screen player is `play(...)` inside the feature; its tools are `tool/juega.dart` (on a stand-in scene) and `tool/differential.dart`. There is no `coqui/tool/juega.dart`: a tool outside the package may not import a feature's `src/`, and the real scene needs Flutter's assets, so the comparison with the real scene runs as the feature's test.
- For the scenes to come: a `set` step's positions written as two-number lists (`respEn`, `casa`, `bolsa`: none in El frente's stories) are not remapped yet; each scene's sheet must name them. Scenes that draw random numbers need the app's `Rng` (El frente draws none).
- Follow-up decided: the story's clock stops while the app is in the background, so no burst of timers on return.
- Old faults ported: a second `camGo` during a slide leaves the first one's wait unresolved; `ask` with `bien: false` still says the default praise; in Listen mode an `elige` takes the first option.

## Order 16. Progress (builder, coqui_progress)

Page 12: sections 1, 2, 6, 7. **From:** historia/palabras.js, rule for rule. Page 08, "Word records and the scheduler".

**Build:** `ProgressStore` on a `KeyValueStore` and a `Clock`. The JSON unchanged, unknown keys kept. `export`, `import`.

**Done when:** all 30 sequences of `ref/progress/`, in both time zones, give the same store after every call (numbers compared as numbers), on vm and chrome.

**Result (Nov 19): done, merged to main.** Built by a Sonnet builder; the four runs and `test_all.sh` on merged main were run again by the orchestrator (all pass).
- `PalabrasStore(KeyValueStore, Clock)`. `bash tool/test_zones.sh` in the package runs the suite four times (UTC and America/New_York, each on vm and chrome): 654 tests on vm, 569 on chrome, per zone.
- Each run replays 30 sequences and 361 calls from `ref/progress/` (the sequence that calls `PAL.rec` is skipped: no page calls it), comparing the whole store, the return value, the saved text and `export()` after every call.
- The members that live in app.html, not palabras.js (`markRead`, `hasRead`, `add`, `added`, `played`, `setting`, `setSetting`, `levelResult`, `minutes`): the page's own code was cut out by pattern and run in node against the real palabras.js; 8 more sequences and 163 calls per zone are replayed the same way.
- `add` trims as JavaScript does, keeps duplicates, has no length cap. `markRead` writes the clock time once. `heard` does not save, exactly as `oida` does not.
- `import(json)` is new (order 43 uses it): valid JSON replaces the store; text that is not JSON throws and leaves the store untouched.
- The `habla` setting is tested by the page with `!== 0`, so it can be 0, 1 or absent; the feature that shows the switch must apply the same test.
- The old faults are ported as they are (the streak and day keys, the 5:00 and 3:00 mornings on clock-change nights, `vence` throwing on a word with no `ear` or `mouth`, `reset` dropping unknown keys).

## Order 17. Content (builder, coqui_content)

Page 12: sections 1, 2, 6, 7. **Build:** `CourseCatalog` over a `fetch(String path)` given by the shell. Loads `datos/*.json`, `cuentos/*.json`, `libros/*.json`, `audio/ready.json`, `audio/marcas.json`. `pairFor` and `linesWith` as `pares()` and `oidoEn()` in app.html.

**Done when:** all 62 story files and 43 books load; every clip a story names has marks; `pairFor` finds each of the 128 words; `linesWith`, for ten words, returns the lines `oidoEn` returns (expected values from node).

**Result (Nov 19): done, merged to main.** Built by a Sonnet builder; `bash coqui/tool/test_all.sh` run again by the orchestrator on merged main (passes).
- `ContentCatalog` over `Future<String> Function(String path)`. 49 tests on vm, 33 on chrome. Expected values come from the old functions run in node (`bash tool/make_fixtures.sh` in the package; byte-identical on a re-run).
- 62 story files and 43 books load, each equal to its file. The 8 routines have no book.
- 1,582 distinct clips are named by the story files (2,141 mentions); every one has marks and a `ClipInfo`. They equal ready.json's clips.
- `pairs` has 128 items and equals the old `CU.items`. `pairFor` finds each of the 128.
- `linesWith` matches `oidoEn` for the ten words, and for all 156 words the builder also tried, with all stories played and with place 1 only.
- `pairFor` takes the exact word first, then the normalized form: bebé/bebe and tú/tu are different words that normalize the same.
- A clip's speaker and text are known once a story that has it is read; before that `clip(id)` gives marks and url with empty text. The url is `audio/<id>.mp3?v=<ready.json's v>`, as juego.js builds it.
- Old behaviour, ported: "Heard in" for bebé also returns lines of the verb bebe (the accent is dropped); the same for tú and tu.
- juego.js line 103 wrote the line "Ahora tú." in code. Done as order 17b (merged): `fijos.json` has `lineas` (clip id to speaker and text, found by `export_datos.mjs` from the old code), and `clip(id)` uses it until a story that has the clip is read. It is the only such line in juego.js, cual.js and llamada.js.

## Order 18. Audio, storage, haptics, speech (builder, coqui_platform)

Page 12: sections 1, 2, 6, 7. **From:** historia/juego.js, "sound: effects, and the recorded voice", and its speech code (`habSR` on); habla-prueba.html; docs/hablar/01-decisiones.md.

**Build, on the routes order 00 chose:**
- `ClipPlayer`: a clip from its start mark to its end mark; `preload`; `tone`, `noiseBurst`, `loop('rain')` with today's numbers. On the web the tones are made live with Web Audio. In a phone build they are rendered once to short buffers by the same formulas.
- On iPhone web: the audio session type order 00 found to work; resume the audio context after every recognition (01-decisiones, "iPhone guards").
- `SpeechListener` on `speech_to_text`, with the language, alternatives and limits docs/hablar/01-decisiones.md gives. Do not choose a language. `available()` false when there is no recogniser, no network, or permission is denied.
- `KeyValueStore` per space; `Haptics` (8 ms tick; nothing on iPhone web); `AppInfo`; the import of the old keys (`coqui.palabras.v1`, `coqui.juego.ult`, `coqui.juego.mem`, `coqui.leer.tam`), read straight from the browser's storage, never deleted.
- All browser code behind a conditional import.

**Done when:** a dev screen plays ten lines back to back with gaps within 60 ms of the pauses asked for; a unit test shows every `SFX` name reaches the audio layer with the old code's numbers; `flutter build apk --debug` passes. How it sounds is Salim's to judge at Gate A.

**Result (Nov 19): done, merged to main.** Built by an Opus builder; the tests and the dev check were run again by the orchestrator.
- **Started before the phones reported**, on order 00's desktop result (the plugin leaves about 215 ms between lines, Web Audio about 6 ms). On the web everything plays through Web Audio by interop, speech goes straight to the browser's recogniser, storage is localStorage. `just_audio`, `speech_to_text`, `shared_preferences` are used only in phone builds. The iPhone audio session type is one constant, `iosAudioSessionType`, null until the tester's result.
- The dev check (`node tool/dev_check.mjs` in the package): ten lines back to back, every gap within 10.3 ms of the pause asked for, measured on the output; all 18 SFX fire and make sound; a recognition attempt ends cleanly at 6 s in headless Chrome.
- 97 tests on vm, 72 in Chrome. Every SFX name's calls equal juego.js's exactly, from juego.js run in node on a recording audio context (`node tool/juego_sonido.mjs`). In phone builds each tone is rendered once to PCM by the Web Audio formulas; against Chrome's own rendering the difference is under 1%.
- `Coquí Android` run 44569491685: the apk built and installed twice. The app does not use the package yet, so this proves the plugins link, not the phone code.
- Old keys: `coqui.palabras.v1` is `storage.progress`; `coqui.juego.ult` and `.mem` are `space('juego')` keys `ult` and `mem`; `coqui.leer.tam` is `space('leer')` key `tam`. A space is the prefix `coqui.<name>.`. Nothing is deleted.
- `Haptics.unlock()` does nothing (the UI plan's unlock pattern is not built). `AppInfo.installed` is true in a phone build. `msToSound` is null when no speech started (callers use `?? 0`). `stop()` stops clips only.
- For order 15: `preload` cannot say which clips failed, and juego.js falls back to timed lines when a clip is missing; the contract needs a way to tell.
- Old quirks ported: a tone bypasses the mute button once scheduled; the clip time limit uses the clip's length plus 1 s.
- Only a real phone can show: how the tones sound through the plugin, speech_to_text on Android and iOS, the iPhone guards, haptics.

## Order 19. The call connection (builder, coqui_platform)

**From:** historia/llamada.js (`precarga`, `startSession` and its options, the handlers, `installStub`); notas/llamada-decisiones-1.md; page 05, "How the page and Danny talk".

**Build:** `CallSession` for the web: the same ElevenLabs JS client at the same pinned version, loaded the same way, `connectionType: "websocket"`, the same agent id and variables, through JS interop. `available` false in phone builds, and wherever `AppInfo.callsAllowed` is false.

**Done when:** on the scripted fake, events arrive in the order llamada_check.py expects; the web build loads the client without error on the test site. No real call: it needs Salim's microphone and costs his credits.

**Result (Nov 19): built and merged to main; the real library load and a real call are unverified until the test site.** Built by an Opus builder; its tests were run again by the orchestrator (136 on vm, 84 in Chrome).
- `createCallSession` on the web: `@elevenlabs/client@1.25.0` from the same address, loaded as `precarga` loads it; `startSession` with the same agent id, `connectionType: "websocket"`, the six variables in llamada.js's order (job, minutes and opening from `CallBrief`); `show_picture` answers "shown" and becomes a `Tool` event; the callbacks become `Connected`, `AgentLine`, `Heard`, `Mode`, `CallError`, `Ended`.
- `available` is false in phone builds, where `callsAllowed` is false, and on the web once the library failed to load (the next read tries again).
- `CallStub` is `installStub` ported: the same steps, pacing and `?stub=` options. Against the old stub run in node it gives the same callbacks at the same ms in all 8 scenarios of llamada_check.py. Its Spanish test lines are in an asset made from llamada.js, not in code.
- No call was placed. The library's own code (the npm package, served locally) loads through the same path and `startSession` is a function. The real address is blocked from the build machine.
- **To check on the test site, with no call started:** on Hablar with an open call card, in the console: `typeof window.ELConv?.startSession + ' ' + window.ELConvError` must print `function undefined`.
- `ClipPlayer.loop('rain', ...)` is idempotent on the web and in phone builds (tested).
- Order 19b (done, merged): `CallSession.start` throws `CallStartError` with a `kind` (microphone, library, failed, unavailable) whose text is the old `<Name>: <message>`; the session resumes the sound context when a call ends or fails to start (the old page reloaded on leaving a call; this app does not).

## Order 20. Shared look (builder, coqui_ui)

**From:** the `<style>` of historia/app.html, cual.html, index.html; notas/ui-decisiones-1 to 3; pages 09 and 10; `ref/pantallas/`.

**Build:** colour and type tokens with v=39's exact values; the buttons; the bottom sheet; the tab bar with the raised Mapa disc; the lesson frame; the Ear and Mouth meters; the word card; the fade under lists; `PixelView` as page 12 section 3. A gallery dev screen.

**Done when:** a fresh reader compares the gallery with `ref/pantallas/` and finds no difference a learner would notice, or lists them. `PixelView` tests: a 196 × 216 picture in a 412-wide screen at pixel ratio 2.625 is drawn at 5 device pixels a pixel, unsmoothed, on whole device pixels; it repaints when its `repaint` fires and not otherwise.

**Round 2 (Nov 19), after the fresh reader's first comparison, merged to main; a second reader is comparing.** The reader found what the builder's own comparison had missed, all fixed in round 2:
- Weights 500 and 600 drew as regular and bold drew too heavy: the web build carried only Roboto Regular. The app now ships Roboto Regular, Medium and Bold itself (from the Flutter SDK's own fonts, Apache 2.0 licence beside them), one look on every platform; CSS 600 uses Bold, as a browser would choose among those three.
- 1-pixel borders were a device pixel too thick. Borders now follow what Chrome does (the CSS width floored, then snapped), through one helper.
- The shelf's "Listen" button missed a `max-width: 420px` rule of the old CSS; its padding and gap now match to within 1 px.
- The reader's Back and Next row is equal halves; the last page's row and a story's end pair are there too; a disabled Back has the old colours exactly.
- Repaso's answer screen: the unchosen picture is dimmed (55%, measured on the old screenshots), and the tick badge has the old size and place.
- `CoquiLabels`: the app name, the five tab names, "¿Cuál?" and "Repaso".
- Left as they are: bold words are a little narrower than in the old screenshots (Roboto against Inter); baselines sit up to 3 device pixels off for the same reason.

**Round 3 and integration 1 (Nov 19), merged to main.** A second fresh reader confirmed round 2's fixes and found a smaller set; a fresh builder fixed them, and two integration builders brought the other packages in line. `test_all.sh` passes on the merged tree.
- Roboto ships in four weights from one source (`@fontsource/roboto` 5.3.0, SIL OFL 1.1, converted to .ttf): 400, 500, 600, 700 each have their own file. Semibold text is now within 1 to 4% of the old screenshots' stem width (it was 13 to 18% heavier).
- Ligatures are off in every text style: "fi" drew joined, so "first" read as "fırst". In an app for learning to read, every letter is plain.
- The streak's flame is a drawn icon. As an emoji, Flutter on the web would fetch an emoji font from Google's servers. A test fails on any character under `lib/` that the shipped fonts lack; the gallery's screenshot run fails on any request that leaves the machine (378 requests, none left).
- `showCoquiSheet` opens a sheet above everything, the tab bar included, as v=39's scrim covers the page. The map's place sheet and Yo's sheets use it.
- The review's end grid follows cual.js's rule (2 columns on the narrow phone, 3 on the wide one); a story's end title hangs 16 px under the picture at every height.
- **Contract changes:** `PictureRef` has a `name` (`<word>.si`, `<word>.no`, `nivel.<word>.<index>`); `PictureSource.of(ref, {width = 196, height = 104, animated})` takes the picture's size in picture pixels and has no `scale`.
- In coqui_scenes: a picture is found by its name in the sheet; a level-check cell (96 × 106) is always drawn at zoom 1, centred where its review picture is centred (at zoom 2 a cell is smaller than the door or the window); **a scene not yet converted shows its old pictures**, the 415 PNGs order 06 saved (half a megabyte), until it is converted, when they are removed.
- The book reader's frame and line, and the shelf row, were removed from coqui_ui: Biblioteca has its own, and nothing else uses them.
- The 1-pixel strip at the edge of screenshots taken at 412 × 915 at 2.625 does not appear at a whole-pixel phone size.
- Not re-read by a third fresh reader: the readers compare the real feature screens at Gate A instead.

**Result (Nov 19), round 1: built and merged to main.** Built by a Sonnet builder; `test_all.sh` run again by the orchestrator on merged main.
- 137 tokens (40 colours, 49 metrics, 6 shadows, 42 text styles), each with its CSS file and line. 61 tests. A gallery (`tool/dev_main.dart`, 17 sections) and `tool/shots.mjs` to capture it on both phone sizes.
- Against the old screenshots, in device pixels: most edges identical (chips, the Mapa disc, word cards, stat cards, the lesson dashes and start disc, sheet title); the rest within 1 to 2 px.
- `PixelView`: 196 × 216 in 412 at 2.625 is 980 × 1080 device pixels, every device pixel equal to its picture pixel; it repaints only on its tick.
- Text is the platform default (Roboto on the web and Android); the old screenshots were taken in Inter, so widths differ a little. No rule in the old CSS uses Pixelify Sans; a style helper for it exists with ligatures off.
- **Decided:** a word card's picture is drawn at a whole-number scale, centred on the card's white, never stretched (v=39 stretched it by about 2.47). It is 392 × 208 device pixels on both reference phones, with about 16 CSS px of card showing each side on the Android size and 20 on the iPhone size.
- The tab bar takes its own five items (`CoquiTabs`); `FeatureTab.icon` cannot carry v=39's drawn icons and is not used. The shell maps by tab id.
- There is one light look and the dark lesson look; the old CSS has no dark mode.

## Orders 21 to 25. The features (builders, one each)

Page 12: sections 1, 2, 3, 6, 7. One package, fakes only, a dev entry. Screens rebuilt from coqui_ui to look and behave as v=39 (`ref/pantallas/`). Every English string copied from the old page. Each check of the old script named becomes a widget test; where there is no script, write one test per behaviour of the old function, list them in the report.

| Order | Package | From | Checks | Notes |
| --- | --- | --- | --- | --- |
| 21 | feature_words | app.html: `palabras`, `extra`, `oidoEn`, `vuelve`, `palabra`, `oyeLinea`. Page 10, "Palabras" | the Palabras checks in leer_check.py | Pictures by `pictures.of`. The review card calls `nav.go(ReviewRoute(...))`. "Add a word or a goal" saves by `progress.add` and says "Saved. Material for it comes later." |
| 22 | feature_library | app.html lines 326 to 401 (`biblioteca` to `cierraTarjeta`). Page 10, "Leer" | leer_check.py | Listen calls `nav.go(StoryRoute(id, listen: true))`. The reader: the lit line, per-page audio, the text-size button (own storage space), the word card. Reading writes no word record; `progress.markRead` at the last page |
| 23 | feature_review | cual.js, cual.html, nivel.js, nivel.html, notas/nivel-explicacion.txt. Page 10, "Repaso" | repaso_check.py, cual_check.py, nivel_check.py | Pictures by `pictures.of(..., animated: true)`; `pictures.warm` for the next item while a sentence plays. A touch before the sentence ends does not count |
| 24 | feature_speaking | llamada.js (all but the connection); app.html: `hablar`, `notaHabla`; habla-prueba.html; notas/llamada-decisiones-1.md | llamada_check.py | On the scripted `CallSession`. When `call.available` is false the card says calls come later on this build. The voice test is `VoiceTestRoute` |
| 25 | feature_profile | app.html: `yo`, `bienvenida`, `listo` | none exists: one test per behaviour | The build number. About: "Map and scene engine: Pixel Plays by Amir Mushich (MIT)" with the licence text. On iPhone web, not installed: a one-time hint, "To install: Share, then Add to Home Screen". The level check opens by `nav.go(LevelCheckRoute())` |

**Done when (each):** its tests pass, count in the report; its dev entry runs alone; a fresh reader compares its screens with `ref/pantallas/`.

**Results (Nov 19).** Each feature was built by a Sonnet builder on its own branch; the orchestrator ran its tests again and `test_all.sh` on merged main. The fresh readers' comparisons of the features' screens come after the shared look's round 3 and the integration pass.

- **Order 23, Repaso and the level check: merged to main.** 199 tests. The logic is plain Dart, compared with the old code run in node: 41 seeded Repaso sessions (520 asks, 887 store calls with their arguments and times, 5,415 random draws at the same place in the stream, every picture's side) and 28 level-check sessions (361 items, the 28 `presume` calls) are reproduced exactly. cual.js and nivel.js shuffle with `sort(() => Math.random() - .5)`, so V8's own sort was ported to get the same order. One test for each check of repaso_check.py (96), cual_check.py (3) and nivel_check.py (14). On both phones the 19 reference pictures match in geometry within 4 device pixels.
  - Ported as the code is, not as the pages say: Repaso never adds minutes; the X in Repaso goes to Palabras; `ReviewRoute(practice:)` is not read (the old page decides: nothing due means practice).
  - Old faults ported: Repaso sets a sign flag nothing draws; a level item naming a word with no pair crashes.
  - Open for the integration pass: the level check's cells are 96 × 106 picture pixels, so `PictureSource.of` takes a width and a height (order 20 round 3 changes the contract).
- **Order 25, Yo and the welcome: merged to main.** 169 tests; the whole Yo page equals the old `yo()` for each of the 8 reference states; 56 old handlers were run in node and replayed by tapping the control. `WelcomeGate` wraps the app and shows the welcome until it is finished. New: the build number at the foot of Yo; an About row with "Map and scene engine: Pixel Plays by Amir Mushich (MIT)" and the licence; the one-time hint "To install: Share, then Add to Home Screen" on an iPhone in Safari, as a card under the title, remembered once shown.
  - The speaking note uses `speech.available()`, which covers no recogniser, no network, a denied permission and a failed turn earlier in the session.
  - Found: the streak's flame is an emoji, and Flutter on the web fetches an emoji font for it from Google's servers. Order 20 round 3 makes it a drawn icon.
  - Old faults ported: with everything played Yo says "place 1 of 10"; the second and third switch cards get an accidental top line.
- **Order 21, Palabras: merged to main** after one adaptation pass to the shared look's round 3 (102 tests; the 36 reference pictures re-taken on both phones). The word sheet opens with `showCoquiSheet`; "Palabras" and "Repaso" come from `CoquiLabels`. Against the old screenshots the text weights are now within about 10% (medium and regular were 18% too thin before the font fix); the field's ring matches; text is still 4 to 8% narrower (Roboto against Inter), so two lines that wrap in the old screenshots do not wrap here and the whole page is about 20 CSS px shorter. Stand-ins that stay in the feature: the text field, the balanced key line, its dev course data and dev picture and clip fakes. One workaround to remove later: the sheet's header title appears on scroll by rebuilding the sheet from its own scroll listener, because `showCoquiSheet` builds once (coqui_ui should take a listenable for it).
- **Order 22, Biblioteca and Leer: merged to main** after one adaptation pass to the shared look's round 3 (109 tests, 58 of them named after leer_check.py's checks; the 17 reference states re-taken on both phones, in real mode over the real `historia/` files). Fin, Otra vez, the Coquí label, Cuento con dibujos and Haz esto come from `CoquiLabels`. Listen on a picture story or a routine opens it as the old link does, without Listen mode. Against the old screenshots: on the Android size the book picture has the same whole-number scale and the same top edge in 15 of 17 states; in the two states of d-toc-toc it stands 15 CSS px lower, because Roboto wraps one line fewer on that book's tallest page; on the iPhone size the picture is at scale 5 where the old screenshots show 4 in seven states, for the same reason (more room is left for the picture). The shelf's buttons are about 3 CSS px narrower (Roboto against Inter). The book reader's layout, the shelf row and the book line stay in this feature. The content base for book images is a parameter of the module, passed by the shell.
- **Order 24, Hablar: merged to main.** 129 tests. The call's logic is a plain class on the `CallSession`, the `Clock`, the catalog and the store. One test for every check of llamada_check.py (the natural call, each goodbye rule, no answer to the end message, the 6-minute and 7-minute rules, a refused microphone, a failed start, Help). The words recorded as mouth answers equal what llamada.js records for the same 9 scripts (24 `PAL.responde` calls, from the old page run in headless Chrome with its own stub). Every part of the call screen and the voice test is within 0.6 px of the old page's own boxes at four screen sizes. No call was placed.
  - Decided after its report: when calls are off on a build the card says "Calls with Danny open later." (the line of UI round 3, historia/notas/ui-decisiones-3.md). The voice test has no entry in the app, as in v=39, where nothing links to it: it is reached by its address only; its twelve lines and its Spanish labels are exported from habla-prueba.html into a data file and passed to the module by the shell. The speaking note stays in Yo.
  - Old faults ported: Hablar lists words by ear stage, not by `abiertaHabla`; saying "el" records "él" (accents are ignored); the 7-minute stop cannot fire in a real call (the end message at 6:00 plus the 15-second cap ends it at 6:15).

## Order 26. The shell (orchestrator)

The tab bar and routes (`go_router` here only), each `AppRoute` to the module that answers `screenFor`; `Services` wired to the real packages; the first-start import of the old keys when the new store is empty; `reduceMotion` from `MediaQuery.disableAnimations`; the first tap calls `clips.unlock()`; `coqui/tool/juega.dart`.

**Done when:** on the test site every tab opens; each flow of the plan's "How features work together" works end to end on the sample course.

**Result (Nov 19): done, merged to main.** Built by an Opus builder (the shell) and a Sonnet builder (the wiring to the real Biblioteca, Palabras, voice test and `?txt=`); every check was run again by the orchestrator on the merged branch.

- Checks run by the orchestrator: `test_all.sh` passes whole (21 packages' test runs); `tool/check_app.mjs` passes 72 of 72 on both phone sizes (412 x 915 Android, 390 x 844 iPhone), empty store and mid-course seed; `tool/check_sitio.mjs --build=2` passes.
- Timing in headless Chrome on this machine (3 runs): navigation to the map's first frame about 1.9 s; map bake 347 to 355 ms (limit 500); map frame mean about 3 ms, slowest 6.8 ms (limit 8); El frente's first bake 91 to 119 ms (limit 150). A phone is slower; not measured on one.
- Addresses: `#/tab/<id>`, `#/cuento/<id>[?oir=1]`, `#/repaso[?practica=1]`, `#/nivel`, `#/libro/<id>`, `#/llamada/<placeId>`, `#/prueba-voz`. Switches: `?perf=1`, `?callstub=1`, `?mic=stub:` / `?mic=off`, `?txt=con|tras|no` (as the old page's).
- The only request that leaves the site: the ElevenLabs library from cdn.jsdelivr.net, once Hablar shows an open call card.
- `tool/juega.dart` at `coqui/tool/` was not made: the story runner's own `packages/features/feature_story/tool/juega.dart` plays a story by rule. Gate A's frames come from a tool of the app (see Gate A's result).
- Decided on the builders' stops: the phone build reads content from the live site's address (fixed in code); the failure screen says "Coquí could not load. Check your connection." with "Try again"; on a first start the welcome shows before a lesson opened by its address; after one failed load of the call library Hablar says "later" until the app starts again (a retry when the tab is shown again is a later small order in feature_speaking).
- Left: `check_app.mjs` still accepts the placeholder names for Biblioteca and Palabras in two selectors.

---

## Gate A. The map, El frente and stories 1 to 3 to Salim

First, by the orchestrator: frames of stories 1 to 3 (all right, all wrong) from `tool/juega.dart`, read by a fresh reader with no sound and no words; real findings fixed. Then the seven steps of 00-start-here. Then one message, one point a line: the link and its build number; what he is looking at; what was checked; what is a guess (the look of the sets with the sprites on them is his to judge; views no longer zoom, they slide; Claude cannot hear).

**Result (Nov 19): ready for Salim as build 3; the scenes lane is stopped.**

- The frames come from `coqui/app/tool/gate_a_frames_test.dart` (the real app, played by touches; `TXT=no` shows no words), not from `tool/juega.dart`. Six plays (stories 1 to 3, all right and all wrong) reach the end; no touch is lost. Lengths, all right: 88.8 s, 114.6 s, 107.9 s.
- Playing by machine found, and builders fixed: the speech bubble swallowed touches on things under it (the old page lets them through); the end screen's title sat on "Play again" (now 16 px under the picture, as the old page); a story whose scene is not converted opened an empty frame (now "This story is not in the new app yet." and "Back to the map").
- Three fresh readers (one per story, no sound, no words): each says a person who cannot read Spanish can mostly follow from the pictures. What hurt most is the stories' own design, the same in the old app: waits with nothing marked, the two answer cards, the cake plate.
- Eleven items that could be new were checked against the old page played in headless Chrome. Fixed in the sheet (`frente-sheet-make.js`, then the Dart assets; 513 pictures still equal to the preview): the bird on the birdhouse (7 px right); the frog's spot under the window (on the lawn before the porch, so his bubble is off abuela's face; hop counts as the old ones); the window's hint frame (the window only); the house's hint frame (to the eaves, so it has a top edge) and its hand (5 px right); the door close view (16 px up, so the frog is not cut at its bottom edge). Left because the old app shows the same: the sad ending (bird on the frog's head, the "z"), rain only under the cloud, the towel over the frog's eyes, the open door as a dark opening, the frog's shadow (cast from his feet; the style is page 11's).
- Not fixed, for after his answer: the answer cards cover abuela's body when she stands in the doorway (the cards sit 46 px above the frog; the new doorway is lower). The fix is in the cards' placement (coqui_pixel `signs.dart`), not the scene.
- Found on the way, for order 40: hop counts between frog spots the recorded stories do not use differ from the old ones (patio to puerta was 2 hops, is 1). To check: the hint hand may be drawn larger than the old one.

**Salim's answer (Nov 20): "looks good to me."** The look of El frente stands for the other scenes; the scenes lane goes on with order 30a. He added: "Biblioteca and Palabras still need UX improvements"; they are as in the old app, and "it just has always needed improvement". That is new design work (the port is no longer a straight copy there); see "Order 27" below, which his next message redirected.

**The scenes lane stops here.** No order 30a starts until he answers. A change he wants to the look is a change to page 11-pixel-engine, made with him, before any other scene. Feature lanes keep going.

## Order 27. Review as games in new sentences; Biblioteca as a real reader (design: orchestrator; build: Opus)

**His words, Nov 20.** First: both tabs "still need UX improvements"; they are as in the old app; "it just has always needed improvement". Then, when shown a tidier shelf: "its not a reader, its just a place to review the stories that already exist. thats not a feature. thats filler and fluff. almost the same deal with the flash cards. differring contenxt make the word stick more. I would like flash cards to work more like how duo lingo does their games."

**What that means (the orchestrator's reading; the second line is a guess until he answers):**
- Review: a word comes back in a different sentence each time, and a session is a run of short, varied games, as a Duolingo lesson is. Spanish only (his rule: English only in menus), so no translation games.
- Biblioteca: a shelf of the stories he already played is not a feature. A reader gives him something new to read and hear, made of words he knows.

**Stopped and parked, not merged:** a tidier shelf (branch `orden/27-bib`: covers on every row, a "Hear next" card, shorter rows; a fresh reader preferred it, "fairly close") and a tidier Palabras tab (branch `lane/feature_words/27`, unfinished). Both polish what he calls filler.

**Steps:** an inventory of how many recorded sentences each word has (a Sonnet reader); the design of the games from it, by the orchestrator, reviewed by fresh reviewers before it reaches him (page 03: a self-review does not count); the build by Opus; a fresh reader on the built screens; the link. New recordings are not made without telling him the amount first.

**Result (Nov 20): the review games are built, merged and live as build 5. Biblioteca is not started (his answer on what a real reader holds is still owed).**

- The design is page 15, in its fourth version. Three earlier versions fell: to two fresh reviewers (the game chosen by how well a word is known would have been one game for two months; reading must not decide the Ear score; saying a line back is not hearing it), then to ten readers who judged every candidate sentence against the pictures the course has (the books' pictures prove too little: 163 fair items of 1,481; the words' own picture pairs fit almost only their own sentence: 139 of 1,294). What holds: he hears a sentence he has not been asked before and says which word was in it.
- Data: `coqui/tool/make_repaso.py` chooses the sentences (565 clean recorded sentences; a word has 9 in the middle; 141 words have three or more) and writes `historia/datos/repaso.json` (183 KB); the readers' verdicts are its inputs, in `coqui/tool/repaso/`. `test_all.sh` checks the file is current.
- Recorded, with his approval: each of the 133 words that had no clip of the word alone (`historia/cuentos/palabras-solas.json`, made by `coqui/tool/make_palabras_solas.py`): 814 characters on his free Azure account, Karina's voice. All 156 words now have such a clip, so every word tile has a speaker and can be answered by ear. The orchestrator had first told him this would use ElevenLabs credits; that was wrong and he was told.
- The session (feature_review; contracts, content and coqui_ui gained what it needs): up to 10 words; one scored item a word (¿Cuál? with the word's own pair and ¿Qué oyes? in a new sentence, in turn); a play item after every third (Arma la frase, Parejas, ¿Dónde?, Dilo); a miss is shown and comes back once, in another order; every item ends with Next; a bar of one segment an item, coloured by its first answer; "N in a row"; an end screen with the missed words first; the session's time counts toward the day.
- Built by an Opus builder, then three rounds of fixes by Sonnet builders from four fresh readers of the screens (a crash in the pictures when two picture items followed each other; wrong answers too faint; the layout jumping; the word-order game's slots giving the answer away; the bar; the end screen hiding the missed words). The last reader: "probably yes" to doing it again tomorrow. The orchestrator ran `test_all.sh` on the branch (passes whole) and looked at each round's screens.
- For a learner who has finished stories 1 to 3 / 11 / 22 / 32: words with both scored games 11 / 47 / 88 / 124; ¿Cuál? only 1 / 0 / 0 / 4; ¿Qué oyes? only 0 / 9 / 18 / 26; none 1 / 1 / 1 / 2.
- The counts on the Palabras card and the map's Today card use the same rule as Repaso.
- Not done, or his to judge: how the single words sound (the orchestrator cannot hear); whether picking the word out of a new sentence is the "differing context" he means; the speaking game on his phones (the phone test results are still owed); the picture pairs that a reader could not decide (sí and no as arrows, adiós), which are the old pairs.
- Parked, not merged: the tidier Biblioteca shelf (`orden/27-bib`) and Palabras tab (`lane/feature_words/27`).

---

## Orders 30 to 39. The other scenes, one at a time

In this order: 30 balcon, 31 sala, 32 patio, 33 camino, 34 campo, 35 lago, 36 banco, 37 mesa, 38 estufa, 39 nevera. A comer follows as the twelfth once its JavaScript version is published and order 06 has made its folder. One scene is finished, both steps, before the next begins.

**Changed by Salim on Nov 21 (his words outrank the line above; the scenes were too slow at 4 to 4.5 hours each, one at a time):**
- Old scenes still to convert (El banco, then La cocina's four): step a gets at most two rounds with fresh readers. After round 2 only three kinds of fault are fixed: a failed check, a hidden face, a hidden thing he must touch. Every other fault is listed here and the scene moves on.
- Not in series: one builder per scene, each in its own worktree and branch; while one scene is ported, the next scene's step a runs; up to four scenes in flight at once. A builder touches only its own scene's files; the orchestrator adds the lines in shared files (the registry and the like) when merging. In practice a builder needs those lines to run its own tests, so it keeps every change to a shared file in commits titled `shared:` and the orchestrator merges those by hand.
- Places 4 to 10 (orders 50 to 77) are port only: step a is the content lane's and is done; no redrawing, no new reading of the sets. The four scenes of a place are ported at the same time, one builder each. The story files come from the generators in the order given below and are never pushed under `historia/cuentos/`. If a sheet, a set or a Needs list blocks a port, that scene stops, the problem is written here for the content lane, and the others go on; this lane does not fix their files.
- Unchanged: the Dart set matches the JavaScript set pixel for pixel; every converted story is checked against its recorded runs; the orchestrator runs every check before telling him anything; nothing is spent without the amount told first.
- One build and one link per place, not per scene. When a place of 4 to 10 plays in a build: "ready for the content lane" with the build number, here. With each link, one line: hours taken per scene in that place.
- How places 4 to 10 play before their stories are on the old site: order 45 (below, before order 40).

**Step a (orchestrator; design).** As order 07: `pixel/<id>-set.html` with every state, and `<id>-sheet.json`, from `ref/escenas/<id>/`. Same objects, same states, same touch keys (page 11-pixel-engine, step 4). A helper the set needs that `PpBuild` lacks is written in the reference first. Sala turns smoothing on in three places and banco copies a patch of its background: the sheet says how each is kept. **Done when:** as order 07, plus a fresh reader, shown this set beside El frente's, says whether they belong to the same world.

**Step b (builder, coqui_scenes).** As order 14: `buildSet` call for call; the old scene file line for line minus its background function; positions from the sheet; its stub in the registry replaced. **Done when:** every state within 0.5% of the reference; every touch box contains its thing; every review pair of the scene draws; the scene's stories' traces are reproduced by `tool/juega.dart`; bake under 150 ms. **Stop if:** a position has no name in the sheet.

**Then (orchestrator):** frames of each of the scene's stories read by a fresh reader with no sound and no words. After each place's last scene (32, 36, 39): the link for that place to Salim, the seven steps first.

### Order 30 (balcon), step a. **Result (Nov 20): done, merged.**

Designed by Opus agents in four rounds; the orchestrator looked at each round's pictures; eight fresh readers saw them with no words.

- Files in `docs/proyecto/pixel/`: `balcon-set.html`, `balcon-sheet-make.js` (writes `balcon-sheet.json` and checks it), `balcon-preview.html`; `set-kit.js` gained `turnedBox`, `drum`, `faceBase` (El frente's pictures are byte-identical).
- In the set: the house wall, door, window with its flower box, a tiled porch on a stone base with a step and path, a short roof over the back of the porch (no posts), the big cane chair with a cushion, the round table, the small yellow chair, bushes. In the sprite layer: abuela, the frog, the bird, glasses and jugs, the fan, bubbles and signs. State parameters: `door` shut or open, `win` shut or open (4 baked states; the stories reach 2). Views `wide`, `mesa`, `porche`, all zoom 1.
- All 13 touch keys, 3 views, 11 frog places, 26 positions, 10 review pairs and 9 level pictures of the old scene are there. Hop counts for all 55 pairs of frog places are the old ones.
- What a learner would notice against the old picture: the 30 degree view; no posts and no hanging plants (they would cover the door and window); a round table for the long low one; chairs turned to the camera; the table view no longer zooms.
- What the rounds fixed, as rules for the next sets: every drink stands on the table top with plain wall behind it; a person who stands at furniture is drawn on clear floor in front of it, after it; a bird perches where the old picture had it (three other perches read as hovering); the whole door, and whoever stands in it, is inside the wide view with a margin; a strip of wall shows over door and window; an empty chair shows its seat; a path starts as wide as its step. "Behind the furniture" is a depth test on the set's own pixels, not a screen row (`sheet.front`).
- Left as the old game has it: the glass beside abuela's head when she drinks; a glass set on the small chair's seat; a glass on the floor beside the frog when he carries it; the hint hand over the thing it points at; pair "toma" with the big bird.
- Not solved: in combinations no story reaches, the frog's bubble can cover abuela's face (frog before the door with her in the doorway). The roof is 15% of the wide view.
- Bake: 76 to 136 ms warm in headless Chrome, 145 to 162 ms the first time.

### Order 30 (balcon), step b. **Result (Nov 20): done, merged; stories 4 and 5 play in the app (build 4).**

Ported by an Opus builder; three files it could not touch were finished by a Sonnet builder; the faults a fresh reader found in the real app were fixed by an Opus builder in the set and the port together. The orchestrator ran `test_all.sh` on the branch (passes whole) and looked at the before-and-after pictures.

- All four baked states: 0 of 51,840 pixels differ from the JavaScript. Preview pictures: 529, 468 identical, none over 2%, the most 0.18%. El frente unchanged.
- The stories at balcon (el-jugo, que-calor, d-agua-pajaro, h-balcon) reproduce their recorded runs except in time: abuela's walk to her chair is 350 ms longer; the view no longer slides (all three views are one window), so el-jugo is 0.3 to 1.4 s shorter and que-calor 640 ms.
- In the real app el-jugo and que-calor play to the end by touches, right and wrong, no touch lost.
- New for later scenes: `Sheet` reads a set with no frames, front parts, numbers and more; `SetOverSprites` (the set's own pixels drawn again over a sprite where they are nearer); the registry gives a scene the runner's random source; the tools take `--scene`; the Gate A frames tool takes `STORIES=`.
- What the reader of the real app found and the fifth round fixed, now checked by the sheet maker at all 869 moments of the 12 recorded runs: every bubble wholly inside the view and clear of the score and thermometer boards (abuela's bubble goes beside her head while the boards are up; her chair moved 6 px); every set of drinks on the table side by side (her folded fan sits at the table's front); a change of view moves nothing; every hint frame inside the view.
- Over the limit: the first bake of a balcon state takes 205 to 313 ms in a release web build on the build machine (limit 150; El frente about 100). Later bakes 114 to 198 ms. Accepted for now; a speed-up is a later order.
- Left as the old game has it: the glass beside abuela's head; a glass on the floor beside the frog when he carries it; the board game's asks with no hint; the two answer cards that look alike.
- Not solved: the door's hint frame reaches 3 px past the view (no story asks for the door); `coqui_scenes`' picture widget fails when it is given another picture in place (found by order 27; a fix is queued).

### Order 31 (sala), step a. **Result (Nov 20): done, merged.**

Designed by Opus agents in two rounds (El balcón took five: this time the brief carried every rule the porch and the balcony taught, and the sheet maker's checks were built before the design); the orchestrator looked at both rounds' pictures; three fresh readers saw them with no words.

- Files in `docs/proyecto/pixel/`: `sala-set.html`, `sala-sheet-make.js` (writes `sala-sheet.json` and checks it over 1,101 moments of 18 recorded runs), `sala-preview.html`; `set-kit.js` gained `revealX` and `planeFace` (El frente's and El balcón's pictures are byte-identical).
- The room is cut open like a model: the two far walls stand, the near ones are not built, the floor runs off the picture, plain dark above the walls (the orchestrator's choice over lawn). Every place on the floor keeps its old screen point, so who stands in front of whom is as in the old picture. In the set: walls, the door to the porch with its open leaf and the porch tiles through it, three framed pictures each on a wire from a nail, the window with curtains, the floor lamp, the sofa, abuelo's armchair, the low table, the baby's blanket, a plant. In the sprite layer: the seven people and the frog, the photos inside the frames, the cake and the camera, bubbles and signs.
- State parameters: `luz` 1 or 0, `fotos` (which frames hang crooked). 5 baked states cover all 27 old states. Both views are one window.
- All 16 things, 9 frog places, 46 positions, 11 review pairs and 28 level pictures of the old scene are there; hop counts for all 36 pairs are the old ones.
- New rules from this scene, for the next ones: a picture on a wall hangs upright, turned to the camera like the furniture, with its whole photo inside the frame at 1:1 (sheared along the wall, a reader could not tell whose face it was); a crooked one turns 14 degrees beside straight ones; a lamp's foot shows on the floor; where a bubble would land on a face, the sheet gives the next free place beside the head (`talk`); a standing person covers no more of a sitting person's face than the old picture did.
- Three places where smoothing is on are kept as the old code has them (the sheet's `smoothing` part).
- Left as the old game has it: people appear and change places between steps; the two answer cards that look alike; a slice of cake shown over the frog; abuela standing in front of the sofa over a sitting person's body.
- Bake: 112 to 194 ms the first time, 59 to 66 ms warm, in headless Chrome (flat walls are drawn one sample a pixel).

### Order 31 (sala), step b. **Result (Nov 20): done, merged; stories 6 to 8 play in the app (build 6).**

Ported by an Opus builder with no stop; the orchestrator ran `test_all.sh` on the branch (passes whole); a fresh reader went through the three stories as they play in the real app.

- All five baked states: 0 of 51,840 differ from the JavaScript. Preview pictures: 609, 486 identical, none over 2%, the most 0.07% (along the turned edges of crooked photos). El frente and El balcón unchanged.
- All 18 recorded runs match in everything but time, with the old number of random draws. la-familia, d-bizcocho-bebe and h-sala are equal whole; la-foto is 700 ms longer, quien-eres-tu 770 to 980 ms, d-foto-familia 140 ms, each because a walk starts from or ends at a place the sheet moved.
- In the real app la-familia, la-foto and quien-eres-tu play to the end by touches, right and wrong, no touch lost.
- `Sheet` now also reads: spots and views given by a world point only, points given only on the screen, floor remaps, `moves`, `smoothing`, `talk`. The three smoothed places are kept exactly (a snapshot of the picture drawn small with smoothing on and back up; identical to Chrome).
- Bake: the very first state, which also builds the floor, 150 to 195 ms (over the limit in 4 of 5 loads); the other first bakes 50 to 102 ms; later ones about 60 ms.
- What the reader of the real app found is the old stories' own: the hint hand runs off the bottom edge under the children and the baby (same places as the old picture); a person standing in front of a seated one; the two answer cards that look alike; the last asks of la-familia with nothing marked; the end heart between the board and the lamp. quien-eres-tu cannot be followed from pictures alone: its choices are made by sound.
- Reported in the JavaScript set, not fixed: the sofa, armchair and door each draw one column 1 px outside their touch box.

### Order 32 (patio), step a. **Result (Nov 20): done, merged.**

Designed by Opus agents in six rounds; the orchestrator looked at every round's pictures and decided the changes; seven fresh readers in all saw them with no words.

- Files in `docs/proyecto/pixel/`: `patio-set.html`, `patio-sheet-make.js` (writes `patio-sheet.json` and checks it over 1,128 moments of 18 recorded runs), `patio-preview.html`; `set-kit.js` gained `UVW` and `planeQuad` (the other three sets' 68 pictures are byte-identical).
- The yard is a corner, like La sala: the back of the house along one world axis on the left (its door, step, roof), the fence with the gate along the other, far right, the tree and its nest at the right edge, the lawn between, a field and hills in the gap. Round 1 stood square to the camera and looked like the old flat picture: the orchestrator's decision to turn it. In the set: house, door (shut or open onto a dim room), fence, gate (shut, or its leaf swung into the yard with the path seen through it), tree, nest, the two beds of turned earth, sky and hills by the hour. In the sprite layer: the people, the frog, the bird, the crate, the flowers, the ball, the sun, moon and stars (drawn behind the set: the sheet's `behind`), bubbles and signs.
- State parameters: `hora` (dia, tarde, tarde2, ocaso, crepusculo, noche), `door`, `gate`. 15 baked states are reached. One view (x0 22).
- All 21 things, 14 frog places, 73 positions, 25 review pictures and 27 level pictures of the old scene are there. Every place keeps its old screen point but two: the frog's place at the gate and where he leaves follow the gate, so that he goes out through it (the old picture had him so; round 3 had him fade on the lawn). For that, 8 pairs of places take one hop more than before (the sheet's `hops`; none of them is walked in the recorded runs). This is the one exception to "hop counts as the old ones".
- The lawn is El frente's grass (the same ramp), calm; green at dusk and at night.
- New for this scene, and a rule for the next ones: **a thing the set paints round an empty place needs something to explain it.** A soft darker patch round each bed (round 4) read as a hole or a shadow of nothing; a border of low leaves (round 5) read as a pit with walls. What holds (round 6): the beds are earth only, and every flower planted in the ground brings its own small clump of leaves, drawn by the sprite layer just before the flower (the sheet's `flowerLeaves`: two stages, open 11 x 22 px, bud 9 x 13 px, three greens). A yellow head stands out from what is round it by 69 (the old lawn: 57).
- Other rules it kept from the earlier scenes, now checked by its sheet maker: the whole door in the view with wall over it; abuela in the doorway with dark round her head; at least 5 rows of lawn between anyone's feet and the foot of the wall, fence or trunk behind them; hint frames and bubbles inside the view; cards over no body; the bird's perches under its feet; stars wholly in the sky or wholly hidden.
- Left as the old game has it: people appear and leave between steps; a thing shown over the frog's head (drink, ball, cake); the two answer cards that look alike; people's feet at the back rim of a bed; the ball in the tree among red apples; the hint hand running off the bottom under the beds.
- Seen by the last reader and not changed: at night an empty bed is a dark oval of low contrast (no story has empty beds at night); the nest reads as a flat dish until the bird sits on it.
- Bake: about 100 to 150 ms the first time, 26 to 52 ms warm, in headless Chrome.

### Order 32 (patio), step b. **Result (Nov 21): done, merged; stories 9 to 11 play in the app (build 7). La casa is whole.**

Ported by an Opus builder with no stop; the orchestrator ran `test_all.sh` on the branch merged with that day's main (passes whole); a fresh reader went through the three stories as they play in the real app.

- All 15 baked states: 0 of 51,840 differ from the JavaScript. Preview pictures: 595, 127 identical, none over 2%, the most 0.22% (the soft edge of the sun's disc). El frente, El balcón and La sala unchanged.
- All 18 recorded runs match in everything but time, with the old hop sounds and the old number of random draws: las-flores and hasta-manana 70 ms longer, que-es-esto 20 ms, d-la-bola and h-patio 70 ms shorter, d-buenas-noches 350 ms shorter, each from a walk to a moved place.
- In the real app las-flores, que-es-esto and hasta-manana play to the end by touches, right and wrong, no touch lost.
- Built for later scenes: a scene can draw sprite-layer things behind the set (the sun, moon and stars: the sheet's `behind`); `flowerLeaves`; `Sheet` reads `hops`, the sun's heights, moves that change a value or a card's place, remaps that name another scene's picture; `BakedSet` keeps the grass blades' colours of its hour; a position an act reads from its story file goes through the sheet's remap as a set step's does.
- Bake: the very first state, which also builds the ground, 133 to 157 ms (over the limit in 2 of 4 loads); every other first bake 26 to 61 ms.
- What the reader of the real app found is the old stories' own (the hint hand running off the bottom under the beds; a thing shown over the frog's head; the two answer cards that look alike; asks with nothing marked; a heart on a wrong touch; fireflies over a face), with these from the new set, left: a flower's clump of leaves read to this reader as "a dark-green rounded shell" (an earlier reader named it stem and leaves); the gate's hint frame crosses papá's face at one ask; the heart bubble of a touched Luis sits over the bird.
- Reported in the JavaScript set, not fixed: the trunk's and the nest's shadows are never cast (a call with a point spread wrongly; the pictures the readers passed are without them); the nest's branch, the crown's leaves at some wind steps (1 px) and the beds' ragged earth (1 to 2 px) reach outside their touch boxes; the sheet's `behind` names its two source lines one too high; at one moment of las-flores the preview puts Carmen 8 px from where the sheet's remap (and so the app) puts her.

### Order 33 (camino), step a. **Result (Nov 21): done, merged.**

Designed by an Opus agent in four rounds (El patio took six: the brief carried its lessons and the layout stood on the world's axes from round 1); the orchestrator looked at every round's pictures and decided the changes; five fresh readers saw them with no words.

- Files in `docs/proyecto/pixel/`: `camino-set.html`, `camino-sheet-make.js` (writes `camino-sheet.json` and checks it over 1,066 moments of 15 recorded runs), `camino-preview.html`; `set-kit.js` unchanged.
- The park: the path comes in from the left edge through the arch, turns at the first stone and climbs to the right past the big tree; the seven stones are the old marks; three small trees stand free at their old feet; the bench runs along the path below them; the big tree is at the right, its crown running off the top and right edges as the old one's did. In the set: lawn (El frente's grass), path, stones, arch, trees, bench, sky with the sun and three clouds, hills. In the sprite layer: people, frog, dog, cat, the nine birds, snail, bush, rings, leash, dust, bubbles and signs.
- One state parameter, `gran` (the big tree there or not): 2 baked states cover the old 9. One view (x0 22).
- All 22 things, 7 frog places, 35 positions, 25 review pictures and 16 level pictures are there. All 21 hop counts are the old ones.
- New for this scene:
  - **A hint box.** The big tree's touch box runs off the picture, so the sheet gives it `things.grande.hintBox`: the hint frame and its twinkle are drawn round that, touches still answer in the box. The one exception to "the hint frame inside the view".
  - **Leaving in a file.** At the end of story 14 everyone walks out through the arch one after another and fades past its line (the sheet's `sevan`); the old act let them fade in a clump. The act is longer (20 ticks; it was 8 for the people) and the dog fades too.
  - **The answer cards stand in the sky** in all four stories that use them, clear of bodies, birds, the corner boards and the sun.
  - **The sun is on the side its shadows need**: upper left (it was baked upper right in round 1 while every shadow fell right), under no board and no card at any moment.
  - **A thin thing casts only a contact shadow.** The arch's true shadow ran along the path's own edge and read as a kerb with a pond at its end; now each post has a short shadow at its foot.
  - **What sits on the bench has one backdrop**: only lit lawn (or only shadowed lawn) behind the cat and the bird; no trunk, no shadow's edge. The bench was moved for it twice; keeping a tree's shadow off the lawn instead (round 2, the orchestrator's decision) left that tree with no shadow, and three readers named it.
  - Checked for every set thing: its pixels inside its touch box at every wind step; each shadow in one piece with its thing; the preview's places equal the sheet's (0 differences in 5,081).
- Left as the old game has it: the frog on Luis's head; the cat as a tail, then a head in the leaves; the dog behind the bush; the bush on the path's bend; people appearing between steps; the frog and the dog at the arch's right post; answer cards that look alike; the hint hand of the first tree on a face at three asks.
- Seen by readers and not changed: the bench has no back (each named it a bench); a crown's shadow lies a little apart from its trunk's foot; the frog at the bench sits in front of it.
- Bake: 57 to 99 ms the first time, 19 to 47 ms warm, in headless Chrome.

### Order 33 (camino), step b. **Result (Nov 21): done, merged; stories 12 to 14 play in the app (build 8).**

Ported by an Opus builder with no stop; the orchestrator ran `test_all.sh` on the branch (passes whole); a fresh reader went through the three stories as they play in the real app.

- Both baked states: 0 of 51,840 differ from the JavaScript. Preview pictures: 527, 518 identical, none over 2%, the most 0.04% (the rings round the counted trees). The four earlier scenes unchanged.
- All 15 recorded runs match in everything but time, with the old hop sounds and the old number of random draws: uno-dos-tres equal whole; h-camino equal in time (the cat's place on the bench differs in the state line); donde-esta-el-gato 70 ms shorter; d-corre 210 ms shorter; rapido-despacio 140 ms longer, from the new walk out through the arch.
- In the real app uno-dos-tres, donde-esta-el-gato and rapido-despacio play to the end by touches, right and wrong, no touch lost.
- Built for later scenes: any thing of any scene can carry a hint box (`Thing.hintBox`: the frame and the twinkle go round it, touches answer in the box); a set step's `respEn` goes through the scene's remap (one small change in the runner); `Sheet` reads a box given as corners, cloud points, a `numbers` remap, front parts placed by `insert`, `sevan`.
- Bake: the first state, which also builds the ground, 104 to 126 ms; the other first bake 17 to 22 ms; later 13 to 27 ms. Under the limit.
- What the reader of the real app found is the old stories' own (the dog in front of the frog at the arch; people in front of one another at the ends; the cat as a tail; answer cards that look alike; asks with nothing marked; a heart on a wrong touch; the dog behind the bush). The walk out through the arch at the end of story 14 plays between two captured frames, so the reader saw only "everyone gone".
- Reported, not changed: the dog's, the cat's and abuela's sprites reach past their old touch boxes (as in the old scene); the sheet's world boxes for the path and the park do not project to their screen boxes (nothing uses them).

### Order 34 (campo), step a. **Result (Nov 21): done, merged.**

Designed by an Opus agent in three rounds (it was cut off in round 2 when Opus reached its weekly limit; Salim reset the usage and it went on from its saved work); the orchestrator looked at every round's pictures and decided the changes; six fresh readers saw them with no words.

- Files in `docs/proyecto/pixel/`: `campo-set.html`, `campo-sheet-make.js` (writes `campo-sheet.json`; it now plays the old page itself and checks every tick inside the acts, 7,020 ticks, not only the ends of steps), `campo-preview.html`; `set-kit.js` gained the park's water (`waterPixel`, and `drawGlints`, a new per-frame step beside the tufts); the five finished sets' 102 pictures are byte-identical.
- The field: lawn (El frente's grass), one tree of El camino's kind at its old foot, the lake's corner at the lower right behind one straight bank on a world axis, a sparse row of reeds along it, El camino's sky. In the sprite layer: Luis, Carmen, the frog, Canelo, the three balls, the basket, the flower, the frog's puddle, the dark curtain of his shut eyes, the butterfly, splashes, bubbles and signs.
- One baked state draws all 7 old states (the old set keys are all sprite-layer things). One view.
- All 10 things, 15 frog places, 66 positions, 22 review pictures and 16 level pictures are there.
- **The water** (made once, for El lago too): a low earth bank with a dark wet line, water lighter and bluer than any sky tone, baked ripple dashes, glints that come and go each frame. Every reader named it water at once.
- New rules from this scene, for the next ones:
  - **Show as much water as the old picture did.** Round 1's bank left a thin triangle at the corner; whatever floated sat against the picture's edge and three readers could not tell grass from water. Round 3 moved the bank up the lawn: the lake shows 132% of the old pond's area.
  - **Whatever is near the shore is clearly on one side**: on the land with 8 px of lawn round its foot, or in the water with 8 px of water all round and 6 px from the picture's edges. 27 places moved for it (the sheet's `moves` and `remap`); 6 pairs of frog places take one hop fewer (the sheet's `hops`; none is walked in a recorded run).
  - **What floats or wades gets a ripple ring** round it, drawn by the sprite layer just before it (the sheet's `helps.ring`).
  - **A ball in the air, and Canelo in the air, has its shadow on the ground under it** at every tick and in every pair picture. A ball a child holds up sits in the raised hand (one line of `campo.js` moved).
  - **A tree alone on an open field casts a lighter crown shadow**: one even shade, the lawn's next darker tone. The engine's full shadow hid the balls and dark hair and read as a hole in close pictures; a dot pattern (round 2) read as "a mesh or grate". No zoom 2 pair picture shows the tree's shadow without the trunk.
  - **Two more helps that failed** (round 2, the orchestrator's decisions): a patch of dug earth where Canelo lies read as "a hole or mud patch" (removed: he lies on the lawn); a dark rim round the yellow ball read as "a hole or a plate" (removed). The yellow ball stands out from this lawn by 26 where the old lawn gave 50: accepted.
- Left as the old game has it: a held ball in front of a face; the ball on the frog; balls heaped beside Canelo; things appearing between steps; answer cards that look alike; the hint hand running off the bottom.
- Seen by the last readers and not changed: a few reed stems at the bank read as "short brown posts"; the crown's shade lies a little apart from the trunk's shadow.
- Bake: 45 ms the first time, 22 to 28 ms warm, in headless Chrome.

### Order 34 (campo), step b. **Result (Nov 21): done, merged; stories 15 to 17 play in the app (build 9).**

Ported by an Opus builder with no stop; the orchestrator ran `test_all.sh` on the branch merged with that day's main (passes whole); a fresh reader went through the three stories as they play in the real app.

- The baked state: 0 of 51,840 differ from the JavaScript, and a frame at two other times (other glints showing) differs in 0 too. Preview pictures: 584, 547 identical, none over 2%, the most 0.02% (the edge of the frog's puddle). The five earlier scenes unchanged.
- All 15 recorded runs match in everything but time, with the old hop sounds and the old number of random draws: h-campo equal whole; la-bola 140 ms shorter; d-bola-canelo 280 ms shorter; arriba-abajo 420 to 770 ms shorter; otra-vez between 70 ms shorter and 280 ms longer; each from walks to the places that moved at the shore.
- In the real app la-bola, arriba-abajo and otra-vez play to the end by touches, right and wrong, no touch lost. The reader placed everything near the water on the right side of the bank (75 to 90% sure each).
- Built for later scenes: the park's water as a kit helper (`waterPixel`: El lago reuses it); glints as a per-frame step of any set that has water (on the engine, kept by `BakedSet`, drawn after the tufts; a set without water draws as before); `helps.ring`; a pair picture's own places go through the scene's remap (`PairPlaces`); `Sheet` reads `helps`, dropped lines as source, a point on a line, the water's depth for the front test.
- Bake: 63 to 87 ms the first time, 25 to 30 ms later. The glints cost under 0.01 ms a frame.
- A gap in the sheet, accepted: two lines of `campo.js` (233, `aparta`; 286, the balls of `final16`) have no entry in the sheet's `code`; their places are unchanged from the old scene and the port keeps their numbers by a rule that allows exactly these two lines. The preview check passes with them.
- What the reader of the real app found is the old stories' own (a held ball in front of a face; Luis's hand over his eyes when he looks up; balls heaped by Canelo; the frog at the trunk's foot; answer cards that look alike; asks with nothing marked; no clear sign for a wrong touch), with one from the new set, left for El lago to settle: **a person's shadow that falls on the water shows as a dark patch on the blue**, and the reader could not explain it.
- Reported in the JavaScript set, not fixed: at its moved place the ball "in the reeds" lies in front of the reed bed and no reed covers it (the sheet's text says the reeds stand before it); the reeds' screen box is 1 px narrower than their box.

### Order 35 (lago), step a. **Result (Nov 21): done, merged.**

Designed by an Opus agent in five rounds; the orchestrator looked at every round's pictures and decided the changes; seven fresh readers saw them with no words.

- Files in `docs/proyecto/pixel/`: `lago-set.html`, `lago-sheet-make.js` (writes `lago-sheet.json`; it plays the old page and checks 17,835 ticks inside the acts), `lago-preview.html`; `set-kit.js`: `waterPixel` takes `look.noShade` (El campo does not set it; the six finished sets' 104 pictures are byte-identical).
- The lake is a bay opening toward the viewer: a left shore and a right shore on the world's two axes, a narrow neck of water between them up to the hills, El campo's water. The dock is a broad deck of planks on pilings, out from the left shore, with a landing on the lawn and two mooring posts; a post stands in the water; the reeds stand in the shallows at the right. In the sprite layer: people, frog, Canelo, the three ducks, the birds, the three boats, the fish, bread, bag, sack, flower, brush, bubbles and signs.
- No state parameter: one baked state draws all 10 old states. One view; all 22 pair pictures at zoom 2.
- All 19 things, 8 frog places, 48 positions, 22 review pictures and 16 level pictures are there. All 21 hop counts are the old ones. 23 moves; the dock's own places keep their old screen points (that is why the deck is broad).
- New rules from this scene, for the next ones:
  - **Keep the old picture's banks.** Rounds 1 and 2 had one shore; the old right bank became water, Carmen in los-botes had nowhere to stand where the boats arrive, and two readers said the boats "go to nobody". Round 3 gave the lake its right bank on the other axis: Carmen stands there, the row of boats ends at her feet, the flower and the reeds are back on that side.
  - **No cast shadow on the water** (`look.noShade`); the dock's own shade is baked into the set, joined to it.
  - **What stands in the water has a waterline** at its foot (the post, the pilings, a few dashes at the reeds); without it the first reader saw them "pasted in".
  - **A fish needs pale water round it to be read as a fish.** On this water two readers called it "a log" or "a turtle shell"; a ring did not help; a box of pale water (round 4, the orchestrator's wording) looked like a card. What holds: an oval of paler water under each fish at the surface, no outline, its edge dithered into the lake, the lake's ripples going on inside it (the sheet's `helps`). Every fish colour stands out from it by 51 or more.
  - Everything that floats or swims has El campo's ring; a fish leaping has its splash.
  - The ask pictures of a design round must be taken at the moment before the ask's first step (round 2's showed the cards one step late, over the sun, although the check was right).
  - No glint is drawn on a thing that stands in the water (a white speck on the planks was a glint recorded before the dock was drawn).
- Left as the old game has it: the duck that appears on the shore behind the frog; the ducks bunching and climbing onto the dock at the girl's feet; the bread that never visibly reaches the duck; boats appearing on the dock again; the pile of boats at the far end; blank cards and cards that look alike; the hint frame over the thing it asks for; the hint hand running off the bottom.
- Seen by readers and not changed: the blue boat's sail stands out least from the water (39); the reeds run off the right edge of the picture; Carmen in los-botes stands 3 px from the right edge.
- Bake: 71 to 95 ms the first time, 12 to 29 ms warm, in headless Chrome.

### Order 35 (lago), step b. **Result (Nov 21): done, merged; stories 18 to 20 play in the app (build 10).**

- Built by one builder on `orden/35b`, checked by the orchestrator: `tool/test_all.sh` passes whole on the merged branch; no commit names a model.
- The set in Dart differs from the JavaScript set in 0 of 51,840 pixels (colour, depth and kinds), at rest and at two glint times. The preview: 801 pictures, 674 identical, none over 2%, the most 0.06% (the edge pixels of a turned sprite: a boat in the reeds, the leaping fish). The six earlier scenes' pictures are unchanged.
- The 15 recorded runs are equal without their times, with the same hop sounds and the same number of random draws. Times differ only where a path moved: pan-para-el-pato 1.3 to 1.7 s longer, los-botes 1 s shorter, d-pato-pequeno 0.4 s shorter, h-lago 0.07 s longer, cual equal.
- Bake in the release web build: 97 to 139 ms the first time, 31 to 41 ms after; the 82 glints cost 0.006 ms a frame.
- New in the kit and the sheet reader: `WaterLook.noShade`; rings by kind (`pato`, `bote`, `pan`), drawn only where the set's water shows (the mask is kept at the bake); the fish's patch (`SheetPatch`, `helps.ring.pez`); a move's `shift`; things whose `world` is null or more than one point.
- **Decided at the stop:** three lines of `lago.js` hold places the sheet's `code` never names (263: the birds rise to row 70; 276: bread falls to `o.y || 178`; 278: the ducks swim out to x 252). None moved; the old numbers are kept by `LagoPlaces.floorRule`, which serves those three lines only, as El campo's does for its two. The two lines 276 and 278 are used by no story of the lake. From El banco on, the sheet maker reads the scene's file itself for every place, not order 06's inventory.
- Reported from the JavaScript, not changed: `lago.js:237`'s comment swallows the rest of its line, so in the old game the boats were never knocked free and Carmen kept her pose at the end of los-botes; the port does the same.
- `lago.js`'s `aveA` is `pajaroA` in Dart (the kit's scene already has an `aveA`). The tests of a scene not converted now use El banco (`la-piragua`; the Repaso test asks `hombre`).
- A fresh reader went through all six plays from the real app (pan-para-el-pato, los-botes, cual; right and wrong). Read well: the dock and its posts standing in the water, the boats going up the bend to the girl on the far bank, the ducks' rings, the shadows all one way, the reeds as reeds. No frame or card cut by an edge or round an empty place.
- **Left:** at pan-para-el-pato's first card ask the hint frame round the first card crosses Carmen's head and the hint hand covers her bag (the set's pictures had it too; the maker checked the cards, not the hint drawn round a card); at one card ask of los-botes the hint hand is on Luis's head. The fish's pale oval still reads as "a plate or sticker" close up to one reader. The hint hand for a duck near the bottom edge is cut by it, as in the old game. From El banco on the maker checks the hint frame and hand round every card against every head; the earlier scenes' cards (El frente's doorway, these two) want one sweep after order 39.

### Order 36 (banco), step a. **Result (Nov 21): done, merged.**

Designed by an Opus agent; two rounds read by fresh readers (four readers in all, no words), then one short fix pass with no third reading (Salim's new rule). The orchestrator looked at every round and ran the maker itself: ok, same bytes twice.

- Files in `docs/proyecto/pixel/`: `banco-set.html`, `banco-sheet-make.js` (writes `banco-sheet.json` and checks it over every tick of the 18 recorded runs), `banco-preview.html`. `set-kit.js` is unchanged.
- The corner: paving on the world's axes; three benches in a row along x, their seats facing +y, sitters on the seats with the back behind them; the cart at the left (11 px left of its old place), its man behind it; the lamp post behind the benches' line in the gap between benches 1 and 2; a pole at the left edge and the wire to the lamp and on, pigeons on it at the old points; the gate at the lower right: two stone posts with balls, 32 px apart, the hedge joined to both, the paving running out through the opening; `PORTON` moved to (199,203) and every way out goes through it. In the sprite layer: everybody, the dogs, the pigeons, the pushchair, the tray, the box, the rolling cart (`carroX`: the same cart pixel for pixel, its box moving with it).
- State parameters: `luz` dia, tarde, noche; `luna`; `carro` abierto, cerrado, no. 7 baked states are reached (of 12); they cover all 49 old states (the other keys are the sprite layer's). One view.
- Evening and night are the set under another light: the lamp's glass lit, a pool of light round its foot (half strength at dusk), the wire dark at dusk and pale at night, the moon. The sprites are not darkened. The old page's copied patch (banco.js:194) hid the old sun at night; the sheet keeps it as "by night no sun".
- All 20 things, 62 positions, 12 review pairs and 4 level items of the old scene are there; 42 moves are listed in the sheet with their reasons (the gate and the exits, the cart and its man, story 22's queue, dogs and Carmen, perch spots, the cards in the sky at `respEn` 126,31).
- New in the maker, and rules for the next scenes: **the picture is checked as it is drawn** (each item owns the pixels it drew last; no bench pixel over a sitter or over what lies on a seat: 0 at 50,197 sittings; no set part over any face); **seen share** (everybody seen no less than in the old picture less 10%, faces no less); **nobody new at the edge** (3 px); a thin line is checked by luminance contrast (2.0), not by colour difference; the maker reads `banco.js` itself for the `code` entries; the hint frame and hand round every card.
- A lesson: three times a check passed while a reader saw the fault (sitters "behind" the benches, the wire gone at night, the gate read as "two bins"). The check measured the wrong thing each time. The kitchen's briefs carry the eye's measure from the start.
- First bakes: 63 to 105 ms with one browser, 110 to 190 ms with a fresh browser for each state (the machine was busy). To be measured in Dart against 150 ms.
- **Left, by Salim's rule (not a failed check, a hidden face or a hidden touch thing):** the sun is small (radius 4) and close to the pole's top and the wire, and one reader took it for a bulb on the wire (a park-size sun fits nowhere clear of the board, the cards, the pole and the wire); the pole stands at the picture's left edge with no base; the gate's right post touches the right edge; the wire is faint where it crosses the first tree's crown (contrast 1.1 to 1.8); Carmen where she hands the bag and the bone (senor-senora) stands 1 px from the lower edge; the cart's man has his legs behind the old dog for a moment as the cart goes home (three step ends, face clear); the box beside Luis is partly behind the gate's left post; the posts are a little lower than a person; the left hedge piece is a stub; in the pair `duerme` a bench leg shows at the top edge (the old pair's too); the hint hand is cut at the lower edge where the dogs lie in the lower left corner (the old's too).
- Left as the old game has it: people appear and leave between steps; the queue at the cart stacks four people; a cone shown over the frog; answer cards that look alike; `h-banco`'s twinkle on another person than the framed one.

### Order 36 (banco), step b. **Result (Nov 21): done, merged; stories 21 to 23 play in the app (build 11). El parque is whole.**

Built by an Opus builder on `orden/36b`, with one stop; the orchestrator ran `test_all.sh` itself on the branch with main merged in: all checks passed.

- Files: `coqui_scenes/lib/src/banco/` (`banco_set.dart`, `banco_places.dart`, `banco_sprites.dart`, `banco.dart`), six tests, the sheet as an asset, `coqui/ref/pp/banco/` (the seven reached states).
- The set: all 7 reached states equal the JavaScript reference: 0 of 51,840 pixels differ in each (pixels, depth, kinds). Sprites: 119 exact.
- The preview: 742 pictures, 674 identical, 0 over 2%, the most 0.20% (edge pixels of rotated sprites). The seven earlier scenes' numbers are unchanged.
- Recorded runs: all 18 equal timeless; hop sounds and random draws the old ones. Time differences, reported and not fixed: la-piragua 210 to 280 ms shorter; senor-senora 70 ms shorter at one step and 1.3 to 2.4 s longer in all; el-bebe-duerme 460 ms shorter; d-vamos-a-casa 140 ms longer.
- **The stop, and what it taught:** in el-bebe-duerme (`acts.alegra`) the frog took 3 hops where the recorded run has 4: the design had moved a sitter 2 px, and the maker checked hop counts only where steps end. The designer's maker now replays every frog walk of the 18 runs (107 walks) against the old page; the man sits at 193 (the old 194) and the count is the old one. The kitchen's makers check walks the same way. The port's builder also found the preview started the rolling cart 11 px off, and a wrong line in the sheet's light text; both are fixed in the JavaScript.
- New in Dart: the draw order "as it is drawn" (each item owns the pixels it changed; a front part is drawn again only where someone stands behind it, never over a sitter's own bench); the cart as the set's own part while it stands and as the set's own pixels moved while it rolls, its box with it; the sitters' places read from the sheet's moves.
- **The tests that need a scene that is not converted no longer use a real scene:** a test-only scene `prueba` (never converted, with order 06's El banco pictures) and the story `prueba-cuento`. No later port has to touch them.
- Every touch box contains its thing (the rolling cart at all 63 ticks); 24 review pairs and 16 level cells draw.
- First bake in Dart (release web, three loads, a busy machine): `dia.0.abierto` 160, 109 and 186 ms, over the 150 ms limit in two of three; every other first bake 31 to 76 ms, later bakes 21 to 74 ms. The cost is the park's ground and grass, built once. Left, as El balcón's.
- A fresh reader of the real app's frames (four plays, no words) found no program fault. Read: treats to the man and the woman, the crying man who gets a cone, the stars and the X marks, the sunset and the night. Not read, and the old game's own: the voice cards that look alike, the crowd at the cart, people who appear and leave between pictures, asks with nothing framed (he must say a word).
- **Left:** to one reader the two sitters on the left and middle benches still look half standing at the bench's end (the old sprites have no knees); at the woman's last ask in senor-senora she stands at the gate and the hint frame touches the picture's right and lower edges; the dog's ask in the lower left corner has its hand cut by the lower edge (the old's too); the first bake above.

### Orders 37 to 39 (mesa, estufa, nevera), step a: how the three were made at once

Since Salim's change (above) the kitchen's three old scenes were designed at the same time by three Opus designers, one each, on `orden/37a`, `38a`, `39a`. The room is one: `docs/proyecto/pixel/cocina-kit.js` holds its colours and pieces (the checker floor on the world's axes, the cream wall with the tile band, base and wall cupboards, the window with what is outside, the stove and hood, the "room cut open" build of La sala, the floor dimmed on the shadow side only). It has one writer, La mesa's designer, who only adds to it; the other two keep an unchanged copy. `set-kit.js` is not touched by any of them. Each design gets two readings by fresh readers at the most; then only a failed check, a hidden face or a hidden touch thing is fixed. The four Escuchar picture stories the content lane wrote for the kitchen need new acts and are not part of these orders; they are an order of their own after the kitchen plays.

### Order 37 (mesa), step a. **Result (Nov 21): done, merged.**

Two rounds read by fresh readers (four readers, no words); nothing after the second reading fell under the three kinds, so there was no fix pass. The orchestrator looked at both rounds and ran the maker itself: same bytes (its bake-time lines fail on a busy machine: 222 and 236 ms against 84 to 107 ms measured quietly).

- Files: `cocina-kit.js` (the kitchen's kit; this designer is its one writer), `mesa-set.html`, `mesa-sheet-make.js` (21,804 moments), `mesa-sheet.json`, `mesa-preview.html`.
- The room: the corner of two walls at screen (124, 86). Left wall: the counter with its white top and tile band, the wall cupboard, a doorway to the patio with its leaf open into the room, a handle, a threshold and El patio's step and lawn outside. Back wall: a small window with a bush, the kit's stove with its hood at the right edge. The table along x with an optional cloth, four chairs along its far side; the seats step down 12 rows each (a level row cannot lie on a world axis). People come in through the doorway: they appear on the step outside, seen in the opening, and walk behind the chairs.
- State parameters: `mantel` and `horno`; 3 baked states are reached and cover the 141 old ones (the rest is the sprite layer). One view. 23 of 24 pair pictures are close (zoom 2 windows of 98 x 52); `cocina.si` stays wide (the sheet says why).
- `cocina.no` (abuela outside the kitchen) is drawn on El colmado's stall, `frutas-set.html?surtido=frutas`; the sheet's `pictures["cocina.no"].port` says what the port needs to draw it before El colmado exists in Dart.
- 19 things, 26 positions (+4 from `h-mesa`), 12 pairs, 16 level pictures: all there. 43 moves and the story moves for `cual-mesa` are in the sheet with their reasons; the cards per story (`respEn` [98,20] or [123,20]) so that every card's hint hand avoids every face. One hop count changes (ranaa to rana.2, 3 to 2) on a pair no run walks.
- New checks, for the next scenes: a pair's yes and no differ in at least 1.5% of the picture; every head in a close picture whole; the pair's thing against a plain surface; no group of fewer than 6 floor pixels unlike what surrounds it (`noSpecks`).
- **Left, by Salim's rule:** the kit's stove is smaller than La estufa's own; the fourth chair stands at the table's corner and abuelo at the far end reads to one reader as "inside or behind the table end" (no chair seen under him); the open door's leaf is behind the top rows of the first sitter's face; the knife Luis holds up in la-cuchara is partly behind the table's corner; at three asks the rounds board covers the top 8 rows of the first card (the old cards touched it); white plates on the white cloth are hard to see; in `tengo_sed` the glass is at Carmen's mouth as in the old picture; `cocina.si` shows abuela's head only; the things on the stove are cut by the right edge as in the old picture; the hint frame on the counter's stacks stands at the left edge.
- Left as the old game has it: the big utensils shown beside heads with no hand; the voice cards that look alike; the hint hand over abuela's face at the counter's asks of `h-mesa` and over the boy in la-mesa (the old hand lay there too); the frame round the woman and the child together; people appearing and leaving; the cloth that comes and goes.

### Order 37 (mesa), step b. **Result (Nov 21): done; merged into `lane/cocina`, not yet on main (it goes to main with La cocina's build).**

Built by an Opus builder on `orden/37b`, with one stop. The orchestrator ran `test_all.sh`'s steps to the end itself on the branch with `lane/cocina` merged in: nothing red but the six tests that wait for the ten single-word recordings.

- Files: `coqui_scenes/lib/src/mesa/` (`mesa_set.dart`, `mesa_places.dart`, `mesa_sprites.dart`, `mesa.dart`, `mesa_frutas_still.dart`), seven tests, the sheet as an asset, `coqui/ref/pp/mesa/`. The kitchen's kit is La estufa's, unchanged.
- The set: the three reached states equal the JavaScript reference: 0 of 51,840 pixels differ. Sprites: 76 exact.
- The preview: 841 pictures, 838 identical, 0 over 2%, the most 0.02%.
- Recorded runs: all 12 (three stories and `h-mesa`) equal timeless, hop sounds and draws the old ones. Time: la-mesa about 0.5 s shorter, la-cuchara about 0.5 s longer, tengo-hambre 3.5 s shorter, h-mesa equal.
- **The stop:** in tengo-hambre the frog took 1 hop where the recorded run has 2 (from abuela's hand at the counter to seat 2): the design had moved `rana.2` by 6 px and its hop check covered only walks between named frog places. The designer's maker now replays every frog walk (181 walks) against the old page; `rana.2` is (118,169). The same check was given to La nevera's and A comer's designers before their ports.
- `cocina.no` (abuela at El colmado's stall) is drawn from a stored still of `frutas-set.html?surtido=frutas` (`mesa_frutas_still.dart`, made by `tool/make_mesa_still.dart`); it goes when order 52 (frutas) is merged: that port's builder is asked to say how the picture is drawn from the real scene.
- `mesa_asks_test`: at 179 asks (102 of the recorded runs, 77 of the app's own plays) the asked thing's box and the hint hand equal the JavaScript preview's; no box sits beside its thing.
- First bake in Dart (release web, median of five, a busy machine): the first state 155 ms (122 to 168; it also lays the floor), the others 80 and 40 ms; later bakes 28 to 44 ms. Left, as El banco's.
- A fresh reader of the real app's frames (four plays): people, the dishes arriving and the utensils going to people read; "frames are centred on what they mean; none sits beside it". What it flagged is in the old pictures too: the frog's thought bubble over part of abuela's face in tengo-hambre, the hint hand over abuela or the boy at the counter's asks, the cloth and the dishes cleared between rounds, asks with nothing framed (he must say a word), voice cards that look alike. New and left: whoever comes in is drawn in front of the open door's leaf for a step.

### Order 38 (estufa), step a. **Result (Nov 21): done, merged.**

Two rounds read by fresh readers (four readers, no words), then one fix pass for two hidden faces. The orchestrator looked at each round and ran the maker itself: ok, same bytes (its bake-time line fails when the machine is busy: 154 to 159 ms against 57 to 126 ms measured quietly).

- Files: `estufa-set.html`, `estufa-sheet-make.js` (checks 16,908 moments: every tick of the 12 runs of the three stories and of `h-estufa`, which the maker plays itself), `estufa-sheet.json`, `estufa-preview.html`, and the kit's copy.
- The layout: one run along the back wall, on the world's axes: the left counter from the corner, the stove (a wide range of the designer's own in the kit's look, its two burners far enough apart for a pot on each), the right counter running off the picture; a steel splashback and the hood joined to the wall with a duct; the shelf on two brackets; the window in a recess with a sill, the patio's wall and sky behind; the family at the window stands outside and is cut at the chest by the sill; the stool is La nevera's. Everyone at the run stands on clear floor in front of it.
- State parameter: `banco` (the stool) only; 2 baked states cover the 164 old ones (the rest is the sprite layer: pots, flames, steam, everything on the counters). One view. Pairs at zoom 2 except `hace`, `cuidado` and `huele`, which cannot hold their subject in the close window (the sheet says why).
- 17 things, 35 positions, 12 pairs, 16 level pictures: all there. About 40 moves in the sheet with their reasons: with one run on one axis the things on the left counter stand 45 to 55 rows higher than in the old picture and those on the right counter 10 to 25 lower; the cards at (146,20).
- The old file's fault is kept and named in the sheet's `faults`: `estufa.js` line 122 draws the baby whenever mamá has `p.bebe`, which is also the cup she is handed (line 125 skips the cup for her), so a cup she holds is drawn as the baby.
- **Left, by Salim's rule:** the stove here is bigger than the one La mesa shows at its edge; the left counter's things stand high at the upper left; the dark above the walls; abuelo's face at the window is 83% seen, as in the old picture (mamá's hair); the hint frame takes in both cups of rice and beans, as the old; no green shows outside the window, only the yard's wall and sky; the empty window can still read as a flat blue picture.
- Left as the old game has it: the twinkle over the frog; voice cards that look alike; the hint hand over the boy at the pot's ask; the pairs `huevo` and `frio` (two different pictures each), `sal` (a shaker in the air); people appearing and leaving; the crowd at the right counter.

### Order 39 (nevera), step a. **Result (Nov 21): done, merged.**

Two rounds read by fresh readers (four readers, no words); after the second reading nothing fell under the three kinds (what was flagged is in the old pictures too), so there was no fix pass. The orchestrator looked at both rounds and ran the maker itself: ok, same bytes.

- Files: `nevera-set.html`, `nevera-sheet-make.js`, `nevera-sheet.json`, `nevera-preview.html`, and the kit's unchanged copy.
- The room: the fridge against the left wall, facing across the room, whole in the view; the counter along the back wall to past the right edge, the sink and tap in it; over it the big window on the patio, 62 rows of outside as in the old picture (this set raises its own walls to 4.95 round its call of `cocinaBuild`; the other kitchen scenes keep the kit's 3.2), with the wall's reveal and a sill. **Whoever is outside is seen only through the opening**: 0 pixels of them outside it at 53,460 person-moments, the head 2 px inside all round, sky or the yard's wall over every head. Both second readers read them as people outside looking in.
- The fridge: shut, half open, open (the door leaf swung out at 150 degrees with its inner face and handle, a white inside tinted so that white milk shows: outline contrast 10 at the least), two shelves, a drawer that is a box joined to the fridge's foot with the fruit in it. The two places on a shelf stand one behind the other.
- State parameters: `nev` 0, 1, 2; `cajon` 0, 1, 2; `pila` empty, dishwater, juice; `banco`. 10 baked states are reached (of 30) and cover the 87 old ones. One view, x0 28 (the hint frames of things at the counter's right end fit). All 24 pair pictures are close (zoom 2).
- 26 things, 29 positions (+7 from `h-nevera`), 12 pairs, 16 level pictures: all there. About 90 moves in the sheet (the shelf places, everything on the counter and the sill, the people outside by a rule `PA`, the cards at [154,4] near the old row).
- Every walk of the frog checked against the old page from the start: 246 walks in 12 runs, 0 differ.
- Its own floor dimming (the kit's `cocinaOcclusion` dimmed the floor all along the counter's lit foot: a dotted fringe a reader could not explain). **For the kit:** a counter whose front slopes down to the right needs this; La estufa's run stands the same way.
- **Left, by Salim's rule:** the pair `leche` differs in 0.88% of the picture (the glass in Carmen's hand; no close window holds more with her head whole); the half-open door is barely open (a card hangs on the wall beside it) and its handle is turned away; the sill is about 2 rows above the counter's top at the window's left end; the stool has almost no shadow; the two glasses on the fridge's top can read as stuck on the wall; a shelf thing's foot is checked over its middle half only; the hint frame takes in more than one cup at the counter's right end, as the old; the fridge has one door and no freezer part.
- Left as the old game has it: fruit shown over heads (also over abuela's face), the ring bubble over mamá's face at the window, heads that overlap in the window, the frog at the counter's front, abuelo eating the apple at his face, the empty glass of `vacio` cut by the picture's top edge, abuela at the picture's right edge at the cups' asks, voice cards that look alike, people appearing and leaving.

### Order 38 (estufa), step b. **Result (Nov 21): done; merged into `lane/cocina`, not yet on main (it goes to main with La cocina's build).**

Built by an Opus builder on `orden/38b` with no stop. The orchestrator ran `test_all.sh`'s steps to the end itself on the branch with `lane/cocina` merged in: nothing red but the six tests that wait for A comer's ten single-word recordings.

- **`lane/cocina`** is the kitchen's integration branch: main plus `orden/06-comer` (A comer's groundwork) plus each kitchen port as it is checked. It exists because the course data that lists A comer cannot go to main before the ten words are recorded and a build that knows A comer is ready.
- Files: `coqui_scenes/lib/src/cocina_kit.dart` (the whole of `cocina-kit.js`, call for call; `test/cocina_kit_test.dart` compares 16 cases with the JavaScript run in headless Chrome by `tool/make_cocina_kit_ref.mjs`: pixels, depth, kinds and ground equal), `lib/src/estufa/` (`estufa_set.dart`, `estufa_places.dart`, `estufa.dart`), six tests, the sheet as an asset, `coqui/ref/pp/estufa/`.
- The set: both baked states equal the JavaScript reference: 0 of 51,840 pixels differ. Sprites: 83 exact.
- The preview: 678 pictures, 616 identical, none over 2%, the most 0.24% (edges of rotated sprites).
- Recorded runs: all 12 (three stories and `h-estufa`, three plans each) equal timeless; hop sounds and draws the old ones. Time: el-pollo-y-el-huevo and h-estufa equal whole; arroz-con-habichuelas 70 ms shorter; cuidado 2.2 to 2.5 s longer (walks to moved places).
- The window's family is drawn unclipped and the set's nearer pixels are drawn again over them, pixel for pixel as the preview; the stool is drawn at its place in the sorted list and never over the frog on it. The old fault (a cup mamá holds is drawn as the baby, estufa.js line 122) is kept.
- `Sheet` gained, on El banco's reader: a remap kind `rect`, a front part drawn after something at a world y, `talk.abuelaHead`, a board with no words, hops with counts only, `faults`.
- All 24 review pictures and 17 level cells draw (azúcar, A comer's, among them). Touch boxes hold their things; the pan's handle and the tray's edges stick out of their boxes exactly as in the old file.
- Bake in Dart (release web, median of five, a busy machine): the first state 98 ms (74 to 162), the other 40 ms; later bakes 17 to 18 ms.
- The app's story test (q) now follows the list of converted scenes (a converted scene's routine opens on its start disc), so no kitchen port has to change it.
- **An old fault that is fixed in the port, not copied (the orchestrator's decision; Salim told):** in el-pollo-y-el-huevo, `estufa.js` gives the drumstick the plate's left half as its box and the egg the right half, always, but draws the pieces by their order on the plate; once the drumstick is gone the egg lies alone on the left, and the old hint frame, hand and touch for the egg went to the empty right half (a touch on the egg itself counted as the drumstick). A fresh reader of the real app's frames saw the frame beside the egg. In Dart a piece's box is the half it is drawn in (`_onPlate`, `_pieceBox`). The recorded runs still pass (the old trace's touch still counts). New test `estufa_asks_test`: at 200 asks (105 of the recorded runs, 95 of the app's own plays) the asked thing's box, hand and drawn pixels against `estufa-preview.html`; the frames tool writes each ask's state (`ASKW=yes`). The sheet's words for `pzpollo` and `pzhuevo` still say "unchanged".
- A reader of the real app's frames also saw, and it is left: a pot looks a little raised over its burner once its flames are out; the hint hand cut by the picture's lower edge at asks low in the picture; the rounds board over the shelf's jars.
- For the content lane and the designers, found by the builder in the JavaScript sheet and not fixed (the port follows the preview): the sheet's words put the frog's surface point under (x+16, y+26) while its frog spots are under y+25; `spots.banco` projects one row above `points.banco`; a picture's `world` is the surface under (x, y-1), so a crop from it is one row higher than the sheet's `crop`.

## From the content lane (Nov 20 and 21): A comer is out; orders 50 to 57, the new scenes of El colmado and La calle

Written by the session that finishes A1's content (scripts, story files, reviews, recordings; page 00 has its state). It builds nothing under `coqui/`. Everything here is for the scenes lane.

### A comer (place 3, scene 4) is published on the old site, v=40

- On main: `historia/escenas/comer.js`; stories `que-quieres`, `buen-provecho`, `cafe-con-azucar`; pairs `cual-comer`; their books; La cocina's three do-this routines `h-mesa`, `h-estufa`, `h-nevera` (place `cocina` now has a `haz` list); four level-check items (`historia/nivel.js`). All recorded (140 clips, 3,938 characters).
- **`historia/datos/` was not exported again, on purpose.** With the three stories in `datos/curso.json`, `make_repaso.py` stops: the pairs of café, azúcar, un poco and mucho have no sheet (no `coqui/ref/escenas/comer/`), 25 older words gain sentences that no reader has judged (102 of them: pan, yo, come, arroz, más, mantequilla, aquí, papá, hay and others), and the three books have no verdict file. So, when this lane takes A comer: order 06 for `comer`, then `node coqui/tool/export_datos.mjs`, the readers' verdicts (books and pairs), `make_repaso.py --app`, `make_palabras_solas.py` (10 more words to record, about 75 characters), then the scene as the twelfth.
- Book verdicts by three fresh readers already exist, made from the sheets of `--hojas-libro` with the three stories in the course: `historia/notas/veredictos-comer/` (they validate; copy them into `coqui/tool/repaso/veredictos/` once the course data lists the stories; the tool refuses a verdict file for a book it does not know).
- Speaking turns: A comer's stories are the first with `tu_turno` (the story kit, page 16).
- A fault in the old `estufa.js`, for order 38: a cup held by mamá is drawn as the baby. `gen_escuchar_cocina.py` works round it with a hidden stand-in (`mama2`).
- Lengths at real speed, clean run, on the old site: 266 s, 305 s, 288 s. Salim has been told.

### La cocina's Escuchar picture stories wait for this lane's kitchen scenes

Four picture stories are written and generated (`historia/tools/gen_escuchar_cocina.py`: `d-cuchara-abuelo`, `d-comida-coqui`, `d-chocolate-luis`, `d-comida-parque`; script and the silent readers' findings in `historia/notas/guiones/escuchar-cocina.md`). With the acts the old kitchen scenes have, their stories do not read from the pictures alone, and the old site is frozen. They need plain acts in mesa, estufa and nevera, as El parque's scenes got: the list is the script's "Needs" (anda, da, toma, deja, come, bebe, gesto, cosa, perro, sinmarcador, and three scene notes). Add them when orders 37b to 39b are written; the story files are not on main until then.

### Orders 50 to 53. El colmado (place 4): mostrador, estantes, frutas, caja

New scenes: there is no old scene file and no `ref/escenas/` folder. Step a (design) is done by the content lane. Step b is this lane's.

**What exists, in `docs/proyecto/pixel/`** (all on main):
- The room and the shop front, shared: `colmado-dentro.js` (inside: counter, register, two runs of shelves, ladder, freezer, chair, doors, shop window) and `colmado-fuera.js` (the front from the street: wall, door, sign, awning, the slanted stand with two assortments, the hanging scale, the hand cart, the low crate, the post).
- Per scene `<id>-set.html` (the baked set, states from the address), `<id>-sheet-make.js` (writes `<id>-sheet.json` and checks it; all four exit 0), `<id>-preview.html` (a dev tool: stand-in sprites over the set at each story moment; `?m=N`).
- `mostrador`: states `donde` dentro or calle, `hora`, `atras`, `nevera`, `puerta` (calle); views `dentro` (x0 21) and `calle` (x0 22), both zoom 1; 47 spots. `estantes`: `anillos`, `mesa`; one view (x0 6); 42 spots. `frutas`: `hora`, `puerta`, `carro`, `surtido` verduras or frutas; one view (x0 21); 23 spots. `caja`: `hora`; one view (x0 17); 25 spots, the two key cards and the amount plate (`importe`).
- Three rounds of fresh readers saw the sets with no words; what they found is fixed (the outside read as a mirror, a truck as a blue box, bins that could not be told apart, a dark room).
- Bake, headless Chrome on the build machine: frutas and mostrador calle 70 to 110 ms; the three inside states 160 to 270 ms. Over the 150 ms limit, as balcon's first bakes are. Not solved.

**The stories.** Scripts with their reviews and a "Needs" list each: `historia/notas/guiones/mostrador.md` (stories 36 to 38), `estantes.md` (39 to 41), `frutas.md` (42 to 44), `caja.md` (45 to 47). Generators: `historia/tools/gen_mostrador.py`, `gen_estantes.py`, `gen_frutas.py`, `gen_caja.py`: run one and it writes its three story files into `historia/cuentos/` (the checker passes all 12 with 0 errors; 4,224 paths walked). **The story files are not on main and must not be pushed**: a push under `historia/cuentos/` records them (369 clips, 13,133 characters), and they are recorded only after they have been played in the app. Keep them out of git locally (`.git/info/exclude`). With them in `historia/cuentos/`, `make_repaso.py --check` and `make_palabras_solas.py --check` report stale data: that is these files, not a fault.

**Step b, one scene at a time (builder, coqui_scenes), in the order mostrador, estantes, frutas, caja:**
1. `buildSet` call for call from the set file and the shared file; every baked state within 0.5% of the JavaScript.
2. The scene written new from the script's "Needs" list: every act, thing, spot, view and speaker key it names, with positions from the sheet only. **Stop if** a position has no name in the sheet, or an act's picture is not settled by the script: the content lane decides and adds it.
3. Sprites: don Pepe (standing, reaching up, sitting with a fan, on the ladder), the three children, the goat, and each thing the Needs lists name. The previews' stand-ins show size and place, not the final drawing. The señora and the señor are El banco's. New sprites are design: the content lane looks at each sheet of them before the port goes on.
4. The sheet's rules hold in the scene: the frog is never behind a grown-up; nothing stands on the amount plate; the two children outside the shop window show only through its panes and the third stands in the doorway; a customer's thing has its price tag at the sheet's `etiqueta` offset.

**Done when:** every state within 0.5% of the reference; every touch box contains its thing; `tool/juega.dart` plays each of the scene's three stories on every path the checker walks, to the end, right and wrong; a fresh reader of the frames with no sound and no words says what happens in each story. Then the content lane measures length and silences, records, and makes the place's pairs, Escuchar set, books and level items.

### Orders 54 to 57. La calle (place 5): esquina, parada, tiendas, cruce

New scenes, as El colmado's: no old scene file, no `ref/escenas/` folder. Step a (design) is the content lane's; step b is this lane's, after El colmado's four.

**What exists, in `docs/proyecto/pixel/`:**
- `calle-base.js`: the streets' shared kit (painters for faces and tops, pavement, asphalt, kerb; a wall along x and along y; a door, a picture sign, a window, an awning; a house front; a tree; a traffic light whose three lamps show unlit; a cone; a seat; a sign on a pole; the sky by hour) and `vehicle(kind, x, y, heading, board)`: the red car, the blue car and the guagua, built on the engine. In the game they are sprites: bake each once from this function (both headings; the guagua with each of its three roof pictures: `arbol` the park, `toldo` the colmado's basket, `casa`), so that the port and the readers' pictures come from one drawing. A bicycle with its rider is not drawn yet.
- `esquina-set.html`: the colmado's corner at a T-junction. States `hora` manana or tarde, `obra` 0 or 1 (the far lane dug up, a barrier and cones, no stripes; two squares of cement in the near pavement), `puerta`. The traffic light's lit lamp is a sprite.
- `parada-set.html`: a bus stop on a street of houses. States `hora` temprano, manana, tarde, noche (noche: lit windows, the lamp and its pool of light).
- `tiendas-set.html`: `fila` tiendas (four fronts with picture signs: toys, coins, a green cross, a letter; a little horse; a post box; a seat) or altos (a tall old building and a low new one; `par` a or b, `lado` izq or der: four baked states); `hora`; `nube` 0, 1, 2 (the sky and the light; rain itself is a sprite layer).
- `cruce-set.html`: a crossing drawn square to the picture: its streets are turned 45 degrees to the engine's axes (the set's `E.xy(u, v)` and `E.uv(x, y)`), so that the frog's left is the picture's left. States `hora` mediodia, tarde, ocaso; `cerrada` 0 or 1 (a barrier and cones across the right street). Two views of one picture, `wide` and `plaza`.
- One fresh reader saw each set with no words; what was not read is fixed. Bake, headless Chrome on the build machine: 55 to 110 ms for every state.
- Sheets (`<id>-sheet-make.js`, `<id>-sheet.json`) and previews (`<id>-preview.html`, `?m=N`): done for all four; every make exits 0 (esquina 10 checks, 43 spots, x0 12; parada 14 checks, x0 4, the second guagua cut at its back end by the window; tiendas 11 checks, x0 4, and x0 10 for `fila=altos`; cruce 11 checks, `wide` x0 6 and `plaza` x0 44). The checks that matter most to the port: two sprites that stand together never overlap unless their feet are 12 px apart up-down; the frog is never behind a grown-up, a car or a guagua; a guagua that stops in story 49 or 50 stands in the near lane (in the far lane it hides the colmado's corner, where the frog is). The orchestrator looked at every preview moment.

**The stories.** Scripts with their reviews and a "Needs" list each: `historia/notas/guiones/esquina.md` (stories 48 to 50), `parada.md` (51 to 53), `tiendas.md` (54 to 56), `cruce.md` (57 to 59). Generators: `historia/tools/gen_esquina.py`, `gen_parada.py`, `gen_tiendas.py`, `gen_cruce.py`, run in that order after El colmado's four (each sees what was recorded before it). The checker passes all 12 with 0 errors. As El colmado's, the story files are not on main and must not be pushed until they have played in the app.

**Step b** and **Done when**: as orders 50 to 53. Two things are new for this place: sprites that drive (they come along a lane, stop at a named spot, drive on; a person in front of one is drawn after it by the sheet's depth rule), and the frog pressing a button on a thing that is itself a sprite (the guagua's doors in story 52).

### Orders 58 to 61. La plaza (place 6): plaza, reloj, quiosco, calendario

New scenes, as La calle's: no old scene file, no `ref/escenas/` folder. Step a (design) is the content lane's; step b is this lane's, after La calle's four.

**What exists, in `docs/proyecto/pixel/`:**
- `plaza-base.js`: the square's shared kit (`PZ`). Everything in this place is laid out square to the picture, in u, v (u across, v down towards the camera; `PZ.xy(u, v)`, `PZ.uv(x, y)`: the same turn as El cruce's). A wall that faces the camera is drawn pixel by pixel with set-kit's `planeQuad` (`PZ.wall`, `PZ.flat`, `PZ.slope`), so a clock's numerals and a board's pictures keep their shape. Pieces: paving, a box, a post, a seat (and one seen from its end), a flower bed, a hedge, a lamp (lit when `PZ.NIGHT`), paper flags, the far clock tower in the sky, the sky and the light by the hour.
- `plaza-set.html`: the bench under the tree. States `hora` manana, mediodia, tarde; `tablero` 0 or 1 (the notice board: the island, the city, a row of five hooks under each, a ledge); `carrito` 0 or 1 (the piragüero's cart).
- `reloj-set.html`: the clock tower's foot. The face has its twelve numerals and no hands: the two hands are sprites that turn about `E.FACE` (the long one 19 px, the short one 12 px). A balcony with a rail, a ladder, the little door of the three figures (three shutters), the works' flap, the quiosco's counter with its fryer. States `hora` mediodia, tarde, ocaso; `mesas` 0 or 1 (three bingo tables, the cage's stand, the prize shelf).
- `quiosco-set.html`: the stand, close: a roofed booth with a U of counter open to the camera, the four stools outside its wings (whoever sits there is seen from the side), a round table with two chairs, a cup sign on the roof. States `hora` mediodia, tarde; `fiesta` 0 or 1 (paper flags).
- `calendario-set.html`: the board of the week: seven columns (five green squares, two orange), three hooks in each, an arch of flags with its own hook over the two orange ones, a step for the frog, a seat seen from its end, two lamps, a bandstand behind. States `hora` manana, tarde, noche (the lamps lit, a pool of light under each); `tela` 0 or 1 (a striped cloth over the last three columns).
- One fresh reader saw each set with no words. Read at once: the clock and all twelve numerals; the board as a week of five days and two, three slots a day; the stand as a U with four stools. Fixed after the reading: the bench was a slab (slats, arm rests, the tree clear behind it); the stand read as a book kiosk (the cup sign); two stools in one line read as one; the tower's flap (a cog on it); the bingo's shelf stood against the stall; the board's cloth was a grey wall (striped, on a rope); lamps that lit nothing; dotted post shadows.
- Sheets (`<id>-sheet-make.js`, `<id>-sheet.json`) and previews (`<id>-preview.html`, `?m=N`): done for all four; every make exits 0 (plaza 10 checks, reloj 14, quiosco 16, calendario 14; x0 22 in all four). It took two to three passes each: my first positions put people in front of the frog, an awning or a roof's edge over a seller's head, and three people on a seat with their heads behind one another. What the checks now hold, and the port must keep: the frog is whole in every moment; a seller's head and paper hat are clear of his awning; the frog on a table may stand in front of whoever sits behind it, but covers no more than a tenth of a head; a card on a hook never covers a hook's neighbour; nobody covers the notice board's pictures. The orchestrator looked at the preview moments.

**The stories.** Scripts with their reviews and a "Needs" list each: `historia/notas/guiones/plaza.md` (stories 60 to 62), `reloj.md` (63 to 65), `quiosco.md` (66 to 68), `calendario.md` (69 to 71). Generators: `historia/tools/gen_plaza.py`, `gen_reloj.py`, `gen_quiosco.py`, `gen_calendario.py`, run in that order after La calle's four. The checker passes all 12 with 0 errors. With places 4 and 5 that is 59,868 characters still to record (inside the free 500,000 a month). As before, the story files are not on main and must not be pushed until they have played in the app.

**Step b** and **Done when**: as orders 50 to 53. New for this place:
- Things that are touched but are not in the world: the two answer bubbles over the frog (story 60), the two time cards (63), abuela's bingo card shown big (65: five squares). Their boxes are in the sheets, in screen pixels.
- Sprites that turn about a point (the clock's hands, with the frog riding the long one: the sheet's `mano_arriba`, `mano_abajo`, `mano_lado`).
- A decision with more than one right answer: story 70's "el fin de semana" uses the engine's `vale` (the arch, the sábado column or the domingo column).
- When he waits, the old engine says a round's `line` again, and only that. In rounds where two people speak (62, 67) or one person says two things, the whole round's lines should be said again, in order: with only the last one a learner who waits hears half the clue.
- New people to draw (looks in the scripts): Ana, her mamá, Beto, her abuela, six visitors with maps and cameras; don Tito; the vendedor; the maestra, the doctor, the cocinero and the policía in work clothes; a young woman. New speaker keys: `ana`, `mama_ana`, `abuela_ana`, `beto`, `tito`, `vendedor`, `maestra`, `doctor`, `cocinero`, `policia`, `la_joven`, `nino`, `nina`.
- Beats the scripts show for which no act is named are listed in each generator as comments (a walk-on, somebody lifting a thing): the port may fold each into the act beside it.

### Orders 62 to 65. La playa (place 7): orilla, sombrilla, ropa, cielo

New scenes, as La plaza's. Step a (design) is the content lane's; step b is this lane's, after La plaza's four.

**What exists, in `docs/proyecto/pixel/`:**
- `playa-base.js`: the beach's shared kit (`PL`), on top of `plaza-base.js`'s painters (everything is laid out square to the picture, in u, v). `PL.ground(u, v, ix, iy, B)` paints a beach from four numbers (the water's edge, the wet strip's width, where the sea turns dark, the horizon): foam, shallow and deep sea with lines of small waves, wet sand, dry sand with ripples. Pieces: a palm (set-kit's `swayPalm`: its fronds sway, so each set's `frame()` calls `drawLeaves`), a striped blanket, a beach umbrella (open or shut), a heap of sand, a bucket, the sky and the light by the hour.
- `orilla-set.html`: the shore. States `hora` manana, mediodia, tarde, ocaso; `castillo` 0 or 1 (a sand castle with three towers and, in front of it, a patch of damp raked sand); `manta` 0 or 1 (abuela's blanket); `bote` 0 or 1 (the fishing boat far out, for the readers' pictures: in the game it is a sprite). Two palms with a rope between them.
- `sombrilla-set.html`: abuela's umbrella with a blanket in its shade, and a damp oval of sand to draw on. States `hora` mediodia, tarde, sol; `dibujo` circulo (a big circle: a face to be) or figura (a lying figure: a round head, two arms with five-line hands, a body, two legs with feet). The lines are part of the ground; the shells, seaweed and stones laid on them are sprites.
- `ropa-set.html`: two palms with a line between them, a cabin with a striped curtain, a bench, the sea at the top and the road at the foot. States `hora` tarde, ocaso; `guagua` 0 or 1 (the guagua at its stop, its door open: a wall that faces the camera, not `CL.vehicle`).
- `cielo-set.html`: an open wooden deck with a table and a rocking chair, and the sky as the upper half of the picture. States `cielo` azul, nublado, gris, rosa, noche (the moon, one big four-pointed star, a long pale cloud, small stars: all painted by the set, in screen pixels given in `E.SKY`); `toldo` arriba or abajo (a blind on a beam at the deck's back: it comes down BEHIND the table). There is no roof over the deck, and nothing over a seller's head anywhere in this place: in this camera a roof hides whoever is under it.
- One fresh reader saw each set with no words. Read at once: the shore, shallow and deep water, the wet strip; the umbrella and the stick figure with its parts; the line between the palms, the cabin, the bench, the guagua and its stop; every sky (clear, overcast, night with the moon biggest and the star brightest, cloudy, dusk). Fixed after the reading: the patch of sand could not be seen (it is damp and has a pale rim, clear of the castle's shadow); the castle's towers read as jars (taller, with windows and battlements); the bag read as a box and the seaweed as melons; the figure's arms were too long for its head; the guagua's open door read as shut; the rope was too pale to see.
- Sheets (`<id>-sheet-make.js`, `<id>-sheet.json`) and previews (`<id>-preview.html`, `?m=N`): done for all four; every make exits 0 (orilla 14 checks, x0 25, because Canelo's drawing is 30 px wide; sombrilla 13, ropa 13, cielo 15, all x0 22). My first positions failed again in the same ways, and the makes now hold the corrected ones: nobody stands behind a palm's trunk or under its fronds (Luis and his boats sit on the open half of the wet sand; in La ropa's story 79 the family stands in FRONT of the line and only the frog is behind it, low enough that the line and its pieces clear him; the fifth thing afloat is to the right of the right palm); nothing hangs or stands over a thing he has to touch (the towels on the rope, the pile, the patch of sand, the spiral shells, the shoes); the pair on the bench is 28 px apart; the four children of story 80 stand above the stop's sign. In El cielo the radio stands at the back of the table and the candles at its front (the left candle covers 11 px of it), the frog on the deck is to the right of abuela's knees, and the shawl lies folded on the deck by her feet (the chair has no arm to hang it on). Stand-ins the art still owes: a person sitting or kneeling on the sand, abuela lying down, the frog's boat, Canelo's poses.

**The stories.** Scripts with their reviews and a "Needs" list each: `historia/notas/guiones/orilla.md` (stories 72 to 74), `sombrilla.md` (75 to 77), `ropa.md` (78 to 80), `cielo.md` (81 to 83). Generators: `historia/tools/gen_orilla.py`, `gen_sombrilla.py`, `gen_ropa.py`, `gen_cielo.py`, run in that order after La plaza's four. The checker passes all 12 with 0 errors; every new word is heard three times or more on every clean path. With places 4 to 6 that is 73,623 characters still to record (inside the free 500,000 a month). The story files are not on main and must not be pushed until they have played in the app.

**Step b** and **Done when**: as orders 50 to 53. New for this place:
- Water: a sprite layer of waves that run up the wet sand and back; people who wade (to the ankles, to the knees); things that float, are pushed in by the frog, or are carried out by a wave.
- Touch places that are painted ground: the sea's edge and the patch of sand (72); the parts of a face and of a lying figure drawn on the sand (75 to 77). Their boxes are in the sheets.
- Two decisions take more than one right answer through the engine's `vale` (75: either eye; 76: either arm, either hand).
- Two look-alike children who each do the opposite thing with the same piece of clothing, over and over, until one is touched (80: `pareja80`).
- The sky's things are touch places in screen pixels (the small cloud, the moon, the big star), and a round picture opens beside the telescope (83).
- A voice with no body: the radio (speaker key `radio`; a bubble over the set shows who is talking).

### Orders 66 to 69. La fonda (place 8): entrada, pedido, comida, cuenta

New scenes, as La playa's. Step a (design) is the content lane's; step b is this lane's, after La playa's four.

**What exists, in `docs/proyecto/pixel/`:**
- `fonda-base.js`: the fonda's shared kit (`FD`), on top of `plaza-base.js`'s painters (u, v). These are the first INDOOR sets on the engine: a floor (v >= 0) and a back wall that faces the camera at v = 0, painted pixel by pixel; a door, a window or a hatch is a hole in it with something painted behind it, so whoever stands behind the wall is seen in the hole and the wall hides the rest of him. No side walls, no ceiling. Pieces: clay tiles, a terrace's boards, the wall's paint (boards to a chair's height, a rail, plaster), what a door or window shows by the hour, a wall lamp that glows, a table with its cloth, a chair at a table's far side, a chair at a table's end, `setTable` (a table with its chairs: it returns the seats' places, kept in each set's `E.SEATS`). Whoever sits at a table sits along its far side, facing us, or at an end.
- `entrada-set.html`: the room seen from inside: the open door at the left with a runner rug, a bench against the wall, the mesera's stand, a rope on two posts running down the picture, three tables one behind another (mesa1 the far one), the vellonera, a window, the kitchen's swing door. States `hora` ocaso, noche, tarde_noche (what the door and the window show); `cuerda` puesta, abierta.
- `pedido-set.html`: the family's long table, and in the back wall the kitchen's hatch with its shelf (plates and the frog stand on the shelf; the cocinero is seen in the hole from the chest up, in front of the kitchen's own back wall), two chalk boards with four panels each (the pictures on them are sprites), a hook, a stool; the next table at the lower right. One state.
- `comida-set.html`: the terrace at night: boards, a rail with a string of small lights (low, behind everyone), the dark sea and the night sky, a long table, the mesera's sideboard at the right (a low top for the frog and a shelf above it for four things), a serving table with the big pot at the left. One state. No roof.
- `cuenta-set.html`: the front of the fonda: a long counter (a glass case of desserts, the spike of slips, the register with its drawer, a bowl of mints), the kitchen's door at the far left, the open door at the right, and between them a window that shows the street with three lamps. States `guagua` no, lejos, medio, cerca (the guagua's lights in the window); `sillas` abajo, arriba (the next table's chairs up on it at closing time).
- One fresh reader saw each set with no words. Read at once: a dining room with a way in, a place to wait and tables to sit at; a serving hatch into a kitchen; a deck over the sea at night with string lights; a counter with a register and a display of pastries, and something small driving along the street in the window. Fixed after the reading: the two menu boards read as windows (they are chalk boards now, with a chalk fork and knife and a chalk glass at the top); the sideboard read as a bunk bed or crates (it has doors, knobs and feet); the rope was a thin red line among red things (it is a thick gold rope); chair backs with no seats read as ladders (the chairs stand a little back from the tables, so the seats show); the window on the street could be a painting (it has a sill); the open door could be a window (it has a doormat).
- Sheets (`<id>-sheet-make.js`, `<id>-sheet.json`) and previews (`<id>-preview.html`, `?m=N`): done for all four; every make exits 0 (entrada 15 checks, x0 21, because the right-hand chairs reach column 216; pedido 14, comida 14, cuenta 13, all x0 22). This time the builders were told to move a failing spot the least distance that passes and to list each move (the sheets keep the list under `moves`), and I changed the sets where a move was not enough: the next table's two chairs are .94 apart (two grown-ups are 24 px wide each); the terrace's serving table is wider, so that the pot, the frog and his bowl all stand on it; the dessert cart stands .2 further right, so that the frog on it is clear of Carmen's chair. What the checks hold, and the port must keep: the frog is whole in every moment; nobody's head at a table is covered; a plate, a drink, a candle, the card machine, the jar and the drawer are covered by nobody when they can be touched; the cocinero's head is inside the hatch's hole; whoever stands behind the counter or the cart is whole from the waist up; the family waiting in the doorway covers none of the window's lamps or of the guagua's lights. Stand-ins the art still owes: the mesera, the mesero and the cocinero (any grown-up maker was used), abuelo, the cat, the dessert cart, a stool, cloths, plates, drinks.

**The stories.** Scripts with their reviews and a "Needs" list each: `historia/notas/guiones/entrada.md` (stories 84 to 86), `pedido.md` (87 to 89), `comida.md` (90 to 92), `cuenta.md` (93 to 95). Generators: `historia/tools/gen_entrada.py`, `gen_pedido.py`, `gen_comida.py`, `gen_cuenta.py`, run in that order after La playa's four. The checker passes all 12 with 0 errors; every new word is heard three times or more on every clean path. With places 4 to 7 that is 100,693 characters still to record (inside the free 500,000 a month). The story files are not on main and must not be pushed until they are recorded.

**Step b** and **Done when**: as orders 50 to 53. New for this place:
- Indoor depth: a person behind a wall's hole (the cocinero in the hatch, the mesera behind the counter) is drawn by the same depth rule as outdoors; nothing new in the engine, but the ports must keep the hole and the wall behind it as two planes.
- Tables' cloths change colour (85): a sprite over the table's top and front, in five colours.
- Things that stand on a shelf, a table or a counter and are pushed across by the frog (plates, drinks, the card machine); a tray of two or three things whose order is drawn.
- A round's clue is often the second of two spoken lines (a question, then the answer that decides): the decision's `line` is the answer.
- Misses filed by what he touched (88, 91): `tests` is built from the draw and the touch through `palabras`.
- A state that is the stake: the guagua's lights in the window (95) move one lamp nearer at each mix-up.
- Voices: three new speaker keys (`mesera`, `mesero`, `cocinero`) and `abuelo`.

### Orders 70 to 73. La casa, un día entero (place 9): cuarto, bano, sala_dia, noche

New scenes, as La fonda's. Step a (design) is the content lane's; step b is this lane's, after La fonda's four.

**What exists, in `docs/proyecto/pixel/`:**
- `casa-base.js`: the house's shared kit (`CS`), on top of `fonda-base.js` and `plaza-base.js` (u, v). Indoor sets, as La fonda's: a floor and a back wall at v = 0 painted pixel by pixel. Pieces: a wooden floor, the wall's paint, bathroom tiles, what a window shows by the hour (alba, manana, tarde, noche), a window, a wall clock with no hands (the hands are sprites), a door (shut or open), a bed, an armchair, a sofa, a rug, three kinds of lamp (standing, small, on the wall) that glow when lit. A bed stands with its head to the back wall and runs towards the camera, so that whoever lies in it is seen whole, head at the top.
- `cuarto-set.html`: the children's bedroom: a wall light with its switch, a window, a clock, the door at the right; Luis's bed (blue) and Carmen's (pink) side by side with a night table between them; an armchair at the far left, a cradle in the right back corner, a chair at the right front, a rug. States `hora` alba, manana; `luz` 0, 1 (the wall light: at dawn the room is dim until it is on); `cuna` 0, 1; `butaca` 0, 1.
- `bano-set.html`: the bathroom: at the left the shower, a tiled corner with a wall across its front as high as a child's chest (whoever stands in it is seen from the chest up; Canelo in it is not seen at all), its head on the back wall and its tap outside it, on the wall at its right; in the middle the sink with its tap and the mirror over it, a shelf at each side; at the right the water heater with its gauge (the three bars are sprites) and the door; a wide stool, a basket. One state.
- `sala_dia-set.html`: the living room in the afternoon: a clock, a window with the low sun, a shelf of books, the kitchen's door; a desk with a computer at its left end and a chair behind its right end; a low table with two cushions along its far side; an armchair with a small round table at its left. States `pantalla` 0, 1 (the computer's screen).
- `noche-set.html`: the living room at night: at the far left a wide arch, a hole through which a corner of the bedroom shows, with a bed; a standing lamp, a window with the moon, a small lamp on a wall shelf, a clock, a sideboard with a wall lamp over its right end; a sofa and an armchair that face us, a rug; the television at the left front; at the right front the dinner table with four chairs along its far side. States `luz1`, `luz2`, `luz3` 0, 1 (the room is a little brighter with each lamp lit); `tele` 0, 1; `mesa` 0, 1; `oscuro` 0, 1 (every lamp out: only the moon).
- A fresh reader saw each set with no words. Read at once: a shared bedroom with two beds, a night table, a window and a door; a tiled bathroom with a sink, a mirror and a shower; a living room or study with a desk, a computer and books, late in the day; a living room at night with lamps, a sofa and a television. Redrawn after the reading: the shower, the water heater, the cradle, and the room's light at dawn. Still weak, and said so by the readers: the desk's chair, seen from behind the desk, can read as a small ladder-back thing on it; the open doors read as dark doorways.
- Sheets (`<id>-sheet-make.js`, `<id>-sheet.json`) and previews (`<id>-preview.html`, `?m=N`): done for all four; every make exits 0 (cuarto 13 checks, x0 22; bano 17, x0 20, because abuela in the door reaches column 215; sala_dia 14, x0 22; noche 15, x0 22). The sheets keep the list of every spot that was moved under `moves`. What I changed in the sets and the positions after the builders' reports: the shower's wall is 1.2 high, not .8 (so that it hides whoever bathes, and the dog); the dinner table's four chairs are wider apart (two grown-ups side by side are 24 px each); the two children in the bed seen through the arch lie at the pillow's two ends; abuela by the window, abuela with her camera, and the frog on the rug and by the big pillow stand clear of the others. What the checks hold, and the port must keep: the frog is whole in every moment; the head of whoever sits or lies is covered by nobody; the taps, the mirror, the gauge, the lamps' shades and the television's screen are covered by nobody when they can be touched; the things on the shelves, the night table, the low table and the sideboard are covered by nobody; the heads of the two in the far bed are inside the arch's hole.
- Stand-ins the art still owes: abuelo sitting and asleep, a child lying in a bed and sitting up in it, the baby in the cradle, a child in a raincoat with its hood up, a child with a towel on his head, abuela's camera and her knitting, Canelo eating, sitting and under a bed (his nose), blankets, the big pillow, the bell, clothes on a chair, towels, the soap, the toothbrush, the comb, the telephone, the book, the pad, the album and its photos.

**The stories.** Scripts with their reviews and a "Needs" list each: `historia/notas/guiones/cuarto.md` (stories 96 to 98), `bano.md` (99 to 101), `sala_dia.md` (102 to 104), `noche.md` (105 to 107). Generators: `historia/tools/gen_cuarto.py`, `gen_bano.py`, `gen_sala_dia.py`, `gen_noche.py`, run in that order after La fonda's four. The checker passes all 12 with 0 errors; every new word is heard three times or more on every clean path. With places 4 to 8 that is 111,587 characters still to record (inside the free 500,000 a month). The story files are not on main and must not be pushed until they are recorded.

**Step b** and **Done when**: as orders 50 to 53. New for this place:
- Whoever lies in a bed is drawn on the bed's own plane, not upright: his sprite hangs from the pillow by its head, runs down the mattress and is cut at the bed's foot, with a blanket over him from the chest (the sheets call this `hung` in cuarto and `lying` in noche; the rule is written in each sheet's notes). Sitting up in bed is the same sprite with the blanket from the waist.
- Light is a state: the wall light at dawn (96), the three lamps and the television at night (105), every lamp out at the end (107). A lamp that is lit glows; the room's light follows the count of lamps.
- A clock's hands are sprites and are set by the story (97, 104, 106).
- Two things the frog pushes or carries in a drawn order (the towels of 99, the clothes of 98, the pages of 104); a pair whose order is the answer ("primero ..., después ...").
- A thing with two places to touch on one person (abuelo's ear and his mouth, 103): two small boxes on his head, kept apart by the sheet.
- Water that runs and stops (the shower, the sink's tap), bars on the heater's gauge that go down (100), Z's over a sleeper that are lost one by one (97).
- The second child told to rest on the sofa takes the second seat (`sofa_pies2`, 107); the generator passes the seat.
- Voices: `abuelo` speaks in every scene; mamá is heard on the telephone only (103).

### Orders 74 to 77. El fuerte (place 10): subida, musica, regalos, muralla

New scenes, as La casa's. Step a (design) is the content lane's; step b is this lane's, after La casa's four. These are the last four scenes of A1.

**What exists, in `docs/proyecto/pixel/`:**
- `fuerte-base.js`: the fort's shared kit (`FT`), on top of `fonda-base.js` and `plaza-base.js` (u, v). The fort is sand-coloured stone. Pieces: the masonry, battlements (the sky shows between them), an opening with a round top and its ring of stones, flagstones, a path of pale stone on grass, the night sky with a moon and the moon's road on the sea, the afternoon and evening sky, an iron wall lamp that glows, a sentry box (a small stone tower with a stepped dome, a door and a lit window), a cord (for lanterns, a curtain, photos), a stool, the yard's inner wall, a string of small lights, a party table with a checked cloth.
- `subida-set.html`: the lawn in front of the fort: the wall across the whole back with its gate (an arch: a hole, with a dark passage behind), a lamp at each side of the gate, a pole over it (the flag is a sprite), a sentry box on the wall's top at the right, the sea and the sky over the wall; a path from the picture's foot to the gate; a tree with a flat stone beside it; with `fiesta` 1 a party table at the right and a hammock's two posts at the left front. States `hora` tarde, ocaso, noche (noche: the gate's lamps are lit); `fiesta` 0, 1.
- `musica-set.html`: the fort's yard at night: the inner wall with four lamps and a string of lights; at the left a low stage of boards with two stools and, at its right end, a rack for two instruments; the open floor; a long bench against the wall at the right; a stool beside the floor. One state. The instruments, the microphone (it stands on the floor beside the stage) and the three paper notes over the stage are sprites.
- `regalos-set.html`: a corner of the yard: at the far left of the wall a wide arch, a hole through which the dance floor shows (its own far wall with a string of lights; the dancers there are sprites, seen in the hole); a cord across the arch for the curtain (a sprite); a bench just right of the arch; a cord on the wall with four pegs for photos; a long table with a blue checked cloth; a step stool between the wall and the table at the right; a low stool in front of the table. One state.
- `muralla-set.html`: the top of the fort's wall at night: the walk; the low parapet at the back with the sea, the moon and the stars beyond, and at the right, far below, a point of land with the road; two sentry boxes on the walk, the left with a red door, the right with a blue door; a cord between them for three lanterns (sprites); a long bench against the parapet; a table at the left front; the head of the steps (a hole in the walk, with a rail) at the right front. States `hora` noche, tarde_noche (the moon low and yellow).
- One fresh reader saw each set with no words. Read at once: a lawn in front of a fort's wall by the sea, with an arched gate, a turret and a flagpole, by day, at sunset and at night; a paved yard at night set up for a party, with a small stage and two stools; a yard at night with an arch, a bench, a long table and two cords on the wall; a terrace high on a wall above the sea at night, with two small towers (a red door, a blue door), a bench, a table and a way down. Fixed after the reading: the party table read as a market stall with a red awning (it has a checked top and a striped apron now, and the hammock's posts no longer stand under it); the sentry boxes' domes read as rocks or sacks (stepped domes with a knob); the flag pole's shadow read as a dark streak on the lawn (it casts none); the arch showed a flat patch (the dance floor's far wall and its lights give it depth); the tables on the yard and on the wall read as slabs (the same checked cloth). Still said by the readers and left: the rack on the stage is an empty frame until the instruments hang on it; the two cords in the yard read as rods until something hangs from them.
- Sheets (`<id>-sheet-make.js`, `<id>-sheet.json`) and previews (`<id>-preview.html`, `?m=N`): done for all four; every make exits 0 (subida 14 checks, x0 22; musica 12, x0 22; regalos 18, x0 19, because the curtain at the far left and abuelo on the step stool at the far right span the whole window; muralla 17, x0 22). The sheets keep the list of every moved spot under `moves`. What I changed after the builders' reports: the three lanterns of story 110 hang in a row over the gate's arch (on stakes beside the gate, the guests behind the table covered them); the yard's floor stool stands further in, so that abuela sitting on it is inside the window; nobody is drawn hiding behind the presents' table (they are simply not seen, and come up at three spots); Carmen dances on the open side of the half-open curtain; the lanterns' cord on the wall's top is a sprite drawn behind everybody, not part of the set (as part of the set it crossed the heads on the bench and the guagua); abuela stands beside her camera, not in front of it; the family at the end stands clear of the guest on the bench. What the checks hold, and the port must keep: the frog is whole in every moment; the head of whoever sits is covered by nobody; the hooks' lanterns, the flag and the paper on the tree are clear of the tree's leaves and of people; the instruments on the rack, the paper notes, the microphone, the things on the bench and on the tables, the photos on the cord and on the table, the cake, the packet on the low stool, the candle on the parapet and the lanterns are covered by nobody when they can be touched; the two doors of the sentry boxes are covered by nobody in story 117's game; the guagua on the road below is covered by nobody.
- Three drawing rules that are new here and are written in the sheets: whoever is inside a sentry box is drawn from the head down, clipped to the door's box; whoever is beyond the arch is seen only inside its hole; the guagua and the two small figures on the road are placed in picture pixels (they are far away), behind everything.
- Stand-ins the art still owes: the two músicos (one with a hat, one with a beard), sitting, with the guitar and with the drum; don Pepe, the maestra, the piragüero, the señor, the señora, the joven, a boy with a dog, a girl; the flag; paper lanterns; Luis's paper with its two round pictures; the hammock, empty and with someone in it; the guitar, the drum, the microphone, the paper notes; abuela's camera, on the frog and on three legs; the curtain on 3, 2, 1 pegs; the cake with 7, 5, 3 candles; the four photos; the packets; the candle with its rings; pigeons; the guagua with faces at its windows.

**The stories.** Scripts with their reviews and a "Needs" list each: `historia/notas/guiones/subida.md` (stories 108 to 110), `musica.md` (111 to 113), `regalos.md` (114 to 116), `muralla.md` (117 to 119). Generators: `historia/tools/gen_subida.py`, `gen_musica.py`, `gen_regalos.py`, `gen_muralla.py`, run in that order after La casa's four. The checker passes all 12 with 0 errors; every new word is heard three times or more on every clean path. With places 4 to 9 that is 123,204 characters still to record for the whole of places 4 to 10 (inside the free 500,000 a month). The story files are not on main and must not be pushed until they are recorded. Don Pepe's speaker key is `pepe`, as in his recorded lines.

**Step b** and **Done when**: as orders 50 to 53. New for this place:
- A lawn with a tree whose leaves sway (as La plaza's): the sheet's checks read the still frame.
- Things that hang: a lantern on a hook, three lanterns over the gate, photos on a cord with pegs, a curtain on a cord that loses its pegs one by one (a state of the sprite: 3, 2, 1), three lanterns on a cord that are knocked off one by one.
- A stake that is a count of something lit: lanterns (108, 110, 117), candles (115: two go out at a miss, so the count is 7, 5, 3), a candle's rings (118), paper notes (112).
- Two músicos whose bubbles say "El músico" and "El otro músico"; who asks is fixed by the round (111).
- A round whose rule is "the two rounds ask the two things, in a drawn order" (108, 114), and one whose second round must ask a photo of the other pair (115).
- A person shown only through a hole: a dancer beyond the arch (114), someone inside a sentry box when its door is open (117), faces at the guagua's windows (119).
- A moment of dark (117): the lanterns flicker and one person is gone when the light comes back.
- A story with a four-step stake that ends at 4, 3 or 2 (119), and an ending line that plays only when something was lost (119: abuelo's line).
- The level's last story (119) ends with the lanterns going out one by one; after its `fin` the map's last stop opens (the fort check, below).
- Voices: `musico1`, `musico2`, `maestra`, `piraguero`, `senor`, `senora`, `joven`, `gente` (small voices from the guagua), and `pepe`.

### The fort check (the A1 final check): a first design, for an order after 77

The plan names it ("the level check and the fort check") and page 02 puts it after El fuerte's call; the plan's own page is not in this repo, so what follows is the content lane's reading, and Salim has been told it is a guess. It is the last stop on the map, at the fort, and it opens after story 119.
- The same form as the level check (`historia/nivel.js`): a sentence, four pictures, he touches one; nothing says right or wrong while it runs. It is not a lesson and not a game: no stake, no stars.
- 40 items, one for each scene of the ten places, in the order of the places, each on a word of that scene in a recorded sentence he has not been asked in Repaso. About ten minutes. He can stop and come back.
- Then ten spoken items, one for each place: a question from that place's call, heard, answered aloud; the accepted answers are the call's. Only where the microphone works and "Speak in stories" is on.
- At the end, no mark out of 40: the map of the ten places, each shown as strong or as coming back, and the words he missed go into Repaso as due now. A place with two or more of its four items missed is "coming back".
- A1 is done, and the road to A2 shows, when no more than two places are coming back and six or more of the ten spoken items were heard right. He can take it again the next day. (These two numbers are first guesses.)
- What it needs from the content lane, once the ten places play in the app: the 40 items (word, sentence, four pictures from the scenes' own picture pairs) and the ten questions. Nothing new is recorded.

## Order 45. Preview content (previa): a build plays stories that are not on the old site yet. **Result (Nov 21): done, merged.**

Why: the story files of places 4 to 10 must never be pushed under `historia/cuentos/` (a push there starts the paid recording job), and they are recorded only after they have played in the app. The app read all its content from the site. Built by an Opus builder on `orden/45`; the orchestrator ran `test_all.sh` itself: all checks passed.

- The build carries its own copy: `coqui/app/assets/previa/curso.json` (an overlay: for each place the list of its preview stories, and each story's `t` and `min`) and `coqui/app/assets/previa/cuentos/<id>.json` (the generators' files, byte for byte). On main the overlay is empty until a place's four scenes are ported.
- The shell wraps the catalog's fetch (`coqui/app/lib/src/previa.dart`): a story the site's `curso.json` does not list is added to its place from the overlay and read from the bundle; **as soon as the site lists a story, the site wins** and the bundled copy is ignored. With an empty, missing or broken overlay the app reads exactly what it read before (tested byte for byte).
- A preview story has no recorded clips, so it plays silent, on timed lines (the runner's own fallback).
- The tool: `python3 coqui/tool/make_previa.py --places colmado[,calle,...]`, then `--check`. It runs the generators in this page's order (every earlier one first), copies the named places' stories into the bundle, writes the overlay, then removes everything it caused under `historia/` and fails unless `git status --porcelain historia/` is empty. It refuses to start on a dirty `historia/`, refuses a place whose scenes are not all in the registry, and never calls git add, commit or push. It bundles exactly the places named: name every place to keep.
- At each place's build the orchestrator: merges the four scenes, runs the tool and `--check`, runs `test_all.sh`, commits `coqui/app/assets/previa/` only, raises `coqui/BUILD`.
- An unknown scene id now shows the same "This story is not in the new app yet." screen as an unconverted scene (before, an empty frame).
- What the other tabs do with a preview story: the map opens the place and offers the story; Biblioteca lists it after it is played, with Listen and no Read (no book); Repaso and the level check never ask it; Palabras shows its new words as plain tiles; Hablar says "Coming soon" for the place; Yo counts it. No tab throws (tested).
- **For the content lane:** `min` in the overlay is a guess (the story's `dots` minus 3, at least 2); the site's own value replaces it when the course lists the story. When a place is published on the site, leave it out at the next run of the tool.
- Not verified: Android (no SDK on the build machine; the files are plain Flutter assets). `--check` is not part of `test_all.sh`, so a generator that changes on main leaves the bundle stale until the tool is run again.

## Order 40. Every story against its recorded runs (orchestrator)

Replay all of `ref/trazas/` with `tool/juega.dart`. Any run that differs is fixed in its lane by an order naming the story and the first step that differs.

## Order 41. Books' pictures (orchestrator)

A Dart tool that does for pictures what historia/tools/gen_libros.py does: each book page's picture at the moment gen_libros.py takes it, without bubbles, captions or HUD, the 196 × 216 display picture, same file names. The books' text does not change. **Done when:** 231 pictures; a fresh beginner reader goes through the 22 readable books and flags any page whose picture no longer fits its lines.

## Order 42. Cutover (orchestrator)

1. Tell Salim the day before, in one line. Nothing is deleted.
2. The old code moves to `legacy/`, still served. `historia/app.html` sends visitors to `/field-notes/app/`.
3. Stories, audio, books and `datos/` stay under `historia/`: the generators, the audio job and the new app all read them there.
4. The recaptured book pictures replace the old ones.
5. Before the push: a dry run shows the audio job would record 0 clips.
6. Rewrite pages 00, 05, 07 and the runbook for the new layout. Add part 22 to page 08.

**Done when:** the old address opens the new app with his progress in it; the old app opens under `legacy/`.

## Order 43. The Android build he can install (orchestrator)

The debug build of order 03. In it: content by address from the site; calls off with the "later" line; in Yo, "Move my progress": the web app shows a code (`progress.export()`), the phone build takes it (`progress.import`). Attached to a GitHub release; the link sent to him. **Done when:** it installs on his phone, plays story 1 with sound, hears one speaking turn, takes his progress from the code.

## Order 44. Testers (orchestrator)

Before the link goes to anyone, one question to Salim: Danny's calls on or off for testers (calls spend his credits; the agent allows 15 a day). It sets `AppInfo.callsAllowed` for the build.

To testers: the link and three lines: open it in Safari; Share, then Add to Home Screen, and use it from there from the start (the home-screen app keeps its own progress, apart from Safari's), or "stay in Safari" if order 00 said the mic fails when installed; turn the ring switch on if there is no sound.

**Done when:** one tester has played story 1 on an iPhone and said so.

---

## Review of this version (Nov 19)

One fresh reviewer read the three pages against the code and against 11-pixel-engine. What it found, and what changed:

- The scene method of the first draft (carry old screen numbers to the new set with two helpers) fails on El frente by arithmetic, and the story and pair files hold screen positions too. Now every scene gets a set reference and a sheet first (design, by the orchestrator), and the builder's port is mechanical and checked against the reference.
- frente-set.html is one state and lacks the sun, the big palm and the shut door and shutters. Order 07 completes it before any builder ports it.
- The old game stretches views by fractions; 11-pixel-engine forbids that. Views now slide and never zoom. Salim sees this at Gate A.
- Order 06 could not be made as written (the scene object does not hold its things). Fixed, with El frente by hand.
- Recorded story runs would not have matched: a different random generator, and 90,000 random draws for the thunder. One generator on both sides; the thunder's noise left out of the runs.
- Builders had not been given the interfaces they code against. Now they are.
- Orders 13 to 15 needed order 20. The story-frames read moved to Gate A. Scene builders use a command-line player instead of importing the story feature.
- Wrong facts fixed: the kinds of step (taken from juego.js now); app_check.py has no Yo checks; the speech language comes from 01-decisiones; A comer is the twelfth scene.
- Phones: a microphone-stream test for calls; the audio session set before the mic test; a fixed debug key from the first build; the Android and iOS permission lines; testers install before they start.
- Contracts: `PixelView` repaints and snaps to device pixels; `Thing` has a world box; the scheduler is checked in two time zones.
