# Coqui: how every AI works here at the same time

Claude, Codex (ChatGPT) and Gemini work on this repo at the same time. This page keeps them out of each other's way.

Read, in this order:

1. The Drive folder's READ FIRST page: what Coqui is and Salim's rules. https://docs.google.com/document/d/1lCqG1wcIAjkwbkqX0Mmm3WL0u2pz_7sswYKxqlYoGq4
2. This page.
3. `coqui/AGENTS.md` before you touch code: the lanes, the checks, the porting rules.

Salim's words come first. If anything here disagrees with what he said, do what he said and tell him in one line.

## Single Source of Truth & Where Things Live

- **Live build board (only live backlog):** GitHub Issues and the existing GitHub Project board in `salimocasio-dev/field-notes`. Never track live tickets in Google Drive (`01 Backlog` in Drive is archived).
- **Idea intake:** General product/feature ideas are worked through in Gemini chat first; architecture ideas are worked through in Claude first. Once shaped, tickets go onto the GitHub board (1 issue = 1 Flutter package/lane).
- **Repo specs (`docs/proyecto/`):** Engineering plans, Noche specs, and contracts stay in GitHub next to the code.
- **Google Drive (`Coqui — Project Context (any AI)`):** Human-readable hub for `03-requirements`, `00 READ FIRST`, grants/LLC tracking, and Gemini handoff briefs. Whenever a major architecture, process, or milestone change lands, update the affected repo docs and keep Drive synced (never leave duplicate active backlogs).

## Multi-AI Operating Model (Salim's Stack)

- **Planning & ticket scoping:** Gemini 4 Neon (Antigravity) turns approved ideas, `03-requirements`, and `docs/proyecto/22-noche-epics.md` into scoped, single-lane GitHub issues.
- **Routine & parallel execution:** Antigravity Orchestrator (Carbon/Neon planner + Hydrogen `high` executor) builds feature packages using isolated Git worktrees (`workspace="branch"`). Never crank Hydrogen to `xhigh`; escalate complex work to Neon `high` or Claude.
- **Architecture & shared packages:** Claude Code (Opus 5.5 / Fable 5.2 when interactive quota is available) owns `coqui_contracts`, `coqui_ui` tokens, `coqui/requests/` merges, and security/platform boundaries. When Claude Code quota is unavailable, Antigravity (Neon/Carbon) handles these under strict cross-model review.
- **Independent PR review & automated merge loop:** Every PR must pass deterministic CI (`coqui.yml` + `coqui-guardrails.yml`) and independent cross-model review (**Claude API** via `claude-pr-review.yml` and **Codex** via ChatGPT Codex Connector) on the latest commit (`HEAD`). No model self-approves its own work, **and** once all required checks and cross-company reviews clear on `HEAD`, the builder or orchestrator agent fixes any flagged issues, re-checks, and squash-merges automatically without waiting for Salim (except locked paths below).
- **Naming & privacy:** `coqui` is the permanent internal codename (package names and folder paths stay `coqui*` even when the public app brand changes). Never introduce new hardcoded public repo/Pages URLs without a build-time override.

## Non-Negotiable Guardrails

1. Salim's words outrank any plan, research, or doc. If they disagree, follow Salim and note the override in one line.
2. One branch changes **one package** under `coqui/`. Never edit `coqui_contracts` from a feature branch — write a request in `coqui/requests/`.
3. **NEVER** modify or push under `historia/cuentos/` unless explicitly authorized (triggers paid Azure audio).
4. **NEVER** modify Danny's ElevenLabs allowlist, origin lock, rate limit, or add pet names (`mi amor`, `nene`).
5. **NEVER** add honor-system / self-report buttons ("I said it", swipe-to-rate), translation pop-ups, machine-translated lesson pages, or story screenshots reused as UI/book pictures.
6. **NEVER** spend money (Azure, ElevenLabs, paid APIs/tests) without stating the exact amount and getting Salim's explicit yes.
7. Keep `historia/` frozen (bug fixes only).
8. Every package PR must pass `dart run tool/check_boundaries.dart`, `dart format`, `flutter analyze`, and its package tests.

## The board

- The board is this repo's GitHub issues: https://github.com/salimocasio-dev/field-notes/issues
- An epic (`type:epic`) is one feature or goal. Its stories (`type:story`) are its sub-issues.
- Every story has three labels: a status, an agent and a lane.
  - Status: `status:ready`, `status:claimed`, `status:in-review`, `status:blocked`, `status:needs-salim`.
  - Agent: `agent:claude`, `agent:codex`, `agent:gemini`, or `agent:any`.
  - Lane: `lane:<package>` (one package of `coqui/`), or `lane:app`, `lane:content`, `lane:docs`.
- The repo is public, so the board is public until Salim makes the repo private. Never put keys, money, accounts or anything personal on the board.
- Live backlog and new tickets are tracked exclusively on GitHub Issues / the GitHub Project board (Drive `01 Backlog` is archived).

## The rule that keeps you apart

- One story works in one lane. A lane is one package (see `coqui/AGENTS.md`, "Lanes").
- A lane holds one story at a time, from claim until its pull request is merged or closed.
- So two agents never change the same files. `coqui/tool/check_boundaries.dart` fails a branch that strays out of its lane.
- `coqui/requests/` is open to every lane. Each request is its own file with its own name, so requests never collide.
- A few stories hold more than one lane. A scene port holds `lane:coqui_scenes` and `lane:feature_story`, because a scene's tests live in both. It holds both lanes until merged, and its branch is `story/<n>`. Its story lists every other path it may change (the scene's own `coqui/ref/pp/<scene>/`, for example).
- Stories in a series (the scene ports) are taken lowest number first.

## Your loop

All commands are run from the repo root. `<you>` is `claude`, `codex` or `gemini`.

1. `python3 tools/board.py ready <you>` lists the stories you may take now.
2. `python3 tools/board.py claim <n> <you>` takes one. If it says the lane is taken, or that you lost a race, pick another.
3. Work in your own clone or your own `git worktree`. Never in a folder another agent is using.
4. Branch from the newest `origin/main`, with the name the claim prints: `lane/<package>/<n>`, or `story/<n>` for a story that holds two lanes.
5. Change only your package and `coqui/requests/`. Run the checks in `coqui/AGENTS.md`, "Commands". `bash coqui/tool/test_all.sh` must pass.
6. Push your branch. Open a ready (non-draft) pull request against `main`:
   - Title: `#<n> <story title>`.
   - Body: `Closes #<n>`, what you did, each check you ran with its numbers, requests you filed. Never claim a check you did not run.
7. `python3 tools/board.py review <n> <you> <pr number>`.
8. **Automated review-fix-merge loop:** Wait for CI (`coqui.yml` + `coqui-guardrails.yml`) and the automated reviewers (**Claude API** + **Codex**) on the latest `HEAD` commit. If any check fails or either reviewer flags blockers or P0/P1 issues, fix them on the same branch, re-run local checks, push, and **comment `@codex review` on the PR** if Codex does not start automatically on the new `HEAD`. Wait for fresh checks/reviews on `HEAD` (including after updating from `main`). Once the Auto-merge gate below passes and the branch is up to date with `main`, **squash-merge automatically** (`gh pr merge <pr> --squash --delete-branch`).
9. Take your next story from a different lane (or newly unblocked stories). Yours stays held until the pull request is merged.

## Reviews and merging

- Automated independent reviews run on every PR via **Claude API** (`claude-pr-review.yml`) and **Codex** (`ChatGPT Codex Connector`). No model self-approves its own work.
- If a human or interactive cross-company reviewer also posts a review, it starts with `REVIEW PASS <you>` or `REVIEW CHANGES <you>`, then numbered findings with file and line.
- Only real problems block: a wrong behaviour, a broken rule of Salim's, a failed check, a Claude API blocker/`CHANGES REQUESTED`, or a Codex P0/P1 finding. Small non-blocking "Warnings / Notes" go into follow-up stories if needed and do not block merge.
- **No auto-merge on locked/sensitive paths:** PRs touching `historia/cuentos/`, ElevenLabs / Danny call config (`historia/notas/danny*` or ElevenLabs allowlist/origin/rate-limit code in `coqui/packages/core/coqui_platform/`), or `coqui/packages/core/coqui_contracts/` must **not** auto-merge: `historia/cuentos/` and ElevenLabs allowlist/origin/rate-limit require Salim's explicit approval, and `coqui_contracts` requires Claude Code sign-off (or Salim's approval if Claude Code quota is unavailable, after both Claude API and Codex pass).
- **Auto-merge gate (all must hold on the latest `HEAD` commit):**
  1. `coqui.yml` and `coqui-guardrails.yml` checks on `HEAD` are `SUCCESS` (not stale from an earlier commit).
  2. Cross-company independent review is complete on `HEAD` (if `HEAD` changes after merging `main` or pushing fixes, fresh CI + reviews are required; comment `@codex review` if Codex doesn't start on the new `HEAD`):
     - **Gemini-built PRs:** Claude API (`claude-review` job `SUCCESS` with `Verdict: APPROVE` or `Verdict: COMMENT` and `Blockers: None`) **and** Codex (`codex-review-state` shows `status` finished—not `running`—and `has_unresolved_findings: false` / zero unresolved P0 or P1 findings).
     - **Claude-built PRs:** must have **Codex** (or Gemini) cross-company review completed on `HEAD` with zero unresolved blockers/P0/P1 findings (never merge a Claude-built PR on Claude API review alone).
     - **Codex-built PRs:** must have **Claude API** (or Gemini) cross-company review completed on `HEAD` with zero blockers.
  3. Do not treat Codex silence as a pass: if Codex does not start or finish within 5 minutes, comment `@codex review` once and wait. Only if Codex explicitly reports a Plus quota/rate-limit failure on a non-Claude, non-`coqui_contracts` PR may you proceed with CI + Claude API + an explicit PR comment documenting the Codex rate-limit skip; otherwise do not merge and escalate.
  4. The PR does not touch the locked paths above and is up to date with `main`.
  5. When all conditions hold, the builder or orchestrator squash-merges (`gh pr merge <pr> --squash --delete-branch`). `Closes #<n>` closes the story.
- If automated reviews request changes, fix them on the same branch and wait for fresh `HEAD` reviews. If still blocked after two fix rounds, escalate to Neon/Carbon (or Claude Code when available), or block for Salim if it needs a product decision.
- Look for review/fix work on open red PRs when `ready` finds nothing for you.

## Who may do what

- Any agent: a story labelled for it or `agent:any`, in that story's lane.
- Claude (the scrum master; or Antigravity Neon/Carbon under cross-model review when Claude Code quota is unavailable):
  - `lane:app` (the shell), `coqui/BUILD` (putting a build live), `docs/`, `.github/`, and this page.
  - Grooming: turning epics and Salim's notes into stories with a "Done when", a lane and an agent.
  - Moving a `status:blocked` story to `status:ready` once what it waits on is merged.
  - Releasing a claim that has sat for 24 hours with no new commit on its branch.
- Salim: approves new epics, plays the builds, answers `status:needs-salim` questions.

## Never

- Never push to `main`. Never force-push someone else's branch.
- Never push anything under `historia/cuentos/`. It starts a paid recording job.
- Never spend money or open accounts: no ElevenLabs calls, no Azure recordings, no keys.
- Never change files outside your lane, or take a story whose lane is held.

## When you are stuck

- You need something from a package outside your lane: file a request in `coqui/requests/` (format in `coqui/AGENTS.md`, "Requests"), use the fake or a local copy, carry on.
- A choice only Salim can make: `python3 tools/board.py block <n> <you> "<one question>"`. That frees the lane. Take another story.
- You must stop for any other reason: `python3 tools/board.py release <n> <you> "<why>"`, and push what you have to your branch first.

## A story

```
## Salim's words
(quoted, from the backlog or the chat)

## Done when
- (each line something a reviewer can check)

## Lane
lane:<package>. Files outside it: only coqui/requests/.

## Links
(briefs, pages, earlier work)
```
