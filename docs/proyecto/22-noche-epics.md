# Noche: epics and stories for the board

Written Nov 23 2026 from the Noche boards on the canvas "Coquí: new app designs, 3 directions" ([https://claude.ai/artifact/Ls3fG6ZKNzaLW9TeESvPp1](https://claude.ai/artifact/Ls3fG6ZKNzaLW9TeESvPp1), rows 3 and 4) and page 21.

Salim, Nov 23: "turn noche into epics/stories be detailed enough that any coding agent can pick it up and get me consistent results. youtube is backlog stuff along with the integration. the others i want to implement soon."

So:

- Epics 0 to 6 are for now. Each story below is written in the board's story format (repo-root `AGENTS.md`, "A story"), ready to post as one issue.  
- Epic 7 (YouTube) is backlog. It does not go on the board as `status:ready` until he says go.  
- None of this is on the GitHub board yet. Posting it is story N0.1.

---

## Part 1. The Noche rules (every Noche story links here)

Every Noche story says "Follow the Noche rules". These are those rules. A reviewer fails a pull request that breaks one.

### 1.1 Where the design is

- The boards are `Noche-*.dc.html` files. After N0.1 they are in the repo at `docs/proyecto/noche/`, with a PNG of each one next to it (same name, `.png`).  
- Each story names its board files. Open them. A board file is plain HTML with inline styles.  
- **What the board file decides:** every size, padding, gap, radius, colour, font, weight, line height and letter spacing that this page does not write down. Read it from the inline `style` of the element. Do not guess and do not round.  
- **What this page decides:** behaviour, data, and every place where it says the build differs from the board. Where this page and a board disagree, this page wins. Each difference is written in the story as "Differs from the board".  
- Ignore these parts of a board file: `<x-dc>`, `<helmet>`, `support.js`, the `data-dc-script` block, `data-props`, `/_blob/...` image addresses. They belong to the canvas, not the app.  
- The `/_blob/` images on the boards are pictures the app already draws itself: the map (`MapPicture`) and the scene pictures (`PixelView`). Use the app's own pictures.

### 1.2 Sample data is never built in

- Every number, name and line on a board is sample data: "96 words", "6 days", "12 of 30 min", "Tengo hambre", "Un verano en Cabo Rojo", "La cocina", "French", "[PRICE]", "[channel name]".  
- The real value comes from the progress store, the course or the content catalog. If a story does not say where a value comes from, stop and block the story. Do not invent a source.  
- English text on a board that is not sample data (button names, section labels, help lines) is copied exactly, letter for letter, including capitals and the middle dot `·`.

### 1.3 Language on screen

- The app's own text (tabs, titles, buttons, section labels, help lines, accessibility labels) is English. Always. This replaces the old rule "English on screen stays exactly as in v=39" for every screen a Noche story changes.  
- Course content (place names, story titles, lesson lines, words, call titles) is in the language being learned. It comes from content, never from code (boundary rule 9). Mark it with the content language for screen readers (Flutter: the text's `locale`, from `course.language`).  
- Words the app says in the learned language as part of the lesson (the mic labels "Toca y habla", "Te escucho", "Un momento", "Escucha", "¡Muy bien!", "Otra vez") come from the course's language data (story N2.1, `Language.micWords`). Never from code.  
- Accessibility labels are English, even on lesson screens, for now. **Differs from the board:** the lesson and reader boards have Spanish (and Arabic) accessibility labels. This is one switch (Part 1.7), not a rewrite.  
- **Tab names are in the course's language:** Biblioteca, Palabras, Mapa, Hablar, Yo for Spanish; an Arabic course shows its own five words. Salim, Nov 23: "i like the spanish tab names", and on whether an Arabic course should show its own: "obviously". They come from the course (`Language.tabNames`), never from code, drawn in the course's script font with its `lang`. They are the one exception to "the app's own text is English". Titles inside a tab stay English ("Words", "Speak", "Me" on the boards stay as page titles).  
- Section labels in capitals on the boards ("UP NEXT ·", "ALL 9 STORIES") are written in normal case in code and shown in capitals by the text style (`CoquiType.label` sets uppercase). When the label holds content ("UP NEXT · LA COCINA"), the content part is uppercased the same way.

### 1.4 Look

- Colours, fonts and sizes come only from the Noche tokens in coqui_ui (`NocheColors`, `NocheType`, `NocheSize`, story N1.1). No colour literal (`Color(0x...)`) and no font family name anywhere outside coqui_ui. A reviewer greps for `Color(0x` and `fontFamily` in the changed files.  
- Shared pieces (tab bar, buttons, chips, cards, sheets, switches, segmented controls, progress dashes, stage bars, mic) come from coqui_ui (stories N1.2 and N1.3). A feature never draws its own copy. If it needs a piece coqui_ui does not have, it files a request (coqui `AGENTS.md`, "Requests") and uses a local copy until the request lands.  
- One orange thing per screen: the next action. Orange (`NocheColors.next`) is never used for anything else on that screen except the Map disc in the tab bar.  
- No red, ever. A miss is a white outline and the line plays again.  
- Every touch target is at least 48 by 48. Spacing is on the 8-point grid (4 is allowed inside a component, as on the boards).  
- Directional layout only: `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `start` and `end`. Never `left` or `right` in new code. The whole screen must mirror when the course's language runs right to left (Arabic board).  
- Pixel pictures (map, scenes) are drawn at a whole-number scale with `PixelView` and never mirrored.

### 1.5 Screens not drawn yet

These have no Noche board: welcome, level check, ¿Cuál? (review), the touch turn in a story, a live call in progress, the review card, a place locked by plan on the map, the reader's chapter list, Paste text, Web page, the story being written after "Write my story".

Rule: keep the screen's current layout and behaviour. Change only its colours, fonts, buttons and sheets to the Noche tokens and pieces. A lesson-style screen (full screen, no tab bar) uses the lesson ground `NocheColors.lessonGround`. Where a story below gives an undrawn screen a layout, the story says so.

### 1.6 Each pull request shows its screens

- Screenshots of every screen the story changes at the two phone sizes `tool/check_app.mjs` uses: 390 by 844 and 412 by 915.  
- Next to each, the board's PNG from `docs/proyecto/noche/`.  
- A story with right-to-left work also shows the screen with the test course in Arabic (story N2.2 adds it to the fakes).  
- `bash coqui/tool/test_all.sh` passes. `dart run tool/check_boundaries.dart` passes.

### 1.7 Board differences that are switches

Salim, Nov 23: "make sure these are easily implementable when I want." Each difference from the boards below is built so that turning it on later is a data change or one flag, in one package, with no screen rewritten. A reviewer checks each one is built this way.

| Difference | Built as | To turn it on later |
| :---- | :---- | :---- |
| Words show 4 stages, not 5 | Every stage bar and stage-dot row reads `ProgressStore.stageMax` (4 today). Nothing writes 4 or 5 in a feature. | Change the stage rules in coqui_progress; every bar follows. |
| No "1 freeze saved" | `ProgressStore.streakFreezes` is `int?` and returns null today. Me shows `"1 freeze saved"` / `"<N> freezes saved"` under the streak when it is not null. | Build freezes in coqui_progress; the line appears. |
| No sample languages in "Add a language" | The list is the catalog's courses minus the ones started. | Add a course to the catalog; it appears. |
| No "[PRICE]", no "[MINUTES]" | Plans shows `Entitlements.priceOf(plan)` and `Entitlements.callMinutes(plan)` when they are not null; both are null on `AllowAllEntitlements`. | Store billing (N3.5) returns them. |
| English accessibility labels on lesson screens | Every lesson and reader accessibility label comes from one table, `NocheA11y` in coqui_ui, keyed by role (`close`, `hearAgain`, `mic`, `captions`, `back`, `textAndPage`, `chapters`, `sentenceAgain`, `listen`, `speed`, ...), English. `Language.a11yWords` is an optional map with the same keys. One flag, `NocheA11y.lessonLabelsInCourseLanguage` (false), chooses the course's word when it has one, English otherwise. | Set the flag to true and add `a11yWords` to the course file. |

### 1.8 Things that cost money or need Salim

- No story here records audio, calls Danny, buys anything, opens an account or adds a key.  
- No story adds a third-party package on its own. Where one is needed, the story says so: the builder checks the package's page on pub.dev (licence, platforms, maintenance), writes the choice and its reason in the pull request, adds it to the allowed list in `tool/check_boundaries.dart`, and the reviewer from the other company must agree before merge.

---

## Part 2. The order

Stories in different lanes run at the same time. A lane holds one story at a time (repo-root `AGENTS.md`).

### Who can work at the same time (Nov 23)

- **coqui_ui is its own package (lane).** Noche adds new names beside the old ones and changes none of them, so nobody's work breaks while it is built. The only story that can break others is N1.4 (removing the old look), and it goes last.  
- **One writer at a time in each core package** (coqui_ui, coqui_contracts, coqui_progress, coqui_content, coqui_platform, coqui_testing). Different core packages can be worked on at the same time.  
- **Gemini is porting scenes.** Those stories hold `lane:coqui_scenes` and `lane:feature_story`. So N2.6 and N4.3 (feature_story) wait until the port series is done, and go to Gemini then: it knows that code. Nothing else here touches those two lanes.  
- **Start now, before N0.1:** N1.1 (coqui_ui) and N2.1 (coqui_contracts). Everything they need is written on this page; they need no board file. Both to Gemini, as two tasks at once (separate sessions from its scene ports).  
- **Next, at the same time, once those merge:** N1.2 (coqui_ui, Gemini again), and N2.2 to N2.5 (four different core lanes, Gemini, as many at once as it can run).  
- **Then the screens,** one per feature lane, all at the same time except feature_story: N4.1 and N4.2 (feature_map), N4.4 (feature_words), N4.6 (feature_speaking, after the Danny-call stories), N4.7 (feature_profile), N4.5 and epic N5 (feature_library, after #2).  
- **Multi-AI workflow (updated Nov 24, governed by root `AGENTS.md`):** Antigravity (Gemini 4 Neon / Carbon planner + Hydrogen `high` executor in isolated worktrees) builds feature packages; Claude Code handles `coqui_contracts`, `coqui_ui` tokens, and `coqui/requests/` merges when quota is available (otherwise Antigravity handles them under strict cross-model review). Every PR is independently reviewed by **Claude API** (automated read-only GitHub Action) and **Codex (ChatGPT Plus)** before merge. *(Historical Nov 23 note: originally posted as `agent:gemini` build / ChatGPT review during temporary Claude quota pause.)*

| Wave | Stories (lane) | Waits for |
| :---- | :---- | :---- |
| 0 | N0.1 (docs, Gemini) | nothing (runs alongside wave 1) |
| 1 | N1.1 (#79, coqui_ui), N2.1 (#84, coqui_contracts) | nothing |
| 2 | N1.2 (#80, coqui_ui), N2.2 (#85, coqui_testing), N2.3 (#86, coqui_content), N2.4 (#87, coqui_progress), N2.5 (#88, coqui_platform) | wave 1 |
| 3 | N1.3 (#81, coqui_ui); the language stories N2.6 (#89, feature_story), N2.7 (#90, feature_review), N2.8 (#91, feature_words), N2.9 (#92, feature_speaking) | wave 2 |
| 4 | the Noche screens: N4.1 to N4.8 (#101–#109), N3.2 to N3.4 (#96–#98), N2.10 (#93), N5.1 to N5.4 (#112–#115) | the stories each one names |
| 5 | N4.9 (#110) and N2.11 (#94) (app, Gemini), then N1.4 (#82, coqui_ui, removes the old look) | every screen story merged |

Stories already on the board that touch the same lanes:

- #12 (feature_map, "Opening a place shows one obvious next step") is replaced by N4.2. If #12 is unclaimed when N4.2 is posted, close #12 with a link to N4.2. If it is claimed or merged, N4.2 builds on it.  
- #2 (feature_library, Biblioteca) goes first. N4.5 and the epic 5 stories wait for it to merge.  
- #4 to #7 (Danny calls) go first in their lanes. N4.6 and N3.3 wait for the ones in feature_speaking.  
- #9 and #10 (flashcards) go first in feature_review. N4.8 waits for them.

---

## Part 3. The epics

Epic N8 (motion between selections) is on its own page: [`24-noche-motion.md`](24-noche-motion.md).

### Epic N0. Get the boards to every agent

Not a feature. One story, for Gemini.

#### N0.1 Put the Noche boards and this page in the repo, and post the epics

- Labels: `type:story`, `agent:gemini`, `lane:docs`, `status:ready`.

**Salim's words**

> turn noche into epics/stories be detailed enough that any coding agent can pick it up and get me consistent results.

**Done when**

- `docs/proyecto/noche/` holds the 18 `Noche-*.dc.html` files from `noche-boards.zip` in the Drive context folder, byte for byte (their sha256 sums are listed in the folder's `noche-boards-sha256.txt`).  
- Each has a PNG beside it, rendered at 390 by 844 (Mic states at 808 by 568) with the fonts of story N1.1 installed, and looked at: nothing clipped, nothing missing. If this session cannot render, say so to Salim in one line and post the stories without PNGs.  
- This page is in the repo as `docs/proyecto/22-noche-epics.md`, with its links pointing at the repo copies.  
- One `type:epic` issue per epic N1 to N6, each with its stories as sub-issues, posted with the labels each story lists. Epic N7 is posted as an epic with `status:blocked` and the note "Backlog. Not before Salim says go." Its stories are not posted.  
- The issue number of each story is written next to it on this page (live tracking is on GitHub Issues only; Drive `01 Backlog` is archived).
- #12 is handled as Part 2 says.

**Lane** lane:docs (and `.github/` is not touched).

**Links** Page 21 (design notes), this page.

---

### Epic N1. The Noche look (coqui_ui) (#78)

The tokens, fonts and shared pieces every screen uses. Nothing else can start until N1.1 and N1.2 are merged.

#### N1.1 Noche tokens, fonts and text styles (#79)

- Labels: `agent:gemini`, `lane:coqui_ui`. Waits for nothing: everything it needs is on this page.

**Salim's words**

> noche is definitely it. lets a research supported blue to replace the green. and an goldish orange make those recommended changes

**What to build**

New tokens beside the old ones. The old `CoquiColors`, `CoquiText` and the rest stay until N1.4 removes them, so features can move one at a time.

`NocheColors` (`lib/src/noche_tokens.dart`), exactly these:

| Name | Hex | Job |
| :---- | :---- | :---- |
| `ground` | #0C1926 | page ground of every tab screen |
| `panel` | #152A3D | cards, sheets, tab bar, chips |
| `chip` | #213D57 | chips on panels, selected tiles in sheets |
| `line` | #33506B | borders, empty track of bars, dashes not reached |
| `bar` | #4A6C8C | neutral chart bars, sheet handle, input border |
| `text` | #EEF3F7 | text, selected pill fill |
| `label` | #A7B8C8 | small labels, secondary text |
| `dimLine` | #8FA2B5 | lines of a transcript not being spoken |
| `lessonGround` | #12171D | full-screen lesson, reader Night page, players |
| `lessonLine` | #37424D | not-reached dashes and empty bars on lessonGround |
| `lessonBorder` | #4A5663 | outline buttons on lessonGround |
| `lessonLabel` | #8C99A6 | small labels on lessonGround |
| `lessonPanel` | #1B232C | the playback bar on lessonGround |
| `litSentence` | #24313F | the sentence being read, the current transcript line |
| `onAccent` | #14110F | text and icons on orange or green |
| `next` | #E69F00 | the next action (Okabe-Ito orange) |
| `listening` | #56B4E9 | the app is listening; never-heard underline; coverage bar |
| `listeningSoft` | #1D3A52 | the soft disc and tag behind sky-blue text |
| `other` | #CC79A7 | thinking, and the other voice speaking |
| `otherSoft` | #3A2433 | the thinking disc |
| `right` | #009E73 | heard right |
| `micResting` | #28323C | the mic while the other voice speaks |
| `scrim` | #B80C1926 | behind a sheet (`rgba(12,25,38,.72)`) |
| `sepiaPage` / `sepiaText` / `sepiaLabel` / `sepiaRule` | #F2E8D5 / #2E2519 / #6B5B45 / #B9A682 | reader, Sepia page |
| `dayPage` / `dayText` | #FAF8F3 / #1B1B1B | reader, Day page |
| `nightText` | #D8DEE4 | reader, Night page body text |

The two book-cover pairs (Library and Add your own): `coverPlum` spine #6B4059, face #3A2433, mark #CC79A7; `coverBlue` spine #4A6C8C, face #213D57, mark #E69F00.

Not on any board, Claude's derivation (checked Nov 23: dayLabel on the Day page 6.3:1; body text on dayLit 13.6:1; Sepia text on sepiaLit 10.5:1): `dayLabel` #5C5C5C, `dayRule` #C9C4B8 (a rule, not text), `dayLit` #E9E4D8, `sepiaLit` #E4D6BA.

Fonts. Bundle them in `coqui_ui/fonts/` the way Roboto is bundled (see the comment in `pubspec.yaml`): one static TTF per weight, cut from the source with fonttools, nothing synthesised, each declared twice (plain name and `packages/coqui_ui/<name>`), licence file beside them.

| Family name in code | Source in github.com/google/fonts at commit 06bfe0d62a98375cb09c942fa18e68bd32cff057 | Static weights to cut | Axes pinned |
| :---- | :---- | :---- | :---- |
| Atkinson Hyperlegible Next | `ofl/atkinsonhyperlegiblenext/AtkinsonHyperlegibleNext[wght].ttf` | 400, 500, 600, 700, 800 | - |
| Bricolage Grotesque | `ofl/bricolagegrotesque/BricolageGrotesque[opsz,wdth,wght].ttf` | 700, 800 | wdth 100, opsz 24 |
| Bricolage Grotesque Display | same file | 800 | wdth 100, opsz 72 |
| Literata | `ofl/literata/Literata[opsz,wght].ttf` | 400, 500, 600 | opsz 19 |
| Literata Italic | `ofl/literata/Literata-Italic[opsz,wght].ttf` | 400 | opsz 19 |
| Lexend | `ofl/lexend/Lexend[wght].ttf` | 400, 500 | - |
| Noto Sans Arabic | `ofl/notosansarabic/NotoSansArabic[wdth,wght].ttf` | 500, 700 | wdth 100 |

- Cut: `fonttools varLib.instancer <src> wght=<w> [opsz=<o>] [wdth=100] -o <Family>-<w>.ttf`.  
- Subset the Latin families to `U+0000-024F,U+0300-036F,U+1E00-1EFF,U+2000-206F,U+20A0-20CF,U+2100-214F,U+2190-21FF,U+2212,U+FEFF,U+FFFD` and Noto Sans Arabic to `U+0000-007F,U+00A0,U+060C-06FF,U+0750-077F,U+08A0-08FF,U+200C-200F,U+FB50-FDFF,U+FE70-FEFF` with `pyftsubset --layout-features='*'`.  
- Copy each family's `OFL.txt` as `fonts/LICENSE-<family>.txt`.  
- If the machine cannot reach github.com, block the story with that one line. Do not take the files from anywhere else.

`NocheType` (text styles). Every style sets `fontWeight` and the family. These are the only styles features use:

| Style | Family | Weight | Size / line height | Other |
| :---- | :---- | :---- | :---- | :---- |
| `pageTitle` | Bricolage Grotesque | 700 | 24 / 24 |  |
| `sheetTitle` | Bricolage Grotesque | 700 | 20 / 24 | plan names, card headings |
| `bigNumber` | Bricolage Grotesque Display | 800 | 64 / 64 | Words "due today" |
| `statNumber` | Bricolage Grotesque Display | 800 | 56 / 48 | Me minutes |
| `label` | Atkinson | 600 | 12 / 12 | uppercase, letter spacing 0.72 (0.06 em) |
| `labelStrong` | Atkinson | 700 | 12 / 12 | uppercase, letter spacing 0.72 |
| `tabLabel` / `tabLabelOn` | Atkinson | 600 / 700 | 12 / 12 |  |
| `button` / `buttonStrong` | Atkinson | 600 / 700 | 14 / 14 | pills, chips |
| `primary` | Atkinson | 700 | 18 / 18 | orange 56-high buttons |
| `primarySmall` | Atkinson | 700 | 17 / 17 | Continue reading, Choose a file |
| `body` | Atkinson | 500 | 14 / 20 | help lines |
| `bodySmall` | Atkinson | 500 | 13 / 16 | meta lines |
| `bodyLarge` | Atkinson | 500 | 16 / 24 | the line under a call title |
| `row` | Atkinson | 600 | 18 / 24 | word rows, language names |
| `cardTitle` | Atkinson | 700 | 22 / 24 | next story, play bar |
| `rowTitle` | Atkinson | 700 | 16 / 20 | call cards, file names |
| `placeTitle` | Atkinson | 800 | 32 / 40 | place name, call title (32 / 36) |
| `lessonLine` | Atkinson | 600 | 28 / 36 | the line spoken in a lesson |
| `lessonPrompt` | Atkinson | 500 | 18 / 24 | "Dile a Abuela: ..." |
| `transcript` / `transcriptNow` | Atkinson | 500 / 700 | 17 / 24, 24 / 32 | video text |
| `bookTitle` | Literata | 600 | 26 / 32 | chapter head |
| `bookBody` | reader's choice | 400 | 19 / 31 by default | see N5.2 |
| `dropCap` | Literata | 600 | 60 / 52 |  |
| `cover` | Literata | 600 | 13 / 16 (10 / 12 small) | type-only covers |

A style used on course content takes its family from the course's script: `NocheType.forScript(style, script)` returns the same style with Noto Sans Arabic, size +2 and line height about 1.7 for `Arab` (the Arabic board: 30 / 52 for the lesson line, 20 / 36 for the prompt, 14 / 24 for labels). Any other script without a bundled font falls back to the platform font and is reported, not guessed.

`NocheSize`: `touch` 48, `pill` radius 24, `card` radius 24, `tile` radius 16, `chip` height 32 radius 16, `tab bar` height 64 radius 32 inset 16, `primary` height 56 radius 28, `play bar` height 72 radius 36, `mic` 96, `disc` 64, `aboveTabBar` 104 (the bottom of anything sitting above the tab bar), `grid` 8.

**Done when**

- The tables above are in code, names as written. Each colour has a test with its hex.  
- A contrast test computes WCAG contrast for: text, label and next on panel; onAccent on next; listening, other and right on lessonGround; the four reader pages' text and labels. Every one is at least 4.5.  
- The fonts load in `flutter test` (a golden of one line in each family and weight) and in the web build.  
- Nothing outside coqui_ui changed. No old token changed.

**Lane** lane:coqui_ui. Files outside it: only coqui/requests/.

**Links** Page 21, "Fonts" and "Colours". Every board file.

#### N1.2 Noche shared pieces (#80)

- Labels: `agent:gemini` (the same agent as N1.1), `lane:coqui_ui`. Waits for N1.1 and N0.1.

**What to build**

Each piece is a widget in coqui_ui, directional, at least 48 high where it can be touched, with its board file named for its exact metrics.

| Piece | What it is | Board file to measure |
| :---- | :---- | :---- |
| `NocheTabBar` | Floating bar: inset 16 from start, end and bottom, 64 high, radius 32, panel fill, 1 px line border, 5 equal columns. Tabs in this order: library, words, map, speak, me. Labels from `course.language.tabNames` (Spanish: Biblioteca, Palabras, Mapa, Hablar, Yo), in the course's script font (`NocheType.forScript`). The bar's order does not mirror. Icons 22, stroke 2. The current tab: icon in a 48 by 28 pill (fill `line`), label `tabLabelOn` in `text`. Others: `label` colour. Map is a 56 disc in `next` with an `onAccent` icon (26, stroke 2.2), raised 24 above the bar, with a 4 px ring of `ground`, on every screen, current or not. | [`Noche-Mapa.dc.html`](noche/Noche-Mapa.dc.html), [`Noche-Palabras.dc.html`](noche/Noche-Palabras.dc.html) |
| `NochePill` | 48 high pill. Kinds: outline (panel fill, line border, `button`), selected (text fill, ground text, `buttonStrong`), dashed-locked (no fill, dashed line border, lock icon 20, 48 wide), plan-tag (no fill, 1 px `next` border, `labelStrong` in next, 24 high, radius 12; a tag, never touchable). | [`Noche-Biblioteca.dc.html`](noche/Noche-Biblioteca.dc.html), [`Noche-Hablar.dc.html`](noche/Noche-Hablar.dc.html), [`Noche-Hablar-Plan.dc.html`](noche/Noche-Hablar-Plan.dc.html) |
| `NocheChip` | 32 high, radius 16, `chip` fill, `button`. Not touchable. | [`Noche-Hablar.dc.html`](noche/Noche-Hablar.dc.html) |
| `NocheCard` | Panel fill, 1 px line border, radius 24, padding 16 (24 where the board has it). Variants: `highlight` (2 px next border), `dashed` (no fill, dashed line border, label text). | [`Noche-Mapa.dc.html`](noche/Noche-Mapa.dc.html), [`Noche-Hablar-Plan.dc.html`](noche/Noche-Hablar-Plan.dc.html) |
| `NochePrimaryButton` | Next fill, onAccent text `primary`, 56 high, radius 28, full width. A disabled state: line fill, label text. | [`Noche-Palabras.dc.html`](noche/Noche-Palabras.dc.html) |
| `NocheOutlineButton` | Transparent, 1 px text border, text colour, 48 high, radius 24, `buttonStrong`. | [`Noche-Biblioteca.dc.html`](noche/Noche-Biblioteca.dc.html) ("Write my story") |
| `NochePlayBar` | 72 high, radius 36, next fill. Start: 56 disc in onAccent with a next play icon. Middle: `labelStrong` line, then `cardTitle`. End: `button` meta. | [`Noche-Lugar.dc.html`](noche/Noche-Lugar.dc.html) |
| `NochePlayDisc` | 64 (or 96) circle, next fill, onAccent icon. | [`Noche-Mapa.dc.html`](noche/Noche-Mapa.dc.html), [`Noche-Hablar.dc.html`](noche/Noche-Hablar.dc.html) |
| `NocheSegmented` | Panel fill, line border, radius 28, padding 4; options 48 high radius 24; selected = text fill and ground text. Used as radio group or tab list. | [`Noche-Yo.dc.html`](noche/Noche-Yo.dc.html) (minutes), [`Noche-Palabras.dc.html`](noche/Noche-Palabras.dc.html) (skills) |
| `NocheDashes` | A row of equal dashes, 8 high, radius 4, gap 4. States: done (text), current (next), not yet (line, or lessonLine on lessonGround). | [`Noche-Cuento.dc.html`](noche/Noche-Cuento.dc.html), [`Noche-Yo.dc.html`](noche/Noche-Yo.dc.html) |
| `NocheStageBar` | 96 by 8 track (line), fill text, width = stage / max. | [`Noche-Palabras.dc.html`](noche/Noche-Palabras.dc.html) |
| `NocheProgressBar` | 8 high (4 in the reader), radius 4, track line, fill given colour. | [`Noche-Biblioteca.dc.html`](noche/Noche-Biblioteca.dc.html), [`Noche-Importar.dc.html`](noche/Noche-Importar.dc.html) |
| `NocheSheet` | Bottom sheet over `scrim`: panel fill, radius 24 top corners, handle 40 by 4 (bar colour) 12 from the top, title `pageTitle` with a 48 close button at the end. | [`Noche-Idiomas.dc.html`](noche/Noche-Idiomas.dc.html), [`Noche-Lector-Aa.dc.html`](noche/Noche-Lector-Aa.dc.html) |
| `NocheSwitchRow` | Full-width row 52 high: label `rowTitle` weight 600 size 15 at start, switch 52 by 32 at end (on: text track, ground knob 24; off: line track, label knob). | [`Noche-Lector-Aa.dc.html`](noche/Noche-Lector-Aa.dc.html) |
| `NocheSectionLabel` | `label` style, label colour, 16 above the thing it names. | every board |
| `NocheBarChart` | Columns of rounded bars (radius 8), number above (`buttonStrong`), label under (`label` size 12 line 16), one bar highlighted in next, optional dashed goal line (1 px, label colour). Bar heights scale so the tallest is the chart's bar area. | [`Noche-Palabras.dc.html`](noche/Noche-Palabras.dc.html), [`Noche-Yo.dc.html`](noche/Noche-Yo.dc.html) |
| `NocheIcon` | The icons of the boards as paths, 24 viewBox, stroke width as on the board, round caps and joins. Copy each path's `d` exactly from the board file it is on. Add them the way `icons.dart` draws the existing ones (no SVG package). | every board |
| `NocheCover` | A book cover made of type: width 90 or 60, height 120 or 84, radius 3 at the spine side and 8 (6) at the other, spine border 5 (4) px, title in `cover`, a 20 by 2 (16 by 2) mark at the foot. Colours: `coverPlum` or `coverBlue`, chosen by a stable hash of the book id (even: blue, odd: plum). | [`Noche-Biblioteca.dc.html`](noche/Noche-Biblioteca.dc.html), [`Noche-Importar.dc.html`](noche/Noche-Importar.dc.html) |

Also in this story:

- The tab names move out of `CoquiLabels` into the course (`Language.tabNames`, N2.1). `CoquiLabels`' Spanish tab names stay only for the old bar until N1.4.  
- `NocheA11y` (Part 1.7): the table of lesson and reader accessibility labels, English, with the flag `lessonLabelsInCourseLanguage = false`.  
- A screen frame `NocheScreen`: ground colour, safe areas, the tab bar drawn over the foot, and the rule that content scrolls under nothing (the scroll view ends 104 above the bottom).  
- A dev page in `coqui_ui/tool/dev_main.dart` showing every piece in every state, in left-to-right and right-to-left.

**Done when**

- Each piece above exists, with a widget test for each state and a golden of the dev page in both directions.  
- Every touchable piece is at least 48 by 48 (a test walks the dev page and checks).  
- `flutter analyze` is clean; no `left`/`right` in the new files (a test greps them).

**Lane** lane:coqui_ui. Files outside it: only coqui/requests/.

**Links** The board files in the table. Part 1 of this page.

#### N1.3 The mic and its six states (#81)

- Labels: `agent:gemini`, `lane:coqui_ui`. Waits for N1.2 and N2.1.

**Salim's words**

> a right touch must never read as wrong

**What to build**

`NocheMic`: a 96 disc with five level bars on each side (4 wide, radius 2, gap as on the board, heights driven by the input level between 8 and 56), and a status word under it (`buttonStrong` size 16 line 24, or 14 on the lesson board). Board: [`Noche-Mic.dc.html`](noche/Noche-Mic.dc.html) (all six), [`Noche-Cuento.dc.html`](noche/Noche-Cuento.dc.html) (in a lesson).

| State | Disc | Bars | Word (from `Language.micWords`) |
| :---- | :---- | :---- | :---- |
| ready | next fill, onAccent mic icon | none | `ready` ("Toca y habla"), in next |
| listening | listening fill, ground icon | listening, moving with the mic level | `listening` ("Te escucho"), in listening |
| thinking | otherSoft fill, 2 px other ring, three 12 dots in other | none | `thinking` ("Un momento"), in other |
| theySpeak | micResting fill, lessonLabel icon | other, moving with the voice's level | `theySpeak` ("Escucha"), in other |
| right | right fill, onAccent check icon | none | `right` ("¡Muy bien!"), in right |
| notYet | no fill, 2 px text ring, text replay icon | none | `notYet` ("Otra vez"), in text |

- thinking shows the moment the learner stops talking. No wait before it.  
- notYet never uses red and never shakes.  
- The disc's accessibility label is English: "Microphone, ready", "Microphone, listening", and so on.

**Done when**

- A golden of the six states matches [`Noche-Mic.png`](noche/Noche-Mic.png) in layout (same order, sizes and colours).  
- A test drives the level and checks the bar heights stay between 8 and 56.  
- The words come from a `Language` passed in; there is no Spanish in the package (the boundary check passes).

**Lane** lane:coqui_ui. Files outside it: only coqui/requests/.

#### N1.4 Remove the old look (#82)

- Labels: `agent:gemini`, `lane:coqui_ui`, `status:blocked` until every Noche screen story is merged (moved to ready by whoever merges the last one).

**Done when**

- `CoquiColors`, `CoquiText`, `CoquiShadows`, the old tab bar, the old buttons and every other piece no file outside coqui_ui uses any more are deleted, with their tests.  
- Roboto and Pixelify Sans are removed if nothing uses them (Pixelify stays if the map still uses it).  
- `test_all.sh` passes on main after the merge.

**Lane** lane:coqui_ui.

---

### Epic N2. Every language (#83)

Salim, Nov 23: "eventually i want every language and subscriptions. lets build that into the designs before its costly later to do it". Nov 22: "same stories for now", "english speakers only for now". Page 19, sections 1, 2 and 4, is the plan this epic builds.

Only Spanish has a course. Nothing in this epic changes what a Spanish learner hears, sees or has recorded. Every recorded run in the tests stays the same.

#### N2.1 Contracts for every language, plans and the new screens (#84)

- Labels: `agent:gemini`, `lane:coqui_contracts`. Waits for nothing: everything it needs is on this page.

**What to build**

1. `Language` (`lib/src/language.dart`):  
   - `code` (BCP-47, `es`), `englishName` (Spanish), `nativeName` (Español), `recognitionLocale` (`es-US`), `direction` (ltr or rtl), `script` (ISO 15924: `Latn`, `Arab`), `partnerName` (Danny), `callAgentId`.  
   - `micWords`: the six words of N1.3, keyed `ready`, `listening`, `thinking`, `theySpeak`, `right`, `notYet`.  
   - `a11yWords`: optional map, the keys of `NocheA11y` (Part 1.7). Empty for Spanish today.  
   - `tabNames`: the five tab names keyed `library`, `words`, `map`, `speak`, `me`. Spanish: Biblioteca, Palabras, Mapa, Hablar, Yo. Required: a course without them does not load.  
   - `normalize(String)` and `tokens(String)`: the word rules. For Spanish they are today's `normalize()` and today's token regex, moved, unchanged. Arabic gets rules that keep Arabic letters (a test: an Arabic word does not come out blank). Other scripts throw `UnsupportedError` with the script's name.  
   - `Language.spanish` with the values above (the agent id is today's `dannyAgentId`).  
   - The global `normalize()` stays, calling `Language.spanish.normalize`, marked deprecated, until N2.11 removes it.  
2. `Course.language` (the course names its language; default Spanish).  
3. `Entitlements`:  
   - `enum Plan { free, course, courseAndCalls }`  
   - `enum Feature { calls, everyPlace, library }`  
   - `abstract interface class Entitlements { Plan get plan; bool has(Feature f); Stream<void> get changes; String? priceOf(Plan p); int? callMinutes(Plan p); Future<void> buy(Plan p); Future<void> restore(); }`  
   - `AllowAllEntitlements`: plan `courseAndCalls`, `has` always true, `priceOf` and `callMinutes` null, `buy` and `restore` do nothing.  
   - What each plan has (Claude's guess on the board, his to change): free = the first place in every language and review of its words; course = every place, every story, the Library; courseAndCalls = all that and calls.  
4. Routes: `LanguagesRoute`, `PlansRoute`, `ImportRoute`, `PlaceRoute(placeId)`. (The reader's settings sheet belongs to the reader and needs no route.)  
5. `CallBrief` gains `agentId` (from `course.language.callAgentId`).  
6. Close `coqui/requests/25-feature-speaking-needs-coqui-contracts-call-titles.md` only if it asks for nothing beyond this; otherwise leave it.

**Done when**

- Everything above is in the public surface, with tests on vm and chrome.  
- A test runs Spanish `normalize` and `tokens` over every line of `coqui/ref/` story data and gets exactly what the old global gave.  
- No caller outside coqui_contracts is changed.

**Lane** lane:coqui_contracts. Files outside it: only coqui/requests/.

**Links** Page 19, sections 1, 4 and 7.

#### N2.2 Fakes: a second language, and plans (#85)

- Labels: `agent:gemini`, `lane:coqui_testing`. Waits for N2.1.

**Done when**

- The fake course can be built in Spanish (today's) or in a test Arabic course: the same places and stories, with a handful of Arabic lines and words, `direction: rtl`, `script: Arab`. The Arabic lines are marked in the file as unchecked by an Arabic speaker.  
- A fake `Entitlements` whose plan a test can set, and whose `buy`/`restore` record the call.  
- Existing tests that use the fakes pass unchanged.

**Lane** lane:coqui_testing.

#### N2.3 The course says its language (#86)

- Labels: `agent:gemini`, `lane:coqui_content`. Waits for N2.1.

**Done when**

- The catalog reads `idioma` from `datos/curso.json` (an object with the fields of `Language`). When it is missing, the language is `Language.spanish`. The Spanish course file is not changed by this story.  
- The catalog's own `normalize()` call goes through `course.language`.  
- `real_tree_test.dart` passes with its counts unchanged.

**Lane** lane:coqui_content.

#### N2.4 Progress per language, and minutes by day (#87)

- Labels: `agent:gemini`, `lane:coqui_progress`. Waits for N2.1.

**What to build**

- Words, stories and level are stored per language under `coqui.<code>.palabras.v1`. On first start, if `coqui.palabras.v1` exists and `coqui.es.palabras.v1` does not, copy it there and keep the old key untouched (so an older app still works).  
- The streak, total minutes and the new minutes by day are shared by every language, under `coqui.shared.v1`.  
- `addMinutes` also adds to today's entry in a minutes-by-day map (the same day keys the streak uses). Keep the last 35 days.  
- `ProgressStore` gains `minutesOn(DateTime day)`, `language` (which language this store is for), `stageMax` (4, the top `etapa`) and `streakFreezes` (`int?`, always null for now). A `ProgressStores` holder gives the store for a language and knows which languages have progress (any language with at least one word or story record).

**Done when**

- The migration test: an old store's JSON comes out the same, byte for byte, under the Spanish key.  
- Minutes by day: a test over three days and a day missed.  
- Every existing progress test passes unchanged.

**Lane** lane:coqui_progress.

**Links** Page 19, section 1.

#### N2.5 Calls and listening take their language from the course (#88)

- Labels: `agent:gemini`, `lane:coqui_platform`. Waits for N2.1.

**Done when**

- `call_session.dart` takes the agent id from `CallBrief.agentId`. `dannyAgentId` is gone from the package.  
- The dev page's recogniser takes its locale from a `Language` (Spanish by default).  
- No call is placed by the tests or by the builder.

**Lane** lane:coqui_platform.

#### N2.6 to N2.9 Each feature uses the course's language (#89–#92)

One story per lane. Each one, labelled `agent:gemini`, waits for N2.1 and N2.2.

| Story | Lane | Change |
| :---- | :---- | :---- |
| N2.6 (#89) | feature_story | `turns.dart`: locale from `course.language.recognitionLocale` (was `'es-US'` at line 380). Every `normalize()` and token split through `course.language`. The lesson screen mirrors for rtl (directional only). |
| N2.7 (#90) | feature_review | `repaso_session.dart`: locale from the course (was line 1043). `normalize()` through the course. |
| N2.8 (#91) | feature_words | `text_rules.dart` and `word_marks.dart` use `course.language.tokens` and `normalize` instead of their own regex copies. |
| N2.9 (#92) | feature_speaking | The three `normalize()` callers, and `voiceTestLocale`, from the course. The partner's name on screen is `course.language.partnerName`. |

**Done when** (each)

- No `'es-US'`, no global `normalize(` and no token regex left in the package (a grep in the PR).  
- Every recorded run and every existing test passes unchanged.  
- The Arabic fake course runs the package's main flow without an exception.

#### N2.10 Your languages (the sheet) and the language chip (#93)

- Labels: `agent:gemini`, `lane:feature_profile`. Waits for N1.2, N2.4.

**Board** [`Noche-Idiomas.dc.html`](noche/Noche-Idiomas.dc.html).

**What to build**

- The sheet opens on `LanguagesRoute`, over the screen it was opened from, dimmed with `scrim`.  
- "Your languages": one 72-high radio card per language the learner has progress in (from `ProgressStores`), current one first. Line 1: English name (`row`, 18/24). Line 2: `"<level> · place <N> of <M> · <K> words"` from that language's store and course. Current: 2 px text border and a 32 check disc. Others: 1 px line border and "Switch" at the end.  
- Switch: sets the current language (a setting in the shared store) and closes the sheet; the shell reloads that course (N2.11).  
- "Add a language": a 56-high row per language that has a course in the catalog and no progress yet: English name, then the native name in label colour, in that language's script font, with its `lang` and direction; a plus icon at the end. Tap: same as Switch.  
- The foot line, exactly: "Each language keeps its own map and its own words. Your streak and your minutes count across all of them."

**Differs from the board**

- With only Spanish built, "Add a language" has nothing to list. Hide the heading and the rows when the list is empty. Do not show "French", "Arabic", "Portuguese" or "Italian": they are sample data.

**Done when**

- The sheet with Spanish only, and (on the fakes) with Spanish and the Arabic test course, both directions.  
- Switching changes the setting and returns to the map.  
- Screenshots as Part 1.6.

**Lane** lane:feature_profile.

#### N2.11 The shell loads the chosen course (#94)

- Labels: `agent:gemini`, `lane:app`. Waits for N2.3, N2.4, N2.10.

**Done when**

- The shell reads the current language setting, loads that course and that language's progress store, and gives them to every module. Changing it rebuilds the modules on the map.  
- The app's text direction follows the course's language on lesson screens; the tab screens stay left to right (the chrome is English).  
- The deprecated global `normalize()` is removed from coqui_contracts by a small follow-up story in that lane once nothing calls it.

---

### Epic N3. Plans (#95)

Salim: "eventually i want every language and subscriptions". Nothing here takes money. Real store billing is N3.5, blocked on store accounts (page 19, section 6). Until then the app runs on `AllowAllEntitlements`, so no learner ever meets a lock; the locked screens show only in tests and on the fakes.

#### N3.1 (inside N2.1, #84)

The `Entitlements` contract is part of N2.1.

#### N3.2 Plans screen and the "Your plan" row (#96)

- Labels: `agent:gemini`, `lane:feature_profile`. Waits for N1.2, N2.1, and N4.7 if both are open (same lane).

**Board** [`Noche-Planes.dc.html`](noche/Noche-Planes.dc.html), and the plan row of [`Noche-Yo.dc.html`](noche/Noche-Yo.dc.html).

**What to build**

- A page on `PlansRoute`: back button, "Plans" title, "One plan covers every language you learn."  
- Three cards in order Free, Course, Course + Calls, with the lines exactly as on the board. The learner's own plan has the "Your plan" tag (text fill). The plan above the learner's own has the 2 px next border and the orange button `"Get <plan>"`. Only one orange button on the screen.  
- Price line: `entitlements.priceOf(plan)` + " a month". When it is null, no price line (no "[PRICE]" on screen). `"<N> minutes of calls a month"` shows only when `callMinutes(plan)` is not null; until then that line is left out.  
- "Get ..." calls `entitlements.buy(plan)`. "Restore purchases" calls `restore()`. The foot line, exactly: "You manage or cancel your plan in your app store account."  
- On `AllowAllEntitlements` the learner is on Course + Calls, so no orange button shows.

**Done when**

- Golden tests on the fake at each of the three plans.  
- The Me row `"Your plan · <plan> · Manage ›"` opens it.

**Lane** lane:feature_profile.

#### N3.3 Speak without the calls plan (#97)

- Labels: `agent:gemini`, `lane:feature_speaking`. Waits for N2.1, N4.6.

**Board** [`Noche-Hablar-Plan.dc.html`](noche/Noche-Hablar-Plan.dc.html).

**What to build**

- `entitlements_hook.dart` is replaced by `Entitlements.has(Feature.calls)`.  
- Without calls: the call titles, place pills and call cards stay as on the Speak screen. The "Words you can use" chips are not shown. The next-call card's label row has the plan tag "Course + Calls" at its end.  
- The mic and `"Call <partner>"` are replaced by one highlight card above the tab bar: "Live calls are in Course + Calls" (`sheetTitle`), the help line exactly as on the board with the partner's name from the course, and the orange "See plans" (`PlansRoute`).  
- No pop-up, ever, and nothing changes inside a lesson.

**Done when**

- On the fake with `Plan.course`: this screen. With `courseAndCalls`: the normal Speak screen.  
- The two locks look different: not reached = dashed pill with lock; not in plan = the orange outlined tag.

**Lane** lane:feature_speaking.

#### N3.4 A place not in the plan (#98)

- Labels: `agent:gemini`, `lane:feature_map`. Waits for N2.1, N4.2.

Not drawn. Built from the two-lock rule and the Speak card, so it looks the same:

- On the map, a place past the free one, when `has(Feature.everyPlace)` is false, keeps its normal look (it is reached, just not in the plan).  
- Opening it shows the place page (N4.2) with the stories visible, the plan tag "Course" at the end of the "All N stories" label row, and in place of the orange play bar one highlight card: "This place is in Course" (`sheetTitle`), "Every place and every story are in Course." (`body`), and the orange "See plans".  
- The first place of each language is always open.

**Done when**

- On the fake with `Plan.free`: place 1 plays, place 2 shows the card; with `Plan.course`: both play.  
- The copy above is written exactly and flagged in the PR as "not drawn, Claude's wording".

**Lane** lane:feature_map.

#### N3.5 Store billing (#99)

- Labels: `agent:gemini`, `lane:coqui_platform`, `status:needs-salim`.  
- Waits for: the store accounts (page 19, section 6: his call on personal or company accounts) and the package choice (RevenueCat or the stores' own plugins), made as Part 1.8 says.  
- One question for Salim when this is picked up: which store accounts to open. Not posted as ready.

---

### Epic N4. The Noche screens (#100)

One story per screen. Each follows Part 1, names its board, and changes only its lane. "Differs from the board" lists every deliberate difference.

#### N4.1 Map (home) (#101)

- Labels: `agent:gemini`, `lane:feature_map`. Waits for N1.2, N2.1.

**Board** [`Noche-Mapa.dc.html`](noche/Noche-Mapa.dc.html).

**What to build**

- Ground `ground`. The map picture (`MapPicture` via `PixelView`) at scale 2, centred across on the learner's current stop, with the stop about half way down (its top at 51% of the screen height); clamped so no edge of the map shows.  
- "You are here": a 40-high text-fill pill (`buttonStrong` in ground) centred over the current stop, with a 12 by 12 diamond under it pointing at the stop. Crisp UI over the pixel art, not part of the picture.  
- Top row, 16 from the top and sides: at the start, the language chip (48 high pill: English language name in `buttonStrong`, the level in label colour, a 16 chevron) → `LanguagesRoute`; at the end, the streak chip (flame icon 18, `"<N> days"` or `"1 day"`, `button`). With a streak of 0 the streak chip is not shown.  
- The "Up next" card above the tab bar (bottom 104, 16 from the sides): a 72 picture of the next story's scene (radius 16), `"Up next · <place>"` (`label`), the story title (`cardTitle`, content language), `"<kind> · <N> min"` (`bodySmall` 14/16, label colour), and a 64 orange play disc at the end → `StoryRoute(next)`. Tapping the picture or the text opens the place (N4.2).  
- Under them in the card: at the start `"Then <step1>, then <step2>"` from today's plan, at the end `"<N> of <M> min today"` (`minutesOn(today)` and the minutes-a-day setting).  
- "Next story" is today's plan's first entry, as the old Today card picks it (`plan()`, kept as it is). The steps are the plan's next two entries named "review", "a call", "a new story" or "listening". With fewer, the line is shortened; with none, it is not shown.

**Differs from the board**

- The streak chip hides at 0.

**Done when**

- Screenshots at a new learner, at place 3, and at the last place, both sizes, beside the board PNG.  
- The current stop is on screen and centred at both sizes (a test reads the camera).  
- No Spanish string in the package.

**Lane** lane:feature_map.

#### N4.2 Opening a place (#102)

- Labels: `agent:gemini`, `lane:feature_map`. Waits for N4.1. Replaces #12 (Part 2).

**Salim's words** (from #12 and the backlog)

> When you open a place it should be clear what to do. Right now it just opens a list. Terrible UX. Opening a place needs an obvious next step, not a list.

**Board** [`Noche-Lugar.dc.html`](noche/Noche-Lugar.dc.html).

**What to build**

- A page inside the Map tab (the tab bar stays, Map is current), not a sheet. Also reachable by `PlaceRoute(id)`.  
- Hero: the place's scene picture, 296 high, with a 48 round back button (ground fill) at the top start → map, and a 40-high ground-fill pill at the top end: `"Place <N> of <M>"`.  
- The place name (`placeTitle`, content language) and `"<N> of <M> stories heard"` (`body` 14, label colour).  
- `"All <N> stories"` and a row of story tiles that scrolls sideways: 104 wide, the scene picture 80 high radius 16, `"<N> · <title>"` under it. Heard: title in label colour and a 24 round check badge (ground fill) at the picture's top start. The next story: 3 px next border and title in `buttonStrong`. Others: normal. Each tile → that story.  
- Three outline pills: "Listen again" → the last heard story told straight through (`StoryRoute(id, listen: true)`); "Read" → that story's book (`BookRoute`); `"Call <partner>"` → `CallRoute(placeId)`. Pills whose target does not exist yet (nothing heard, no call for the place) are not shown.  
- The orange play bar above the tab bar: `"Play next · Story <N>"`, the title, `"<M> min"` → `StoryRoute(next)`. When every story is heard, #12's rule: the bar goes to the place's call, or to review, with the label `"Call <partner>"` or `"Review"`.

**Differs from the board**

- The board's "Listen again" and "Read" go to the Library; here they go to the story and its book.

**Done when**

- A new place, a half-done place and a finished place, both sizes.  
- Every story tile reaches its story; the play bar reaches the first unheard story.

**Lane** lane:feature_map.

#### N4.3 Story lesson (#103)

- Labels: `agent:gemini`, `lane:feature_story`. Waits for N1.3, N2.6.

**Boards** [`Noche-Cuento.dc.html`](noche/Noche-Cuento.dc.html), [`Noche-Cuento-AR.dc.html`](noche/Noche-Cuento-AR.dc.html), [`Noche-Mic.dc.html`](noche/Noche-Mic.dc.html).

**What to build**

- Full screen on `lessonGround`, no tab bar.  
- Header, 64: close (48, X) → the place; the part dashes (`NocheDashes` on lessonGround), one per part of the story; the TXT toggle (56 by 48 pill: on = text fill and lessonGround text, off = lessonBorder outline). TXT is the existing captions setting.  
- The scene, 400 high, drawn by the scene as today.  
- Under it: the speaker (`labelStrong`, label colour), the line (`lessonLine`), and on a speaking turn the prompt (`lessonPrompt` in label colour, the words to say in `text` and bold). All three from the story file, in the content language and its script font. With TXT off, only the speaker shows.  
- The controls, 32 from the bottom: a 48 "hear it again" outline button at the start, `NocheMic` in the middle, an empty 48 at the end (keeps the mic centred).  
- The mic's state follows the turn: ready when it is his turn, listening while he talks, thinking the moment he stops, theySpeak while a voice plays, right on a right answer (short, then the story moves on), notYet on a miss (the line plays again).  
- Touch turns and every other step keep today's layout (Part 1.5) with Noche colours.  
- Right to left: with an rtl course the whole screen mirrors as on the Arabic board, with `forScript` styles.

**Differs from the board**

- Accessibility labels in English (Part 1.3).

**Done when**

- Every recorded run of feature_story still passes (`differential_test.dart`).  
- Screenshots of a speaking turn in each mic state, a touch turn, and the Arabic fake, both sizes.

**Lane** lane:feature_story.

#### N4.4 Words (#104)

- Labels: `agent:gemini`, `lane:feature_words`. Waits for N1.2, N2.8.

**Board** [`Noche-Palabras.dc.html`](noche/Noche-Palabras.dc.html).

**What to build**

- Header: `"<Language>"` label over `"Words"` (`pageTitle`); at the end the outline pill "+ Add a word or goal" → today's add box.  
- The due card: the number of words due today for the chosen skill (`bigNumber` in next) and "words come / back today" (`row`).  
- `"When your <N> words come back"`: a `NocheBarChart` with five columns: Today (due today or earlier; next colour), Tomorrow, 3 days (due in 2 or 3 days), This week (4 to 7 days), Later (more than 7). Counts for the chosen skill.  
- The skill switch (`NocheSegmented`, a tab list): `"Listening · <N>"`, `"Speaking · <N>"`, `"Reading · A2"`. Good = words at the top ear (or mouth) stage. Reading shows, in label colour, and on tap the list says "Reading opens for tracking at A2." while the learner is below A2.  
- The word list for the chosen skill, soonest first: 56-high rows, the word (`row`, content language) over its due line (`"back today"` in next; `"back tomorrow"`, `"back in <N> days"`, `"back in <N> weeks"`; `"good · back in <N> weeks"` at the top stage; label colour), and the `NocheStageBar` at the end. Tap → today's word sheet.  
- The orange "Start review" button above the tab bar → `ReviewRoute()`. When nothing is due: "Practice" → `ReviewRoute(practice: true)`.

**Differs from the board**

- Stages: the store has 4 stages for a word (etapa 1 to 4), not 5. The bar fills etapa / `stageMax` (Part 1.7).  
- The button says "Start review" with no minutes: nothing in the app estimates review time yet.

**Done when**

- Screenshots with no words, a few words, and 96 words, each skill, both sizes.  
- Bucket test: words due yesterday, today, tomorrow, in 3, 5 and 20 days land in the right columns.

**Lane** lane:feature_words.

#### N4.5 Library (home) (#105)

- Labels: `agent:gemini`, `lane:feature_library`. Waits for #2 merged, N1.2.

**Board** [`Noche-Biblioteca.dc.html`](noche/Noche-Biblioteca.dc.html).

**What to build**

- Header: `"<Language>"` over `"Library"`; at the end "+ Add your own" → `ImportRoute` (shown once N5.4 is merged; until then hidden).  
- "A new story at your level · about what?": the topic radio pills and the outline "Write my story", wired to #2's story generator exactly as #2 built it. If #2 did not build topics, show only "Write my story".  
- "Your shelf · reading counts from A2" (the second half only while below A2): the filter pills All, Stories, Books; then a sideways row: stories (scene picture 104 by 120 radius 16, title, "Story"), books (`NocheCover` 90 by 120, title, "Book"). Most recently opened first.  
- The "Keep reading" card above the tab bar, for the last book opened and not finished: small cover (60 by 84), `"Keep reading · Chapter <N>"` (no chapter part for a book with one chapter), title (`sheetTitle` in Atkinson 700 20/24), `"Page <P> of <Total> · <M> min left in the chapter"`, a progress bar in next, and the orange "Continue reading" → `BookRoute`. With nothing in progress, no card.

**Differs from the board**

- No YouTube filter and no video items (epic N7 is backlog).

**Done when**

- An empty shelf, a shelf with stories only, and with stories and books, both sizes.

**Lane** lane:feature_library.

#### N4.6 Speak (#106)

- Labels: `agent:gemini`, `lane:feature_speaking`. Waits for the Danny-call stories in this lane (#4 to #7), N1.2, N2.9.

**Board** [`Noche-Hablar.dc.html`](noche/Noche-Hablar.dc.html).

**What to build**

- Header: `"<Language>"` over `"Speak"`; at the end `"<N> words ready to say"` (words open for speaking).  
- The place pills (a tab list): one per place reached, the current one selected; one dashed-locked pill after them for the next place not reached (accessibility label `"<place>, not reached yet"`).  
- The next-call card: `"Next call with <partner> · <N> min"` (`label` in next), the call title (`placeTitle` 32/36, content language), its English job line (`bodyLarge`, label colour), "Words you can use" and their chips (content language).  
- The place's other calls, two to a row, 88 high: open ones as cards (`"<N> min · open"`), not yet open ones dashed with `"<N> min · after story <M>"`.  
- `"Call <partner>"` and the 96 orange disc with the phone icon above the tab bar → `CallRoute`.  
- Call titles, job lines and lengths come from the call catalog as the Danny-call stories left it.

**Done when**

- A place with one call open, with all open, with none open; both sizes.

**Lane** lane:feature_speaking.

#### N4.7 Me (#107)

- Labels: `agent:gemini`, `lane:feature_profile`. Waits for N1.2, N2.4, N2.10.

**Board** [`Noche-Yo.dc.html`](noche/Noche-Yo.dc.html).

**What to build**

- Header: "Me"; at the end the outline pill "How Coquí works" → today's How it works.  
- Stats card: total minutes (`statNumber`) with "minutes listened" and, under it in label colour, "all languages". At the end: flame and `"<N> days"` (hidden at 0). Then the 7-day chart: one bar per day for the last 7 days from `minutesOn`, each labelled with its weekday's English initial, today's bar last, in next, labelled "Today", the dashed goal line at the minutes-a-day setting.  
- Language card: the language pill (→ `LanguagesRoute`), `"<level> · place <N> of <M>"` and the place name; one dash per place (done text, current next, rest line); rows Listening and Speaking with a progress bar and `"<N> of <M> good"`; Reading with "Open now. Counts from A2." below A2.  
- "Minutes a day": `NocheSegmented` 15, 30, 60, 120 (the existing setting).  
- The "Your plan" row (N3.2).  
- Below, scrolling: the existing rows that are not on the board, restyled: "Open every place" and "Speak in stories" as `NocheSwitchRow` with their help lines, "Level check" with its Start button, "About". Text exactly as today.

**Differs from the board**

- "1 freeze saved" shows only when `streakFreezes` is not null (Part 1.7). It is null today.  
- The existing switches and rows stay, below the board's part.

**Done when**

- A new learner and a learner with a week of minutes, both sizes.

**Lane** lane:feature_profile.

#### N4.8 Review, level check and welcome in Noche colours (N4.8a #108, N4.8b #109)

- Labels: `agent:gemini`. Two stories, one per lane: N4.8a (#108) `lane:feature_review` (waits for #9, #10, N1.3, N2.7), N4.8b (#109) `lane:feature_profile` for the welcome (waits for N4.7).

Not drawn (Part 1.5): same layouts, Noche tokens and pieces, lesson screens on `lessonGround`, the speaking items with `NocheMic`, a wrong choice shown with a white outline and never red.

**Done when**

- Every recorded run and test of the package passes. Screenshots of each screen beside the old one.

#### N4.9 The shell in Noche (#110)

- Labels: `agent:gemini`, `lane:app`. Waits for N1.2.

**Done when**

- `NocheTabBar` replaces the old bar; its tab names come from the current course (`Language.tabNames`) and change when the language changes.  
- `LanguagesRoute`, `PlansRoute`, `ImportRoute`, `PlaceRoute` go to their modules.  
- The app's background, the web page's background and theme colour, and the phone status bars are `ground`.  
- `check_app.mjs` passes at both sizes.

---

### Epic N5. The reader and your own books (#111)

Salim, Nov 23: "I want the reader to look like a real reader not a simple text thing that makes my eyes want to die." "users can upload pdfs, ebook/etc to put their books in the reader."

All in feature_library, so these go one at a time, after #2 and N4.5.

#### N5.1 The reader page (#112)

- Labels: `agent:gemini`, `lane:feature_library`. Waits for N4.5.

**Board** [`Noche-Lector.dc.html`](noche/Noche-Lector.dc.html).

**What to build**

- Full screen, page colour from the settings (Night by default: `lessonGround`, body `nightText`).  
- Header, 56: back (chevron) → Library; the book title in capitals, centred (`label`, lessonLabel); "Aa" (Literata 500 20) → the settings sheet (N5.2); the chapters button (list icon) → a sheet listing the chapters (`NocheSheet`, one 56 row per chapter, the current one marked with the check disc; not drawn).  
- The page: side padding 28. Chapter label only when the book itself has chapter titles (the book's own words, never made up). Chapter head in `bookTitle`, a 32 by 1 rule (lessonBorder). Body in `bookBody`, left aligned, never justified. Paragraphs: first line indented 1.4 em, except the first of a chapter. Drop capital (`dropCap`, 3 lines) on the first paragraph of a chapter.  
- Paged, not scrolled: swipe sideways, or tap the outer fifth of either side, to turn. Page numbers are counted for the current text size.  
- Word marks, from the ear records of the learner's language, with the course's `tokens` and `normalize`: never heard (no record or stage 0) = solid 2 px underline in `listening`; still learning (stage 1 to `stageMax` − 1) = dotted 2 px underline in the page's label colour; known (stage `stageMax`) = no mark.  
- Tap a word: it gets a `listening` background with page-ground text (radius 6), and a bubble above it (text fill, page-ground text, 44 high, radius 22): a speaker icon, the word (`primarySmall`), and one 6 px dot per stage (`stageMax`, 4 today), one filled per ear stage reached. The word's clip plays if the course has one; if not, no speaker icon and no sound. No translation. Tap elsewhere closes it.  
- Course story books have their recorded audio: the foot has "sentence again" (48 outline), Listen / Pause (64 orange), and speed (48 outline, "0.9×", cycling 0.75×, 0.9×, 1×). The sentence being read is lit (`litSentence` background, text colour) when that setting is on.  
- The foot line: `"<page> / <total>"` at the start and a clock with `"<N> min"` at the end (minutes left in the chapter: words left ÷ 120, rounded up; Claude's guess at reading speed); a 4-high progress bar (lessonLine track, lessonLabel fill).  
- Books with no recording (the learner's own) have no Listen, sentence-again or speed buttons, and no lit sentence. Read-aloud for them is not decided (page 21, "Money").  
- The place in each book is remembered.

**Differs from the board**

- No "CAPÍTULO 2" label made up by the app; only a book's own chapter titles.

**Done when**

- A course story book in Night, a long imported book (on the fake) across a chapter end, at the smallest and largest text size, both sizes.  
- A test of the word marks against a fake ear record with words at stages 0 to 4.

**Lane** lane:feature_library.

#### N5.2 Text and page settings (#113)

- Labels: `agent:gemini`, `lane:feature_library`. Waits for N5.1.

**Board** [`Noche-Lector-Aa.dc.html`](noche/Noche-Lector-Aa.dc.html).

**What to build**

- `NocheSheet` over the page (the page shows its colour behind the scrim).  
- Text size: smaller "A", 7 dashes, larger "A"; `"Step <N> of 7"`. Sizes (body / line height at Normal): 15/25, 16/26, 17/28, 19/31, 21/34, 23/38, 26/42. Default step 4. (Only step 4 is on the board; the rest are Claude's steps.)  
- Font: three 80-high tiles, "Ag" in the font and its name: Literata, Atkinson, Lexend. Help line exactly: "No font is fastest for everyone. Keep the one you read most easily."  
- Line spacing: Tight, Normal, Loose (icons from the board) = line height × 0.88, × 1, × 1.15.  
- Page: Night, Sepia, Day, each a 48 pill filled with its page colour and an "A" in its text colour.  
- Switches: "Underline words I'm still learning" (off hides both underline kinds), "Light up the sentence being read".  
- Every setting applies at once and is kept in the feature's own storage space.

**Done when**

- Each setting changes the page in a widget test; the settings survive a restart on the fake storage.

**Lane** lane:feature_library.

#### N5.3 How much of a book you know (#114)

- Labels: `agent:gemini`, `lane:feature_library`. Waits for N5.1.

**Done when**

- `coverage(book)` = running words of the book whose ear record is at stage 1 or more ÷ all running words, using the course's `tokens` and `normalize`. Numbers and words in another script are left out of both counts.  
- The phrase under it: below 90%, "A stretch for now. Reading gets easy near 98%."; 90 to 97%, "Close. Reading gets easy near 98%."; 98% and up, "Easy to read now." (Only the first is on the board; the other two are Claude's wording.)  
- A test on a fake book and record gives the exact percentage.

**Lane** lane:feature_library.

#### N5.4 Add your own: the screen, paste text and plain text files (#115)

- Labels: `agent:gemini`, `lane:feature_library`. Waits for N5.3, N4.9 (the route).

**Board** [`Noche-Importar.dc.html`](noche/Noche-Importar.dc.html).

**What to build**

- A page on `ImportRoute`: close, "Add your own", the line `"Books and documents in <formats>. Only you can see what you add."` where `<formats>` lists only what is built (this story: `"TXT"`).  
- "Adding now": a card per file being added: name, size, three dashes for the three steps (open it, read the pages, check its words against yours), and `"Step <N> of 3."` with what is happening.  
- "Ready": a row per added book: `NocheCover` 60 by 84, title, `"<format> · <N> pages[ · <M> chapters]"`, the coverage bar in `listening`, `"You've heard <N>% of its words."` and the phrase from N5.3. Tap → `BookRoute`.  
- A book that cannot be opened: a card with a 1 px text outline (never red) and the reason in one line.  
- The foot: a "Paste text" tile (opens a full-screen text box with "Add" as the orange button; not drawn), and the orange "Choose a file".  
- Added books are stored on the device in the feature's own space, never sent anywhere. If the storage space cannot hold books of a few megabytes on the web, file a request to coqui_platform for a file store and use the fake meanwhile.  
- A pasted text or TXT file becomes a book: a blank line starts a paragraph; a line of its own in capitals or starting "Chapter"/"Capítulo" is not guessed at: no chapters.

**Differs from the board**

- No "Web page" or "YouTube video" tiles, and no "Or from any app: Share, then Coquí." line, until the stories for them are built (N5.6, epic N7).

**Done when**

- Adding a TXT file and a pasted text on the fake, both reaching the reader with the right coverage.

**Lane** lane:feature_library.

#### N5.5 EPUB and Word files (needs two packages) (#116)

- Labels: `agent:gemini`, `lane:feature_library`. Waits for N5.4.

**Done when**

- The packages (likely `archive` and `xml`) are chosen and added as Part 1.8 says.  
- EPUB: chapters from the book's own table of contents, text and paragraphs from its pages, the title and author from its metadata. A book with an `encryption.xml` that locks its content shows "Locked by the store it came from. Coquí can't open locked books." (exactly as the board).  
- Word (.docx): paragraphs, headings as chapters.  
- The formats line lists EPUB and Word once they work.

#### N5.6 PDF, scanned pages, web pages and Share (#117)

- Labels: `agent:gemini`, `status:blocked`. Waits for N5.5.  
- PDF text needs a package (chosen as Part 1.8 says). Scanned PDFs need text read off the picture: on Android and iPhone the phone can do it on the device; the web cannot without a paid service. Web pages hit browser limits on the web build. Share from another app needs a package per phone system.  
- One question for Salim when this is picked up, with the choices and any cost. Not posted as ready.

---

### Epic N6. Small Noche pieces left over (#118)

#### N6.1 Mic states everywhere (#119)

The mic is used in N4.3 (stories), N4.8a (review) and the call screen. The call screen in progress is not drawn: covered by the Danny-call stories, with `NocheMic` once N1.3 is merged. If those stories are merged before N1.3, a follow-up story in feature_speaking swaps the mic, posted then.

---

### Epic N7. YouTube (backlog, not on the board) (#120)

Salim, Nov 23: "youtube is backlog stuff along with the integration." The integration is the Drive backlog item "Videos — YouTube clips at the learner's level".

Boards: [`Noche-Video.dc.html`](noche/Noche-Video.dc.html), [`Noche-Video-Ver.dc.html`](noche/Noche-Video-Ver.dc.html), [`Noche-Video-Texto.dc.html`](noche/Noche-Video-Texto.dc.html), and the YouTube parts of [`Noche-Biblioteca.dc.html`](noche/Noche-Biblioteca.dc.html) and [`Noche-Importar.dc.html`](noche/Noche-Importar.dc.html). Page 21, "YouTube: what is allowed", holds the rules checked on Nov 23.

Stories to write when he says go (outline only):

| Story | What | Blocks on |
| :---- | :---- | :---- |
| N7.1 | YouTube Data API v3 key in a Google Cloud project; privacy policy; the link to YouTube's Terms | Salim: his Google account and the key (he enters it) |
| N7.2 | The player: YouTube's own embedded player, at least 200 by 200, nothing over it, untouched; our controls under it drive it through the player API (5 s back, speed, pause, loop, save) | the player package, chosen as Part 1.8 says |
| N7.3 | Find a video: search (100 a day for the whole app until YouTube's audit), paste a link, and Share from YouTube; filters Subtitles, Under 4 min, 4–20 min | N7.1, N7.2 |
| N7.4 | Watching any video: Spanish subtitles inside the player, never English; minutes count as listening; words do not | N7.2 |
| N7.5 | Videos with their text: transcripts from channels that publish them, with each creator's written OK (Dreaming Spanish, StoryLearning Spanish first); tappable lines, lit current line, words count | Salim: the creators' permission |
| N7.6 | The known-words filter: score each video's transcript by the share of words the learner knows (98% is easy reading; few videos pass at A1); show the ones he can follow | N7.5 |
| N7.7 | The Library's YouTube filter and video items, and the "YouTube video" tile in Add your own | N7.3 |
| N7.8 | YouTube's compliance audit before quota above the default | N7.1 to N7.4 built |

---

## Part 4. Decisions in this page that are Claude's, for Salim to change

- Treated everything drawn as approved, including page 21's open guesses (the tier names and what each holds, Literata and the three reader fonts, one plan for every language, shared streak and minutes).  
- Tab names: in the course's language (Spanish for Spanish), as you said; English page titles inside them, as on the boards.  
- Differences from the boards, each a switch (Part 1.7): 4 word stages not 5; no "1 freeze saved" (no freezes exist); no review minutes on the Words button; no sample languages in "Add a language"; no "[PRICE]" on screen; English accessibility labels on lesson screens; no made-up chapter labels in the reader.  
- Not drawn and specified here: the place-not-in-plan card, the chapters sheet, Paste text, the extra text sizes, the two other coverage phrases, reading speed for "min left".