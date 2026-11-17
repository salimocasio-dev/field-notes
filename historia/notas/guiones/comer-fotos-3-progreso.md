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
