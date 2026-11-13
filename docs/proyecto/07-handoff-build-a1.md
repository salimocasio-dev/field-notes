# Handoff: build out A1

Written Nov 13 2026 by the chat that built story 1. For a new chat that starts with none of that chat's memory or files.
(Copy of the claude.ai project page. Page 08 records what was built after this; where they differ, 08 wins.)

## The job

- Build out the whole A1 course of Coquí on the spec that now exists: the A1 plan, the 40 scenes, and the game model that story 1 was built on.
- Salim's words: "Give me a detailed handoff for an new chat to build out A1 on this spec".
- Then, a minute later: "Also give the coqui his own voice and let him reply. Speech bumbles and captions. Use the other Puerto Rican voice for the coqui. Just include those changes in the handoff".
- So the first job is that change to story 1. (DONE Nov 13, see 08.)
- He has not said how story 1 felt or sounded. Treat the spec as approved to build. When his notes on story 1 come, they apply to every story.

## Read these first, in this order

1. 03-requirements. Everything he has asked for and rejected, in his words.
2. 00-start-here. State, decisions that stand, mistakes already made, how he wants to work.
3. 06-stories-1-3-game. The game model, the scripts of stories 1 to 3, how it scales, what four reviewers found.
4. 01-plan. The A1 plan: the app, the course, progression, misses, time, cost, checks.
5. 02-all-40-scenes. The ten places, 40 scenes and their words.
6. 05-build-and-tools. What is built, ids, costs, the audio route.
7. 04-research-notes. Only when a design question comes up.

## What outranks what

1. His words. Always.
2. The plan doc and these pages.
3. The research reports. They inform. They never override him. His words: "This needs to stop happening."

Where a report or the plan disagrees with something he said, do what he said and tell him so in one line.

## Where things are

- Voice samples (96 Spanish voices, pick by ear): https://salimocasio-dev.github.io/field-notes/historia/muestras/
- Old test page (a map, two scenes, a live call with Danny; first-draft rules): https://salimocasio-dev.github.io/field-notes/
- Code: GitHub project salimocasio-dev/field-notes. Public. The main branch is the live site. Attach it with push access before anything else.
- Plan doc, the one he reads: https://claude.ai/artifact/DAUEyjyynrQe5x1uZRFKcJ
    - Tabs: Plan, Stories 1 to 3: the game, All 40 scenes, First draft (old).
    - Doc id 6280254d-a04b-4d71-9575-7447225a5037. Plan tab body: node 033f3313-3a12. Game tab body: node 83006dbc-079c. Scenes tab body: node 2bcea587-80f6.
    - If the doc and these pages differ, the doc wins. Bring changes back here.
- Research reports: in his Google Drive. Links are in 01-plan, "Sources".
- Azure Speech: resource coqui-voz-2611, region eastus, free tier F0. Its key is the secret AZURE_SPEECH_KEY in the GitHub project. Nobody but him handles the key.
- Danny, the live voice agent (ElevenLabs): ids, settings and tests are in 05-build-and-tools.

## How the code is organised

All under historia/ in the GitHub project. (See 08 for files added since: palabras.js, cual.js, cual.html, curso.js, app.html, fuentes/, tools/cual_check.py.)

| File | What it is |
| --- | --- |
| index.html | Loads the scripts for a story. The script tags carry ?v=N. Raise the number when any script changes, or phones keep the old one. |
| engine.js | The drawing library: pixel buffer (Buf), palettes (RP), sprites (mkCoqui, mkAbuela, mkPalm, mkBush, mkPot, mkDog, mkTree), sky, grass, icon bubbles (bubble, with glyphs in GL and colours in GC). |
| juego.js | The game engine. The same for every story. |
| escenas/frente.js | The scene El frente: its drawing, its states, its actions. |
| cuentos/*.json | The stories as data. |
| audio/ | The recordings and ready.json. |
| tools/voz.py | Makes the recordings on Azure. |
| tools/juega.py | Plays a story by machine. |
| muestras/ | The voice samples page. |

**Sizes.** The picture is 196 by 216 on screen. A scene is 240 by 216 and a camera shows part of it. One tick is 70 ms.

**A story file** has: id, title, place, scene, goal, stake {thing, steps}, focus_words, also_heard, names, clips, beats, final (plus, since: next, dots, bien, cam, palabras, back_again).

- clips: every spoken line. {"id": {"who": "narr" | "tu", "text": "...", "habla": "abuela" (optional)}}. Clip ids are shared by all stories. The same id must have the same text everywhere (voz.py stops otherwise).
- names: for a free poke. {"thing touched": "clip id that names it"}.
- beats, then final: lists of steps. A step is one of:

| Step | Does |
| --- | --- |
| "clip_id" | Says the line. |
| {"say": id, "gap": ms} | Says it, with a set pause after. |
| {"wait": ms} | Waits. |
| {"cam": name, "n": ticks} | Moves the camera to one of the scene's named views. |
| {"dots": n} | Lights n progress dots. |
| {"set": {...}} | Sets values in the world. |
| {"if": cond, "then": [...], "else": [...]} | cond is "name", "!name" or "name=value". It looks in the story's variables, then the world (lost, rain, win, wet...). |
| {"act": name, ...} | Runs one of the scene's actions. |
| {"ask": thing, "loose": bool, "lead": [...], "line": id, "after": [...], "then": [...]} | An ask with the big sign. A touch counts from the first word of the lead. Then: signal, "after" steps, "¡Muy bien!", "then" steps. |
| {"decide": kind, "options": [a, b], "as": "a", "other": "b", "alterna": bool, "pick": "$b", "do": act, "tests": word, "lead": [...], "line": id, "wrong": [...], "right": [...]} | A decision. See below. More steps were added since: see 08. |

- In any clip id or argument, $name is filled from the story's variables. "as" and "other" name the drawn option and the other one. $x is the wrong thing he touched.

**A decision, as the engine runs it**

1. It draws the right option at random. With "alterna" it takes the other one than last play. With "pick" it is fixed. A URL value named like "as" forces it (?a=puerta).
2. It says the lead and the line. No sign. Both options are live. Anything else he touches is named, free.
3. He touches one. The scene's "do" action runs on what he touched. What he did stays done.
4. Wrong: the "wrong" steps, one step of the stake is lost (the scene's stake() shows it), then the big sign shows the right one and he does it.
5. Then the signal for right, "¡Muy bien!", and the "right" steps.
6. Each decision is logged: word tested, what was asked, what he touched, right first time or not, ms. The word records now store it (08).

**A scene file** registers ESCENAS.name = {SW, SH, CAM, handAt, heartAt, fresh, draw, box, hit, poke, acts, stake, talkAt, hud}.

- fresh(): the scene's starting state. draw(c, W, a): draws everything, frog included. box(k, W): the box of a thing, for signs and stars. hit(x, y, W): what was touched. poke(what): a scene's own reaction to a free touch. acts: the named actions a story can call. stake(lost, max, en): shows the thing at stake taking a step. talkAt(who, W): where a speech bubble points. hud(g, W): drawn on top, screen coordinates.
- A scene may use the engine's: W (the world), V (story variables), F (frame count), S (the story), cam, wait, say, camGo, hopTo, bounce, fx, SFX, tone, frog, frogBox, bub, runId, FAST, TICK, TALK.

## How the story game sits inside the app

- The app (historia/app.html, see 09) is the home. The map is its centre tab.
- He taps a stop on the map, or the Today card. Both open index.html?cuento=id&desde=app.
- When the story ends, the game reports by itself into the word records (palabras.js): which story, how it ended, the decision log. The learner never reports his own result. (Never call a piece of software a "player" when writing to him; he read it as meaning he had to do it.)
- An arrow at the end goes to the next story; a home button goes back to the app.
- The old test page stores his test progress under coqui.v3. Do not wipe it.

## How to test, record, publish and check

- **Test.** Serve the repo (python3 -m http.server 8765) and run historia/tools/juega.py (story) or cual_check.py (¿Cuál?). Their first lines say how. ?fast=3 speeds it up. TL=1 times every spoken line. The page exposes its state as window.Story.
- **Record.** Push a change to a file in historia/cuentos/. The job "Voz" starts by itself, records only clips whose text, voice or pace changed, and commits them ("Audio: cuento"). About 3 minutes for 34 clips. Pull before the next push or the push is refused.
- **Publish.** Push to main. The live site rebuilds in about a minute.
- **Check the live site.** The workspace may not open github.io. Ask GitHub instead, no token needed:
    - https://api.github.com/repos/salimocasio-dev/field-notes/deployments?environment=github-pages&per_page=1 (then its statuses_url: "success")
    - https://api.github.com/repos/salimocasio-dev/field-notes/actions/runs?per_page=3
- **Give him a link with a new ?v= number** every time.
- The page cuts the silence at both ends of each recording. Pauses are set by the story.

## Then: build out A1, in this order

1. Stories 2 and 3 of El frente. (DONE, see 08.)
2. Word records and the scheduler; the next-day ¿Cuál? pass. (DONE, see 08.)
3. The app shell. (DONE, rebuilt to his UI plan, see 09.)
4. **Place 1, La casa, complete.** All its scenes and stories, about 4 hours of Escuchar, the reading texts, its call with Danny. The plan has him use it for a week before more is built. That is his call to make or skip.
5. **The level check.**
6. **Places 2 to 10.** Then the fort check. A2 comes after.

Sizes to keep in mind (from the plan; the hours and characters are estimates):

- About 100 stories across 40 scenes. Each needs its script, its scene pictures, its lines.
- The pictures are the biggest job. Original pixel art only.
- About 40 hours of Escuchar. About 1 million characters of recorded audio for all of A1.
- Azure's free tier is 500,000 characters a month and stops there. It cannot bill. More in one month needs a paid tier, and that needs his yes with the amount.

## How to write a story

Page 06 is the model. The short form:

- A goal he can see without words. One thing at stake, lost a step at a time.
- The opening is his sketch: the voice talks to him in whole sentences, asks a real question, a big sign shows what to touch. Nothing can go wrong.
- A turn. Then two or three real decisions with no sign.
- An ending by what is left. Losing changes the picture. It never removes a beat.
- The coquí speaks his own lines (who: "tu", Victor's voice) where he is spoken to or reacts.

Check every story against this list. Each line is something a reviewer caught:

- Every decision that costs has two real options, and the picture does not say which. Only the Spanish does.
- A word is shown or taught before it decides anything.
- A right move changes something for good, and always gets the same signal.
- Nothing in the picture after a right move points at the next answer. (A lamp beside the door did. The frog standing at the door did.)
- No ask is repeated to pad.
- Each new word is heard at least three times on a clean run.
- A miss is filed under the word that decided it.
- Poking around is free. Waiting is free. No clock.
- Who is talking is always clear.
- The voice: slow, plain, A1 words, short praise, no pet names, nothing religious. Course words are Puerto Rican.
- Words outside the scene's list are allowed. He hears many and focuses on the new ones.
- Free-touch names are short sentences ("Es la puerta."), never bare labels.

## Reviews he expects

- A plan or a story script gets fresh reviewers who did not write it, before it goes to him. One plays it as a beginner and checks it against his words. One checks the Spanish as a Puerto Rican speaker. A self-review does not count.
- Anything built with pictures gets a fresh reader who sees only frames, with no sound and no words (?txt=no), and says what is happening.
- Fix what is real. Tell him what was found and what was left.
- He is the last check. Claude cannot hear audio. Only he can say how it sounds.

## What needs his yes

- Any spend. Tell him the amount first. ElevenLabs calls and tests use his credits. Check the balance before any call.
- Opening an account or a paid resource.
- Downloading a file.
- Sending his email address to any outside service.
- He types keys and passwords himself. Never type or show one.
- The ElevenLabs agent is locked to the test page's address. Removing that lock was refused as a security change. It is his decision. Do not work around it.
- The 625-word list by Wyner is paid and copyrighted. Use its method. Never copy it.

## Open items and known flaws

- Plan doc game tab: "The porch lamp, between the door and the window, comes on and stays on." becomes "The lights come on inside and stay on: the shutters and the door both glow." Also "A porch lamp." (list of things drawn), "the porch lamp coming on" (guesses), "turns the porch lamp on" (reviewer 3), and the first line, which still says nothing is built.
- The Plan tab still describes the old way in "Each story is played three ways", "Touch" and "Scripts and audio". Bring them in line with the game model.
- Story 1: the second knock is always the other place, so it can be worked out. He has been told.
- Story 1: in a still frame abuela's wave at the door can look like a raised fist.
- The belief that Azure's free tier allows 20 requests a minute is from memory. The job waits 3.2 seconds between lines.
- Still missing: the report on what keeps adults coming back, the check against the Instituto Cervantes A1 inventory, a Puerto Rican speaker's check of the word list.
- GitHub will require two-factor sign-in on his account by December 9, 2026. Only he can turn it on.

## Things that go wrong in this workspace

- A new chat has no local files. Clone the GitHub project again.
- The shell refuses to delete with a variable in the path. Use new folder names.
- The workspace cannot reach Azure or github.io. GitHub can reach Azure. That is why the audio job runs there.
- The local test server stops between turns. Start it again in the same command as the test.
- Screenshots taken the instant a state changes can miss the redraw. Wait about 300 ms.

## How he wants to work

- Short and plain. One point per line. He reads on his phone.
- Answer at the size he asked. No extra work he did not ask for.
- Say what is a guess. Say when Claude's own work caused the problem.
- Do not hunt for something to criticise.
- Ask everything needed in one go. Do not hand him to-dos.
- Check numbers against the source.
- Looking at websites is approved.
- Use judgement that follows his words. He should not have to spell things out twice.
