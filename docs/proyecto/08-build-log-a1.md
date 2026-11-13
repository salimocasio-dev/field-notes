# A1 build log (the chat that took over from 07)

Started Nov 13 2026. Newest first. Where this page and 05, 06 or 07 differ, this page wins.

## Live now

- The app: https://salimocasio-dev.github.io/field-notes/historia/app.html?v=20
- Story 1 directly: historia/?v=20 . Story 2: ?cuento=el-bizcocho . Story 3: ?cuento=donde-esta-el-pajaro . ¿Cuál?: historia/cual.html
- Script tags carry ?v=20 in index.html, cual.html and app.html. Raise all three when a script changes.
- The audio job also commits ("Audio: cuento") after a push that touches cuentos/. Pull before pushing again, or the push is refused.

## Nov 13, part 4: the app rebuilt to his UI plan

- See page 09. Only the home map is the game; the rest is a clean modern app with a bottom tab bar (Biblioteca, Palabras, Mapa, Hablar, Yo).

## Nov 13, part 3: the app as a game world (superseded by part 4)

- His reaction to the first shell (dark cards, a tab bar, system font): "What kind of UI is this????". Claude then made every screen a pixel game. He corrected: "I didn't say the whole thing is a game, I said on the home screen is the map to the game as the main part of the course." The SMB3-style map from this version is kept as the home tab.

## Nov 13, part 2: word records, ¿Cuál?

### Word records and the scheduler (historia/palabras.js, global PAL)

- Stored on the phone: localStorage "coqui.palabras.v1": palabras, dias (streak), cuentos (plays per story), ajustes (min a day, todo switch, bienvenida seen), minutos, extra (added words and goals).
- Every word: an ear record and a mouth record. A miss in one never touches the other. The mouth record is not fed yet (it waits for calls).
- Stages: oído (heard), encontrado (found), se queda (holding), bien (good). Internally etapa 1 to 4.
- First meeting in a story: heard; due the next morning (4 am) for ¿Cuál?. A right decision inside its first story moves it to found without moving the schedule.
- A return: right fast stretches the gap x2.5 (min 1 day); right but slower than 2 s keeps the gap; a miss brings it back in 10 minutes, divides the gap by 3, drops a step. Two right in a row moves up a step (1 to 4). Good = right on 3 returns over 14 days or more. Three misses in a row: parked 7 days, flagged, stage drops to found.
- The 2.5 multiplier and the 4 am cut are Claude's choices, not from a report. The 85% difficulty tuning is not built.
- Each finished story writes its words and decisions (with ms to answer). Machine runs with ?fast skip this unless ?rec=1.
- Checked by a node test over a simulated 20 days.

### ¿Cuál? (historia/cual.html, cual.js, cuentos/cual-frente.json)

- One sentence, two pictures stacked, only one fits. A touch before the sentence ends does not count. Waiting replays it every 9 s. Right: stars and "¡Sí! ¡Muy bien!". Wrong: that picture dims, the big frame shows the right one, he touches it, "¡Muy bien!".
- Asks the words due, most overdue first (max 8; ?n=). With none due, every heard word (or all with ?todo=1), without moving the schedule.
- Pairs from El frente states: casa (house / empty yard), puerta and ventana, abuela (at the door / shut door), abre (window open with abuela / shut), cierra (abuela behind the half-shut door / in the open door), hola and adiós (day, door open, frog at the door waving / dusk, door closing, frog going), sí and no (the nodding and shaking bubbles), grande and pequeña (house / birdhouse, same zoom). toca is heard-only.
- All sentences reuse lines recorded for stories 1 to 3.
- The silent reader ran after it first went live (wrong order). It flagged casa, cierra, hola, adiós; all redrawn the same hour. sí and no flagged as colour-only; left, because on the phone the bubbles nod and shake.

## Nov 13, part 1: the coquí's voice, stories 2 and 3

### The coquí's voice, bubbles, captions

- The coquí speaks in es-PR-VictorNeural (V_TU default in .github/workflows/voz.yml). Clips with "who": "tu" are his.
- Story 1 lines: "¡Ay, la lluvia!", "¡Soy yo, abuela! ¡Abre!", "¡Abre la puerta/ventana, abuela!", "¡Bien, gracias!" or soaked "¡Ay, abuela! Estoy mojado.", "¡Coquí!" when touched.
- Frog and abuela in a speech bubble at the speaker; narrator as a caption under the picture. "Abuela dice:" in the caption, her words in her bubble (clips with "habla": "abuela"). Speaker not visible: the caption carries the whole line. The frog's bubble sits beside him. Mouths move while a character talks.
- TXT setting: ?txt=con (default), tras, no.
- Free-touch names are short sentences ("Es la puerta.", "Esta es abuela.").
- Every page is marked do-not-translate (his phone was translating the captions into English).

### Stories 2 and 3

- Built to page 06 plus the coquí's lines and the reviewers' fixes. Story 3 round 3 has all four places in play. A bird given a slice in story 2 starts story 3 on his head and, if it wins all three rounds, flies one slice back.

### Engine additions (juego.js)

| Step | Does |
| --- | --- |
| {"decide": "say", ...} | sí/no answer bubbles; "said" makes the frog say his answer |
| "noretry": true | one guess, then the story shows the answer |
| "lock": true | option touches count only once the line is asked |
| "bien": clip or false | this decision's praise, or none |
| {"cost": 1, "en": place} | where the stake step happens inside "wrong" |
| {"elige": kind, "options", "said", option: [steps]} | a choice with no wrong answer |
| {"draw": var, "options", "other"} | a fresh draw from any number of options; ?var= fixes it |
| {"calc": var, "cond", "then", "else"} | sets a variable |
| {"recuerda": key, "valor": v} | saves for later stories (mem_key); ?mem=key:v for checks |
| ask "resp": ["si","no"] | an ask on an answer bubble |

- Story file fields: next, dots, bien, cam, palabras (log spelling), tipo ("cual").
- LOG entries: word, asked, got, ok, ms.

### Testing

- historia/tools/juega.py <outdir|-> <plan> <cuento> [fast] [extra-query]. WRAP=1 includes words in screenshots. TL=1 times lines.
- historia/tools/cual_check.py <plan> [extra-query] [outdir] plays ¿Cuál?.
- Every path of stories 1 to 3 and the friend-bird path played by machine, no errors. Story 1 clean run with audio: 85 s.

### Reviews done

- Scripts: beginner + Puerto Rican reviewers before building; a second PR check of the built lines of stories 2 and 3.
- Built: silent frame reader on story 1, twice on stories 2 and 3. Real findings fixed. Left: choices only make sense with the Spanish (by design); story 1's second knock is always the other place; abuela's wave can look like a fist.

### Audio

- About 80 clips recorded across the stories, all inside Azure's free tier.

## Next, in the order of page 07

1. Place 1 complete: El balcón, La sala, El patio (stories, scenes, pictures, lines), its Escuchar, reading texts, its call with Danny.
2. The level check. 3. Places 2 to 10. 4. The fort check.
- Also open: the rest of the UI plan (09); the 85% difficulty tuning; the mouth record fed by calls; the plan doc's game tab fixes ("porch lamp", "nothing is built").
