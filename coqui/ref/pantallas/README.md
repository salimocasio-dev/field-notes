# ref/pantallas/

Phone-size pictures of every screen of the old JavaScript app (v=39), so that the Flutter builders (orders 20 to 25, 13 and 15) rebuild what the learner really saw, and a fresh reader can compare. Order 05, part C. The old site is read and run, never changed.

- `<device>/<nn>-<screen>-<state>.png`: the pictures. Two phones: `android-412x915` (412 × 915 CSS px, device pixel ratio 2.625, 1082 px wide) and `iphone-390x844` (390 × 844, ratio 3, 1170 px wide). Both phones have the same pictures under the same names.
- `index.json`: for each picture its file, device, screen, state, the URL and the steps that reached it, the stored progress it was taken in, the orders of page 13 that use it, whether it is a whole-page picture, its size and SHA-256. At the top: what is pinned.
- `seeds/<name>.json`: the progress states (what the app keeps under `localStorage` `coqui.palabras.v1`), each made by the app's own code. `index.json` says what each is.
- `strings.json`: every English string v=39 can show (from app.html, cual.js, nivel.js, llamada.js, juego.js, index.html, habla-prueba.html and the English place names of curso.js) and the pictures where each shows; `not_shown` lists the ones that show in none.

## Names

`<nn>` counts the pictures in the order they are taken (the same on both phones). `<screen>` is the page or tab: `bienvenida`, `mapa`, `lugar` (the place sheet), `palabras`, `palabra` (the word sheet), `biblioteca`, `libro` (the book reader), `hablar`, `yo`, `repaso` (cual.html), `nivel` (nivel.html), `llamada`, `prueba-de-voz`, `cuento` (the story page). `<state>` says what is shown. The three progress states are `nada-jugado` (the welcome done, nothing played), `a-medio-curso` (five days in: La casa done, El parque begun, ten or more words due, a streak of 5) and `todo-jugado` (a month in: everything built so far, places 1 to 3, played; nothing due; a streak of 31). A name ending `-pagina-entera` is the whole page, top to bottom (the viewport is made as tall as the page, so the tab bar is at its foot). A name ending `-con-movimiento` is taken with motion on (see below).

## Re-running

```
node coqui/tool/ref/pantallas/capturar.mjs                      everything, into this folder (about 3 minutes)
node coqui/tool/ref/pantallas/capturar.mjs --list               the groups of pictures
node coqui/tool/ref/pantallas/capturar.mjs --only palabra,libro --device android --out /tmp/x --no-optimise     some of them, to a scratch folder
```

Node 22 and the pre-installed Playwright (`require('playwright')`, `chromium.launch()`). The script serves the worktree itself on a free port at `/field-notes/historia/...`, like the live site; nothing is fetched from the network (every request that is not to that server is refused, so the voice library of the call never loads and no call is placed). The PNGs are made lossless-smaller with oxipng (`@napi-rs/image` 1.16.0), installed on the first run into the system temp folder; without network pass `--no-optimise` (the files then differ from the committed ones). A second full run gives byte-identical files.

To open a state by hand in the old app: serve the repository so that `historia/app.html` is at `/field-notes/historia/app.html`, put the seed in storage (`localStorage.setItem('coqui.palabras.v1', <seeds/NAME.json as one line>)`), set `window.__PAL_NOW = 1795104000000` before the page's scripts run (the app's own fixed clock for the word records) and open the URL from `index.json`. The pictures also need the browser's own date to be 19 Nov 2026 (the Today card and the chips count days from it): the script does it with Playwright's clock, so the easiest way to see a state is `--only <group> --out <dir>`.

## What is pinned

- The clock: 19 Nov 2026, 12:00 in Puerto Rico (UTC-4, no daylight saving), time zone `America/Puerto_Rico`, locale `en-US`. Playwright's clock is installed and **paused**: it moves only when the script moves it, in steps of one frame (70 ms, the story engine's own tick). Fetches and decoding run in real time while the clock waits, so nothing depends on how fast the machine is. The word records' clock (`window.__PAL_NOW`) is fixed at the same moment. `performance.now()` is made `Date.now() - T0` (the fake clock's own starts a few real milliseconds late, a different few each load, which moved the map's frog, the call's rings and the mic's pulse by a frame in one run of ten).
- `Math.random` is Mulberry32, seed 1, injected before the page's scripts. The draws of La lluvia are fixed with the page's own switch `?a=ventana`.
- Audio is silent: a recorded line "plays" for its own length on the paused clock and then ends (`AudioBufferSourceNode.start` is replaced), so the lit line of the book, the speaking mouth and the order of the lines are the real ones. Chromium runs with `--mute-audio`.
- `prefers-reduced-motion: reduce`, touch on, a mobile user agent. Screenshots are taken with CSS animations and transitions finished (`animations: "disabled"`). Chromium runs with `--mute-audio --disable-threaded-animation`, and just before each picture the page is hidden and shown again (`display: none` on the root, scroll positions put back by hand): without that, Chromium rasterised an icon or a shadow with a few pixels of different anti-aliasing from one load to the next.
- Progress is stored the way the app stores it: `seeds/*.json` are produced by running `palabras.js` (`PAL.cuento`, `PAL.responde`, `PAL.oido`, `PAL.minutos`) in the page, day by day, with the clock set to each moment; Repaso sessions follow cual.js's rules (up to 10 due words with a picture pair, most overdue first). Two parts are written the way the app writes them but not by the app's flow: `db.leidos` (what `marcaLeido()` writes at a book's last page) and, in `uno`, the three slow right answers. The `nivel` seeds are made by playing nivel.html.

## Animations that cannot be pinned

The mic's pulse, the call's rings and dots and the story mic's rings and dots are CSS animations. With reduced motion the page itself draws them still (the story's mic shows a static ring) or, in the call, not at all (the rings and dots stay at their start). The main pictures are taken that way. Where the look depends on the motion, a second picture ends `-con-movimiento`: motion on, every CSS animation paused at a set time (`document.getAnimations()`, 0.3 to 0.7 s). Everything the story engine draws on its canvas (the hand, the frame, the twinkles, the frog) is driven by the frame counter on the paused clock, so it is exact.

## What the pictures are not

- Text is drawn with Inter, the container's `system-ui`. A phone draws it with Roboto (Android) or San Francisco (iPhone): letters are a few percent narrower or wider, and a line can wrap at another word. Weights 500 and 600 are real in Inter. The picture of the canvas art, the colours, the sizes and the layout are exact.
- Only the portrait phone sizes of the order. The old app also has landscape layouts (a phone on its side, 844 × 390) and a 360 × 640 layout; they are not here.
- A real phone's keyboard, the system bars and the browser's own chrome are not drawn.

## What could not be captured, and why

- `All your words` (the Today card when there is no story at all): v=39 cannot reach it with its course. (`More words` in Palabras is reached: `palabras-una-palabra`, a word heard with no story played.)
- No About in the old Yo (only "How it works"): order 25's About is new.
- Speaking turns in stories: no story of v=39 carries a `tu_turno` mark yet (the real ones are marked later). The pictures of the mic (`cuento-micro-*`) are of a copy of El bizcocho served from memory with four clips marked (as `historia/tools/habla_motor_check.py` does) under `?mic=stub:si|si|si|si&abiertas=todas`. Nothing is written into `historia/`.
- The real call, the real recogniser and the real voice (they cost money or need a microphone): the call is the page's own `?callstub=1&stub=manual` stub, the voice test the page's own `?mic=stub:` recogniser.
- The map's own text: the `N/M` chip under the current stop and the stop numbers are drawn on the map's canvas, not in the page, so `strings.json` does not list them; they show in every `mapa-*` and `lugar-*` picture.
- Landscape and 360 × 640: see above.

## Things that look wrong in the old app itself (not fixed)

- Everything built so far played (`mapa-todo-jugado`, `yo-todo-jugado`): the chip says "1 · La casa", the frog stands on place 1 with an "11/11" chip, and Yo says "A1 · place 1 of 10 · La casa". `aqui()` in app.html gives place 1 when no built place is unfinished.
- A word with no picture pair ("toca", "con", "está", "¿quién?" ...) is never asked in Repaso, yet it gets a return date, and a day-one meeting sets it due. In `todo-jugado` that is why Palabras says "Nothing due today" while `PAL.vence('ear')` still lists words (28 in the seed): `plan()` and `palabras()` count only words with a pair. Their word sheets say "Comes back today" or "Comes back in N days" for a return that no screen ever asks.
- A place that has stories is "open" whether or not the places before it are done (place 3 in `lugar-abierto-3-nada-jugado`). "Locked until the places before it are done." appears only on places that have no stories yet.
- In the call, while Danny speaks his new line, the learner's last line stays in green under it (`llamada-danny-con-imagen`).
- Repaso: page 10 says the right picture gets "the green ring and the sign"; cual.js sets a `sign` flag that nothing draws. Only the green ring shows (`repaso-toque-mal-se-muestra-la-buena`).
