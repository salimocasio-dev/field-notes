# The app's look: Salim's UI plan (Nov 13)

## His words

- On the first shell (dark cards, a tab bar, the map one tab among many): "What kind of UI is this????"
- On the second (the whole app made into a pixel game): "I didn't say the whole thing is a game, I said on the home screen is the map to the game as the main part of the course."
- He pointed to his plan doc: "Language App UI Design Plan", https://docs.google.com/document/d/1oYSXXDBPCQhxDJ3IbrvKfI7LC2eDjCPhOW8Ljs9BEm0 . It is the spec for the app's UI. Read it before changing any screen.

## What the doc says, in short

- Home is the 16-bit course map, in the centre tab of a persistent bottom tab bar (3 to 5 tabs). Map = home; flashcards/review; library/reading; stats/profile; optional community.
- Hybrid rendering: only the map, terrain, avatar and its animations are pixel art. Buttons, text, pop-ups, counters and the tab bar are crisp modern UI over it. A pixel font only for signs on the map, never for learning content.
- Pixel art scaled nearest-neighbour, by whole numbers; no sub-pixel movement.
- The map must read instantly: clear paths, done vs locked stops, the current objective highlighted. Branching allowed (autonomy).
- Thumb zone: primary actions and the mic in the bottom third. Targets 48 px or more, 16 to 24 px apart. 8-point grid. Type: H1 24 semibold, H2 16 to 18, body 14 to 16, labels 12.
- Lessons go full screen; the tab bar hides and comes back on exit. Learning screens are calm (white, off-white or dark grey); colour only for meaning (green right, red/orange wrong, blue/purple system and active tab).
- Each tab keeps its state (scroll, place in a deck).
- Speaking: a big mic in the bottom centre with clear states (idle, listening with a live wave, processing within 200 ms, system speaking in another colour); reply within about 0.6 to 1 s; pitch-contour feedback for intonation.
- Reading: karaoke highlight synced with the audio; tap a line or word to jump there. (The doc also says a translation tooltip; see below.)
- Flashcards: spaced repetition; the doc suggests swipe right/left to rate and tap to flip. (See below.)
- Haptics: short crisp ticks on taps, a richer pattern on unlocking a place, never long buzzes. Synced with sound and visuals.
- Avoid gamification fatigue: forgiving streaks (streak freezes), meaningful rewards, no rigid single path.

## Where the build differs from the doc, and why (told to him in one line each)

- No swipe-to-rate flashcards: that is the learner telling the app he knows a word. Review stays the picture check (¿Cuál?), where the app finds out. His rule against self-report buttons.
- No English translation tooltip in reading: his rule that English is only for menus, the welcome and the stuck line.

## What is built (v=34, Nov 14)

Rebuilt in two rounds after the owner called the app "a mess"; the decisions are in historia/notas/ui-decisiones-1.md and ui-decisiones-2.md, the screenshots of each round in the orchestrator's scratchpad (uitour1, uitour2, uitour3).
- One system: green #17803F for anything that starts or continues learning, blue #3B5BDB for other primary actions; one green 48 px play disc; one outline secondary button; 48 px targets 16 px apart; 8-point grid; H1 24, H2 18, body 16, labels 12.
- Lessons (story, ¿Cuál?, level check) are full screen on calm dark grey, the tab bar hidden: a top bar with a close X (works mid-play and returns to where the lesson began), a thin progress bar and the sound button; pictures whole-number scaled; the start disc in the bottom third; at a story's end its last picture stays, with the title and buttons under it.
- Map: stop states (current ringed, done green, open outlined, locked grey); the Today card never covers a stop; small phones and landscape scroll the map instead of shrinking it.
- Place sheet: 70% high, a close X, the tab bar stays usable.
- Biblioteca lists only what he has played; reading audio stops when its sheet closes. Palabras reviews only heard words. Hablar showed calls as "Calls open later" at v=34 (the old test page is no longer linked); v=35 replaces that with the call, below. Each tab keeps its scroll.
- Fixed with it: finished stories now record progress (they recorded nothing before: a `window.PAL` test in juego.js).
- Round 3 (v=34): map stops show done/current/open/locked with an N/M chip; the place sheet marks the next story; story ends offer Play again and Map; landscape lessons keep their controls in the right column; Hablar is one card; the level check's explanation lives in Yo.

## Call screen (v=35, Nov 16)

Built from historia/notas/llamada-decisiones-1.md (code: historia/llamada.js). Only La casa has a call.
- Hablar: one "Call Danny" card for each place, in place order. La casa's opens once all 11 of its stories are played (stories the level check skipped count). Open: "Call Danny", "La casa · about 5 min", a green 48 px call disc. Locked: grey, "Opens when you finish <place>".
- The call is a full-screen lesson screen on calm dark grey #1B1B1F, the tab bar hidden. Top bar: the close X (48 px) at the left, the timer (mm:ss, 12 px) at the right.
- Middle: the picture Danny shows (starts as the house; whole-number scaled, 16 px margins), under it Danny's last line (18 px, white, two lines at most), under that what the app heard the learner say (16 px, #9AD5A8).
- Bottom third: the mic disc (72 px) with its state label, and an outline "Help" button (48 px, sends "(ayuda)").
- Mic states: Start call (green disc, phone icon); Calling… (the disc pulses); Danny (blue #3B5BDB rings spreading from the disc); Your turn (a green ring whose thickness follows the microphone level); One moment (three pulsing dots, once he has spoken and been quiet for 0.6 s, until Danny speaks). Every change shows within 200 ms of its cause.
- The end: the X, the 7-minute limit, or Danny ending it. A summary on the same layout as a lesson end: "Call done", "N min · M words said", the words as small chips, a blue "Back to Hablar" button. Everything stops (session, timers, sound lock) on every way out, and the tab bar comes back.
- Errors are one plain line and the X: "The microphone is off. Allow it in your browser to call." / "The call did not start. Check your connection and try again."
- Landscape (844x390): the picture at the left, the lines and the mic at the right. Small phone (360x640): the picture scales down by whole numbers.
- Checked with the stub (?callstub=1, page 05): states, sizes, colours and layout at 390x844, 360x640 and 844x390.

## Not done from the doc

- Pitch-contour feedback. (The mic states are built for the call at v=35; the learner's side is a level ring, not a waveform.)
- Per-word tap-to-jump in reading (tap works per line).
- A rich haptic on unlocking a place; streak freezes; the map at an angle; finished places changing the map's art.
- 28 story words have no picture pair; they show as plain rows under "More words" in Palabras.
