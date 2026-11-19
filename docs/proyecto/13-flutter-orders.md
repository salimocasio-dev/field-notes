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

## Order 26. The shell (orchestrator)

The tab bar and routes (`go_router` here only), each `AppRoute` to the module that answers `screenFor`; `Services` wired to the real packages; the first-start import of the old keys when the new store is empty; `reduceMotion` from `MediaQuery.disableAnimations`; the first tap calls `clips.unlock()`; `coqui/tool/juega.dart`.

**Done when:** on the test site every tab opens; each flow of the plan's "How features work together" works end to end on the sample course.

---

## Gate A. The map, El frente and stories 1 to 3 to Salim

First, by the orchestrator: frames of stories 1 to 3 (all right, all wrong) from `tool/juega.dart`, read by a fresh reader with no sound and no words; real findings fixed. Then the seven steps of 00-start-here. Then one message, one point a line: the link and its build number; what he is looking at; what was checked; what is a guess (the look of the sets with the sprites on them is his to judge; views no longer zoom, they slide; Claude cannot hear).

**The scenes lane stops here.** No order 30a starts until he answers. A change he wants to the look is a change to page 11-pixel-engine, made with him, before any other scene. Feature lanes keep going.

## Orders 30 to 39. The other scenes, one at a time

In this order: 30 balcon, 31 sala, 32 patio, 33 camino, 34 campo, 35 lago, 36 banco, 37 mesa, 38 estufa, 39 nevera. A comer follows as the twelfth once its JavaScript version is published and order 06 has made its folder. One scene is finished, both steps, before the next begins.

**Step a (orchestrator; design).** As order 07: `pixel/<id>-set.html` with every state, and `<id>-sheet.json`, from `ref/escenas/<id>/`. Same objects, same states, same touch keys (page 11-pixel-engine, step 4). A helper the set needs that `PpBuild` lacks is written in the reference first. Sala turns smoothing on in three places and banco copies a patch of its background: the sheet says how each is kept. **Done when:** as order 07, plus a fresh reader, shown this set beside El frente's, says whether they belong to the same world.

**Step b (builder, coqui_scenes).** As order 14: `buildSet` call for call; the old scene file line for line minus its background function; positions from the sheet; its stub in the registry replaced. **Done when:** every state within 0.5% of the reference; every touch box contains its thing; every review pair of the scene draws; the scene's stories' traces are reproduced by `tool/juega.dart`; bake under 150 ms. **Stop if:** a position has no name in the sheet.

**Then (orchestrator):** frames of each of the scene's stories read by a fresh reader with no sound and no words. After each place's last scene (32, 36, 39): the link for that place to Salim, the seven steps first.

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
