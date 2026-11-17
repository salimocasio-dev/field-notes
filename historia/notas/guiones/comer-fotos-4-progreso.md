# A comer, picture fixes round 4 (Nov 17): progress

Brief: scratchpad comer_fix_brief4.md (A across the three stories, B story 33, C story 34, D story 35, E pairs). Point by point; the commit that holds each is in git log. The Spanish lines, the clips and the clip list are untouched (gen_comer.py: 1691 clips, 3190 characters to record, 0 clashes, no MISSING TURN LINE; the only change in the stories' beats is the order of two acts in 34, wrong answer A: Luis takes his mound first, then the frog gets up).

## Tools
- reposo.py keeps a frame at every change of state (STSIG: a bite, a sip, a lap, a pour stage, the level of rice on a plate, what a spoon carries, a hand that appears, the mounds on the platter, the frog's belly and fall, who speaks, which answer card is lit). The lit card (W.respOn) is part of the picture: a frame for each card lit in turn and one at rest, neither lit. That is why the readers of round 3 saw the left card lit at every choice: the engine does light each card while its voice plays and leaves both grey after (juego.js respDraw), but a rest-only capture kept only the first. No engine change is needed.
- Walks: the moving hands and things also count in PASO (gx/gy of a hand).

## A. Across all three stories
- A1 every bite and sip: reposo.py (above). The bites, sips, laps and pour stages themselves were already acts; now every one is a frame.
- A2 feet: nobody is seen with his feet above the floor outside the table. Behind the table the cloth hides him from the waist down; to go there he walks on the floor to the end of the table, in under the edge of the cloth and up to the lane behind it (detras / delante in comer.js); the lane behind the seated is a lane higher (ATRAS 122), so a walker's head is over theirs. A walker's hands and what he carries are drawn behind the seated, not over them. The children of 33 stand at the back corners inside the cloth. Abuela stands in front of the stove on the floor (FOGON 168) and steps up to the stove only to take or put (AFOGON 153).
- A3 sizes: plate 15 wide (a little wider than a roll, narrower than shoulders), child's plate 13, the frog's 12; roll 11 x 7 with its edge (a head is 13); tray 26 and platter 28 (as wide as abuela); the big spoon's bowl 5 x 3 (a fist is 6 x 6) with a 2 px handle a hand long; mounds 5 x 4; dishes 22 x 15; the basket 36 x 21 with the rolls above its rim.
- A4 hand-offs in view, both hands on the thing for a moment: the roll from the asker to the frog and back (33), the spoon abuela to Luis, Luis to the frog, the frog back to Luis, Luis to abuela and back (34); abuela's lifts of pots and trays are by a hand at the handle.
- A5 paths: the ways round the table end are fixed (see A2); Canelo and his bowl moved to the left front (35), the high chair to the right end in front of the stove (34), the stool stays; nobody crosses the table legs (they walk below them, at y 208).
- A6 nobody cut by the frame edge: the high chair and baby (34) inside; the counter plate (34) at x 58; the askers (33) at 52 to 58; the dog (35) inside.

## B. Story 33
- Abuela's plate: she stands behind it (long arm, p.L 12 for the moment), a hand on its far rim, and slides it along the table top from her place to beside the basket (112, 138). At the end she lays her roll on it from the front of the table, takes it in both hands and carries it round the end, along the lane, sets it at her place and sits.
- The tray: 26 wide, carried at her belly with both hands, along the lane behind the seated (drawn behind them), round the left end to the basket; the rolls slide into the basket.
- The patch on the basket: the folded cloth is now a small striped towel on the left rim of the basket, inside its outline (no table check any more).
- Steam only while the basket has rolls.
- The frog: no plate behind his head (the plate stands beside the basket at the back, his place is lower); he waits at the left end, takes a roll from the right of the basket, fills it in his left hand with his spoon (right hand), the roll held out to his left (a gap from his body).
- The askers stand to the left of the table end, on the floor, clear of the basket and the table's leg; the roll goes from hand to hand there (no board any more).
- Children at the back corners (72, 138) and (178, 138): inside the cloth, the cloth hides their feet. Granny and the woman: they walk on the floor and in under the cloth.
- Abuela's arms reach the plate; the tray does not hide her face (carried at her belly); no post under her feet (she walks below the legs).
- Rolls smaller than a head, plates a little wider than a roll (A3).

## C. Story 34
- Cards: reposo.py (above).
- The full thought: a fat frog (belly twice as wide as his head), eyes shut, smiling, both hands on the belly, his clean plate beside him; in a cloud 56 x 42 over the empty left of the table, above the heads (nobody under it).
- One big spoon only: Luis no longer gets a second one when the frog holds it. The hand-offs are in view. At rest the spoon hangs low at his side.
- The frog eats at his plate with his fork (it lies by the plate; his hand takes it; three forkfuls, the plate goes o, o2, o1, empty).
- Abuela carries the platter at her belly in both hands, low, along the front (28 wide); the pot stays on the table while she serves (she reaches over the table with the spoon; the pot is lifted at the end from its right side, tipped, and she and it leave together).
- Serving papá: she sets the platter down in front of his plate (no tilt), moves each mound with the big spoon, then his fork; the platter goes back to the stove.
- The frog clear of the pot: his plate and place moved right (150 / 172).
- High chair and baby: at the right end, fully inside; mamá takes him out with both hands and puts him back over five frames.
- Shoes behind the table: A2. Carmen takes her plate to the counter: she stands in front of the cabinet (floor), sets it on the counter top (visible, x 58), it stays while she is away.
- The frog's speech bubble is always over his head; the stars of a sign over an answer fall above his head, not on his face (COSAS entries di_buen, di_tambien, di_lleno, di_poco, di_mucho).
- ww: the mounds of the platter are all in view (the fork lies along the back rim, above papá's three); the frog's belly swells over three frames, he tips over on his back over two more and stays swollen until Luis has taken his mound (gen_comer.py order), then deflates the same way; hops are several small hops (about 26 px each); abuela's spoon hangs low; the platter on the stove is smaller than the stove top; the thought bubble covers nobody.

## D. Story 35
- The thought of round B: the cup he gets when right (poco light tan, mucho dark brown); it was an empty cup because the draw's value ("poco", "mucho") was not a cup colour.
- Cups: an empty cup shows its own light glaze (no liquid); black coffee near black with steam; milk bright white; sugar is off-white with grains in a heap, milk smooth white.
- Teaspoons: each man has his own lying by his cup; the frog's big spoon only carries sugar and goes back into the bowl; the man stirs with his own teaspoon and leaves it standing in the cup; with the cups drunk empty each man lays it down; at the turn each man takes the big spoon from the bowl himself, puts it back, stirs with his teaspoon.
- Canelo and his bowl at the left front; the stool, the stove and the way between them are clear; abuela's cup and the greca have a gap between them; the sugar bowl and the frog's cup are clear of each other.
- Pours: abuela stands beside the cup (never in front of it); the thought bubble sits over the empty left of the table.
- Abuela's feet: she walks on the floor round the end of the table (detras / delante), never over the oven door.

## E. Pairs
- rico (5): the plate stands on the table edge; the hand lies flat on his belly (a hand, not a strap).
- buen provecho (6): the three apart, each plate held in two hands at the chest; the girl and the boy at the counter on the floor.
- quieres (1) and ¿qué quieres? (2): the question marks right over the head of the one asked; the boy's two hands on the plate's rim; the serving spoons brown with a small bowl in each pot.
- azúcar (10): the milk jug lower, at the cup, the stream leaves the spout.

## Not done / for fresh eyes
- Some hands are 2 to 8 px beyond the arm (reposo.py prints them): abuela's long reach over the table for the slide and the serving, the men's teaspoons, a few pours of 35.
- In 34 abuela reaches over the table with a long arm to serve the three plates (the plates are at the back row); a fresh reader may find the arm long.
