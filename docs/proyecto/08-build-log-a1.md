# A1 build log (the chat that took over from 07)

Started Nov 13 2026. Newest first. Where this page and 05, 06 or 07 differ, this page wins.

## Live now

- The app: https://salimocasio-dev.github.io/field-notes/historia/app.html?v=25
- Story 1 directly: historia/?v=25 . Any story: ?cuento=<id> (la-lluvia, el-bizcocho, donde-esta-el-pajaro, el-jugo, que-calor, la-familia, la-foto, quien-eres-tu, las-flores, que-es-esto, hasta-manana). ¿Cuál?: historia/cual.html
- Script tags carry ?v=25 in index.html, cual.html and app.html. Raise all three when a script changes.
- The audio job also commits ("Audio: cuento") after a push that touches cuentos/. Pull before pushing again, or the push is refused.

## Nov 13, part 10: place 2, El parque. Scene 1, El camino

Live at ?v=25. Scripts (final, draft 3): historia/notas/guiones/camino.md. Generator: historia/tools/gen_camino.py.

### What is built

- **The park path** (historia/escenas/camino.js): the park gate, a dirt path with seven stones (nine marks, one for every round of story 12), three small trees with birds in them, a bench, one very big tree. Luis and Carmen; abuela's dog Canelo (W.perro); a grey cat (W.gato). The dog and the cat have their own drawings and ways of going.
- **Story 12, Uno, dos, tres** (parque, perro, camina, corre, espera; uno, dos, tres counted aloud). A "do what Luis calls" game along the path. He answers with moving "doing" pictures (walk, run, stand still). Stake: his place on the path; a wrong move and Luis shakes his head and he walks back a stone, so Carmen gets ahead. Round 2 calls one thing for Carmen and another for him.
- **Story 13, ¿Dónde está el gato?** (gato, árbol, hay, uno, dos, tres, ¿dónde está?). The cat hides in one of three trees; the trees have one, two and three birds, dealt fresh every round. A: "Está en el árbol con tres pájaros." B: two "no" lines. C: he tells them himself. Stake: three fish biscuits, one a round: a heart if the cat gets it, a paw mark if Canelo does.
- **Story 14, Rápido, despacio** (rápido, despacio). He walks the dog back to the gate with three guineos on his head for abuela. A: he sees what the dog does and says "¡Despacio!" or "¡Rápido!". B: Luis calls the pace. C: the dog is behind a bush and he only hears what it does. Stake: the guineos; the leash jerks, one falls, Canelo eats it.
- **¿Cuál?**: 13 pairs in cuentos/cual-camino.json. A pair's picture may now name another scene (the park against abuela's yard).

### New in the engine

| Piece | What it does |
| --- | --- |
| three answer bubbles | `resp` or a decision's `options` may hold three; they stand in a row, shuffled (`baraja`) |
| `"quieto"` | the right signal without the hop, where the right move is to stand still |
| end buttons | home, again and next now sit below the picture, so the last picture is not covered (story, ¿Cuál? and level-check pages) |
| `spec.esc` in a pair | that picture is drawn by another scene |

### Reviews

- Scripts: three drafts. Round 1 (beginner): the picture fought the rule in story 12 (running always looked right), "espera" was drawn as sitting (he knows that as "se sienta"), rounds repeated, forms used before they were taught, rápido / despacio pictures untrue. Spanish: "El gato no está…" (a bare "No está" is heard as "No. Está…"), the frog must answer where the cat is, not how many birds there are. Last gate: answers could be won by echo or by order; all closed.
- Wordless frames, two fresh readers. Fixed after the first: the dog was hidden at the start; the walk and wait cards looked alike; the opening went back to the start twice; the snail and the fish biscuits were unreadable; the bush of story 14 came from nowhere. Fixed after the second: frog, dog and Carmen overlapped (Canelo now stands a little ahead on the path, Carmen a little below it); the last walk back to the gate is gone (the path has a stone for every round); the wait card has a clear raised hand and the walk card footprints and an arrow; the group at the gate in story 14 was cut by the edge; speed lines are bolder; the dog's tail shows at the bush. Left as it is: speaking bubbles look alike (he picks by ear); the cat shows only as a tail or a face (that is the game); answer cards sometimes cover Luis.
- A slip to avoid: frames were once captured into a folder that already held old frames, and the reader read a mix. Always capture into a new folder.

### Testing

- Every story: all-right, all-wrong, mixed, and draws forced both ways. All 58 picture pairs. The app check.

### Audio

- 117 new lines, about 3,500 characters. Session total so far about 15,700 of 500,000.

## Nov 13, part 9: the level check

Live at ?v=24: historia/nivel.html (Yo tab, "Level check"; and the welcome's "I understand some Spanish"). Code: historia/nivel.js.

- The plan's rules: touch only; a sentence and four pictures; items run easy to hard; a right answer moves up, a miss moves down; it stops where he starts to miss. Nothing says right or wrong while it runs.
- 20 items, in story order, built from the ¿Cuál? pictures and their recorded sentences (no new audio). Four pictures: the one that fits, usually its pair's other picture, and two from other pairs. Each picture is a square cut of its pair's picture.
- It stops after three misses in a row, after five changes of direction, when he is right on the two top items, or after 16 items.
- Result: every story up to the highest one where he was right on its items and on three in four of everything asked up to there. Those stories count as done (the map starts him after them; he can still play them). Their words start at "se queda", are due the next morning for a cold check, and are open for speaking at once (`PAL.presume`).
- It covers place 1 only, because only place 1 is built. Each new place adds its items to the list NV in nivel.js.
- Checked by machine: all right (11 stories presumed, stops after 11 items), all wrong (stops after 3, nothing presumed), right up to story 6 (6 presumed, starts at La foto). `?todo=1` shows all 20 items in order.
- Known limit, told to Salim: in some items two of the four pictures are easy to rule out, so those items are closer to a choice of two.

## Nov 13, part 8: Escuchar for La casa, first set

Live at ?v=24. Scripts (final, draft 3): historia/notas/guiones/escuchar-casa.md. Generator: historia/tools/gen_escuchar.py (run it, never edit the JSON by hand).

### What Escuchar is, as built

It lives in the Library tab, under "Listen · La casa". Nothing in it is scored; it only adds minutes listened and a "Heard N×" count (PAL.oido).

| Part | What it is | Opens |
| --- | --- | --- |
| Otra vez | each of the eleven map stories told straight through, nothing to touch (`?oir=1`: asks and decisions answer themselves, no praise lines, no stars) | once that story has been played on the map |
| Cuentos con dibujos | six new picture stories in the four scenes already drawn; he only watches and hears (`tipo:"escucha"`) | when all eleven map stories are done (or "Open every place" in Yo) |
| Haz esto | four do-this routines, one per scene (`tipo:"haz"`) | the same |

- Picture stories: Toc, toc (frente); Agua para el pájaro (balcón); El bizcocho del bebé and La foto de la familia (sala); La bola and Buenas noches (patio). Ids start with d-.
- Routines: Abre y cierra (frente); En el balcón; La familia (sala); En el patio. Ids start with h-.
- Size, measured with sound: the six picture stories run 55 to 105 seconds each (about 7 minutes); the routines about 1 to 2 minutes each; the eleven stories told straight through about 15 minutes. About 30 minutes of listening in all. **The plan sizes Escuchar at about 4 hours a place. This first set is far short of that**; more sets follow the same pattern (write, two fresh reviews, build, wordless read, record).

### How a routine works (his rules applied)

- Not all "toca": lines are also "¿Dónde está…?", abre, cierra, "El agua es para abuela", and each routine ends with a line in two parts.
- Right: the thing happens; no praise after each; one "¡Muy bien!" at the end.
- Wrong: nothing is lost. "No. Esa es la ventana." then the big sign.
- Where two touches are fair, both count (`vale`). A two-part line can be done in either order. If he waits, the line repeats, and after the second repeat the sign shows.

### Engine pieces new here (juego.js)

| Piece | What it does |
| --- | --- |
| `?oir=1` | straight-through telling |
| `"libre":true` on a decision | no cost; wrong says `hz_no_<thing>`; then the sign |
| `"vale":[...]` | other touches that also count as right |
| `"mudo":true` | a second part with no new line (the line still repeats if he waits) |
| `"alias":{"abuela":"silla_grande"}` | a touch on one thing stands for another (abuela sitting on the big chair) |
| `S.tipo` | "escucha" or "haz": not written into the word records |

New scene actions: patio (bolaarbol, avesale, avepica2, pelota3, seva, cierra, noche, aveduerme, luzsale, canta, abreporton, pon, deja, flores, apunta), sala (llora, ninos, ponecamara, retrato: the family photo shown big over the room).

### Words changed by the Puerto Rican reviewer

- A firefly is "un cucubano". "Entra a la casa" (not "en"). "Ahora está lloviendo." "¡Vamos para adentro!" "Ven acá."

### Reviews and tests

- Scripts: three drafts; beginner and Spanish reviewers, then a last gate. Main changes: routines were 21 bare "toca X" out of 33 (rewritten); two lines had two fair answers (both now count); two-part lines accept either order; story 4 got a turn (abuelo puts the camera down and joins the photo).
- Wordless frames, fresh reader: fixed after it: two weak endings (story 2 and 6 now end on a heart; in story 3 the frog is seen eating), the third photo looked like the first (now papá), the family photo was small and cut the frog off (now big, with him in it), the ball fell too fast to see, the frog's wide eyes were too big, the loop mark stayed in the sky.
- Machine: every picture story end to end; every routine all-right, all-wrong and mixed; all eleven stories in the straight-through mode; the app check; the Library screen.
- Found by testing: the frog stood in front of the small chair (moved aside); the baby on mamá's lap took her touches (the baby stays on its blanket in the routine); the test tool treated a new question with the same things as the old one (fixed in juega.py).

### Audio

- 165 new lines, about 3,900 characters. Session total so far about 12,200 of 500,000.

## Nov 13, part 7: El patio (scene 4 of La casa). All eleven stories of place 1 are built.

Live at ?v=23. Scripts (final, draft 4): historia/notas/guiones/patio.md. The generator that writes the three story files and the pairs is kept in historia/tools/gen_patio.py (run it, never edit the JSON by hand).

### What is built

- **The yard** (historia/escenas/patio.js): the back of the house with its door, a fence with the garden gate (el portón), a flamboyán with the bird's nest, two flower beds with five holes each, a sun that can sink to the fence, dusk, night, fireflies. Luis and Carmen; the family at the back door.
- **Story 9, Las flores** (niño, niña, juega, flor, sol, aquí, allá). He plants abuela's flowers. Stake: the daylight; a wrong move and the sun sinks a step, and what he planted wrong stays a shut bud. Round 1: "Una flor aquí / allá" (the speaker stands behind one bed). Round 2: abuela says "para el niño / la niña". Round 3: "¡Aquí no! ¡Allá!" in four orders. The beds as he left them are remembered and show in stories 10 and 11.
- **Story 10, ¿Qué es esto?** (¿qué es esto?, amigo, mira, ven). Luis's sack, the frog's basket, the bird that snatches. A: Carmen says ven or mira and he picks what the frog does (two "doing bubbles": hop, or eyes wide). B: he answers the question by ear. C: he asks it himself.
- **Story 11, Hasta mañana** (vamos, hasta mañana). Dusk, then night. Stake: three fireflies, each with someone. A: reply to Carmen's "Adiós". B: thank abuelo for the cake. C: Luis says "¡Ven, Coquí!" or "¡Vamos al portón!". He leaves by the gate; in every ending he sings and the fireflies answer.
- **¿Cuál?**: 12 pairs in cuentos/cual-patio.json.

### Two changes to the plan's words (told to Salim)

- "allí" is taught as "allá" (Puerto Rican reviewer: that is what is said across a yard, and it is easier to tell from "aquí" by ear).
- The garden gate is "el portón"; "puerta" stays the door of the house.

### Engine and scene pieces new here

| Piece | What it does |
| --- | --- |
| doing bubbles | a Say decision with picture answers (`options:["ir","ver"]`, no `voces`); the scene draws them in `respIcon` |
| an ask with no line | `ask` with `resp` + `voces` and `line:null`: only the bubbles speak (the frog picks a question) |
| `{"cost":1,"en":"carmen"}` | the stake act gets which thing is lost (which firefly) |
| `vmapa` | the helper once called `mapa` in juego.js; the old name clashed with the app page and stopped the app from starting (caught by the app check before publishing) |
| `KIT.FAM` | the family's look, shared by La sala and El patio |

### Reviews

- Scripts: four drafts. Round 1 (beginner, Spanish): the gate word, bird must not talk, aquí/allí unfair as taught, ven/mira unfair, story 11 staked neither new word. Round 2: vamos taught with a ven picture, asking never taught, wrong answers in story 11 changed only a counter. Last gate: firefly on the gate gave the answer away, the "no" line never modelled. All fixed.
- Wordless frames, fresh reader: fixed after it: the glass (now juice and a straw), the crate looked like a hat on the frog, the hop card read as a face, the family overlapped, the lights card was too small, pairs juega / amigo / aquí / allá differed in more than one thing.

### Testing

- Every story: all-right, all-wrong and mixed paths, and every draw forced both ways, by machine. All 45 picture pairs. The app check.

### Audio

- 116 new lines, about 2,600 characters, Azure free tier. Session total so far about 8,300 of 500,000.

## Nov 13, part 6: La sala (scene 3 of La casa)

Live at ?v=22. Scripts (final, draft 3): historia/notas/guiones/sala.md.

### What is built

- **The room** (historia/escenas/sala.js): wall with three picture frames, door to the porch, window, sofa, abuelo's armchair, lamp, low table, the baby's blanket. The family are people like abuela: mamá, papá, abuelo, el hermano (Luis), la hermana (Carmen), el bebé. They live in W.gente ({x,y,pose,sent,bub,dir,vis,...}) and are drawn back to front.
- **Story 6, La familia** (mamá, papá, abuelo, bebé, familia). Stake: his own three slices of cake, shown in the corner; a wrong delivery and the wrong person takes a bite of one. Three rounds with three sentence shapes: "para X", "X quiere", "no es para X, es para Y". Who is named is dealt fresh, nobody twice.
- **Story 7, La foto** (hermano, hermana, él, ella). Stake: the three frames on the wall; a right photo hangs straight with the frog in it, a wrong one hangs crooked. Round 3 is a sí/no answer to "¿Es él?" / "¿Es ella?" with the camera's blurred window. The wall he made is remembered and hangs in story 8.
- **Story 8, ¿Quién eres tú?** (yo, tú, soy, eres, me llamo). Stake: abuelo's coffee (he has lost his glasses and bumps into things). Answers are speaking bubbles. Opens with one English card, his rule for words that cannot be drawn: "Yo soy: I am. Tú eres: you are. Me llamo: my name is."
- **¿Cuál?**: 11 pairs in cuentos/cual-sala.json (mamá, papá, abuelo, bebé, familia, hermano, hermana, él, ella, yo, tú). The pass now reads every file listed in CURSO.cual and loads each scene as needed.

### Engine and kit additions

| Piece | What it does |
| --- | --- |
| `{"reparte":[names],"options":[...]}` | deals the options out to several variables, none twice; `?name=value` fixes one |
| `voces` / `said` maps with variables | keys and values are filled in from the story's variables |
| `W.apodo` | a scene can give a thing another poke line for a while |
| `S.nota` | an English card before the story starts (the one allowed English line) |
| `S.leer` | the lines the Library shows for reading |
| dynamic scenes | a story names its scene; escenas/<id>.js loads when needed |
| `KIT.mkPersona`, `KIT.mkBebe`, `KIT.FAM` | one drawing for every person who is not abuela; the family's look is shared by all places |
| right signal | for a spoken answer the stars go on the frog, not where the bubble was |

### Reviews

- Scripts: three drafts. Fresh reviewers each round: a beginner against the requirements, a Puerto Rican Spanish reader, then a last gate. Main changes they forced: three different sentence shapes in story 6; the wall of photos as the stake in story 7; story 8 rebuilt around speaking bubbles and one English card.
- Wordless frames (?txt=no), fresh reader: fixed after it: cake slices read as jars (now wedges; a bitten one is half gone); the sleeping Z was too small; children stood on abuela's feet; an answer bubble covered abuelo; in the photo story the camera window went sharp before the bad photo (now after); the refilled cup in the corner read as a win (the corner now keeps the true count); the yo/tú pictures (both hands on the chest; the arm points down at the frog); the abuelo pair now has abuela as the other picture.
- Left as it is, on purpose: the two speaking bubbles look alike (he must pick by ear); stars after a corrected answer (the model replays the right side).

### Testing

- Every story: all-right, all-wrong and mixed paths by machine, with sound, no errors. All 33 picture pairs.
- Clean run at real speed with instant touches: La familia 1 min 55 s, La foto 1 min 05 s, ¿Quién eres tú? 2 min. Longest stretch with no voice: 4.5 s.

### Audio

- 135 new lines, about 3,650 characters, Azure free tier. Session total so far about 5,700 of 500,000.

## Nov 13, part 5: El balcón (scene 2 of La casa), by the session that took over the build

### What is built

- Scene El balcón (historia/escenas/balcon.js): abuela's porch. Wall, window, door, abuela's big chair, a round table, a small yellow chair. States: door, shutters, glasses and jugs, abuela standing, walking or sitting, a paper fan, sweat, a thermometer.
- Story 4, El jugo (cuentos/el-jugo.json). New words: silla, se sienta, vaso, jugo, agua, toma. Stake: three drinks. Each round abuela sets out two glasses, one his and one hers, and says which is his. Wrong: she takes hers back and the bird drinks his. Rounds: jugo or agua; the glass on the chair or on the table; the big glass or the small one. Two scores in the top corners. The frog loses a drop of sweat with every glass.
- Story 5, ¡Qué calor! (cuentos/que-calor.json). New words: quiero, por favor, gracias, de nada, ¿cómo estás?, bien. Stake: the heat (a thermometer with five marks, starts on the third; a drink for abuela brings it down, a wrong move sends it up). Decisions: two with the speaking bubbles (after "Gracias." and after "Toma."), in an order drawn fresh, then "Quiero jugo, por favor. No quiero agua." with both drinks named and the order drawn fresh. A free pick of juice or water for himself; it is saved as mem_bebida for La sala.
- ¿Cuál? pairs for the scene (cuentos/cual-balcon.json): silla, vaso, jugo, agua, se sienta, toma, quiero, gracias, ¿cómo estás?, bien. por favor and de nada have no pair yet (they are tested by the speaking bubbles in story 5 and counted as heard).
- The scripts with every reviewer's changes: historia/notas/guiones/balcon.md.

### New in the engine (juego.js)

| Thing | Does |
| --- | --- |
| A story names its scene | index.html no longer lists scene files. arranca() loads escenas/<scene>.js when the story needs it. kit.js is loaded by all three pages. |
| Speaking bubbles | For answers that cannot be drawn (gracias, de nada, por favor). {"decide":"say","options":[a,b],"voces":{option: clip},"said":{...},"baraja":true}. Each bubble says its line aloud in the frog's voice, in turn, with no words on screen. The bubbles are dead until both have spoken once. Waiting replays abuela's line and both bubbles, free. Touching the frog replays them too. "baraja" draws the sides fresh. After a wrong pick the sign shows the right bubble, it speaks again, and the frog says the right line. |
| ask with "resp" + "voces" | The same bubbles under the big sign. This is how a new kind of bubble is taught before it can cost. |
| Picture bubbles | Any two answers, not only sí and no: the scene's respIcon(g,k,x,y,w,h) draws what is in each. |
| Story.scene() | The scene's own state as text (the scene's estado(W)), for juega.py. |
| "leer" in a story file | The story's own reading order (a list of clip ids). Biblioteca uses it when present. |

### The scene kit (historia/escenas/kit.js, global KIT)

- KIT.escena({id, CAM, lugar, cosas, fresh, draw, hud, poke, acts, stake, talkAt, respIcon, estado}) registers a scene. cosas = the things that can be touched, front to back ({id, box or (W)=>box, si:(W)=>shown, hand, m:slack}). lugar = where the frog stands at each thing. It supplies box, hit, handAt and the actions ir, burbuja, calla, pose, fin.
- KIT.mkAve / drawAve / aveVa: the bird (v.dip tips it to drink). KIT.mkAbuelaS(pose, open): abuela sitting (idle, fan0, fan1, vaso, bebe, zzz).
- El frente was written before the kit and is unchanged.

### ¿Cuál? and the app

- curso.js lists the pair files (CURSO.cual). cual.js cualCarga() reads them all and loads each scene; every pair is drawn by its own scene. app.html uses the same.
- CURSO.lugares[0].cuentos now has five stories; they show on the map sheet, in Today, Biblioteca and Palabras by themselves.

### Reviews

- Scripts: four rounds of fresh reviewers (beginner against his words; Puerto Rican Spanish; two more on the rewrites). Real findings fixed: the stake made no sense with the sound off (he drank even when wrong); too many juice-or-water asks; agua asked after one hearing; nothing new was staked in story 5; the speaking bubbles were first met at a decision that costs; picture pairs that leaked their answer; "Esa es el agua" changed to "Eso es agua"; "entra a la casa".
- Left, and why: reviewers asked to stop naming things on a free poke during a round. Not done: poking is free and names things (his rule).

### Testing

- Every path of both stories by machine (all right, all wrong, both orders, both free picks), the 22 pairs, the three old stories again, and the app. No errors.

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
