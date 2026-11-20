# 15 · Repaso as games, each word in a new sentence

Written Nov 20 2026 by the orchestrator, from Salim's words that day. Read with 03, 09, 10 and 13 (order 27). Where this page and 10 differ about Repaso, this page wins once it is built.

Status: second version. The first was read by two fresh reviewers (one as a beginner against page 03, one against the real sentences, the progress rules and his research). What they found is under "What the first version got wrong". Nothing is built yet.

## His words

"its not a reader, its just a place to review the stories that already exist. thats not a feature. thats filler and fluff. almost the same deal with the flash cards. differring contenxt make the word stick more. I would like flash cards to work more like how duo lingo does their games."

Older words of his that bind this (page 03): "the pictures are an aid to the listening. Not the game. It's listening and speaking." "How do people learn languages? Hearing first with context." "Reading gets no tracking until A2." "Each language skill keeps its own retention value per word." Never an echo of a line he has just heard; never a self-report button. The plan's "no points, timers, lives or win screens" no longer stands as written: he wants a real game.

## What is wrong today (from the code)

- A word has one sentence and one pair of pictures. Every review is that sentence and those two pictures.
- Every item is the same game.
- The 28 words with no picture pair never come up.
- Repaso never asks him to say anything.

## What there is to work with (counted by script on the real files)

- 156 words; 1,582 recorded lines. No new recording is needed for any of this.
- Not every line is a fair review item out of its story. Of 868 lines that are not a story's question or order, 408 are clean: not a correction ("No. Esa es la puerta."), not a bare reaction ("Abuela dice: ¡Listo!"), not heard only after a wrong touch. A word has 4 clean sentences in the middle; 32 words have fewer than 3.
- So the sentences are chosen ahead of time into a data file, by a tool and then by readers, not by a rule at play time.
- The story books hold a picture for the moment a line is said: 231 pages, 582 recorded lines. That is the context: the same picture he saw when he first heard it.
- 88 lines have decided accepted forms for speech (72 words).
- A word cannot be played alone: there is no timing of single words, and only 23 words have a clip of the word by itself.

## The session

- Words: as today (up to 10; due first, most overdue first). A word that no game can serve is dropped before the cap, the same way everywhere the count is shown.
- Each word gets one scored item. Around them, about four play items that score nothing. About 14 items, 4 minutes.
- The mix does not wait for a word to be well known. Every session from the second day has at least three kinds of game.
- A missed item shows its answer, and comes back once three items later: the same sentence, the same game, not scored. At most five come back in a session.
- Each game has one plain English line saying what to do (menus may be English): "Touch the picture that fits." "Does it fit? Sí or No." "Touch the word you heard." "Put the words in order." "Say it." "Match each sound to its picture."
- A row of right answers shows as a small count ("4 in a row"). The end screen says how many he got right the first time, and lists each word with the sentence it was asked in; a tap plays it. No lives and no clock.
- Repaso counts toward the day's minutes, so a day with only Repaso keeps the streak. Today it does not.
- Silence, in the two scored games only: 6 s after the sentence it plays again; 6 s more, the answer is shown and it is a miss (as today). The play games never time out.

## The games

Scored: listening only, with a picture as the aid. These decide what he knows by ear.

| Game | What he does |
|---|---|
| **¿Cuál?** | Hears a sentence, touches the picture that fits: two or three pictures. Either the word's own sentence with its two pictures (today's game), or a new sentence with the book picture of its moment beside one or two other moments of the same story. |
| **¿Sí o no?** | Sees one book picture, hears one sentence, touches Sí or No. |

A word's reviews take its sentences in turn, round and round, so two reviews running are never the same sentence. Which pictures are fair wrong answers, and which sentences are false for a picture, is decided ahead of time in the data and checked by readers who look at the pictures.

Play: these score nothing for Ear. They use the session's words in still other sentences.

| Game | What he does |
|---|---|
| **¿Qué oyes?** | Hears a sentence with its picture. Three written word tiles: the word and two that are not in it and do not sound like anything in it. He touches the one he heard; the sentence then shows as text with the word lit. |
| **Arma la frase** | Hears a sentence of 3 to 6 words with its picture. Its words are tiles in a mixed order, lower case, no punctuation, with two extra tiles. He touches them in order; a wrong tile jumps back. Lines with a name, a repeated word or a "says" tag are not used. |
| **Parejas** | Three or four speaker tiles and as many pictures. A speaker plays a sentence; he touches its picture. Right pairs lock. The sets are fixed in the data so that no two pictures look alike and no sentence fits two of them. |
| **Dilo** | Only for a word that is open for speaking (today's rule: some days after he first hears it), only with a line that has decided accepted forms, only when the microphone works and "Speak in stories" is on. He sees the picture and hears what comes just before the line in its story (the question or the cue), not the line itself, so it is not an echo; where a line has nothing before it, it is not used. Heard right: a Mouth answer right. Anything else writes nothing. What the app heard is shown, as on the call screen. |

Reading is in the play games only, so a slip in reading never lowers what the app thinks he hears. A word with no pictured sentence at all (a few) is scored by ¿Qué oyes? instead; the data names them.

Nothing is in English but the menus. No game translates.

## What is written to his progress

- ¿Cuál? and ¿Sí o no?: an Ear answer, right or wrong, exactly as Repaso writes today, with the same timing rule. The schedule, the stages and the steps do not change. The sentence in turn is taken from the count of answers the record already keeps.
- Dilo heard right: a Mouth answer right. Nothing else for Mouth.
- The other play games write nothing.
- The day's minutes get the session's time.

## The data

One file, `historia/datos/repaso.json`, made by a tool in `coqui/tool/` from the stories, the books and the decided speech marks, then checked by readers:

- For each word: its clean sentences in a fixed order; for each, the clip, the text as recorded, the story, and the book picture of its moment when there is one.
- For a pictured sentence: the other pictures of the same story that are fair wrong answers; and for a picture, sentences that are false for it.
- The fixed sets for Parejas. The lines for Dilo. Which words fall back to ¿Qué oyes? for scoring, and which no game can serve.

The app uses a sentence only when he has finished its story.

## What the first version got wrong

- It chose the game from how well a word is known. By the progress rules the tile game would first come around day 64 and the speaking game around day 406. For two months a session would have been one game.
- It took any line with the word in it. More than half are corrections, reactions or lines that mean nothing without their scene.
- It brought a sentence back without its picture: a new quiz, not a new context. The book pictures were not used.
- It let reading decide the Ear score, against "reading gets no tracking until A2".
- It counted saying a line back as hearing it, and made speaking an echo.
- A miss was not shown and came back as a different sentence, so nothing was learned from it.
- It kept "no points, no streak" without a reason, against his wish for a real game.

## What this does not do

- No new recordings, no new story text, nothing changed under `historia/cuentos/`.
- No change to the schedule or to what Ear and Mouth mean.
- No English outside menus, no translation, no typing.
- Biblioteca is a separate question (order 27).

## Guesses

- That a book picture of another moment of the same story is a fair wrong answer often enough. The readers' check will give the number.
- That the old book pictures (the flat style) are fine beside the new scenes until order 41 redraws them.
- That written tiles are welcome in a listening-first course at this level, as play.
- That the recogniser hears one word inside a short line reliably on his phones (the phone test results are still owed).
