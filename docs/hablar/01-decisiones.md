# Speaking inside the stories: the decisions

Written Nov 16 2026 by the planning chat. Every choice is made here. Whoever builds this follows it and makes no design calls. If something here cannot be built as written, stop and say what and why; do not improvise.

## His words

- Asked when the research says speaking starts: per word, 2 to 3 days after he first hears it.
- "So basically the design is fine. You speak to Danny after finishing a story. Except right now we should probably put some speaking prompts in the next stories that use the previously learned vocabulary."
- "How big a job is it to edit the existing stories" — then: do it, prepared so it can be executed without decisions.
- Standing rules: anything he says must be heard by the app (never a self-report button); Spanish only on screen except menus; only the home map is game-styled, the rest follows his UI plan (docs/proyecto/09-ui-plan.md).

## What changes for him

- Some of the coquí's lines become his turn. Instead of the coquí saying "¡Bien, gracias!", he says it, the app hears it, and the story goes on.
- A line is his turn only when every word it tests is open for speaking (below). Until then the line plays exactly as today. So the same story is all listening on the first play and has speaking turns on later plays.
- In the next new stories (A comer onward), the speaking turns use words from earlier scenes. That is in 03-para-historias-nuevas.md.

## When a word is open for speaking

A word is open for speaking when EITHER:
1. its ear record is at stage 3 or more (the same test as llamada.js abierta(w); the level check sets stage 3, so placed words count), OR
2. its mouth record already has at least one answer (mouth.n > 0).
Write this as a new function PAL.abiertaHabla(w) in palabras.js. Do NOT change llamada.js or how the call picks its words.

A line is his turn only if ALL its target words are open.
A switch in Yo: "Speak in stories" (English; menus are English). On by default. Off = every line plays as today.

Turns never happen (the line plays as today, nothing recorded) when: OIR=1 (Escuchar), S.callado is set, the Yo switch is off, or speaking is unavailable (below). Mouth writes follow the same condition as PAL.cuento at juego.js:280 (not under ?fast without ?rec).

## Once per play

A clip with "tu_turno" is a turn at most once in one play of a story: at its first live occurrence. Every later occurrence in that play plays as today. At most 4 turns in one play (the first 4 live ones).

## The speaking turn on a plain line, step by step

A plain line is a bare string step or {"say": id}, in paso().
1. **Lead-in.** The narrator line before it plays as today.
2. **The model, only if new.** If ANY target word has mouth.n = 0, the coquí's recorded line plays first, as today, then the narrator's "Ahora tú." (existing clip ahora_tu). Otherwise go straight to step 3.
3. **His turn.** The coquí's bubble appears empty with only a mic icon (it shows even when TXT is "no"). If the frog is not visible or is off camera, the mic bubble sits just above the mic button instead. A large round mic button appears: bottom centre of the scene in portrait; bottom of the right column in landscape (UI plan: controls in the right column). At least 72 px, the UI plan's system-state colours. No words of the line are shown. The camera holds still during the turn. The frog does not change pose (there is no "facing" pose; he blinks as usual).
4. **Mic ready only after the lead-in.** The button is dead until the line (and "Ahora tú.", if played) has finished. hush() runs before recognition starts.
5. **He taps to start.** Listening: the button pulses on a timer (no live level ring; do not open getUserMedia). Recognition ends by the browser's own end-of-speech; call stop() at 6 s at the latest.
6. **Processing.** Show the processing state on speechend, audioend or the 6 s stop, whichever comes first.
7. **Heard right.** His recognised words (the best alternative) show in the coquí's bubble, if TXT allows; a green tick shows always; the usual right signal (SFX.right, stars, via senal). The coquí's recording does NOT play again: his voice was the line. The story goes on. No "¡Muy bien!".
8. **Not heard right.** First miss: "Ahora tú." plays again; the mic is ready again. Second miss: the coquí's recording plays (the model), a soft neutral sound, no stars, the story goes on. Never costs anything, never blocks.
9. **Waiting is free.** No tap within 9 s: "Ahora tú." plays again, every 9 s. All timers pause while listening and processing. Touching the frog does nothing while listening or processing.
10. **Recorded.** One answer per target word: PAL.responde(word, "mouth", ok, ms, false). ok = heard right on try 1 or 2; wrong after two misses. ms = time from the tap to the recogniser's speechstart event (if there is none, pass 0). Never write the ear record.

## The speaking turn inside a signed "ask"

The ask step whose target's "said" clip has "tu_turno" (ask() only plays said[t]).
- The question line plays as today. During the turn the answer bubbles do NOT speak (no voces), and the sign does NOT show. He answers from the picture and the question: this is recall, not repeating.
- The mic bubble and button, steps 3 to 6 and 9 as above. The repeat every 9 s is the ask's own question line (no "Ahora tú.").
- No model first, ever.
- Heard right: green tick, the usual right signal, the ask counts as done; said[t] does NOT play again; the story goes on (st.after, bien, then).
- Heard the OTHER option, or nothing that matches: a miss. Two misses: the voces, the sign and the touchable bubbles come back exactly as today, and he touches the target. Write mouth wrong.
- Recorded as on a plain line: right on try 1 or 2, wrong after two misses.

## The speaking turn inside "elige"

The elige step where the said clips of its options have "tu_turno" (a choice with no wrong answer).
- The question line and the option bubbles show as today (pictures, nod and shake). The mic bubble and button appear too. He may answer by speaking OR by touching, whichever comes first.
- Speaking: if the words match the targets of exactly one option, that option is taken. Green tick, said[option] does NOT play again, the story goes on to that option's steps. Matches none or both: a miss. After two misses the mic goes away and the bubbles are the only way, as today.
- No model first. No "Ahora tú.". The repeat every 9 s is the question line.
- Recorded: a spoken match writes mouth right for that option's targets. A touch or a miss writes nothing (there is no wrong answer in elige).

## Never inside "decide"

A decide costs (a slice, a step of rain). Recognition errors must never cost him. Lines inside decide stay touch, even when the clip has "tu_turno".

## What counts as heard right

- Recognition: window.SpeechRecognition || window.webkitSpeechRecognition. lang "es-US", interimResults false, maxAlternatives 5, continuous false. (iPhone usually gives 1 alternative; that is fine.)
- Normaliser: reuse llamada.js's norm() exactly, copied into palabras.js as PAL.norm (it lowers case, drops accents and turns ñ into n, turns everything that is not a-z0-9 into a space, and pads with a space each side). Apply it to the alternatives AND to the accepted forms at runtime.
- Heard right = for EVERY target, at least one accepted form f has (" " + norm(f).trim() + " ") inside norm(alternative), for ANY alternative. Extra words are fine; order does not matter.
- Targets and forms: the "tu_turno" field on the clip (from 02-marcas.json). Nothing else is accepted.

## When speaking cannot work

- Before showing the mic: recognition must exist, and navigator.onLine must be true. If navigator.permissions can query "microphone" and it says "denied", that counts as unavailable.
- Errors during a turn:
  - "no-speech", "aborted" by the 6 s stop, or a result that doesn't match: a miss.
  - "not-allowed", "service-not-allowed", "network", "audio-capture", "language-not-supported": unavailable. The line plays as today (plain line: the coquí's clip; ask/elige: touch as today). Nothing recorded. No more turns for the rest of the session.
- Unavailable: show once per day, in Yo only (never inside a story), the English note: "Speaking in stories isn't available on this phone right now."
- The first turn triggers the browser's own permission prompt. Nothing else is added.
- iPhone: after recognition ends, call ac().resume() before playing any clip, and give every clip played after a turn a time limit (its length + 1 s), so the story cannot hang.

## Machine tests

- ?mic=stub:<r1>|<r2>|... feeds the recogniser results for the next attempts, in order. Each ri is either alternatives split by "/" (e.g. "hola abuela/ola abuela"), or "none" (no-speech), or "error:<code>" (e.g. error:not-allowed).
- ?mic=off: recognition is unavailable.
- ?abiertas=todas: every word counts as open.
- None of this runs without these query values.

## The voice test before marking all stories

One page, historia/habla-prueba.html, styled per the UI plan (calm, plain). English instructions in one line: "Tap the mic and say each Spanish line." It shows 12 lines in Spanish, one at a time, with a mic button, and records what the recogniser heard for each (all alternatives) and whether it counts as heard right under the rule above. Lines (all from La casa): hola, abuela · sí · no · gracias · adiós · la casa · la puerta · la ventana · quiero jugo, por favor · me llamo [any name] (target: "me llamo") · ¿cómo estás? · uno, dos, tres (accept "uno" or "1", and "tres" or "3"). At the end: "Heard right: N of 12", and per line what was heard. Results kept in localStorage under coqui.hablaprueba so the build session can read them on his phone only if he shares them; he only needs to say the number. If fewer than 10 of 12 are heard right, stop and tell him before marking the stories; the planning chat then decides (other lang codes, looser forms, or a different recogniser).

## What it costs

- The browser's recognition is free. On Android Chrome it sends the audio to Google to recognise. No new recordings: every clip used already exists.
- Nothing is spent. No new account. No key.

## What is not decided here and must not be invented

- Pronunciation scoring, pitch contours, waveforms: not part of this. Heard right or not, nothing more.
- Speaking in ¿Cuál?, Escuchar or the level check: not part of this.
