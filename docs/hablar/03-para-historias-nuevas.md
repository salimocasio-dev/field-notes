# Speaking turns in new stories (A comer onward)

Applies to every story written from now on. 01-decisiones.md is the rule book; this page says what each new script must contain.

## Each new story

- 2 to 4 speaking turns. Each is a coquí line that he says instead of the coquí.
- Every turn tests words from EARLIER scenes (words in focus_words of a story that comes before this one in curso.js). Never a word that is new in this story. Earlier words keep coming back this way.
- Turns go only on: a plain coquí line, a coquí line inside "elige", or a coquí line inside a signed "ask". Never inside a costed "decide".
- Each turn is a natural reply inside the scene: answering a question, greeting, thanking, asking for something, saying sí or no. The narrator or a character asks or sets it up in the line just before. Not a drill, not a repeat of the line just heard.
- The line is short: 1 to 5 words. A model of it (the coquí saying it) must be possible: it is a normal recorded coquí clip ("who": "tu").
- Spread them out: not two turns in a row.

## How a turn is written in the story file

On the coquí's clip, add a field "tu_turno": a list of targets. Every target must be heard.

```
"gracias_ab": {"who": "tu", "text": "¡Gracias, abuela!",
  "tu_turno": [{"palabra": "gracias", "formas": ["gracias"]}]}
```

- "palabra" is the word exactly as it appears in focus_words (the key of the word record, accents included).
- "formas" are the accepted forms after normalising (lower case, no accents, no punctuation). Include the plain form and real variants only (for example "por favor"; "favor" alone is NOT accepted). Never add a near-miss spelling to make recognition easier.
- A line can have 1 or 2 targets. Not more.
- In "elige", each option's "said" clip gets its own "tu_turno". The targets must be set so that no natural answer satisfies two options (they may share a word, like "quiero" in "Quiero jugo" and "Quiero agua", as long as another target tells them apart).

## Reviews

- The beginner reviewer and the Puerto Rican reviewer read the script with the turns marked. Add one question for the beginner reviewer: "At each turn, is it clear what the coquí should say, from the story alone?"
- The silent frame reader sees one frame of a turn (empty bubble with the mic, the mic button) and says what it asks him to do.


How turns behave (from 01, after review):
- In a signed ask, the turn hides the sign and the speaking bubbles: he answers from the picture and the question. So the question and picture must make the answer clear on their own.
- A clip is a turn once per play (first live occurrence). Don't count on repeats of the same line as extra turns.
- Never make the turn an echo of a line he has just heard.
