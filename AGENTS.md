# Coqui: how every AI works here at the same time

Claude, Codex (ChatGPT) and Gemini work on this repo at the same time. This page keeps them out of each other's way.

Read, in this order:

1. The Drive folder's READ FIRST page: what Coqui is and Salim's rules. https://docs.google.com/document/d/1lCqG1wcIAjkwbkqX0Mmm3WL0u2pz_7sswYKxqlYoGq4
2. This page.
3. `coqui/AGENTS.md` before you touch code: the lanes, the checks, the porting rules.

Salim's words come first. If anything here disagrees with what he said, do what he said and tell him in one line.

## The board

- The board is this repo's GitHub issues: https://github.com/salimocasio-dev/field-notes/issues
- An epic (`type:epic`) is one feature or goal. Its stories (`type:story`) are its sub-issues.
- Every story has three labels: a status, an agent and a lane.
  - Status: `status:ready`, `status:claimed`, `status:in-review`, `status:blocked`, `status:needs-salim`.
  - Agent: `agent:claude`, `agent:codex`, `agent:gemini`, or `agent:any`.
  - Lane: `lane:<package>` (one package of `coqui/`), or `lane:app`, `lane:content`, `lane:docs`.
- The repo is public, so the board is public until Salim makes the repo private. Never put keys, money, accounts or anything personal on the board.
- Salim's notes may still land in the Drive backlog (`01 Backlog — master copy`). Claude turns them into stories here and writes the issue number next to the note.

## The rule that keeps you apart

- One story works in one lane. A lane is one package (see `coqui/AGENTS.md`, "Lanes").
- A lane holds one story at a time, from claim until its pull request is merged or closed.
- So two agents never change the same files. `coqui/tool/check_boundaries.dart` fails a branch that strays out of its lane.
- `coqui/requests/` is open to every lane. Each request is its own file with its own name, so requests never collide.

## Your loop

All commands are run from the repo root. `<you>` is `claude`, `codex` or `gemini`.

1. `python3 tools/board.py ready <you>` lists the stories you may take now.
2. `python3 tools/board.py claim <n> <you>` takes one. If it says the lane is taken, or that you lost a race, pick another.
3. Work in your own clone or your own `git worktree`. Never in a folder another agent is using.
4. Branch from the newest `origin/main`: `lane/<package>/<n>`, the name the claim prints.
5. Change only your package and `coqui/requests/`. Run the checks in `coqui/AGENTS.md`, "Commands". `bash coqui/tool/test_all.sh` must pass.
6. Push your branch. Open a pull request against `main`:
   - Title: `#<n> <story title>`.
   - Body: `Closes #<n>`, what you did, each check you ran with its numbers, requests you filed. Never claim a check you did not run.
7. `python3 tools/board.py review <n> <you> <pr number>`.
8. Take your next story from a different lane. Yours stays held until the pull request is merged.

## Reviews and merging

- Every pull request is reviewed by an agent from a different company than the one that built it. Claude's work is reviewed by Codex or Gemini; theirs by Claude or each other.
- A review is a comment on the pull request. It starts with `REVIEW PASS <you>` or `REVIEW CHANGES <you>`, then numbered findings, each with the file and line.
- Only real problems block: a wrong behaviour, a broken rule of Salim's, a failed check. Small things go in the comment as "later" and become a new story. They do not block.
- Merge when all three hold: CI (`coqui.yml`) is green, there is a `REVIEW PASS` from another company, and the branch is up to date with `main`. The reviewer squash-merges. `Closes #<n>` closes the story.
- `REVIEW CHANGES`: the builder fixes it on the same branch. After two rounds, Claude decides.
- Look for review work when `ready` finds nothing for you: open pull requests built by another company.

## Who may do what

- Any agent: a story labelled for it or `agent:any`, in that story's lane.
- Claude only (the scrum master):
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
