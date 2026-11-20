# 15 · Repaso as games, each word in a new sentence

Written Nov 20 2026 by the orchestrator, from Salim's words that day. Read with 03, 09, 10 and 13 (order 27). Where this page and 10 differ about Repaso, this page wins once it is built.

Status: fourth version. The first was read by two fresh reviewers (one as a beginner against page 03, one against the real sentences, the progress rules and his research): see "What the first version got wrong". The second put the scored games on the story books' pictures; readers then judged all 43 books, picture by picture, and that did not hold: see "What the second version got wrong". What the third got wrong is below too. The data is final (`coqui/tool/make_repaso.py`, the readers' verdicts in `coqui/tool/repaso/`); the build is order 27.

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
- Each game has one plain English line saying what to do (menus may be English): "Listen. Touch the picture that fits." (¿Cuál? and ¿Dónde? say the same line) "Listen. Touch the word you heard." "Listen. Touch the words in the order you hear. Two don't belong." "Touch a sound, then its word." "Listen. Say what comes next."
- A row of right answers shows as a small count ("4 in a row"). The end screen says "N of M words right the first time" (M is the session's scored words; the play games do not count) and lists every one of those words in one of two lists, "Got it the first time" and "Coming back soon", each with the sentence it was asked in; a tap plays it. No lives and no clock.
- Repaso counts toward the day's minutes, so a day with only Repaso keeps the streak. Today it does not.
- Silence, in the scored game only: 6 s after the sentence it plays again; 6 s more, the answer is shown and it is a miss (as today). The play games never time out.

## The games

Scored. These decide what he knows by ear. A word's reviews take them in turn: ¿Cuál?, then ¿Qué oyes?, and so on; after a miss the next is ¿Cuál?.

| Game | What he does |
|---|---|
| **¿Cuál?** | Hears a sentence, touches the one of the word's two pictures that fits. The pictures are the word's own pair. The sentence is the pair's own, or another recorded sentence a reader judged to fit the right picture and not the other (78 of 128 words have one or more; none has more than a few). |
| **¿Qué oyes?** | Hears a sentence he has not been asked in before: one of the word's clean recorded sentences, in turn. Three word tiles, written, each with a speaker that plays the word alone when the word has such a clip. They show while the sentence plays and can be touched when it ends. He touches the word that was in it. The other two are words he has met that are not in the sentence and cannot be taken for anything in it. Then the sentence shows as text with the word lit, and with its story picture where readers judged the picture to show it. |

¿Qué oyes? is where the new context is: 141 words have three or more such sentences, the middle word 9. It needs him to read a tile, or to hear it: see "Asked of Salim".

Play: these score nothing for Ear. They use the session's words in still other sentences.

| Game | What he does |
|---|---|
| **Arma la frase** | Hears a sentence of 3 to 6 words. Its words are tiles in a mixed order, lower case, no punctuation, with two extra tiles. Under them is an empty answer line (no places, so the answer cannot be read from the shapes of slots; its height for two rows is there from the start). He touches the tile of the next word of the sentence: it goes onto the line, one after another from the left, and has the green border at once. Any other tile stays in the bank, red-orange with an X for about a second, and the item counts as missed; he goes on. A tile on the line stays (every placed tile is right). Lines with a name, a repeated word or a "says" tag are not used. |
| **Parejas** | Four speaker tiles and four written words. A speaker plays a sentence; he touches the word that is in it. Right pairs lock. The four are chosen so that each word is in its own sentence only and no two are easily taken for each other. |
| **¿Dónde?** | Hears a sentence and touches the picture of its moment, among two or three pictures of the same story. Only for the sentences where readers found fair wrong pictures (163 items, 64 words). |
| **Dilo** | Only for a word that is open for speaking (today's rule: some days after he first hears it), only with a line that has decided accepted forms, only when the microphone works and "Speak in stories" is on. He hears what comes just before the line in its story (the question or the cue), not the line itself, so it is not an echo; where a line has nothing before it, it is not used. Heard right: a Mouth answer right. Anything else writes nothing. What the app heard is shown, as on the call screen. |

Where a sentence has a book picture that readers judged to show it clearly, the play games show that picture while it plays: the moment he first heard it.

A word with no picture pair (28 words) is scored by ¿Qué oyes? only; a word with no clean sentence (6 words) by ¿Cuál? only; two words no game can serve.

Nothing is in English but the menus. No game translates.

## What is written to his progress

- ¿Cuál? and ¿Qué oyes?: an Ear answer, right or wrong, exactly as Repaso writes today, with the same timing rule. The schedule, the stages and the steps do not change. The sentence in turn is taken from the count of answers the record already keeps.
- Dilo heard right: a Mouth answer right. Nothing else for Mouth.
- The other play games write nothing.
- The day's minutes get the session's time.

## The data

One file, `historia/datos/repaso.json`, made by a tool in `coqui/tool/` from the stories, the books and the decided speech marks, then checked by readers:

- For each word: its clean sentences in a fixed order; for each, the clip, the text as recorded, the story, and the book picture of its moment when there is one.
- For each word with a picture pair: the sentences that fit its pair, as readers judged them.
- For a pictured sentence: whether its book picture shows it clearly, and the other pictures of the same story that are fair wrong answers.
- Which written words must never be offered together (accent twins, one inside another, near spellings). The lines for Dilo. Which words fall back to ¿Qué oyes? for scoring, and which no game can serve.

The app uses a sentence only when he has finished its story.

## What the first version got wrong

- It chose the game from how well a word is known. By the progress rules the tile game would first come around day 64 and the speaking game around day 406. For two months a session would have been one game.
- It took any line with the word in it. More than half are corrections, reactions or lines that mean nothing without their scene.
- It brought a sentence back without its picture: a new quiz, not a new context. The book pictures were not used.
- It let reading decide the Ear score, against "reading gets no tracking until A2".
- It counted saying a line back as hearing it, and made speaking an echo.
- A miss was not shown and came back as a different sentence, so nothing was learned from it.
- It kept "no points, no streak" without a reason, against his wish for a real game.

## What the second version got wrong

It made the scored games "touch the picture of this sentence's moment" and "does this sentence fit this picture", on the story books' pictures. Five readers then judged every sentence of all 43 books against every page (581 sentences, 231 pages):

- Only 163 of 1,481 items have a fair wrong picture in their own story; 92 of 156 words have none.
- For 349 sentences the book picture does not clearly show what the sentence says (no bread near the duck, no ball in the tree, nobody visibly running).
- Many pages of one story look almost the same; some are identical.
- No set of four could be made for a matching game on pictures.

So the book pictures are context, not proof. The scored game went back to each word's own picture pair, with the sentence changing, and only sentences a reader judged against the two pictures.

## What the third version got wrong

It kept the scored game on each word's own picture pair and changed the sentence. Five readers judged 1,294 sentences against the 128 pairs without knowing which picture is the right one: 139 fit. The pairs are tight pictures of one thing; another sentence names other people and things and fits neither. Half the words have only the sentence their pictures were drawn for.

So no picture the course has can score a new sentence fairly. What can: he hears the sentence and says which word was in it.

## Asked of Salim (Nov 20), and his answer

Which word was in it needs him to read the tiles or to hear them. He was offered: written tiles decide the Ear score (no cost, bends "reading gets no tracking until A2"); or each word recorded alone, once, so that every tile can be heard.

**His answer, Nov 20: "You're approved for those recordings."**

- The orchestrator had said the recordings would use ElevenLabs credits. That was wrong. Recorded lines are made by the audio job with his free Azure Speech account (page 05: 500,000 characters a month free; the tier cannot bill). ElevenLabs is only the live calls. He was told.
- The clips are listed in one new file, `historia/cuentos/palabras-solas.json` (made by `coqui/tool/make_palabras_solas.py`): one clip per tracked word that has no clip of the word alone yet, in Karina's voice like the narrator. This order allows that one file under `historia/cuentos/`. The audio job records them when the file reaches main.
- When every tile of an item has its clip, the tiles show a speaker and he can answer by ear alone.

## What this does not do

- No new story text. The only new recordings are the single words he approved; the only new file under `historia/cuentos/` is their list.
- No change to the schedule or to what Ear and Mouth mean.
- No English outside menus, no translation, no typing.
- Biblioteca is a separate question (order 27).

## Guesses

- That hearing a known word in a sentence he has not been asked before, and picking it out, is the "differing context" he means.
- That written tiles are welcome in a listening-first course at this level.
- That Arma la frase with two extra tiles is not too hard.
- That the recogniser hears one word inside a short line reliably on his phones (the phone test results are still owed).
