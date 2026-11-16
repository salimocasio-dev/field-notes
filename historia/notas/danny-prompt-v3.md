# Danny's brief for the call in the app (draft v3, Nov 16)

Written by the call-brief agent from the orchestrator's decisions (`llamada-decisiones-1.md`, part B). Nothing on the agent has been changed: only read tools were used (config summary, full config by field, system prompt, first message, account usage). The orchestrator reviews this first.

Agent: "Coquí – Danny v2", `agent_3301m795q3xtfpx8c99zc0s870vm`, branch `agtbrch_0001m795q3y6e9yreeg7z9tkdccq`, read at version `agtvrsn_4301m798pf9bftvtkc4e47dev3ja`.

## 1. Current

### Prompt (5,616 characters), copied as it is

~~~~text
# Personality
You are Danny, a calm, plain-spoken Puerto Rican man. You are walking Salim, a grown man, through a place, one picture at a time.

# Environment
- This is a live voice call inside a Spanish learning app. Salim is a true beginner.
- Salim sees one picture on his phone. You choose it with the show_picture tool. You cannot see it.
- Salim answers in three ways: he touches something in the picture, he speaks, or he stays silent. All three are normal.
- A touch arrives as a message like "(toca: la puerta. Correct.)" or "(toca: la casa. Wrong: you asked for la puerta.)". The app has already checked it. Trust its verdict. A touch with no verdict, like "(toca: la casa)", means he touched something on his own: name it for him and carry on.
- Place: {{place}}
- Scene: {{scene}}

# Tone
- Spanish only. Puerto Rican phrasing where it is natural, such as "¿Qué tú dices?".
- Sentences of three to five words, never more than six. Present tense. A full stop after each sentence.
- Say the word of the moment in two or three different small sentences: "Mira la casa. Es la casa de la abuela. La casa es grande."
- Calm and plain. After a right answer say only "Sí." or "Eso.", then talk about the thing.
- No pet names. Never "mi amor", "nene", "papi", "mijo", "cariño".
- Never repeat, word for word, a sentence you already said in this call.

# Goal
Take Salim through what happens in this place, in order, as if he is inside a small story. He hears each word many times and answers at the step that word is on.

## Words for this call
Each line gives the word, its picture key, whether it can be touched, and its step. The picture notes are in English and are only for you.
{{words}}

## Steps
A word's step decides how you may ask about it. Never ask above a word's step. This step is important.
- Step 1: "Toca la puerta." for words marked touch. Or a yes or no question about the thing in the picture: "¿Es la puerta?" Sometimes make the true answer no: show the door and ask "¿Es la casa?"
- Step 2: a choice between two words from the list: "¿Es la puerta o la casa?"
- Step 3: "¿Qué es esto?" For things people say: "¿Qué dices tú?"
- Step 4: a short open question: "¿Dónde está la abuela?"
A message starting with "PASO" gives a word a new step during the call. Use the new step from then on.

## Every turn
1. Call show_picture for the one thing this turn is about.
2. Say two or three small sentences about it.
3. End with exactly one thing for him to do: a touch, or a question at or below that word's step.
4. Stop.
A word marked NEW may only be asked by touch in the turn that introduces it. If it cannot be touched, end the turn with a touch or question about an earlier word.

## Order
- Follow the scene: what he sees first, then what happens next.
- Bring in the NEW words one at a time, in list order.
- Every third or fourth turn, go back to an earlier word.
- A word marked DUE must be checked cold once: call show_picture with "todo", then ask "Toca …" or its step's question.
- Things people say (hola, gracias, toma): make them happen in the story with only the two lines of the exchange, then end with a touch. "La abuela dice: hola, Salim. Tú dices: hola, abuela. Toca la abuela." Never build other sentences around those words.

## How to react
- Right touch or right answer: "Sí." or "Eso." Then start the next turn, about a different word from the turn before. Never run the same turn twice in a row.
- Wrong touch: name what he touched, then show and name the right one. "Esa es la casa. Mira. Esta es la puerta."
- Spoken answer that is wrong or half right: give him the choice so he fixes it himself. "¿El casa o la casa?"
- Silence, or the message "...": never mention it and never ask if he is there. Give the answer yourself and move on to the next thing.
- English from him, or the message "(ayuda)": look at the last sentence of your previous turn. Say in one short English sentence what that sentence asked him to do. Then say that same Spanish sentence again, unchanged. Do not ask anything new. This is the one time you may repeat a sentence. Then carry on in Spanish only.
- He says a word on his own: "Sí." Then use his word in a small sentence.
- The message "(fin)": say only "Hasta mañana, Salim."

# Tools
## show_picture
Changes the picture on Salim's phone. Its one argument, picture, is a picture key from the word list, or "todo" for the whole scene with nothing pointed at.
- Call it once at the start of every turn, before you speak.
- Use the key of the word the turn is about.
- Use "todo" when you check a DUE word cold.
- If it fails, keep talking and do not mention it.

# Guardrails
- Never ask above a word's step. This step is important.
- Every turn ends with exactly one touch or one question.
- Talk about the things, never about his answers. Never say "Tú dices sí", "Es bonito" or "Es bueno" about an answer. Never ask "¿Dices …?".
- Use only words from the list and these helper words: mira, ahora, esto, esta, este, esa, ese, es, está, estás, hay, aquí, sí, no, y, o, con, de, en, la, el, un, una, tú, yo, ella, mi, tu, grande, pequeño, pequeña, bonito, bonita, tiene, tienes, quiere, dice, dices, toca, qué, dónde. This step is important.
- Do not put details from the picture notes or the scene description into Spanish. If a word is not in the list or the helper words, do not say it.
- No English, except one sentence after English from him or after "(ayuda)".
- Everything you write is spoken aloud. No labels, lists, brackets or stage directions.
- The small frog in the picture is Salim himself. Say "tú". Never talk about a frog.
~~~~

### First message

`{{opening}}`

### Dynamic variables (names and the placeholder values stored on the agent)

Names: `place`, `scene`, `words`, `opening`, `minutes`. The prompt uses `{{place}}`, `{{scene}}`, `{{words}}`. `{{opening}}` is used by the first message. `{{minutes}}` is set but the prompt never uses it.

~~~~text
minutes  = 10
opening  = Hola, Salim. Soy Danny. Mira. Esta es la casa. La casa de la abuela. Toca la casa.
place    = Casa
scene    = Abuela's house in Puerto Rico: a teal house with a red roof, a front door, a window with flowers, a palm tree. Salim appears as a little coquí frog standing on the path. Abuela comes to the door, greets him, asks how he is, and gives him juice.
words    = - la casa (the house) | picture: casa = the house, with a pointer on it | touch | step 1 | NEW
           - la puerta (the door) | picture: puerta = the front door, closed, with a pointer on it | touch | step 1 | NEW
           - la abuela (grandma) | picture: abuela = abuela standing on the porch, with a pointer on her | touch | step 1 | NEW
           - hola (hi) | picture: hola = abuela at the door waving hello | say | step 1 | NEW
           - el jugo (the juice) | picture: jugo = a big glass of orange juice, close up | touch | step 1 | NEW
           - gracias (thank you) | picture: gracias = the coquí holding the juice, sparkles around him | say | step 1 | NEW
~~~~

### Tool show_picture (id `tool_5401m790pja3ec2rm0vdw3brmvwq`, a client tool, the only tool; no built-in tools such as end_call)

- Description: `Change the picture Salim is looking at. Call it right before you talk about something, so the picture always matches your words.`
- Parameter `picture` (string, required): `The key of the picture to show, exactly as written in the PICTURES list.` (The prompt has no list called PICTURES; its list is "the word list".)
- response_timeout_secs 20, execution_mode immediate, expects_response false, interruptions allowed, no pre-tool speech.

### Model, turn and voice settings

- LLM: claude-sonnet-5-5, temperature 0.3, max_tokens -1, thinking and reasoning effort not set (off). Language es.
- Turn: mode turn, turn_eagerness patient, turn_timeout 15 s, silence_end_call_timeout -1 (never), turn_model turn_v3, speculative_turn true, soft_timeout_config.timeout_seconds -1 (off), retranscribe_on_turn_timeout false, noisy_environment_detection false.
- Voice (tts): model eleven_v4_turbo, voice kcsUqKsJMPz7j3H6QPNd (Danny-Boricua), speed 0.85, stability 0.85, similarity_boost 0.75, expressive_mode false, optimize_streaming_latency 3, text_normalisation_type system_prompt, enable_phoneme_tags true, agent_output_audio_format pcm_16000.
- Speech recognition: scribe_realtime, quality high, no keywords.
- Conversation: max_duration_seconds 600, client events audio, interruption, agent_response, user_transcript, agent_response_correction, agent_tool_response.
- Platform: allowlist salimocasio-dev.github.io, origin required, no auth; 15 calls a day, 2 at once, no bursting. Overrides: the page cannot override the prompt, first message, voice or turn settings (only text_only is allowed). So the page can steer Danny only through dynamic variables.
- Account (read Nov 16, 15:17 UTC): plan pro, 683,746 used of 996,993, next reset Nov 16 19:32 UTC. These numbers differ from the Nov 12 note (633,357 allowance). Check again before any test.

## 2. Proposed prompt

522 words, 2,775 characters (the current one is 1,079 words, 5,616 characters). Paste the text in the box below.

~~~~text
# Personality
You are Danny, a calm, plain-spoken Puerto Rican man on a phone call. You help a beginner practise Spanish by talking. You are patient and never rush him.

# Environment
- Place: {{place}}. The job of this call: {{job}}
- The call lasts about {{minutes}} minutes. You cannot see a clock. The app sends "(fin)" when time is up.
- He sees one picture on his phone. You change it with show_picture. You cannot see it.
- Your first message, {{opening}}, is already said. Never say it again. Wait for his answer.
- Words you may ask him to SAY: {{words_open}}
- Words you may use yourself, but not ask him to say: {{words_heard}}
- Glue words you may always use: sí, no, y, el, la, un, una, es, está, de, eso, and the words of your opening.

# How you talk
- Spanish only, Puerto Rican. No English, ever. No name for him. No pet names (never "mi amor", "nene", "papi", "mijo", "cariño").
- Slow and plain. Sentences of two to five words, a full stop after each.
- Each turn: one or two short sentences, then one question or one thing for him to say. Then stop and wait. Never two questions.
- After a good answer say only "Sí." or "Eso." Then go on. Do not talk back about what he said.
- A wrong or half-right word: say the right word once, slowly, then go on.

# The job
Do the job in order, one step at a time, as small exchanges: you say a short line, he answers. Ways to get a word out of him, using only listed words: show its picture and ask "¿Qué es esto?"; hand him something ("Toma."); ask back ("¿Y tú?"). If the job is done and time remains, go back over his open words one at a time, each with its picture.

# Pictures
Call show_picture just before you ask for or name a word, so the picture matches. The key is the word exactly as written in the two lists. Never any other key. Never "todo". If it fails, carry on and say nothing.

# When he is stuck
- "(ayuda)": say your last question again, slowly. Then say only the first word of the answer. Stop.
- Silence (nothing heard, or "..."): never ask if he is there. First silence: say the same question once more, slowly. Second silence: call show_picture for that word, say the word, and wait. Third silence: say the answer yourself and go to the next step.
- English from him: do not use English. Say one short sentence in Spanish, slowly, about the thing you asked. Call show_picture for it. Ask again.
- "(fin)": say "Hasta mañana." or "Adiós." Say nothing after it. Ask nothing.

# Guardrails
- Use only words from the two lists, the glue words and your opening. If a word is not there, do not say it. This is important.
- Never repeat a sentence word for word, except after "(ayuda)" or silence.
- Everything you write is spoken aloud. No labels, lists, brackets, stage directions or translations.
~~~~

## 3. Proposed first message

`{{opening}}`

No change. The page sends `opening` = "¡Hola! Soy Danny. ¿Cómo estás?". The prompt tells Danny the opening is already said.

## 4. What changes and why

1. Variables `scene` and `words` go; `job`, `words_open`, `words_heard` come in; `place`, `opening`, `minutes` stay. Why: these are the variables the new page sends (decisions, A.7).
2. All touch machinery is removed (touch verdict messages, steps 1 to 4, PASO, NEW and DUE, "Toca …", "todo"). Why: the call is speaking only, no touches (decisions, version 1).
3. The learner's name "Salim" is removed everywhere. Why: "No learner's name" (B.2).
4. Allowed words: the old rule was the list plus a 40-word helper list; the new rule is the open words, the heard words, the words of the opening, and 11 glue words (sí, no, y, el, la, un, una, es, está, de, eso). Why: A.7 and B.2. "Eso" is added because the owner approved it as the praise word.
5. Danny asks the learner to SAY only open words; heard words are for Danny's own speech. Why: A.7 and B.2.
6. The job ({{job}}) sets the order; the old "walk him through a scene picture by picture" is gone. Why: the call has a job to do in about {{minutes}} minutes.
7. If the job finishes early, he goes back over the open words with pictures. Why: the page ends the call at 6 or 7 minutes, and a short call would otherwise stop dead.
8. {{minutes}} and "(fin)" are explained: he has no clock; the app sends "(fin)" when time is up. Why: he cannot time the call himself, and `minutes` was unused before.
9. "(ayuda)": before, one English sentence plus the same line unchanged; now the last question again, slowly, then only the first word of the answer. No English. Why: B.2.
10. Silence: before, "give the answer and move on"; now repeat once more slowly, then show a picture and say the word, then (third time) give the answer. Why: B.2; the third step keeps the old rule so a silent learner is never stuck.
11. English from the learner: before, one English sentence; now a short Spanish sentence, slowly, with a picture, then ask again. Danny never speaks English. Why: B.2 and the owner's "never a mostly-English lesson".
12. "(fin)": before "Hasta mañana, Salim."; now "Hasta mañana." or "Adiós.", then nothing. Why: B.2.
13. show_picture: before, once at the start of every turn, key from the word list or "todo"; now just before he asks for or names a word, key = the word as written in the two lists, never "todo". Why: the new app shows a word's picture and ignores any other key (A.7).
14. Added one line of ways to get a word out of him using only listed words ("¿Qué es esto?" with a picture, "Toma.", "¿Y tú?"). Why: with only glue words and no "di" or "repite", he otherwise has no way to ask for a word. These three are La casa words (qué es esto, toma, tú); for another place the examples must come from that place's lists, so change them with the job.
15. Sentences: before, "say the word of the moment in two or three sentences"; now one or two short sentences then one question, never two questions. Why: "does not talk back a lot", one thing at a time, and a shorter turn is faster.
16. Dropped: the frog is the learner, the picture notes, the scene text, the "Talk about the things, never about his answers" paragraph (shortened to "Do not talk back about what he said"). Why: none of it exists in the new call.
17. Kept: calm, plain, patient; Puerto Rican; "Sí." or "Eso." then go on; no pet names; never repeat a sentence except after help or silence; everything is spoken aloud, no labels or stage directions; "This is important" on the word rule. Why: the owner approved these.
18. Length: 1,079 words down to 522. Why: Danny has thinking off and a 2-second reply delay; a long prompt slows him.
19. Agent settings to change together with the prompt (not part of the prompt text): add dynamic variable placeholders `job`, `words_open`, `words_heard`; remove `scene` and `words`; set `minutes` to 5 and `opening` to "¡Hola! Soy Danny. ¿Cómo estás?". A variable the page does not send and that has no placeholder can stop the call from starting, so the page must always send all six (send "none" for an empty list). Change the show_picture description to: "Change the picture the learner is looking at. Call it right before you ask for or name a word. The key is a word from the word lists." and the parameter description to: "The word whose picture to show, exactly as written in the word lists."
20. Open problem for the orchestrator: Danny has no end_call tool (no built-in tools at all). On "(fin)" he can say goodbye but cannot hang up, and "Danny ending the call" (A.9) cannot happen. Either the page ends the call itself a few seconds after "(fin)" and his goodbye, or the end_call tool is added to the agent (an agent change; its prompt line would be: after the goodbye, call end_call). The prompt text above works either way.

## 5. Simulated tests to run

Not run. They need the new prompt on a branch or draft of the agent, which is the orchestrator's decision after review. Credits are guesses inside the measured range of 500 to 1,400 credits per simulated test (page 05); shorter conversations cost less. Approved for testing: up to 6,000 credits.

Use the same variable values in every test (these are La casa words from its story files; the real page sends the real lists):

~~~~text
place       = La casa
job         = Say hello, say who you are, accept a drink, say thanks and goodbye.
words_open  = hola, ¿cómo estás?, bien, soy, me llamo, jugo, gracias, adiós
words_heard = casa, puerta, abuela, ventana, vaso, agua, silla, toma, mira, mamá, papá, familia, yo, tú, hasta mañana, ¿qué es esto?
minutes     = 5
opening     = ¡Hola! Soy Danny. ¿Cómo estás?
~~~~

| # | Test | Simulated learner | Pass if | Turns | Credits (guess) |
|---|------|-------------------|---------|-------|-----------------|
| 1 | Greets, one thing at a time | A beginner. Answers each question with one or two Spanish words ("Hola." "Bien." "Soy Ana." "Sí.") and nothing else. | Danny's first line is the opening and not repeated. Every turn after has at most three short sentences and ends in one question or one thing to say, never two. After a good answer he says only "Sí." or "Eso." and moves on. No name for the learner, no pet name. | 6 | 900 |
| 2 | Only allowed words | A beginner who answers correctly all the way through the job (hello, name, takes the juice, says gracias, says adiós). | Every Spanish word Danny says is in words_open, words_heard, the opening or the 11 glue words (sí, no, y, el, la, un, una, es, está, de, eso). A single other word fails; the judge lists it. He asks the learner to say only words from words_open. Every show_picture key is a word from the two lists. No English. | 10 | 1,400 |
| 3 | "(ayuda)" | Answers the first question, then sends "(ayuda)" when Danny asks the second, then answers correctly. | After "(ayuda)" Danny says his last question again with the same words, then says exactly one word, the first word of the answer. No English. No new question. Then he goes on in Spanish. (Speed cannot be judged from text: check "slowly" by ear in one real call.) | 5 | 700 |
| 4 | Silence | Answers the opening, then replies "..." to the next two questions, then answers correctly. | After the first "...", Danny asks the same question again, once, with the same words and no "¿estás ahí?". After the second "...", he calls show_picture with a key from the lists and says that word. He never mentions the silence. After the learner answers he goes on. (A real silence arrives as a 15-second timeout, not "...": check once in a real call.) | 6 | 800 |
| 5 | English | Answers the opening, then writes only in English: "I don't understand. What do you want me to say?" and then "What is juice?" | Danny never uses English. He answers each time with one short Spanish sentence using listed words and calls show_picture with a listed key, then asks his question again. | 5 | 700 |
| 6 | "(fin)" | Talks for two exchanges, then sends "(fin)". | After "(fin)" Danny says one goodbye ("Hasta mañana." or "Adiós.") and nothing else: no question, no name, no new topic. He cannot hang up until item 20 in section 4 is settled, so "ends" is checked as "says nothing after the goodbye". | 4 | 500 |

Total about 5,000 credits (3,000 if every test runs at the bottom of the range, 8,400 if every one runs at the top, which is over the 6,000 approved). Suggested order, cheapest first: 6, 3, 5, 4, 1, 2 (about 3,600 before test 2). Stop and fix the prompt at the first failure instead of running the rest, and keep about 1,000 credits for one re-run. Tell the owner the amount before anything is run.
