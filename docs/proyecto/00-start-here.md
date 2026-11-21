# Coquí: start here

**Nov 19 2026: the app is moving to Flutter.** A session doing that work starts from 14-flutter-handoff.md, then 11-flutter-plan, 12-flutter-contracts, 13-flutter-orders and 11-pixel-engine. The JavaScript site described below stays live and frozen (bug fixes only) until the cutover in page 13, order 42.

## The Flutter move: state at the end of the first session (Nov 19)

Every order's result, with its numbers and what was decided, is under its heading in 13-flutter-orders. The decisions taken while it ran are in 11-flutter-plan, "Decisions made here", the rows marked Nov 19. What follows is the short state.

- **How the work runs (his words, Nov 19):** the orchestrator only plans, decides and checks. Mechanical work goes to Sonnet at extra-high effort; work with decisions that only show up once it has started, and every set design, to Opus at high effort. A follow-up to a builder with a long history goes to a fresh builder with a short brief (it costs less).
- **Done and on main:** orders 01 to 07, 10 to 25, with 02b, 12b, 17b, 19b, the shared look's rounds 2 and 3, and integration 1. The code is under `coqui/`; CI runs `coqui/tool/test_all.sh` on every push.
- **Order 26 (the shell) and Gate A's preparation are done too.** Build 3 is live at https://salimocasio-dev.github.io/field-notes/app/ : every tab, the map, El frente, stories 1 to 3; stories 4 on say "This story is not in the new app yet." (their scenes are not converted). **Gate A is passed (Nov 20): "looks good to me."** The scenes lane goes on with order 30a (balcon). Order 30 (El balcón) is done: stories 4 and 5 play (build 4). He then said Biblioteca and the flash cards are "filler and fluff" and asked for review that works like Duolingo's games, each word in a different context: order 27 in page 13, designed in page 15, built and live as build 5. Order 31 (La sala) is done too: stories 6 to 8 play (build 6). Order 32 (El patio) is done (Nov 21): stories 9 to 11 play (build 7), so all of La casa plays in the new app, and the link for the whole place went to him. Order 33 (El camino, the first scene of El parque) is done too: stories 12 to 14 play (build 8). Order 34 (El campo) is in step a: round 1 was read by two fresh readers; round 2 (the orchestrator's five decisions: the water's edge, the tree's shadow, Canelo's patch of earth, a ball in the air, the yellow ball) is half done on `orden/34a` (one commit, plus uncommitted work in the worktree `/home/user/wt/o34a`: do not discard it). **It stopped on Nov 21 when Opus reached its weekly limit (resets Nov 26, 8:00 UTC).** Set design and ports are Opus work by Salim's rule, so the scenes lane waits for that or for his word. To go on: message the same designer agent to continue round 2, then two fresh readers on `scratchpad/o34a-r2/`, then the port as orders 32b and 33b. The content lane has added step-b orders for two new places (50 to 53 El colmado, 54 to 57 La calle) in page 13; they come after 39. Still owed by him: what a real reader in Biblioteca should hold; the phone test results. What the readers saw, what was fixed and what was left is under "Gate A" in page 13.
- **Live:** the phone test page, https://salimocasio-dev.github.io/field-notes/prueba/?v=1 (order 00). The new app, https://salimocasio-dev.github.io/field-notes/app/ (build 8; Yo shows the number). To publish a new build: raise `coqui/BUILD` on main.
- **Waiting on him:**
    - The phone test results: his Android in Chrome and installed; one tester's iPhone in Safari and from the home screen. They set the iPhone audio session type and whether speaking turns and calls run on iPhone web. Order 18 was started on the desktop result (the plugin leaves about 215 ms between lines, Web Audio about 6 ms, the limit is 120 ms); a guess that his phones agree.
    - Gate A, when the link is sent: the map, El frente and stories 1 to 3. His to judge there: the look of the set with the sprites on it; a change of zoom cuts where it used to glide; stories 1 to 3 run about a second quicker in places (fewer hops, one camera slide gone); a sprite between pixels is no longer blurred; word-card pictures are a little smaller, at a whole-number scale; scenes not yet converted show their old pictures; the map's bake and frame times and El frente's bake time on his phone (`?perf=1`).
    - Told him, no answer needed: in US Eastern time the streak reads 0 in the evening and an evening play is filed under the next day (today's app does it; the port copies it unless he says fix).
    - The four research reports he added to his Drive on Nov 19 (speech, retention, listening-first review; two files are the same report) change nothing in the port. What they suggest is course design, his to pick, after the move. A reader's notes on them were made in the session's scratch folder and are not in the repo (the repo is public; the notes quote his reports).
- **Where the plan was wrong and is corrected:** "a view never zooms". The old close views are exactly 2×; only one view was a fraction. Views are zoom 1 or 2 (page 12 section 5). The Pages source was not changed (not reachable from the build machine): CI commits the built app to `app/` on main when `coqui/BUILD` changes.
- **Not verified until the app is on the test site or on a phone:** the real ElevenLabs library load and a real call (the library's address is blocked from the build machine; the check is in page 13, order 19); everything about sound, the microphone and haptics on a real phone; the bake times (the build machine was heavily loaded).
- **Open after Gate A (small orders):** the answer cards cover abuela's body when she stands in the doorway (card placement, coqui_pixel); Hablar says "later" until the app restarts after one failed load of the call library; `check_app.mjs` still accepts placeholder tab names; the hint hand's size against the old one is unchecked.
- **A leftover:** the branch `prueba-ci/falla` on GitHub (one deliberately bad file, used to prove CI fails) could not be deleted from the build machine. The branches `int/1`, `orden/*` and `lane/*` are merged and can go.
- **The build machine:** a cloud environment named "field-notes" allows `salimocasio-dev.github.io` and installs Flutter 3.50.0 at the start of a session (unproven until a fresh session starts on it).

## The content lane: state on Nov 20 (the session finishing A1's content)

Since Nov 20 two sessions run side by side. The Flutter session runs the move (above). This one, on branch `ccr-cb95dbe2-hupsof`, owns content: scripts, story files, reviews, recordings, and the sets of NEW scenes; it adds new scene orders to page 13 for the Flutter session's scenes lane and touches no lane that session works in. How a story is written is page 16 (the story kit), with the sheets in `docs/proyecto/kit/`.

- **A comer** (place 3, scene 4): **published, Nov 20, v=40**: https://salimocasio-dev.github.io/field-notes/historia/app.html?v=40 . Stories 33 to 35 (que-quieres, buen-provecho, cafe-con-azucar), their twelve review pairs, three books, four level-check items; 140 clips recorded (3,938 characters). Every machine test passed on the merged code before the push (the plays over every draw and plan, the pairs right and wrong, the level check to 35 stories, reading 113 of 113, the app page, the review session checks) and each story plays to its end on the live site. Seven fresh readers saw the wordless frames of round 5: the three stories are followed; the pairs rico, azúcar and un poco and the sugar bowl were redrawn and read again. Not solved: abuela leaning over the table looks as if she stood in it (as in La mesa); the three stories run 266, 305 and 288 s at real speed on a clean run, three times the kit's 77 to 85 s. They are the first stories with speaking turns. `historia/datos/` is not exported again: the new app takes A comer by the steps on page 13 ("From the content lane").
- **La cocina's Escuchar set** (historia/notas/guiones/escuchar-cocina.md, generator historia/tools/gen_escuchar_cocina.py): the three routines (h-mesa, h-estufa, h-nevera) are live with v=40. The four picture stories do not carry their story in pictures with the old kitchen scenes' acts; they wait for the new app's kitchen scenes (their acts are in the script's Needs and on page 13). A comer's own routine and a fifth picture story are not written. La cocina's call with Danny waits until Salim says La casa's call works.
- **Place 4, El colmado** (stories 36 to 47; scenes mostrador, estantes, frutas, caja; scripts in historia/notas/guiones/ under those names):
    - Scripts: written, each reviewed by a fresh beginner reader and a fresh Puerto Rican Spanish reader (the Spanish review runs on a fresh agent of the orchestrator's own model: the orchestrator writes the scripts, and a self-review does not count), then rewritten. What was found and what was left is at the end of each script.
    - Story files: generated by gen_mostrador.py, gen_estantes.py, gen_frutas.py, gen_caja.py; the checker finds no error; every path was walked by a reader of the step types. 13,133 new characters to record. Not in git: a push under historia/cuentos/ records them, and they are not final until they have played in the new app.
    - Sets and sheets: done. One room inside (`pixel/colmado-dentro.js`, framed three ways by mostrador-set.html, estantes-set.html, caja-set.html) and the street front with the stand (`pixel/colmado-fuera.js`: frutas-set.html, and mostrador-set.html?donde=calle). Three rounds with fresh readers on the sets. Each scene has its sheet, a sheet maker whose checks all pass, and a preview with stand-in people at each story's moments; the orchestrator looked at every preview. Bake of the inside states is 160 to 270 ms, over the 150 ms limit.
    - Handed over: orders 50 to 53 on page 13 (the Dart port, the acts from each script's Needs, the new sprites). Machine play, the silent reader, the recordings, the pairs, Escuchar set, books and level items follow the port, scene by scene.
- **Place 5, La calle** (stories 48 to 59; scenes esquina, parada, tiendas, cruce; scripts in historia/notas/guiones/ under those names):
    - Scripts: written, each reviewed by a fresh beginner reader and a fresh Puerto Rican Spanish reader, then rewritten (draft 2). What was found and what was left is at the end of each script. Salim's call on Nov 21 ("pick whatever is most used"): the everyday Puerto Rican word wins over the plan's, now a rule on page 16: después, al frente de, se monta, se baja, se va, ¿para dónde vas? are in the scripts and on page 02; stories 50, 51, 52 and 59 have new titles and ids (ahora-y-despues, para-donde-vas, se-monta-y-se-baja, al-frente-y-detras). Kept: mamá and papá (the course's words since La casa; children say mami and papi), globos (neutral; "bombas" also means bombs).
    - Story files: generated by gen_esquina.py, gen_parada.py, gen_tiendas.py, gen_cruce.py (run in that order, after El colmado's four); the checker finds no error in any of the twelve; every path walked. With El colmado's twelve, 31,925 new characters to record. Not in git, as El colmado's.
    - Sets: drawn (`pixel/calle-base.js` shared; esquina-set.html, parada-set.html, tiendas-set.html, cruce-set.html). One fresh reader saw each with no words; what they could not read is fixed (shop signs, the post box, the guagua's doors and its picture of where it goes, the lamp at night, the traffic light's lamps, the hole in the road, the closed street). El cruce is drawn square to the picture (its streets turned 45 degrees), so that left is left. Cars and guaguas are drawn by the kit as stand-ins for the readers' pictures; in the game they are sprites.
    - Sheets and previews: done; each scene's sheet maker passes all its checks, and the orchestrator looked at every preview moment with people in it. It took three passes: the first positions put people on top of each other (a sprite is 24 to 32 px wide, so two on one row need 1.6 world units between them).
    - Handed over: orders 54 to 57 on page 13. As for El colmado, machine play, the silent reader, the recordings, pairs, Escuchar set, books and level items follow the port.
- **Place 6, La plaza** (stories 60 to 71; scenes `plaza`, `reloj`, `quiosco`, `calendario`): done as far as the content lane goes without the app (Nov 21).
    - Scripts: `historia/notas/guiones/plaza.md`, `reloj.md`, `quiosco.md`, `calendario.md`: each reviewed by a fresh beginner reader and a fresh Puerto Rican Spanish reader, then rewritten; what was found and what was left is at the end of each. One wording changed by the "most used" rule: the question about work is "¿en qué trabajas?" (a bare "¿qué haces?" is "what are you doing?"); pages 02 and 16 say so.
    - Story files: gen_plaza.py, gen_reloj.py, gen_quiosco.py, gen_calendario.py (run in that order after La calle's four). The checker finds no error in any of the twelve; every path walked by each builder. With places 4 and 5 that is 59,868 characters to record. Not in git.
    - Sets: `pixel/plaza-base.js` (the square is laid out square to the picture, as El cruce) and four sets; one fresh reader each, with no words; what was not read is fixed. Sheets and previews: every make exits 0.
    - Handed over: orders 58 to 61 on page 13. Machine play, the silent reader, the recordings, pairs, Escuchar set, books and level items follow the port.
- **Place 7, La playa** (stories 72 to 83; scenes `orilla`, `sombrilla`, `ropa`, `cielo`): scripts written, reviewed by the same two kinds of fresh reader, and rewritten (draft 2) on Nov 21: `historia/notas/guiones/orilla.md`, `sombrilla.md`, `ropa.md`, `cielo.md`. Four words changed by the "most used" rule (pages 02 and 16): bote (the plan's barco is a ship), tiene puesto (lleva is "carries"), está lloviendo, ¿cómo está el tiempo? Story files: `historia/tools/gen_orilla.py`, `gen_sombrilla.py`, `gen_ropa.py`, `gen_cielo.py`; the checker passes all 12 with 0 errors (the files stay off git until they are recorded). Sets on the engine (`pixel/playa-base.js`, `orilla-set.html`, `sombrilla-set.html`, `ropa-set.html`, `cielo-set.html`), read by fresh readers; sheets and previews done, every make exits 0. Handed to the Flutter session as orders 62 to 65 on page 13. Steps e to h wait for those ports. Characters still to record for places 4 to 7: 73,623 (inside Azure's free 500,000 a month; nothing spent).
- **Place 8, La fonda** (stories 84 to 95; scenes `entrada`, `pedido`, `comida`, `cuenta`): scripts written, reviewed and rewritten (draft 2) on Nov 21. Words changed by the "most used" rule (pages 02 and 16): me da ..., por favor (the plan's quisiera), mantecado (helado), estoy lleno (satisfecho), el pique, un café negro; one word kept against the rule, and why: efectivo (the island says cash, which he has; a guest answers "Cash" and the mesera says "En efectivo"). Story files: `historia/tools/gen_entrada.py`, `gen_pedido.py`, `gen_comida.py`, `gen_cuenta.py`; the checker passes all 12 with 0 errors (the files stay off git until they are recorded). Sets on the engine (`pixel/fonda-base.js` and the four `<id>-set.html`: the first indoor sets), read by fresh readers; sheets and previews done, every make exits 0. Handed to the Flutter session as orders 66 to 69 on page 13. Steps e to h wait for those ports. Characters still to record for places 4 to 8: 100,693 (inside Azure's free 500,000 a month; nothing spent).
- **Place 9, La casa, un día entero** (stories 96 to 107; scenes `cuarto`, `bano`, `sala_dia`, `noche`): scripts written, reviewed and rewritten (draft 2) on Nov 21: `historia/notas/guiones/cuarto.md`, `bano.md`, `sala_dia.md`, `noche.md`. Words changed: la peinilla (the plan's peine), se cepilla los dientes, ve televisión, estudia en la computadora; gafas are sunglasses on the island (espejuelos are glasses to see with), so no story of this place uses gafas for glasses. Story files built by four generators (`historia/tools/gen_cuarto.py`, `gen_bano.py`, `gen_sala_dia.py`, `gen_noche.py`), checker clean; sets on `pixel/casa-base.js`, read by fresh readers and fixed; sheets and previews done, every make exits 0; handed to the Flutter lane as orders 70 to 73 on page 13. With places 4 to 8: 111,587 characters to record. Steps e to h wait for the Dart ports.
- **Place 10, El fuerte** (stories 108 to 119; scenes `subida`, `musica`, `regalos`, `muralla`): scripts written, reviewed by six fresh reviewers and rewritten (draft 2) on Nov 21: `historia/notas/guiones/subida.md`, `musica.md`, `regalos.md`, `muralla.md`. Words changed by the "most used" rule (pages 02 and 16): se ríe (the plan's ríe), ¿de quién es la fiesta?, voy a tomar algo, ¡feliz cumpleaños! beside ¡felicidades!, velitas on a cake; at a party's end people say nos vemos and cuídate, so hasta pronto is kept only for the músicos and the narrator's last line. Story files built by four generators (`historia/tools/gen_subida.py`, `gen_musica.py`, `gen_regalos.py`, `gen_muralla.py`), checker clean; sets on `pixel/fuerte-base.js`, read by fresh readers and fixed; sheets and previews done, every make exits 0; handed to the Flutter lane as orders 74 to 77 on page 13, with a first design of the fort check (a guess: the plan's own page is not in the repo). Places 4 to 10 together: 123,204 characters to record. Steps e to h of places 4 to 10 wait for the Dart ports.
- On Nov 21 the account's weekly usage limit stopped every agent for a time (three sheet builders and five reviewers); they were restarted or run again, and nothing was lost.
- Decided here: don Pepe says tú to children and usted to grown-ups; "aquí tiene" is taught on grown-ups; eggs are not on the colmado's list ("no hay huevos" has a rude second meaning); no speaking turn is filed under "por favor" or "de nada" (no story tracks them: each builder's generator now warns when a turn's word was never a story's new word); every second round of a game is drawn on its own, never "the other one"; a number is never tested against its neighbour that sounds like it (dieciséis and diecisiete).

State on Nov 19 2026, after the second build session (the one finishing A1) and the rebuild of reading and review. Read this page first. Update it at the end of every working session.
(These pages live in two places: the claude.ai Project "Coqui - Language Learning App" and this folder, docs/proyecto/ in the GitHub project. A session that cannot see the Project works from this folder and keeps it current. Keep both the same.)

**Read 03-requirements, this page, 07-handoff-build-a1, 08-build-log-a1 (everything built since 07; it wins where they differ), and 09-ui-plan before touching any screen. Before touching Leer, Palabras or Repaso, read 10-leer-y-repaso too.**
01-plan, 02-all-40-scenes and 06-stories-1-3-game are tabs of the plan doc: https://claude.ai/artifact/DAUEyjyynrQe5x1uZRFKcJ

## What Coquí is

- An app to learn a language, with everything in one place. Spanish is the first language.
- The method is immersion and spaced repetition. Hearing first, with context.
- It is a general app. Nothing in the course is personal or religious. The design must work for any language.
- It must be able to fill all of a learner's language hours.
- For now it is an MVP for Salim. Later, a real app for Google Play.
- Salim is the first user. He understands some Spanish and cannot speak it. The course is still built for a true beginner. The level check places people like him.

## Where things stand

- The A1 plan is written, reviewed, and all five of its decisions are settled by Salim (Nov 13). His words are in 03-requirements.
- **Live now (Nov 20): v=40** (A comer and La cocina's routines; see the content lane's section above). The app: https://salimocasio-dev.github.io/field-notes/historia/app.html?v=40 . What follows describes v=39, which v=40 only adds to.
- **Nov 19: v=39.**
    - Leer, Palabras and Repaso are rebuilt and live. Every decision and its reason: page 10. What stands now: page 09, "Reading and review (Nov 19)". What was built and tested: page 08, part 21.
    - Leer: a picture book of each story he has played, in Biblioteca (Listen and Read). 43 books; 22 read well and have a Read button, 21 wait for fixes and show Listen only.
    - Palabras: every word he has met, by place, with Ear and Mouth meters and a word sheet. Repaso: up to 10 words a session, a miss comes back once, an end screen with the session's words.
    - The speaking turns engine is in since v=38 (commit ee1c866). No story is marked yet, so no story changes. The 88 speaking turns for the older stories are not live: they wait on his seven answers.
    - v=39 raised only the cual.js tags (app.html, cual.html, nivel.html) and the ?v=39 on the book files and pictures. The other script tags stay as they were (llamada.js v=37, juego.js and palabras.js v=38, the rest v=35).
- **Also live (v=34 to v=37): the UI rounds and the call with Danny.**
    - UI rounds 1 to 3 are done (v=34, Nov 14). One look for every screen. Decisions: historia/notas/ui-decisiones-1.md, 2 and 3. What is built: page 09.
    - Call Danny is open in Hablar, for La casa. Its card opens once all 11 stories of La casa are played. Page 08, part 18; the screen is in page 09.
    - The call is a speaking call. Danny talks. The screen shows his line, the picture he asks for and what the app heard. Every word of the place that he says becomes a mouth record.
    - A call costs about 650 ElevenLabs credits a minute. The page ends the call at 7 minutes at most (about 4,500 credits).
    - His first two real calls (Nov 16, about 1,000 credits for both): Danny did the job in 35 s and said goodbye himself, then a 20 s goodbye loop, because the page only ended a call on a goodbye from 120 s; replies took 3 to 4.7 s on turns where the model reasoned; the page sent only 8 words as open. Call 1 also picked up background English (a guess: another person or a car). Page 08, part 19.
    - Fixed and live, untested until his next call: v=36 and v=37. Any learner adiós or hasta mañana ends the call after Danny's next line, at any time; a goodbye from Danny alone ends it after that line; all 50 La casa words go as open. Danny's prompt fix 7: he never starts the goodbye; after the job he goes through the open words with a picture and "¿Qué es esto?", going back over part of the job every fourth word. LLM reasoning set to "low" ("none" is refused by the platform). No test credits were spent.
    - A call cannot be placed from localhost: the agent only connects from the published site. The screens are checked with a stub (?callstub=1). Page 05.
    - Danny's brief for place calls is prompt v3: historia/notas/danny-prompt-v3.md. Fix 7 (Nov 17) is section 9 of it, on branch ccr-2871b5d2-axaw8h. Live agent version agtvrsn_6101m7ke5jw1e359681bw18yk2x4 (866 words, 4,572 characters).
- **Live (Nov 17): the voice test for speaking turns: https://salimocasio-dev.github.io/field-notes/historia/habla-prueba.html?v=1** (commit 64752db; 141 machine checks pass). He taps the mic and says 12 lines. Waiting for his number.
- **Not live (Nov 17), on branch ccr-2871b5d2-axaw8h:** A comer, place 3, scene 4, stories 33 to 35. (The speaking turns engine, order 1 of docs/hablar/04-encargo.md, went live at v=38.)
    - A comer: the script is final. All six speaking turns are built and machine-tested (every turn fires once after its set-up line; all right and all missed both pass; habla_motor_check 186/186; matrix 576 runs, 0 problems).
    - A comer pictures: four rounds of fixes, each judged by fresh readers with no sound and no words. After round 4 the three stories read from start to end. Round 5 is running.
    - A comer stays on the branch until the pictures pass the readers. Then it is published. Page 08, part 20.
- **Live (Nov 13): the app to his UI plan, all eleven stories of place 1, La casa, as games (El frente 1 to 3, El balcón 4 and 5, La sala 6 to 8, El patio 9 to 11), word records with the scheduler, and the next-day ¿Cuál? pass for all four scenes.**
    - El balcón: El jugo (silla, se sienta, vaso, jugo, agua, toma) and ¡Qué calor! (quiero, por favor, gracias, de nada, ¿cómo estás?, bien). New in the game: answer bubbles that speak, for words that cannot be drawn. Page 08, part 5.
    - La sala: La familia (mamá, papá, abuelo, bebé, familia), La foto (hermano, hermana, él, ella), ¿Quién eres tú? (yo, tú, soy, eres, me llamo). The family are drawn people. Story 8 opens with one English card. Page 08, part 6.
    - El patio: Las flores (niño, niña, juega, flor, sol, aquí, allá), ¿Qué es esto? (¿qué es esto?, amigo, mira, ven), Hasta mañana (vamos, hasta mañana). "Allí" is taught as "allá"; the gate is "el portón". Page 08, part 7.
    - Escuchar for La casa, first set (Library tab): the eleven stories told straight through, six new picture stories, four do-this routines. About 30 minutes; the plan's size is about 4 hours a place, so this is a first set. Page 08, part 8.
    - The level check (Yo tab, and the welcome): one sentence, four pictures, easy to hard, about 3 minutes. It covers place 1 for now. Page 08, part 9.
    - Place 2, El parque, has begun. El camino: Uno, dos, tres (parque, perro, camina, corre, espera), ¿Dónde está el gato? (gato, árbol, hay, uno, dos, tres), Rápido, despacio. Abuela's dog is Canelo. Page 08, part 10.
    - El campo (place 2, scene 2): La bola (bola, tiene, tira, coge, dame), ¡Arriba! ¡Abajo! (arriba, abajo, salta), ¡Otra vez! (mi, tu, más, otra vez). The balls are told apart by size and pattern. A card in the corner keeps a star or a mark for each of the three rounds. Page 08, part 11.
    - El lago (place 2, scene 3): Pan para el pato (pato, pez, pájaro, nada, vuela), Los botes (rojo, azul, verde, ¿de qué color?), ¿Cuál? (amarillo, blanco, negro, ¿cuál?). The three colours of story 19 differ in lightness as well as hue. Page 08, part 12.
    - El banco (place 2, scene 4; Nov 14): La piragua (hombre, mujer, come, bebe), ¡Señor! ¡Señora! (señor, señora, joven, viejo), El bebé duerme (cansado, contento, triste, duerme). All twelve stories of El parque are built (stories 12 to 23). In this scene the answer bubbles stand in the sky so that nobody is hidden while he chooses, and story 23 is stars only (a baby sleeps). Page 08, part 13.
    - Escuchar for El parque, first set (Nov 14; Library tab): the twelve stories told straight through, five new picture stories (a race, Canelo and the ball, the small duck, Luis's piragua, going home at night), four do-this routines. Page 08, part 14.
    - Place 3, La cocina, has begun (Nov 14). La mesa: La mesa (mesa, plato, taza, pone), La cuchara (cuchara, tenedor, cuchillo, comida), Tengo hambre (tengo hambre, tengo sed, listo, cocina). Stories 24 to 26, in abuela's kitchen. Page 08, part 15.
    - La estufa (place 3, scene 2; Nov 14): Arroz con habichuelas (arroz, habichuelas, olla, hace), El pollo y el huevo (pollo, huevo, sal, huele), ¡Cuidado! (caliente, frío, cuidado, ya). Stories 27 to 29, at abuela's stove. Page 08, part 16.
    - La nevera (place 3, scene 3; Nov 14): No hay leche (leche, queso, no hay, busca), Para los pájaros (fruta, guineo, manzana, pan), Jugo de china (china, mantequilla, lleno, vacío). Stories 30 to 32, at abuela's fridge. Page 08, part 17.
    - Built: page 08. The UI spec and how the build follows it: page 09.
- **The look (his correction, Nov 13): only the home map is the game.** "I didn't say the whole thing is a game, I said on the home screen is the map to the game as the main part of the course." His spec is the doc "Language App UI Design Plan" (link in 09). The map is 16-bit pixel art in the centre tab; everything else is a clean modern UI with a bottom tab bar.
- The coquí speaks in his own voice (Victor, es-PR-VictorNeural), with speech bubbles and captions, Spanish only. Narrator and abuela's lines in Karina (es-PR-KarinaNeural).
- Captions showed in English on his phone; the code was all Spanish, so most likely his browser translated the page. Every page is now marked do-not-translate. He said: "It's good. Continue".
- Audio route: push a story file, GitHub records the changed lines on Azure by itself (free tier so far). ElevenLabs is for live calls with Danny only.
- Progress is stored on the one phone (localStorage), as the plan says, until accounts come.
- Nov 13, evening: he asked why the stories stopped. Claude had stopped on its own, judging the chat too long, against his instruction to build out all of A1. Do not do that. Build scene by scene; keep the pages current after each scene.

## Waiting on Salim

- How the app, stories 1 to 11, ¿Cuál? and the call with Danny feel and sound. Nothing is blocking.
- How Leer (the books), Palabras and Repaso feel at v=39. Nothing is blocking.
- His seven answers, which the 88 speaking turns for the older stories wait on.
- His number from the voice test: https://salimocasio-dev.github.io/field-notes/historia/habla-prueba.html?v=1 . 10 of 12 or more and the 31 older stories get marked for speaking turns; fewer and the turns stop (docs/hablar/04-encargo.md, order 3).
- His next call with Danny on the live page (https://salimocasio-dev.github.io/field-notes/historia/app.html?v=39, Hablar, La casa). Nobody can try it for him: it needs his microphone and the published site. His own words: "you aren't even sure if the first call is right", so the calls of El parque and La cocina wait until he confirms La casa's works.
- His yes was given on Nov 16 for up to 6,000 ElevenLabs credits (about $1) on simulated test calls. Tell him the amount before any more is spent. His own calls cost about 650 credits a minute. No test credits have been spent for v=36, v=37 or fix 7.
- His word on "salta" (asked Nov 13, night): his list says "salta"; in Puerto Rico the everyday word is "brinca". The stories use "salta" until he says otherwise. Also told: "el campo" means the countryside in Puerto Rico, so the stories say "el parque"; the scene keeps his name for it.
- Told him (Nov 14): "pato" is also an insult in Puerto Rico when called at a person; the stories only ever say "el pato" / "un pato" of a duck. His list has "vuela" and "nada"; people say "está volando" / "está nadando" for something happening now; the stories keep his forms. "¿Quién nada?" and "¡El pato nada!" must be said in one breath or "nada" is heard as "nothing": only he can hear whether the voice does.
- Told him (Nov 14, El banco): "viejo" is taught on a dog, because said of a person it is blunt in Puerto Rico (the polite word is "mayor", which comes later); people in the stories are "señor", "señora", "joven". "Hombre" and "mujer" are only said by the narrator. "Bebe" (drinks) and "bebé" (baby) differ only in stress; everyday speech says "toma agua" more than "bebe agua"; "bebe" is his word and is kept. A crying baby is not "triste" in Puerto Rico, so the baby is only "contento" or asleep. In story 21 a learner can find the man or the woman from "el" / "la" and the old words "niño" / "niña": no cleaner test of "hombre" / "mujer" exists inside the word list.
- Told him (Nov 14, La mesa): "pone" is his word and the stories keep it in what the narrator says; the command to one person would be "pon". A "taza" is for something hot in Puerto Rico, so story 24 serves hot chocolate. The fork dish in story 25 is spaghetti, because many people eat rice with a spoon. Six signed touches cannot show spoon, fork and knife in every way; the knife is never the signed picture. The pairs for "tengo hambre" and "tengo sed" are the same contrast twice.
- Told him (Nov 14, La estufa): "ya" is taught as "¡Ya está!", because "¡Ya!" alone means "enough, stop it". Abuela says "Ponle sal al pollo.", because a bare "Sal para el pollo" starts like "get out". "Huevo" has a vulgar use, so it is never said with mi, tu or su, and never after "huele a". "Caliente" is only said of things. Cold chocolate is served in a cup, because the cups are what runs out. The fritter is never named. "No hay más" is heard before "nada" is taught. The pairs for "arroz" and "habichuelas" are the same contrast twice. Story 29 has no speaking round.
- Told him (Nov 14, La nevera): "no hay" is taught against "sí hay", because a bare "Hay leche." sounds like "¡Ay, leche!"; only he can hear whether the voice keeps the pause in "Abuela dice: Sí hay leche." and says "¡Fo!" clearly. "Leche", like "huevo", is never said with mi, tu or su. Bad food "no huele bien" (not "viejo"). "Busca", "china" and "mantequilla" decide nothing in their stories. "Pan" has been heard since story 18. In stories 30 and 32 it is the frog who goes without first; in 30 it is his own money.
- His yes or no on two small things (asked Nov 13): "por favor" and "de nada" have no next-day picture pair (they are tested by the speaking bubbles inside story 5); and whether this session may keep publishing straight to main, as page 07 says.

## Next steps, in order

In short: his voice test number and his next La casa call; A comer (picture round 5 and fresh readers, then publish); marking the 31 stories; then places 4 to 10, then the fort check.

**His ask, Nov 16 (applies to every story from A comer on):** "we should probably put some speaking prompts in the next stories that use the previously learned vocabulary." So each new story includes moments where he says a line out loud, using words from earlier scenes whose ear record has held 2 to 3 days (the coquí's lines are the natural place), and the app hears it. Never a self-report button. Needs speech recognition on the story page (the phone's built-in recognition is free; the voice test checks how well it hears his Spanish first). Words he says go to their mouth record. He also confirmed the design: speaking with Danny comes after a place's stories. The decisions and the work orders are in docs/hablar/ (01 to 04).

1. **His voice test number and his next La casa call.** The test is live (https://salimocasio-dev.github.io/field-notes/historia/habla-prueba.html?v=1). 10 or more of 12: go on. Fewer than 10: stop and report the lines and what was heard; do not change the settings or the accepted forms. His next call (https://salimocasio-dev.github.io/field-notes/historia/app.html?v=39; the call code is still v=37) shows whether the fixes hold: no goodbye from Danny until he says one, the call ends after his adiós, replies under about 2 s (a turn over 2 s means reasoning is still running), the review of the open words with pictures. No call for El parque or La cocina until he confirms La casa's works.
2. **A comer: the pictures, then publish.** Place 3, scene 4; stories 33 ¿Qué quieres?, 34 Buen provecho, 35 Café con azúcar. Not live.
    - The script is final (historia/notas/guiones/comer.md, after decisions 4 to 7). Built on the branch: scene historia/escenas/comer.js, generator historia/tools/gen_comer.py.
    - Pictures: four rounds of fixes, commits a01301e (round 2) to 18ed1ba (round 4) on the branch, each judged by fresh readers with no sound and no words (txt=no).
    - After round 4 the three stories read from start to end: who asks, who speaks, what is lost, the counts.
    - Left: layering, reach, some actions still out of view, and three pairs (rico, azúcar, un poco). Round 5 is running.
    - Not published: A comer stays on the branch until the pictures pass the readers. Then publish (item 6): merge main, raise ?v=, push to main, send him the link.
    - Audio: 3,190 characters to record on Azure when it is published, within the free 500,000 a month. Nothing spent yet.
3. **Speaking turns in A comer: built and machine-tested** (commit 711ba4f). Six turns: story 33 bien, gracias; story 34 lleno, papá; story 35 bien, gracias. Every turn fires once after its set-up line; all right and all missed both pass; habla_motor_check 186/186; matrix 576 runs, 0 problems. The turn lines reuse recorded clips, so no new audio. Per his Nov 16 ask, every new story from now on gets them (docs/hablar/03-para-historias-nuevas.md).
4. **The speaking turns engine** (order 1 of docs/hablar/04-encargo.md). On the branch, with its machine check (habla_motor_check, 186/186). Not live.
5. **Marking the 31 stories** (order 4), only after his voice test passes (item 1). Then the machine tests and the reviews (orders 5 and 6).
6. **Publish** (order 7): push, check the live site, send him the link with a new ?v= number and one line per point: what changed, what was checked, what is a guess.
7. Place 1: all four scenes, eleven stories, a first set of Escuchar and the call with Danny are done (v=37). Reading is picture books (page 10). Still to do for place 1: more Escuchar sets toward the plan's 4 hours, and whatever his next call shows.
8. The level check: built for place 1 (page 08, part 9). Each new place adds its items.
9. Places 2 to 10. Place 2, El parque: all four scenes and a first Escuchar set are done. Its call with Danny is not built yet (only La casa has one; on hold, item 1). Place 3, La cocina: scenes 1 to 3, La mesa, La estufa and La nevera, are done (stories 24 to 32); scene 4 is item 2. Then the place's Escuchar and its call. Since Nov 14 the work runs with one orchestrating session and builder agents; their rules are in historia/notas/runbook-agentes.md, and the test helpers are in historia/tools/. Words for every scene: page 02.
10. Open alongside: the rest of the UI plan (09: unlock haptics, streak freezes, the map at an angle and finished places changing it, pitch feedback); the 85% difficulty tuning; the plan doc fixes ("porch lamp", "nothing is built", old three passes).

## Pages

| Page | What it holds |
| --- | --- |
| 00-start-here | This page: state, next steps, rules |
| 02-all-40-scenes | The ten places, forty scenes and their words (copied into the repo Nov 13) |
| 01-plan | The A1 plan, second draft (plan doc, Plan tab) |
| 02-all-40-scenes | The ten places, 40 scenes and their words (plan doc, All 40 scenes tab) |
| 03-requirements | What Salim asked for and rejected, in his words |
| 04-research-notes | Claude's notes on the six research reports (Project only) |
| 05-build-and-tools | Ids, costs, the audio route, Danny, how story 1 was first built |
| 06-stories-1-3-game | Stories 1 to 3 as designed (plan doc, game tab) |
| 07-handoff-build-a1 | The handoff for building out A1: the code, the story file format, the build order, the checklists |
| 08-build-log-a1 | Everything built since 07 |
| 09-ui-plan | His UI spec (his doc), his words on the look, where the build follows or differs, what is left |
| 10-leer-y-repaso | Reading (Leer), Palabras and Repaso: the redesign and the decisions after each fresh read |

## Links

- Plan doc, the one Salim reads and comments on: https://claude.ai/artifact/DAUEyjyynrQe5x1uZRFKcJ (if it and these pages differ, the doc wins)
- UI plan doc (his): https://docs.google.com/document/d/1oYSXXDBPCQhxDJ3IbrvKfI7LC2eDjCPhOW8Ljs9BEm0
- Live app (v=39): https://salimocasio-dev.github.io/field-notes/historia/app.html?v=39
- Live voice test (v=1): https://salimocasio-dev.github.io/field-notes/historia/habla-prueba.html?v=1
- Code: https://github.com/salimocasio-dev/field-notes (public; main is the live site)
- Research reports in his Google Drive: links in 01-plan, "Sources".

## Decisions that stand

- Recorded listening for the bulk of the hours. Live calls for speaking.
- The full app is open on day 1, tailored to A1. What changes by level is what is tracked.
- Reading is in from day 1. It is not tracked until A2.
- The map is the home screen and the main part of the course, the only game-styled screen. The rest of the app is a normal, clean app. Listening is not all packed into the map.
- Each skill keeps its own record per word. A miss while speaking counts against speaking only.
- Danny is slow and deliberate, plain, A1 and A2 words only. He says "Sí." or "Eso." and moves on. No pet names.
- The course words are Puerto Rican and stay Puerto Rican. The voice's accent does not have to be. Never filter voice options by accent.
- Pictures are an aid to listening. Someone who knows zero words must understand from the picture alone.
- Touch is how he answers in listening. Games are not ruled out. His test is whether a thing works and teaches.
- A real game with stakes inside the stories: something can be lost, and what he touches and answers changes what happens.
- His word comes before a research rule or a plan doc. Where they disagree, do what he said and tell him in one line. His words: "This needs to stop happening."
- Anything he says must be heard by the app or by Danny. No button that takes his word for it (so no swipe-to-rate cards).
- The coquí has his own voice and speaks his own lines. Speech bubbles and captions, Spanish only, shown with the sound (his call over "sound first"; one setting, TXT).
- English only for menus, the welcome, the stuck line and the one line before a new grammar pattern. Never while Spanish plays. No page may be machine-translated. No translation pop-ups.
- The mosque is off the map. Original pixel art only. Wyner's 625-word list: method only, never copied.

## Mistakes already made here. Do not repeat them.

- A self-review was presented where he had asked for an independent review.
- Guessed numbers were written as if they were findings. Say plainly what is a guess.
- The map was made into the whole app, all listening was packed into it, and reading was pushed out of A1.
- Voice options were filtered by accent; then the Puerto Rican words were swapped out of the course. Both wrong and reversed. Apply what he says at exactly the scope he says it.
- The first build was tap-only and taught nothing, with an "I said it" button. His word: garbage.
- The first story spoke in bare labels with long dead pauses: "beyond boring".
- A thing was marked before a touch on it counted, so a right touch read as wrong.
- Nov 13: ¿Cuál? went to him before the silent picture check ran. Run the reader before sending anything with pictures.
- Nov 13: the first app shell was a default dark card layout with the map as one tab ("What kind of UI is this????"). The fix then went too far and made every screen a pixel game. He had asked for the map as the home screen and main part of the course, not the whole app. Same mistake as before: his words stretched past their scope. Read his UI plan (09) before changing a screen.
- Nov 13: Claude stopped building on its own before A1 was done. Never stop to wrap up; keep going scene by scene.

## Before anything with pictures or lines goes to Salim

1. Write it to his sketch (03-requirements): whole sentences, real questions, short praise, keep moving.
2. When a plan rule makes it worse to sit through, the rule loses. Tell him in one line.
3. Fresh reviewers on the script: one as a beginner against his requirements ("where is this dull?"), one for Puerto Rican Spanish.
4. Build it. Play every path by machine (historia/tools/juega.py, cual_check.py).
5. A fresh reader looks at frames with no sound and no words (?txt=no) and says what happens. Fix what is real.
6. Measure the silences and the length.
7. Send the link with a new ?v= number. Claude cannot hear. He is the last check.

## How Salim wants to work

- Short and plain. One point per line. He reads on his phone.
- Answer at the size he asked. No extra work he did not ask for.
- Say what is a guess. Say when Claude's own work caused the problem.
- Do not hunt for something to criticise.
- Ask everything needed in one go. No to-dos.
- Check numbers against the source.
- Looking at websites is approved.
- Tell him the amount before anything is spent. ElevenLabs uses his credits.
- He enters keys and passwords himself. Opening an account is his call.
- Don't ask him to confirm the plan. Build, and tell him when there is something to play.

## Still missing

- The report on what keeps adults coming back (research prompt 5) is not in his Drive.
- The check of the word list against the Instituto Cervantes A1 inventory.
- A Puerto Rican speaker's check of the whole word list (for example, helado or mantecado).
