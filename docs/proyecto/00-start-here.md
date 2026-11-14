# Coquí: start here

State on Nov 13 2026, during the second build session (the one finishing A1). Read this page first. Update it at the end of every working session.
(These pages live in two places: the claude.ai Project "Coqui - Language Learning App" and this folder, docs/proyecto/ in the GitHub project. A session that cannot see the Project works from this folder and keeps it current. Keep both the same.)

**Read 03-requirements, this page, 07-handoff-build-a1, 08-build-log-a1 (everything built since 07; it wins where they differ), and 09-ui-plan before touching any screen.**
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
- **Live (Nov 13): the app to his UI plan, all eleven stories of place 1, La casa, as games (El frente 1 to 3, El balcón 4 and 5, La sala 6 to 8, El patio 9 to 11), word records with the scheduler, and the next-day ¿Cuál? pass for all four scenes.**
    - The app: https://salimocasio-dev.github.io/field-notes/historia/app.html?v=32
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

- How the app, stories 1 to 11 and ¿Cuál? feel and sound. Nothing is blocking.
- His yes or no (asked Nov 13, evening): may up to 6,000 ElevenLabs credits (about $1) be spent on simulated test calls for place 1's call with Danny, once the allowance renews Nov 16. Until he says yes, build only the app side and the brief; spend nothing.
- His word on "salta" (asked Nov 13, night): his list says "salta"; in Puerto Rico the everyday word is "brinca". The stories use "salta" until he says otherwise. Also told: "el campo" means the countryside in Puerto Rico, so the stories say "el parque"; the scene keeps his name for it.
- Told him (Nov 14): "pato" is also an insult in Puerto Rico when called at a person; the stories only ever say "el pato" / "un pato" of a duck. His list has "vuela" and "nada"; people say "está volando" / "está nadando" for something happening now; the stories keep his forms. "¿Quién nada?" and "¡El pato nada!" must be said in one breath or "nada" is heard as "nothing": only he can hear whether the voice does.
- Told him (Nov 14, El banco): "viejo" is taught on a dog, because said of a person it is blunt in Puerto Rico (the polite word is "mayor", which comes later); people in the stories are "señor", "señora", "joven". "Hombre" and "mujer" are only said by the narrator. "Bebe" (drinks) and "bebé" (baby) differ only in stress; everyday speech says "toma agua" more than "bebe agua"; "bebe" is his word and is kept. A crying baby is not "triste" in Puerto Rico, so the baby is only "contento" or asleep. In story 21 a learner can find the man or the woman from "el" / "la" and the old words "niño" / "niña": no cleaner test of "hombre" / "mujer" exists inside the word list.
- Told him (Nov 14, La mesa): "pone" is his word and the stories keep it in what the narrator says; the command to one person would be "pon". A "taza" is for something hot in Puerto Rico, so story 24 serves hot chocolate. The fork dish in story 25 is spaghetti, because many people eat rice with a spoon. Six signed touches cannot show spoon, fork and knife in every way; the knife is never the signed picture. The pairs for "tengo hambre" and "tengo sed" are the same contrast twice.
- Told him (Nov 14, La estufa): "ya" is taught as "¡Ya está!", because "¡Ya!" alone means "enough, stop it". Abuela says "Ponle sal al pollo.", because a bare "Sal para el pollo" starts like "get out". "Huevo" has a vulgar use, so it is never said with mi, tu or su, and never after "huele a". "Caliente" is only said of things. Cold chocolate is served in a cup, because the cups are what runs out. The fritter is never named. "No hay más" is heard before "nada" is taught. The pairs for "arroz" and "habichuelas" are the same contrast twice. Story 29 has no speaking round.
- Told him (Nov 14, La nevera): "no hay" is taught against "sí hay", because a bare "Hay leche." sounds like "¡Ay, leche!"; only he can hear whether the voice keeps the pause in "Abuela dice: Sí hay leche." and says "¡Fo!" clearly. "Leche", like "huevo", is never said with mi, tu or su. Bad food "no huele bien" (not "viejo"). "Busca", "china" and "mantequilla" decide nothing in their stories. "Pan" has been heard since story 18. In stories 30 and 32 it is the frog who goes without first; in 30 it is his own money.
- His yes or no on two small things (asked Nov 13): "por favor" and "de nada" have no next-day picture pair (they are tested by the speaking bubbles inside story 5); and whether this session may keep publishing straight to main, as page 07 says.

## Next steps, in order

1. Place 1: all four scenes, eleven stories and a first set of Escuchar are done. The reading texts are in the Library (each story carries its lines). Still to do for place 1: more Escuchar sets toward the plan's 4 hours, and its call with Danny (the app side and Danny's brief can be built without spending; testing a call costs ElevenLabs credits and needs Salim's yes; the allowance was used up Nov 12 and renews Nov 16).
2. The level check: built for place 1 (page 08, part 9). Each new place adds its items.
3. Places 2 to 10. Place 2, El parque: all four scenes and a first Escuchar set are done. Its call with Danny waits on the same yes as place 1's. Place 3, La cocina: scenes 1 to 3, La mesa, La estufa and La nevera, are done (stories 24 to 32). Paused (Nov 14, at the owner's word, while he tests the app): scene 4, A comer. Its script is at draft 3, after two rounds of reviews: historia/notas/guiones/comer.md (33 ¿Qué quieres?: butter or chocolate inside a hot roll, a wrong one is bitten and left, abuela eats last; 34 Buen provecho: second helpings against papá's lunch, the frog says "¡Buen provecho!" to leave the table; 35 Café con azúcar: sugar and coffee that cannot come out of a cup). Every story has two scored rounds. The orchestrator's decisions for draft 3 are in historia/notas/guiones/comer-decisiones-3.md. Open before the last gate: in 34 B whether Luis takes a mound for himself (the count allows one); the pairs for "quieres" ("pan" picks the picture) and "buen provecho" (the clean-plates picture now fits too); "No tengo…" is heard only twice before the game. Next: settle those, a last gate and a final Spanish check (fresh reviewers), then build (scene file comer.js from the table of mesa.js, historia/tools/gen_comer.py on the pattern of gen_nevera.py), pairs, level-check items, version 33, machine tests, wordless readers, audio, publish. Then the place's Escuchar and its call. Since Nov 14 the work runs with one orchestrating session and builder agents; their rules are in historia/notas/runbook-agentes.md, and the test helpers are in historia/tools/. Words for every scene: page 02.
4. Open alongside: the rest of the UI plan (09: calm full-screen lesson screens, the mic states, unlock haptics, streak freezes, the map at an angle and finished places changing it); the 85% difficulty tuning; the mouth record fed by calls; the plan doc fixes ("porch lamp", "nothing is built", old three passes).

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

## Links

- Plan doc, the one Salim reads and comments on: https://claude.ai/artifact/DAUEyjyynrQe5x1uZRFKcJ (if it and these pages differ, the doc wins)
- UI plan doc (his): https://docs.google.com/document/d/1oYSXXDBPCQhxDJ3IbrvKfI7LC2eDjCPhOW8Ljs9BEm0
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
