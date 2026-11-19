# ref/trazas: every story played by machine on the old page

Each of the 51 files the story page plays (stories, picture stories, routines), played on the OLD `historia/index.html` by rule, with
three plans each, every source of chance and time pinned. The Dart player of order 15 (`tool/juega.dart`) must give the same traces
(order 40). The same runs also read each scene's sprite cache for `ref/sprites/escenas/` (see `../escenas_sprites/README.md`).

## Run

```
node coqui/tool/ref/trazas/juega.mjs                    # all 51 x 3; replaces coqui/ref/trazas/ and coqui/ref/sprites/escenas/
node coqui/tool/ref/trazas/juega.mjs --only la-lluvia   # one file, three plans, into a temp folder (prints where); the repo is not touched
node coqui/tool/ref/trazas/juega.mjs --out DIR          # all of it into DIR (DIR/_sprites for the sprites) instead of the repo
```

Options: `--jobs N` pages at once (default 6; the output does not depend on it), `--root DIR` a site folder holding `historia/` (only to test the tool on a scratch story).
Needs Node 22 and the pre-installed Node Playwright with its Chromium (`chromium.launch()`, no options). It starts its own static server of
the worktree on 127.0.0.1 (a free port); nothing goes to the network. About a minute for all 153 runs. A second run gives byte-identical files.

## Which files

`curso.js` is read as it is (in a node `vm`): its places' `cuentos` (32 stories), `dibujos` (11 picture stories) and `haz` (8 routines) = 51.
`historia/cuentos/` holds 62 files: those 51 and the 11 review sets of `CURSO.cual` (`cual-frente` ... `cual-nevera`), which the story page does not play.
None is missing from the folder and none is in no list (checked on every run; `runs.json` `course`). Note: `cual.json` is a story (El parque), not a review set.

## What is injected, and why

Nothing in `historia/` is changed. Before any page script runs, `page-init.js` is added (Playwright `addInitScript`):

1. **`Math.random` is Mulberry32, seed 1**, made once at page start, counting its draws. The exact function:
   ```js
   function mulberry32(a) {
     return function () {
       let t = (a += 0x6d2b79f5);
       t = Math.imul(t ^ (t >>> 15), t | 1);
       t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
       return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
     };
   }
   ```
   Its first values for seed 1: 0.6270739405881613, 0.002735721180215478, 0.5274470399599522.
2. **A virtual clock.** `setTimeout`, `setInterval`, `clearTimeout`, `clearInterval`, `performance.now`, `Date.now` and palabras.js's `window.__PAL_NOW`
   are replaced. Time starts at 0 and moves only when the runner fires the next timer; nothing waits for real time, so how fast the
   machine is cannot change the order of anything. Rules: a delay is converted as the browser converts it (WebIDL `long`: `ToInt32`, so fractions
   are cut; negative is 0; no 4 ms clamp for nested timers); timers fire in order of due time, then of creation; an interval is re-armed at
   due + interval when it fires, and counts as created then; `setInterval(f, 0)` and `requestAnimationFrame` are refused (the page uses neither).
   `Date.now()` is 2026-03-02T15:00:00Z plus the virtual time. After each timer every queued microtask runs (a real `MessageChannel` round trip) before the next.
   The fast mode of juega.py (`?fast=`) is not used for speed: the page runs at `fast=1`, its own pace, on the virtual clock.
3. **Audio.** `AudioContext` is a stand-in. A clip "plays" in no time: its source's `start()` sets a 0 ms timer that reports its end
   (`onended`), unless `stop()` came first; a looping source (the rain) never ends. `decodeAudioData` gives a silent 0.1 s buffer.
   The runner answers every request for `historia/audio/<id>.mp3` itself: the 3 bytes `ID3` when the file exists in the worktree (the stand-in
   decodes those), 404 when not. `audio/ready.json` is the real one. So `VOICE` is true exactly when it would be on the site.
   Tones and oscillators do nothing.
4. **The thunder's noise.** juego.js's `noise()` fills a 2 s buffer (88,200 samples at 44.1 kHz) with `Math.random()` the first time thunder or
   rain sounds. The runner sets juego.js's `NOISE` beforehand to a buffer filled by a separate xorshift32 (seed 1), so those draws are never made
   and the Mulberry32 draw count is only what the story logic uses, as in the Dart runner.
5. `navigator.permissions.query` never answers (juego.js's `HAB.perm` stays null: it is only read by speaking turns); `navigator.vibrate` does nothing.
6. `document.createElement("canvas")` notes the stack that made each canvas (for the sprite dump), and the scene script's `KIT.escena(d)` call
   is caught to read the scene's list of things `d.cosas` (for the wrong-touch rule). Neither changes what the page does.

After the page has loaded the story, its scene and its clips, `page-drive.js` runs in the page (global code, so it sees juego.js's top-level names) and:

- wraps, to record and nothing else: `paso`, `espera`, `say`, `playClip`, every `SFX` method, `tone`, `PAL.cuento`, `PAL.oido`, `PAL.minutos`, `PAL.responde`;
- replaces `pasos` by the same loop (`for` over the list, `await paso(step)`), which also passes the step's place in the story file;
- redefines juego.js's `tap(x, y)` from its own source with one change: when the runner touches a thing, `what` is that thing, not what
  `E.hit(x, y)` finds. Every other line of `tap` runs as it is. This makes touches independent of pixel positions;
- sets `NOISE` (above);
- clicks `#go` and drives the run (below).

The page is opened as `historia/index.html?cuento=<id>&fast=1&rec=1&mic=stub:none&abiertas=todas`, in a fresh browser context each run
(empty localStorage and sessionStorage, so no `coqui.juego.ult` and no `coqui.juego.mem` from another story), viewport 390 x 844, time zone UTC.
`rec=1` makes the page call `PAL.cuento` (it skips it under `?fast` otherwise). `mic=stub:` and `abiertas=todas` are the page's own switches for
speaking turns: the stub answers in order from a list the runner fills turn by turn, and every word counts as open for speaking.

## The learner: when he touches, and what

The runner looks after every timer. A **choice is ready** when juego.js's `pending` exists, is not done, has been asked (`asked`), has finished
asking (`tEnd` is set: the lead, the line and any speaking bubbles are over), is not busy naming a poked thing (`busy`), no clip is playing
(`speaking` is 0) and the mic is not listening. A **speaking turn is ready** when the mic is ready (`HAB.est === "ready"` with a turn waiting).
When one becomes ready at virtual time t, the learner acts at t + 700 ms (`think`), after every timer due at or before that time has run,
if it is still the same situation then (otherwise it starts again from the new one). 700 ms is so the logged `ms` (time to answer) is not 0.

Each espera is one of: the **first** of an `ask`, `decide` or `elige` step (a choice point), the **retry** of a `decide` after a wrong touch
(`espera([pick])`), or **again** (a `decide` asked again after a free answer; never happens with these rules). Every choice point takes the next
letter of the plan; retries take none:

| Plan | Letters |
| --- | --- |
| `right` | r, r, r, ... |
| `wrong` | w, w, w, ... |
| `alternate` | r, w, r, w, ... (choice points counted from the start of the story, speaking turns outside a choice included) |

What is touched (a touch is always by thing id, at the point `Story.tapOn` would use: `E.handAt[k]` + 3 down, or the middle of `bx(k)`; the point
only places the stars):

| Step | r | w |
| --- | --- | --- |
| `ask` (one live thing: nothing can go wrong) | the asked thing | first a **wrong touch**: the first thing in the scene's list that is shown, is not the frog, is not an answer bubble, and that `tap()` would not count as the asked one (after `loose` and `alias`). The scene's list is `d.cosas` in file order, those whose `si(W)` is true or absent and whose box is not null; for El frente (no list) the order of its `hit()`: abuela (if `W.ab`), palma_pequena, casa_pequena, palma_grande, casa_grande (if `W.escondite`), pajaro (if the bird is out), bizcocho (if `W.plato != null`), nube (if `W.storm && W.nube`), puerta, ventana, casa, sol (if not `W.storm`), palma. It is a poke: free, the page names it and asks again. When the page has finished (choice ready again), the asked thing. If no such thing exists, the asked thing (`noWrong` in the choice) |
| `decide` (do, or `say` with answer bubbles) | `pick` (the right one) | the first live thing (juego.js's order: options, then `vale`, then `burbujas`) that is not `pick`, not in `vale` (also right), not a key of `gratis` (free; choosing it would loop), and does not map to `pick` or a `vale` by `alias`. If there is none, `pick` (`noWrong`; seven routines have one). After a wrong touch the page shows the right one: the retry touches `pick` |
| `elige` (no wrong answer) | the first option | the second option (as juega.py) |
| speaking turn (a clip marked `tu_turno`) | the stub hears, at the first try, the first accepted form of every target word, joined by a space; for an `elige` turn, those of the option the letter picks (first or second) | the stub hears nothing (`none`, a missed turn), at every try. For a turn inside an `ask` or `elige` the letter is that step's; then the touch follows the same letter |

**No story file has a `tu_turno` mark today** (0 of 62), so no recorded run has a speaking turn. The turn rule was checked on a scratch copy of
el-bizcocho with four marks (as `habla_motor_check.py` makes), outside the repo: line, ask and elige turns, heard and missed, all three plans finish.

## Files

`coqui/ref/trazas/<story>/<plan>.json`, plan `right`, `wrong` or `alternate`; and `coqui/ref/trazas/runs.json`.

A trace (long lists one entry per line):

| Field | What |
| --- | --- |
| `story`, `plan`, `seed` | the run |
| `list`, `place`, `scene`, `tipo` | where curso.js lists it (`cuentos`, `dibujos`, `haz`), its place, its scene, the file's `tipo` (`escucha`, `haz` or null) |
| `storySha256` | SHA-256 of the story file played. Remake the traces when a story file changes |
| `page`, `think` | the address played, and the think time (ms) |
| `end`, `finished` | `"finished"` when the page reached its end screen; otherwise why it stopped (`page error`, `stuck: ...`) |
| `virtualMs` | the virtual time at the end |
| `voice` | juego.js's `VOICE` (every clip of the story recorded). True in all 153 |
| `draws` | Mulberry32 draws: `atLoad` (before `#go`: 0 in every run) and `total` |
| `decisions` | juego.js's `LOG`, exactly as logged: `{word, asked, got, ok, ms}` for a decide, `{word: null, asked: "libre", got, ok: true}` for an elige. `ms` is on the virtual clock, so it is kept: it is the think time times `FAST` (700). No field is wall-clock |
| `marks` | the scene's `W.marcas` at the end (the round marks of the kit scenes), or null |
| `lost` | `W.lost` at the end |
| `ending` | `lost`, the stake's `steps`, `heart` (`W.heart`: the win sign), `final` (the paths of the `final` steps that ran, so which branch of each `if`), `screen` (`#app`'s state: `end`) |
| `estado` | the scene's `estado(W)` string at the end (kit scenes), or null |
| `result` | the `StoryResult` the page handed to `PAL.cuento`: `id`, `focusWords` (`S.focus_words`), `backAgain` (`S.back_again` or []), `lost` (`S._lost`), `log` (the Decision list). Null for picture stories and routines, which call `PAL.oido` instead |
| `listened` | the id given to `PAL.oido` (picture stories and routines), or null |
| `minutes` | what the page gave `PAL.minutos` (virtual minutes) |
| `choices` | one per choice point: `espera` (its number, counted from 0 over all esperas), `t`, `kind`, `step` (its path), `letter`, `live`, `pick`, `touched` (in order), `noWrong` |
| `touches` | every touch: `t`, `what`, `why` (`right`, `wrong`, `wrong-poke`, `retry`, `first`, `second`), `espera`, `x`, `y` (the point used) |
| `speech` | `turns`: juego.js's `HAB.log` as it is; `events`: what the stub was told to hear per turn and the mouth answers written (`PAL.responde`). Empty in all 153 |
| `memory` | juego.js's `MEM` at the end (what `recuerda` steps saved for later stories) |
| `clips` | every clip the page asked for, in order: `t`, `id`, `via` (`say`: juego.js's `say()`, a line with its pause; `clip`: a direct `playClip()`: a name on a touch, a repeated question, a speaking bubble), `who` (the clip's `who` in the story file: `narr`, `tu`...), `talker` (who speaks it on screen, from juego.js's `partes()`: `coqui`, `abuela`, a person), `voice: false` when there was no recording for it (none) |
| `sounds` | every `SFX` call in order (name, or `[name, args...]`), and every `tone()` a scene made directly, as `["tone", f0, at, dur, type, vol, f1]` |
| `steps` | every step `paso()` ran: `n`, `t`, `path` (where it is in the story file, like `beats.15.wrong.2`; null for a list a scene built), `kind` (the key that chose its branch in `paso`: `line`, `say`, `wait`, `cam`, `dots`, `set`, `if`, `act`, `ask`, `decide`, `elige`, `draw`, `reparte`, `calc`, `recuerda`, `cost`), `id` (line and say: the clip after `$` filling), `act` (act: its name). Lead lines of an ask are said by `espera`, not `paso`: they are in `clips` only |
| `errors` | page errors and console errors (none) |

`runs.json`: the command, seed, plans, think time, SHA-256 of juego.js; `count` (played, runs, finished, the ones not finished with why);
`course` (the counts above); and `runs`: per run `story`, `plan`, `list`, `scene`, `file`, `sha256` (of the trace file), `bytes`, `end`, `finished`,
`decisions`, `choices`, `lost`, `draws`, `errors`, and `identical` when plans of that story came out the same (`right-equals-alternate`,
`right-equals-wrong`; compared on everything but the plan's name). The 11 picture stories have no choice at all: all three plans are identical, flagged.

## What a Dart player must do to reproduce a run

- Seed one `Mulberry32(1)` at the start of the page (before the story loads), used for every `Math.random()` of juego.js and the scene; never
  for the thunder's noise. `fresh()` runs at load and again when the story starts; nothing draws before `#go` today (`draws.atLoad` is 0 in every run).
- A fake clock starting at 0 with the timer rules above (`ToInt32` delays, order by due time then creation, intervals re-armed on firing), and all
  microtasks run between timers. `FAST = 1`, `?rec=1` behaviour (`storyFinished` called). Each run with empty storage.
- A `ClipPlayer` whose `play` ends by a 0 ms timer; a clip exists exactly when `historia/audio/<id>.mp3` exists and is in `ready.json`.
- Touches by thing id, with juego.js's `tap` logic after the hit test, at the point above (it only places stars).
- The learner as above: ready condition, 700 ms, one letter per choice point, the per-kind rule. The scene's list for the wrong touch is the
  scene's `cosas` order (El frente: its `hit` order).
- Then compare: `decisions`, `marks`, `lost`, `ending`, `result` / `listened`, `clips` (ids, `via`, order), `steps` (`path`, `kind`), `choices` and
  `touches` (`what`, `why`), `draws.total`, and `memory`. The `t` fields are expected to match too if the timers are ported faithfully; `x`, `y` depend on
  today's screen boxes and will differ after a scene's `remap` (compare them through the remap, or not at all). `sounds` are for order 18.

## What these recordings do not cover

- **Speaking turns:** no story is marked, so none happens (see above). Only the rule is in place.
- **Listen mode (`?oir=1`)**, `?txt=` other than `con`, `?mem=` and forced draws (`?a=puerta`): not played.
- **Memory between stories:** every run starts empty, so steps that read `mem_*` (in donde-esta-el-pajaro and la-familia) always take their "nothing remembered" branch, and `alterna` decides draw fresh.
- Touches before a question has finished (a touch counts from the first word of the lead), touches on the frog, waiting long enough for the 9 s repeat, the Play again and Next buttons, the X.
- Clips with real lengths: every clip takes no time, so a touch can never land while a line is playing, and bubble and caption timing is not exercised.
- `review` sets (`cual-*`), ¿Cuál? and the level check: other pages.
- Pixel positions: the runs never use `E.hit`, so touch boxes are not tested here (order 06 records them).

## Nondeterminism found and how it is pinned

- `Math.random` (draws, `reparte`, `baraja`, `decide` picks, scene acts such as `azar()`): Mulberry32 seed 1, counted.
- The thunder's noise buffer (88,200 draws on first thunder or rain): filled by injection, no draws.
- Real time everywhere (`setTimeout`/`setInterval` waits, `performance.now` for `ms` and `minutos`, the speech stub's own real-time pace, the
  9 s repeats, the 6 s wait for the voice in `run()`): the virtual clock. The runner waits in real time, before `#go`, until the story, the scene
  script and every clip have loaded, so `Promise.race([voiceReady, sleep(6000)])` always finds the voice ready.
- Audio decoding and clip ends: the stand-in AudioContext, ends by 0 ms timers.
- The microphone permission query (answers at an unknown time): never answers.
- Stored state between plays (`coqui.juego.ult`, `coqui.juego.mem`, `coqui.palabras.v1`, the session's speaking flag): a fresh browser context per run.
- Running several pages at once: each page has its own clock; results are merged in a fixed order. `--jobs 8` and `--jobs 3` gave identical files.

## Old code: things noticed (not fixed)

- `cuentos/*.json`: no clip carries a `tu_turno` mark, so the speaking-turn engine (docs/hablar/01-decisiones.md) never runs in a real story yet.
- Not a bug, but worth knowing when comparing: `libre` decides (every routine) write nothing to `LOG`, so routines give `decisions: []` in every plan; their plans differ only in touches, clips and steps.
