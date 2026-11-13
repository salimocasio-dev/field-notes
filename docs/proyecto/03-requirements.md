# What Salim has asked for and rejected (his words where quoted). The plan must satisfy ALL of these.

## What the app is
- A general app to learn a language. Spanish first. The course WORDS are Puerto Rican and stay Puerto Rican. The recorded voice's accent does not have to be, at this stage. "Im building an app to learn language and right now Spanish" — NOT tailored to his personal goals; nothing religious or personal in the course ("The Islamic stuff is not relevant").
- Course design must be language-agnostic: any language can be added later.
- The method is "immersion and spaced repetition". "How do people learn languages? Hearing first with context." Learn like a baby. The research guides it but must not make it "like every other app".
- "For a true beginner experience every word is new. So it goes into the system that way, you can ask more questions as the person learns more words… Once the word is consistently used, its goes into good and comes less frequently." "And you can just test someone and understand what level they are anyway."
- Each language skill keeps its own retention value per word (missing a word while speaking counts against speaking only).
- "the whole point is that someone can use this app for all their language hours. If all they can do is 15 minutes. That's a big problem."
- "Recorded listening for the bulk of the hours, live calls for speaking." (Live calls cost about $6.50/hour.)
- "It shouldn't take almost 3 months to get out of A1" (said about an estimate of one short call a day).
- Users need a sense of accomplishment and must understand where they are going and why.
- MVP for himself now; a real app for Google Play later.

## The app structure
- "You made the whole app the map and game., when the map is just one part and it's how you interact with the lessons. The rest of the app should still exist."
- "we don't need to pack all the listening to the map, the app can have another opportunities just like it does outside of A1. The full app should be available for Day 1 just tailored for the A1 experience."
- Reading on day 1: "Yes it includes everything. What changes its what's tracked. Reading gets no tracking until A2."
- UI vision: a simple welcome explaining how it works; A1→A2 as a classic Super Mario Bros. 3 style world map (16-bit, seen at an angle, roads, numbered stops, landmarks; places match what is learned), worked through daily; a profile showing where he is; a simple streak; a way to add words or state a goal ("I want to be able to speak to my 1-year-old son around the house") and get extra material; course adjusted to time commitment.
- Art bar: instagram.com/science_in_8bit. Pictures must be clear enough that someone who understands zero words understands from the picture.
- Nov 13, on the first app shell: "What kind of UI is this????" Then, on a version that made every screen a pixel game: "I didn't say the whole thing is a game, I said on the home screen is the map to the game as the main part of the course." His UI spec is his doc "Language App UI Design Plan" (page 09).

## Lessons
- "the pictures are an aid to the listening. Not the game. It's listening and speaking" — said about an early build that was tap-only, with an "I said it" honor button. The app must actually hear him by voice. (Nov 13, his correction: he did not reject games or touch. He rejected tapping that was all there was and taught nothing, and speaking that nobody heard.)
- "I hear a robot voice and a script that repeats words. I told you a conversation." — rejected a script that plays lines and has him repeat words; rejected the phone's robot voice.
- A lesson is not capped at its target words: "they hear a bunch of words and focus on the words their learning."
- Lessons "heavy on listening… with words still returning with other lessons". A five-phrase lesson was too little.
- Danny (the voice): slow and deliberate, plain, A1/A2 vocabulary, not flamboyant, does not talk back a lot after each answer, NO pet names ("mi amor", "nene").
- English only so a stuck learner can navigate; never a mostly-English lesson.
- "Your instructions to Danny are the problem. Not the design."

## The five plan decisions: all settled by him on Nov 13
1. Touch as the answer in listening: approved. "this is fine." "I didnt reject games. you didnt give me a game before, you gave me tap this thing and learn nothing." The earlier build failed "because that's ALL you did. you made me garbage. I support stuff that works." So: games are NOT ruled out. His test is whether it works and teaches.
2. One English line before a new grammar pattern: approved, "fine if its supported by research". (It is: Norris & Ortega 2000, Spada & Tomita 2010, Goo et al. 2015, as summarised in the grammar report.)
3. Saying a line back to Danny: approved. His objection to the earlier build was: "you had me repeating to no one, to myself, unheard by anyone or even the app. clicking 'i said it' which the app couldnt do anything with that information anyway." So: anything he says must be HEARD by the app or by Danny. Never a self-report button.
4. One story as the first test: approved. "thats fine".
5. The map: approved. "the map is fine".

## How a story must sound and play (Nov 13, his verdict on the first version of story 1)
- The first version spoke in bare labels with long pauses and asked for the same touches twice ("La casa. Es la casa. Toca la casa. Sí. La casa."). His verdict: "What you gave me is beyond boring".
- His direction: "Here's how it needs to go. Something like (in Spanish): Is this Abuelas house. Look at Abuelas house. Can you touch the house? Big indicator to touch. Good job. This is the door of the house. It's closed. Where is the door? Big indicator to touch (when I touch the door it reads as wrong btw). Abuela opened the door. Hola Abuela! Abuela says hola como estas".
- So: the voice talks TO the learner in whole, natural sentences and asks real questions. Not labels. Praise is short ("¡Muy bien!"), then on. The sign for what to touch is BIG. A right touch never reads as wrong. The story moves; no repeating an ask to pad it.
- He picked the voice by ear: "Karina Puerto Rico" (es-PR-KarinaNeural).

## His word comes before a research rule (Nov 13)
- Asked why the first version was boring, Claude answered that it had put the research rules above what he had said. His reply: "This needs to stop happening."
- So: the research informs. It never overrides him. Where a report and his words disagree, do what he said and tell him so in one line.

## A real game with stakes (Nov 13)
- "I want to explore the idea of making the game a real game with stakes. Responses and taps move the story forward in meaningful ways."
- "We are just on MVP so it doesn't need to be fully now, bit I want what we create to be easily scaleable."
- "Try again story 1 and 2 and 3. Reread the research. Have someone review"
- So: something can be lost in a story; what he touches and answers changes what happens; what is built for stories 1 to 3 carries over to every later story. The plan's line "No points, timers, lives or win screens" was Claude's, from a report. It no longer stands as written.

## Story 1 built, the handoff, and the coquí's voice (Nov 13)
- "Build story one". Built as a game, La lluvia, and live.
- "Give me a detailed handoff for an new chat to build out A1 on this spec". The handoff is page 07.
- "Also give the coqui his own voice and let him reply. Speech bumbles and captions. Use the other Puerto Rican voice for the coqui."
- Built: the coquí in es-PR-VictorNeural, speaking his own lines and answering when spoken to; speech bubbles and captions, Spanish only. Captions go against the plan's "sound first"; his word won; he was told in one line.

## His instructions to the build chat (Nov 13)
- "Your job: build out all of A1 on that spec, in the order page 07 gives."
- "My words outrank the plan and the research. If they disagree, do what I said and tell me in one line."
- "Before a story script reaches me, have fresh reviewers check it: one as a beginner against my requirements, one for Puerto Rican Spanish."
- "Before a built story reaches me, have a fresh reader look at frames with no sound and no words."
- "A self-review does not count."
- "Test every path by machine before you send me a link. Send each link with a new ?v= number."
- "Tell me the amount before anything is spent. I type keys and passwords myself."
- "Write to me short and plain, one point per line. Say what is a guess."
- "Don't hand me to-dos. Ask everything you need in one go."
- "Update the project pages at the end of each working session."
- "Don't ask me to confirm the plan. Start building, and tell me when there is something to play."
- "Why are the captions English. Everything should be in spanish." (The code was all Spanish; most likely his phone translated the page. Pages are now marked do-not-translate.) Then: "It's good. Continue". So: nothing on screen in a lesson may turn into English, by any route.
- "Why did you stop creating stories. You were supposed to finish a1." Claude had stopped on its own. Build until A1 is done.

## Audio and voice (Nov 13)
- On recording all the stories with ElevenLabs (about $165): "I feel like 11 is overkill for this. And robot voice is not my only other option". The recorded stories do not use ElevenLabs. ElevenLabs is for the live calls only.
- "Puerto Rican is unnecessary I just want Spanish. The accent isn't that distinct. Completely irrelevant for this stage". Then, after Claude wrongly swapped the Puerto Rican words out of the course: "I said it was unnecessary for the voice. An accent at this stage doesn't matter. You're limiting my options based on that and I want all the options available to me."
  - So: never filter voice options by accent. Show him all of them. The course words stay Puerto Rican.
- "Okay - we'll go recorded". The audio is made once and saved as files (on Azure). It is not generated on demand each time a line plays.
- He picks the voice by ear. Claude cannot hear audio.

## His order for this plan
- "review all the research again… First design the A1 course, progression logic, scenes, scene logic for misses. Be thorough. Validate whether or not the first should only include listening. If so, it probably needs more than one scene. Or a way to get more repetition without getting boring., once all that is figured out then you can write the scripts for generation, your plan needs to be reviewed before you move forward."
- He then asked whether the plan had an INDEPENDENT review (it had not), asked what was guessed, and had seven research prompts run (six reports came back; the one on retention did not).
- "Don't you need info on game design itself?"

## How he wants to be told things
- Short, plain, one point per line. No padding. Say plainly what is a guess. Do not manufacture criticism; raise only what matters.
- Does not want to-dos handed to him; Claude does the mechanics.
- Verify numbers before putting them in a document.
- Apply an instruction at exactly the scope he states. Do not stretch it to things he did not say.
- Do not do extra work he did not ask for. Answer the question at the size he asked it.
- Ask everything needed in one go.
- A plan gets an independent review (fresh reviewers who did not write it) before it goes to him. A self-review does not count.
- Say plainly when Claude's own work caused a problem.
