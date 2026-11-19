# Flutter plan: Coquí in Flutter, one feature per package

Second version, Nov 19 2026. Against the code at commit 85679b3 (v=39). Nothing here is built.

Three pages go together. Copy all three, and 11-pixel-engine with its `pixel/` files, into docs/proyecto/ in the GitHub project before starting.

| Page | What it is | Who reads it |
| --- | --- | --- |
| 11-flutter-plan (this page) | The decisions, the layout, the rules, the order | Everyone |
| 12-flutter-contracts | The shared interfaces, as Dart, and the porting rules | Every builder |
| 13-flutter-orders | The work orders, one per agent task | The orchestrator hands them out; a builder reads only its own |
| 11-pixel-engine | The spec for the map and the scene pictures. Its decisions are made | Builders in the pixel, scenes and map lanes |

Where this page and 11-pixel-engine differ about the map or a scene picture, 11-pixel-engine wins. Where they differ about where code lives or who may touch it, this page wins.

## His asks (Nov 19)

- "I want to convert the app into flutter so that all this dev time isnt wasted and later I can easily make it a android/ios app."
- "I want to just have it on my phone as an app as a webapp."
- "I want my codebase to be structured such that each unique feature exists as separately as possible from others so that i have xyz agents working on reading features, they will never bump into or need context from the speaking or game module. this will limit the required context for agents later and make it so that i can have many concurrent tasks without introducing bugs from the concurrent work."
- "MY PHONE IS AN ANDROID MY TESTERs on iphones. intergrat this into the plan. make sure the plan is 100% complete for executing to sonnet agents wirthout sacrificing any quality"
- "Part of this conversion is bringing in the pixel engine work from Nov 14." Order he gave: the engine, then the map, then El frente, "Stop and show Salim before doing other scenes", then "the other scenes one at a time".

So:

1. The app in Flutter. One codebase: web now, Android and iOS later.
2. On his Android phone as an installed web app. The same link for his testers on iPhones.
3. Each feature in its own box. An agent in one box cannot touch, and never needs to read, another.
4. The map and the scene sets drawn by the Pixel Plays engine, ported to Dart. Characters stay today's sprites.
5. Builders are Sonnet agents. Every decision is made before an order goes out. A builder that meets a choice its order does not settle stops and reports.
6. One kind of work is not given to builders: designing each scene's set. A set is built and checked in JavaScript first, by the orchestrator, with every state its stories need. The builder then ports it and proves the port against it. See "What is not Sonnet work".

Everything in 03-requirements still binds.

## What changes for a learner, and what does not

- Changes: the map and the scene backgrounds get the new look (page 11). Nothing else.
- Does not change: the stories, the lines, the voices, the rules of the game, the scheduler, every screen's layout (page 09 and 10), his progress.

## What the move costs, said once

- About 630 KB of JavaScript is rewritten in Dart, and about 120 KB of page code becomes Flutter screens.
- Of the 490 KB of scene code, the background drawing is not ported. It is rebuilt as sets in the new engine. The characters, the props that move, and what happens in each scene are ported as they are.
- 11 of the 40 scenes are live and a twelfth (A comer) is on its branch. Moving now is the cheapest it will be.
- While the move runs he gets no new playable scenes. Scripts and recordings can go on.
- Scenes are converted one at a time, as he said. That is the slowest part of the plan. Everything else runs in parallel.

## What carries over unchanged

- Every story file (historia/cuentos, 62 files: 32 stories, 11 picture stories, 8 routines, 11 review sets).
- Every recording (historia/audio, about 1,580 clips, 40 MB) and the audio job.
- The 43 books. Their 231 page pictures stay until each scene is converted, then are captured again from the new scene.
- The generators (historia/tools/gen_*.py), the scripts, the course, the scheduler's rules, Danny's agent and prompt, pages 00 to 10.
- His progress on his phone.

## Phones

| | His Android | Testers' iPhones |
| --- | --- | --- |
| How they get it | The link, installed from Chrome | The same link, added to the home screen from Safari |
| Sound | Works as today | The ring switch can silence it. The app sets the audio session to "playback" (iOS 17 on). Checked in order 00 |
| Mic in stories | Chrome's recognition, as today | Works in Safari with Dictation on. In an installed app it has been broken on some iOS versions. Checked in order 00. If it is off, speaking turns do not run and nothing else changes (today's rule) |
| Tap ticks | Yes | No. iPhones ignore them on the web |
| Install prompt | Chrome offers it | None. A one-time hint shows "Share, then Add to Home Screen" |
| Old progress | The installed app shares Chrome's storage, so the import is automatic | Testers have none |
| Danny | Works (same site, same allowlist) | Works in Safari; the installed app is checked in order 00 |

- A real Android build (an .apk) is made by CI on every change to main from phase 1 on. It proves the code never becomes web-only. He can install it. In it, calls with Danny are off until there is a small server for call tokens (see "Later").
- An iOS build is compiled, unsigned, once a week by CI, for the same reason. Putting it on testers' iPhones needs an Apple developer account (about $99 a year, to check when the time comes). His call, later.
- Danny's calls spend his ElevenLabs credits, whoever places them. The agent's own limit is 15 calls a day. Before the link goes to testers, the orchestrator asks him one question: calls on or off for testers.

## Decisions made here, so nobody re-decides them

| Decision | Why |
| --- | --- |
| Same GitHub project (salimocasio-dev/field-notes), new folder `coqui/` | Same site address: Danny's allowlist, the audio secret and his progress keep working |
| Flutter stable, pinned in the repo. Flutter's release pages show 3.50 with Dart 3.14 on Nov 19 2026; confirm with `flutter --version` and pin what is there | One version for every agent |
| One workspace, many packages (pub workspaces) | One lock file, each feature a package with its own tests |
| The boxes are kept apart by a check, not by the compiler | A workspace shares one package list, so any package can import any other. `tool/check_boundaries.dart` and the lint `depend_on_referenced_packages` (as an error) fail the branch |
| All pixel drawing goes into one `Uint32List` picture, shown scaled by a whole number with no smoothing (page 11, decision 3) | One method for the map, the sets and the sprites. Same picture on every device. Tests need no screen |
| The sprite layer is a small software canvas shaped like the browser's (fillRect, drawImage, save, restore, translate, scale, rotate, arc, ellipse, clip, globalAlpha) writing into that same picture | Today's character and prop code ports line by line |
| A view never zooms. It is a 196 × 216 window that slides over the 240 × 216 scene | Today's game stretches views by fractions (a door view is about 1.08 times). Page 11-pixel-engine, decision 3, forbids a fractional scale. He sees the difference at Gate A |
| A scene's story and review files are not edited. Screen positions in them go through the scene's own table | 62 files stay as they are; one table per scene holds the change |
| coqui_pixel is pure Dart | Its tests run in milliseconds, on the Dart VM and compiled to JavaScript, so number differences between phone and web are caught |
| Dart code in English. JSON keys stay as they are | Story files are not rewritten |
| Stories stay raw JSON. The runner reads steps as maps | A new kind of step changes one package |
| The scene's world (`W`) stays a JSON-shaped map | Story steps and review pictures write its keys by name |
| No code generation. No state library across packages (inside one: ChangeNotifier or ValueNotifier). Routing only in the shell | Fewer shared files, nothing shared to conflict on |
| Until cutover the web app reads stories, audio and books by address from `historia/` on the same site | No copy of 40 MB, the audio job is untouched |
| The old site stays live and frozen (bug fixes only) until cutover | He never loses a working app |
| Builders may not add a third-party package | One lock file. They file a request |
| Orchestrator: the Claude Code session. Builders: Sonnet agents. Reviewers and readers: fresh agents that did not build the thing | His rule: a self-review does not count |

Name map (JSON and old code → Dart): cuento → story. escena → scene. cosa → thing. lugar (in a scene) → spot. palabras → words. cual → review pair. nivel → level check. llamada → call. libros → books. dibujos → picture stories. haz → routines.

## The layout

```
field-notes/
  index.html, historia/        the old site. Frozen. The source of stories, audio and books until cutover
  docs/proyecto/               the project pages, with pixel/ (the JS reference of page 11)
  coqui/
    pubspec.yaml               the workspace root
    AGENTS.md                  the runbook: lanes, rules, commands (order 01 writes it from page 12 and 13)
    requests/                  what a builder needs from a package it may not touch
    tool/                      check_boundaries.dart, exports, reference dumps
    ref/                       reference data made from the old code: pictures, traces, inventories
    app/                       the shell: tabs, routes, wiring, web/, android/, ios/
    packages/
      core/
        coqui_contracts/       models, interfaces, routes. Pure Dart
        coqui_progress/        word records and the scheduler. Pure Dart
        coqui_content/         reads the course, stories, review sets, books, clip list. Pure Dart
        coqui_platform/        audio, speech recognition, the call connection, storage, haptics. The only package with plugins or browser code
        coqui_pixel/           the Pixel Plays engine, the set-building helpers, the sprite library, the software canvas, the scene kit. Pure Dart
        coqui_scenes/          one folder per scene (its set, its scene), and the pictures other features ask for
        coqui_ui/              colours, type, shared widgets, the lesson frame, the widget that shows a pixel picture
        coqui_testing/         a fake for every interface, and a tiny sample course
      features/
        feature_map/           the home map (page 11), the Today card, the place sheet
        feature_story/         the story game: the step runner, the play screen, Listen mode, speaking turns
        feature_review/        Repaso (¿Cuál?) and the level check
        feature_words/         Palabras
        feature_library/       Biblioteca and the book reader (Leer)
        feature_speaking/      Hablar: the call with Danny, the voice test
        feature_profile/       Yo, the welcome, settings, About
```

## Packages: what each replaces and what it may depend on

| Package | Replaces | May depend on |
| --- | --- | --- |
| coqui_contracts | the shapes in palabras.js, curso.js, the story file; `norm` | nothing |
| coqui_progress | historia/palabras.js | contracts |
| coqui_content | curso.js, the pair index (`CU.items`), `NV` in nivel.js, `LLAMADAS` in llamada.js, the fetches of cuentos/, libros/, audio/ready.json | contracts |
| coqui_platform | the sound code in juego.js, SpeechRecognition, the ElevenLabs client, localStorage, vibrate | contracts, plugins |
| coqui_pixel | docs/proyecto/pixel/pp-engine.js, the building helpers in mapa.js, historia/engine.js, escenas/kit.js, the signs and marks in juego.js | contracts |
| coqui_scenes | historia/escenas/*.js, pixel/frente-set.html, `miniatura` and `panelW` | pixel, contracts, ui |
| coqui_ui | the CSS in app.html, notas/ui-decisiones-1 to 3, page 09 | Flutter only |
| coqui_testing | (new) | contracts, ui |
| feature_map | pixel/mapa.js and mapa.html; the Today card and place sheet in app.html | contracts, ui, pixel |
| feature_story | juego.js, index.html | contracts, ui, pixel, scenes |
| feature_review | cual.js, cual.html, nivel.js, nivel.html | contracts, ui |
| feature_words | the Palabras tab in app.html | contracts, ui |
| feature_library | the Biblioteca tab and the book reader in app.html | contracts, ui |
| feature_speaking | llamada.js, habla-prueba.html, the Hablar tab | contracts, ui |
| feature_profile | the Yo tab and the welcome in app.html | contracts, ui |
| app | app.html's tab bar and page switching | everything |

## The boundary rules

The check script enforces 1 to 5 on every branch.

1. A feature never depends on another feature. Not in its pubspec, not by import.
2. A package depends only on the packages in its row above.
3. A package's public surface is one file, `lib/<package>.dart`. Everything else is under `lib/src/`. Nobody imports another package's `src/`.
4. A feature exports one thing: its module. The shell holds the only list of modules.
5. One order changes files in one package. A branch that touches two fails, unless it is the orchestrator's. `coqui/requests/` is open to all.
6. Shared state is the progress store, nothing else. A feature's own settings live in its own storage space.
7. Core packages have one writer at a time, named in the order. A builder that needs something from a package it may not touch files a request, uses the fake or a local copy, and carries on.
8. Content is data. Code builders do not edit content. Content builders do not edit code.
9. No Spanish text and no clip id in engine or feature code. They come from content.

## How features work together without knowing each other

| What happens | How |
| --- | --- |
| He taps a place on the map | The map calls `nav.go(StoryRoute(id))`. The shell opens the story screen |
| A story ends | Story calls `progress.storyFinished(result)`. The map redraws: it listens to `progress.changes` |
| "Listen" on the shelf | Library calls `nav.go(StoryRoute(id, listen: true))` |
| "Start" on Repaso | Words calls `nav.go(ReviewRoute())` |
| A word's picture (Palabras, Repaso, level check, call screen) | The feature asks `pictures.of(ref)`. It never imports a scene |
| "Heard in" on a word sheet | Words asks the catalog for the lines, and progress for the stories played |
| He says a word to Danny | The call writes `progress.answer(word, Skill.mouth, ...)` |
| The level check places him | Review calls `progress.presume(...)`. The map follows |

## The order of work

The orders themselves are page 13. This is the shape.

| Step | What | Who | He sees |
| --- | --- | --- | --- |
| Order 00 | Six questions on real phones: his Android and one tester's iPhone | Orchestrator | One link. He and one tester tap through it |
| Orders 01 to 06 | The skeleton: workspace, contracts, fakes, checks, CI, the site build, the exports, the reference data from the old code | Orchestrator, alone | Nothing |
| Order 07 | El frente's set, completed in JavaScript: every state, the sun, the big palm, and its sheet | Orchestrator (design) | Only if a look question comes up: two pictures side by side |
| Orders 10 to 12 | Page 11, step 1: the engine in Dart, proven against the JS (0.5%). Then the sprites and the kit | Builders, pixel lane | Nothing |
| Order 13 | Page 11, step 2: the map, wired to progress. Three golden states. Bake and frame times measured on his phone | Builder, map lane | The map on his phone |
| Orders 14, 15 | Page 11, step 3: El frente, every state its stories use, and the story runner. Stories 1 to 3 play | Builders | **Stop. El frente and story 1 on his phone.** Nothing after this in the scenes lane until he answers |
| Orders 16 to 26 | In parallel with 10 to 15: progress, content, platform, ui, the five other features, the shell | Builders, one a lane | Screens as they land, on the test link |
| Orders 30 to 39 | Page 11, step 4: the other ten scenes, one at a time. For each: (a) its set and sheet in JavaScript, by the orchestrator; (b) the port, by a builder; then a fresh reader | Orchestrator, then one builder | Each place when its scenes are done |
| Orders 40 to 45 | Every story checked against its recorded runs, books recaptured, the switch to the new app, the Android build he can install, the iPhone hint | Orchestrator and builders | The new app at the old address |

During the move: scripts, story files and recordings can go on. A comer finishes in JavaScript and becomes the twelfth scene to convert. After that, a new scene is made the new way from the start: its set and sheet, then Dart.

## What is not Sonnet work

Said plainly, because he asked for a plan Sonnet can execute without losing quality.

- **Sonnet can execute as written:** the engine, the sprites, the kit, the map, the story runner, progress, content, audio and speech, the call connection, the shared look, all five other features, and the port of each scene once its set and sheet exist. Each has a check a machine runs.
- **Sonnet cannot, and is not asked to:** design a set. Where a door goes, what the frog stands on, what a view shows, how a state reads with no words: these are choices, and they are judged by looking. The second review showed that trying to make this mechanical breaks on El frente itself. So the orchestrator builds each set in JavaScript, fresh readers look at it, and El frente is his to approve before any other.
- **What exists today:** the map (complete) and one state of El frente. Not yet made: the rest of El frente's states (order 07) and the sets of the other ten scenes (orders 30a to 39a).
- This is the slowest part of the move and the part with the most of his eye in it.

## Checks

- **The engine:** the same set drawn by the JS and by Dart; no more than 0.5% of pixels differ (page 11).
- **Sprites:** every sprite the old code makes, made by Dart: identical, pixel for pixel.
- **The map:** golden pictures for nothing done, three places done, all done. Bake under 500 ms and a frame under 8 ms on his phone (page 11).
- **The scheduler:** the old file and the port give the same numbers for the same answers at the same times.
- **Stories:** each story's recorded runs from the old page (all right, all wrong, with a seeded random) replayed by the Dart runner: same decisions, same marks, same steps lost, same ending. The art changed; the game did not.
- **Scenes:** every state rendered and read by a fresh reader with no words, against El frente's look. Every review pair of the scene drawn.
- **Features:** widget tests on fakes, covering what the old check scripts cover (leer_check, repaso_check, app_check, llamada_check, habla_motor_check, nivel_check, cual_check).
- **Before anything goes to him:** the seven steps in 00-start-here.

## Later (not in these orders)

- Store releases. The Play Store needs a signing key and an account; the App Store needs the Apple account.
- Danny in a phone build: a phone app has no web address, so the allowlist cannot guard the agent. It needs short-lived call tokens from a small server and ElevenLabs' Flutter SDK (elevenlabs_agents; its page documents Android and iOS). Only coqui_platform changes.
- Content inside the app as packs, downloaded per place.
- Accounts, so progress leaves the one phone.
- Offline use.

## Guesses and risks

| Item | Status |
| --- | --- |
| Speech recognition in an installed web app on an iPhone | Sources disagree: WebKit said in 2021 it was not available there; a current test site says it now is. Order 00 settles it on a real iPhone |
| iPhone: mic and playback taking turns (a line plays, he speaks, a line plays) | Reported to break after the first round on iOS. Order 00 runs five rounds |
| iPhone sound with the ring switch on silent | Fixed by the "playback" audio session on iOS 17 and later, by WebKit's own account. Order 00 confirms |
| iPhone Safari clearing a site's storage when it is not opened for a while | Not checked. Order 00 looks it up and tests. Installing to the home screen is the usual way round it |
| Gaps between recorded lines | Not checked. Order 00 measures both players. The fallback is the browser's Web Audio, as today |
| How the new sets look with flat sprites on them | He saw it on El frente and chose to go on (page 11, known gaps). Ten more sets are builders' work; each is read before the next starts, and El frente is his to judge first |
| Views that slide instead of zoom | A choice made here to keep decision 3. A door will look a little smaller than today. His to judge at Gate A |
| Ten sets not yet designed | The largest unknown in the plan. Each is made and read one at a time; El frente first |
| A set too slow to bake on a phone | Each bake is timed (150 ms on a desktop). Over that, the builder reports; nobody redesigns on their own |
| First load of a Flutter web app | A few MB, then cached. A guess until order 00 |
| The recorded runs and check scripts cover every behaviour | They cover what was tested. His play is the real check |
| Flutter's service worker and offline support | Changed across versions. Not used in this plan |

## Done means

- Every screen of v=39 exists in the Flutter app and behaves the same.
- The map and all eleven scenes are on the new engine, each seen by a fresh reader, El frente by him.
- The recorded story runs match. The scheduler matches.
- `check_boundaries` passes. Any feature runs alone on fakes.
- It is on his Android home screen with his progress in it, and his testers have the same link on their iPhones.
- CI builds the web app, the Android build and (weekly) the iOS build from the same code.
- The old site is under `legacy/` until he says otherwise.

## Reviews of this plan

- First version: one fresh reviewer read it against the code. Its findings were taken (the compiler does not keep packages apart; scenes call the engine and are not only drawing; sound is more than named effects; pictures for other features needed an owner; gaps in the contracts; no copy of the audio; the call's browser code out of the feature; story runs seeded).
- This version adds his phones, his testers, page 11-pixel-engine and the work orders. A second fresh reviewer read all three pages against the code and the pixel spec. Its findings were taken; they are listed at the end of page 13. The largest: scene sets cannot be converted mechanically, so they are designed first and ported second.
