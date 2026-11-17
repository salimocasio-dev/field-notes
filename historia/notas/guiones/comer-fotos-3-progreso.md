# A comer, picture fixes round 3 (Nov 17): progress

Brief: scratchpad comer_fix_brief3.md (A1-A8, B story 33, C story 34, D story 35, E pairs). Point by point; "commit" = the commit that holds it (git log has the ids). The Spanish lines, the clips and the clip list are untouched (gen_comer.py: 1691 clips, 3190 characters, 0 clashes; its only change in the stories is `mira34 a="$qt"` and the pair data).

## Tools
- reposo.py: a frame is kept when who speaks changes (the empty speech bubble is part of the picture; that is why customers never showed it: the picture did not change, so no frame was kept); one more frame at the end of every run: the last picture with the story's title under it (the end card). The runs did stop at their true end (the last picture of que-quieres_ww and cafe-con-azucar_ww is the ending); the sheets had 60 pages of twelve, which is where 719/720 came from. Nothing in reposo.py capped the count.
- window.__dev (comer.js) gives COSA and cosaIm to a preview script.

## A. Across all three stories and the pairs
- A1 arms and hands: upper arm in the sleeve (4 px, 3 for a child), forearm bare skin (3 px) so that it shows against the body and what it holds, hand 4 x 4 with a dark edge drawn over the handle or rim; sleeves a shade darker than the shirt; abuelo in a green shirt (cream on cream before). Things are carried low and in front (tray at the belly, platter and pot low, cups at the chest); nothing is held over a face. (commit 1: 791af61)
- A2 nothing fills, empties or moves in one frame: rolls and rice are eaten in three bites / forkfuls (the roll gets a bite, then half, then is gone; the rice on the plate goes r, r2, r1, clean; crumbs stay), every state held at rest; the frog eats his mound in three bites; cups are drunk in two sips (full, half, empty); pours show a stream over several frames and the cup fills in two stages; the pot of rice goes lleno, m3, m2, m1, vacio at every scoop; the spoon goes from the pot to the plate or the platter in view with a rest over the plate; plates are carried by a hand. (commits 6590286, 1c95c54)
- A3 the one who holds a thing stays in view: nobody walks along the back lane in front of a seated face any more (the lane is at y 128, drawn behind the seated heads), abuela pours from beside the men or from in front of the table (never from a row inside the table, where she was hidden), the way along the front of the table runs below the frog.
- A4 speaker marker: reposo.py (see above); the marker is bigger, with a tail, stands to the side of abuela at the stove and of the frog while a thought is over him.
- A5 sizes: one roll size (17 x 12) for basket, board, hand and plate; cups 17 x 17; coffee pot 18 x 21, greca 14 x 16, milk pan 21 x 11, rice pot 24 x 21; forks 15 tall (12 without the forkful), spoons forearm long, the big spoon's bowl 9 x 7 (smaller than a head); mounds 10 x 8; the platter 52 x 26. (commit 1)
- A6 thought clouds: outlined cloud of round lobes, two small round circles leading to the one who thinks, standing where it covers nobody (34: left of the frog over the empty chair; 35: right of him between the men). (commit 1, positions 6590286)
- A7 capture to the end: see Tools.
- A8 the frog is never hidden by pots (they stand to his left or in front of nothing), nobody stands cut by the frame edge (the platter waits at x 196 on the stove, abuela's stool is inside).

## B. Story 33
- Speaker marker for every "X dice" line: A4.
- Luis eats his roll at his place (back left corner of the table, by his plate), in three bites, crumbs on the plate; Carmen likewise at the back right corner. They hide neither the board nor the basket nor anybody.
- Every redo roll is eaten by the one it is for (the same eating routine); rolls are one size; the tray's rolls slide off its low edge into the basket (abuela tips the tray from the left end of the table, her face over the tray).
- People walk behind the seated (never a face over a face); abuela's steam over her face is gone (no steam on the carried tray); her plate stands a clear gap from the basket, in view; seated people's arms are bent with the hand at the plate.
- The frog holds one spoon, in his left hand, all story; a roll he fetches from the basket he carries in the same fist as the spoon. Askers in the rounds with one line take a roll, hold it up open and empty for a moment at rest, set it on the board and go out.
- Papá and Carmen at the turn stop, look at the full basket (a hand towards it, a nod), then go out. The cloth is laid over in two moves. Abuela's plate: she lays her roll on it, carries the plate with the roll to her chair and eats there.

## C. Story 34
- The full thought: the frog with a big round belly, his hands on it, eyes shut and a smile, beside his clean plate (`barriga`), in an outlined cloud over the empty chair to the left of him (nobody under it); the want thought is the mound with a heart.
- Eating with forks: every eater holds a fork from the first picture, lifts it at step 2, takes forkfuls to his mouth (the rice on the plate goes down by levels), then lays the fork down by his plate; Luis, papá, mamá, abuelo and Carmen eat forkful by forkful, the frog eats his mound in three bites. Forks are 12 px tall.
- The turn: abuela takes the platter from the stove (it waits at x 196, inside the picture) low in both hands and carries it along the front, below the frog; Luis gives her the big spoon; she lifts the pot with one hand low at her side and the spoon in the other, and serves the three plates from behind the table (the spoon waits loaded over each plate for a moment); she sets the pot down in its place and scoops seven mounds onto the platter (four helpings at the left, papá's three at the right, a plain gap), the pot going lleno / m3 / m2 / m1 / vacio with the scoops; the fork is laid flat on papá's three with the spoon; she lifts the pot and tips it towards us (empty), gives the spoon back to Luis and walks out with the pot.
- Papá's serving: she carries the platter behind the table to his chair, tips it over his plate and his mounds go onto it one at a time (the platter shows the count: 3, 2 or 1); he takes the fork and eats forkful by forkful.
- Wrong A (full): the frog stays swollen on his back until the beat, then back to size; Luis turns his head to papá's fork and his spoon takes one mound from papá's end (the platter shows one less). Wrong B: the full one puts a hand on his belly and pushes the plate away, held for a moment; the one who asked looks at the platter (`mira34 a="$qt"`).
- Carmen / the one who gets up in the game carries his plate to the counter (not when the plate holds the heap), then goes out; the high chair is on the floor at the left end, in front of the counter and away from the plate's place on the counter top.
- The big spoon: handle in the hand, bowl 9 x 7. The baby in mamá's hands is the baby of the chair. Nobody passes in front of a seated face.

## D. Story 35
- The thought over the frog is an outlined cloud, to the right of him between the men, away from the children. Four cup colours (black, dark brown, light tan, white) and an empty cup that shows its dark inside; a held cup shows what is in it; half-full cups (`_`) are used for sips and pours.
- Sugar: the bowl is green with a heap of white sugar and one spoon; the frog takes the spoon out of it, dips it, brings it to the cup, grains fall in three little falls, he stirs, the spoon stays standing in the cup (2 px thick, silver). At the turn abuela brings the bowl to each man behind the table and he takes the spoon from it himself, sweetens his own half cup, tastes it and nods.
- Wrong B: the frog lifts and tips the cup, makes a big sour face and sets the cup down by him, full and the wrong colour; the face stays while the cup stands. Abuela then takes her own cup off her stool and drinks it off in sips (full, half, empty), "ah", a hand on her chest, holds the empty cup up, then walks to the little pot and the pan, takes each, tips it towards us and sets it back.
- Abuela's stool is inside the picture and in front of the table's plane; her cup goes on the stool when she gets up, and she takes it again when she sits. She pours from beside the men (behind the table, drawn behind them) or from in front of the table; one pot at a time. Canelo sits up, walks to the bowl, laps (the milk goes down in three levels), walks back and lies down.
- Short steam: none on held cups.

## E. Pairs
- Arms and hands everywhere (A1); cups, jug and glass hand-sized (cup e 1, glass e 1, jug e 1); the coffee pot and the jug stand on the table.
- ¿qué quieres?: two silver serving spoons, handle up from her raised hand, bowl in each pot.
- no me gusta: both pictures kept closer (2x crop) with the counter behind; right a plain frown (brows down, mouth down, eyes open, no cross), other a calm face with a straight mouth, one hand on the belly and one pushing the plate.
- rico: abuelo keeps his glasses in both; right: eyes shut inside the lenses, a forkful in his mouth with his fork in his hand, the other hand on his belly; other: small puffed cheeks, a round mouth and a breath towards the steaming forkful held in front of it; the cake on its plate inside the frame; the stove behind him.
- buen provecho (other): the striped box and the blue circles are gone; the plates are held by arms.
- azúcar: the stream is 4 px wide, white, bends out of the lip and splashes; steam from the cup's top. un poco: the bowl and the handle of the same silver spoon show in both pictures (the heap stands in the bowl, the lip drawn in front).
- Not done: the brief asks for the closer pictures (4 and 5) at the same pixel size as the others. The pictures are crops of the one canvas scaled up by the ¿Cuál? page (juego.js and cual.js are the engine), so a close-up is always blockier; I kept the 2x crop and showed the kitchen behind. A real fix needs the scene drawn at a higher resolution for the pair (a cual.js change): proposal only.
