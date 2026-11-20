# A comer: proposed speaking turns (stories 33, 34, 35)

Proposal only. No story file and no code was changed. Rules: docs/hablar/03-para-historias-nuevas.md and 01-decisiones.md. Style: 02-marcas.md. Checked against the story files historia/cuentos/que-quieres.json, buen-provecho.json, cafe-con-azucar.json (as of Nov 17 2026, 00:35), the final script comer.md, the step kinds in historia/juego.js (paso, ask, elige, decide) and the focus_words of the 32, 33 and 34 stories that come before 33, 34 and 35 in curso.js.

## Result

| story | turns | clips |
|---|---|---|
| 33 ¿Qué quieres? | 0 (fewer than 2: none can pass) | none; nearest candidates below |
| 34 Buen provecho | 2 | c34_cq_lleno (signed ask), c34_cq_bp_papa (plain line) |
| 35 Café con azúcar | 2 | c35_cq_mucho (signed ask), c35_cq_huele (plain line) |

Four turns in all. None is inside a decide. None is in an elige (none of the three stories has an elige step: every choice is an ask, a decide or a plain line).

## How I read the rules (one point needs a ruling)

- "Never a word that is new in this story" (03): I read it as the TESTED words. Every target below is in focus_words of an earlier story and in no focus_words of this one. This is how 03 words it ("every turn tests words from EARLIER scenes ... never a word new in this story").
- Only focus_words count as earlier words. "por favor" and "de nada" live only in the palabras map of que-calor, not in its focus_words, so I did not use "por favor" as a target (02 allowed palabras-map words; the brief for this proposal says focus_words only).
- The coquí's lines in these stories are mostly the lines that teach the new words, so three of the four proposed lines also CARRY a new word that is not tested. I only accepted that when the new word has been heard several times earlier in the same play, so the learner can say the line from the story. Counts are given per turn.
- If the ruling is the stricter one (the whole line must be free of this story's new words), only c34_cq_lleno passes: 33 stays at 0, 34 falls to 1, 35 to 0. Say which reading you want; the list below is for the first reading.

## Story 33: ¿Qué quieres? (no turn can pass)

Every coquí line is either the story's new phrase, a name, inside a decide, or too long.

| clip | text | where | what blocks it |
|---|---|---|---|
| c33_q_abuelo | ¿Qué quieres, abuelo? | plain line, step 2 (again step 4) | Its only earlier word is "abuelo". The rest is the story's new phrase "¿qué quieres?", heard for the first time here, with no spoken line before it (abuelo just walks in with an empty roll). With "abuelo" at mouth 0 the model plays first, then "Ahora tú.": a repeat drill, not a reply. Fails "not a drill / not an echo". |
| c33_q_mama | ¿Qué quieres, mamá? | plain line, step 3 (again step 6) | Same, with one earlier hearing of the frame. Target would be "mamá" only. |
| c33_q_luis | ¿Qué quieres, Luis? | plain line, step 5 | The only name is Luis, and names are never targets. No earlier word to test. |
| c33_q_papa, c33_q_carmen | ¿Qué quieres, papá? / ¿Qué quieres, Carmen? | in the lead of decide A and decide B | Inside a decide: never. (Carmen is a name too.) |
| c33_cq_pan_abuela | ¡Me gusta el pan de abuela! | plain line, the ending, only "if pan" | The only one that would otherwise pass: targets pan (para-los-pajaros) and abuela (la-lluvia); "me gusta" was heard 3 times before (steps 1, 2, 3) and the setup line is "La familia come pan." But it has 6 words (limit 5; 02 allowed one 6-word reply in story 5) and is not played at all in the two-miss play (abuela has no roll). |
| yo_coqui | ¡Coquí! | not a story step (said when he touches the frog) | Not a line of the story; a name. |

To get a turn in 33 without changing a line, the planning chat would have to allow one 6-word exception for c33_cq_pan_abuela, with these targets: `[{"palabra":"pan","formas":["pan"]},{"palabra":"abuela","formas":["abuela"]}]`. That is one turn, below the 2 that 03 asks for. I did not put it in the JSON.

## Story 34: Buen provecho (2 turns)

### Turn 1: c34_cq_lleno

- Text: "Yo estoy lleno." (3 words).
- Where: signed ask, the second ask of the opening (script step 4, the second "¿Y tú, Coquí?"). The ask target is di_lleno and this clip is its `said`.
- Line just before: NARR c34_luis_y_tu "Luis dice: ¿Y tú, Coquí?", after c34_luis_quiero "Luis dice: Quiero más arroz, por favor." Luis holds out the spoon with a mound. The thought bubble (piensa34 "lleno") shows the frog's round belly beside his clean plate.
- Targets: `lleno` (formas `lleno`), taught in jugo-de-china (story 32, La nevera).
- Why a reply and not an echo: it answers Luis's question from the picture (belly, clean plate), the opposite of step 3 (heart over a mound). Nothing he has just heard says "lleno".
- Rules:
  - Spread: opening (dot 3) and the ending; steps 5, 6, the turn and both decisions lie between. Passes.
  - 1 to 5 words: 3. Passes.
  - Once per play: the clip is a voces bubble in ask 3 and ask 4 and the said clip and bubble in decide A; the first live turn occurrence is ask 4; decide A never turns. Passes.
  - Elige: none in this story. Not applicable.
  - Never new: "lleno" is not in focus_words of buen-provecho (buen provecho, también, rico, todo). The line text has no new word ("yo", "estoy" are old). Passes.
  - Not inside a decide: it sits in an ask. Passes.
- Clear from the story alone? Yes for a learner who has "lleno" (the turn is live only then): the picture and the question point at it. Without voces and sign the contrast with step 3 does the work.
- Side effect: in a heard-right turn the frog's recording is not played, so the hearings of "lleno" before decide A are 2 (abuelo step 5, Carmen's "llena" step 6) plus his own saying, not 3. "lleno" is an old word (the guion already says the owner is told), so the new-word floor of 3 does not apply to it.

### Turn 2: c34_cq_bp_papa

- Text: "¡Buen provecho, papá!" (3 words).
- Where: plain line (`{"say": ..., "gap": 300}`) in the ending.
- Line just before: NARR c34_papa_hola "Papá dice: ¡Hola, familia!" (abuela has brought him in, he sits, she scrapes the platter onto his plate).
- Targets: `papá` (formas `papa`), taught in la-familia (story 6).
- Why a reply and not an echo: papá greets, the frog wishes him a good meal over the plate in front of him. The nearest "buen provecho" heard is Carmen's or mamá's after the touch, a whole decision earlier, not the line just before.
- Rules:
  - Spread: the ending; the other turn is at dot 3. Passes.
  - 1 to 5 words: 3. Passes.
  - Once per play: used only here. Passes.
  - Elige: not applicable.
  - Never new: the target "papá" is old. The line carries "buen provecho", this story's new phrase, which is not tested: he has heard it at least 5 times before (step 2 twice, Carmen, mamá, once after the touch in B) and the frog says it himself in step 2. Passes on the first reading; fails on the strict one.
  - Not inside a decide: plain line. Passes.
- Clear from the story alone? Fairly: the family has wished each other "¡Buen provecho!" all story and papá is about to eat. A model plays the first time (papá at mouth 0).

Nearest candidates that do not pass:

| clip | text | where | what blocks it |
|---|---|---|---|
| c34_cq_buen | ¡Buen provecho! | signed ask, step 2 | The story's new phrase and nothing else: no earlier word to test. |
| df12 | ¡Y yo también! | signed ask, step 3 (and in decide A) | "también" is new and is heard here for the first time; an ask never plays a model and a turn silences the bubbles, so he could not know the word. Only "yo" is old. It also sits right before turn 1 (steps 3 and 4 would be two turns in a row). |
| cq_gracias_abuela | ¡Gracias, abuela! | only a decoy bubble in the step 2 ask | It is never a plain line, never a `said`, never in an elige: an ask turn runs only on the target's `said` clip. Both words are old and the line would be ideal, but nothing in the step list can carry the turn without a change to the step. |

## Story 35: Café con azúcar (2 turns)

### Turn 1: c35_cq_mucho

- Text: "Sí, mucho, por favor." (4 words).
- Where: signed ask, the second ask of step 6 (brown cup). The ask target is di_mucho and this clip is its `said`.
- Line just before: NARR c35_ab_quieres "Abuela dice: ¿Quieres café, Coquí?", with the thought bubble of a brown cup (piensa35 "marron"). It is the second time this question and picture come, after the pale cup.
- Targets: `sí` (formas `si`), taught in el-bizcocho (story 2). ("por favor" is not in any focus_words, so it is not a target; saying it or not changes nothing.)
- Why a reply and not an echo: it answers abuela's question, and the answer shares no word with the question ("café" is only in the question).
- Rules:
  - Spread: step 6 (dot 5) and the ending; the turn, decision A and decision B lie between. Passes.
  - 1 to 5 words: 4. Passes.
  - Once per play: the clip is a voces bubble in ask 6a, the `said` in ask 6b (the turn) and the said and bubble in decide B; decide B never turns. Passes.
  - Elige: none in this story. Not applicable.
  - Never new: "sí" is not in focus_words of cafe-con-azucar (café, azúcar, un poco, mucho). The line carries "mucho", this story's new word, which is not tested: he has heard it 3 times before (Luis dice, Luis toma, Carmen dice, steps 4 and 5). Passes on the first reading; fails on the strict one.
  - Not inside a decide: it sits in an ask. Passes.
- Clear from the story alone? Yes: a question with an offered cup, and "sí" is enough to be heard right. He has just seen the same question once, with the pale cup.
- Side effect: a heard-right turn removes the frog's own "mucho" from the count before decide B, so "mucho" has 3 hearings, not 4. That is still the floor the other stories use (3).

### Turn 2: c35_cq_huele

- Text: "¡Huele a café!" (3 words).
- Where: plain line (`{"say": ..., "gap": 300}`) in the ending.
- Line just before: NARR c35_ab_toma "Abuela toma café." Abuela sits at the stove with her cup. That line is said only if her cup holds coffee; after a miss in B nothing is spoken before it and the cup is empty.
- Targets: `huele` (formas `huele`), taught in el-pollo-y-el-huevo (story 28).
- Why a reply and not an echo: it is the frog's own remark over abuela's cup, after the story's whole game; the narrator's "Huele a café." was said once at the start (step 1), nowhere near the end.
- Rules:
  - Spread: the ending; the other turn is at dot 5. Passes.
  - 1 to 5 words: 3. Passes.
  - Once per play: used only here. Passes.
  - Elige: not applicable.
  - Never new: "huele" is old and is not in this story's focus_words. The line carries "café", this story's new word, which is not tested: heard 17 times before. Passes on the first reading; fails on the strict one.
  - Not inside a decide: plain line. Passes.
- Clear from the story alone? This is the weakest turn: it is a remark, not an answer, and it leans on the opening line "Huele a café." The model plays the first time (huele at mouth 0). If it is judged too weak, the swap is below.

Nearest candidates (not proposed):

| clip | text | where | what blocks it |
|---|---|---|---|
| c35_cq_poco | Sí, un poco, por favor. | signed ask, first ask of step 6 (pale cup) | Same shape as turn 1 (target sí), but the two asks are neighbours, so only one of them can be a turn. I chose the second: by then he has seen the pattern once. |
| c35_cq_rico | ¡El café está rico! | plain line, straight after ask 6b | Target would be "rico" (buen-provecho, story 34), a good return of a word from the story before. It follows turn 1 with nothing between, so it would be two turns in a row. It is set up by an action (he drinks), not by a spoken line. Use it only INSTEAD of turn 1 (keep c35_cq_mucho unmarked), never beside it. |

Swap if "huele" is too weak: turn 1 = c35_cq_poco (ask 6a), turn 2 = c35_cq_rico (after 6b). That keeps "not two in a row" only by one non-turn ask between them, and both turns then sit inside one short beat; I do not recommend it.

## Points for the planning chat

1. The reading of "never a word new in this story" (above). It decides whether 34 has 2 turns or 1 and 35 has 2 or 0.
2. Story 33 has no passable line. Options that do not change a line: accept 0 turns for 33, or allow the 6-word exception for c33_cq_pan_abuela (it would still be absent in the two-miss play).
3. Engine, for the build: in all the asks used here `line` is empty (the question is a narr step before the ask), so the 9 s repeat has no question to play; the same holds in the existing line-less marked asks (la-mesa, la-cuchara and others). No change is needed, but the repeat is silent here.
4. The beginner reviewer's question for these four turns: the answer for c34_cq_lleno and c35_cq_mucho is yes from the picture and the question; c34_cq_bp_papa is likely; c35_cq_huele is the one to watch.

## Machine-readable copy (same shape as docs/hablar/02-marcas.json)

```json
{
 "que-quieres": {},
 "buen-provecho": {
  "c34_cq_lleno": [
   {
    "palabra": "lleno",
    "formas": [
     "lleno"
    ]
   }
  ],
  "c34_cq_bp_papa": [
   {
    "palabra": "papá",
    "formas": [
     "papa"
    ]
   }
  ]
 },
 "cafe-con-azucar": {
  "c35_cq_mucho": [
   {
    "palabra": "sí",
    "formas": [
     "si"
    ]
   }
  ],
  "c35_cq_huele": [
   {
    "palabra": "huele",
    "formas": [
     "huele"
    ]
   }
  ]
 }
}
```
