# Reading (Leer) and review (Palabras, Repaso): the redesign (Nov 19)

Decided by the build session after the research of Nov 19 (his UI plan doc, the seven Drive reports, the A1 plan, and a web review of the evidence and of reading and review apps). His words outrank all of it. Builders apply this page exactly; a question it does not answer is reported, not decided.

His ask: "Reading and flash card parts of the app need design and feature work. They are so bad there's no point in opening them up."

## What is wrong today
- Leer: a 70% bottom sheet with every line of the script at once, game prompts included ("¿Puedes tocar la silla de abuela?"), no pictures, "Abuela dice:" prefixes, and 35 to 78 mp3s decoded before it opens. Only map stories; three of them use placeholder hacks.
- Palabras: the grid shows only words with a picture pair; tapping a card plays the review sentence, not anything about the word; the mouth record never shows; "Add a word or a goal" stores text and does nothing.
- ¿Cuál?: a word always shows the same two pictures; a miss never comes back in the session; nothing happens if he waits; the end screen is a number.

## Rules that bind this (his)
- No English in learning content: no translation, no gloss. English only in menus, labels, the welcome, the stuck line.
- No self-report: no swipe-to-rate, no "I knew it". The app finds out by asking.
- Reading from day 1, not tracked until A2: reading writes no word record.
- Original pixel art; pictures must read with zero words known.
- Only the map is game-styled. Reading and review are calm screens (UI plan).
- Spanish text is shown exactly as recorded.

## Leer: a picture book of each story he has played

### The shelf (Biblioteca tab)
- Per place (h2 = place name), one row per story he has played: a small cover picture (its first page), the title, and two buttons: Listen (the story straight through, as "Otra vez" today) and Read (opens the book). A small check after a book has been read to its last page (completion only; no word record).
- The Escuchar picture stories and routines of a finished place appear the same way.
- Nothing he cannot open yet is listed; one grey line counts them (as today).

### The book
- Full screen, calm (the lesson frame: close X top left, a thin page-progress bar, text size button top right, tab bar hidden). Close returns to the shelf.
- One page at a time: the picture on top (whole-number scaled, the scene as it was at that moment of the story), up to three lines of text below, large type (20 px, 30 px line height; a text-size button toggles 20 / 24 px and is remembered).
- The speaker shows as it is in the text (the recording says "Abuela dice: …"); the coquí's lines carry a small "Coquí" label as today.
- Opening a page plays its lines in order; the line playing is lit (line level, not word level: Puerto Rican speech drops sounds the spelling keeps). Then it waits. He can tap any line to hear it again. Next / back: big arrow buttons at the bottom and a swipe; no auto-advance. The last page ends with "Otra vez" (read again) and "Biblioteca".
- Tapping a word that has a picture (the 128 words with a ¿Cuál? pair, matched on the normalised word, multi-word words as phrases): a small card pops over the page with that word's picture (its "sí" picture) and the word; every place the word occurs on the page is underlined for a moment; the card closes on any tap. Other words: the tap plays the line. No translation, ever.
- Audio loads per page (the page's clips and the next page's), not the whole story.

### What goes in a book (the text)
- Built by a tool from the story file, mechanically: the story's lines in play order (its "leer" list if it has one, else the walk of beats and final as today, without placeholder hacks: a $ variable takes the value the all-right first draw gives it).
- Left out: every clip used as the question line of an ask, decide or elige; the engine's generic clips (praise, "Ahora tú.", "Mira.", the sign lines); a clip already used earlier in the book.
- Pages: consecutive kept lines, at most three; a new page when the camera moves, or when the canvas at the next line's start differs from the page's picture in more than 10% of its pixels (decided Nov 19: "a scene act runs" broke three pages in four into one line).
- Picture of a page: the scene canvas captured (no UI, no bubbles, no captions, no HUD counters) at the moment the page's first line starts in an all-right play. "First draw" = each draw's first option, except where a story's own "leer" list needs another draw (the tool's DRAWS table). Saved as PNG at the art's own size, in historia/libros/img/. The book is historia/libros/<story id>.json: pages of {img, clips}.
- Routines (Haz esto) get no book: all their lines are commands. On the shelf they have Listen only.
- A fresh beginner reviewer reads every book (Spanish text only, as a beginner who has played the story) and flags pages that read wrong (a line out of place, a picture that does not match its lines). Fixes go into a per-story override list in the tool, never by hand in the JSON.

## Palabras: every word he has met, and how it stands

### The tab
- Top: the review card (as today, renamed "Repaso"): "N words today · about M min" and Start; when nothing is due: "Nothing due today" and "Practice" (asks his weakest heard words, schedule untouched, as now).
- Then words grouped by place, in story order. Each word is a card: its picture (pair words) or a plain tile (words with no picture), the word, and two small four-dot meters with labels "Ear" and "Mouth" (dots = stage 1 to 4). The word is always spelled (decided Nov 19 after the fresh read: the "?" before stage 2 read as a bug, and the books show every word written from day 1 anyway, so hiding it protected nothing).
- Tap a card: a word sheet opens: the big picture, the word, Ear and Mouth meters with the next return in English ("Comes back in 2 days"), and "Heard in" — up to five lines from stories he has played that contain the word, each with a play button (the story's own recording). No translation.
- "Add a word or a goal" stays (his vision) with honest text: "Saved. Material for it comes later." and the saved list.

## Repaso (¿Cuál?): the session
- Up to 10 words a session (due first, most overdue first). If more are due, the rest wait for the next session; no backlog count is shown beyond "N words today".
- Each item as today: the sentence plays, two pictures, only one fits; a touch before the sentence ends does not count.
- No touch 6 s after the sentence ends: the sentence plays again; 6 s more: the right picture gets the green ring and the sign and he touches it (counts as a miss).
- A miss comes back once in the same session, three items later (or at the end if fewer are left), with the pictures in a new random order; that second ask is not scored (intro), as the plan says ("the word comes back later in the session").
- End screen: the words of the session with a picture each, grouped "Moving up" (right) and "Coming back soon" (missed), and Back to Palabras. No score number.
- The scheduler (palabras.js) is unchanged except: the due check uses the palabras clock, not Date.now().

## Not now (said so it is not invented)
- Word-level karaoke or word audio (no word timing exists).
- Themes (dark/sepia), reading tracking, new recordings, new review item types beyond ¿Cuál?, pictures for the 28 words without a pair.

## After the first fresh read (Nov 19)
- Nothing is ever covered by the tab bar or the Mapa disc: lists, grid and sheets end clear of it.
- Book: the line playing is lit on every page; each line has a small speaker icon (tap to hear it again); words with a picture carry a faint dotted underline; a page count "3 / 9" beside the progress bar; the last page says "Fin" above its buttons, both buttons in the app's green style (no blue), "Otra vez" with a replay icon.
- Shelf: the Read button has a book icon; a read book shows "Read ✓" in place of a bare check.
- Palabras: one key line under the grid title: "Ear: you know it when you hear it. Mouth: you can say it."; a word with no picture is a plain tile with the word large (no empty picture box); the word sheet keeps the word in its header when scrolled; the word is bold inside its "Heard in" lines.
