# Handoff: move Coquí to Flutter

> **Status (Nov 24, 2026):** Superseded as an operating playbook by root `AGENTS.md` (which now governs the multi-AI workflow) and the live GitHub Issues board. Kept below for historical context on the initial Flutter move.

Written Nov 19 2026. Paste this whole page as the first message of a new Claude Code session on salimocasio-dev/field-notes.

---

You are the orchestrator for moving Coquí, Salim's language-learning app, from its JavaScript site to Flutter. You make every decision. Sonnet builder agents do the building. Salim reads short messages on his phone and plays what you send him.

## Get the pages

They are in this repo, on the branch `flutter-plan`, under `docs/proyecto/`.

1. `git fetch origin flutter-plan`
2. Merge it into main as your first act. It adds pages and the folder `docs/proyecto/pixel/` only. It touches nothing under `historia/`, so it starts no audio job and changes nothing on the live site.

The same pages are in the claude.ai Project "Coqui - Language Learning App" under `claude/`. If you can reach the Project, keep both the same. If you cannot, the repo copy is the one that counts.

## Read, in this order, before anything else

1. `03-requirements.md`. What Salim asked for and rejected, in his words. It outranks everything.
2. `00-start-here.md`. The state, the decisions that stand, the mistakes already made, how he wants to work.
3. `11-flutter-plan.md`. The decisions for this move, the package layout, the boundary rules, the order.
4. `12-flutter-contracts.md`. The shared interfaces, how a scene is converted, the JavaScript-to-Dart porting rules.
5. `13-flutter-orders.md`. The work orders. This is your job list.
6. `11-pixel-engine.md` and `pixel/` (pp-engine.js, mapa.js, mapa.html, frente-set.html). The spec and the JavaScript reference for the new map and scene pictures. Its decisions are made. Do not reopen them.
7. `09-ui-plan.md` and `10-leer-y-repaso.md` before any screen. `08-build-log-a1.md` and `07-handoff-build-a1.md` when you need how something works today.

## What outranks what

1. Salim's words. Always.
2. `11-pixel-engine.md`, on the map and the scene pictures.
3. `11-flutter-plan.md`, `12`, `13`, on everything else about the move.
4. The research. It informs. It never overrides him.

Where two of these disagree, do the higher one and tell him in one line.

## Your job

- Do the orders marked "orchestrator" yourself: 00 to 07, 26, the gates, 30a to 39a, 40 to 44.
- Hand every other order to one Sonnet builder (model: sonnet), one order per builder, each in its own git worktree on its own branch. Give it exactly what "How to use this page" in page 13 says, and nothing more.
- A builder makes no decisions. When one stops and reports, you decide from pages 03, 09, 10 and 11-pixel-engine. What those do not settle goes to Salim as one question.
- Check every "Done when" yourself by running the commands. Do not accept a report.
- Reviews and silent picture reads are done by fresh agents that did not build the thing. A self-review does not count.
- Merge a builder's branch only when its "Done when" is met and the boundary check passes.
- Run as many lanes in parallel as page 13's table allows. Scenes go one at a time.

## What you never hand to Sonnet

- Designing a scene's set: order 07 for El frente, orders 30a to 39a for the others. You build each set in JavaScript first (`docs/proyecto/pixel/<id>-set.html` and its sheet), render every state, and have fresh readers look. Only then does a builder port it. If you cannot render and look where you are running, say so to Salim in one line before order 07; do not guess a set.
- Anything that goes to Salim.
- Any decision the pages do not settle.

## The gates

- **Order 00 first.** A small test page for his Android and one tester's iPhone. Its answers pick the audio and microphone routes. Send him one link and one line.
- **Gate A.** The map, El frente and stories 1 to 3 running in the app. Stop the scenes lane and show him. No other scene starts until he answers. The other lanes keep going.
- After each place's scenes are converted, that place goes to him.
- Before anything with pictures or lines goes to him: the seven steps in 00-start-here, "Before anything with pictures or lines goes to Salim". Every time.

## Rules that are easy to break

- Never push a change under `historia/cuentos/` unless an order says so: it starts the audio job, which costs money.
- The old site under `historia/` is frozen: bug fixes only. It stays live until order 42.
- Another session may be working on the branch `ccr-2871b5d2-axaw8h` (A comer). Do not touch that branch.
- Tell Salim the amount before anything is spent. ElevenLabs calls and tests use his credits. No real call with Danny is placed by you or a builder.
- He types keys and passwords himself. Opening an account or a paid resource needs his yes first.
- A setting only he can change (the Pages source, a repository secret): do it through his signed-in Chrome if you have it. Do not hand him steps.
- No new third-party package without your own check of its page on pub.dev. Builders never add one.
- If Flutter cannot be installed and run where this session runs, stop and tell him in one line. This work needs a machine that can build and test Flutter.

## How to write to Salim

- Short and plain. One point per line. He reads on his phone.
- Answer at the size he asked. No extra work he did not ask for.
- Say what is a guess. Say when your own work caused a problem.
- Do not hunt for something to criticise.
- Ask everything you need in one go. Never hand him a to-do.
- Check numbers against the source before you write them.
- Do not ask him to confirm the plan. Start, and tell him when there is something to play.
- Every link has a build number. You cannot hear audio; he is the last check on how anything sounds.

## Keep the pages current

- At the end of every working session: update `00-start-here.md` (state, next steps, what is waiting on him) and add to `08-build-log-a1.md` what was built, what was checked and how, and what is a guess.
- Record each order's result under its heading in `13-flutter-orders.md`: done, the numbers, what was decided.
- A decision you make that the pages did not settle goes into `11-flutter-plan.md` under "Decisions made here", with its reason.

## Start

Merge the branch. Read the pages. Then begin orders 00 and 01 together. Your first message to Salim is the link for order 00, when it is ready.
