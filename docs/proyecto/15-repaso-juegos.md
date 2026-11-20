# 15 · Repaso as games, each word in a new sentence

Written Nov 20 2026 by the orchestrator, from Salim's words that day. Read with 03, 09, 10 and 13 (order 27). Where this page and 10 differ about Repaso, this page wins once it is built. Status: design, reviewed by fresh reviewers before any build (page 03: a self-review does not count).

## His words

"its not a reader, its just a place to review the stories that already exist. thats not a feature. thats filler and fluff. almost the same deal with the flash cards. differring contenxt make the word stick more. I would like flash cards to work more like how duo lingo does their games."

## What is wrong today (from the code, Nov 20)

- A word has one sentence and one pair of pictures. Every review of that word is the same sentence and the same two pictures; only the side changes.
- Every item is the same game: hear, touch one of two pictures.
- The 28 words with no picture pair never come up in Repaso at all.
- Repaso never asks him to say anything. The Mouth meter moves only in stories and calls.
- Each word's record has a step (1 to 4) that rises with right answers. Nothing uses it.

## What there is to work with (counted by script, Nov 20)

- 156 words in the three places that have stories. 1,582 recorded lines, 1,475 different sentences.
- A word is in 14 or 15 different recorded sentences (the middle word); 143 of 156 words are in five or more. So a new sentence costs no new recording.
- Lines by length: 2 to 6 words: 1,205. That is the size for tiles.
- No timing of single words inside a line, and only 23 words have a clip of the word alone. So a word cannot be played by itself.
- 128 words have a picture pair. A pair's two pictures were drawn for its one sentence: a different sentence with the same word may fit the wrong picture ("La puerta no está cerrada"). So pictures stay with their own sentence.
- 88 lines in 31 stories already have decided accepted forms for speech (72 words).

## The session

- Words: as today (up to 10; due first, most overdue first). Words with no picture are no longer left out.
- One item per word. Then, once, after the fifth item: a round of Parejas, when at least four of the session's words have pictures.
- A missed word comes back once, three items later, in another sentence, in the easiest game it can have. That second ask is not scored (as today).
- About 11 to 13 items, 3 to 4 minutes. The start screen says "Listen and play." and "N words · about M min".
- No lives, no timer, no points, no streak inside the session. The progress segments, the praise clips and the end screen stay. The end screen adds, for each word, the sentence it was asked in; a tap plays it.
- Silence: 6 s after the sentence, it plays again; 6 s more, the answer is shown and it counts as a miss (as today).
- A speaker button replays the sentence at any time, free.

## The games

The game for a word comes from its step, so a word he knows better gets a harder game.

| Step | Game | What he does |
|---|---|---|
| 1 | **¿Cuál?** | Today's game: hears the word's own sentence, touches one of its two pictures. Only for a word with pictures, and never twice running for the same word: the next time at step 1 it is "¿Qué oyes?". |
| 1 (no picture, or last time was ¿Cuál?) and 2 | **¿Qué oyes?** | Hears a new sentence. No text. Three written word tiles: the word, and two other words he has met that are not in the sentence. He touches the one he heard. Then the sentence shows as text with the word lit. |
| 3 | **Arma la frase** | Hears a new sentence of 3 to 6 words. Its words are tiles in a mixed order, with two extra tiles that do not belong. He touches them in order. A wrong tile jumps back and the item counts as a miss, but he finishes the sentence. |
| 4 | **Dilo** | Hears a new sentence of 2 to 6 words and says it. Right when the recogniser hears the word (its decided accepted forms where it has them, else the word itself). Only when the microphone works here. "Can't speak now" turns the speaking games off for the session and the word gets Arma la frase instead. A microphone error never counts against him. |
| once | **Parejas** | Four speaker tiles and four pictures. A speaker plays its word's own sentence; he touches the picture that fits. Right pairs lock. Not scored. A word he mismatches twice gets one more unscored ask at the end. The four are chosen so that none of the four words is in another's sentence. |

Nothing is in English but the menus (page 09). No game translates.

## Which sentence

A sentence can be used for a word when all of this is true:

- It is a recorded line of a story he has played. So he has heard it before, with its picture, and knows what it is about.
- It has the word as a whole word, with the word's own accents ("él" is not "el"; "está" is not "esta").
- It is not a line that asks him to do something in the story (a step's question or order), nor a praise or fixed clip.
- Its length fits the game.

The sentences of a word are put in a fixed mixed order (the same on every phone). The word's Nth scored review takes the Nth sentence, round and round, so two reviews running never use the same sentence. A second ask in the same session takes the next one. A word with no usable sentence yet keeps ¿Cuál? with its own sentence; a word with neither is left out, as today.

## What is written to his progress

- ¿Cuál?, ¿Qué oyes? and Arma la frase write an Ear answer, right or wrong, exactly as Repaso does today. The schedule, the stages and the step rules do not change.
- Dilo, said right: an Ear answer right and a Mouth answer right. Tried and not heard: a Mouth answer wrong, then Arma la frase decides the Ear answer. Not tried: nothing for Mouth.
- Parejas writes nothing.
- One number may be added to a word's Ear record: how many scored reviews it has had (old records read as 0). Nothing else in the store changes.

## What this does not do

- No new recordings, no new story text, no change under `historia/`.
- No change to Palabras' tab or the word sheet.
- No English, no translation, no typing.
- Biblioteca is a separate question (order 27): what a real reader holds, and what new recordings would cost.

## Guesses

- That written word tiles are welcome in a listening-first course at this level (the books already show text; reading is not tracked until A2).
- That Arma la frase with two extra tiles is not too hard at step 3.
- That the recogniser hears one word inside a short sentence reliably on his phones (the phone test results are still owed).
- That a line heard once in a story is understood again weeks later without its picture.
