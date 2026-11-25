# Coqui Parallel Package Workflow (Template)

Run in Antigravity when 2+ independent Flutter packages are ready in the same wave:

/run-workflow For each listed GitHub issue [<ISSUE_1>, <ISSUE_2>], start one subagent in an isolated Git branch worktree (workspace="branch") using model flash/hydrogen at high thinking. Each subagent must:
1. Read root AGENTS.md, coqui/AGENTS.md, its package AGENTS.md, and the GitHub issue body.
2. Edit files ONLY inside its single assigned package (or coqui/requests/ for contract requests). Never touch historia/cuentos/.
3. Run dart run tool/check_boundaries.dart, dart format, flutter analyze, and its package tests.
4. Commit to its branch, open a ready (non-draft) PR referencing the issue, and run `python3 tools/board.py review <n> <agent> <pr>` (use your agent name, e.g., `gemini`).
5. Wait for CI (`coqui.yml` + `coqui-guardrails.yml`) and required cross-company reviews per the Auto-merge gate in root `AGENTS.md` on the latest `HEAD` commit. If any check fails or any blocker / P0 / P1 issue is flagged, fix it on the same branch, re-run checks, push, and wait for fresh `HEAD` reviews.
6. Once the Auto-merge gate in root `AGENTS.md` passes (not touching locked paths like `coqui_contracts`, `historia/cuentos/`, or ElevenLabs config) and the branch is up to date with `main`, squash-merge the PR automatically (`gh pr merge <pr> --squash --delete-branch`).
7. Always end with the exact **Final Status Report** from root `AGENTS.md` (`Status: MERGED | WAITING ON MERGE | WAITING ON REVIEW | BLOCKED | NEEDS SALIM | STOPPED (NO PR)`, verified `Ticket:` `CLOSED`/`OPEN`, `PR:`, `Checks & Reviews:`, and `Next:`).
