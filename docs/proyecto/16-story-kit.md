# Story kit: everything needed to write a story

Written Nov 20 2026. Salim asked why stories cost so much to make: "Theyre just stories."

**To write a story, read this page and the sheet for your scene. Nothing else.**

- The sheets: `docs/proyecto/kit/scene-<id>.md` (one per scene, made by `historia/tools/hojas_escena.py`).
- New words for a new place: only that place's section of 02-all-40-scenes.
- Do not read the engine (juego.js), the scene code (escenas/), the Flutter code (coqui/), or the other project pages. Everything a writer needs from them is here.
- If something a writer needs is missing from this page, add it here. Don't send the next writer back to the long pages.

## What a writer does and does not do

- A story is one JSON file in `historia/cuentos/`, plus one line in `historia/curso.js` (the place's `cuentos` list). That is content. Nothing else changes.
- A writer never edits code: not `escenas/`, not `juego.js`, not `coqui/`.
- When a story needs something the scene can't do yet (a new act, a new thing to touch, a new spot, a new kind of step), the writer doesn't build it. Put it in a short **Needs** list at the end of the script: the name, what it does on screen, which beat uses it. The code lane builds it.
- A story in a scene that already exists should need nothing new. That is the cheap case.
- A new scene (places 4 to 10) is design work: the set and the sheet come first (page 13, orders 30a to 39a, the orchestrator's job). Write the scripts against the scene's word list. The scripts' Needs lists become the scene designer's brief.

## His rules for every story

From 03-requirements and the reviewers' list in 07. His words outrank everything, including research.

**How it sounds**
- The voice talks to him in whole, natural sentences and asks real questions. Never bare labels. ("La casa. Es la casa. Toca la casa." was "beyond boring".)
- Short praise ("¡Muy bien!"), then on to the next thing. The story keeps moving.
- No ask repeated to pad it. No long dead pauses: something moves in every gap.
- Slow, plain, A1 words. No pet names. Nothing religious or personal.
- Course words are Puerto Rican. Where the plan's word (page 02) and the word Puerto Ricans use most in everyday speech differ, the everyday one wins, in every line (Salim, Nov 21: "I just want the Spanish usable. Pick whatever is most used."). So: después, not luego; al frente de, not delante de; se monta, se baja, se va at a guagua; ¿para dónde vas?; ¿en qué trabajas?, not a bare ¿qué haces?; bote, not barco, for a small boat; tiene puesto, not lleva; está lloviendo; ¿cómo está el tiempo?, not ¿qué tiempo hace?; el radio (the set); ven acá; un sándwich. The Spanish reviewer names the everyday word; the writer takes it and changes page 02's list to match.
- Who is talking is always clear. Narrator lines with another speaker start "Abuela dice:" (the bubble shows the rest).
- The coquí has his own voice and lines ("who": "tu"). He replies when spoken to.
- Spanish only on screen. English only for menus, the welcome, the stuck line, and the one line before a new grammar pattern.

**How it plays**
- A goal he can see without words. One thing at stake, lost one step at a time.
- The opening: the voice talks to him, asks a real question, a big sign shows what to touch. Nothing can go wrong yet.
- A turn. Then two or three real decisions with no sign.
- An ending decided by what is left. Losing changes the last picture. It never removes a beat.
- Every costed decision has two real options, and the picture doesn't say which. Only the Spanish does.
- A word is shown or taught before it decides anything.
- A right move changes something for good, and always gets the same signal.
- After a right move, nothing in the picture points at the next answer. (A lamp beside the door did. The frog standing at the door did.)
- Each new word is heard at least 3 times on a clean run.
- A miss is filed under the word that decided it (`tests`).
- Poking around is free. Waiting is free (the line replays every 9 s). No clock.
- Words outside the scene's list are fine. He hears many and focuses on the new ones.
- Pictures carry it: someone who knows zero words understands what happens from the picture alone.
- Length: a clean run of the built stories is 77 to 85 s with instant touches.

**Speaking turns** (every story from A comer on)
- 2 to 4 turns. Each is a coquí line he says instead of the coquí.
- Only words from EARLIER stories (their `focus_words`, earlier in curso.js). Never a word new in this story.
- Only on a plain coquí line, a coquí line inside `elige`, or a coquí line inside a signed `ask`. Never inside a costed `decide`.
- A natural reply: answering, greeting, thanking, asking for something, sí or no. The line just before sets it up. Not a drill, not an echo of the line just heard.
- 1 to 5 words. Not two turns in a row.
- In a signed ask, the turn hides the sign: the question and the picture alone must make the answer clear.
- How to mark one is under "The file", below.

## Reviews

Before a script goes to him: two fresh reviewers who didn't write it. A self-review doesn't count.
- Give each reviewer **only** the script and the "His rules" section of this page. Not the project pages.
- Reviewer 1 plays it as a beginner against his rules: where is it dull, where is it unclear? At each speaking turn: is it clear what the coquí should say, from the story alone?
- Reviewer 2 checks the Spanish as a Puerto Rican speaker.
- Fix what is real. Tell him what was found and what was left.

After it is built: a fresh reader sees frames only, no sound, no words (`?txt=no`), and says what happens. Give that reader only the frames.

## The work, in the cheap order

1. Write several scripts at once as plain text: beats, lines, decisions, stake, ending, Needs. This is the cheap part.
2. Reviews, as above. Fix.
3. Turn each script into its JSON file. Run the checker (below). Fix every ERROR.
4. Only then: machine play, the silent reader, recordings, publish. That is the code session's job and the only expensive part.

## The file

```
{"id": "la-familia", "title": "La familia", "place": "La casa", "scene": "sala",
 "next": "la-foto",                          the story after this one
 "goal": "...",                              one line, in English, for us
 "stake": {"thing": "plato", "steps": 3},    the thing at stake; the scene must show it (see its sheet)
 "dots": 7,                                  progress dots
 "bien": "si_muy_bien",                      the praise clip
 "focus_words": [...],                       the new words: filed, scheduled, tested
 "back_again": [...],                        earlier words coming back
 "also_heard": [...],                        heard, not tracked
 "names": {"mama": "esta_es_mama", ...},     the free poke: thing touched -> clip that names it
 "palabras": {"mama": "mamá"},               thing key -> word as it is written, when they differ
 "clips": {...}, "beats": [...], "final": [...],
 "leer": [...]}                              the clip ids that make its reading text, in order
```

**Clips**

- `"id": {"who": "narr" | "tu", "text": "..."}`. narr is Karina, tu is the coquí (Victor).
- A narrator line said by someone else adds `"habla": "abuela"` (or luis, carmen, mama, papa, abuelo, hermano, hermana, senor, senora, mujer, hombre, joven).
- Clip ids are shared by every story. The same id must have the same text everywhere. A new line gets a new id.
- An exact line already recorded elsewhere: reuse its id. It costs no recording. The checker finds these.
- A speaking turn: on the coquí's clip, add `"tu_turno": [{"palabra": "gracias", "formas": ["gracias"]}]`. `palabra` is the word exactly as in focus_words. `formas` are the accepted forms (lower case, no accents, no punctuation): the plain form and real variants only, never a near-miss spelling. 1 or 2 targets per line.

**Steps** (in beats and final)

| Step | Does |
| --- | --- |
| `"clip_id"` | Says the line. |
| `{"say": id, "gap": ms}` | Says it, with a set pause after. |
| `{"wait": ms}` | Waits. |
| `{"cam": view, "n": ticks}` | Moves to one of the scene's views. |
| `{"dots": n}` | Lights n progress dots. |
| `{"set": {...}}` | Sets values in the world. |
| `{"act": name, ...}` | Runs one of the scene's acts (its sheet lists them, with an example). |
| `{"if": cond, "then": [...], "else": [...]}` | cond is `"name"`, `"!name"` or `"name=value"`, read from the story's variables, then the world (`lost`, `ok`, `x`, `mem_<key>`...). |
| `{"draw": var, "options": [...], "other": var2}` | A fresh random pick. |
| `{"reparte": [v1, v2...], "options": [...]}` | Deals the options out to several names, none twice. |
| `{"calc": var, "cond": c, "then": value, "else": value}` | Sets a variable. |
| `{"recuerda": key, "valor": v}` | Saved for later stories, read as `mem_<key>`. |
| `{"cost": 1, "en": place}` | One step of the stake is lost here (inside `wrong`). |
| `{"ask": thing, "lead": [...], "line": id, "after": [...], "then": [...]}` | An ask with the big sign. Nothing can go wrong. Also: `resp` (answer bubbles), `said`, `bien`, `quieto`, `loose`. |
| `{"decide": kind, "options": [a, b], ...}` | A decision. See below. |
| `{"elige": kind, "options": [...], "said": {...}, "<option>": [steps]}` | A choice with no wrong answer: each option leads somewhere else. |

**A decision**

```
{"decide": "find" | "say", "options": ["jugo", "agua"],
 "pick": "$d",           fixed right answer; or "as"/"other" name the drawn one and the other one
 "alterna": true,        the other one than last play
 "baraja": true,         answer bubbles change sides
 "lock": true,           touches count only once the line is asked
 "noretry": true,        one guess, then the story shows the answer
 "tests": "$d",          the word this decision tests ("-" for none)
 "do": "coge",           the scene act run on what he touched
 "lead": [...], "line": "toma_$d",
 "said": {...},          what the frog says for each answer
 "bien": clip | false,   this decision's praise, or none
 "wrong": [...], "right": [...]}
```

- "say" shows sí/no answer bubbles instead of things to touch.
- Wrong: the `wrong` steps, one step of the stake lost (unless `wrong` has its own `cost`), then the big sign shows the right one and he does it.
- In any id or argument, `$name` is filled from the story's variables. `$x` is the wrong thing he touched.

## The checker

`historia/tools/revisa_cuento.py` checks a story against its scene and every other story, without running the game. It is fast and costs almost nothing. Run it before any machine play.

```
python3 historia/tools/revisa_cuento.py . historia/cuentos/<id>.json     (run from the repo's root)
```

- **ERROR** (must fix): a missing field, a clip that isn't in the file, a clip id that already means a different line elsewhere, an act the scene doesn't have (list it under Needs), a spot or view that doesn't exist, a speaking turn on a new word.
- **note**: a line already recorded under another id (reuse it), a focus word heard fewer than 3 times, a touched thing the scene doesn't have, the turn count.
- It prints how many new characters will be recorded.

Tested Nov 20 on all 31 built stories: no errors.

## Recording, cost and publishing

- Pushing a change under `historia/cuentos/` starts the audio job (Azure). Push only finished files.
- Azure's free tier is 500,000 characters a month, and it stops there. A story records about 450 to 1,900 new characters. Past the free tier needs a paid tier: tell him the amount first.
- Testing (`historia/tools/juega.py`), the silent reader, and the `?v=` link are the code session's steps. They're listed in 00-start-here, "Before anything with pictures or lines goes to Salim".

## Keep it current

- After a scene changes: rerun `historia/tools/hojas_escena.py` and replace its sheet in `docs/proyecto/kit/`.
- A new kind of step or a new rule from him: add it here, in his words.
