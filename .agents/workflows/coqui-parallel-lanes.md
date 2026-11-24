# Coqui Parallel Package Workflow (Template)

Run in Antigravity when 2+ independent Flutter packages are ready in the same wave:

/run-workflow For each listed GitHub issue [<ISSUE_1>, <ISSUE_2>], start one subagent in an isolated Git branch worktree (workspace="branch") using model flash/hydrogen at high thinking. Each subagent must:
1. Read root AGENTS.md, coqui/AGENTS.md, its package AGENTS.md, and the GitHub issue body.
2. Edit files ONLY inside its single assigned package (or coqui/requests/ for contract requests). Never touch historia/cuentos/.
3. Run dart run tool/check_boundaries.dart, dart format, flutter analyze, and its package tests.
4. Commit to its branch, open a ready (non-draft) PR referencing the issue, and run `python3 tools/board.py review <n> gemini <pr>`.
5. Wait for CI (`coqui.yml` + `coqui-guardrails.yml`) and automated reviews (**Claude API** + **Codex**). If any check fails or any blocker / P0 / P1 issue is flagged, fix it on the same branch, re-run checks, push, and re-verify.
6. Once CI is green, automated reviews have no blockers / P0 / P1 findings, and the branch is up to date with `main`, squash-merge the PR automatically (`gh pr merge <pr> --squash --delete-branch`) and return a one-line status with test results and the merged PR URL.
