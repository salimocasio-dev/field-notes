# ref/progress: the scheduler, recorded

How `historia/palabras.js` (the word records and the scheduler, global `PAL`) behaves, call by call, so that
`coqui_progress` (order 16) can be checked against it. Made by this folder, written to `coqui/ref/progress/`.

## Run

```
node coqui/tool/ref/progress/make.mjs        # writes coqui/ref/progress/ (deletes and rewrites both zone folders and index.json)
bash coqui/tool/ref/progress/coverage.sh     # the same run under c8 (fetched by npm into a temp folder); prints line and branch coverage
```

Node 22, nothing to install for `make.mjs`. A second run gives byte-identical files. `make.mjs` starts itself once per time zone
with `TZ` set in the child's environment (`UTC`, then `America/New_York`), because palabras.js mixes local time and UTC.

## How palabras.js is run

- The file is read as it is and run with `vm.runInContext` in a fresh context per sequence (a fresh `PAL` each time).
  `PAL` is read back by a second script in the same context (`"PAL"`): a top-level `const` is visible to later scripts of the same context. The file is not changed.
- The context has: `window = {__PAL_NOW}` and an in-memory `localStorage` (only the key `coqui.palabras.v1` is kept).
- The clock is palabras.js's own hook, `window.__PAL_NOW`, set to the step's time before every call. In those sequences `Date.now`
  is replaced by a function that throws, so a read of the real clock would stop the run (none happens).
  Three sequences reach the other branch of `now()` on purpose (setup `clock`): `"zero"` (`__PAL_NOW = 0`, falsy, so palabras.js calls `Date.now`)
  and `"none"` (no `window` at all). There `Date.now` returns the same scripted time.
- `new Date(...)` is the real one: `setHours` and `getDate` follow the process's `TZ`; `toISOString` is UTC. That mix is what is being recorded.
- Scripted times are written as local wall-clock times ("2026-03-03 03:59") and turned into epoch ms in the run's zone, so both zones follow
  the same local day; the epoch values differ between the zones.

## Files

`coqui/ref/progress/<zone>/<sequence>.json`, zone `UTC` or `America_New_York`; `coqui/ref/progress/index.json`.

A sequence file:

| Field | What |
| --- | --- |
| `id`, `title` | the sequence, and what it is for |
| `tz` | the IANA zone it ran in |
| `source`, `sourceSha256` | `historia/palabras.js` and the SHA-256 of the text that was run |
| `setup.stored` | the text in `localStorage["coqui.palabras.v1"]` before palabras.js loads (null: none) |
| `setup.storage` | `"memory"` (works), `"throws"` (every getItem and setItem throws: a blocked private window), `"absent"` (no `localStorage` at all) |
| `setup.clock` | `"hook"`, `"zero"` or `"none"`, above |
| `dartReplayable` | false when a step has no Dart form that changes the store the same way (only `PAL.rec`, sequence 27) |
| `initial.store` | `PAL.db` right after load, before any call; `initial.saved`: the stored text then |
| `steps` | one object per call, in order, one per line |

A step:

| Field | What |
| --- | --- |
| `i` | its index |
| `now` | the clock, epoch ms (what `__PAL_NOW`, or `Date.now`, returned during the call) |
| `local` | the same time as local wall clock with its UTC offset, for reading only |
| `call` | the old name: a function of `PAL` (`oida`, `responde`, ...), or `db` / `STAGES` (reading those properties) |
| `args` | the arguments exactly as passed, positional. `undefined` is written as `null`; `undefinedArgs` lists the positions that were really `undefined` |
| `member` | the `ProgressStore` member of page 12 that the call maps to; null when there is none |
| `dart` | the same arguments by the Dart member's names (table below); null when the call has no Dart form |
| `note` | why a call has no member, where that applies |
| `returns` | what the call returned (JSON copy taken at once). Absent when it returned `undefined` |
| `throws` | instead of `returns`: the old code threw (V8's message). The store is as the call left it |
| `store` | the WHOLE `PAL.db` after the call (JSON copy). This is the in-memory store, `ProgressStore.raw` |
| `saved` | what is in `localStorage` after the call: `"same"` when it equals `store`; otherwise the parsed stored JSON, `null` for nothing stored, or `{"text": ...}` when it is not JSON. It differs from `store` after `rec` (rec does not save), with storage that throws, and before the first save of a store loaded from bad text |

Numbers are JSON numbers as JavaScript writes them (`gap` is fractional after a miss: `0.3333333333333333`). Compare them as numbers.

`index.json`: the command, the zones, the exported names of `PAL`, `notCalled` (exported names no sequence calls: empty), and per file
the zone, the step count, the calls made (by name, with counts), `dartReplayable` and its SHA-256.

## Old name -> ProgressStore member

| palabras.js | ProgressStore | `dart` fields |
| --- | --- | --- |
| `oida(w)` | `heard(w)` | `w` |
| `responde(w, sk, ok, ms, intro)` | `answer(w, skill, ok:, ms:, intro:)` | `w`, `skill` (`"ear"`/`"mouth"`), `ok` and `intro` as booleans (JavaScript truthiness: absent intro is false), `ms` (null when absent) |
| `cuento(S, log)` | `storyFinished(StoryResult)` | `result`: `id` = `S.id`, `focusWords` = `S.focus_words` or [], `backAgain` = `S.back_again` or [], `lost` = `S._lost` or 0, `log` (Decision list, or []) |
| `presume(words, stories, log)` | `presume(words, stories, log)` | each one or [] |
| `oido(id)` | `listened(id)` | `id` |
| `minutos(m)` | `addMinutes(m)` | `m` |
| `vence(sk, t)` | `due(skill, at:)` | `skill`, `at` (null when absent; palabras.js uses `t\|\|now()`, so `at: 0` also means now: sequence 13 has one) |
| `racha()` | `streak` | none |
| `abiertaHabla(w)` | `openForSpeaking(w)` | `w` |
| `norm(s)` | `normalize(s)`, top-level in coqui_contracts | `s`; null `dart` for the three non-string inputs of sequence 16 (42, true, an array), which the Dart signature cannot take |
| `reset()` | `reset()` | none |
| `PAL.db` | `raw` | none |
| `rec(w)` | none | the record is made in memory and not saved. Used only in sequence 27 |
| `save()` | none | the Dart store saves after every change. The store does not change |
| `PAL.STAGES` | none | the constant |

The parts of `ProgressStore` that palabras.js does not have (`hasRead`, `markRead`, `added`, `add`, `setting`, `export`, `import`) are not recorded here.

## What a Dart test does

For each file: build the store on a fake `KeyValueStore` holding `setup.stored` (for `"throws"` and `"absent"`, one whose read and write throw)
and a settable `Clock`; check `raw` equals `initial.store`; then for each step set the clock to `now`, make the `member` call with `dart`
(skip steps whose `member` is null: `save` and `STAGES` change nothing), compare `returns` (or that it threw where `throws` is set) and
compare `raw` with `store`, numbers as numbers. Do it for both zones, with the test process in that zone.
Sequence 27 (`rec`) cannot be replayed as it is: ProgressStore has no member that makes a record without hearing it.

## The sequences

31 per zone (30 asked, one added after measuring coverage). The ones order 05 names:

| Asked | Sequence |
| --- | --- |
| the 20-day run of page 08 | 01. Page 08 says only "a node test over a simulated 20 days"; that test is not in the repo, so this one is rebuilt from page 08's rules: Mar 2 to 21 2026, five story plays in the evenings (la-lluvia twice), every morning `vence` and an answer for every due word (fast, slow or a miss by a fixed rule from the word and the day), the words missed come back 10 minutes later and are answered, two days skipped, `racha` every evening. It crosses the US clock change of Mar 8 |
| a miss | 02 |
| three misses in a row | 03 (and 30, the parked word afterwards) |
| a slow right answer | 04 (2600 ms, and the limit: 2000 is not slow, 2001 is) |
| `presume` | 05 |
| a story finished twice | 06 (and la-lluvia twice in 01) |
| an answer at 3:59 and at 4:01 local | 07 and 08 |

The others: 09 intro answers; 10 "good" (3 returns over 14 days); 11 steps 1 to 4; 12 mouth and ear apart, open for speaking; 13 vence's order and filters;
14 the streak; 15 oido and minutos; 16 norm; 17 reset; 18 loading a stored store (unknown keys, missing ear or mouth); 19 a stored text that is not JSON;
20 storage that throws; 21 no window; 22 `__PAL_NOW = 0`; 23 and 24 the clock changes of Mar 8 and Nov 1 2026; 25 cuento's edge cases;
26 late evening (in New York the UTC day has already turned); 27 rec; 28 an answer on a word never met; 29 the gap; 30 a parked word;
31 (added) a stored store with `cuentos` and `ajustes` null.

## Coverage of palabras.js (c8, V8 block coverage, both zones, all 31 sequences)

Lines 59/59 (100%), functions 18/18, branches 97/98. The one branch not reached is the right side of `db.cuentos=db.cuentos||{}`
inside `cuento` (line 44). It cannot be reached through PAL: the load line and `reset` always leave `db.cuentos` an object, and no
old page writes it (app.html only reads it). Only an outside write to `PAL.db.cuentos` reaches it.

## What the recordings show about the old code (not fixed)

- Sequence 18: a stored word record with no `ear` (or no `mouth`) makes `vence` throw (`r[sk].etapa` on undefined). `abiertaHabla` guards it; `vence` does not.
- The streak and the day keys are UTC dates of local times. In New York every `racha` at 21:00 returns 0 (sequence 01: 0 every evening), because 21:00 there is already the next UTC day, which has no entry yet. In sequence 26 a play at 19:30 on Mar 2 in New York is filed under Mar 3, and `racha` is 1 just after midnight but 0 at 20:30 the same day.
- `nextMorning` is "today 4:00 local, plus 24 hours". On the night the clocks change that is 5:00 (Mar 8, sequence 23) or 3:00 (Nov 1, sequence 24) in New York, not 4:00.
- At 3:59 the word is due at 4:00 the next day, not one minute later (sequence 07): the 4 am cut is a day boundary only for the day after.
