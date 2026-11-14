# A1 build log (the chat that took over from 07)

Started Nov 13 2026. Newest first. Where this page and 05, 06 or 07 differ, this page wins.

## Live now

- The app: https://salimocasio-dev.github.io/field-notes/historia/app.html?v=32
- Story 1 directly: historia/?v=32 . Any story: ?cuento=<id> (the ids are in historia/curso.js). ¿Cuál?: historia/cual.html
- Script tags carry ?v=32 in index.html, cual.html, app.html and nivel.html. Raise all four when a script changes.
- The audio job also commits ("Audio: cuento") after a push that touches cuentos/. Pull before pushing again, or the push is refused. It records as soon as a story file reaches the branch, so a line pushed early and changed later is recorded twice: do not push new story files until their Spanish has had its last review, and keep test story files out of cuentos/ (a story id may only hold a to z, 0 to 9 and the hyphen).

## Script lessons so far (what reviewers have caught; check every new script against this before it goes to them)

Decisions
- Only the Spanish decides. Not echo (the question holds the sound of the answer), habit, position, elimination (the answer is the word the last round did not use), memory of an earlier step, line length, an old word, the picture, or world knowledge (cake goes on a plate; a shivering man wants something hot).
- Every deciding word is heard three times or more before it can cost. Every answer mode (touch a thing, touch a person, picture bubbles, speaking bubbles, doing bubbles) is done under the big sign first, with each target kind. Six signed touches at most in an opening.
- The three games of a scene open differently, and the three stories of a scene do not share a skeleton or a turn.
- A draw must never make a round unloseable, and both wrong sides must cost.

The world
- The goal and what is at stake show in the first frame. A loss follows from the mistake, shows at once, and stays in the picture to the end. A redo brings no reward and needs nothing that is not there.
- Count every thing in every branch (right and wrong of A, then B, then C, with each draw): plates, cups, portions, tools, people, chairs. Make stock finite and visible if a loss is "one fewer".
- "No, Coquí. Mira." and a whole sentence, true to the eye at that moment.
- Nobody acts like a fool or refuses without a reason. Nobody who cannot see asks. No hiding tricks. No clock.
- A line about an action is said during it. No bare labels: whole sentences.
- A poke never names a thing that decides a round. A touch on somebody's things counts as that person.

Puerto Rican Spanish (so far)
- "Viejo" of a person is blunt; any grown man is "un señor"; "pato" called at a person is a slur; "bebe" (drinks) against "bebé"; "taza" for hot drinks and "vaso" for cold; "pon" is the command of "pone"; "entra a", not "entra en"; "habichuelas"; "bizcocho"; "canasta"; "piragua"; "portón".
- Say "Tú tienes sed", not "Tienes sed" (it runs into "tiene sed" aloud).
- "¡Ya!" alone means "enough, stop it": say "¡Ya está!". Bare "Sal para el pollo" starts like "get out": say "Ponle sal al pollo." "Huevo" never with mi, tu or su, never in the plural of a person, and never after "huele a" ("huele a huevo" is said of a rotten smell): "Mira el huevo.", "El bebé quiere el huevo." "Caliente" only of things, never of a person. "La familia tiene hambre."
- "Leche", like "huevo", never with mi, tu or su; never "tiene queso". A bare "Hay leche." sounds like "¡Ay, leche!": say "Sí hay leche." or "Aquí hay…"; "y hay" runs together, so say "Hay leche y queso." "¿Qué no hay?" is not a question anyone asks. "Busca" is "go and get": say it while he goes, not while he hands over. A fruit after "come" has its article ("come el guineo"), and "el pájaro" in the singular beside "guineo" is slang: "para los pájaros". Bad food "no huele bien"; "¡Fo!" at a bad smell. "Le pone mantequilla al pan", not "pone mantequilla en el pan". A guineo with brown spots is ripe, not bad.

Pictures (what readers with no sound and no words could not read)
- A place 24 pixels wide holds two things; keep places apart. Small things in a hand do not read: hold them up at twice the size, in a hand, beside the head.
- A flat brown oval reads as a dish, not a puddle: splashes need drops and a rim. A thing drawn over a head reads as alarming.
- Whoever loses something reacts. Whoever stands in front must not hide the frog or the thing that matters.
- Stills are taken at changes of state: a cause that lasts half a second is not seen in them. Make the result explain itself.
- White food on a white plate is an empty plate: give plates a colour. A lost thing must rest on something (the floor in the open, a bucket, a plate): against a cabinet or a stove front it reads as stuck to a wall or hanging in the air.
- A boil-over is one soft shape over the rim with runs down the front and what was in the pot beside it; blocks read as a fault in the picture. Smoke is a puff, not specks. Rice needs its grains, beans their dark dots.
- Thought clouds must not cover what stands on a counter, or each other: stand the people lower. Two who come in together need a body's width each.
- Somebody who must not hear or see has to be out of the room, or at the far end of the yard: standing with a back turned, or at the sink, does not hold up with a reviewer. Whoever knows the answer must not handle the thing afterwards.
- When the good ending spends what the bad ending loses (coins), the last picture must show the wish: the frog thinks of what he could not buy.
- A thing held by a child is held over the head at twice the size: beside the head it covers the face. An empty place needs a lining (a checked cloth, a stand): a white hollow reads as a bun. A bad thing gets green wisps. Birds must not be the colour of bread.
- The sheet tool sorts frames by number now: a run of more than 99 frames was shown out of order.
- A thing held up for a pair is held in a raised hand and must leave the face free. A cup with a heap on it reads as a mug of beer: use a bowl.

Pairs
- No old word in the sentence may fit one picture only. "Mi" or "tu" instead of "un" and "una". The other picture is as lively as the right one. No picture is right twice.

## Nov 14, part 17: place 3, La cocina, scene 3, La nevera (stories 30 to 32)

Live at ?v=32. Script (final): historia/notas/guiones/nevera.md, with what each round of reviews, the final Spanish check, the last gate and the wordless readers changed at its end. Generator: historia/tools/gen_nevera.py (three stories, twelve pairs; it also sets `next` on story 29). Scene: historia/escenas/nevera.js.

### What is built

| Story | Words | The game (after the turn) | What a miss costs |
| --- | --- | --- | --- |
| 30 no-hay-leche, No hay leche | leche, queso, no hay, busca | A he sees into the fridge and says what there is none of ("¡Papá, no hay leche!"); B abuela says both halves ("Sí hay leche. No hay queso.") and he answers with a picture card; C she says one line of four and he answers with a picture card | papá fetches the wrong thing for abuela's coin; its place in the fridge is taken, so it stands on the counter, and the second errand is paid from the frog's own jar of three coins: his piragua is a scoop smaller for each |
| 31 para-los-pajaros, Para los pájaros | fruta, guineo, manzana, pan | A touch the roll or the plate of fruit abuela names ("El pan no huele bien."); B touch the child who holds the fruit she names; C he sees the spots and says which ("¡El guineo no huele bien!"), and abuelo, who sees only the backs, throws it | a good thing goes to the birds and is eaten at once; its cell in the picnic basket stays empty (three lots, three cells) |
| 32 jugo-de-china, Jugo de china | china, mantequilla, lleno, vacío | A the children say "Mi vaso está vacío / lleno." and he pours; B mamá says one line of four about the red or the blue cup and he pours; C abuela says one line of four and he takes a cup to the sink | juice poured into a full cup runs over (a puddle that stays, a mark off the jug); a full cup tipped into the sink turns the dishwater orange: the jug has four marks, and the frog, then abuela, then the child go without |

- Nobody can see into a metal cup or a shut fridge: that is what makes "lleno", "vacío" and "no hay" turn on the Spanish. In the openings a round picture shows a cup from above.
- "Busca", "china" and "mantequilla" decide nothing in their stories; they are tested the next day by their pairs. "Nevera" and "fo" are helper words.
- `curso.js` lists the three stories; the level check has four new items (48: leche, queso, guineo, lleno); ¿Cuál? has twelve new pairs (cual-nevera, 128 in all).

### The scene (nevera.js)

- The fridge at the left: `W.nev` {abierta (1 open to us, 2 a little, only who looks in sees; 0 shut), h (two shelves, four places), soporte (story 30: a stand for the bottle and a dish for the cheese), cajon and cajonver (the drawer and whether it is tipped towards us)}. A counter with a sink (`W.pila`: dishwater "a", orange "j"). A wide window to the yard: `W.patio` {aves, cosas (what lies on the wall), carrito}; a sill things stand on: `W.repisa` [{id, k, v, x, e}]. Whoever has `fuera:1` stands in the yard and is drawn inside the window.
- Things with a name of their own live in `W.cosas` with an `id` (`ob(id)`); `porId` makes them touchable (the four cups, the two things on the tray).
- Story 30: `mira30` (abuela at the fridge), `sale30` (her coin on the sill, out of the door), `mandado` (the coin to papá, papá off and back, Luis in at the door to the fridge: he puts the thing in, or its place is taken and it stands on the counter), `sacamoneda` (the frog's own coin), `comparten`, `final30`.
- Story 31: `lote`, `huele31`, `tira31`, `resto31` (give, keep, or turn over), `sostienen`, `huelemanos`, `quita`, `nino31`, `abuelo31` (trae, alza, pone, tira, come, da, mira), `alMuro` (what is thrown lands in one of four places on the wall; a good thing stays there with its bird). `W.canasta` is the picnic basket; `W.olfato` shows a sniff; a bad thing has green wisps (`hedor`).
- Story 32: `exprime`, `unta`, `vista` (the round picture), `vierte` (the frog pours from behind the jug; into a full cup: puddles), `ninos32`, `mama32`, `abuelamira`, `lleva32` (a cup to the sink), `final32`.
- cual.html takes `solo=word,word` for the machine check of a few pairs.

### Reviews

- Two designers wrote proposals first; both came to the same three costs. Script: draft 1 and draft 2 each "not ready" for all three (beginner) with 13 and 10 lines of Spanish; draft 3 to a final Spanish check (112 lines read one by one, two changed) and a last gate (one fix a story, the pairs ready).
- Wordless frames: four fresh readers, then three more after the redraw. What they could not read is at the end of the script and in "Script lessons so far".
- The biggest mistakes caught: papá could hear abuela name what was missing, and abuela could send a wrong buy back (30); abuela handled food she knew was bad, and the frog threw good fruit out against his own eyes (31); people stood by while a full cup was filled (32); "Mira mi leche", "¿Qué no hay?", "Hay leche." heard as "¡Ay, leche!", "come guineo" beside "el pájaro" (Spanish); a green cup drawn grey, food over abuela's face, a basket that never looked empty, an ending whose loss did not show (pictures).

### Testing

- TESTLINE17
- Found by testing: cups hidden after an earlier step could not be touched; a run of more than 99 frames was shown to a reader out of order.

### Audio

- 117 new lines, about 3,350 characters. Azure so far this month: about 43,400 of 500,000 characters (my own running count, not a reading from Azure).

## Nov 14, part 16: place 3, La cocina, scene 2, La estufa (stories 27 to 29)

Live at ?v=31. Script (final): historia/notas/guiones/estufa.md, with what each round of reviews, the last gate and the wordless readers changed at its end. Generator: historia/tools/gen_estufa.py (three stories, twelve pairs; it also sets `next` on story 26). Scene: historia/escenas/estufa.js.

### What is built

| Story | Words | The game (after the turn) | What a miss costs |
| --- | --- | --- | --- |
| 27 arroz-con-habichuelas, Arroz con habichuelas | arroz, habichuelas, olla, hace | A touch the cups of rice or of beans for the cook who asks ("Dame arroz, por favor."; only his pot is on the stove); B say what a pot needs more of; C touch the pot abuela says is ready | a cup of the wrong food is skimmed off into the bucket, or the ready pot boils over: three cups of each for three plates, so somebody's plate has rice only or beans only |
| 28 el-pollo-y-el-huevo, El pollo y el huevo | pollo, huevo, sal, huele | A call out the piece that smokes ("¡Abuela, el pollo!"); B doing bubbles: salt the piece Carmen names; C touch the piece on the plate abuela holds out ("El bebé quiere el huevo.") | a piece burns black, or is salted twice and pushed aside, or the baby throws it on the floor: six pieces on the tray, and the frog's own is the last |
| 29 cuidado, ¡Cuidado! | caliente, frío, cuidado, ya | A doing bubbles: wait or take out ("¡Cuidado, Coquí!" / "¡Ya está, Coquí!"); B touch the pot or the jug ("Quiero chocolate frío."), the frog fills the cup; C touch who ("¿Quién quiere chocolate caliente?") | a fritter falls raw or burns; a wrong cup is drunk by Luis and thrown in the bucket: four balls of batter, nine cups; the last cup is abuela's, the one before it the frog's |

- Story 29 has no speaking round; 27 and 28 have one each.
- `curso.js` lists the three stories; the level check has four new items (44: arroz, olla, pollo, caliente); ¿Cuál? has twelve new pairs (cual-estufa, 116 in all).
- "Olla", "hace", "huele" decide nothing in their stories; they are tested the next day by their pairs.

### The scene (estufa.js)

- The stove in the middle with two burners, a counter at each side, a shelf and a window. Cooks stand at the two sides of the stove, lower than the pots; the frog on a stool in front.
- A burner: `W.fuegos[i]` {k (olla, sarten), con, n (cups in it, 0 to 3), llama, vapor, humo, mal (the wrong food lying on top), espuma (boiled over: the food's name), cosas:[{k, v, sal, humo}]}.
- Left counter `W.izq` {saco, tazon (cups of rice and of beans left), llenando, bandeja:{pollo, huevo}, jarra, tazas, sucias}; right counter `W.der` {platos, pila, platito, servidos:[{de, items}], masa, fuente, frituras}. `W.estante` (1: the full sack and jar on the shelf, 2: both empty), `W.repisa` (the baby's plate waits at the back of the right counter), `W.plata` (the plate abuela holds out, drawn three times the size: its two pieces are the touch targets), `W.mat` (the frog's small plate by the stool: o, taza), `W.cubo` and `W.basura` (the bucket and what is in it: rice, beans, a black fritter, a cup), `W.olor` (a wavy line from a pan to a nose, for a pair).
- People as in mesa.js, plus `alza` {k, v, e (size), dx, dy}, `come`, `cierra` (eyes shut), `pdx` (where a thought cloud stands). Abuela's offering arm points the way she faces.
- Story 27 keeps count: `cae(i,k)` puts a cup in a pot (the wrong food lies on top and comes out again with `saca`); `sirve27` serves rice from Luis's plate on and beans from abuela's plate on, so no plate is empty; after a miss in A, round B is at the pot of the food that was thrown away (act `nota` sets `V.fa`), so one food is never lost three times.
- An act with `suelto:1` runs while a line is said; `act ya` waits for it (`corre(o,pr)`).
- cual.html takes `solo=word,word` for the machine check of a few pairs.

### Reviews

- Script: draft 1 to draft 3 over two rounds (a beginner against his requirements, and Puerto Rican Spanish, each round by fresh reviewers); story 28 was redesigned twice (no honest cost for pollo against huevo until the smoke, the salt and the baby's wish); then a final Spanish check and a last gate (every decision holds; one must-fix per story). A last Spanish check of the lines the gate added threw one of them out ("¡Y huele a huevo!").
- Wordless frames: four fresh readers (one per story, one for the pairs), then two more after the redraw. What they could not read and what was redrawn is at the end of the script and in "Script lessons so far" above.
- The biggest mistakes caught: one food could be lost three times so a plate would be empty (27); Carmen bit a piece she had watched being salted twice (28); the last cup went to the frog, so a miss cost abuela first (29); "¡Ya!", "Sal para…", "Mira mi huevo", "huele a huevo" (Spanish); white rice on a white plate, cups stuck to the oven, a boil-over that read as a chef's hat (pictures).

### Testing

- 183 machine runs after the last change to the pictures: each story all right, all wrong and every mix of misses, over every set of draws (27: 59 runs, 28: 64, 29: 60). All end, with the stars and crosses they should have. All 116 picture pairs, the level check with all 44 items shown, and the app check.
- Found by testing: a pot held two cups at most, so the third plate at the turn was empty.

### Audio

- 114 new lines, about 3,400 characters. Azure so far this month: about 40,000 of 500,000 characters (my own running count, not a reading from Azure).

## Nov 14, part 15: place 3, La cocina, scene 1, La mesa (stories 24 to 26)

Live at ?v=30. Script (final): historia/notas/guiones/mesa.md, with what each round of reviews changed at its end. Generator: historia/tools/gen_mesa.py (three stories, twelve pairs; it also sets `next` on story 23). Scene: historia/escenas/mesa.js.

### What is built

| Story | Words | The game (after the turn) | What a miss costs |
| --- | --- | --- | --- |
| 24 la-mesa, La mesa | mesa, plato, taza, pone | A touch the plates or the cups ("Un plato para papá."); B touch who ("¿Quién no tiene taza?"); C say what is missing | a slice of bizcocho or a cup of chocolate is ruined, and one plate or cup stays empty: there are exactly three of each |
| 25 la-cuchara, La cuchara | cuchara, tenedor, cuchillo, comida | A touch who ("¿Quién tiene la cuchara?"); B say what is missing; C picture bubbles ("Un tenedor para Carmen.") | the food drops off the wrong thing onto the white cloth; the stain stays |
| 26 tengo-hambre, Tengo hambre | tengo hambre, tengo sed, listo, cocina | A he says what he wants himself (a thought bubble shows it); B touch food or water; C touch who said it | Canelo has the plate or the glass, and the one it was for sits without it: four plates, four glasses |

- The three games open differently (a thing, a person, something he says) and end differently.
- A new place on the map: La cocina opens when El parque is done. `curso.js` lists the three stories; the level check has four new items (40); ¿Cuál? has twelve new pairs (cual-mesa).
- "Mesa", "pone", "comida", "cocina" and "listo" decide nothing in their stories; they are tested the next day by their pairs.

### The scene (mesa.js)

- Abuela's kitchen: counter and cupboard left, the table in the middle seen a little from above with four chairs behind it, stove and window right, the door to the yard at the left edge. Whoever stands in front of the table is lower in the picture than its top, so nothing on the table is hidden.
- People: `W.gente[name]` {x, y, dir, sent, vis, hace (come, bebe), que, lleva, lleva2, alza (held up, drawn twice the size), mano (in the hand at a dish), piensa (a thought bubble: hambre or sed), bebe (mamá carries the baby)}. `W.sitio[name]` is the chair, 0 to 3. Abuela also has `ofrece` (what she holds out).
- A place: `W.puestos[i]` {plato:{n, con, vapor}, taza:{n, con, k}, frente:[...]}. `con`: bizcocho, choco, sopa, espa, pan, comida, migas, agua. `frente` holds the messes (roto, charco, mancha with its colour) and a thing put aside. The plate stands in front, the cup behind it to the right, so four places stay apart.
- The counter is `W.mostrador` {platos, tazas, bandeja, comidas, vasos, jarron}; the tray's contents are `W.bandeja`; the stove is `W.estufa` {olla (2: empty, tipped towards us), tapa, vapor, bizcocho, jarra, pastel, horno}.
- `coloca(i,k)`: a second plate or cup at a place ruins what was in the first. Story 24 counts slices and cups of chocolate (`W.reb`, `W.choc`) once `W.contado` is set at the turn; abuela's board shows the slices left.
- Story 25: there is one spoon, one fork, one knife. `tiene(id)`, `quienTiene(k)`; `util` (the frog carries one, and a wrong one flies back to where it came from: `W.origen`), `llama` (two people change over), `come25` (a stain when the thing does not fit the dish).
- Story 26: `W.tuvo[who]` and `W.perdio[who]` keep what each has had and what Canelo had instead; `reparte26` hands out what is left at the end.
- `suelto:1` on an act starts it and goes on, so that a line is said during it; `act ya` waits for it. `abuelaa` {a, centro, sirve, nada}, `entra`, `sale`, `muestra` (one thing lifts up to twinkle), `piensa`.
- A touch on somebody's place counts as that person (the person's box reaches down to the table). No poke names a plate, a cup, a spoon, a fork, a knife, food or water.
- Pair pictures use `afuera` (a market stall), `estufa.horno`, `florero`, `pano`, and `alza` on anybody.

### Reviews

- Script: draft 1 (beginner: all three "not ready"; Spanish: six lines), draft 2 (beginner: every decision holds, three still "not ready"; Spanish: six small things), draft 3 to a last gate (26 ready; 24 and 25 one rule each) and a final Spanish check (nothing to fix). What changed is at the end of the script.
- Wordless frames: two fresh readers, one after the other; the second read the redrawn pictures. Both could follow the stories. Redrawn after them: the messes of 24, the knife, the spaghetti, the cloth and its heap, where mamá and the baby sit, how a thing is held up, the fallen glass, a mat for the frog. The list is at the end of the script.
- The biggest mistakes caught: a wrong answer that cost nothing in the world (24); things nobody kept count of (25: who has which; 26: plates that never ran out); the same story twice (24 and 25); a free poke that named the answer; pairs solved by an old word.

### Testing

- 68 machine runs: each story all right, all wrong and every single miss, over four sets of draws; 44 of them again after the pictures were redrawn. All end, with the stars and crosses and the end state they should have. All 104 picture pairs, the level check with every item shown, and the app check.
- With the recorded lines in place a story takes 2 to 3 minutes by machine at six times speed: give the test tool 4 minutes a run.
- Found by testing: the baby took the touch meant for mamá; six plates could not stay apart at 24 pixels a place (plate in front, cup behind).

### Audio

- 138 new lines, about 4,100 characters. Azure so far this month: about 36,600 of 500,000 characters (my own running count, not a reading from Azure).

## Nov 14, part 14: Escuchar for El parque, first set

Live at ?v=29. Script (final): historia/notas/guiones/escuchar-parque.md, with what each review changed at its end. Generator: historia/tools/gen_escuchar_parque.py.

### What is built

It is in the Library tab under "Listen · El parque", the same three parts as La casa (part 8 below): the twelve map stories told straight through (Otra vez; nothing to build, the three bench stories were checked in that mode), five new picture stories, four do-this routines.

| Piece | Scene | What happens |
| --- | --- | --- |
| d-corre, ¡Corre! | El camino | a race to the big tree; Canelo goes after a cat instead; Carmen wins |
| d-bola-canelo, La bola de Canelo | El campo | Canelo takes Luis's ball and will not give it back, until he sees another one |
| d-pato-pequeno, Pan para el pato pequeño | El lago | the two big ducks beat the small one to the bread twice; the frog feeds it from the end of the dock |
| d-piragua-luis, La piragua de Luis | El banco | Luis's piragua falls; Carmen gives him hers; the frog buys two more; a pigeon eats the fallen one |
| d-vamos-a-casa, Vamos a casa | El banco | night; everybody goes home; Canelo is too tired to move, until abuela bounces a ball |
| h-camino, En el camino | El camino | touch the dog, the cat, the big tree, the tree with three birds; run and wait (doing bubbles) |
| h-campo, En el campo | El campo | "Toca mi bola." / "Toca tu bola."; catch, jump, throw (doing bubbles) |
| h-lago, En el lago | El lago | ducks and boats by colour; who flies; where the fish is |
| h-banco, En el banco | El banco | señor, joven, señora; who drinks, who is tired, who sleeps |

- His rule for listening ("they hear a bunch of words and focus on the words their learning") applies to the picture stories: they are built on the words he has met and carry seven others by their pictures (gana, otra, canasta, su, se cae, piragüero, luna). The routines stay inside his words, because there he must act on what he hears.
- In a routine, not every answer in a group is asked for, and one may be asked twice: so the last line of a group is never the only one left.

### New in the engine and the scenes

- Nothing new in the engine. `W.respEn` (part 13) is set by the path and field routines too, so the bubbles do not hide Carmen or the cat.
- Each park scene got a few plain acts for Escuchar, so that a picture story can be written in the generator without new code for each beat. banco.js: g (set anything on a person), anda (walk; `suelto`: the line is said while he walks; `lento`), saluda, rana, encima, can, pal, cosa, rueda, rebota, luz (night, with a moon), manos, hace. lago.js: tirapan and gana (bread on the water and the ducks' race for it), patoa, cuacp, mecebote, avea, suelta, dip. campo.js: alta (a high ball and the frog's jump), perro, saluda, ranaa. camino.js: ranaa (the frog alone to a stone), sacude, and `queda` / `fin` on cuenta (the three fingers stay up while the line is said).
- banco.js at night (`W.noche`): the sun is painted over and the picture darkens; `W.luna` draws a moon.

### Reviews

- Script: draft 1 (beginner and Spanish), draft 2, a last gate, then the Spanish of the final lines again. The big changes: three picture stories retold map stories and got turns of their own (story 3 twice); draft 1 held the picture stories to his word lists, against his rule; three routines could be done without the Spanish; any grown man is "un señor" in Puerto Rico, so the piragua man counts for "Toca al señor."; "¡Corre!" said to three runners was a grammar error ("¡A correr!").
- Wordless frames: two fresh readers (stories, routines). Fixed after them: see the end of the script.

### Testing

- Every picture story end to end. Every routine all right, all wrong and mixed. The three bench stories in the straight-through mode. The app check.
- Found by testing: two asks in a row with the same answer stall the test tool (the routine was reordered); a child holding a ball takes the touch meant for the child (a touch on either counts: `alias`); a ball Canelo has taken lives in his pile under another name (pila0).

### Audio

- 141 new lines, about 3,500 characters. Azure so far this month: about 32,500 of 500,000 characters (my own running count, not a reading from Azure).

## Nov 14, part 13: place 2, scene 4, El banco. All twelve stories of El parque are built.

Live at ?v=28. Scripts (final): historia/notas/guiones/banco.md, with what each round of reviews changed at its end. Generator: historia/tools/gen_banco.py (stories, pairs; it also sets cual's `next`).

### What is built

- **The benches** (historia/escenas/banco.js): three benches in a row, a piragua cart on the left, a lamp post behind, a wire across the top where five pigeons sit, a hedge with a gate at the right edge (the way home). People in `W.gente` (the man, the woman, an old gentleman, a young man, a lady with a pushchair, the piragua man, abuela standing or sitting): `animo` draws a feeling on the face (triste, cansado, contento), `hace` holds a thing at the mouth (come, bebe), `lleva` and `lleva2` hold things low, `lee` a newspaper, `sin` what he has left behind. Pigeons in `W.palomas` (on the wire, on a bench back, pecking, drinking, flying). Things in `W.cosas`. Dogs in `W.perros` (canelo; viejo: grey, white muzzle; joven: white with black patches; poses for sad, tired, asleep). The pushchair in `W.coche` (hood up or down; the baby asleep, crying, laughing). What the frog holds: `W.bandeja` (a tray on his head), `W.encima` (a thing on his head), `W.manos` (one thing in each hand).
- **Story 21, La piragua** (hombre, mujer, come, bebe). A: a pigeon pecks at the man's piragua or has its beak in the woman's bottle; he warns them: "¡El pájaro come!" / "¡El pájaro bebe!". B: "La piragua es para la mujer." (or el hombre, el niño, la niña): touch one of four. C: a pigeon lands behind him; "Carmen dice: ¡Come, Coquí!" / "¡Bebe, Coquí!": eat or drink (doing bubbles). Stake: a pigeon that gets food does not go back to the wire; it settles on a bench.
- **Story 22, ¡Señor! ¡Señora!** (señor, señora, joven, viejo). A: "¡Es del perro viejo!" / "joven": which dog gets the bone. B: somebody drops a wallet and walks to the gate; he calls "¡Señor!", "¡Señora!" or "¡Joven!". C: "¡Es del señor!" (a paper bag): touch one of the two who are left. Stake: the thing goes into Luis's box of lost things; on three stars the man from story 21 comes back for the newspaper he left at the turn.
- **Story 23, El bebé duerme** (cansado, contento, triste, duerme). A: the hood is down; "La señora dice: El bebé duerme." / "El bebé está contento.": keep still, or sing. B: "Abuela dice: ¿Cómo está Canelo?": he says contento, cansado or triste. C: "¿Quién está cansado?" (triste, contento): Canelo, Luis or the man. Stake: each miss ends in a noise; the baby wakes and throws a toy out; the toys stay on the ground.
- **¿Cuál? pairs**: 12 in cuentos/cual-banco.json. **Level check**: four more items (come, señora, viejo, triste); 36 in all, 23 stories.

### New in the engine

| Piece | What it does |
| --- | --- |
| `"callado":true` on a story | stars only for a right move: no chime, no hop, no "¡Sí! ¡Muy bien!" (a baby sleeps) |
| `W.respEn=[x,y]` set by a scene | the answer bubbles stand there, and not over the frog: here, in the sky, so that nobody is hidden while he chooses |
| an act may set `V` | story 22's last round is drawn among "the two who are left": the act `cola22` works out who they are and puts their ids in `V.ra`, `V.rb`, `V.pc` |
| a draw may repeat an option | `["hombre","mujer","hombre","mujer","nino","nina"]`: the grown-ups twice as often |

### Reviews

- Scripts: three drafts and a last gate (beginner against his requirements, Puerto Rican Spanish, both twice). The big changes. "Viejo" said of a person is blunt, so it is taught on a dog and people are "señor", "señora", "joven". "El piragüero" does not speak ("señor" not yet taught). Commands are "¡Come, Coquí!" (the name after), so they are not heard as "Coquí eats". A crying baby is not "triste". "No duerme" let old "no" decide, so the lady says "duerme" or "está contento". Somebody "walking away" cannot be caught or missed with no clock, so there is a gate where each one stops. At the turn of story 21 he had done as told and was punished for it. Touching Luis for "cansado" was wrong although Luis had been taught as the tired one. A right answer in the game ("¡Está cansado!") had never been the signed one.
- Wordless frames: three fresh readers (one a story), then two more on the fixed frames. Fixed after them: see the end of banco.md. The biggest: the answer bubbles covered the people and birds the choice was about; "keep still" drawn as a raised hand read as stop or wave, and notes read as Z's; feelings were too small to read; the old dog read as a donkey.
- Honest limits, told to Salim in page 00: story 21's "hombre" / "mujer" round can be done from "el" / "la" and the old words.

### Testing

- Every story: all right, all wrong, mixed both ways, with every draw forced (64 runs). All 92 picture pairs. The level check. The app check.

### Audio

- 116 clips recorded, about 2,950 characters (two of them, about 70 characters, are lines that were changed after the job had recorded them). Azure so far this month: about 29,000 of 500,000 characters (my own running count, not a reading from Azure).

## Nov 14, part 12: place 2, scene 3, El lago

Live at ?v=27. Scripts (final, draft 3): historia/notas/guiones/lago.md. Generator: historia/tools/gen_lago.py (stories, pairs; it also sets otra-vez's `next`).

### What is built

- **The pond** (historia/escenas/lago.js): pale water, a dock on the left with a post at each end, a post in the water, a clump of tan reeds in the middle, the far bank along the top (a child can stand there). Ducks in `W.patos` (white, black, a small yellow one; they paddle, fly, walk), fish in `W.peces` (any colour; just under the water, or jumping), birds in `W.aves`, toy boats in `W.botes` (`en`: muelle, agua, carmen, juncos), a row of bread `W.fila`. Things that keep moving while he chooses (a bird flying round, the duck paddling round the post, a fish circling, boats under way) are moved by `anima()` in the draw.
- **Story 18, Pan para el pato** (pato, pez, pájaro, nada, vuela). A: "¡Pan para el pez!" (touch one of three). B: "¿Quién vuela?" / "¿Quién nada?" with the bird in the air, the fish in the water and the duck on the bank (the duck does both, so a touch on it is a free poke). C: Luis, head down, asks "¿Y el pato?"; he says "¡El pato vuela!" or "¡El pato nada!". Stake: six pieces of bread in a row on the dock; a wrong round uses two; what is left is shared out at the end.
- **Story 19, Los botes** (rojo, azul, verde, ¿de qué color?). A: "¡dame el bote azul!". B: a fish circles; Luis, head in his bag: "¿De qué color es?"; he says the colour; Luis paints a boat that colour and the fish pushes it across. C: "¡Ahora dos botes! Uno verde y uno rojo.": two touches on pots of paint (picture bubbles). Stake: a boat nobody blows or pushes drifts into the reeds and stays.
- **Story 20, ¿Cuál?** (amarillo, blanco, negro, ¿cuál?). A: "¿Cuál es el pato negro?". B: a bird takes Carmen's bread; "¿Cuál pájaro?"; he says which. C: "¡Pan para el pato!" (which is not said: he must ask "¿Cuál?", a bubble beside the ducks) or "¡Pan para el pato blanco!" (touch it). Stake: the three ducks' place out of seven; noise sends them out.
- **¿Cuál? pairs**: 11 in cuentos/cual-lago.json. **Level check**: four more items (pato, vuela, rojo, negro); 32 in all, 20 stories. A right answer now moves him up by `PASO` items (the list length over 14, at least 2), so the check still reaches the top in about a dozen items as scenes are added.

### New in the engine

| Piece | What it does |
| --- | --- |
| `"burbujas":[...]` on a touch decision | speaking bubbles that stand beside the things he can touch (the "¿Cuál?" bubble); their lines come from `voces` |
| `"gratis":{option:[steps]}` | an answer that is neither right nor wrong: its steps run and he chooses again |
| a rule | `$name` in a story file only takes letters: a variable called `o1` is never filled in |

### Colours

- rojo is a light orange-red, azul a middle blue, verde a dark yellowish green: they differ in lightness too, for eyes that cannot tell red from green. The water is pale so that blue things show on it; the reeds are tan so that a green boat shows against them.

### Reviews

- Scripts: three drafts and a last gate. Round 1: story 18 repeated story 16's hiding trick; a step of story 19 could not happen (a cart of boats); the "¿Cuál?" decision punished asking; "¿Dónde está el pato?" answered by "vuela" taught verbs as places; "El pato nada" is heard as "the duck, nothing"; a bare "pato" called out is an insult. Round 2: the duck both swims and flies, so "¿Quién nada?" had two true answers; "¿Cuál?" was free and so decided nothing; five places were too few to show every loss; a loss had no cause. Last gate: asking when already told had a silent penalty (now a bird takes the bread from his hand); eight signed touches in story 19 (now six); the fish must push the boat, or Luis's question is not real.
- Wordless frames, fresh reader. Fixed after it: bread too small to read (now a slice with a crust); the duck lost in the reeds and the ducks overlapping them (the reeds moved up to the far side); the fish and far ducks so low that the sign was cut off; the three different "wrong" marks on the card, none of which was read (now one red cross; the picture itself shows what went wrong); green too close to blue when the picture dims; Canelo and Carmen overlapping. Left as it is: the speaking bubbles look alike; birds and boats that "appear from nowhere" between two frames.

### Testing

- Every story: all-right, all-wrong, mixed both ways, every draw forced. The path "asked ¿Cuál? when she had said" by its own script. All 80 picture pairs. The level check. The app check.

### Audio

- 121 new clips, 3,418 characters. Azure so far this month: about 26,000 of 500,000 characters (my own running count, not a reading from Azure).

## Nov 13, part 11: place 2, scene 2, El campo

Live at ?v=26. Scripts (final, draft 3): historia/notas/guiones/campo.md. Generator: historia/tools/gen_campo.py (stories, pairs; it also sets rapido-despacio's `next`).

### What is built

- **The field** (historia/escenas/campo.js): open grass, one tree with a fork, Canelo's spot under it, the bank down to the pond with reeds and water. Luis, Carmen, Canelo. Balls live in `W.bolas` by name: `{k, x, y, z, con, vis, flota, vuela}`; `con` is who carries it (a person, "cq", "perro"). Three kinds, told apart by size and pattern: L (Luis, big, stripes), C (Carmen, dots), q (the frog's, small, star). A basket supplies new small balls.
- **Story 15, La bola** (bola, tiene, tira, coge, dame). A: Luis calls throw or catch (doing bubbles). B: who has the ball, behind their backs ("X tiene" / "X no tiene"). C: he sees who has it and says "¡Dame la bola!" or "¡Coge la bola!". Wrong: Canelo takes the ball to his pile.
- **Story 16, ¡Arriba! ¡Abajo!** (arriba, abajo, salta). A: Luis calls "¡Por arriba!" or "¡Por abajo!" and throws. B: the picture goes dark, the ball is hidden, Carmen says where; he touches the tree or the reeds. C: he sees where it lands and tells Luis. Wrong: the ball ends in the pond and floats there.
- **Story 17, ¡Otra vez!** (mi, tu, más, otra vez). A: "tira mi bola" / "tira tu bola", by Luis or Carmen; he touches one of three balls. B: "¡Otra vez!", "¡Dame la bola!" or "¡No más!" (throw, give, hold). C: he sees which ball Canelo has and says "¡Es mi bola!" or "¡Es tu bola!". Wrong: wet Canelo shakes himself beside the frog; the puddle grows.
- **The card in the corner** (`W.tarjeta="rondas"`, `W.marcas`): three places; a star for a round done right, the mark of what went wrong otherwise (paw, splash, drop). Added because a right move left nothing to see. From El lago on, a round that went wrong is one red cross: a fresh reader could not read the small pictures.
- **¿Cuál?**: 11 pairs in cuentos/cual-campo.json. "Otra vez" has none (a still picture cannot show "again").
- **Level check**: four more items (tira, coge, arriba, mi); 28 in all, 17 stories.

### New in the engine and the kit

| Piece | What it does |
| --- | --- |
| `"tests":"-"` on a decision (also through `palabras`) | nothing is filed in the word records: no word decided it |
| kit.js: `KIT.mkPerro`, `mkCesta`, `mano`, `tarjeta` | the dog, a basket, the raised hand and the corner card are shared by the park scenes |
| campo.js helpers | `vuela(name, target, height)` (a ball flies or rolls to a place or into hands), `roba` (Canelo takes a ball to his pile), `alagua` (a ball rolls into the pond), `nueva` (a new ball from the basket), `sacude` |
| a quirk | the kit draws the "offer" arm on the far side; campo.js turns it to the side the person faces |

### Reviews

- Scripts: three drafts and a last gate. Round 1: a right move left nothing on screen; the ball count could run out; five of nine decisions were the same kind; a decision staked only old words; bare "No. X" corrections can be heard as the opposite ("No. ¡Tira!" = "no tira"); "campo" is the countryside in Puerto Rico. Round 2: balls not accounted for step by step; the two taught "who has it" rounds had the same answer; only the tree, not the reeds, had been touched under the sign; "no" alone decided story 17's second decision; corrections said after they had stopped being true. Last gate: a ball other than his own had never been touched before it could cost; seven picture pairs could be done without the word (the fitting picture was always the lively one).
- Said plainly to him: "tiene" and "más" decide nothing in the stories ("tiene" is heard a dozen times; "más" has its pair).
- Wordless frames, fresh reader. Fixed after it: the frog's ball looked like a coin or a flower (now plain yellow with a white line); the catch, throw and "up" answer pictures looked alike (each now has its own arms and arrow; "up" and "down" are the frog stretched tall and crouched flat); people stood on the frog; Canelo was cut by the edge at the start of story 16; the dark of the hiding game read as night (the frog now stays lit, eyes shut); the "salta" pair (Canelo now jumps over a ball). Left as it is: the speaking bubbles look alike (he picks by ear); the "mi" and "tu" pairs differ in more than one thing.

### Testing

- Every story: all-right, all-wrong, mixed both ways, and every draw forced both ways. All 69 picture pairs. The level check (all items; a 17-story pass). The app check.

### Audio

- 118 new clips, 3,210 characters. Azure so far this month: about 22,500 of 500,000 characters (a sum of the counts printed by the generators, not a reading from Azure).
- Minutes, measured by machine with sound: about 2.5 to 3 a play for each story.

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
