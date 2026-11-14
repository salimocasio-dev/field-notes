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

## What is built (v=33, Nov 14)

Rebuilt in two rounds after the owner called the app "a mess"; the decisions are in historia/notas/ui-decisiones-1.md and ui-decisiones-2.md, the screenshots of each round in the orchestrator's scratchpad (uitour1, uitour2, uitour3).
- One system: green #17803F for anything that starts or continues learning, blue #3B5BDB for other primary actions; one green 48 px play disc; one outline secondary button; 48 px targets 16 px apart; 8-point grid; H1 24, H2 18, body 16, labels 12.
- Lessons (story, ¿Cuál?, level check) are full screen on calm dark grey, the tab bar hidden: a top bar with a close X (works mid-play and returns to where the lesson began), a thin progress bar and the sound button; pictures whole-number scaled; the start disc in the bottom third; at a story's end its last picture stays, with the title and buttons under it.
- Map: stop states (current ringed, done green, open outlined, locked grey); the Today card never covers a stop; small phones and landscape scroll the map instead of shrinking it.
- Place sheet: 70% high, a close X, the tab bar stays usable.
- Biblioteca lists only what he has played; reading audio stops when its sheet closes. Palabras reviews only heard words. Hablar shows calls as "Calls open later" (the old test page is no longer linked). Each tab keeps its scroll.
- Fixed with it: finished stories now record progress (they recorded nothing before: a `window.PAL` test in juego.js).

## Not done from the doc

- The mic states, live waveform and pitch contour (calls are not open yet).
- Per-word tap-to-jump in reading (tap works per line).
- A rich haptic on unlocking a place; streak freezes; the map at an angle; finished places changing the map's art.
- 28 story words have no picture pair; they show as plain rows under "More words" in Palabras.
