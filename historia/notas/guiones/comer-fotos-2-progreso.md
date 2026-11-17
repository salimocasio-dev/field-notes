# A comer, picture fixes round 2 (Nov 17): progress

Brief: scratchpad comer_fix_brief2.md (points A1-A7, B, C, D, E). Point by point; "commit" = the commit that holds it (git log has the ids). The Spanish lines, the clips and the generator's clip list are untouched (gen_comer.py: 3190 characters, 0 clashes).

Tools
- historia/tools/reposo.py: new environment variable PASO=8. Walks and carries are never at rest, so a rest-only capture shows nobody walking (that is why the readers saw people pop in and out). With PASO=n a frame is also kept whenever a person, the frog or a thing has moved n pixels since the last frame kept; the last picture of the run is always kept. Use `PASO=8 python3 historia/tools/reposo.py ...` (the old behaviour is the default).
- A speaker gets an empty speech bubble over him when the words are hidden (txt=no), so that it is plain who speaks (comer.js, SINTXT).

Shared (historia/escenas/comer.js)
- [x] A1/A2 people are drawn without arms; their arms are drawn over them with an elbow, a sleeve and a hand (brazoJ); legs step when they walk (mkPersonaN, mkAbuelaN, mkAbuelaSN). Every held thing is in a hand (GRIP table, agarres); the frog has arms too. ALCANCE logs a hand that is farther than the arm.
- [x] A1 walk helper (mueve/ruta/entra/sale/sienta/levanta: 5 px per tick, the door is out of the picture at x=0) and carry helpers (manoA, toma, pon, suelta, centroPara; ranaToma/ranaPon for the frog).
- [x] A3 spoons no longer than the forearm (cucharaPos), the roll keeps its size, nothing at 2.5x in the stories.
- [x] A4 steam short and beside the faces; held cups beside the face.
- [x] A6 thought bubbles lead to the one who thinks (nube with aim); 33's "stalk" was the roll held up on a bare arm: now a hand.
- [x] A7 stray yellow lump: it was the mound drawn at the spoon bowl; the mound now travels in a hand.

Story 33: roll lifecycle with hands (basket, board, mouth, plate); the wrong roll is bitten once, no mould, plain frown, put on his plate and pushed a little away, stays to the end; the right roll is eaten and leaves crumbs; chocolate is a bowl of chocolate with a spoon handle (same bowl as the butter); the tray has a rim and is carried in both hands, rolls slide into the basket; the frog keeps his spoon while he carries a roll; Luis and Carmen hold their plates; the ending has no heart after a miss (bitten rolls in view).
Story 34: platter waits on the stove and abuela carries it to the table; she lifts the pot with one hand, serves the three small spoons behind the table, scoops seven mounds onto the platter with the spoon in view, moves papá's fork flat onto his three, hands the spoon to Luis and walks out with the pot; Luis walks and reaches with a spoon as long as his arm; the baby is a baby in the chair or in mamá's hands, never missing; the frog's thought leads to him; the wrong "full" answer keeps him on his back until the next beat.
Story 35: teaspoon from the sugar bowl, grains fall, he stirs, the spoon stays in the cup; the milk pan is a saucepan with a handle and lip, milk is a solid white stream; the blue pot is the coffee pot, the red one is a greca (small moka pot); abuela's stool is there from the start and she sits fully inside the picture; the men and the children lift their cups and drink; the spoiled cup is put down at its owner's place and he stays cross.
Pairs: quieres, ¿qué quieres?, me gusta, no me gusta and rico redrawn (closer camera for the last two), azúcar jug redrawn, un poco spoon shortened, no held object floats (every held thing has an arm and a hand).

Open: see the end of this file (updated before each commit).
