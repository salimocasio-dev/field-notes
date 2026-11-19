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

## Order 02. Contracts and fakes (orchestrator)

**From:** historia/palabras.js, curso.js, juego.js (the names in page 12 section 4), escenas/kit.js (`escena`), cual.js (`panelW`, items), nivel.js (`NV`), llamada.js (`LLAMADAS`, the session calls).

- coqui_contracts, coqui_ui's contracts, and `Thing`, `Scene`, `SceneHost` in coqui_pixel, as page 12 sections 2 to 4. `SceneHost`: one member per name listed, with juego.js's parameters. `normalize` tested on 30 strings whose expected values come from `PAL.norm` in node. `Mulberry32` with ten values checked against the same generator in node.
- coqui_testing: a fake for every interface (in memory; a settable clock; a scripted `SpeechListener` in the shape of today's `?mic=stub:`; a scripted `CallSession` in the shape of today's `?callstub`), and the sample course: El frente, stories 1 to 3, cual-frente, the book la-lluvia, twenty clips. The fake `PictureSource` shows labelled grey boxes now, and saved frames from `ref/` once order 06 has made them.
- A dev entry in each feature that starts it on the fakes.

**Done when:** everything compiles; each dev entry opens; the report lists every member added beyond page 12.

## Order 03. Site build; Android and iOS builds (orchestrator)

- One workflow that deploys Pages from Actions: the repo's static files as they are, plus `flutter build web --base-href /field-notes/app/` under `app/`. Change the Pages source to "GitHub Actions".
- `.github/workflows/voz.yml`: as its last step, start the site build (`workflow_dispatch`; the job needs `actions: write`). Commits made with GitHub's own token do not start other workflows.
- `flutter create --platforms=android,ios` in `coqui/app`. Android: the microphone permission and the speech-recognition `<queries>` entry in the manifest; a fixed debug signing key kept in the repo (not a secret; it lets each build install over the last; not for the store). iOS: the microphone and speech-recognition usage lines in Info.plist. Take the exact entries from the `speech_to_text` page.
- CI: `flutter build apk --debug` on every push to main, kept as an artifact; `flutter build ios --no-codesign` weekly on a macOS runner. Confirm on GitHub's pricing page that Actions minutes are free for this public repo before turning the macOS job on; tell Salim if not.
- `web/manifest.json` and `web/index.html`: name Coquí, `display: standalone`, portrait, the coquí icon (rendered from `mkCoqui` after order 11; a placeholder until then), `translate="no"`, `<meta name="google" content="notranslate">`, the Apple touch icon and web-app meta tags.

**Done when:** https://salimocasio-dev.github.io/field-notes/app/ serves the empty app; the old site works at its old addresses (checked with the GitHub API as page 07 says); a dry run shows the audio job would start the site build; the Android artifact installs on an emulator, twice in a row.

## Order 04. Content exports and clip marks (orchestrator)

New files beside the stories. The old site does not read them.

- `historia/datos/curso.json` (`CURSO`), `nivel.json` (`NV`), `llamadas.json` (`LLAMADAS`), `fijos.json` (every clip id that juego.js, cual.js and llamada.js name in code, each under a role; the goodbye words). Made by `coqui/tool/export_datos.mjs` in node.
- `historia/audio/marcas.json`: for every clip in ready.json, `[startMs, endMs, lengthMs]` by juego.js's `trim` rule (threshold 0.012 on channel 0; 30 ms before the first loud sample, 100 ms after the last). `historia/tools/voz.py` adds the marks for clips it makes.

**Done when:** every clip has marks; ten, picked at random, match what the old page computes in Chrome within 5 ms; a dry run of the audio job records 0 clips.

## Order 05. Reference data from the old code (orchestrator)

Made by scripts in `coqui/tool/ref/`, written to `coqui/ref/`, committed.

- **Engine** (`ref/pp/`): headless Chrome renders of `docs/proyecto/pixel/`: the map with the demo states `?hecho=0`, `?hecho=3`, `?hecho=10` at time 0 (with the `hecho`, `abierto`, `aqui` arrays mapa.html builds for each, saved beside the picture), each as raw `pix`, `zb`, `kinds` and as PNG. A unit page that calls `hash`, `noise`, `project`, `unproject`, `rampOf` on 200 fixed inputs, outputs as JSON.
- **Sprites** (`ref/sprites/`): every sprite engine.js and kit.js can make, and every sprite a scene file makes for itself (read each scene's sprite cache after its stories' runs), as width, height, raw pixels, and the call that made it.
- **Canvas sheet** (`ref/ctx/`): one page drawing 40 numbered cases with the browser's canvas into 64 × 64 tiles: fillRect at whole and half positions; drawImage plain, scaled 1.6 and 0.86, flipped, rotated 0.5 rad; with smoothing on; globalAlpha 0.5; arc and ellipse fills at five sizes; a clip rectangle; strokes of width 1 and 2.
- **Scheduler** (`ref/progress/`): palabras.js in node on 30 scripted sequences with `__PAL_NOW`, each run twice, under `TZ=UTC` and `TZ=America/New_York`: the 20-day run of page 08, a miss, three misses in a row, a slow right answer, `presume`, a story finished twice, an answer at 3:59 and at 4:01 local. The calls and the store after every call.
- **Stories** (`ref/trazas/`): each of the 51 story, picture-story and routine files, played on the old page by tools/juega.py with `Math.random` replaced by Mulberry32 (seed 1) and juego.js's `noise()` buffer filled without it (both injected by the tool; the old site is not changed), every draw fixed: all right, all wrong, right and wrong alternating. Per run: the decisions (`LOG`), the marks, `lost`, the ending, the order of clips spoken. The list of runs is committed. Remake a story's traces whenever its file changes.
- **Screens** (`ref/pantallas/`): phone-size screenshots of v=39: every tab, each sheet, a book page, a Repaso item and its end screen, the level check, the call screen on its stub, the welcome.

**Done when:** every file exists; a second run gives byte-identical pp, sprites, ctx, progress and trazas.

## Order 06. Scene inventories and frames (orchestrator)

`coqui/ref/escenas/<id>/` for each of the eleven scenes:

- `inventory.json`. For the ten kit scenes: wrap `KIT.escena` to capture what each scene passes it (`cosas`, `lugar`, `CAM`, `heartAt`, `fresh`, the act names); `ESCENAS[id]` alone does not hold them. For El frente, which has no kit: by hand from frente.js (`box`, `hit`, `LUGAR`, `ABAT`, `PERCH`, `HOLE`, `SPOT`). For every scene: each thing's box in the fresh state and in every state its stories reach (read `W` after each step of the order-05 runs, so states set by acts are caught), and the name of its background function (`bg`, `fondo`, `mkPuesto`).
- `positions.json`: every distinct screen position in the scene's story files, review pairs and level-check items (`set` steps with x and y, `cam`, crops), each with where it is used.
- `frames/`: each state, with and without characters.
- `pairs.json`: every review pair and level-check picture that uses the scene.
- `draw-order.md`: for each character, what the old `draw()` draws after it (what covers it), and every clip region.

**Done when:** eleven folders; each inventory's thing ids equal the old scene's; a fresh reader, shown three frames from each with no words, names what is in them.

## Order 07. El frente's set reference and sheet, completed (orchestrator; design)

frente-set.html is one state of El frente: door open, shutters open, a porch lamp lit. Page 11-pixel-engine approved its look. It is not yet everything the stories need.

**Build, in `docs/proyecto/pixel/`:**
- frente-set.html takes its state from the address and draws every state in `ref/escenas/frente/`: the door shut, half and open; the shutters shut and open; the lights on inside (page 08: "the lights come on inside and stay on: the shutters and the door both glow"; the old scene has no porch lamp, so the lamp goes). Sky enough for the storm cloud.
- The things the stories touch or name that the set lacks: the sun; the big palm (story 3's hiding places), put where it covers no touch box (decision 14 took the first palm out for that); the small palm and the birdhouse if the inventory has them in the background.
- `frente-sheet.json`, every part of page 12 section 5.
- Check the views: at `S = 26` the house is wider than the 196 window. Every view in the sheet must show what its stories need without zoom; where one cannot, move the origin (decision 9 allows it), not `S`.

**Done when:** every state rendered; each of the 12 pairs of cual-frente told apart by a fresh reader with no words; a fresh reader names everything in the wide view; nothing green over a touch box; order 05's script has added each state's raw pixels to `ref/pp/frente/`.

**This is design.** It needs a session that renders and looks. If the orchestrator cannot settle a look question from pages 03, 09 and 11-pixel-engine, it asks Salim with two pictures side by side, before order 14.

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

## Order 11. Sprites and the software canvas (builder, coqui_pixel)

Page 12: sections 1, 4, 6, 7. **From:** historia/engine.js, all of it.

**Build:** `Sprite`, `Buf`, every `mk*`, `RP`, `sky`, `grass`, `shadow`, `face`, `coqui`, `bubble`, `GL`, `GC`, `fr`. `Ctx`: a transform stack (2 × 3 matrix); alpha blending in 0–255 steps; drawImage by inverse mapping, nearest neighbour at pixel centres, bilinear when `smoothing` is on; arc and ellipse fills by scanline with 4 × 4 coverage; a clip stack of rectangles and one path mask; `snapshot`.

**Done when:** every sprite of engine.js in `ref/sprites/` is reproduced exactly, every pixel, on vm and chrome. Canvas sheet: fillRect, plain and flipped drawImage, clip: exact. The other cases: no more than 3% of a tile's pixels differ by more than 24 in any channel. Report every case's number.

**Stop if:** a sprite differs in one pixel. That is a porting error, not a tolerance.

## Order 12. The scene kit, the signs, the frame (builder, coqui_pixel)

Page 12: sections 1, 4, 5, 6, 7. **From:** historia/escenas/kit.js, all of it; from historia/juego.js: `hand`, `heart`, `star`, `spot`, the twinkle and glow, the answer bubbles (`respDraw`, `BUBL`, `bx`), `frogBox`, the frog's draw (juego.js line 48 on), the view and its slide (`cam`, `camGo`).

**Build:** the kit: `escena` as a base class giving `box`, `hit`, `handAt` and the shared acts; the bird; `FAM`, `mkPersona`, `mkBebe`, `mkAbuelaS`, `mkPerro`, `mkCesta`, `tarjeta`, `mano`. A sheet reader: `<id>-sheet.json` to things, spots, views, `remap`, clips, front, shadows. The camera of page 12 section 5 (a 196 × 216 window, whole pixels, no zoom). The frame recipe of section 5 as one function. `clipTo(thing, face)`: the polygon of that face on screen as the clip.

**Done when:** the kit's sprites in `ref/sprites/` match exactly; tests for the sheet reader, the camera (a view at each edge stays inside the picture; `camGo` passes only whole pixels), `clipTo` on a made-up box; `hit` on a made-up scene returns the same ids as the old `hit` for 50 points (expected values from the old function in node).

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

## Order 17. Content (builder, coqui_content)

Page 12: sections 1, 2, 6, 7. **Build:** `CourseCatalog` over a `fetch(String path)` given by the shell. Loads `datos/*.json`, `cuentos/*.json`, `libros/*.json`, `audio/ready.json`, `audio/marcas.json`. `pairFor` and `linesWith` as `pares()` and `oidoEn()` in app.html.

**Done when:** all 62 story files and 43 books load; every clip a story names has marks; `pairFor` finds each of the 128 words; `linesWith`, for ten words, returns the lines `oidoEn` returns (expected values from node).

## Order 18. Audio, storage, haptics, speech (builder, coqui_platform)

Page 12: sections 1, 2, 6, 7. **From:** historia/juego.js, "sound: effects, and the recorded voice", and its speech code (`habSR` on); habla-prueba.html; docs/hablar/01-decisiones.md.

**Build, on the routes order 00 chose:**
- `ClipPlayer`: a clip from its start mark to its end mark; `preload`; `tone`, `noiseBurst`, `loop('rain')` with today's numbers. On the web the tones are made live with Web Audio. In a phone build they are rendered once to short buffers by the same formulas.
- On iPhone web: the audio session type order 00 found to work; resume the audio context after every recognition (01-decisiones, "iPhone guards").
- `SpeechListener` on `speech_to_text`, with the language, alternatives and limits docs/hablar/01-decisiones.md gives. Do not choose a language. `available()` false when there is no recogniser, no network, or permission is denied.
- `KeyValueStore` per space; `Haptics` (8 ms tick; nothing on iPhone web); `AppInfo`; the import of the old keys (`coqui.palabras.v1`, `coqui.juego.ult`, `coqui.juego.mem`, `coqui.leer.tam`), read straight from the browser's storage, never deleted.
- All browser code behind a conditional import.

**Done when:** a dev screen plays ten lines back to back with gaps within 60 ms of the pauses asked for; a unit test shows every `SFX` name reaches the audio layer with the old code's numbers; `flutter build apk --debug` passes. How it sounds is Salim's to judge at Gate A.

## Order 19. The call connection (builder, coqui_platform)

**From:** historia/llamada.js (`precarga`, `startSession` and its options, the handlers, `installStub`); notas/llamada-decisiones-1.md; page 05, "How the page and Danny talk".

**Build:** `CallSession` for the web: the same ElevenLabs JS client at the same pinned version, loaded the same way, `connectionType: "websocket"`, the same agent id and variables, through JS interop. `available` false in phone builds, and wherever `AppInfo.callsAllowed` is false.

**Done when:** on the scripted fake, events arrive in the order llamada_check.py expects; the web build loads the client without error on the test site. No real call: it needs Salim's microphone and costs his credits.

## Order 20. Shared look (builder, coqui_ui)

**From:** the `<style>` of historia/app.html, cual.html, index.html; notas/ui-decisiones-1 to 3; pages 09 and 10; `ref/pantallas/`.

**Build:** colour and type tokens with v=39's exact values; the buttons; the bottom sheet; the tab bar with the raised Mapa disc; the lesson frame; the Ear and Mouth meters; the word card; the fade under lists; `PixelView` as page 12 section 3. A gallery dev screen.

**Done when:** a fresh reader compares the gallery with `ref/pantallas/` and finds no difference a learner would notice, or lists them. `PixelView` tests: a 196 × 216 picture in a 412-wide screen at pixel ratio 2.625 is drawn at 5 device pixels a pixel, unsmoothed, on whole device pixels; it repaints when its `repaint` fires and not otherwise.

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
