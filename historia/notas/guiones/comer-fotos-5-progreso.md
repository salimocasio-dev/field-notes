# A comer, picture fixes round 5 (Nov 17): progress

Brief: scratchpad comer_fix_brief5.md (A across the three stories, B story 33, C story 34, D story 35, E pairs). Point by point; the commit that holds each is in git log. The Spanish lines, the clips and the clip list are untouched (gen_comer.py: 1691 clips, 3190 characters to record, 0 clashes, no MISSING TURN LINE). The only change in the beats of the stories is one act name in 34, step 5: `limpia34` (Carmen eats her last forkful in view) in place of `plato34` (her plate cleaned in one frame).

## A. Across the three stories (comer.js)
- A1 one rule for the layers, in `draw()` (`capa`, `detrasMesa`): whoever is behind the table (not seated, feet above the table's near edge and between its two ends) is drawn behind everybody who sits, together with his arms and everything he holds; the cloth then hides what is below its far edge. Seated people and the children at the corners have their hands over the cloth. It is the same for every scene and every frame; no scene orders its people any more. Where a person has to put something on the table from behind (abuela with her plate at her chair, 34's serving) he stands in the plane of the seated (`est`).
- A2 reach: nobody reaches across the table. `detras` now chooses the end of the table by where the person is going (before, by where he stood: that is how Carmen's arm and roll slid across the whole table top with her body under the cloth), so everybody walks round with what he carries, body in view. Abuela's long-arm moves are gone: in 33 she slides her plate from in front of it (a short slide, within her arm) and, at the end, walks round with the roll; in 34 she serves the three plates and papá's mounds from behind the table, the pot or the platter in one hand and the spoon in the other. The frog tips from beside the plate, one hop away (`lado34`), the spoon only as long as its handle.
- A3 everything that changes, changes in view and in steps: standing up (`levanta`: the head goes up in steps 3, 6, 7 (upright), 10, 17) and sitting down (`sienta`: 4, 2, 0); the cloth over the basket (33: she takes the towel off the rim, holds it over the roll, lays it down, her hand goes back in three steps); the pot's level at every scoop (34: `olla` levels n1 to n7 over the 18 scoops: Luis's eight, the three small helpings, the seven mounds); the frog's swell and shrink (34: three belly sizes, each held 4 ticks, two more for the fall; the same back); a cup pushed to the middle (35: his hand on it, 4 steps); Canelo getting up (35: lying, sitting, standing, walking, 10 ticks over 30 px); eating and drinking (every bite, forkful and sip is held long enough to be a frame; the sips of the children are tilted and last 5 ticks).
- A4 thought bubbles right above the one who thinks, trail to his head, clear of the people and of the answer cards (they are at y 22 to 58): 34 `NUBE34`/`AIM34` (papá's chair, the empty one, is now the one at the right end, above the frog); 35 `NUBE35` (the men sit at chairs 1 and 4, the frog stands under the empty chairs between them).
- A5 hand-offs in view: the big spoon goes from abuela to Luis and back at the stove, at the right end (Luis walks along the front to her, she steps out to meet him, both hands on it, he walks back with it; nothing of the table behind them, no pot over her head).
- A6 every held thing in a fist with the arm in view: the baby's spoon in 34 is in his fist at the end of his arm (and lies on the tray when mamá lifts him out); Carmen's plate to the counter is carried from the floor in front of the counter; the children's cups in 35 are put down and picked up by a hand in view (put down in 6 steps and left there for 3 ticks).

## B. Story 33
- Frog's spoon: wooden, a plain round bowl (7 x 5).
- Standing up: A3.
- Cloth over the basket: A3; the folded towel lies on the rim; with one roll left the cloth is a small one over it (its end shows).
- Counts: the tray is a new sprite, 26 x 21, four rolls each with its own dark edge in two rows (it showed two before: the rows overlapped); four rolls go into the basket.
- The ending: abuela walks round with her roll to her plate (in front of it, within reach), lays it down, takes the plate in both hands, carries it round and along the lane to her chair, sets it down, sits, and eats the roll in three bites at her place (each bite and each chew a few ticks longer than before).
- The children stand at the table's back corners, in the plane of the seated, heads and shoulders above the cloth (they were 12 px lower, so only their heads showed), clear of the counter (it is 8 px narrower: it ends at x 68), the stove and papá; each by his own plate (Carmen's is 18 px from papá's, a plate-width of cloth between them; a refused roll is pushed forward, never sideways into a neighbour), facing outwards so that what they eat is never over a neighbour.
- Abuela's tray no longer covers the frog (he steps aside to the right of the basket for the refill, and she tips it from the left end); her head covers no dish (the front lane is lower, FR 212, and the dishes moved up to the table's front row between the frog and her plate: butter 112, chocolate 160; her own plate lies in the middle row, between the dishes' places and the basket, and she stands below the slot between the dishes).
- Layering: A1. Abuelo and mamá sit apart (chairs 1 and 3, abuela between them at the end); a seated eater holds his roll 8 px to the side, never over a neighbour. Abuela comes from the stove along the front: no two-frame jump from the stove to behind the table.
- The frog stands beside the dish he uses and clear of the other (the dishes are 48 px apart).

## C. Story 34
- Hand-offs: A5. Abuela holds the spoon up in front (bowl and handle plain) while she waits for Luis.
- Fat frog: A3 (verify in the captured frames: each step is a frame).
- Mounds leave the platter in the spoon in view (Luis's spoon goes to the mound, takes it, the platter has one less; at the end abuela's spoon goes to each of papá's mounds on the platter she holds, behind his chair, and moves it onto his plate).
- Pot level: A3; everyone eats in view (Carmen's last forkful before she gets up; the plates of the others go down forkful by forkful as before).
- Luis's spoon held out reaches the frog's plate (it goes to a point over the plate, and the frog hops to it).
- The frog tips from beside the plate (A2).
- Abuela's pot is carried at her side, never held up with nothing in it; her serving of the three plates is from behind the table; the hand-offs are at the stove, where nothing stands behind her.
- The girl's plate and hand: Carmen takes her plate to the counter from the floor in front of it (not from under the cloth, where her body was hidden); mamá takes the baby out from beside the chair, not in front of it.
- Papá's plate: three separate mounds (a small triangle, each with its own shadow), fewer as he eats.
- The say-cards are at the top; the thought cloud is over the frog, below them.
- The girl's hands: the seated children's arms use the same rule as everybody's (a sleeve and a hand at the plate).

## D. Story 35
- Colours seen from above: black coffee near black (#0C0806), much coffee a deep chocolate (#3A1A0A), a little a very pale milky coffee (#EBD3AC), milk pure white, an empty cup shows its own mid blue inside (#4A84E0). The bubble's cup uses the same two browns.
- Sugar: six white dots, two pixels each, fall from the spoon one after the other over about ten ticks; a small white heap lies on the coffee for five ticks; then the stir. The men's own spoons the same.
- The thought is above the frog (A4).
- Round A wrong: the frog is at the cup with the spoon before abuela pours (she waits for him), the grains fall while she pours, and the cup turns after both.
- The spoiled cup is pushed to the middle with his hand (A3).
- Canelo: A3. The children's cups: A3/A6.
- The little pot is set down to the right of the sugar bowl (it was on it), the frog's cup moved 4 px right; the sugar bowl, the greca and the frog's cup are clear of each other.
- The milk stream is 6 px wide (coffee 4).

## E. Pairs (gen_comer.py, comer.js)
- rico (5): abuelo's jacket is closed (a darker green zip and pockets; the tan details of the cream shirt looked like bare skin); the fork is a plain grey fork with a brown-and-cream piece of cake on its tines; the right picture: eyes shut inside the lenses, mouth closed with the fork at his lips, the other hand on his belly (an arm, no patch); the other: eyes open, small puffed cheeks with their own edge, a small round mouth, three breath dashes from his lips to the steaming forkful held in front of him.
- azúcar (10): a plain white jug (no band, an open ring handle), held by abuela at her chest by its handle, low beside the cup, a thick white stream into the cup; the cup sits on the table with a shadow under it in both pictures.
- un poco (11): a serving spoon with a plain round bowl (9 x 7); the small scoop a white mound in the bowl about a third of the big one.
- ¿qué quieres? (2): a spoon in each fist at her chest, the bowl of each in its pot.
- café (9): both hands round the cup.
- no me gusta (4): a closer crop that includes her arms and the plate (y 138 to 194): both arms to the hands on the bowl's rim.
- buen provecho (6): the three apart, each plate in two hands, inside the frame.
- todo (8): the dog stands with his head down in the bowl, his tongue in it.

## Not done / for fresh eyes
See the report; the layout of 34 (the pot, the platter and the people at the front) is the tightest of the three.
