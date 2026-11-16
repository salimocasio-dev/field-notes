# Work orders: speaking turns in the stories

For the Claude Code session. Every decision is already made in 01-decisiones.md, 02-marcas.md (+ 02-marcas.json) and 03-para-historias-nuevas.md. Hand each order below to an agent (Sonnet is enough). An agent that hits a question these pages do not answer stops and reports it; it does not decide. The session collects those questions and asks the planning chat (or Salim, in one go).

Order of work: 1 and 2 in parallel → 3 (his voice test) → 4 → 5 → 6 → 7.

## 1. Engine (one agent)

Build exactly what 01-decisiones.md says, in historia/juego.js (and palabras.js / app.html where named).
- A speaking turn function, called ONLY from paso() for plain lines, from ask() for the target's said clip, and from elige() for the options' said clips, when the clip has "tu_turno" and every target word is open (01, "When a word is open") and the Yo switch is on and recognition is available. Never from decide(), say() or playClip().
- PAL.abiertaHabla(w) and PAL.norm in palabras.js, per 01. Do not edit llamada.js.
- Once per play, and at most 4 turns per play, per 01.
- Signed ask during a turn: no voces, no sign, until two misses. Elige: speech or touch, whichever first. Per 01.
- iPhone guards per 01: ac().resume() after recognition, a time limit on clips after a turn.
- The mic button, its states (ready, listening, processing), the coquí's empty bubble with a mic icon, the green tick, per 01 and the UI plan (docs/proyecto/09-ui-plan.md).
- Mouth record writes: PAL.responde(word, "mouth", ok, ms, false), one per target word per turn.
- The Yo switch "Speak in stories" (default on) and the once-a-day note in Yo when recognition is unavailable.
- The test switches exactly as in 01, "Machine tests" (?mic=stub:..., ?mic=off, ?abiertas=todas).
- Raise ?v= on every script tag that loads a changed file (index.html, app.html, cual.html, nivel.html).

## 2. Voice test page (one agent, in parallel with 1)

historia/habla-prueba.html exactly as in 01, "The voice test". Same recogniser settings and normaliser as the engine (import or copy the same function; no differences). Its own ?mic=stub for the machine check.

## 3. His voice test (the session itself, not an agent)

- Push 1 and 2. Send Salim one link: historia/habla-prueba.html?v=N, with one line: "Tap the mic and say each line. Tell me the number at the end."
- 10 or more of 12 heard right: go on to 4.
- Fewer than 10: stop. Report the lines and what was heard to the planning chat. Do not change the settings or the accepted forms yourself.

## 4. Marking the 31 stories (one agent)

- For each story id and clip id in docs/hablar/02-marcas.json, add the field "tu_turno" with exactly that value to that clip in historia/cuentos/<story id>.json. Change nothing else. Keep the file's existing formatting style (indentation).
- Check before writing: the clip exists in that file and its "who" is "tu". If not, stop and report.
- A story file change starts the audio job; no clip text changes, so nothing new is recorded. Confirm on the job's log that 0 clips were made.

## 5. Machine tests (one agent)

Extend historia/tools/juega.py (or a new tools/habla_check.py) to drive turns with the stub. For every one of the 31 stories, with ?abiertas=todas:
- (a) every turn heard right on the first try, (b) every turn missed twice, (c) ?mic=off, (d) without ?abiertas (first play: no turn may fire), (e) error:not-allowed on the first turn (no more turns that play), (f) in each signed-ask turn, the other option said twice (bubbles and sign come back, touch works).
Check: no page errors; no story hangs (time limit per story); the story reaches its end every time; a turn never changes the stake (W.lost) ; no turn fires inside a decide; mouth records are written in (a) and (b) and not in (c) or (d); elige and ask turns pick the option that was said; a clip is a turn once per play; never more than 4 turns per play; no voces and no sign during an ask turn; ?oir=1 has no turns; ear records are the same as in a run without turns.
Also: the call with Danny still opens words the same way (tools/llamada_check.py passes).

## 6. Reviews (fresh agents that did not build it)

- Beginner reviewer: reads 02-marcas.md and the stories' scripts with the turns marked, as a beginner, against docs/proyecto/03-requirements.md. Question: "At each turn, is it clear what the coquí should say, from the story alone? Is any turn dull, padded or out of place?"
- Silent frame reader: frames of turns (?txt=no): the empty bubble with the mic, the mic button in its three states, the green tick. "What is this asking you to do?"
- Fix only what is real and inside these pages. Anything that needs a design decision: report, do not decide.

## 7. Ship

- Push. Check the live site via the GitHub API (docs/proyecto/07). Send Salim the app link with a new ?v= and one line per point: what changed, what was checked, what is a guess.
- Update docs/proyecto/00 and 08 (and the claude.ai Project pages if this session can reach them).

## New stories from now on

Every new story follows 03-para-historias-nuevas.md. Its turns are part of the script review and of the machine tests above.
