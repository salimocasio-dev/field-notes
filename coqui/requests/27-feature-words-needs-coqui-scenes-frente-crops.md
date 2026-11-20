# 27: feature_words needs coqui_scenes: El frente's word pictures to show their word

## What I need

New `crop` (and `zoom`) values in `coqui_scenes/assets/sheets/frente-sheet.json`, `pictures`, for these entries. Each picture is 196 x 104 picture pixels as today. The Palabras card shows it as wide as the card and, on a phone at 2 device pixels per css pixel, one whole scale larger with its sides cut by the card (about 1/8 of the width each side). So the thing the word names should sit whole inside the middle three quarters of the picture.

| Entry | What the picture must show | Why today's fails (as drawn in the app, Nov 20) |
| --- | --- | --- |
| `ventana.si` (and `abre.si`, same view) | The window whole, centred: frame, shutters and flower box; the palm at most at one edge. | Crop `[24, 49, 98, 52]`, zoom 2: the left half is the palm tree, and the window is cut by the right edge. With zero words, the picture reads as "palm tree". |
| `puerta.si` (and `cierra.si`) | The door whole, centred, with its frame. | Crop `[122, 65, 98, 52]`, zoom 2: the door fills the left third and is cut by the left edge; the rest is wall and grass. |
| `abuela.si` | Abuela in the doorway, large: zoom 2, centred on her. | Zoom 1 over the whole front: she is about 10 picture pixels tall, a speck on a card. |
| `hola.si`, `adiós.si` | Abuela waving and the frog, large enough to see the wave: zoom 2 on the doorway. | Zoom 1: the wave and the frog are a few pixels each. |

The `what` lines of these entries already say the right thing ("the window, close: no door in it"); the crops do not match them in the new El frente set. A likely cause (a guess): the crops' centres are the old scene's screen positions of these things, and the things moved when the set was redrawn.

## Why

Order 27 (Palabras, better to use): "Pictures must be clear enough that someone who understands zero words understands from the picture" (03-requirements). The Palabras card shows each word's `<word>.si` picture; the first words a learner meets are El frente's, and three of the first four cards show the wrong thing. The same pictures are Repaso's (¿Cuál?) pictures, so the fix helps there too; the `.no` pictures of the same pairs should keep the same view as their `.si` (Repaso shows both side by side).

## What I am using meanwhile

The pictures as they are. The card draws them larger than before (the whole picture fills the card's width), which helps every picture but does not fix these crops.

## Order and branch

Order 27, branch `lane/feature_words/27`.
