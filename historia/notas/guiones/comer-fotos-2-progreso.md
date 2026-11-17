# A comer, picture fixes round 2 (Nov 17): progress

Brief: scratchpad comer_fix_brief2.md (points A1-A7, B, C, D, E). Point by point; "commit" = the commit that holds it.

Tools: historia/tools/reposo.py has a new environment variable PASO=8: besides the rests it also keeps a frame whenever a person, the frog or a thing has moved 8 px since the last frame kept (walks and carries are never at rest, so rest-only frames show nobody walking). Use `PASO=8 python3 historia/tools/reposo.py ...`.

## Shared (historia/escenas/comer.js)
- [x] People without arms in the sprite; arms drawn over them with elbow, sleeve and hand (brazoJ); legs step when walking (mkPersonaN, mkAbuelaN, mkAbuelaSN).
- [x] Everything held is in a hand (GRIP table, agarres); the frog has arms too.
- [x] Walk helper mueve/ruta/entra/sale/sienta/levanta (5 px per tick, doors out of the picture at x=0).
- [x] Carry helpers manoA, toma, pon, suelta, centroPara.
- [x] A real stool (taburete) exists (it was a plate before).

## Story 33
- in progress (see git log)
